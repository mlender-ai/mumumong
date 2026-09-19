import { assert, assertEquals, assertThrows } from "@std/assert";
import type { SceneDraft } from "../_shared/contract.ts";
import {
  buildCommitPayload,
  type CommitGateway,
  type CommitInput,
  CommitInputError,
  type CommitPayload,
  type EnqueueRequest,
  runCommit,
} from "./commit.ts";
import { deterministicUuid } from "../_shared/uuid.ts";

const DREAM = "d2222222-2222-4222-8222-222222222222";
const VOLUME = "d1111111-1111-4111-8111-111111111111";
const JOB = "d3333333-3333-4333-8333-333333333333";
const USER = "d9999999-9999-4999-8999-999999999999";
const UMBRELLA = "11111111-1111-4111-8111-111111111111";
const ENTITY_A = "44444444-4444-4444-8444-444444444444";
const ENTITY_B = "55555555-5555-4555-8555-555555555555";

function draft(overrides: Partial<SceneDraft> = {}): SceneDraft {
  return {
    scene: { placement: "continuation", title: "붉은 문" },
    passages: [
      { origin: "D", text: "복도에 물이 차 있었다.", source_element_ids: [UMBRELLA] },
      { origin: "C", text: "이층의 복도와 닮아 있었다.", c_reason: "전이" },
    ],
    open_image: "문틈으로 새어 나오는 물소리",
    ...overrides,
  };
}

function input(overrides: Partial<CommitInput> = {}): CommitInput {
  return {
    jobId: JOB,
    userId: USER,
    dreamId: DREAM,
    volumeId: VOLUME,
    clarity: "partial",
    placement: "continuation",
    draft: draft(),
    sceneOrderKey: "a0001",
    ...overrides,
  };
}

/// Mirrors `commit_scene`: one scene per source dream, returned again on retry.
class FakeGateway implements CommitGateway {
  readonly scenesByDream = new Map<string, string>();
  readonly payloads: CommitPayload[] = [];
  readonly jobPatches: Record<string, unknown>[] = [];
  readonly enqueued: EnqueueRequest[] = [];
  private readonly usedKeys = new Set<string>();
  readonly archived: string[] = [];
  commitCalls = 0;
  private counter = 0;

  commitScene(
    dreamId: string,
    _volumeId: string,
    payload: CommitPayload,
  ): Promise<string> {
    this.commitCalls += 1;
    this.payloads.push(payload);
    const existing = this.scenesByDream.get(dreamId);
    if (existing) return Promise.resolve(existing);
    this.counter += 1;
    const sceneId = `scene-${this.counter}`;
    this.scenesByDream.set(dreamId, sceneId);
    return Promise.resolve(sceneId);
  }

  markArchivedOnly(dreamId: string): Promise<void> {
    this.archived.push(dreamId);
    return Promise.resolve();
  }

  mergeJobPayload(_jobId: string, patch: Record<string, unknown>): Promise<void> {
    this.jobPatches.push(patch);
    return Promise.resolve();
  }

  /// Mirrors the unique index on (user_id, idempotency_key): a repeat presents
  /// the same key and is collapsed rather than queued twice.
  enqueueJob(request: EnqueueRequest): Promise<string | null> {
    const key = `${request.userId}:${request.idempotencyKey}`;
    if (this.usedKeys.has(key)) return Promise.resolve(null);
    this.usedKeys.add(key);
    this.enqueued.push(request);
    return Promise.resolve(`job-${this.enqueued.length}`);
  }
}

// --- Completion condition: running the same job twice creates one scene ---

Deno.test("a repeated job creates exactly one scene", async () => {
  const gateway = new FakeGateway();

  const first = await runCommit(gateway, input());
  assertEquals(first.sceneId, "scene-1");
  assertEquals(first.reused, false);

  // Second attempt with the scene_id the first run wrote onto the job.
  const second = await runCommit(gateway, input({ existingSceneId: first.sceneId! }));
  assertEquals(second.sceneId, "scene-1");
  assertEquals(second.reused, true);

  assertEquals(gateway.commitCalls, 1, "the RPC is not called again");
  assertEquals(gateway.scenesByDream.size, 1);
  assertEquals(gateway.enqueued.length, 1, "remember is queued once");
});

Deno.test("a retry that lost the job payload still yields one scene", async () => {
  const gateway = new FakeGateway();

  // Both attempts believe they are the first: the RPC's own idempotency is
  // what holds the line, exactly as migration 0007 guarantees.
  const first = await runCommit(gateway, input());
  const second = await runCommit(gateway, input());

  assertEquals(first.sceneId, second.sceneId);
  assertEquals(gateway.commitCalls, 2);
  assertEquals(gateway.scenesByDream.size, 1, "still one scene for the dream");
});

Deno.test("commit records the scene on the job and queues remember", async () => {
  const gateway = new FakeGateway();
  const result = await runCommit(gateway, input());

  assertEquals(gateway.jobPatches, [{ scene_id: "scene-1" }]);
  assertEquals(gateway.enqueued[0].type, "remember");
  assertEquals(gateway.enqueued[0].userId, USER);
  assertEquals(gateway.enqueued[0].volumeId, VOLUME);
  assertEquals(gateway.enqueued[0].payload, {
    dream_id: DREAM,
    volume_id: VOLUME,
    scene_id: "scene-1",
  });
  assertEquals(result.rememberJobId, "job-1");
});

// --- standalone ---

Deno.test("standalone archives the dream without a scene or a remember job", async () => {
  const gateway = new FakeGateway();
  const result = await runCommit(
    gateway,
    input({ placement: "standalone", draft: undefined }),
  );

  assertEquals(result.sceneId, null);
  assertEquals(result.archivedOnly, true);
  assertEquals(result.rememberJobId, null);
  assertEquals(gateway.archived, [DREAM]);
  assertEquals(gateway.commitCalls, 0);
  assertEquals(gateway.enqueued.length, 0);
  assertEquals(gateway.jobPatches, [{ archived_only: true }]);
});

// --- Payload assembly ---

Deno.test("payload merges auto links with the draft's used entities", () => {
  const payload = buildCommitPayload(input({
    draft: draft({ used_entities: [ENTITY_A] }),
    links: [
      { entity_id: ENTITY_A, status: "auto" },
      { entity_id: ENTITY_B, status: "auto" },
      { entity_id: "66666666-6666-4666-8666-666666666666", status: "pending" },
      { entity_id: "77777777-7777-4777-8777-777777777777", status: "rejected" },
    ],
  }));

  assertEquals(payload.used_entities?.length, 2);
  assert(payload.used_entities!.includes(ENTITY_A));
  assert(payload.used_entities!.includes(ENTITY_B));
});

Deno.test("payload carries clarity, placement, order_key and open_image", () => {
  const payload = buildCommitPayload(input());
  assertEquals(payload.clarity, "partial");
  assertEquals(payload.scene.placement, "continuation");
  assertEquals(payload.scene.order_key, "a0001");
  assertEquals(payload.scene.title, "붉은 문");
  assertEquals(payload.open_image, "문틈으로 새어 나오는 물소리");
  assertEquals(payload.scene.open_image, "문틈으로 새어 나오는 물소리");
});

Deno.test("passages get stable order keys and keep provenance", () => {
  const payload = buildCommitPayload(input());
  assertEquals(payload.passages.map((passage) => passage.order_key), ["a0001", "a0002"]);
  assertEquals(payload.passages[0].source_element_ids, [UMBRELLA]);
  assertEquals(payload.passages[1].c_reason, "전이");
});

Deno.test("an explicit passage order_key is preserved", () => {
  const payload = buildCommitPayload(input({
    draft: draft({
      passages: [
        { origin: "D", text: "물.", source_element_ids: [UMBRELLA], order_key: "m5" },
      ],
    }),
  }));
  assertEquals(payload.passages[0].order_key, "m5");
});

Deno.test("empty entity lists are omitted rather than sent as empty arrays", () => {
  const payload = buildCommitPayload(input());
  assertEquals(payload.new_entities, undefined);
  assertEquals(payload.used_entities, undefined);
});

// --- Input guards ---

Deno.test("a U passage is refused before it reaches the database", () => {
  assertThrows(
    () =>
      buildCommitPayload(input({
        draft: draft({
          passages: [
            { origin: "D", text: "물.", source_element_ids: [UMBRELLA] },
            { origin: "U", text: "내가 쓴 문단." },
          ],
        }),
      })),
    CommitInputError,
    "user passages",
  );
});

Deno.test("a D passage without provenance is refused", () => {
  assertThrows(
    () =>
      buildCommitPayload(input({
        draft: draft({ passages: [{ origin: "D", text: "물." }] }),
      })),
    CommitInputError,
    "source element",
  );
});

Deno.test("a missing order_key is refused", () => {
  assertThrows(
    () => buildCommitPayload(input({ sceneOrderKey: "   " })),
    CommitInputError,
    "order_key",
  );
});

Deno.test("standalone and a scene payload are mutually exclusive", () => {
  assertThrows(
    () => buildCommitPayload(input({ placement: "standalone" })),
    CommitInputError,
    "standalone",
  );
  assertThrows(
    () => buildCommitPayload(input({ draft: undefined })),
    CommitInputError,
    "E4 draft",
  );
});

// --- Idempotency key ---

Deno.test("the remember key is stable per dream, so a re-run queues nothing new", async () => {
  const gateway = new FakeGateway();

  // Two attempts that both believe they are the first.
  const first = await runCommit(gateway, input());
  const second = await runCommit(gateway, input());

  assertEquals(first.rememberJobId, "job-1");
  assertEquals(second.rememberJobId, null, "the duplicate enqueue is collapsed");
  assertEquals(gateway.enqueued.length, 1);
  assertEquals(
    gateway.enqueued[0].idempotencyKey,
    await deterministicUuid(`remember:${DREAM}`),
  );
});

Deno.test("deterministicUuid is stable, shaped like a v5 UUID, and name-specific", async () => {
  const a = await deterministicUuid(`remember:${DREAM}`);
  const b = await deterministicUuid(`remember:${DREAM}`);
  const other = await deterministicUuid(`remember:${VOLUME}`);

  assertEquals(a, b);
  assert(a !== other);
  assert(
    /^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/u.test(a),
    `not a v5-shaped uuid: ${a}`,
  );
});

Deno.test("a retry after a crash before enqueue still queues remember", async () => {
  const gateway = new FakeGateway();

  // First attempt commits the scene, then dies before queueing the next stage.
  const sceneId = await gateway.commitScene(DREAM, VOLUME, buildCommitPayload(input()));
  assertEquals(gateway.enqueued.length, 0);

  // The retry sees the scene_id on the job and must still queue remember.
  const retry = await runCommit(gateway, input({ existingSceneId: sceneId }));

  assertEquals(retry.reused, true);
  assertEquals(retry.sceneId, sceneId);
  assertEquals(retry.rememberJobId, "job-1");
  assertEquals(gateway.enqueued.length, 1);
  assertEquals(gateway.commitCalls, 1, "the RPC is not called again");
});

// WO-E6 · Commit
//
// No model is called at this stage. Commit assembles the `commit_scene` payload
// from the E1 elements, the E2 link decisions and the E4 draft, calls the RPC,
// records the resulting scene on the job, and queues `remember`.
//
// The transaction and its idempotency live in `commit_scene` (migration 0007),
// which returns the existing scene for a retried dream instead of inserting a
// second one. This wrapper adds the step before that: a job that already
// carries a `scene_id` does not call the RPC again at all.

import type { Clarity, PlacementKind, SceneDraft } from "../_shared/contract.ts";
import { deterministicUuid } from "../_shared/uuid.ts";

export interface CommitPayload {
  readonly clarity: Clarity;
  readonly open_image?: string;
  readonly scene: {
    readonly id?: string;
    readonly order_key: string;
    readonly kind?: string;
    readonly placement: PlacementKind;
    readonly title?: string;
    readonly open_image?: string;
  };
  readonly passages: readonly {
    readonly id?: string;
    readonly order_key?: string;
    readonly origin: "D" | "C";
    readonly text: string;
    readonly source_element_ids?: readonly string[];
    readonly c_reason?: string;
  }[];
  readonly new_entities?: readonly Record<string, unknown>[];
  readonly used_entities?: readonly string[];
}

/// An E2 decision. Only `auto` links count as used entities: a `pending` link is
/// still a question waiting for the user, and a rejected one is not a link.
export interface LinkDecision {
  readonly entity_id: string;
  readonly status: "auto" | "pending" | "rejected";
}

export interface CommitInput {
  readonly jobId: string;
  /// Owner of the job. `jobs.user_id` is NOT NULL, so the queued `remember`
  /// job cannot be inserted without it.
  readonly userId: string;
  readonly dreamId: string;
  readonly volumeId: string;
  readonly clarity: Clarity;
  readonly placement: PlacementKind;
  /// The validated E4 draft. Absent for `standalone`, which commits no scene.
  readonly draft?: SceneDraft;
  /// Supplied by the caller from the volume's current scene count.
  readonly sceneOrderKey?: string;
  readonly links?: readonly LinkDecision[];
  /// A `scene_id` already present in `jobs.payload` from an earlier attempt.
  readonly existingSceneId?: string;
}

export interface CommitGateway {
  commitScene(
    dreamId: string,
    volumeId: string,
    payload: CommitPayload,
  ): Promise<string>;
  markArchivedOnly(dreamId: string): Promise<void>;
  mergeJobPayload(jobId: string, patch: Record<string, unknown>): Promise<void>;
  /// Returns the job id, or null when an equivalent job is already queued.
  enqueueJob(request: EnqueueRequest): Promise<string | null>;
}

export interface EnqueueRequest {
  readonly type: string;
  readonly userId: string;
  readonly dreamId: string;
  readonly volumeId: string;
  /// Stable across retries, so the unique index on (user_id, idempotency_key)
  /// collapses a re-run instead of queueing a duplicate.
  readonly idempotencyKey: string;
  readonly payload: Record<string, unknown>;
}

export interface CommitResult {
  readonly sceneId: string | null;
  readonly archivedOnly: boolean;
  /// Null when nothing was queued: a standalone commit, a reused scene, or a
  /// `remember` job that was already waiting.
  readonly rememberJobId: string | null;
  /// True when the job already carried a scene and the RPC was not called.
  readonly reused: boolean;
}

export class CommitInputError extends Error {}

export function buildCommitPayload(input: CommitInput): CommitPayload {
  const draft = input.draft;
  if (!draft) {
    throw new CommitInputError("a scene payload requires an E4 draft");
  }
  if (input.placement === "standalone") {
    throw new CommitInputError("standalone commits no scene");
  }

  const orderKey = input.sceneOrderKey?.trim();
  if (!orderKey) {
    throw new CommitInputError("scene order_key is required");
  }

  const passages = draft.passages.map((passage, index) => {
    if (passage.origin === "U") {
      // commit_scene rejects this too, but failing here keeps a bug from
      // reaching the database as a transaction error.
      throw new CommitInputError("commit does not accept user passages");
    }
    if (passage.origin === "D" && (passage.source_element_ids ?? []).length === 0) {
      throw new CommitInputError("a D passage requires at least one source element");
    }
    return {
      ...(passage.id ? { id: passage.id } : {}),
      order_key: passage.order_key ?? `a${String(index + 1).padStart(4, "0")}`,
      origin: passage.origin,
      text: passage.text,
      ...(passage.source_element_ids ? { source_element_ids: passage.source_element_ids } : {}),
      ...(passage.c_reason ? { c_reason: passage.c_reason } : {}),
    };
  });

  const usedEntities = new Set<string>(draft.used_entities ?? []);
  for (const link of input.links ?? []) {
    if (link.status === "auto") usedEntities.add(link.entity_id);
  }

  const openImage = draft.scene.open_image ?? draft.open_image;

  return {
    clarity: input.clarity,
    ...(openImage ? { open_image: openImage } : {}),
    scene: {
      ...(draft.scene.id ? { id: draft.scene.id } : {}),
      order_key: orderKey,
      ...(draft.scene.kind ? { kind: draft.scene.kind } : {}),
      placement: input.placement,
      ...(draft.scene.title ? { title: draft.scene.title } : {}),
      ...(openImage ? { open_image: openImage } : {}),
    },
    passages,
    ...(draft.new_entities && draft.new_entities.length > 0
      ? { new_entities: draft.new_entities as readonly Record<string, unknown>[] }
      : {}),
    ...(usedEntities.size > 0 ? { used_entities: [...usedEntities] } : {}),
  };
}

export async function runCommit(
  gateway: CommitGateway,
  input: CommitInput,
): Promise<CommitResult> {
  // A retry that already committed does not call the RPC again, but it still
  // tries to queue `remember`: the first attempt may have died between writing
  // the scene and queueing the next stage. The deterministic key makes the
  // second attempt a no-op when the job is already there.
  if (input.existingSceneId) {
    const rememberJobId = await queueRemember(gateway, input, input.existingSceneId);
    return {
      sceneId: input.existingSceneId,
      archivedOnly: false,
      rememberJobId,
      reused: true,
    };
  }

  if (input.placement === "standalone") {
    await gateway.markArchivedOnly(input.dreamId);
    await gateway.mergeJobPayload(input.jobId, { archived_only: true });
    // Nothing was written to the manuscript, so there is nothing to remember.
    return { sceneId: null, archivedOnly: true, rememberJobId: null, reused: false };
  }

  const payload = buildCommitPayload(input);
  const sceneId = await gateway.commitScene(input.dreamId, input.volumeId, payload);

  await gateway.mergeJobPayload(input.jobId, { scene_id: sceneId });

  const rememberJobId = await queueRemember(gateway, input, sceneId);

  return { sceneId, archivedOnly: false, rememberJobId, reused: false };
}

async function queueRemember(
  gateway: CommitGateway,
  input: CommitInput,
  sceneId: string,
): Promise<string | null> {
  return await gateway.enqueueJob({
    type: "remember",
    userId: input.userId,
    dreamId: input.dreamId,
    volumeId: input.volumeId,
    idempotencyKey: await deterministicUuid(`remember:${input.dreamId}`),
    payload: {
      dream_id: input.dreamId,
      volume_id: input.volumeId,
      scene_id: sceneId,
    },
  });
}

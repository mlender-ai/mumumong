import { assertEquals } from "@std/assert";
import {
  FakeLlm,
  TEST_ELEMENT_ID,
  TEST_ENTITY_ID,
  TEST_VOLUME,
} from "../_shared/testing/fake_llm.ts";
import { WRITE_FALLBACK, WRITE_SYSTEM } from "../_shared/prompts/write.v1.ts";
import { OPENING_EXPANSION_SYSTEM } from "./opening_expansion.ts";
import { OPENING_POLISH_SYSTEM } from "./opening_polish.ts";
import { runWrite, type WriteCoreInput } from "./core.ts";

function draft(text = "구슬이 바닥을 굴렀다.", passageCount = 1) {
  return {
    scene: {
      title: "모델 제목",
      kind: "dream",
      placement: "continuation",
      open_image: "synthetic image",
    },
    passages: Array.from({ length: passageCount }, () => ({
      origin: "D",
      text,
      source_element_ids: [TEST_ELEMENT_ID],
      c_reason: null,
    })),
    new_entities: [],
    used_entities: [TEST_ENTITY_ID],
    open_image: "synthetic image",
  };
}
function input(patch: Partial<WriteCoreInput> = {}): WriteCoreInput {
  return {
    dream: { raw_text: "구슬이 바닥을 굴렀다.", recall_answers: {}, sensitive_flags: [] },
    volume: TEST_VOLUME,
    memory: null,
    entities: [],
    recentScenes: [],
    lockedPassages: [],
    payload: { scene_title: "구슬", placement: "continuation", target_length: 700 },
    writeAttempt: 0,
    isFallback: false,
    ...patch,
  };
}

Deno.test("write core preserves normal call, title normalization and entity filtering", async () => {
  const llm = new FakeLlm([draft()]);
  const core = await runWrite(input(), llm);
  assertEquals(llm.calls.length, 1);
  assertEquals([
    llm.calls[0].role,
    llm.calls[0].system,
    llm.calls[0].temperature,
    llm.calls[0].maxTokens,
  ], ["write", WRITE_SYSTEM, 0.75, 5000]);
  assertEquals((core.sceneDraft.scene as Record<string, unknown>).title, "구슬");
  assertEquals(core.sceneDraft.used_entities, []);
  assertEquals(core.nextPayloadPatch.draft, core.sceneDraft);
  assertEquals(core.auditRun.tokensIn, 10);
});

Deno.test("write core preserves retry feedback and fallback parameters", async () => {
  const payload = {
    ...input().payload,
    is_first_dream: true,
    validation_feedback: [{ code: "V4", message: "synthetic" }],
  };
  const llm = new FakeLlm([draft()]);
  await runWrite(input({ payload, writeAttempt: 3, isFallback: true }), llm);
  assertEquals(llm.calls.length, 1);
  assertEquals(llm.calls[0].system.startsWith(WRITE_SYSTEM), true);
  assertEquals(llm.calls[0].system.endsWith(`\n\n${WRITE_FALLBACK}`), true);
  assertEquals(llm.calls[0].system.includes("V4"), true);
  assertEquals([llm.calls[0].temperature, llm.calls[0].maxTokens], [0.2, 8000]);
  assertEquals(
    ((llm.calls[0].input as Record<string, unknown>).settings as Record<string, unknown>)
      .target_length,
    420,
  );
  const retry = new FakeLlm([draft()]);
  await runWrite(input({ writeAttempt: 1 }), retry);
  assertEquals(retry.calls[0].temperature, 0.45);
});

Deno.test("write core keeps expansion, polish and the legacy aggregated audit", async () => {
  const llm = new FakeLlm([draft(), { text: "구슬".repeat(260) }, draft("구슬".repeat(40), 7)]);
  const core = await runWrite(
    input({
      payload: {
        ...input().payload,
        is_first_dream: true,
        elements: [{ id: TEST_ELEMENT_ID, label: "구슬", salience: "high" }],
      },
    }),
    llm,
  );
  assertEquals(llm.calls.map((call) => [call.role, call.temperature, call.maxTokens]), [
    ["write", 0.75, 8000],
    ["write_aux", 0.45, 900],
    ["polish", 0.35, 8000],
  ]);
  assertEquals(llm.calls[1].system, OPENING_EXPANSION_SYSTEM);
  assertEquals(llm.calls[2].system, OPENING_POLISH_SYSTEM);
  assertEquals(core.passageCount, 7);
  assertEquals((core.sceneDraft.scene as Record<string, unknown>).kind, "prologue");
  assertEquals(core.modelRuns.map((run) => run.role), ["write", "write_aux", "polish"]);
  assertEquals([core.auditRun.tokensIn, core.auditRun.tokensOut, core.auditRun.latencyMs], [
    30,
    60,
    15,
  ]);
});

Deno.test("optional expansion or polish failures retain the draft and only successful run metadata", async () => {
  const llm = new FakeLlm([
    draft(),
    new Error("synthetic failure"),
    new Error("synthetic failure"),
  ]);
  const core = await runWrite(
    input({ payload: { ...input().payload, is_first_dream: true } }),
    llm,
  );
  assertEquals(llm.calls.length, 3);
  assertEquals(core.passageCount, 1);
  assertEquals(core.modelRuns.length, 1);
  assertEquals(core.auditRun.tokensIn, 10);
});

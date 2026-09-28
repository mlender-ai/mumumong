import { assertEquals } from "@std/assert";
import { FakeLlm, TEST_ELEMENT_ID, TEST_VOLUME } from "../_shared/testing/fake_llm.ts";
import { PLAN_SYSTEM } from "../_shared/prompts/plan.v1.ts";
import { runPlan } from "./core.ts";

Deno.test("plan core keeps the frozen first-scene normalization and model call", async () => {
  const llm = new FakeLlm([{
    placement: "standalone",
    attach_to_scene_id: null,
    beats: [{ kind: "D", element_ids: [TEST_ELEMENT_ID], note: "synthetic" }],
    target_length: 5000,
    scene_title: "구슬",
  }]);
  const core = await runPlan({
    dream: { raw_text: "구슬이 바닥을 굴렀다.", recall_answers: {} },
    volume: TEST_VOLUME,
    memory: null,
    existingScenes: [],
    payload: {
      clarity: "partial",
      elements: [{ id: TEST_ELEMENT_ID, type: "object", label: "구슬", salience: "high" }],
    },
  }, llm);
  assertEquals(core.plan.placement, "continuation");
  assertEquals(core.plan.target_length, 700);
  assertEquals(core.nextPayloadPatch.is_first_dream, true);
  assertEquals(core.nextStage, "write");
  assertEquals([
    llm.calls[0].role,
    llm.calls[0].system,
    llm.calls[0].temperature,
    llm.calls[0].maxTokens,
  ], ["plan", PLAN_SYSTEM, 0.3, 1800]);
  assertEquals((llm.calls[0].input as Record<string, unknown>).length_cap, 2340);
});

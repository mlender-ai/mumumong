import { assertEquals } from "@std/assert";
import { FakeLlm, TEST_ELEMENT_ID } from "../_shared/testing/fake_llm.ts";
import { deterministicUuid } from "../_shared/uuid.ts";
import { EXTRACT_SYSTEM } from "../_shared/prompts/extract.v1.ts";
import { runExtract } from "./core.ts";

Deno.test("extract core preserves request parameters, Unicode spans and stable IDs", async () => {
  const llm = new FakeLlm([{
    elements: [{
      type: "object",
      label: "구슬",
      detail: null,
      salience: "high",
      source: "raw",
      span: [0, 1],
    }],
    clarity: "vivid",
    empty_slots: [],
    sensitive_flags: [],
  }]);
  const input = { dreamId: TEST_ELEMENT_ID, dream: { raw_text: "🔵구슬", recall_answers: null } };
  const core = await runExtract(input, llm);
  assertEquals(core.normalized.clarity, "fragment");
  assertEquals(core.rows[0].span, "[1,3)");
  assertEquals(
    core.rows[0].id,
    await deterministicUuid(`element:${input.dreamId}:0:raw:object:구슬`),
  );
  assertEquals(core.nextPayloadPatch.elements[0].id, core.rows[0].id);
  assertEquals(llm.calls[0].input, { raw_text: input.dream.raw_text, recall_answers: {} });
  assertEquals([
    llm.calls[0].role,
    llm.calls[0].system,
    llm.calls[0].temperature,
    llm.calls[0].maxTokens,
  ], ["extract", EXTRACT_SYSTEM, 0, 1600]);
  assertEquals(core.modelRuns[0].role, "extract");
  assertEquals(Object.keys(core.modelRuns[0]).sort(), [
    "latencyMs",
    "model",
    "promptVersion",
    "role",
    "tokensIn",
    "tokensOut",
  ]);
});

import { assertEquals } from "@std/assert";
import { FakeLlm, TEST_ELEMENT_ID, TEST_ENTITY_ID } from "../_shared/testing/fake_llm.ts";
import { LINK_SYSTEM } from "../_shared/prompts/link.v1.ts";
import { runLink } from "./core.ts";

Deno.test("link core uses the model only for ambiguity and preserves the pending decision", async () => {
  const llm = new FakeLlm([{
    matches: [{
      element_id: TEST_ELEMENT_ID,
      entity_id: TEST_ENTITY_ID,
      confidence: 0.7,
      reason: "synthetic",
    }],
  }]);
  const input = {
    dreamId: TEST_ELEMENT_ID,
    volumeId: TEST_ENTITY_ID,
    elements: [{ id: TEST_ELEMENT_ID, type: "person", label: "천문대지기" }],
    entities: [{ id: TEST_ENTITY_ID, type: "person", role_name: "수문장" }],
  };
  const result = await runLink(input, llm);
  assertEquals([
    llm.calls[0].role,
    llm.calls[0].system,
    llm.calls[0].temperature,
    llm.calls[0].maxTokens,
  ], ["link", LINK_SYSTEM, 0, 1000]);
  assertEquals(result.decisions.auto.length, 0);
  assertEquals(result.decisions.pending?.entity_id, TEST_ENTITY_ID);
  assertEquals(result.rows[0].status, "pending");
  assertEquals(result.modelRuns.length, 1);
  const exact = new FakeLlm([]);
  const automatic = await runLink({
    ...input,
    entities: [{ ...input.entities[0], role_name: "천문대지기" }],
  }, exact);
  assertEquals(exact.calls.length, 0);
  assertEquals(automatic.modelRuns.length, 0);
  assertEquals(automatic.decisions.auto.length, 1);
});

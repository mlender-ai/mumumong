import { assertEquals } from "@std/assert";
import { FakeLlm, TEST_ELEMENT_ID } from "../_shared/testing/fake_llm.ts";
import { runValidate } from "./core.ts";

const draft = {
  scene: { placement: "continuation" },
  open_image: "synthetic image",
  passages: [{ origin: "D", text: "구슬이 바닥을 굴렀다.", source_element_ids: [TEST_ELEMENT_ID] }],
};
const base = {
  payload: { draft, clarity: "fragment", adaptation: "balanced" },
  elements: [{ id: TEST_ELEMENT_ID, label: "구슬", salience: "high" as const }],
  registry: [],
  lockedPassages: [],
};

Deno.test("validate core accepts the same draft without calling a model", async () => {
  const llm = new FakeLlm([]);
  const core = await runValidate(base, llm);
  assertEquals(core.outcome.action, "accept");
  assertEquals(core.next.stage, "commit");
  assertEquals(core.nextPayloadPatch.validation_complete, true);
  assertEquals(llm.calls.length, 0);
});

Deno.test("validate core preserves retry to fallback transition and locked-passage discard", async () => {
  const shortOpening = { ...base.payload, is_first_dream: true, target_length: 700 };
  for (const attempt of [0, 1, 2]) {
    const core = await runValidate({
      ...base,
      payload: { ...shortOpening, write_attempt: attempt },
    }, new FakeLlm([]));
    assertEquals(core.next.stage, "write");
    assertEquals(core.next.writeAttempt, attempt + 1);
    assertEquals(core.next.isFallback, attempt === 2);
  }
  const relaxed = await runValidate(
    { ...base, payload: { ...shortOpening, is_fallback: true } },
    new FakeLlm([]),
  );
  assertEquals(relaxed.outcome.profile, "relaxed");
  assertEquals(relaxed.next.stage, "commit");
  const locked = await runValidate(
    { ...base, lockedPassages: [{ text: draft.passages[0].text }] },
    new FakeLlm([]),
  );
  assertEquals(locked.outcome.action, "discard");
  assertEquals(locked.next.terminal, true);
  assertEquals(locked.audit.codes, ["V6"]);
});

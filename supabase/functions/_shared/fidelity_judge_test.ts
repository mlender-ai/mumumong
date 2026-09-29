import { assert, assertEquals, assertRejects, assertThrows } from "@std/assert";
import {
  CONTRADICTION_TYPES,
  differentJudge,
  FIDELITY_SYSTEM,
  type FidelityInput,
  fidelityPass,
  judgeFidelity,
} from "./fidelity_judge.ts";
import type { StructuredCall, StructuredLlmPort } from "./llm_port.ts";
const input: FidelityInput = {
  raw_text: "새로 만든 가짜 꿈에서 나는 은색 주전자를 이웃에게 건넸다.",
  recall_answers: null,
  elements: [{ id: "e1", label: "은색 주전자", salience: "high" }],
  passages: [{
    origin: "D",
    text: "나는 은색 주전자를 이웃에게 건넸다.",
    source_element_ids: ["e1"],
  }, { origin: "C", text: "손끝에 망설임이 남았다." }],
  narrative_voice: "first_person_past",
};
const clean = () => ({
  protagonist_is_recorder: true,
  paragraphs: input.passages.map((p, index) => ({
    index,
    origin: p.origin,
    contradictions: [],
    invented_concrete: [] as string[],
  })),
  missing_high_elements: [] as string[],
});
const models = { writer: "groq:openai/gpt-oss-120b", judge: "groq:openai/gpt-oss-20b" };
function port(
  value: unknown,
  model = "openai/gpt-oss-20b",
  inspect?: (r: StructuredCall) => void,
): StructuredLlmPort {
  return {
    structured<T>(request: StructuredCall) {
      inspect?.(request);
      return Promise.resolve({
        value: value as T,
        model,
        tokensIn: 10,
        tokensOut: 5,
        latencyMs: 1,
      });
    },
  };
}
Deno.test("fidelity uses structured judge role, explicit fact/sensory boundary and metadata-only audit", async () => {
  const result = await judgeFidelity(
    input,
    port(clean(), undefined, (request) => {
      assertEquals(request.role, "judge");
      assertEquals(request.input, input);
      assertEquals(request.temperature, 0);
      assert(request.system.includes("감각적 질감"));
      assert(request.system.includes("C 문단"));
    }),
    models,
  );
  assertEquals(result.pass, true);
  assertEquals(result.modelRuns[0].promptVersion, "fidelity.v1");
  assert(!JSON.stringify(result.modelRuns).includes(input.raw_text));
  assert(FIDELITY_SYSTEM.includes("3인칭"));
});
Deno.test("fidelity pass fails protagonist, each contradiction, D invention and high omissions but not C invention", () => {
  for (const type of CONTRADICTION_TYPES) {
    const finding = clean();
    const changed = {
      ...finding,
      paragraphs: [
        { ...finding.paragraphs[0], contradictions: [{ type, detail: "합성 오류" }] },
        finding.paragraphs[1],
      ],
    };
    assertEquals(fidelityPass(changed), false);
  }
  const finding = clean();
  finding.paragraphs[1].invented_concrete = ["새 창문"];
  assertEquals(fidelityPass(finding), true);
  finding.paragraphs[0].invented_concrete = ["새 색"];
  assertEquals(fidelityPass(finding), false);
  assertEquals(fidelityPass({ ...clean(), protagonist_is_recorder: false }), false);
  assertEquals(fidelityPass({ ...clean(), missing_high_elements: ["e1"] }), false);
});
Deno.test("fidelity rejects omitted/duplicate/out-of-range/origin-flipped paragraphs and unknown omissions", async () => {
  const c = clean();
  for (
    const value of [
      { ...c, paragraphs: [c.paragraphs[0]] },
      { ...c, paragraphs: [c.paragraphs[0], c.paragraphs[0]] },
      { ...c, paragraphs: [c.paragraphs[0], { ...c.paragraphs[1], index: 99 }] },
      { ...c, paragraphs: [c.paragraphs[0], { ...c.paragraphs[1], origin: "D" }] },
      { ...c, missing_high_elements: ["unknown"] },
      { ...c, missing_high_elements: ["e1", "e1"] },
      { ...c, hidden: "extra" },
    ]
  ) await assertRejects(() => judgeFidelity(input, port(value), models));
});
Deno.test("fidelity rejects same model including alias and false response model before using findings", async () => {
  assertThrows(() => differentJudge("openai:gpt-4.1", "openai:gpt-4.1-2025-04-14"));
  let calls = 0;
  await assertRejects(() =>
    judgeFidelity(input, port(clean(), undefined, () => calls++), {
      ...models,
      judge: models.writer,
    })
  );
  assertEquals(calls, 0);
  await assertRejects(() => judgeFidelity(input, port(clean(), "openai/gpt-oss-120b"), models));
  await assertRejects(() => judgeFidelity({ ...input, passages: [] }, port(clean()), models));
});

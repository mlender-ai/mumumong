import { assert, assertEquals, assertFalse, assertStringIncludes, assertThrows } from "@std/assert";
import { sceneDraftSchema } from "../_shared/contract.ts";
import { type PlanV7, planV7Schema } from "../_shared/stage_contracts.ts";
import { assembleSceneDraft, formatProseParseFeedback, parseProse } from "./prose_markers.ts";

const element1 = "00000000-0000-4000-8000-000000000001";
const element2 = "00000000-0000-4000-8000-000000000002";
const entity1 = "00000000-0000-4000-8000-000000000003";

const plan: PlanV7 = {
  placement: "continuation",
  attach_to_scene_id: null,
  scene_title: "종이 열쇠",
  target_length: 900,
  beats: [
    {
      id: "b1",
      kind: "D",
      element_ids: [element1],
      fact: "기록자가 종이 열쇠를 든다.",
      actor: "나",
      action: "든다",
      target: "종이 열쇠",
      recipient: null,
      purpose: null,
      status: "ongoing",
    },
    {
      id: "b2",
      kind: "C",
      element_ids: [],
      fact: "열쇠를 문 쪽으로 가져간다.",
      actor: "나",
      action: "가져간다",
      target: "열쇠",
      recipient: null,
      purpose: null,
      status: null,
    },
    {
      id: "b3",
      kind: "D",
      element_ids: [element2],
      fact: "문틈에서 빛이 나온다.",
      actor: null,
      action: "나온다",
      target: "빛",
      recipient: null,
      purpose: null,
      status: "ongoing",
    },
  ],
  open_image: "문틈에 남은 빛",
  hook_beat: "b1",
  opening_type: "action",
  ending_type: "image",
  new_entities: [{ role_name: "문지기", type: "person", from_element: element1 }],
  used_entities: [entity1],
};

Deno.test("v7 plan has a distinct typed schema without changing the v6 contract", () => {
  assert(planV7Schema.safeParse(plan).success);
  assertFalse(
    planV7Schema.safeParse({
      ...plan,
      beats: [{ ...plan.beats[0], element_ids: [] }],
    }).success,
  );
  assertFalse(planV7Schema.safeParse({ ...plan, scene_title: "x" }).success);
});

Deno.test("marked prose parses and derives source metadata only from plan beats", () => {
  const text = "[[b1]] 종이 열쇠를 들었다.\n\n[[b1]] 손바닥이 서늘했다.\n\n" +
    "[[b2]] 문 쪽으로 걸었다.\n\n[[b3]] 문틈에서 빛이 새어 나왔다.";
  const parsed = parseProse(text, plan.beats);
  assert(parsed.ok);
  assertEquals(parsed.orderDeviation, false);
  const draft = assembleSceneDraft(plan, parsed);
  assert(sceneDraftSchema.safeParse(draft).success);
  assertEquals(draft.passages.map((passage) => passage.origin), ["D", "D", "C", "D"]);
  assertEquals(draft.passages.map((passage) => passage.source_element_ids), [
    [element1],
    [element1],
    [],
    [element2],
  ]);
  assertEquals(draft.passages[2].c_reason, plan.beats[1].fact);
  assertEquals(draft.scene.title, plan.scene_title);
  assertEquals(draft.open_image, plan.open_image);
  assertEquals(draft.new_entities?.[0].from_element, element1);
  assertEquals(draft.used_entities, [entity1]);
});

Deno.test("unmarked preface and nonexistent beat are V1 without echoing model prose", () => {
  const privateLookingProse = "비밀 창고의 유리사다리";
  const parsed = parseProse(
    `${privateLookingProse}\n\n[[b7]] 문을 밀었다.\n\n[[b1]] 열쇠를 들었다.\n\n[[b3]] 빛이 보였다.`,
    plan.beats,
  );
  assertFalse(parsed.ok);
  assertEquals(parsed.issues.filter((issue) => issue.code === "V1").length, 2);
  const feedback = formatProseParseFeedback(parsed.issues);
  assertStringIncludes(feedback, "b7");
  assertFalse(feedback.includes(privateLookingProse));
});

Deno.test("marker-only blocks are discarded and missing D beats become V5", () => {
  const parsed = parseProse("[[b1]]\n\n[[b2]] 잠시 멈췄다.", plan.beats);
  assertFalse(parsed.ok);
  assertEquals(parsed.paragraphs, [{ beatId: "b2", text: "잠시 멈췄다." }]);
  assertEquals(parsed.issues, [{ code: "V5", missingBeatIds: ["b1", "b3"] }]);
  assertStringIncludes(formatProseParseFeedback(parsed.issues), "b1, b3");
});

Deno.test("C beat omission is allowed and beat reorder is recorded, not rejected", () => {
  const parsed = parseProse("[[b3]] 빛이 샜다.\n\n[[b1]] 열쇠를 들었다.", plan.beats);
  assert(parsed.ok);
  assertEquals(parsed.orderDeviation, true);
  assertEquals(parsed.paragraphs.map((paragraph) => paragraph.beatId), ["b3", "b1"]);
});

Deno.test("two beat markers in one paragraph violate V1", () => {
  const parsed = parseProse(
    "[[b1]] 열쇠를 들었다. [[b2]] 걸었다.\n\n[[b3]] 빛이 샜다.",
    plan.beats,
  );
  assertFalse(parsed.ok);
  assert(parsed.issues.some((issue) => issue.code === "V1" && issue.kind === "multiple_markers"));
});

Deno.test("malformed plan beats and invalid assembled draft fail with fixed non-prose errors", () => {
  assertThrows(
    () => parseProse("[[b1]] 문을 열었다.", [plan.beats[1]]),
    Error,
    "invalid_plan_beat_sequence",
  );
  const parsed = parseProse("[[b1]] 열쇠를 들었다.\n\n[[b3]] 빛이 샜다.", plan.beats);
  assert(parsed.ok);
  assertThrows(
    () => assembleSceneDraft({ ...plan, scene_title: "" }, parsed),
    Error,
    "invalid_scene_draft",
  );
});

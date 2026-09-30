import { assert, assertEquals, assertFalse } from "@std/assert";
import { type PlanV7, planV7Schema } from "../_shared/stage_contracts.ts";
import { enforcePlanV7 } from "./plan_v7.ts";

const firstId = "00000000-0000-4000-8000-000000000011";
const secondId = "00000000-0000-4000-8000-000000000012";
const foreignId = "00000000-0000-4000-8000-000000000099";

const plan: PlanV7 = {
  placement: "continuation",
  attach_to_scene_id: null,
  scene_title: "종이 열쇠",
  target_length: 800,
  beats: [
    {
      id: "b1",
      kind: "D",
      element_ids: [firstId],
      fact: "기록자가 종이 열쇠를 쥔다.",
      actor: "나",
      action: "쥔다",
      target: "열쇠",
      recipient: null,
      purpose: null,
      status: "ongoing",
    },
    {
      id: "b2",
      kind: "C",
      element_ids: [],
      fact: "열쇠를 문으로 가져간다.",
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
      element_ids: [secondId],
      fact: "문틈에서 빛이 나온다.",
      actor: null,
      action: "나온다",
      target: "빛",
      recipient: null,
      purpose: null,
      status: "ongoing",
    },
  ],
  open_image: "문틈의 빛",
  hook_beat: "b1",
  opening_type: "action",
  ending_type: "image",
  new_entities: [],
  used_entities: [],
};

const input = {
  clarity: "partial" as const,
  elements: [
    { id: firstId, label: "종이 열쇠", salience: "high" as const, type: "object" },
    { id: secondId, label: "문틈의 빛", salience: "high" as const, type: "sensory" },
  ],
  speechElementIds: new Set<string>(),
  isFirstDream: false,
};

Deno.test("valid v7 plan keeps D provenance and the existing v6 title normalization is reusable", () => {
  const result = enforcePlanV7(plan, input);
  assert(result.ok);
  assertEquals(result.issues, []);
  assertEquals(result.plan.beats[0].element_ids, [firstId]);
  assert(planV7Schema.safeParse(result.plan).success);
});

Deno.test("unknown source IDs are removed but an emptied D beat fails instead of becoming C", () => {
  const result = enforcePlanV7({
    ...plan,
    beats: [{ ...plan.beats[0], element_ids: [foreignId] }, plan.beats[1], plan.beats[2]],
  }, input);
  assertFalse(result.ok);
  assertEquals(result.plan.beats[0].kind, "D");
  assertEquals(result.plan.beats[0].element_ids, []);
  assert(result.issues.some((issue) => issue.code === "D_SOURCE_MISSING"));
  assert(result.issues.some((issue) => issue.code === "HIGH_ELEMENT_MISSING"));
  assertFalse(JSON.stringify(result.issues).includes("종이 열쇠"));
});

Deno.test("first scene requires a D opening beat and b1 hook", () => {
  const result = enforcePlanV7({ ...plan, hook_beat: null }, { ...input, isFirstDream: true });
  assertFalse(result.ok);
  assert(result.issues.some((issue) => issue.code === "FIRST_HOOK"));
  const cFirst = enforcePlanV7({
    ...plan,
    beats: [
      { ...plan.beats[0], kind: "C", element_ids: [] },
      ...plan.beats.slice(1),
    ] as PlanV7["beats"],
  }, { ...input, isFirstDream: true });
  assert(cFirst.issues.some((issue) => issue.code === "FIRST_HOOK"));
});

Deno.test("clarity beat count and b1..bN sequence are checked without changing v10", () => {
  const result = enforcePlanV7(
    { ...plan, beats: [plan.beats[0], { ...plan.beats[2], id: "b4" }] },
    input,
  );
  assertFalse(result.ok);
  assert(result.issues.some((issue) => issue.code === "BEAT_IDS"));
  assert(result.issues.some((issue) => issue.code === "BEAT_COUNT"));
});

Deno.test("dialogue opening without a speech element normalizes to action", () => {
  const noSpeech = enforcePlanV7({ ...plan, opening_type: "dialogue" }, input);
  assertEquals(noSpeech.plan.opening_type, "action");
  const withSpeech = enforcePlanV7({ ...plan, opening_type: "dialogue" }, {
    ...input,
    speechElementIds: new Set([firstId]),
  });
  assertEquals(withSpeech.plan.opening_type, "dialogue");
});

Deno.test("standalone plans have no manuscript beats or attachment", () => {
  const result = enforcePlanV7({
    ...plan,
    placement: "standalone",
    attach_to_scene_id: foreignId,
  }, input);
  assert(result.ok);
  assertEquals(result.plan.beats, []);
  assertEquals(result.plan.attach_to_scene_id, null);
  assertEquals(result.plan.hook_beat, null);
});

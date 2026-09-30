// Q-20 deterministic checks only. The production plan.v6 route is untouched.
import type { Clarity } from "../_shared/contract.ts";
import type { PlanV7 } from "../_shared/stage_contracts.ts";
import { normalizeSceneTitle } from "./plan.ts";

export type PlanV7Issue =
  | { code: "BEAT_IDS" }
  | { code: "BEAT_COUNT"; min: number; max: number; actual: number }
  | { code: "D_SOURCE_MISSING"; beatIds: string[] }
  | { code: "HIGH_ELEMENT_MISSING"; elementIds: string[] }
  | { code: "FIRST_HOOK" };

export type PlanV7Check = {
  plan: PlanV7;
  issues: PlanV7Issue[];
  ok: boolean;
};

export type PlanV7Element = {
  id: string;
  label: string;
  salience: "high" | "mid" | "low";
  type?: string;
};

const beatRange: Record<Clarity, readonly [number, number]> = {
  fragment: [1, 3],
  partial: [3, 6],
  vivid: [5, 9],
};

export function enforcePlanV7(
  output: PlanV7,
  input: {
    clarity: Clarity;
    elements: readonly PlanV7Element[];
    speechElementIds: ReadonlySet<string>;
    isFirstDream: boolean;
    rawText?: string;
  },
): PlanV7Check {
  const validIds = new Set(input.elements.map((element) => element.id));
  const beats = output.beats.map((beat) => ({
    ...beat,
    element_ids: beat.element_ids.filter((id) => validIds.has(id)),
  }));
  const title = normalizeSceneTitle(output.scene_title, input.elements, {
    preferSourceImage: input.isFirstDream,
    rawText: input.rawText,
  });
  const sceneTitle = title.length >= 2 ? title.slice(0, 12) : "낯선 사물";
  const first = beats[0];
  const openingType = output.opening_type === "dialogue" &&
      (!first || !first.element_ids.some((id) => input.speechElementIds.has(id)))
    ? "action"
    : output.opening_type;
  const plan: PlanV7 = { ...output, beats, scene_title: sceneTitle, opening_type: openingType };
  const issues: PlanV7Issue[] = [];

  if (plan.placement === "standalone") {
    return {
      plan: { ...plan, attach_to_scene_id: null, beats: [], hook_beat: null },
      issues,
      ok: true,
    };
  }
  if (beats.some((beat, index) => beat.id !== `b${index + 1}`)) {
    issues.push({ code: "BEAT_IDS" });
  }
  const [min, max] = beatRange[input.clarity];
  if (beats.length < min || beats.length > max) {
    issues.push({ code: "BEAT_COUNT", min, max, actual: beats.length });
  }
  const emptyDreamBeatIds = beats.filter((beat) =>
    beat.kind === "D" && beat.element_ids.length === 0
  ).map((beat) => beat.id);
  if (emptyDreamBeatIds.length) {
    issues.push({ code: "D_SOURCE_MISSING", beatIds: emptyDreamBeatIds });
  }
  const covered = new Set(
    beats.filter((beat) => beat.kind === "D")
      .flatMap((beat) => beat.element_ids),
  );
  const missingHighIds = input.elements.filter((element) =>
    element.salience === "high" && !covered.has(element.id)
  ).map((element) => element.id);
  if (missingHighIds.length) {
    issues.push({ code: "HIGH_ELEMENT_MISSING", elementIds: missingHighIds });
  }
  if (input.isFirstDream && (output.hook_beat !== "b1" || first?.kind !== "D")) {
    issues.push({ code: "FIRST_HOOK" });
  }
  return { plan, issues, ok: issues.length === 0 };
}

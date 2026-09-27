import type { WriteOutput } from "../_shared/stage_contracts.ts";

export const FIRST_SCENE_OPENING_CONTRACT = {
  mode: "serialized_prologue",
  purpose: "turn the recorded dream into an opening scene, not a recap",
  paragraph_range: [7, 9],
  minimum_target_ratio: 0.7,
  passage_length_chars: { dream: [70, 120], adaptation: [70, 100] },
  provenance_mix: { minimum_dream_passages: 5, adaptation_must_be_shorter: true },
  stages: [
    "concrete_hook",
    "protagonist_immediate_want",
    "dream_anomaly",
    "irreversible_choice",
    "consequence_before_goal_completion",
  ],
  ending: "specific unresolved change caused by the protagonist's choice",
} as const;

export function toSceneDraft(
  output: WriteOutput,
  options: {
    validEntityIds?: ReadonlySet<string>;
    isFirstScene?: boolean;
    plannedTitle?: string;
  } = {},
): Record<string, unknown> {
  const validEntityIds = options.validEntityIds;
  const scene = {
    ...output.scene,
    ...(options.isFirstScene ? { kind: "prologue" as const } : {}),
    ...(options.plannedTitle ? { title: options.plannedTitle } : {}),
  };
  return {
    scene,
    passages: output.passages.map((passage) => ({
      origin: passage.origin,
      text: passage.text,
      source_element_ids: passage.source_element_ids,
      ...(passage.c_reason ? { c_reason: passage.c_reason } : {}),
    })),
    new_entities: output.new_entities.map((entity) => ({
      role_name: entity.role_name,
      type: entity.type,
      ...(entity.description ? { description: entity.description } : {}),
      aliases: entity.aliases,
      ...(entity.from_element ? { from_element: entity.from_element } : {}),
    })),
    used_entities: validEntityIds
      ? output.used_entities.filter((id) => validEntityIds.has(id))
      : output.used_entities,
    open_image: output.open_image,
  };
}

export function fallbackTarget(targetLength: number): number {
  return Math.max(1, Math.floor(targetLength * 0.6));
}

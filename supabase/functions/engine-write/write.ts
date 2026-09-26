import type { WriteOutput } from "../_shared/stage_contracts.ts";

export function toSceneDraft(
  output: WriteOutput,
  options: { validEntityIds?: ReadonlySet<string>; isFirstScene?: boolean } = {},
): Record<string, unknown> {
  const validEntityIds = options.validEntityIds;
  return {
    scene: options.isFirstScene ? { ...output.scene, kind: "prologue" } : output.scene,
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

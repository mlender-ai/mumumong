import type { PlanOutput } from "../_shared/stage_contracts.ts";

export function enforcePlan(
  output: PlanOutput,
  input: {
    lengthCap: number;
    cRatioMax: number;
    validSceneIds: ReadonlySet<string>;
    isFirstDream?: boolean;
    firstDreamElementIds?: readonly string[];
  },
): PlanOutput {
  const targetLength = Math.max(1, Math.min(output.target_length, input.lengthCap));
  if (input.isFirstDream && output.placement === "standalone") {
    const elementIds = input.firstDreamElementIds ?? [];
    return {
      ...output,
      placement: "continuation",
      attach_to_scene_id: null,
      beats: elementIds.length > 0
        ? [{ kind: "D", element_ids: [...elementIds], note: "첫 꿈의 핵심 장면" }]
        : output.beats,
      target_length: targetLength,
    };
  }
  if (output.placement === "standalone") {
    return { ...output, attach_to_scene_id: null, beats: [], target_length: targetLength };
  }
  let placement: PlanOutput["placement"] = output.placement;
  let attach = output.attach_to_scene_id;
  if (placement === "fragment_attach" && (!attach || !input.validSceneIds.has(attach))) {
    placement = input.isFirstDream ? "continuation" : "standalone";
    attach = null;
  }
  if (placement === "standalone") {
    return {
      ...output,
      placement,
      attach_to_scene_id: null,
      beats: [],
      target_length: targetLength,
    };
  }

  const maxC = Math.floor(output.beats.length * input.cRatioMax);
  let keptC = 0;
  const beats = output.beats.filter((beat) => {
    if (beat.kind === "D") return true;
    keptC += 1;
    return keptC <= maxC;
  });
  return { ...output, placement, attach_to_scene_id: attach, beats, target_length: targetLength };
}

export function nextSceneOrderKey(existing: readonly string[]): string {
  const largest = existing.reduce((max, value) => {
    const match = /^s(\d+)$/u.exec(value);
    return Math.max(max, match ? Number(match[1]) : 0);
  }, 0);
  return `s${String(largest + 1).padStart(4, "0")}`;
}

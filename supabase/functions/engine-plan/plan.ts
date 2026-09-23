import type { PlanOutput } from "../_shared/stage_contracts.ts";

export function enforcePlan(
  output: PlanOutput,
  input: { lengthCap: number; cRatioMax: number; validSceneIds: ReadonlySet<string> },
): PlanOutput {
  const targetLength = Math.max(1, Math.min(output.target_length, input.lengthCap));
  if (output.placement === "standalone") {
    return { ...output, attach_to_scene_id: null, beats: [], target_length: targetLength };
  }
  let placement: PlanOutput["placement"] = output.placement;
  let attach = output.attach_to_scene_id;
  if (placement === "fragment_attach" && (!attach || !input.validSceneIds.has(attach))) {
    placement = "standalone";
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

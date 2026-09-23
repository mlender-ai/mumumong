import type { RememberOutput } from "../_shared/stage_contracts.ts";

export function normalizeMemory(output: RememberOutput): RememberOutput {
  const open = output.open_threads.filter((thread) => thread.status === "open").slice(0, 5);
  const closed = output.open_threads.filter((thread) => thread.status === "closed");
  const remaining = Math.max(0, 5 - open.length);
  return {
    ...output,
    story_so_far: [...output.story_so_far].slice(0, 1500).join(""),
    open_threads: [...open, ...(remaining === 0 ? [] : closed.slice(-remaining))],
  };
}

export function blendGenreProfile(
  previous: Readonly<Record<string, number>>,
  scene: Readonly<Record<string, number>>,
): Record<string, number> {
  const keys = new Set([...Object.keys(previous), ...Object.keys(scene)]);
  return Object.fromEntries([...keys].map((key) => [
    key,
    Number(((previous[key] ?? 0) * 0.7 + (scene[key] ?? 0) * 0.3).toFixed(4)),
  ]));
}

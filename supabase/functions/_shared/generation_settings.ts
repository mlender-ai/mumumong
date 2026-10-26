import type { VolumeContext } from "./stage_context.ts";

// Transport-only preference pinning. Frozen prompts/quality rules are unchanged.
export function pinnedGenerationVolume(
  volume: VolumeContext,
  payload: Record<string, unknown>,
): VolumeContext {
  const raw = payload.generation_settings;
  if (raw === undefined) return volume; // Existing eval/baseline input contract.
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    throw new Error("invalid_settings_snapshot");
  }
  const s = raw as Record<string, unknown>;
  if (
    !Number.isSafeInteger(s.version) || (s.version as number) < 1 ||
    !["faithful", "balanced", "free"].includes(String(s.adaptation)) ||
    !["plain", "lyrical", "cinematic"].includes(String(s.style)) ||
    !["first_person_past", "third_person_past"].includes(String(s.narrative_voice)) ||
    (payload.generation_settings_version !== undefined &&
      payload.generation_settings_version !== s.version)
  ) {
    throw new Error("invalid_settings_snapshot");
  }
  return {
    ...volume,
    adaptation: s.adaptation as VolumeContext["adaptation"],
    style: s.style as VolumeContext["style"],
    narrative_voice: s.narrative_voice as VolumeContext["narrative_voice"],
  };
}

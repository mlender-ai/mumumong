import { CORE_PROSE_METRICS, type ProseMetrics } from "./prose_lint.ts";
import { REFERENCE_PROFILE, type ReferenceProfile } from "./reference_profile.ts";

export function referenceProximity(
  metrics: ProseMetrics,
  profile: ReferenceProfile | null = REFERENCE_PROFILE,
) {
  if (!profile?.eligible) return null;
  const byMetric = Object.fromEntries(CORE_PROSE_METRICS.map((key) => {
    const band = profile.positive.opening[key];
    const value = metrics[key];
    if (
      !band || !Number.isFinite(value) || !Number.isFinite(band.p25) ||
      !Number.isFinite(band.p75) || band.p25 > band.p75
    ) {
      throw new Error("reference_profile_invalid");
    }
    return [key, value >= band.p25 && value <= band.p75];
  })) as Record<(typeof CORE_PROSE_METRICS)[number], boolean>;
  return { inBand: Object.values(byMetric).filter(Boolean).length, of: 10 as const, byMetric };
}

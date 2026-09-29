import type { ProseMetrics } from "./prose_lint.ts";

export type MetricBands = Record<
  keyof ProseMetrics,
  { p10: number; p25: number; p50: number; p75: number; p90: number }
>;
export interface ReferenceGroup {
  count: number;
  opening: MetricBands;
  ending: MetricBands;
  labels: {
    opening_type: Record<string, number>;
    ending_type: Record<string, number>;
    first_event_para_p50: number;
    reveal_by_2000: Record<string, number>;
  };
}
export interface ReferenceProfile {
  version: 1;
  eligible: boolean;
  source_sha256: string;
  positive: ReferenceGroup;
  control: ReferenceGroup | null;
  voices: { first: ReferenceGroup | null; third: ReferenceGroup | null };
  median_deltas: {
    opening: Record<keyof ProseMetrics, number>;
    ending: Record<keyof ProseMetrics, number>;
  } | null;
}
// No invented reference bands. Q-09 actual data + direct user labels must precede publication.
export const REFERENCE_PROFILE: ReferenceProfile | null = null;

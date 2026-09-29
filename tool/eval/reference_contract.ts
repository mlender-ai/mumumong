import { z } from "zod";
import { lintProse, type ProseMetrics } from "../../supabase/functions/_shared/prose_lint.ts";
import { EvalError } from "./config.ts";
import type { ReferenceProfile } from "../../supabase/functions/_shared/reference_profile.ts";

export const OPENING_TYPES = [
  "dialogue",
  "action",
  "situation",
  "sense",
  "monologue",
  "explanation",
] as const;
export const ENDING_TYPES = [
  "new_presence",
  "new_information",
  "before_crisis",
  "before_choice",
  "dialogue",
  "image",
] as const;
export const REVEAL_TYPES = ["circumstance", "goal_problem", "anomaly"] as const;
export const referenceLabelSchema = z.object({
  opening_type: z.enum(OPENING_TYPES),
  first_event_para: z.number().int().positive(),
  reveal_by_2000: z.array(z.enum(REVEAL_TYPES)).max(3),
  ending_type: z.enum(ENDING_TYPES),
  hook_note: z.string().max(240).default(""),
}).strict();
export const workSchema = z.object({
  id: z.string().regex(/^[A-Za-z0-9_-]{1,80}$/),
  group: z.enum(["positive", "control"]),
  genre: z.enum(["현판", "로판", "판타지", "로맨스", "미스터리/호러", "기타"]),
  voice: z.enum(["first", "third"]),
  opening: z.string().min(1),
  ending: z.string().min(1),
  next_opening: z.string().optional(),
  synthetic: z.boolean().default(false),
  labels: referenceLabelSchema.optional(),
}).strict();
export type ReferenceWork = z.infer<typeof workSchema>;
export const proseMetricsSchema = z.object(
  Object.fromEntries(
    Object.keys(lintProse([], "first_person_past")).map((
      key,
    ) => [key, z.number().finite().nonnegative()]),
  ),
).strict() as unknown as z.ZodType<ProseMetrics>;
const keys = Object.keys(lintProse([], "first_person_past"));
const bands = z.object({
  p10: z.number().finite().nonnegative(),
  p25: z.number().finite().nonnegative(),
  p50: z.number().finite().nonnegative(),
  p75: z.number().finite().nonnegative(),
  p90: z.number().finite().nonnegative(),
}).strict().refine((v) => v.p10 <= v.p25 && v.p25 <= v.p50 && v.p50 <= v.p75 && v.p75 <= v.p90);
const metricBands = z.object(Object.fromEntries(keys.map((k) => [k, bands]))).strict();
const fractions = (choices: readonly string[]) =>
  z.object(Object.fromEntries(choices.map((k) => [k, z.number().finite().min(0).max(1)]))).strict();
const referenceGroupSchema = z.object({
  count: z.number().int().positive(),
  opening: metricBands,
  ending: metricBands,
  labels: z.object({
    opening_type: fractions(OPENING_TYPES),
    ending_type: fractions(ENDING_TYPES),
    first_event_para_p50: z.number().int().nonnegative(),
    reveal_by_2000: fractions(REVEAL_TYPES),
  }).strict(),
}).strict();
const deltas = z.object(Object.fromEntries(keys.map((k) => [k, z.number().finite()]))).strict();
export const referenceProfileSchema = z.object({
  version: z.literal(1),
  eligible: z.boolean(),
  source_sha256: z.string().regex(/^[a-f0-9]{64}$/),
  positive: referenceGroupSchema,
  control: referenceGroupSchema.nullable(),
  voices: z.object({
    first: referenceGroupSchema.nullable(),
    third: referenceGroupSchema.nullable(),
  }).strict(),
  median_deltas: z.object({ opening: deltas, ending: deltas }).strict().nullable(),
}).strict().refine((p) =>
  (p.voices.first?.count ?? 0) + (p.voices.third?.count ?? 0) === p.positive.count &&
  (!p.eligible ||
    p.positive.count >= 25 && (p.voices.first?.count ?? 0) >= Math.ceil(p.positive.count / 2))
) as unknown as z.ZodType<ReferenceProfile>;
export const referenceParagraphs = (text: string) =>
  text.split(/\r?\n+/).map((p) => p.trim()).filter(Boolean);
export function parseWorks(text: string): ReferenceWork[] {
  try {
    const rows = text.trim().split(/\r?\n/).map((line) => workSchema.parse(JSON.parse(line)));
    if (
      !rows.length || new Set(rows.map((r) => r.id)).size !== rows.length ||
      rows.some((r) =>
        r.labels && r.labels.first_event_para > referenceParagraphs(r.opening).length
      )
    ) throw new Error();
    return rows;
  } catch {
    throw new EvalError("REFERENCE_INVALID");
  }
}

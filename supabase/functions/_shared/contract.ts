// Engine contract shared by the validate (E5) and commit (E6) stages.
//
// The E4 output schema mirrors PDR §24. Budgets and length caps mirror PDR §17.
// Nothing here calls a model, so both stages stay deterministic and testable.

import { z } from "zod";

export const PASSAGE_ORIGINS = ["D", "C", "U"] as const;
export type PassageOrigin = (typeof PASSAGE_ORIGINS)[number];

export const PLACEMENT_KINDS = [
  "continuation",
  "motif",
  "interlude",
  "fragment_attach",
  "standalone",
] as const;
export type PlacementKind = (typeof PLACEMENT_KINDS)[number];

export const SCENE_KINDS = ["prologue", "dream", "interlude", "ending"] as const;

export const CLARITIES = ["fragment", "partial", "vivid"] as const;
export type Clarity = (typeof CLARITIES)[number];

export const ADAPTATION_LEVELS = ["faithful", "balanced", "free"] as const;
export type AdaptationLevel = (typeof ADAPTATION_LEVELS)[number];

export const SALIENCES = ["high", "mid", "low"] as const;
export type Salience = (typeof SALIENCES)[number];

/// E4 emits only engine passages. A `U` passage in the output is a V6 violation,
/// so the schema accepts it structurally and lets V6 reject it with the right code.
const passageSchema = z.object({
  id: z.string().uuid().optional(),
  order_key: z.string().min(1).optional(),
  origin: z.enum(PASSAGE_ORIGINS),
  text: z.string().min(1),
  source_element_ids: z.array(z.string().uuid()).optional(),
  c_reason: z.string().min(1).optional(),
});

const newEntitySchema = z.object({
  role_name: z.string().min(1),
  type: z.string().min(1).optional(),
  description: z.string().min(1).optional(),
  aliases: z.array(z.string().min(1)).optional(),
  from_element: z.string().uuid().optional(),
});

export const sceneDraftSchema = z.object({
  scene: z.object({
    id: z.string().uuid().optional(),
    title: z.string().min(1).optional(),
    kind: z.enum(SCENE_KINDS).optional(),
    placement: z.enum(PLACEMENT_KINDS),
    open_image: z.string().min(1).optional(),
  }),
  passages: z.array(passageSchema).min(1),
  new_entities: z.array(newEntitySchema).optional(),
  used_entities: z.array(z.string().uuid()).optional(),
  // WO-E4 requires an open image so the scene never closes.
  open_image: z.string().min(1),
});

export type SceneDraft = z.infer<typeof sceneDraftSchema>;
export type DraftPassage = z.infer<typeof passageSchema>;
export type NewEntityDraft = z.infer<typeof newEntitySchema>;

export interface DreamElement {
  id: string;
  label: string;
  salience: Salience;
}

export interface RegistryEntity {
  id: string;
  role_name: string;
  aliases?: string[];
}

export interface AdaptationBudget {
  /// V2 ceiling: C characters over total characters.
  readonly cRatioMax: number;
  /// V4 multiplier applied to the clarity length cap.
  readonly lengthMultiplier: number;
  /// V3 policy for a named entity that resolves to neither today's elements
  /// nor the volume registry.
  readonly unresolvedNamedEntity: "forbidden" | "c_tagged_only";
}

export const ADAPTATION_BUDGETS: Readonly<Record<AdaptationLevel, AdaptationBudget>> = {
  faithful: { cRatioMax: 0.15, lengthMultiplier: 1.0, unresolvedNamedEntity: "forbidden" },
  balanced: { cRatioMax: 0.35, lengthMultiplier: 1.3, unresolvedNamedEntity: "forbidden" },
  free: { cRatioMax: 0.6, lengthMultiplier: 1.6, unresolvedNamedEntity: "c_tagged_only" },
};

/// Upper bound of the PDR §17 per-clarity range, before the adaptation multiplier.
export const CLARITY_LENGTH_CAP: Readonly<Record<Clarity, number>> = {
  fragment: 700,
  partial: 1800,
  vivid: 3500,
};

export function lengthCapFor(clarity: Clarity, level: AdaptationLevel): number {
  return Math.floor(CLARITY_LENGTH_CAP[clarity] * ADAPTATION_BUDGETS[level].lengthMultiplier);
}

/// Boundary parsers. A handler must never cast an untrusted payload field to one
/// of these unions: an unknown `clarity` would make the V4 cap `NaN`, which
/// silently passes every draft instead of failing loudly.
export const claritySchema = z.enum(CLARITIES);
export const adaptationSchema = z.enum(ADAPTATION_LEVELS);
export const placementSchema = z.enum(PLACEMENT_KINDS);

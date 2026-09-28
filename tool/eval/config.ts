import { z } from "zod";
import type { Clarity } from "../../supabase/functions/_shared/contract.ts";
import { EXTRACT_PROMPT_VERSION } from "../../supabase/functions/_shared/prompts/extract.v1.ts";
import { LINK_PROMPT_VERSION } from "../../supabase/functions/_shared/prompts/link.v1.ts";
import { PLAN_PROMPT_VERSION } from "../../supabase/functions/_shared/prompts/plan.v1.ts";
import { WRITE_PROMPT_VERSION } from "../../supabase/functions/_shared/prompts/write.v1.ts";
import { REMEMBER_PROMPT_VERSION } from "../../supabase/functions/_shared/prompts/remember.v1.ts";
import { VALIDATE_PROMPT_VERSION } from "../../supabase/functions/engine-validate/core.ts";

export class EvalError extends Error {
  constructor(readonly code: string) {
    super(code);
  }
}

export const settingsSchema = z.object({
  style: z.enum(["plain", "lyrical", "cinematic"]),
  adaptation: z.enum(["faithful", "balanced", "free"]),
  narrative_voice: z.enum(["first_person_past", "third_person_past"]),
}).strict();
const model = z.string().regex(/^groq:[A-Za-z0-9_./-]{1,80}$/);
export const configSchema = z.object({
  label: z.string().regex(/^[A-Za-z0-9_-]{1,48}$/),
  engine_version: z.literal("v10"),
  models: z.object({
    extract: model,
    link: model,
    plan: model,
    write: model,
    write_aux: model,
    polish: model,
    remember: model,
    judge: z.null(),
  }).strict(),
  settings: settingsSchema,
}).strict();
export type RunConfig = z.infer<typeof configSchema>;
export type Settings = z.infer<typeof settingsSchema>;
export type EvalSet = "dev" | "holdout" | "fixtures" | "sentinel";
export interface CorpusDream {
  raw_text: string;
  recall_answers?: Record<string, string>;
  expected_clarity: Clarity | null;
}
export type CorpusCase = {
  id: string;
  set: "dev" | "holdout" | "sentinel";
  settings: Partial<Settings> | null;
} & ({ kind: "single" } & CorpusDream | { kind: "sequence"; dreams: CorpusDream[] });

export const PROMPT_VERSIONS = {
  extract: EXTRACT_PROMPT_VERSION,
  link: LINK_PROMPT_VERSION,
  plan: PLAN_PROMPT_VERSION,
  write: WRITE_PROMPT_VERSION,
  write_aux: WRITE_PROMPT_VERSION,
  polish: WRITE_PROMPT_VERSION,
  validate: VALIDATE_PROMPT_VERSION,
  remember: REMEMBER_PROMPT_VERSION,
  // The two opening helpers have no independent version constants in v10.
  opening_expansion: "edfc13c",
  opening_polish: "edfc13c",
} as const;

export async function digest(value: string): Promise<string> {
  const bytes = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(bytes)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

// Never forward arbitrary exception messages, Zod details or provider bodies.
export function failureCode(error: unknown): string {
  if (error instanceof EvalError) return error.code;
  if (error instanceof z.ZodError) return "STAGE_SCHEMA_INVALID";
  return "STAGE_FAILED";
}

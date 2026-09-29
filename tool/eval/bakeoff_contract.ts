import baseline from "../../eval/configs/baseline_v10.json" with { type: "json" };
import { resolveModel } from "../../supabase/functions/_shared/llm/registry.ts";
import { EvalError, type RunConfig } from "./config.ts";

export const WRITER_ROLES = ["write", "write_aux", "polish"] as const;
const FIXED_ROLES = ["extract", "link", "plan", "remember", "judge"] as const;

// Model separation prevents self-judging; provider separation is a distinct reporting caveat.
// This annotation does not change the frozen Q-series gate thresholds.
export function fidelityEvidence(models: Record<string, string | null>, rate: number | null) {
  let sameProvider: boolean | null = null;
  try {
    const judge = resolveModel(models.judge!).provider;
    const writers = WRITER_ROLES.map((role) => resolveModel(models[role]!).provider);
    sameProvider = writers.includes(judge);
  } catch {
    // Unknown or missing identities must not claim independent evidence.
  }
  return {
    rate,
    measured: rate !== null,
    same_provider: sameProvider,
    label: sameProvider === true ? "참고용" : sameProvider === false ? "교차 공급사" : "미검증",
  };
}

export function canonicalModel(name: string): string {
  try {
    const model = resolveModel(name);
    return `${model.provider}:${model.id}`;
  } catch {
    throw new EvalError("MODEL_NOT_REGISTERED");
  }
}

export function baselineModels(models: Record<string, string | null>): boolean {
  try {
    return Object.keys(models).length === Object.keys(baseline.models).length &&
      Object.entries(baseline.models).every(([role, value]) =>
        role === "judge"
          ? !!models.judge &&
            WRITER_ROLES.every((r) => canonicalModel(models.judge!) !== canonicalModel(models[r]!))
          : !!models[role] && canonicalModel(models[role]!) === canonicalModel(value!)
      );
  } catch {
    return false;
  }
}

// Q-10 varies the entire prose-producing group, not just the main write call.
// A shared, independent judge and all non-prose roles remain fixed.
export function q10ModelsMatch(
  A: Record<string, string | null>,
  B: Record<string, string | null>,
): boolean {
  try {
    if (!baselineModels(A) || Object.keys(B).length !== Object.keys(A).length) return false;
    const candidate = canonicalModel(B.write!);
    return candidate !== canonicalModel(A.write!) &&
      WRITER_ROLES.every((role) => canonicalModel(B[role]!) === candidate) &&
      FIXED_ROLES.every((role) => canonicalModel(A[role]!) === canonicalModel(B[role]!)) &&
      candidate !== canonicalModel(B.judge!);
  } catch {
    return false;
  }
}

export function candidateConfig(base: RunConfig, label: string, model: string): RunConfig {
  const writer = canonicalModel(model);
  const candidate = {
    ...base,
    label: `bakeoff_${label}`,
    models: { ...base.models, write: writer, write_aux: writer, polish: writer },
  };
  if (!q10ModelsMatch(base.models, candidate.models)) {
    throw new EvalError("Q10_MODEL_COMPARISON_INVALID");
  }
  return candidate;
}

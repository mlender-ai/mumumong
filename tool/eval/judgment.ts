import { z } from "zod";
import { digest, EvalError } from "./config.ts";

export const WIN_REASONS = ["natural", "faithful", "engaging"] as const;
export const LOSS_PROBLEMS = ["ai_translation", "fact_error", "dragging", "too_short"] as const;
const id = z.string().regex(/^[A-Za-z0-9_-]{1,80}$/);
export const passageSchema = z.object({
  text: z.string().min(1),
  origin: z.enum(["D", "C", "U"]).optional(),
  source_element_ids: z.array(z.string()).optional(),
});
export const sceneSchema = z.object({
  title: z.string().nullable().optional(),
  passages: z.array(passageSchema),
});
export type Scene = z.infer<typeof sceneSchema>;
export const voteSchema = z.object({
  winner: z.enum(["A", "B", "tie"]),
  automatic: z.enum(["none", "A_failed", "B_failed", "both_failed"]),
  not_ready: z.object({ A: z.boolean().nullable(), B: z.boolean().nullable() }).strict(),
  reasons: z.array(z.enum(WIN_REASONS)).max(3),
  problems: z.array(z.enum(LOSS_PROBLEMS)).max(4),
}).strict();
export type Vote = z.infer<typeof voteSchema>;
const auditVote = z.object({
  choice: z.enum(["agree", "disagree", "keep", "reject"]),
  annotations: z.array(
    z.object({
      paragraph: z.number().int().nonnegative(),
      labels: z.array(z.string().min(1).max(40)).max(12),
      note: z.string().max(240),
    }).strict(),
  ).max(1000).optional(),
}).strict();
export type AuditVote = z.infer<typeof auditVote>;
const metric = z.number().finite().nonnegative();
export const runStatsSchema = z.object({
  engine_version: z.enum(["v10", "v11"]),
  models: z.record(z.string().nullable()),
  settings_sha256: z.string(),
  prompt_versions: z.record(z.string()),
  cases: z.number().int().positive(),
  failures: z.number().int().nonnegative(),
  dream_count: z.number().int().nonnegative(),
  mean_cost_krw: metric.nullable(),
  max_cost_krw: metric.nullable(),
  p95_ms: metric.nullable(),
  provenance_errors: metric.nullable(),
  v2_compliance: metric.max(1).nullable(),
  fidelity_rate: metric.max(1).nullable(),
  reference_proximity: metric.max(10).nullable(),
}).strict();
export type RunStats = z.infer<typeof runStatsSchema>;
export const judgmentSchema = z.object({
  version: z.literal(1),
  mode: z.enum(["ab", "pro", "fidelity-audit", "pick", "annotate"]),
  seed: z.string().regex(/^[a-f0-9]{32}$/),
  revision: z.number().int().nonnegative(),
  identity: z.string().regex(/^[a-f0-9]{64}$/),
  set: z.enum(["dev", "fixtures", "sentinel", "holdout", "auxiliary"]),
  gate_eligible: z.boolean(),
  stats: z.object({ A: runStatsSchema, B: runStatsSchema }).nullable(),
  items: z.array(
    z.object({
      id,
      kind: z.enum(["single", "sequence", "audit", "candidate", "reference"]),
      clarity: z.enum(["fragment", "partial", "vivid", "mixed", "unclassified"]),
      vote: voteSchema.nullable(),
      audit: auditVote.nullable(),
    }).strict(),
  ).min(1).max(10000),
}).strict();
export type Judgment = z.infer<typeof judgmentSchema>;
export type JudgmentItem = Judgment["items"][number];

export function seed(): string {
  return [...crypto.getRandomValues(new Uint8Array(16))].map((n) => n.toString(16).padStart(2, "0"))
    .join("");
}
export async function leftSide(seed: string, id: string): Promise<"A" | "B"> {
  return parseInt((await digest(`${seed}:${id}`)).slice(0, 8), 16) % 2 ? "A" : "B";
}
export async function atomicSave(path: URL, judgment: Judgment) {
  judgmentSchema.parse(judgment);
  const temporary = new URL(`${path.href}.${crypto.randomUUID()}.tmp`);
  try {
    await Deno.writeTextFile(temporary, JSON.stringify(judgment, null, 2) + "\n", {
      mode: 0o600,
      createNew: true,
    });
    await Deno.rename(temporary, path);
  } finally {
    try {
      await Deno.remove(temporary);
    } catch { /* Already renamed or never created. */ }
  }
}

// Reject path traversal and symlink escapes. Only ignored local evaluation directories are accepted.
export async function privatePath(
  root: URL,
  relative: string,
  folder: string,
  directory = false,
): Promise<URL> {
  if (
    !relative.startsWith(`eval/${folder}/`) || relative.includes("\\") ||
    relative.split("/").some((part) => part === ".." || part === ".")
  ) throw new EvalError("PRIVATE_PATH_REQUIRED");
  const path = new URL(relative.replace(/\/$/, "") + (directory ? "/" : ""), root);
  try {
    const [base, target] = await Promise.all([
      Deno.realPath(new URL(`eval/${folder}/`, root)),
      Deno.realPath(path),
    ]);
    if (!target.startsWith(base + "/")) throw new EvalError("PRIVATE_PATH_REQUIRED");
  } catch (error) {
    if (error instanceof EvalError) throw error;
    throw new EvalError("PRIVATE_INPUT_UNREADABLE");
  }
  return path;
}

export function safeCode(error: unknown): string {
  return error instanceof EvalError ? error.code : "JUDGMENT_FAILED";
}

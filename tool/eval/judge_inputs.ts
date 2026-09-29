import { z } from "zod";
import { ADAPTATION_BUDGETS } from "../../supabase/functions/_shared/contract.ts";
import { type CorpusCase, digest, EvalError } from "./config.ts";
import { validateCorpusTexts } from "./validate_corpus.ts";
import {
  type Judgment,
  type JudgmentItem,
  privatePath,
  type RunStats,
  type Scene,
  sceneSchema,
  seed,
} from "./judgment.ts";

const ROOT = new URL("../../", import.meta.url);
const hash = z.string().regex(/^[a-f0-9]{64}$/);
const manifestSchema = z.object({
  engine_version: z.enum(["v10", "v11"]),
  models: z.record(z.string().nullable()),
  settings: z.object({ adaptation: z.enum(["faithful", "balanced", "free"]) }).passthrough(),
  prompt_versions: z.record(z.string()),
  identity: z.object({
    set: z.enum(["dev", "fixtures", "sentinel", "holdout"]),
    corpus_sha256: hash,
    fixture_llm: z.boolean(),
    source_sha256: hash.optional(),
  }),
});
const dreamSchema = z.object({
  expected_clarity: z.enum(["fragment", "partial", "vivid"]).nullable(),
  stages: z.array(z.object({ stage: z.string(), output: z.unknown() })),
  scene: sceneSchema.nullable(),
  status: z.enum(["success", "failed"]),
  cost_krw: z.number().finite().nonnegative(),
  cost_complete: z.boolean(),
  latency_ms: z.number().finite().nonnegative(),
});
const resultSchema = z.object({
  id: z.string().regex(/^[A-Za-z0-9]+$/),
  kind: z.enum(["single", "sequence"]),
  status: z.enum(["success", "failed"]),
  dreams: z.array(dreamSchema).max(4),
  scenes: z.array(sceneSchema).max(4),
});
type Result = z.infer<typeof resultSchema>;
const qualitySchema = z.object({
  results_sha256: hash,
  case_ids: z.array(z.string()).min(1),
  fidelity: z.object({ passed: z.number().int().nonnegative(), total: z.number().int().positive() })
    .strict().optional(),
  reference_proximity: z.number().int().min(0).max(10).optional(),
  fidelity_calibration: z.object({ judge_model: z.string(), certificate_sha256: hash }).strict()
    .optional(),
}).strict();

export interface DisplayItem {
  id: string;
  originals: string[];
  A?: Scene[];
  B?: Scene[];
  text?: string;
  paragraphs?: string[];
  labels?: string[];
  reference_form?: { opening_paragraphs: number; synthetic: boolean };
}
export interface Prepared {
  judgment: Judgment;
  display: Map<string, DisplayItem>;
  nameA: string;
  nameB?: string;
}
function clarity(record: CorpusCase): JudgmentItem["clarity"] {
  if (record.kind === "single") return record.expected_clarity ?? "unclassified";
  const values = new Set(record.dreams.map((dream) => dream.expected_clarity));
  return values.size === 1 ? record.dreams[0].expected_clarity ?? "unclassified" : "mixed";
}
async function loadRun(path: string, root: URL) {
  const directory = await privatePath(root, path, "runs", true);
  try {
    const manifestText = await Deno.readTextFile(new URL("config.json", directory));
    const manifest = manifestSchema.parse(JSON.parse(manifestText));
    // Do not open holdout inputs until Q-32 explicitly unlocks this tooling.
    if (manifest.identity.set === "holdout") throw new EvalError("HOLDOUT_LOCKED_UNTIL_Q32");
    const text = await Deno.readTextFile(new URL("results.jsonl", directory));
    const results = text.trim().split(/\r?\n/).map((line) => resultSchema.parse(JSON.parse(line)));
    if (results.length === 0 || new Set(results.map((r) => r.id)).size !== results.length) {
      throw new EvalError("RUN_INVALID");
    }
    let quality: z.infer<typeof qualitySchema> | undefined;
    try {
      quality = qualitySchema.parse(
        JSON.parse(await Deno.readTextFile(new URL("quality_metrics.json", directory))),
      );
      if (
        quality.results_sha256 !== await digest(text) ||
        quality.fidelity && quality.fidelity.passed > quality.fidelity.total
      ) throw new EvalError("QUALITY_METRICS_INVALID");
    } catch (error) {
      if (!(error instanceof Deno.errors.NotFound)) throw new EvalError("QUALITY_METRICS_INVALID");
    }
    return {
      manifest,
      results,
      quality,
      // Later Q-07/Q-09 measurements must not invalidate already collected blind votes.
      fingerprint: await digest(manifestText + text),
    };
  } catch (error) {
    if (error instanceof EvalError) throw error;
    throw new EvalError("RUN_INVALID");
  }
}

async function stats(
  run: Awaited<ReturnType<typeof loadRun>>,
  results: Result[],
  root: URL,
): Promise<RunStats> {
  const dreams = results.flatMap((result) => result.dreams);
  const latencies = dreams.map((d) => d.latency_ms).sort((a, b) => a - b);
  let errors = 0, checked = 0, compliant = 0, finalCount = 0;
  for (const dream of dreams) {
    if (!dream.scene) continue;
    const extraction = dream.stages.find((stage) => stage.stage === "extract")?.output as {
      rows?: { id: string }[];
    } | undefined;
    if (
      !Array.isArray(extraction?.rows) || extraction.rows.some((row) => typeof row.id !== "string")
    ) continue;
    checked++;
    const ids = new Set(extraction.rows.map((row) => row.id));
    let total = 0, adapted = 0;
    for (const passage of dream.scene.passages) {
      const length = [...passage.text].length;
      total += length;
      if (passage.origin === "C") adapted += length;
      if (
        !passage.origin ||
        passage.origin === "D" && !passage.source_element_ids?.length ||
        passage.source_element_ids?.some((id) => !ids.has(id))
      ) errors++;
    }
    finalCount++;
    if (
      total > 0 && adapted / total <= ADAPTATION_BUDGETS[run.manifest.settings.adaptation].cRatioMax
    ) compliant++;
  }
  const full = run.quality &&
    JSON.stringify([...run.quality.case_ids].sort()) ===
      JSON.stringify(results.map((r) => r.id).sort());
  const proof = run.quality?.fidelity_calibration;
  const currentProof = full && proof && run.manifest.models.judge
    ? await (await import("./measurements.ts")).calibrationProof(run.manifest.models.judge, root)
    : null;
  const verifiedFidelity = proof && currentProof &&
    proof.judge_model === currentProof.judge_model &&
    proof.certificate_sha256 === currentProof.certificate_sha256;
  return digest(JSON.stringify(run.manifest.settings)).then((settings_sha256) => ({
    engine_version: run.manifest.engine_version,
    models: run.manifest.models,
    settings_sha256,
    prompt_versions: run.manifest.prompt_versions,
    ...(run.manifest.identity.source_sha256
      ? { source_sha256: run.manifest.identity.source_sha256 }
      : {}),
    cases: results.length,
    failures: results.filter((r) => r.status === "failed").length,
    dream_count: dreams.length,
    mean_cost_krw: dreams.length && dreams.every((d) => d.cost_complete)
      ? dreams.reduce((sum, d) => sum + d.cost_krw, 0) / dreams.length
      : null,
    max_cost_krw: dreams.length && dreams.every((d) => d.cost_complete)
      ? Math.max(...dreams.map((d) => d.cost_krw))
      : null,
    p95_ms: latencies.length ? latencies[Math.ceil(latencies.length * 0.95) - 1] : null,
    provenance_errors: checked === dreams.filter((d) => d.scene).length && checked > 0
      ? errors
      : null,
    v2_compliance: finalCount > 0 && checked === dreams.filter((d) => d.scene).length
      ? compliant / finalCount
      : null,
    fidelity_rate: full && verifiedFidelity && run.quality?.fidelity
      ? run.quality.fidelity.passed / run.quality.fidelity.total
      : null,
    reference_proximity: full ? run.quality?.reference_proximity ?? null : null,
  }));
}

export async function prepareAB(a: string, b: string, root = ROOT): Promise<Prepared> {
  if (a.replace(/\/$/, "") === b.replace(/\/$/, "")) throw new EvalError("SAME_RUN");
  const [A, B] = await Promise.all([loadRun(a, root), loadRun(b, root)]);
  const set = A.manifest.identity.set;
  if (
    set !== B.manifest.identity.set ||
    A.manifest.identity.corpus_sha256 !== B.manifest.identity.corpus_sha256
  ) throw new EvalError("CORPUS_MISMATCH");
  let corpus: CorpusCase[];
  try {
    const text = await Deno.readTextFile(
      new URL(set === "fixtures" ? "eval/fixtures/sample.jsonl" : `eval/corpus/${set}.jsonl`, root),
    );
    if (
      await digest(text) !== A.manifest.identity.corpus_sha256 ||
      validateCorpusTexts([{ text, expectedSet: set === "fixtures" ? "dev" : set }]).issues.length
    ) throw new EvalError("CORPUS_MISMATCH");
    corpus = text.trim().split(/\r?\n/).map((line) => JSON.parse(line));
  } catch (error) {
    if (error instanceof EvalError) throw error;
    throw new EvalError("CORPUS_INVALID");
  }
  const common = A.results.filter((r) => B.results.some((s) => s.id === r.id)).sort((a, b) =>
    a.id.localeCompare(b.id)
  );
  if (!common.length) throw new EvalError("NO_COMMON_CASES");
  const display = new Map<string, DisplayItem>();
  const items: JudgmentItem[] = common.map((left) => {
    const right = B.results.find((r) => r.id === left.id)!;
    const source = corpus.find((r) => r.id === left.id);
    if (!source || left.kind !== right.kind || source.kind !== left.kind) {
      throw new EvalError("CASE_MISMATCH");
    }
    for (const result of [left, right]) {
      if (
        result.status === "success" &&
        (result.dreams.length !== (source.kind === "single" ? 1 : 4) || result.dreams.some((d) =>
          d.status !== "success"
        ) || result.scenes.length !== (source.kind === "single" ? 1 : 4))
      ) result.status = "failed"; // A successful pipeline with no complete manuscript is still no usable output.
    }
    display.set(left.id, {
      id: left.id,
      originals: source.kind === "single"
        ? [source.raw_text]
        : source.dreams.map((d) => d.raw_text),
      A: left.scenes,
      B: right.scenes,
    });
    const aFailed = left.status === "failed", bFailed = right.status === "failed";
    return {
      id: left.id,
      kind: left.kind,
      clarity: clarity(source),
      audit: null,
      vote: aFailed || bFailed
        ? {
          winner: aFailed && bFailed ? "tie" : aFailed ? "B" : "A",
          automatic: aFailed && bFailed ? "both_failed" : aFailed ? "A_failed" : "B_failed",
          not_ready: { A: aFailed ? true : null, B: bFailed ? true : null },
          reasons: [],
          problems: [],
        }
        : null,
    };
  });
  return {
    nameA: a.split("/").filter(Boolean).at(-1)!,
    nameB: b.split("/").filter(Boolean).at(-1)!,
    display,
    judgment: {
      version: 1,
      mode: "ab",
      seed: seed(),
      revision: 0,
      identity: await digest(A.fingerprint + B.fingerprint),
      set,
      gate_eligible: set === "dev" && !A.manifest.identity.fixture_llm &&
        !B.manifest.identity.fixture_llm,
      stats: {
        A: await stats(A, common, root),
        B: await stats(B, B.results.filter((r) => common.some((s) => s.id === r.id)), root),
      },
      items,
    },
  };
}

export { loadRun, ROOT };

import baseline from "../../eval/configs/baseline_v10.json" with { type: "json" };
import { z } from "zod";
import { resolveModel } from "../../supabase/functions/_shared/llm/registry.ts";
import { FIDELITY_PROMPT_VERSION } from "../../supabase/functions/_shared/fidelity_judge.ts";
import {
  baselineModels,
  candidateConfig,
  canonicalModel,
  q10ModelsMatch,
} from "./bakeoff_contract.ts";
import { configSchema, digest, EvalError, PROMPT_VERSIONS } from "./config.ts";
import { loadRun, prepareAB, ROOT } from "./judge_inputs.ts";
import { privatePath, type RunStats, runStatsSchema, safeCode } from "./judgment.ts";
import { savePrivate } from "./measurements.ts";
import { qualityPreflight } from "./preflight.ts";
import { proseMetricsSchema } from "./reference_contract.ts";
import { validateCorpusTexts } from "./validate_corpus.ts";

const equal = (a: Record<string, unknown>, b: Record<string, unknown>) =>
  JSON.stringify(Object.entries(a).sort()) === JSON.stringify(Object.entries(b).sort());
type Check = { code: string; status: "pass" | "fail" | "unverified"; value?: number | null };

// Thresholds are Q-10's automatic first screen, NOT G1 or a model-quality decision.
export function automaticScreen(A: RunStats, B: RunStats) {
  runStatsSchema.parse(A);
  runStatsSchema.parse(B);
  if (A.failures > A.cases || B.failures > B.cases) throw new EvalError("COUNTS_INVALID");
  const checks: Check[] = [];
  const check = (code: string, passed: boolean | null, value?: number | null) =>
    checks.push({
      code,
      status: passed === null ? "unverified" : passed ? "pass" : "fail",
      ...(value !== undefined ? { value } : {}),
    });
  check("BASELINE_FIDELITY", A.fidelity_rate !== null ? true : null, A.fidelity_rate);
  check("PIPELINE_FAILURE_RATE", B.failures / B.cases <= 0.05, B.failures / B.cases);
  const drop = A.fidelity_rate === null || B.fidelity_rate === null
    ? null
    : A.fidelity_rate - B.fidelity_rate;
  check("FIDELITY_DROP_MAX_5PP", drop === null ? null : drop <= 0.05 + 1e-12, drop);
  check("COST_PER_DREAM", B.max_cost_krw === null ? null : B.max_cost_krw <= 200, B.max_cost_krw);
  return {
    result: checks.some((c) => c.status === "fail")
      ? "REJECT"
      : checks.some((c) => c.status === "unverified")
      ? "INCOMPLETE"
      : "SURVIVES_AUTOMATIC_SCREEN",
    checks,
    human_judgment_required: true,
    winner_selected: false,
  };
}

export async function prepareCandidates(
  baselinePath: string,
  choices: { label: string; model: string }[],
  root = ROOT,
) {
  // Configs contain metadata only. Confine all reads/writes to the public config folder.
  if (!/^eval\/configs\/[A-Za-z0-9_-]+\.json$/.test(baselinePath)) {
    throw new EvalError("CONFIG_PATH_REQUIRED");
  }
  const directory = new URL("eval/configs/", root);
  if (await Deno.realPath(directory) !== await Deno.realPath(root) + "/eval/configs") {
    throw new EvalError("CONFIG_PATH_REQUIRED");
  }
  const basePath = new URL(baselinePath, root);
  if ((await Deno.lstat(basePath)).isSymlink) throw new EvalError("CONFIG_PATH_REQUIRED");
  const base = configSchema.parse(JSON.parse(await Deno.readTextFile(basePath)));
  if (!baselineModels(base.models) || !equal(base.settings, baseline.settings)) {
    throw new EvalError("BASELINE_SETTINGS_CHANGED");
  }
  if (!choices.length || choices.length > 3) throw new EvalError("CANDIDATE_COUNT_1_TO_3");
  if (choices.some((c) => !/^[A-Za-z0-9_-]{1,40}$/.test(c.label))) {
    throw new EvalError("CANDIDATE_LABEL_INVALID");
  }
  if (new Set(choices.map((c) => c.label)).size !== choices.length) {
    throw new EvalError("CANDIDATE_DUPLICATE");
  }
  const configs = choices.map((c) => configSchema.parse(candidateConfig(base, c.label, c.model)));
  if (new Set(configs.map((c) => c.models.write)).size !== configs.length) {
    throw new EvalError("CANDIDATE_DUPLICATE");
  }
  const paths = configs.map((c) => new URL(`${c.label}.json`, directory));
  for (const path of paths) {
    try {
      await Deno.lstat(path);
      throw new EvalError("CONFIG_EXISTS_NO_OVERWRITE");
    } catch (error) {
      if (!(error instanceof Deno.errors.NotFound)) throw error;
    }
  }
  // Validate the entire batch before writing. createNew also protects racing invocations.
  for (const [i, path] of paths.entries()) {
    await Deno.writeTextFile(path, JSON.stringify(configs[i], null, 2) + "\n", {
      createNew: true,
      mode: 0o644,
    });
  }
  return { candidate_configs_created: configs.length, production_changed: false };
}

export async function candidateReadiness(
  configPath: string,
  root = ROOT,
  readSecret = (name: string) => Deno.env.get(name),
) {
  if (!/^eval\/configs\/[A-Za-z0-9_-]+\.json$/.test(configPath)) {
    throw new EvalError("CONFIG_PATH_REQUIRED");
  }
  const config = configSchema.parse(JSON.parse(await Deno.readTextFile(new URL(configPath, root))));
  if (!config.models.judge) throw new EvalError("FIDELITY_MODEL_REQUIRED");
  if (
    [config.models.write, config.models.write_aux, config.models.polish].some((name) =>
      canonicalModel(name) === canonicalModel(config.models.judge!)
    )
  ) throw new EvalError("FIDELITY_REQUIRES_DIFFERENT_MODEL");
  const providers = [
    ...new Set(Object.values(config.models).map((name) => resolveModel(name!).provider)),
  ];
  const credentials = Object.fromEntries(providers.map((provider) => {
    const key = `${provider.toUpperCase()}_API_KEY`;
    return [key, !!readSecret(key)?.trim()];
  }));
  const state = await qualityPreflight(root, readSecret);
  return {
    dev: state.dev,
    credentials,
    ready_for_measured_run: state.dev.full && Object.values(credentials).every(Boolean),
    holdout: "locked_until_Q32",
    provider_calls: 0,
    production_changed: false,
  };
}

const identitySchema = z.object({
  source_sha256: z.string().regex(/^[a-f0-9]{64}$/),
  measurements: z.object({
    lint: z.literal(true),
    fidelity: z.literal(true),
    fidelity_version: z.literal(FIDELITY_PROMPT_VERSION),
  }),
});
async function measuredIdentity(path: string, root: URL) {
  const dir = await privatePath(root, path, "runs", true);
  const manifest = JSON.parse(await Deno.readTextFile(new URL("config.json", dir)));
  const parsed = identitySchema.safeParse(manifest.identity);
  if (!parsed.success) throw new EvalError("MEASURED_SOURCE_IDENTITY_REQUIRED");
  // Inspect numeric lint evidence only. Do not surface prose or validation details.
  const rows = (await Deno.readTextFile(new URL("results.jsonl", dir))).trim().split(/\r?\n/)
    .map((s) => JSON.parse(s));
  const dreams = rows.flatMap((r) => r.dreams).filter((d) => d.scene);
  if (dreams.some((d) => !proseMetricsSchema.safeParse(d.metrics).success)) {
    throw new EvalError("LINT_MEASUREMENTS_REQUIRED");
  }
  return parsed.data;
}

export async function screenCandidate(a: string, b: string, root = ROOT) {
  const [A, B] = await Promise.all([loadRun(a, root), loadRun(b, root)]);
  if (
    [A, B].some((r) => r.manifest.identity.set !== "dev" || r.manifest.identity.fixture_llm)
  ) throw new EvalError("Q10_REQUIRES_REAL_DEV");
  if (
    [A, B].some((r) =>
      r.manifest.engine_version !== "v10" ||
      !equal(r.manifest.prompt_versions, PROMPT_VERSIONS)
    ) ||
    !equal(A.manifest.settings, baseline.settings) ||
    !q10ModelsMatch(A.manifest.models, B.manifest.models)
  ) throw new EvalError("Q10_COMPARISON_INVALID");
  const [sourceA, sourceB] = await Promise.all([
    measuredIdentity(a, root),
    measuredIdentity(b, root),
  ]);
  if (sourceA.source_sha256 !== sourceB.source_sha256) {
    throw new EvalError("Q10_SOURCE_CHANGED");
  }
  const p = await prepareAB(a, b, root), j = p.judgment;
  const idsA = A.results.map((r) => r.id).sort(), idsB = B.results.map((r) => r.id).sort();
  const corpus = await Deno.readTextFile(new URL("eval/corpus/dev.jsonl", root));
  const validated = validateCorpusTexts([{ text: corpus, expectedSet: "dev" }]);
  const corpusIds = corpus.trim().split(/\r?\n/).map((s) => JSON.parse(s).id).sort();
  if (
    !j.gate_eligible || JSON.stringify(idsA) !== JSON.stringify(idsB) ||
    validated.issues.length || JSON.stringify(idsA) !== JSON.stringify(corpusIds) ||
    j.items.length !== 21 || j.items.filter((i) => i.kind === "sequence").length !== 3 ||
    ["fragment", "partial", "vivid"].some((clarity) =>
      j.items.filter((i) => i.kind === "single" && i.clarity === clarity).length !== 6
    )
  ) throw new EvalError("Q10_FULL_DEV_REQUIRED");
  const report = {
    event: "q10_automatic_screen",
    ...automaticScreen(j.stats!.A, j.stats!.B),
    baseline_model: canonicalModel(A.manifest.models.write!),
    candidate_model: canonicalModel(B.manifest.models.write!),
    comparison_sha256: await digest(A.fingerprint + B.fingerprint),
    cases: 21,
    baseline: { failures: j.stats!.A.failures, p95_ms: j.stats!.A.p95_ms },
    candidate: { failures: j.stats!.B.failures, p95_ms: j.stats!.B.p95_ms },
  };
  const dir = await privatePath(root, b, "runs", true);
  await savePrivate(new URL("q10_screening.json", dir), report);
  return report;
}

export async function main(
  args: string[],
  root = ROOT,
  log: (text: string) => void = console.log,
) {
  try {
    let result;
    if (args[0] === "prepare" && args[1] === "--baseline" && args[2]) {
      const choices = [];
      for (let i = 3; i < args.length; i += 2) {
        if (args[i] !== "--candidate" || !args[i + 1]?.includes("=")) throw new EvalError("USAGE");
        const [label, ...model] = args[i + 1].split("=");
        choices.push({ label, model: model.join("=") });
      }
      result = await prepareCandidates(args[2], choices, root);
    } else if (args[0] === "check" && args.length === 2) {
      result = await candidateReadiness(args[1], root);
    } else if (args[0] === "screen" && args.length === 3) {
      result = await screenCandidate(args[1], args[2], root);
    } else throw new EvalError("USAGE");
    log(JSON.stringify(result));
    return "result" in result && result.result !== "SURVIVES_AUTOMATIC_SCREEN" ||
        "ready_for_measured_run" in result && !result.ready_for_measured_run
      ? 2
      : 0;
  } catch (error) {
    log(JSON.stringify({ event: "q10_bakeoff", status: "failed", code: safeCode(error) }));
    return 1;
  }
}
if (import.meta.main) Deno.exit(await main(Deno.args));

import { z } from "zod";
import { FIDELITY_PROMPT_VERSION } from "../../supabase/functions/_shared/fidelity_judge.ts";
import { resolveModel } from "../../supabase/functions/_shared/llm/registry.ts";
import { type CorpusCase, digest, EvalError, type EvalSet, type RunConfig } from "./config.ts";
import type { CaseResult } from "./pipeline.ts";
import { judgmentSchema, privatePath } from "./judgment.ts";
import { loadRun, ROOT } from "./judge_inputs.ts";

export async function savePrivateText(path: URL, contents: string) {
  const temporary = new URL(`${path.href}.${crypto.randomUUID()}.tmp`);
  try {
    await Deno.writeTextFile(temporary, contents, {
      createNew: true,
      mode: 0o600,
    });
    await Deno.rename(temporary, path);
  } finally {
    try {
      await Deno.remove(temporary);
    } catch { /* Already moved. */ }
  }
}
export async function savePrivate(path: URL, value: unknown) {
  await savePrivateText(path, JSON.stringify(value, null, 2) + "\n");
}
const hash = z.string().regex(/^[a-f0-9]{64}$/);
const auditSchema = z.object({
  version: z.literal(1),
  results_sha256: hash,
  judge_model: z.string(),
  prompt_version: z.literal(FIDELITY_PROMPT_VERSION),
  items: z.array(
    z.object({ id: z.string(), raw_text: z.string(), text: z.string(), finding: z.string() })
      .strict(),
  ),
}).strict();
const calibrationSchema = z.object({
  version: z.literal(1),
  judge_model: z.string(),
  prompt_version: z.literal(FIDELITY_PROMPT_VERSION),
  audit_path: z.string(),
  judgment_path: z.string(),
  audit_sha256: hash,
  judgment_sha256: hash,
  reviewed: z.literal(15),
  agreed: z.number().int().min(12).max(15),
  eligible: z.boolean(),
}).strict();
function canonical(name: string) {
  const m = resolveModel(name);
  return `${m.provider}:${m.id}`;
}
async function calibrationPath(model: string, root: URL) {
  return new URL(
    `eval/judgments/fidelity-${
      (await digest(canonical(model) + FIDELITY_PROMPT_VERSION)).slice(0, 16)
    }.json`,
    root,
  );
}

export async function calibrateFidelity(runPath: string, judgmentPath: string, root = ROOT) {
  const run = await loadRun(runPath, root); // Holdout is denied before any audit text read.
  const auditPath = `${runPath.replace(/\/$/, "")}/fidelity_audit.json`;
  const auditFile = await privatePath(root, auditPath, "runs");
  const votesFile = await privatePath(root, judgmentPath, "judgments");
  const auditText = await Deno.readTextFile(auditFile),
    voteText = await Deno.readTextFile(votesFile);
  let audit, votes;
  try {
    audit = auditSchema.parse(JSON.parse(auditText));
    votes = judgmentSchema.parse(JSON.parse(voteText));
  } catch {
    throw new EvalError("FIDELITY_AUDIT_INVALID");
  }
  const results = await Deno.readTextFile(
    new URL(`${runPath.replace(/\/$/, "")}/results.jsonl`, root),
  );
  if (
    audit.results_sha256 !== await digest(results) ||
    !run.manifest.models.judge ||
    canonical(audit.judge_model) !== canonical(run.manifest.models.judge) ||
    votes.mode !== "fidelity-audit" || votes.identity !== await digest(auditText) ||
    audit.items.length < 15 || votes.items.length !== 15 ||
    new Set(audit.items.map((i) => i.id)).size !== audit.items.length ||
    votes.items.some((item, index) =>
      item.id !== audit.items[index].id || !["agree", "disagree"].includes(item.audit?.choice ?? "")
    )
  ) {
    throw new EvalError("FIDELITY_AUDIT_INCOMPLETE");
  }
  const agreed = votes.items.filter((i) => i.audit?.choice === "agree").length;
  if (agreed < 12) throw new EvalError("FIDELITY_AGREEMENT_BELOW_80");
  const eligible = run.manifest.identity.set === "dev" && !run.manifest.identity.fixture_llm;
  const certificate = calibrationSchema.parse({
    version: 1,
    judge_model: canonical(audit.judge_model),
    prompt_version: FIDELITY_PROMPT_VERSION,
    audit_path: auditPath,
    judgment_path: judgmentPath,
    audit_sha256: await digest(auditText),
    judgment_sha256: await digest(voteText),
    reviewed: 15,
    agreed,
    eligible,
  });
  await Deno.mkdir(new URL("eval/judgments/", root), { recursive: true, mode: 0o700 });
  const path = await calibrationPath(audit.judge_model, root);
  try {
    if ((await Deno.lstat(path)).isSymlink) throw new EvalError("PRIVATE_PATH_REQUIRED");
  } catch (error) {
    if (!(error instanceof Deno.errors.NotFound)) throw error;
  }
  await savePrivate(path, certificate);
  return { reviewed: 15, agreed, agreement: agreed / 15, gate_eligible: eligible };
}

export async function calibrated(model: string | null, root = ROOT): Promise<boolean> {
  if (!model) return false;
  try {
    const path = await calibrationPath(model, root);
    const certificate = calibrationSchema.parse(JSON.parse(await Deno.readTextFile(path)));
    if (!certificate.eligible || certificate.judge_model !== canonical(model)) return false;
    const a = await privatePath(root, certificate.audit_path, "runs"),
      j = await privatePath(root, certificate.judgment_path, "judgments");
    const auditText = await Deno.readTextFile(a), voteText = await Deno.readTextFile(j);
    if (
      await digest(auditText) !== certificate.audit_sha256 ||
      await digest(voteText) !== certificate.judgment_sha256
    ) return false;
    // Recheck the source run/results too: certificates cannot outlive changed manuscripts.
    const runPath = certificate.audit_path.slice(0, -"/fidelity_audit.json".length);
    const run = await loadRun(runPath, root);
    const audit = auditSchema.parse(JSON.parse(auditText));
    const results = await Deno.readTextFile(new URL(`${runPath}/results.jsonl`, root));
    const votes = judgmentSchema.parse(JSON.parse(voteText));
    return run.manifest.identity.set === "dev" && !run.manifest.identity.fixture_llm &&
      !!run.manifest.models.judge &&
      canonical(run.manifest.models.judge) === certificate.judge_model &&
      canonical(audit.judge_model) === certificate.judge_model &&
      audit.results_sha256 === await digest(results) &&
      audit.prompt_version === FIDELITY_PROMPT_VERSION &&
      votes.mode === "fidelity-audit" && votes.identity === await digest(auditText) &&
      votes.items.length === 15 &&
      votes.items.every((item, i) =>
        item.id === audit.items[i]?.id && ["agree", "disagree"].includes(item.audit?.choice ?? "")
      ) &&
      votes.items.filter((item) => item.audit?.choice === "agree").length >= 12;
  } catch {
    return false;
  }
}

export async function calibrationProof(model: string | null, root = ROOT) {
  if (!model || !await calibrated(model, root)) return null;
  return {
    judge_model: canonical(model),
    certificate_sha256: await digest(await Deno.readTextFile(await calibrationPath(model, root))),
  };
}

// Private artifacts only. No body/finding/detail ever reaches the CLI or a committed report.
export async function writeMeasurementArtifacts(
  directory: URL,
  records: CorpusCase[],
  results: CaseResult[],
  config: RunConfig,
  root: URL,
  set: EvalSet,
) {
  const resultsText = await Deno.readTextFile(new URL("results.jsonl", directory));
  const resultsHash = await digest(resultsText);
  const auditItems: z.infer<typeof auditSchema>["items"] = [];
  for (const result of [...results].sort((a, b) => a.id.localeCompare(b.id))) {
    const record = records.find((r) => r.id === result.id)!;
    const inputs = record.kind === "single" ? [record] : record.dreams;
    for (const [index, dream] of result.dreams.entries()) {
      if (dream.fidelity?.status !== "success" || !dream.scene) continue;
      auditItems.push({
        id: `${result.id}d${index}`,
        raw_text: inputs[index].raw_text +
          (inputs[index].recall_answers
            ? "\n\n회상 답변\n" + JSON.stringify(inputs[index].recall_answers)
            : ""),
        text: (dream.scene.passages as { text: string }[]).map((p) => p.text).join("\n\n"),
        finding: JSON.stringify({ pass: dream.fidelity.pass, ...dream.fidelity.finding }, null, 2),
      });
    }
  }
  if (config.models.judge && auditItems.length) {
    await savePrivate(new URL("fidelity_audit.json", directory), {
      version: 1,
      results_sha256: resultsHash,
      judge_model: config.models.judge,
      prompt_version: FIDELITY_PROMPT_VERSION,
      items: auditItems.slice(0, 15),
    });
  }
  const scenes = results.flatMap((r) => r.dreams).filter((d) => d.scene);
  const measured = scenes.filter((d) => d.fidelity?.status === "success");
  const approved = set === "dev" && await calibrated(config.models.judge, root);
  const proof = approved ? await calibrationProof(config.models.judge, root) : null;
  const complete = scenes.length > 0 && measured.length === scenes.length;
  // A metric's absence is not zero or success. A later calibrated refresh writes fidelity.
  const fidelity = approved && complete
    ? {
      passed: measured.filter((d) => d.fidelity?.status === "success" && d.fidelity.pass).length,
      total: measured.length,
    }
    : undefined;
  let previous: { reference_proximity?: number } = {};
  try {
    const p = JSON.parse(await Deno.readTextFile(new URL("quality_metrics.json", directory)));
    if (p.results_sha256 === resultsHash && typeof p.reference_proximity === "number") previous = p;
  } catch { /* No prior, or stale, metrics. */ }
  await savePrivate(new URL("quality_metrics.json", directory), {
    results_sha256: resultsHash,
    case_ids: results.map((r) => r.id),
    ...(fidelity && proof ? { fidelity, fidelity_calibration: proof } : {}),
    ...(previous.reference_proximity === undefined
      ? {}
      : { reference_proximity: previous.reference_proximity }),
  });
  try {
    const summary = JSON.parse(await Deno.readTextFile(new URL("summary.json", directory)));
    if (summary.fidelity) {
      summary.fidelity.calibrated = approved;
      await savePrivate(new URL("summary.json", directory), summary);
    }
  } catch { /* No summary in an imported run. */ }
  return {
    measured: measured.length,
    calibrated: approved,
    complete,
    pass_rate: measured.length
      ? measured.filter((d) => d.fidelity?.status === "success" && d.fidelity.pass).length /
        measured.length
      : null,
  };
}

export async function refreshMeasurements(path: string, root = ROOT) {
  const run = await loadRun(path, root);
  const directory = await privatePath(root, path, "runs", true);
  const config = (await import("./config.ts")).configSchema.strip().parse(
    JSON.parse(await Deno.readTextFile(new URL("config.json", directory))),
  );
  const set = run.manifest.identity.set;
  const corpusFile = set === "fixtures" ? "eval/fixtures/sample.jsonl" : `eval/corpus/${set}.jsonl`;
  const corpus = await Deno.readTextFile(new URL(corpusFile, root));
  if (await digest(corpus) !== run.manifest.identity.corpus_sha256) {
    throw new EvalError("CORPUS_MISMATCH");
  }
  const records = corpus.trim().split(/\r?\n/).map((s) => JSON.parse(s) as CorpusCase);
  const results = (await Deno.readTextFile(new URL("results.jsonl", directory))).trim().split(
    /\r?\n/,
  ).map((s) => JSON.parse(s) as CaseResult);
  return await writeMeasurementArtifacts(directory, records, results, config, root, set);
}

export async function main(args: string[], root = ROOT) {
  try {
    let result;
    if (args[0] === "calibrate" && args.length === 3) {
      result = await calibrateFidelity(args[1], args[2], root);
    } else if (args[0] === "refresh" && args.length === 2) {
      result = await refreshMeasurements(args[1], root);
    } else throw new EvalError("USAGE");
    console.log(JSON.stringify(result));
    return 0;
  } catch (error) {
    console.log(
      JSON.stringify({ code: error instanceof EvalError ? error.code : "MEASUREMENT_FAILED" }),
    );
    return 1;
  }
}
if (import.meta.main) Deno.exit(await main(Deno.args));

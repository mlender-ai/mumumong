import {
  type Judgment,
  type JudgmentItem,
  judgmentSchema,
  privatePath,
  safeCode,
} from "./judgment.ts";
import { EvalError, PROMPT_VERSIONS } from "./config.ts";
import { ROOT } from "./judge_inputs.ts";
import { q10ModelsMatch } from "./bakeoff_contract.ts";

// Exact one-sided binomial tail P(X >= wins), p=1/2; ties are excluded.
// Log-space summation avoids factorial overflow, not a normal approximation.
export function signP(wins: number, losses: number): number {
  if (![wins, losses].every((n) => Number.isSafeInteger(n) && n >= 0)) {
    throw new EvalError("COUNTS_INVALID");
  }
  const n = wins + losses;
  if (n === 0) return 1;
  let logTerm = -n * Math.log(2), logSum = -Infinity;
  for (let k = 0; k <= n; k++) {
    if (k >= wins) {
      const max = Math.max(logSum, logTerm);
      logSum = max + Math.log(Math.exp(logSum - max) + Math.exp(logTerm - max));
    }
    if (k < n) logTerm += Math.log(n - k) - Math.log(k + 1);
  }
  return Math.min(1, Math.exp(logSum));
}
function tally(items: JudgmentItem[]) {
  const votes = items.flatMap((item) => item.vote ? [item.vote] : []);
  const winners = { A: 0, B: 0, tie: 0 };
  const automatic = { A_failed: 0, B_failed: 0, both_failed: 0 };
  const reasons: Record<string, number> = {}, problems: Record<string, number> = {};
  for (const vote of votes) {
    winners[vote.winner]++;
    if (vote.automatic !== "none") automatic[vote.automatic]++;
    for (const key of vote.reasons) reasons[key] = (reasons[key] ?? 0) + 1;
    for (const key of vote.problems) problems[key] = (problems[key] ?? 0) + 1;
  }
  const notReady = (side: "A" | "B") => {
    const assessed = votes.filter((vote) => vote.not_ready[side] !== null);
    const count = assessed.filter((vote) => vote.not_ready[side]).length;
    return {
      count,
      assessed: assessed.length,
      rate: assessed.length ? count / assessed.length : null,
    };
  };
  return {
    total: items.length,
    judged: votes.length,
    wins: winners,
    automatic,
    not_ready: { A: notReady("A"), B: notReady("B") },
    reasons,
    problems,
    candidate_one_sided_p: signP(winners.B, winners.A),
    baseline_one_sided_p: signP(winners.A, winners.B),
  };
}
export type Gate = "G1" | "G2" | "G3";
function ordered(value: Record<string, unknown>): string {
  return JSON.stringify(Object.entries(value).sort(([a], [b]) => a.localeCompare(b)));
}
export function buildReport(judgment: Judgment, gate?: Gate) {
  judgmentSchema.parse(judgment);
  if (!["ab", "pro"].includes(judgment.mode)) {
    if (gate) throw new EvalError("GATE_REQUIRES_AB");
    const votes = judgment.items.flatMap((item) => item.audit ? [item.audit] : []);
    const choices: Record<string, number> = {}, labels: Record<string, number> = {};
    for (const vote of votes) {
      choices[vote.choice] = (choices[vote.choice] ?? 0) + 1;
      for (const row of vote.annotations ?? []) {
        for (const label of row.labels) labels[label] = (labels[label] ?? 0) + 1;
      }
    }
    return {
      event: "judgment_report",
      mode: judgment.mode,
      total: judgment.items.length,
      judged: votes.length,
      choices,
      labels,
    };
  }
  const summary = tally(judgment.items);
  const breakdown = (field: "kind" | "clarity") =>
    Object.fromEntries(
      [...new Set(judgment.items.map((item) => item[field]))].sort().map((
        value,
      ) => [value, tally(judgment.items.filter((item) => item[field] === value))]),
    );
  const report: Record<string, unknown> = {
    event: "judgment_report",
    mode: judgment.mode,
    comparison: "A=baseline,B=candidate",
    ...summary,
    by_clarity: breakdown("clarity"),
    by_kind: breakdown("kind"),
    gate_eligible: judgment.gate_eligible,
  };
  if (judgment.mode === "pro") {
    report.comparison = "A=engine,B=professional";
    report.engine_win_rate = summary.wins.A + summary.wins.B
      ? summary.wins.A / (summary.wins.A + summary.wins.B)
      : null;
  }
  if (!gate) return report;
  if (judgment.mode !== "ab" || !judgment.stats) throw new EvalError("GATE_REQUIRES_AB");
  const A = judgment.stats.A, B = judgment.stats.B;
  const checks: { code: string; status: "pass" | "fail" | "unverified"; value?: number | null }[] =
    [];
  const check = (code: string, pass: boolean | null, value?: number | null) =>
    checks.push({
      code,
      status: pass === null ? "unverified" : pass ? "pass" : "fail",
      ...(value !== undefined ? { value } : {}),
    });
  check(
    "ELIGIBLE_CORPUS",
    judgment.gate_eligible && judgment.set === (gate === "G3" ? "holdout" : "dev"),
  );
  const single = judgment.items.filter((item) => item.kind === "single");
  check(
    "FULL_CORPUS_COVERAGE",
    single.length === (gate === "G3" ? 6 : 18) &&
      judgment.items.filter((item) => item.kind === "sequence").length ===
        (gate === "G3" ? 1 : 3) &&
      ["fragment", "partial", "vivid"].every((clarity) =>
        single.filter((item) => item.clarity === clarity).length === (gate === "G3" ? 2 : 6)
      ),
  );
  check("JUDGMENT_COMPLETE", summary.judged === summary.total);
  check("SETTINGS_FIXED", A.settings_sha256 === B.settings_sha256);
  if (gate === "G1") {
    check(
      "SOURCE_FIXED",
      !A.source_sha256 || !B.source_sha256 ? null : A.source_sha256 === B.source_sha256,
    );
    check(
      "V10_PROMPTS_FIXED",
      A.engine_version === "v10" && B.engine_version === "v10" &&
        ordered(A.prompt_versions) === ordered(PROMPT_VERSIONS) &&
        ordered(B.prompt_versions) === ordered(PROMPT_VERSIONS),
    );
    check(
      "ONLY_PROSE_MODEL_GROUP_VARIES",
      q10ModelsMatch(A.models, B.models),
    );
  } else {
    check(
      "V11_VS_V10_MODELS_FIXED",
      A.engine_version === "v10" && B.engine_version === "v11" &&
        ordered(A.models) === ordered(B.models),
    );
  }
  if (gate === "G3") check("WINS_NOT_BELOW_LOSSES", summary.wins.B >= summary.wins.A);
  else check("SIGN_TEST", summary.candidate_one_sided_p <= 0.05, summary.candidate_one_sided_p);
  check(
    "FIDELITY",
    A.fidelity_rate === null || B.fidelity_rate === null
      ? null
      : B.fidelity_rate + (gate === "G1" ? 0.03 + 1e-12 : 0) >= A.fidelity_rate,
    B.fidelity_rate,
  );
  if (gate === "G1") {
    check("PIPELINE_FAILURE_RATE", B.failures / B.cases <= 0.05, B.failures / B.cases);
  }
  if (gate !== "G2") {
    check("COST_PER_DREAM", B.max_cost_krw === null ? null : B.max_cost_krw <= 200, B.max_cost_krw);
  }
  if (gate === "G2") {
    check(
      "PROVENANCE_ZERO",
      B.provenance_errors === null ? null : B.provenance_errors === 0,
      B.provenance_errors,
    );
    check(
      "V2_ALL_FINAL_SCENES",
      B.v2_compliance === null ? null : B.v2_compliance === 1,
      B.v2_compliance,
    );
  }
  if (gate !== "G1") {
    check("READINESS_COMPLETE", summary.not_ready.B.assessed === summary.total);
    check(
      "NOT_RELEASE_READY",
      summary.not_ready.B.rate === null
        ? null
        : summary.not_ready.B.rate <= (gate === "G2" ? 0.25 : 0.2),
      summary.not_ready.B.rate,
    );
    check(
      "REFERENCE_PROXIMITY",
      A.reference_proximity === null || B.reference_proximity === null
        ? null
        : B.reference_proximity >= A.reference_proximity + (gate === "G2" ? 2 : 0),
      B.reference_proximity,
    );
  }
  if (gate === "G3") check("P95_LATENCY", B.p95_ms === null ? null : B.p95_ms <= 90000, B.p95_ms);
  report.gate = {
    name: gate,
    result: checks.every((row) => row.status === "pass") ? "PASS" : "FAIL",
    checks,
  };
  return report;
}
export async function main(
  args: string[],
  root = ROOT,
  log: (text: string) => void = console.log,
): Promise<number> {
  try {
    if (
      !args[0] || args.length !== 1 && args.length !== 3 ||
      args.length === 3 && (args[1] !== "--gate" || !["G1", "G2", "G3"].includes(args[2]))
    ) throw new EvalError("USAGE");
    const file = await privatePath(root, args[0], "judgments");
    const judgment = judgmentSchema.parse(JSON.parse(await Deno.readTextFile(file)));
    const report = buildReport(judgment, args[2] as Gate | undefined);
    log(JSON.stringify(report));
    return (report.gate as { result: string } | undefined)?.result === "FAIL" ? 2 : 0;
  } catch (error) {
    log(JSON.stringify({ event: "judgment_report", status: "failed", code: safeCode(error) }));
    return 1;
  }
}
if (import.meta.main) Deno.exit(await main(Deno.args));

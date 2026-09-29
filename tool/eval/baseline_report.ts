import baseline from "../../eval/configs/baseline_v10.json" with { type: "json" };
import { CONTRADICTION_TYPES } from "../../supabase/functions/_shared/fidelity_judge.ts";
import { digest, EvalError, PROMPT_VERSIONS } from "./config.ts";
import { loadRun, ROOT } from "./judge_inputs.ts";
import { judgmentSchema, privatePath } from "./judgment.ts";
import { calibrated, savePrivateText } from "./measurements.ts";
import type { CaseResult } from "./pipeline.ts";
import { summarize } from "./pipeline.ts";
import { proseMetricsSchema } from "./reference_profile.ts";
import { validateCorpusTexts } from "./validate_corpus.ts";

export async function baselineReport(runPath: string, aaPath?: string, root = ROOT) {
  const run = await loadRun(runPath, root);
  if (run.manifest.identity.set !== "dev" || run.manifest.identity.fixture_llm) {
    throw new EvalError("BASELINE_REQUIRES_REAL_DEV");
  }
  if (
    run.manifest.engine_version !== "v10" ||
    Object.entries(baseline.settings).some(([key, value]) =>
      run.manifest.settings[key] !== value
    ) ||
    Object.entries(baseline.models).some(([role, model]) =>
      role !== "judge" && run.manifest.models[role] !== model
    ) ||
    Object.entries(PROMPT_VERSIONS).some(([role, version]) =>
      run.manifest.prompt_versions[role] !== version
    )
  ) throw new EvalError("BASELINE_SETTINGS_CHANGED");
  const corpus = await Deno.readTextFile(new URL("eval/corpus/dev.jsonl", root));
  const valid = validateCorpusTexts([{ text: corpus, expectedSet: "dev" }]),
    counts = valid.summary.dev;
  const corpusIds = corpus.trim().split(/\r?\n/).map((s) => JSON.parse(s).id).sort();
  if (
    valid.issues.length || counts.single !== 18 || counts.sequence !== 3 || counts.dreams !== 30 ||
    Object.values(counts.singleClarity).some((n) => n !== 6) ||
    await digest(corpus) !== run.manifest.identity.corpus_sha256 ||
    JSON.stringify(run.results.map((r) => r.id).sort()) !== JSON.stringify(corpusIds)
  ) throw new EvalError("BASELINE_CORPUS_INCOMPLETE");
  if (!await calibrated(run.manifest.models.judge ?? null, root)) {
    throw new EvalError("FIDELITY_CALIBRATION_REQUIRED");
  }
  const directory = await privatePath(root, runPath, "runs", true);
  const results = (await Deno.readTextFile(new URL("results.jsonl", directory))).trim().split(
    /\r?\n/,
  ).map((s) => JSON.parse(s) as CaseResult);
  const scenes = results.flatMap((r) => r.dreams).filter((d) => d.scene);
  if (
    !scenes.length ||
    scenes.some((d) =>
      !proseMetricsSchema.safeParse(d.metrics).success || d.fidelity?.status !== "success"
    )
  ) throw new EvalError("BASELINE_MEASUREMENTS_INCOMPLETE");
  const summary = summarize(results), m = summary.prose_metrics!;
  let aa: { wins_a: number; wins_b: number; ties: number; noisy: boolean } | null = null;
  if (aaPath) {
    const file = await privatePath(root, aaPath, "judgments");
    const judged = judgmentSchema.parse(JSON.parse(await Deno.readTextFile(file)));
    const stats = judged.stats;
    if (
      judged.mode !== "ab" || judged.set !== "dev" || judged.items.length !== 10 ||
      judged.items.some((i) => !i.vote || i.vote.automatic !== "none") || !stats ||
      JSON.stringify(stats.A.models) !== JSON.stringify(stats.B.models) ||
      stats.A.settings_sha256 !== stats.B.settings_sha256 ||
      JSON.stringify(stats.A.prompt_versions) !== JSON.stringify(stats.B.prompt_versions) ||
      stats.A.engine_version !== "v10" || stats.B.engine_version !== "v10"
    ) throw new EvalError("AA_JUDGMENT_INVALID");
    const wins_a = judged.items.filter((i) => i.vote?.winner === "A").length,
      wins_b = judged.items.filter((i) => i.vote?.winner === "B").length;
    aa = { wins_a, wins_b, ties: 10 - wins_a - wins_b, noisy: wins_a >= 7 || wins_b >= 7 };
  }
  const metrics = Object.entries(m).map(([key, v]) => `| ${key} | ${v.p50} | ${v.p90} |`).join(
    "\n",
  );
  const known = ["protagonist", "missing_high", "invented_concrete", ...CONTRADICTION_TYPES];
  const violations = Object.fromEntries(
    known.map((key) => [key, summary.fidelity.violations[key] ?? 0]),
  );
  const cost = summary.cost_krw.complete
    ? JSON.stringify(summary.cost_krw)
    : "미검증 · 실패 호출/미등록 모델 비용 포함 불완전";
  const report =
    `# Q-08 기준선 측정\n\n기준: edfc13c / write.v10 / plan.v6. 실제 dev 21개 판정 단위, 원본 꿈 30개.\n\n- 파이프라인 실패율: ${
      summary.failed / 21
    }\n- 꿈 처리 실패: ${summary.dream_failed} / 시도 ${summary.dreams}\n- 실패 이후 미시도 꿈: ${
      30 - summary.dreams
    }\n- fallback율: ${
      summary.fallback / 21
    }\n- 충실도 통과율: ${summary.fidelity.pass_rate} (실제 15건 사람 검수 승인 후; 장면 ${scenes.length}건)\n- 꿈당 엔진 비용(KRW): ${cost}\n- 지연(ms): ${
      JSON.stringify(summary.latency_ms)
    }\n- 평가 판정기 추가 비용(KRW): ${summary.fidelity.cost_krw}; 완전 측정 ${summary.fidelity.cost_complete}\n- A/A: ${
      aa ? JSON.stringify(aa) : "미검증 · 권장 검사 미실행"
    }\n- 레퍼런스 근접도: ${
      run.quality?.reference_proximity ?? "미검증 · Q-09 실제 프로파일 필요"
    }\n\n## 위반 분포\n\n충실도: ${JSON.stringify(violations)}\n\n결정론 검증 위반 총수: ${
      Object.values(summary.validation_codes).reduce((n, v) => n + v, 0)
    } (재시도 포함)\n\n## 산문 지표\n\n| 지표 | 중앙값 | p90 |\n|---|---:|---:|\n${metrics}\n\n이 보고서는 수치만 포함한다. 미실행 검사는 통과로 간주하지 않는다. 평가 판정 비용·지연은 엔진 비용·지연과 분리했다.\n`;
  const path = new URL("baseline_report.md", directory);
  await savePrivateText(path, report);
  return {
    cases: 21,
    corpus_dreams: 30,
    scene_measurements: scenes.length,
    failed: summary.failed,
    aa_verified: aa !== null,
    reference_verified: run.quality?.reference_proximity !== undefined,
  };
}
export async function main(args: string[], root = ROOT) {
  try {
    if (![1, 3].includes(args.length) || (args.length === 3 && args[1] !== "--aa")) {
      throw new EvalError("USAGE");
    }
    console.log(JSON.stringify(await baselineReport(args[0], args[2], root)));
    return 0;
  } catch (error) {
    console.log(
      JSON.stringify({ code: error instanceof EvalError ? error.code : "BASELINE_REPORT_FAILED" }),
    );
    return 1;
  }
}
if (import.meta.main) Deno.exit(await main(Deno.args));

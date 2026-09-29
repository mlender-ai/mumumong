import {
  lintProse,
  metricDistribution,
  type ProseMetrics,
} from "../../supabase/functions/_shared/prose_lint.ts";
import type {
  ReferenceGroup,
  ReferenceProfile,
} from "../../supabase/functions/_shared/reference_profile.ts";
import { referenceProximity } from "../../supabase/functions/_shared/reference_proximity.ts";
import { digest, EvalError } from "./config.ts";
import { loadRun, ROOT } from "./judge_inputs.ts";
import { judgmentSchema, privatePath } from "./judgment.ts";
import { savePrivate, savePrivateText } from "./measurements.ts";
import {
  ENDING_TYPES,
  OPENING_TYPES,
  parseWorks,
  proseMetricsSchema,
  referenceParagraphs,
  referenceProfileSchema,
  type ReferenceWork,
  REVEAL_TYPES,
} from "./reference_contract.ts";
export {
  ENDING_TYPES,
  OPENING_TYPES,
  parseWorks,
  proseMetricsSchema,
  referenceLabelSchema,
  referenceParagraphs,
  type ReferenceWork,
  REVEAL_TYPES,
  workSchema,
} from "./reference_contract.ts";

function group(rows: ReferenceWork[]): ReferenceGroup | null {
  if (!rows.length) return null;
  const metrics = (key: "opening" | "ending") =>
    metricDistribution(
      rows.map((row) =>
        lintProse(
          referenceParagraphs(row[key]),
          row.voice === "first" ? "first_person_past" : "third_person_past",
        )
      ),
    )!;
  const distribution = (key: "opening_type" | "ending_type", choices: readonly string[]) =>
    Object.fromEntries(
      choices.map((value) => [
        value,
        rows.filter((r) => r.labels?.[key] === value).length / rows.length,
      ]),
    );
  const events = rows.flatMap((r) => r.labels ? [r.labels.first_event_para] : []).sort((a, b) =>
    a - b
  );
  return {
    count: rows.length,
    opening: metrics("opening"),
    ending: metrics("ending"),
    labels: {
      opening_type: distribution("opening_type", OPENING_TYPES),
      ending_type: distribution("ending_type", ENDING_TYPES),
      first_event_para_p50: events[Math.max(0, Math.ceil(events.length / 2) - 1)] ?? 0,
      reveal_by_2000: Object.fromEntries(
        REVEAL_TYPES.map((key) => [
          key,
          rows.filter((r) => r.labels?.reveal_by_2000.includes(key)).length / rows.length,
        ]),
      ),
    },
  };
}

export async function buildProfile(rows: ReferenceWork[], source: string) {
  const positive = rows.filter((r) => r.group === "positive"),
    control = rows.filter((r) => r.group === "control");
  const reasons: string[] = [];
  if (positive.length < 25) reasons.push("POSITIVE_COUNT");
  if (positive.filter((r) => r.voice === "first").length < Math.ceil(positive.length / 2)) {
    reasons.push("FIRST_PERSON_SHARE");
  }
  if (
    positive.some((r) => positive.filter((p) => p.genre === r.genre).length / positive.length > .4)
  ) reasons.push("GENRE_CONCENTRATION");
  if (rows.some((r) => !r.labels)) reasons.push("LABELS_INCOMPLETE");
  if (rows.some((r) => r.synthetic)) reasons.push("SYNTHETIC_REFERENCES");
  if (!positive.length) throw new EvalError("REFERENCE_POSITIVE_REQUIRED");
  const p = group(positive)!, c = group(control);
  const delta = (key: "opening" | "ending") =>
    Object.fromEntries(
      Object.keys(p[key]).map((
        metric,
      ) => [
        metric,
        p[key][metric as keyof ProseMetrics].p50 - c![key][metric as keyof ProseMetrics].p50,
      ]),
    ) as Record<keyof ProseMetrics, number>;
  const profile: ReferenceProfile = {
    version: 1,
    eligible: !reasons.length,
    source_sha256: await digest(source),
    positive: p,
    control: c,
    voices: {
      first: group(positive.filter((r) => r.voice === "first")),
      third: group(positive.filter((r) => r.voice === "third")),
    },
    median_deltas: c ? { opening: delta("opening"), ending: delta("ending") } : null,
  };
  return { profile, reasons };
}

// Fixed labels + aggregate numbers only. No titles, IDs, hook notes or excerpts.
export function profileReport(profile: ReferenceProfile) {
  const p = profile.positive;
  const bands = (section: "opening" | "ending") =>
    Object.entries(p[section]).map(([key, value]) =>
      `| ${key} | ${value.p10} | ${value.p25} | ${value.p50} | ${value.p75} | ${value.p90} |`
    ).join("\n");
  return `# Q-09 레퍼런스 프로파일\n\n상태: ${
    profile.eligible ? "측정 완료" : "미확정 · 품질 게이트에 사용 금지"
  }\n\n양성 ${p.count}, 대조 ${
    profile.control?.count ?? 0
  }. 작은 대조 표본의 차이는 방향만 보며 유의성을 주장하지 않는다.\n\n## 도입 지표\n\n| 지표 | p10 | p25 | p50 | p75 | p90 |\n|---|---:|---:|---:|---:|---:|\n${
    bands("opening")
  }\n\n## 끝 지표\n\n| 지표 | p10 | p25 | p50 | p75 | p90 |\n|---|---:|---:|---:|---:|---:|\n${
    bands("ending")
  }\n\n## 몰입 문법 스펙\n\n${
    profile.eligible
      ? `- 도입 유형은 양성 분포를 따른다 — 행동 ${p.labels.opening_type.action}, 대사 ${p.labels.opening_type.dialogue}, 그 밖의 유형은 프로파일 참조.\n- 첫 사건의 위치는 양성 문단 중앙값 ${p.labels.first_event_para_p50}을 근거로 검토한다.\n- 한 문장 문단과 모바일 밀도는 양성 도입 중앙값 ${p.opening.one_sentence_para_rate.p50}, ${p.opening.mobile_lines_per_para.p50}을 목표 분포로 삼는다.\n- 첫 문장의 길이는 양성 도입 p25–p75 ${p.opening.first_sentence_len.p25}–${p.opening.first_sentence_len.p75}을 참고한다.\n- 2,000자 안의 처지·목표·이상함 공개율은 ${p.labels.reveal_by_2000.circumstance}·${p.labels.reveal_by_2000.goal_problem}·${p.labels.reveal_by_2000.anomaly}이다.\n- 끝맺음 유형은 새 정보 ${p.labels.ending_type.new_information}, 위기 직전 ${p.labels.ending_type.before_crisis}, 선택 직전 ${p.labels.ending_type.before_choice} 등 실제 분포를 따른다.`
      : "실제 수집·직접 라벨링 전에는 원칙을 확정하지 않는다."
  }\n\n장르 문법 제외: 회귀·빙의·환생 설정, 상태창·시스템창, 사이다 구조, 회차 분량.\n`;
}

export async function analyzeReferences(path: string, root = ROOT, annotationsPath?: string) {
  const file = await privatePath(root, path, "reference");
  const text = await Deno.readTextFile(file);
  const rows = parseWorks(text);
  let source = text;
  if (annotationsPath) {
    const file = await privatePath(root, annotationsPath, "judgments");
    const votesText = await Deno.readTextFile(file);
    const votes = judgmentSchema.parse(JSON.parse(votesText));
    if (
      votes.mode !== "annotate" || votes.identity !== await digest(text) ||
      votes.items.length !== rows.length ||
      votes.items.some((item, i) => item.id !== rows[i].id || !item.audit?.reference_labels)
    ) throw new EvalError("REFERENCE_LABELS_INCOMPLETE");
    rows.forEach((row, i) => row.labels = votes.items[i].audit!.reference_labels);
    source += votesText;
  }
  const { profile, reasons } = await buildProfile(rows, source);
  const outputDirectory = new URL("./", file);
  await savePrivate(new URL("profile.json", outputDirectory), profile);
  await savePrivateText(new URL("profile_report.md", outputDirectory), profileReport(profile));
  await savePrivateText(
    new URL("profile_module.ts", outputDirectory),
    profile.eligible
      ? "export const REFERENCE_PROFILE = " + JSON.stringify(profile, null, 2) + " as const;\n"
      : "export const REFERENCE_PROFILE = null; // Unverified; do not publish bands.\n",
  );
  return {
    positive: profile.positive.count,
    control: profile.control?.count ?? 0,
    eligible: profile.eligible,
    reasons,
  };
}

export async function scoreReferenceRun(runPath: string, profilePath: string, root = ROOT) {
  await loadRun(runPath, root); // Holds before results and metrics reads.
  const file = await privatePath(root, profilePath, "reference"),
    dir = await privatePath(root, runPath, "runs", true);
  const profile = referenceProfileSchema.parse(JSON.parse(await Deno.readTextFile(file)));
  if (!profile.eligible) throw new EvalError("REFERENCE_PROFILE_UNVERIFIED");
  const text = await Deno.readTextFile(new URL("results.jsonl", dir));
  const rows = text.trim().split(/\r?\n/).map((line) =>
    JSON.parse(line) as { id: string; dreams: { scene: unknown; metrics?: ProseMetrics }[] }
  );
  const dreams = rows.flatMap((row) => row.dreams).filter((d) => d.scene);
  if (!dreams.length || dreams.some((d) => !d.metrics)) {
    throw new EvalError("LINT_MEASUREMENTS_INCOMPLETE");
  }
  const distribution = metricDistribution(dreams.map((d) => proseMetricsSchema.parse(d.metrics)))!;
  const medians = Object.fromEntries(
    Object.entries(distribution).map(([key, value]) => [key, value.p50]),
  ) as unknown as ProseMetrics;
  const score = referenceProximity(medians, profile)!;
  const current = JSON.parse(await Deno.readTextFile(new URL("quality_metrics.json", dir)));
  if (current.results_sha256 !== await digest(text)) throw new EvalError("QUALITY_METRICS_INVALID");
  await savePrivate(new URL("quality_metrics.json", dir), {
    ...current,
    reference_proximity: score.inBand,
  });
  return score;
}

export async function main(args: string[], root = ROOT) {
  try {
    const result = args[0] === "analyze" &&
        (args.length === 2 || args.length === 4 && args[2] === "--annotations")
      ? await analyzeReferences(args[1], root, args[3])
      : args[0] === "score" && args.length === 3
      ? await scoreReferenceRun(args[1], args[2], root)
      : (() => {
        throw new EvalError("USAGE");
      })();
    console.log(JSON.stringify(result));
    return 0;
  } catch (error) {
    console.log(
      JSON.stringify({
        code: error instanceof EvalError ? error.code : "REFERENCE_ANALYSIS_FAILED",
      }),
    );
    return 1;
  }
}
if (import.meta.main) Deno.exit(await main(Deno.args));

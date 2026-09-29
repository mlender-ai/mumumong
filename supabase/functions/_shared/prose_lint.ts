import { BANNED_EXPRESSIONS } from "../engine-validate/validate.ts";

export type NarrativeVoice = "first_person_past" | "third_person_past";
export const CORE_PROSE_METRICS = [
  "sent_len_mean",
  "sent_len_cv",
  "ending_top_share",
  "subject_lead_rate",
  "one_sentence_para_rate",
  "mobile_lines_per_para",
  "present_tense_share",
  "short_sentence_rate",
  "dialogue_ratio",
  "first_sentence_len",
] as const;
export interface ProseMetrics {
  ending_top_share: number;
  ending_max_run: number;
  subject_lead_rate: number;
  translationese_per_1k: number;
  named_emotion_per_1k: number;
  simile_per_1k: number;
  conj_lead_rate: number;
  sent_len_mean: number;
  sent_len_cv: number;
  para_count: number;
  para_len_mean: number;
  dialogue_ratio: number;
  meta_dream_hits: number;
  one_sentence_para_rate: number;
  mobile_lines_per_para: number;
  present_tense_share: number;
  short_sentence_rate: number;
  ellipsis_dash_per_1k: number;
  dialogue_para_rate: number;
  first_sentence_len: number;
}
const chars = (text: string) => [...text].length;
const mean = (values: number[]) => values.reduce((a, b) => a + b, 0) / (values.length || 1);
const ratio = (n: number, total: number) => total ? n / total : 0;
function hits(text: string, pattern: RegExp): number {
  return [...text.matchAll(new RegExp(pattern.source, "gu"))].length;
}

// Terminal marks within speech do not split until its quote closes. NFC and code points
// make the metrics independent of UTF-16 surrogate pairs and decomposed Korean input.
export function splitProseSentences(text: string): string[] {
  const input = [...text.normalize("NFC").trim()];
  const result: string[] = [];
  let start = 0, quote: "curly" | "straight" | null = null, pending = false;
  const boundary = (next?: string) => next === undefined || /\s/u.test(next);
  const flush = (end: number) => {
    const sentence = input.slice(start, end).join("").trim();
    if (sentence) result.push(sentence);
    start = end;
    pending = false;
  };
  for (let i = 0; i < input.length; i++) {
    const c = input[i], next = input[i + 1];
    if (c === "“" && quote === null) quote = "curly";
    else if ((c === "”" && quote === "curly") || (c === '"' && quote === "straight")) {
      quote = null;
      if (pending && boundary(next)) flush(i + 1);
    } else if (c === '"' && quote === null) quote = "straight";
    else if (/[.!?…]/u.test(c) && (boundary(next) || next === "”" || next === '"')) {
      if (quote) pending = true;
      else flush(i + 1);
    }
  }
  flush(input.length);
  return result;
}

function dialogueChars(text: string): number {
  let quote: "curly" | "straight" | null = null, count = 0;
  for (const c of text) {
    if (c === "“" && quote === null) quote = "curly";
    else if ((c === "”" && quote === "curly") || (c === '"' && quote === "straight")) quote = null;
    else if (c === '"' && quote === null) quote = "straight";
    else if (quote) count++;
  }
  return count;
}

export function lintProse(paragraphs: readonly string[], voice: NarrativeVoice): ProseMetrics {
  const paras = paragraphs.map((p) => p.normalize("NFC").trim()).filter(Boolean);
  const groups = paras.map(splitProseSentences), sentences = groups.flat();
  const text = paras.join("\n"), total = paras.reduce((n, p) => n + chars(p), 0);
  const endings = sentences.map((s) => {
    const words = s.replace(/[.!?…“”"\s]+$/gu, "").split(/\s+/u);
    return [...(words.at(-1) ?? "")];
  });
  const counts = new Map<string, number>();
  let previous = "", run = 0, maxRun = 0;
  for (const word of endings) {
    const ending = word.slice(-2).join("");
    counts.set(ending, (counts.get(ending) ?? 0) + 1);
    run = ending === previous ? run + 1 : 1;
    maxRun = Math.max(maxRun, run);
    previous = ending;
  }
  const lengths = sentences.map(chars), average = mean(lengths);
  const subject = voice === "first_person_past"
    ? /^(나는|나도|내가)(?=\s|[,.!?…“”"]|$)/u
    : /^(그는|그녀는|그가|그녀가)(?=\s|[,.!?…“”"]|$)/u;
  const lead = (s: string) => s.replace(/^[\s“”"]+/u, "");
  const per1k = (count: number) => ratio(count * 1000, total);
  return {
    ending_top_share: ratio(Math.max(0, ...counts.values()), sentences.length),
    ending_max_run: maxRun,
    subject_lead_rate: ratio(
      sentences.filter((s) => subject.test(lead(s))).length,
      sentences.length,
    ),
    translationese_per_1k: per1k(
      hits(
        text,
        /것이었다|에 대해(?:서)?|(?:을|를) 가지고 있|되어지|에 있어(?:서)?|로 인해|중 하나/u,
      ) +
        sentences.filter((s) => /^그것은/u.test(lead(s))).length,
    ),
    named_emotion_per_1k: per1k(
      hits(
        text,
        /(?:불안|두려움|공포|슬픔|그리움|외로움|안도|설렘|긴장)(?:감)?(?:이|가)?\s+(?:밀려|몰려|엄습|차올|스며|피어)|(?:기분|느낌|감정)이 들었다|느껴졌다/u,
      ),
    ),
    simile_per_1k: per1k(hits(text, /마치|듯이/u)),
    conj_lead_rate: ratio(
      sentences.filter((s) =>
        /^(그리고|그러자|그래서|하지만|그런데|그러나|그러고는)/u.test(lead(s))
      ).length,
      sentences.length,
    ),
    sent_len_mean: average,
    sent_len_cv: average ? Math.sqrt(mean(lengths.map((n) => (n - average) ** 2))) / average : 0,
    para_count: paras.length,
    para_len_mean: ratio(total, paras.length),
    dialogue_ratio: ratio(paras.reduce((n, p) => n + dialogueChars(p), 0), total),
    meta_dream_hits: BANNED_EXPRESSIONS.reduce((n, pattern) => n + hits(text, pattern), 0),
    one_sentence_para_rate: ratio(groups.filter((g) => g.length === 1).length, groups.length),
    mobile_lines_per_para: ratio(total, paras.length * 20),
    present_tense_share: ratio(
      endings.filter((w) =>
        w.at(-1) === "다" &&
        !/[었았였했겠]/u.test(w.slice(-3).join(""))
      ).length,
      sentences.length,
    ),
    short_sentence_rate: ratio(lengths.filter((n) => n <= 8).length, sentences.length),
    ellipsis_dash_per_1k: per1k(hits(text, /[…—]/u)),
    dialogue_para_rate: ratio(paras.filter((p) => /^[“"]/u.test(p)).length, paras.length),
    first_sentence_len: lengths[0] ?? 0,
  };
}

export function metricDistribution(metrics: readonly ProseMetrics[]) {
  if (!metrics.length) return null;
  return Object.fromEntries(
    Object.keys(metrics[0]).map((key) => {
      const values = metrics.map((m) => m[key as keyof ProseMetrics]).sort((a, b) => a - b);
      const quantile = (p: number) => values[Math.max(0, Math.ceil(values.length * p) - 1)];
      return [key, {
        p10: quantile(.1),
        p25: quantile(.25),
        p50: quantile(.5),
        p75: quantile(.75),
        p90: quantile(.9),
      }];
    }),
  ) as Record<
    keyof ProseMetrics,
    { p10: number; p25: number; p50: number; p75: number; p90: number }
  >;
}

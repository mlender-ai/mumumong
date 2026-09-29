import { assert, assertEquals } from "@std/assert";
import { CORE_PROSE_METRICS, lintProse, splitProseSentences } from "./prose_lint.ts";
const lint = (p: string[]) => lintProse(p, "first_person_past");
Deno.test("prose sentence boundaries respect speech, ellipses, whitespace and unterminated speech", () => {
  assertEquals(splitProseSentences(" “왔다. 벌써?” 나는 섰다.\n왜?"), [
    "“왔다. 벌써?”",
    "나는 섰다.",
    "왜?",
  ]);
  assertEquals(splitProseSentences('"왔다. 정말?" …\n갔다!'), ['"왔다. 정말?"', "…", "갔다!"]);
  assertEquals(splitProseSentences("기다려…… 잠깐."), ["기다려……", "잠깐."]);
  assertEquals(splitProseSentences("“왔다. 아직"), ["“왔다. 아직"]);
  assertEquals(splitProseSentences("1.2는 수다. 됐다."), ["1.2는 수다.", "됐다."]);
});
Deno.test("prose endings, leads and tense have positive and negative controls", () => {
  const m = lint(["  나는 했다. 나도 했다. 내가 했다. 문이 닫힌다."]);
  assertEquals(m.ending_top_share, .75);
  assertEquals(m.ending_max_run, 3);
  assertEquals(m.subject_lead_rate, .75);
  assertEquals(m.present_tense_share, .25);
  assertEquals(lint(["문이 열렸다."]).subject_lead_rate, 0);
  assertEquals(lintProse(["그녀는 섰다. 그가 걷는다."], "third_person_past").subject_lead_rate, 1);
  assertEquals(lint(["나는 했다. 나도 봤다. 내가 했다."]).ending_max_run, 1);
  assertEquals(lint(["걸었다. 보았다. 하였다. 했었다. 하겠다."]).present_tense_share, 0);
});
Deno.test("prose translation patterns count occurrences not paragraphs", () => {
  for (
    const text of [
      "것이었다",
      "에 대해서",
      "을 가지고 있",
      "되어지",
      "에 있어서",
      "로 인해",
      "중 하나",
      "그것은",
    ]
  ) {
    assert(lint([text]).translationese_per_1k > 0);
  }
  assertEquals(lint(["문이 열렸다. 사람은 그것은 아니라고 말했다."]).translationese_per_1k, 0);
  assertEquals(lint(["것이었다 것이었다"]).translationese_per_1k, 2000 / 9);
});
Deno.test("prose named emotion and simile deliberately exclude sensory texture and처럼", () => {
  for (const text of ["불안감이 밀려", "설렘이 피어", "감정이 들었다", "느껴졌다"]) {
    assert(lint([text]).named_emotion_per_1k > 0);
  }
  assertEquals(lint(["손끝이 떨렸다."]).named_emotion_per_1k, 0);
  assert(lint(["마치 듯이"]).simile_per_1k > 0);
  assertEquals(lint(["종이처럼"]).simile_per_1k, 0);
});
Deno.test("prose conjunctions only at sentence leads, quote-aware", () => {
  assertEquals(lint([" “그리고 간다.” 하지만 쉰다. 문은 그대로다."]).conj_lead_rate, 2 / 3);
  assertEquals(lint(["문 그리고 바닥."]).conj_lead_rate, 0);
});
Deno.test("prose lengths, variability, paragraphs, mobile density and first sentence are code-point based", () => {
  const m = lint(["가.", "가나다라.", " "]);
  assertEquals(m.para_count, 2);
  assertEquals(m.sent_len_mean, 3.5);
  assertEquals(m.sent_len_cv, 1.5 / 3.5);
  assertEquals(m.para_len_mean, 3.5);
  assertEquals(m.mobile_lines_per_para, .175);
  assertEquals(m.first_sentence_len, 2);
  assertEquals(m.short_sentence_rate, 1);
  assertEquals(m.one_sentence_para_rate, 1);
  assertEquals(lint(["아주 긴 문장을 새로 지었다. 둘째다."]).one_sentence_para_rate, 0);
  assertEquals(lint(["아주 길고 긴 문장을 새로 지었다."]).short_sentence_rate, 0);
  assertEquals(lint(["가. 나."]).sent_len_cv, 0);
  assertEquals(lint(["😀."]).first_sentence_len, 2);
  assertEquals(lint(["가."]).first_sentence_len, 2);
});
Deno.test("prose dialogue, meta-dream and breathing marks include repeats with negative controls", () => {
  const m = lint(["“가.”", '"나."']);
  assertEquals(m.dialogue_ratio, .5);
  assertEquals(m.dialogue_para_rate, 1);
  assertEquals(lint(["꿈속에서 꿈속에서"]).meta_dream_hits, 2);
  assertEquals(lint(["…—"]).ellipsis_dash_per_1k, 1000);
  const clean = lint(["문이 열렸다."]);
  for (
    const key of [
      "dialogue_ratio",
      "dialogue_para_rate",
      "meta_dream_hits",
      "ellipsis_dash_per_1k",
    ] as const
  ) assertEquals(clean[key], 0);
});
Deno.test("empty prose has finite zero values and core list has exactly ten metrics", () => {
  assertEquals(CORE_PROSE_METRICS.length, 10);
  for (const value of Object.values(lint([" ", ""]))) assertEquals(value, 0);
});

import { assert, assertEquals, assertRejects, assertThrows } from "@std/assert";
import { CORE_PROSE_METRICS, lintProse } from "../../supabase/functions/_shared/prose_lint.ts";
import { referenceProximity } from "../../supabase/functions/_shared/reference_proximity.ts";
import {
  analyzeReferences,
  buildProfile,
  main,
  parseWorks,
  profileReport,
  type ReferenceWork,
  scoreReferenceRun,
} from "./reference_profile.ts";
import { referenceProfileSchema } from "./reference_contract.ts";
import { prepareAux } from "./judge_aux.ts";
import { JudgeStore } from "./judge_store.ts";
import { EvalError } from "./config.ts";
import { runEvaluation } from "./run.ts";
import config from "../../eval/configs/baseline_v10_measured.json" with { type: "json" };
import { qualityPreflight } from "./preflight.ts";
import { createReferenceDemo } from "./reference_demo.ts";

function works(n = 25): ReferenceWork[] {
  return Array.from(
    { length: n },
    (_, i) => ({
      id: `r${i}`,
      group: "positive",
      genre: (["현판", "판타지", "로맨스"] as const)[i % 3],
      voice: i % 3 ? "first" : "third",
      synthetic: false,
      opening: "문이 닫혔다.\n나는 다시 손잡이를 눌렀다.",
      ending: "누군가 이름을 불렀다.",
      labels: {
        opening_type: "action",
        first_event_para: 1,
        reveal_by_2000: ["goal_problem"],
        ending_type: "new_presence",
        hook_note: "직접 만든 합성 메모",
      },
    }),
  );
}
async function temporary() {
  const path = await Deno.makeTempDir({ prefix: "mumumong-reference-test-" }),
    root = new URL(`file://${path}/`);
  await Deno.mkdir(new URL("eval/reference/", root), { recursive: true });
  return { root, cleanup: () => Deno.remove(root, { recursive: true }) };
}

Deno.test("reference profile computes opening/ending quantiles, label proportions, voice splits and control direction only", async () => {
  const rows = works();
  rows.push({
    ...rows[0],
    id: "c",
    group: "control",
    opening: "긴 합성 설명 문장을 만들었다. 두번째 합성 문장을 붙였다.",
  });
  const { profile, reasons } = await buildProfile(rows, JSON.stringify(rows));
  assertEquals(reasons, []);
  assertEquals(profile.positive.count, 25);
  assertEquals(profile.control!.count, 1);
  assertEquals(profile.voices.first!.count, 16);
  assertEquals(profile.voices.third!.count, 9);
  assertEquals(profile.positive.labels.opening_type.action, 1);
  assertEquals(profile.positive.labels.reveal_by_2000.goal_problem, 1);
  assertEquals(profile.positive.labels.first_event_para_p50, 1);
  assert(profile.median_deltas!.opening.sent_len_mean < 0);
  assertEquals(referenceProfileSchema.safeParse(profile).success, true);
  const emitted = profileReport(profile);
  assert(!emitted.includes(rows[0].opening));
  assert(!emitted.includes(rows[0].labels!.hook_note));
  assert(!JSON.stringify(profile).includes("r0"));
  assert(emitted.includes("유의성을 주장하지 않는다"));
  assert(emitted.includes("장르 문법 제외"));
});
Deno.test("reference proximity has ten inclusive core bands only; missing/unconfirmed profile is unverified", async () => {
  const { profile } = await buildProfile(works(), "synthetic metadata");
  const metrics = lintProse(["문이 닫혔다.", "나는 다시 손잡이를 눌렀다."], "first_person_past");
  // Direct synthetic numeric bands exercise both boundary inclusions and non-core exclusion.
  for (const key of CORE_PROSE_METRICS) {
    profile.positive.opening[key] = {
      p10: metrics[key],
      p25: metrics[key],
      p50: metrics[key],
      p75: metrics[key] + 1,
      p90: metrics[key] + 1,
    };
  }
  assertEquals(referenceProximity(metrics, profile)!.inBand, 10);
  const changed = { ...metrics, translationese_per_1k: 999999 };
  assertEquals(referenceProximity(changed, profile)!.inBand, 10);
  assertEquals(
    referenceProximity({ ...changed, first_sentence_len: metrics.first_sentence_len + 1 }, profile)!
      .inBand,
    10,
  );
  assertEquals(
    referenceProximity({ ...changed, first_sentence_len: metrics.first_sentence_len + 2 }, profile)!
      .inBand,
    9,
  );
  assertEquals(referenceProximity(metrics), null);
  assertEquals(referenceProximity(metrics, { ...profile, eligible: false }), null);
  assertThrows(() => referenceProximity({ ...metrics, first_sentence_len: NaN }, profile));
});
Deno.test("reference requirements fail closed on count, first-person share, genre concentration, labels and synthetic sources", async () => {
  for (
    const [rows, reason] of [
      [works(24), "POSITIVE_COUNT"],
      [works().map((r) => ({ ...r, voice: "third" as const })), "FIRST_PERSON_SHARE"],
      [
        works().map((r) => ({ ...r, genre: "현판" as const })),
        "GENRE_CONCENTRATION",
      ],
      [works().map((r) => ({ ...r, labels: undefined })), "LABELS_INCOMPLETE"],
      [works().map((r) => ({ ...r, synthetic: true })), "SYNTHETIC_REFERENCES"],
    ] as [ReferenceWork[], string][]
  ) {
    const result = await buildProfile(rows, "synthetic unit metadata");
    assertEquals(result.profile.eligible, false);
    assert(result.reasons.includes(reason));
  }
});
Deno.test("reference parsing rejects duplicates, unknown titles, malformed labels and out-of-range event paragraphs without excerpts", () => {
  const row = works(1)[0];
  for (
    const text of [
      "not JSON private prose",
      JSON.stringify({ ...row, title: "private title" }),
      JSON.stringify({ ...row, labels: { ...row.labels, first_event_para: 9 } }),
      [row, row].map((r) => JSON.stringify(r)).join("\n"),
    ]
  ) {
    assertEquals(assertThrows(() => parseWorks(text), EvalError).message, "REFERENCE_INVALID");
  }
  assertEquals(parseWorks(JSON.stringify(row)).length, 1);
});
Deno.test("Q09 exact work format is labelable, persisted, resumable and consumed without automatic labels or source leaks", async () => {
  const t = await temporary();
  try {
    const rows = works(2).map((r) => ({ ...r, synthetic: true, labels: undefined })),
      source = rows.map((r) => JSON.stringify(r)).join("\n") + "\n";
    await Deno.writeTextFile(new URL("eval/reference/works.jsonl", t.root), source);
    const prepared = await prepareAux("annotate", "eval/reference/works.jsonl", undefined, t.root);
    const store = await JudgeStore.open(prepared, t.root);
    let votesPath: string;
    try {
      const state = await store.state();
      assert("reference_form" in state);
      assertEquals(state.reference_form!.opening_paragraphs, 2);
      assertEquals(state.demo, true);
      assertEquals(state.reference_labels, null);
      await assertRejects(
        () => store.submit({ id: "r0", revision: 0, choice: "keep", annotations: [] }),
        EvalError,
        "SUBMISSION_INVALID",
      );
      await assertRejects(
        () =>
          store.submit({
            id: "r0",
            revision: 0,
            choice: "keep",
            annotations: [],
            reference_labels: { ...works()[0].labels, first_event_para: 3 },
          }),
        EvalError,
        "SUBMISSION_INVALID",
      );
      for (const item of store.judgment.items) {
        await store.submit({
          id: item.id,
          revision: store.judgment.revision,
          choice: "keep",
          annotations: [],
          reference_labels: works()[0].labels,
        });
      }
      votesPath = `eval/judgments/${store.path.pathname.split("/").at(-1)}`;
    } finally {
      await store.close();
    }
    const resumed = await JudgeStore.open(prepared, t.root);
    try {
      const state = await resumed.state(0);
      assert("reference_labels" in state);
      assertEquals(state.reference_labels!.opening_type, "action");
    } finally {
      await resumed.close();
    }
    const result = await analyzeReferences("eval/reference/works.jsonl", t.root, votesPath);
    assertEquals(result.eligible, false);
    assertEquals(result.positive, 2);
    const profile = await Deno.readTextFile(new URL("eval/reference/profile.json", t.root));
    assert(!profile.includes(rows[0].opening));
    assert(!profile.includes("합성 메모"));
    assertEquals(
      (await Deno.stat(new URL("eval/reference/profile.json", t.root))).mode! & 0o777,
      0o600,
    );
    await Deno.writeTextFile(new URL("eval/reference/works.jsonl", t.root), source + "\n");
    await assertRejects(
      () => analyzeReferences("eval/reference/works.jsonl", t.root, votesPath),
      EvalError,
      "REFERENCE_LABELS_INCOMPLETE",
    );
  } finally {
    await t.cleanup();
  }
});
Deno.test("reference scorer preserves fidelity fields, binds actual result hash and rejects missing metrics/unconfirmed/holdout", async () => {
  const t = await temporary();
  try {
    await Deno.mkdir(new URL("eval/configs/", t.root), { recursive: true });
    await Deno.mkdir(new URL("eval/fixtures/", t.root), { recursive: true });
    await Deno.writeTextFile(new URL("eval/configs/m.json", t.root), JSON.stringify(config));
    await Deno.copyFile(
      new URL("../../eval/fixtures/sample.jsonl", import.meta.url),
      new URL("eval/fixtures/sample.jsonl", t.root),
    );
    const run = await runEvaluation(
      { config: "eval/configs/m.json", set: "fixtures", concurrency: 1, resume: false, lint: true },
      t.root,
      new Date("2026-01-01"),
    );
    const runPath = `eval/runs/${run.directory.pathname.split("/").filter(Boolean).at(-1)}`;
    const { profile } = await buildProfile(works(), "synthetic unit metadata");
    await Deno.writeTextFile(
      new URL("eval/reference/profile.json", t.root),
      JSON.stringify(profile),
    );
    const scored = await scoreReferenceRun(runPath, "eval/reference/profile.json", t.root);
    assert(scored.inBand >= 0 && scored.inBand <= 10);
    const sidecar = JSON.parse(
      await Deno.readTextFile(new URL("quality_metrics.json", run.directory)),
    );
    assertEquals(sidecar.reference_proximity, scored.inBand);
    assertEquals(sidecar.fidelity, undefined);
    await Deno.writeTextFile(
      new URL("eval/reference/profile.json", t.root),
      JSON.stringify({ ...profile, eligible: false }),
    );
    await assertRejects(
      () => scoreReferenceRun(runPath, "eval/reference/profile.json", t.root),
      EvalError,
      "REFERENCE_PROFILE_UNVERIFIED",
    );
    const manifestPath = new URL("config.json", run.directory),
      manifest = JSON.parse(await Deno.readTextFile(manifestPath));
    manifest.identity.set = "holdout";
    await Deno.writeTextFile(manifestPath, JSON.stringify(manifest));
    await assertRejects(
      () => scoreReferenceRun(runPath, "eval/reference/profile.json", t.root),
      EvalError,
      "HOLDOUT_LOCKED_UNTIL_Q32",
    );
  } finally {
    await t.cleanup();
  }
});
Deno.test("reference CLI never forwards malformed private input, titles or parser details", async () => {
  const t = await temporary(), output: string[] = [], original = console.log;
  try {
    await Deno.writeTextFile(
      new URL("eval/reference/works.jsonl", t.root),
      '{"opening":"private reference sentence"',
    );
    console.log = (v) => output.push(String(v));
    assertEquals(await main(["analyze", "eval/reference/works.jsonl"], t.root), 1);
    assert(!output.join("").includes("private reference sentence"));
    assert(!output.join("").includes("SyntaxError"));
  } finally {
    console.log = original;
    await t.cleanup();
  }
});

Deno.test("readiness check reports only missing-data counts and credential booleans without opening holdout", async () => {
  const t = await temporary();
  try {
    await Deno.mkdir(new URL("eval/corpus/", t.root));
    await Deno.writeTextFile(
      new URL("eval/corpus/holdout.jsonl", t.root),
      "invalid private holdout that must never be parsed",
    );
    const result = await qualityPreflight(t.root, () => "private credential value");
    assertEquals(result.dev.available, false);
    assertEquals(result.reference.available, false);
    assertEquals(result.measured_baseline_ready, false);
    assertEquals(result.holdout, "locked_until_Q32");
    assertEquals(result.credentials.OPENAI_API_KEY, true);
    assert(!JSON.stringify(result).includes("private credential value"));
  } finally {
    await t.cleanup();
  }
});

Deno.test("reference demo is private/synthetic and new launches cannot silently resume previous demo votes", async () => {
  const t = await temporary();
  try {
    const a = await createReferenceDemo(t.root), b = await createReferenceDemo(t.root);
    const first = parseWorks(await Deno.readTextFile(new URL(a, t.root))),
      second = parseWorks(await Deno.readTextFile(new URL(b, t.root)));
    assert(first.every((r) => r.synthetic));
    assertEquals(first.length, 2);
    assert(first[0].id !== second[0].id);
    const store = await JudgeStore.open(await prepareAux("annotate", a, undefined, t.root), t.root);
    try {
      for (const item of store.judgment.items) {
        await store.submit({
          id: item.id,
          revision: store.judgment.revision,
          choice: "keep",
          annotations: [],
          reference_labels: { ...works()[0].labels, first_event_para: 1 },
        });
      }
      assertEquals((await store.state()).demo, true); // Synthetic banner remains visible on completion.
    } finally {
      await store.close();
    }
    const fresh = await JudgeStore.open(await prepareAux("annotate", b, undefined, t.root), t.root);
    try {
      assertEquals((await fresh.state()).completed, 0);
    } finally {
      await fresh.close();
    }
  } finally {
    await t.cleanup();
  }
});

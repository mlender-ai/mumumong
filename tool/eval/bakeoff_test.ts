import { assert, assertEquals, assertRejects, assertThrows } from "@std/assert";
import baselineJson from "../../eval/configs/baseline_v10_measured.json" with { type: "json" };
import gpt54Json from "../../eval/configs/bakeoff_gpt54.json" with { type: "json" };
import sonnet5Json from "../../eval/configs/bakeoff_sonnet5.json" with { type: "json" };
import {
  adapterFor,
  estimatedCostKrw,
  priceFor,
  resolveModel,
} from "../../supabase/functions/_shared/llm/registry.ts";
import {
  automaticScreen,
  candidateReadiness,
  main,
  prepareCandidates,
  screenCandidate,
} from "./bakeoff.ts";
import {
  baselineModels,
  candidateConfig,
  fidelityEvidence,
  q10ModelsMatch,
} from "./bakeoff_contract.ts";
import { configSchema, type CorpusCase, digest, EvalError, PROMPT_VERSIONS } from "./config.ts";
import { FIDELITY_PROMPT_VERSION } from "../../supabase/functions/_shared/fidelity_judge.ts";
import { FixtureLlm } from "./fixture_llm.ts";
import { type RunStats } from "./judgment.ts";
import { evaluateCase } from "./pipeline.ts";
import { buildReport } from "./report.ts";
import { prepareAux } from "./judge_aux.ts";
import { JudgeStore } from "./judge_store.ts";
import {
  calibrateFidelity,
  refreshMeasurements,
  writeMeasurementArtifacts,
} from "./measurements.ts";

const base = configSchema.parse(baselineJson);
const writer = "anthropic:claude-sonnet-5";
const candidate = candidateConfig(base, "example", writer);
const gpt54 = configSchema.parse(gpt54Json);
const marker = "SYNTHETIC_PRIVATE_ERROR_MARKER";
const stats = (): RunStats => ({
  engine_version: "v10",
  models: { ...base.models },
  settings_sha256: "synthetic",
  prompt_versions: { ...PROMPT_VERSIONS },
  source_sha256: "0".repeat(64),
  cases: 21,
  failures: 0,
  dream_count: 30,
  mean_cost_krw: 100,
  max_cost_krw: 200,
  p95_ms: 90000,
  provenance_errors: 0,
  v2_compliance: 1,
  fidelity_rate: 0.95,
  reference_proximity: null,
});

async function setup() {
  const temp = await Deno.makeTempDir({ prefix: "mumumong-q10-test-" });
  const root = new URL(`file://${temp}/`);
  await Deno.mkdir(new URL("eval/configs/", root), { recursive: true });
  await Deno.writeTextFile(new URL("eval/configs/base.json", root), JSON.stringify(base));
  return { root, cleanup: () => Deno.remove(root, { recursive: true }) };
}

Deno.test("Q10 checked-in candidates span two providers and pin GPT-5.4 price and snapshot", () => {
  const configs = [gpt54, configSchema.parse(sonnet5Json)];
  assertEquals(new Set(configs.map((c) => resolveModel(c.models.write).provider)).size, 2);
  for (const config of configs) {
    assert(q10ModelsMatch(base.models, config.models));
    assertEquals(config.settings, base.settings);
    assertEquals(config.engine_version, base.engine_version);
  }
  assertEquals(gpt54.models.write, "openai:gpt-5.4-2026-03-05");
  assertEquals(resolveModel("openai:gpt-5.4").id, "gpt-5.4-2026-03-05");
  assertEquals(priceFor(gpt54.models.write), { input: 2.5, output: 15 });
  assertEquals(estimatedCostKrw(gpt54.models.write, 1000, 1000), 24.5);
  assertEquals(gpt54.models.judge, base.models.judge);
  assertEquals(q10ModelsMatch(base.models, { ...gpt54.models, judge: "openai:gpt-5.4" }), false);
});

Deno.test("fidelity distinguishes shared provider, cross-provider and unknown identity without fabricating rates", () => {
  assertEquals(fidelityEvidence(gpt54.models, 0.95), {
    rate: 0.95,
    measured: true,
    same_provider: true,
    label: "참고용",
  });
  assertEquals(fidelityEvidence(candidate.models, 0.95).label, "교차 공급사");
  assertEquals(
    fidelityEvidence({ ...candidate.models, polish: gpt54.models.polish }, 0.95).label,
    "참고용",
  );
  assertEquals(fidelityEvidence({ ...gpt54.models, write: "openai:gpt-5.4" }, null), {
    rate: null,
    measured: false,
    same_provider: true,
    label: "참고용",
  });
  assertEquals(fidelityEvidence({ ...gpt54.models, judge: null }, 0.95).label, "미검증");
  const A = stats(), B = { ...stats(), models: gpt54.models };
  const screen = automaticScreen(A, B);
  assertEquals(screen.fidelity.B.label, "참고용");
  assertEquals(
    screen.checks.find((c) => c.code === "FIDELITY_DROP_MAX_5PP")?.evidence_label,
    "참고용",
  );
  assertEquals(screen.result, "SURVIVES_AUTOMATIC_SCREEN");
  B.fidelity_rate = null;
  assertEquals(automaticScreen(A, B).result, "INCOMPLETE");
});

Deno.test("GPT-5.4 candidate uses unchanged OpenAI structured and text payloads (stub only)", async () => {
  const requests: Record<string, unknown>[] = [];
  const model = resolveModel(gpt54.models.write);
  const adapter = adapterFor(model, {
    fetcher: (_url, init) => {
      const body = JSON.parse(String(init?.body));
      requests.push(body);
      return Promise.resolve(
        new Response(JSON.stringify({
          choices: [{ message: { content: body.response_format ? '{"ok":true}' : "synthetic" } }],
          usage: { prompt_tokens: 10, completion_tokens: 4 },
        })),
      );
    },
  });
  const request = {
    model: model.id,
    apiKey: "sk-proj-synthetic-key",
    system: "Synthetic test only.",
    input: {},
    temperature: 0.75,
    maxTokens: 128,
  };
  const result = await adapter.structured<{ ok: boolean }>({
    ...request,
    schemaName: "synthetic",
    schema: {
      type: "object",
      properties: { ok: { type: "boolean" } },
      required: ["ok"],
      additionalProperties: false,
    },
  });
  assertEquals(result.value, { ok: true });
  assertEquals(
    (await adapter.text({ ...request, user: "Synthetic test only." })).text,
    "synthetic",
  );
  for (const body of requests) {
    assertEquals(body.model, "gpt-5.4-2026-03-05");
    assertEquals(body.temperature, 0.75);
    assertEquals(body.max_completion_tokens, 128);
    assertEquals(body.store, false);
    assertEquals(body.reasoning_effort, undefined);
  }
});

Deno.test("Q10 changes all three prose roles, keeps fixed roles/judge and canonicalizes aliases", () => {
  assert(baselineModels(base.models));
  assert(q10ModelsMatch(base.models, candidate.models));
  assertEquals([candidate.models.write, candidate.models.write_aux, candidate.models.polish], [
    writer,
    writer,
    writer,
  ]);
  for (const role of ["extract", "link", "plan", "remember", "judge"] as const) {
    assertEquals(candidate.models[role], base.models[role]);
    const changed = structuredClone(candidate.models);
    changed[role] = "groq:openai/gpt-oss-120b";
    if (changed[role] === base.models[role]) changed[role] = "groq:openai/gpt-oss-20b";
    assertEquals(q10ModelsMatch(base.models, changed), false);
  }
  const aliasBase = { ...base, models: { ...base.models, judge: "groq:openai/gpt-oss-20b" } };
  // Judge also must differ from the baseline's auxiliary writer.
  assertEquals(baselineModels(aliasBase.models), false);
  const commonJudge = { ...base, models: { ...base.models, judge: "anthropic:claude-sonnet-4-6" } };
  const aliasCandidate = candidateConfig(commonJudge, "alias", "openai:gpt-4.1");
  assertEquals(aliasCandidate.models.write, "openai:gpt-4.1-2025-04-14");
});

Deno.test("Q10 rejects main-write-only substitutions, mixed prose models, self-judging and baseline candidates", () => {
  assertEquals(q10ModelsMatch(base.models, { ...base.models, write: writer }), false);
  assertEquals(
    q10ModelsMatch(base.models, { ...candidate.models, polish: base.models.polish }),
    false,
  );
  for (const model of [base.models.write, base.models.judge!, "openai:gpt-4.1", "unknown:model"]) {
    assertThrows(() => candidateConfig(base, "bad", model), EvalError);
  }
  assertEquals(q10ModelsMatch({ ...base.models, extract: writer }, candidate.models), false);
  assertEquals(q10ModelsMatch(base.models, { ...candidate.models, extra: writer }), false);
});

Deno.test("candidate preparation validates entire batch, preserves baseline and refuses overwrites", async () => {
  const t = await setup();
  try {
    const before = await Deno.readTextFile(new URL("eval/configs/base.json", t.root));
    assertEquals(
      await prepareCandidates("eval/configs/base.json", [
        { label: "a", model: writer },
        { label: "b", model: "anthropic:claude-sonnet-4-6" },
      ], t.root),
      { candidate_configs_created: 2, production_changed: false },
    );
    for (const label of ["a", "b"]) {
      const parsed = configSchema.parse(JSON.parse(
        await Deno.readTextFile(
          new URL(`eval/configs/bakeoff_${label}.json`, t.root),
        ),
      ));
      assert(q10ModelsMatch(base.models, parsed.models));
    }
    assertEquals(await Deno.readTextFile(new URL("eval/configs/base.json", t.root)), before);
    await assertRejects(
      () => prepareCandidates("eval/configs/base.json", [{ label: "a", model: writer }], t.root),
      EvalError,
      "CONFIG_EXISTS_NO_OVERWRITE",
    );
    await assertRejects(
      () =>
        prepareCandidates("eval/configs/base.json", [
          { label: "new", model: writer },
          { label: "bad", model: base.models.judge! },
        ], t.root),
      EvalError,
      "Q10_MODEL_COMPARISON_INVALID",
    );
    await assertRejects(
      () => Deno.stat(new URL("eval/configs/bakeoff_new.json", t.root)),
      Deno.errors.NotFound,
    );
  } finally {
    await t.cleanup();
  }
});

Deno.test("candidate preparation enforces max three, unique canonical models and safe paths including symlinks", async () => {
  const t = await setup();
  try {
    for (
      const choices of [
        [],
        Array.from({ length: 4 }, (_, i) => ({ label: `a${i}`, model: writer })),
      ]
    ) {
      await assertRejects(
        () => prepareCandidates("eval/configs/base.json", choices, t.root),
        EvalError,
        "CANDIDATE_COUNT_1_TO_3",
      );
    }
    await assertRejects(
      () =>
        prepareCandidates("eval/configs/base.json", [
          { label: "a", model: writer },
          { label: "b", model: writer },
        ], t.root),
      EvalError,
      "CANDIDATE_DUPLICATE",
    );
    await assertRejects(
      () => prepareCandidates("eval/configs/base.json", [{ label: "../x", model: writer }], t.root),
      EvalError,
      "CANDIDATE_LABEL_INVALID",
    );
    await assertRejects(
      () =>
        prepareCandidates(
          "eval/configs/../../private.json",
          [{ label: "a", model: writer }],
          t.root,
        ),
      EvalError,
      "CONFIG_PATH_REQUIRED",
    );
    await Deno.symlink(
      new URL("eval/configs/base.json", t.root).pathname,
      new URL("eval/configs/link.json", t.root),
    );
    await assertRejects(
      () => prepareCandidates("eval/configs/link.json", [{ label: "a", model: writer }], t.root),
      EvalError,
      "CONFIG_PATH_REQUIRED",
    );
    const changed = { ...base, settings: { ...base.settings, style: "lyrical" } };
    await Deno.writeTextFile(new URL("eval/configs/base.json", t.root), JSON.stringify(changed));
    await assertRejects(
      () => prepareCandidates("eval/configs/base.json", [{ label: "a", model: writer }], t.root),
      EvalError,
      "BASELINE_SETTINGS_CHANGED",
    );
  } finally {
    await t.cleanup();
  }
});

Deno.test("automatic screen tests exact 5pp / 200KRW boundaries and missing calibrated evidence", () => {
  const A = stats(), B = stats();
  B.models = candidate.models;
  B.fidelity_rate = 0.9;
  B.failures = 1;
  assertEquals(automaticScreen(A, B).result, "SURVIVES_AUTOMATIC_SCREEN");
  B.failures = 2;
  assertEquals(automaticScreen(A, B).result, "REJECT");
  B.failures = 0;
  B.fidelity_rate = 0.899999;
  assertEquals(automaticScreen(A, B).result, "REJECT");
  B.fidelity_rate = 0.95;
  B.max_cost_krw = 200.001;
  assertEquals(automaticScreen(A, B).result, "REJECT");
  B.max_cost_krw = null;
  assertEquals(automaticScreen(A, B).result, "INCOMPLETE");
  B.max_cost_krw = 200;
  A.fidelity_rate = null;
  assertEquals(automaticScreen(A, B).result, "INCOMPLETE");
  assertEquals(automaticScreen(A, B).winner_selected, false);
  assertThrows(() => automaticScreen(A, { ...B, cases: 0 }));
});

Deno.test("G1 accepts whole prose-group substitutions, rejects drift and uses stricter 3pp fidelity", () => {
  const A = stats(), B = { ...stats(), models: candidate.models };
  const judgment = {
    version: 1 as const,
    mode: "ab" as const,
    seed: "0".repeat(32),
    revision: 21,
    identity: "0".repeat(64),
    set: "dev" as const,
    gate_eligible: true,
    stats: { A, B },
    items: Array.from({ length: 21 }, (_, i) => ({
      id: `fake${i}`,
      kind: i < 18 ? "single" as const : "sequence" as const,
      clarity: i < 18 ? (["fragment", "partial", "vivid"] as const)[i % 3] : "mixed" as const,
      audit: null,
      vote: {
        winner: "B" as const,
        automatic: "none" as const,
        not_ready: { A: false, B: false },
        reasons: [],
        problems: [],
      },
    })),
  };
  const gate = () =>
    buildReport(judgment, "G1").gate as {
      result: string;
      checks: { code: string; status: string }[];
    };
  assertEquals(gate().result, "PASS");
  B.fidelity_rate = 0.92;
  assertEquals(gate().result, "PASS");
  B.fidelity_rate = 0.90;
  assertEquals(automaticScreen(A, B).result, "SURVIVES_AUTOMATIC_SCREEN");
  assertEquals(gate().result, "FAIL");
  B.fidelity_rate = 0.95;
  B.models = { ...candidate.models, polish: base.models.polish };
  assertEquals(
    gate().checks.find((c) => c.code === "ONLY_PROSE_MODEL_GROUP_VARIES")!.status,
    "fail",
  );
  B.models = gpt54.models;
  const sharedProviderReport = buildReport(judgment, "G1");
  assertEquals((sharedProviderReport.fidelity as { B: { label: string } }).B.label, "참고용");
  assertEquals(
    (sharedProviderReport.gate as { checks: { code: string; evidence_label?: string }[] })
      .checks.find((c) => c.code === "FIDELITY")?.evidence_label,
    "참고용",
  );
  assertEquals(gate().result, "PASS");
  assertEquals(
    (buildReport(judgment).fidelity as { B: { label: string } }).B.label,
    "참고용",
  );
  B.models = candidate.models;
  B.source_sha256 = "1".repeat(64);
  assertEquals(gate().checks.find((c) => c.code === "SOURCE_FIXED")!.status, "fail");
  delete B.source_sha256;
  assertEquals(gate().checks.find((c) => c.code === "SOURCE_FIXED")!.status, "unverified");
});

async function runs(t: Awaited<ReturnType<typeof setup>>, set = "dev", fixture = false) {
  const records: CorpusCase[] = Array.from({ length: 18 }, (_, i) => ({
    id: `d${i}`,
    set: "dev",
    kind: "single",
    settings: null,
    raw_text: "새로 지어낸 가짜 꿈이다. 나는 파란 장갑을 창틀에 놓았다.",
    expected_clarity: (["fragment", "partial", "vivid"] as const)[i % 3],
  }));
  for (let i = 0; i < 3; i++) {
    records.push({
      id: `s${i}`,
      set: "dev",
      kind: "sequence",
      settings: null,
      dreams: Array.from(
        { length: 4 },
        () => ({
          raw_text: "나는 파란 장갑을 창틀에 놓았다. 가짜 꿈이다.",
          expected_clarity: "partial",
        }),
      ),
    });
  }
  const corpus = records.map((r) => JSON.stringify(r)).join("\n") + "\n";
  await Deno.mkdir(new URL("eval/corpus/", t.root), { recursive: true });
  await Deno.writeTextFile(new URL("eval/corpus/dev.jsonl", t.root), corpus);
  const results = await Promise.all(
    records.map((r) => evaluateCase(r, base, new FixtureLlm(), { lint: true, fidelity: true })),
  );
  for (const [name, config] of [["a", base], ["b", candidate]] as const) {
    const dir = new URL(`eval/runs/${name}/`, t.root);
    await Deno.mkdir(dir, { recursive: true });
    await Deno.writeTextFile(
      new URL("config.json", dir),
      JSON.stringify({
        ...config,
        prompt_versions: PROMPT_VERSIONS,
        identity: {
          set,
          fixture_llm: fixture,
          corpus_sha256: await digest(corpus),
          source_sha256: "0".repeat(64),
          measurements: { lint: true, fidelity: true, fidelity_version: FIDELITY_PROMPT_VERSION },
        },
      }),
    );
    await Deno.writeTextFile(
      new URL("results.jsonl", dir),
      results.map((r) => JSON.stringify(r)).join("\n") + "\n",
    );
    await writeMeasurementArtifacts(dir, records, results, config, t.root, set as "dev");
  }
}
async function changeManifest(
  t: Awaited<ReturnType<typeof setup>>,
  edit: (m: Record<string, unknown>) => void,
) {
  const path = new URL("eval/runs/b/config.json", t.root);
  const manifest = JSON.parse(await Deno.readTextFile(path));
  edit(manifest);
  await Deno.writeTextFile(path, JSON.stringify(manifest));
}

Deno.test("full synthetic dev-shaped run cannot survive without real calibrated fidelity; report is private metadata", async () => {
  const t = await setup();
  try {
    await runs(t);
    const report = await screenCandidate("eval/runs/a", "eval/runs/b", t.root);
    assertEquals(report.result, "INCOMPLETE");
    assertEquals(report.winner_selected, false);
    const path = new URL("eval/runs/b/q10_screening.json", t.root);
    const body = await Deno.readTextFile(path);
    assert(!body.includes("장갑") && !body.includes("raw_text") && !body.includes("passages"));
    if (Deno.build.os !== "windows") assertEquals((await Deno.stat(path)).mode! & 0o777, 0o600);
  } finally {
    await t.cleanup();
  }
});

Deno.test("synthetic certificate workflow authorizes first screen only and revokes changed human evidence", async () => {
  const t = await setup();
  try {
    // Unit-only dev-shaped fake data exercises the certificate path; not quality evidence.
    await runs(t);
    const store = await JudgeStore.open(
      await prepareAux("fidelity-audit", "eval/runs/a/fidelity_audit.json", "eval/runs/a", t.root),
      t.root,
    );
    let votesPath: string;
    try {
      for (const item of store.judgment.items) {
        await store.submit({
          id: item.id,
          revision: store.judgment.revision,
          choice: "agree",
        });
      }
      votesPath = `eval/judgments/${store.path.pathname.split("/").at(-1)}`;
    } finally {
      await store.close();
    }
    await calibrateFidelity("eval/runs/a", votesPath!, t.root);
    await refreshMeasurements("eval/runs/a", t.root);
    await refreshMeasurements("eval/runs/b", t.root);
    const result = await screenCandidate("eval/runs/a", "eval/runs/b", t.root);
    assertEquals(result.result, "SURVIVES_AUTOMATIC_SCREEN");
    assertEquals(result.human_judgment_required, true);
    assertEquals(result.winner_selected, false);
    const file = new URL(votesPath!, t.root);
    await Deno.writeTextFile(file, await Deno.readTextFile(file) + "\n");
    assertEquals(
      (await screenCandidate("eval/runs/a", "eval/runs/b", t.root)).result,
      "INCOMPLETE",
    );
  } finally {
    await t.cleanup();
  }
});

Deno.test("complete pipeline failure is rejected even when no final scenes can be linted", async () => {
  const t = await setup();
  try {
    await runs(t);
    const path = new URL("eval/runs/b/results.jsonl", t.root);
    const rows = (await Deno.readTextFile(path)).trim().split("\n").map((r) => JSON.parse(r));
    for (const row of rows) {
      row.status = "failed";
      row.scenes = [];
      for (const dream of row.dreams) {
        dream.status = "failed";
        dream.scene = null;
        delete dream.fidelity;
      }
    }
    await Deno.writeTextFile(path, rows.map((r) => JSON.stringify(r)).join("\n") + "\n");
    await Deno.remove(new URL("eval/runs/b/quality_metrics.json", t.root));
    assertEquals((await screenCandidate("eval/runs/a", "eval/runs/b", t.root)).result, "REJECT");
  } finally {
    await t.cleanup();
  }
});

Deno.test("screen rejects changed source, missing lint evidence and incomplete actual dev coverage", async () => {
  const t = await setup();
  try {
    await runs(t);
    await changeManifest(t, (m) => {
      (m.identity as Record<string, unknown>).source_sha256 = "1".repeat(64);
    });
    await assertRejects(
      () => screenCandidate("eval/runs/a", "eval/runs/b", t.root),
      EvalError,
      "Q10_SOURCE_CHANGED",
    );
    await changeManifest(t, (m) => {
      (m.identity as Record<string, unknown>).source_sha256 = "0".repeat(64);
    });
    const path = new URL("eval/runs/b/results.jsonl", t.root);
    const rows = (await Deno.readTextFile(path)).trim().split("\n").map((r) => JSON.parse(r));
    delete rows[0].dreams[0].metrics;
    await Deno.writeTextFile(path, rows.map((r) => JSON.stringify(r)).join("\n"));
    await assertRejects(
      () => screenCandidate("eval/runs/a", "eval/runs/b", t.root),
      EvalError,
      "QUALITY_METRICS_INVALID",
    );
    await Deno.remove(new URL("eval/runs/b/quality_metrics.json", t.root));
    await assertRejects(
      () => screenCandidate("eval/runs/a", "eval/runs/b", t.root),
      EvalError,
      "LINT_MEASUREMENTS_REQUIRED",
    );
    rows.shift();
    await Deno.writeTextFile(path, rows.map((r) => JSON.stringify(r)).join("\n"));
    await assertRejects(
      () => screenCandidate("eval/runs/a", "eval/runs/b", t.root),
      EvalError,
      "Q10_FULL_DEV_REQUIRED",
    );
  } finally {
    await t.cleanup();
  }
});

Deno.test("screen explicitly rejects fixtures/sentinel and locks holdout before results are opened", async () => {
  const t = await setup();
  try {
    for (
      const [set, fixture] of [["fixtures", true], ["sentinel", false], ["dev", true]] as const
    ) {
      await runs(t, set, fixture);
      await assertRejects(
        () => screenCandidate("eval/runs/a", "eval/runs/b", t.root),
        EvalError,
        "Q10_REQUIRES_REAL_DEV",
      );
    }
    await runs(t, "holdout");
    await Deno.remove(new URL("eval/runs/a/results.jsonl", t.root));
    await assertRejects(
      () => screenCandidate("eval/runs/a", "eval/runs/b", t.root),
      EvalError,
      "HOLDOUT_LOCKED_UNTIL_Q32",
    );
  } finally {
    await t.cleanup();
  }
});

Deno.test("readiness lists only required credential booleans, never keys, and requires full dev coverage", async () => {
  const t = await setup();
  try {
    await Deno.writeTextFile(
      new URL("eval/configs/candidate.json", t.root),
      JSON.stringify(candidate),
    );
    const read = (key: string) => key === "ANTHROPIC_API_KEY" ? undefined : marker;
    const state = await candidateReadiness("eval/configs/candidate.json", t.root, read);
    assertEquals(state.credentials, {
      GROQ_API_KEY: true,
      ANTHROPIC_API_KEY: false,
      OPENAI_API_KEY: true,
    });
    assertEquals(state.ready_for_measured_run, false);
    assert(!JSON.stringify(state).includes(marker));
    await runs(t);
    assertEquals(
      (await candidateReadiness("eval/configs/candidate.json", t.root, () => marker))
        .ready_for_measured_run,
      true,
    );
    await Deno.writeTextFile(
      new URL("eval/configs/candidate.json", t.root),
      JSON.stringify({ ...candidate, models: { ...candidate.models, judge: writer } }),
    );
    await assertRejects(
      () => candidateReadiness("eval/configs/candidate.json", t.root, read),
      EvalError,
      "FIDELITY_REQUIRES_DIFFERENT_MODEL",
    );
  } finally {
    await t.cleanup();
  }
});

Deno.test("bakeoff CLI redacts malformed args/private errors and returns distinct incomplete status", async () => {
  const t = await setup(), messages: string[] = [], log = (s: string) => messages.push(s);
  try {
    assertEquals(await main([marker], t.root, log), 1);
    assertEquals(
      await main(
        ["prepare", "--baseline", "eval/configs/base.json", "--candidate", `bad=${marker}`],
        t.root,
        log,
      ),
      1,
    );
    assertEquals(await main(["check", "eval/configs/base.json"], t.root, log), 2);
    await Deno.writeTextFile(new URL("eval/configs/private.json", t.root), marker);
    assertEquals(await main(["check", "eval/configs/private.json"], t.root, log), 1);
    assert(!messages.join("").includes(marker));
    await runs(t);
    assertEquals(await main(["screen", "eval/runs/a", "eval/runs/b"], t.root, log), 2);
  } finally {
    await t.cleanup();
  }
});

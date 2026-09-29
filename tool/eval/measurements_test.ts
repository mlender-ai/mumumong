import { assert, assertEquals, assertRejects } from "@std/assert";
import measuredJson from "../../eval/configs/baseline_v10_measured.json" with { type: "json" };
import { baselineReport, main as baselineMain } from "./baseline_report.ts";
import { configSchema, type CorpusCase, digest, EvalError, PROMPT_VERSIONS } from "./config.ts";
import { FixtureLlm } from "./fixture_llm.ts";
import { prepareAux } from "./judge_aux.ts";
import { prepareAB } from "./judge_inputs.ts";
import { JudgeStore } from "./judge_store.ts";
import {
  calibrated,
  calibrateFidelity,
  refreshMeasurements,
  writeMeasurementArtifacts,
} from "./measurements.ts";
import { evaluateCase, summarize } from "./pipeline.ts";
import { runEvaluation } from "./run.ts";

const config = configSchema.parse(measuredJson);
const options = { lint: true, fidelity: true };
const makeRecord = (
  id: string,
  clarity: "fragment" | "partial" | "vivid" = "fragment",
): CorpusCase => ({
  id,
  set: "dev",
  kind: "single",
  raw_text: "새로 지어낸 가짜 꿈이다. 나는 파란 장갑을 창틀에 놓았다.",
  expected_clarity: clarity,
  settings: null,
});
async function setup(full = false, set = "dev", fixture = false) {
  const temp = await Deno.makeTempDir({ prefix: "mumumong-quality-test-" }),
    root = new URL(`file://${temp}/`);
  const directory = new URL("eval/runs/a/", root);
  await Deno.mkdir(directory, { recursive: true });
  await Deno.mkdir(new URL("eval/corpus/", root), { recursive: true });
  const records = full
    ? Array.from(
      { length: 18 },
      (_, i) => makeRecord(`d${i}`, (["fragment", "partial", "vivid"] as const)[i % 3]),
    )
    : Array.from({ length: 15 }, (_, i) => makeRecord(`d${i}`));
  if (full) {
    for (let i = 0; i < 3; i++) {
      records.push({
        id: `s${i}`,
        set: "dev",
        kind: "sequence",
        settings: null,
        dreams: Array.from(
          { length: 4 },
          () => ({
            raw_text: "나는 파란 장갑을 모래 위에 펼쳤다. 새로 만든 가짜 꿈이다.",
            expected_clarity: "partial",
          }),
        ),
      });
    }
  }
  const text = records.map((r) => JSON.stringify(r)).join("\n") + "\n";
  await Deno.writeTextFile(new URL("eval/corpus/dev.jsonl", root), text);
  await Deno.writeTextFile(
    new URL("config.json", directory),
    JSON.stringify({
      ...config,
      prompt_versions: PROMPT_VERSIONS,
      identity: { set, corpus_sha256: await digest(text), fixture_llm: fixture },
    }),
  );
  const results = await Promise.all(
    records.map((r) => evaluateCase(r, config, new FixtureLlm(), options)),
  );
  await Deno.writeTextFile(
    new URL("results.jsonl", directory),
    results.map((r) => JSON.stringify(r)).join("\n") + "\n",
  );
  await Deno.writeTextFile(new URL("summary.json", directory), JSON.stringify(summarize(results)));
  await writeMeasurementArtifacts(directory, records, results, config, root, set as "dev");
  return {
    root,
    directory,
    records,
    results,
    cleanup: () => Deno.remove(root, { recursive: true }),
  };
}
async function audit(t: Awaited<ReturnType<typeof setup>>, agrees = 12) {
  const store = await JudgeStore.open(
    await prepareAux("fidelity-audit", "eval/runs/a/fidelity_audit.json", "eval/runs/a", t.root),
    t.root,
  );
  try {
    for (const [i, item] of store.judgment.items.entries()) {
      await store.submit({
        id: item.id,
        revision: store.judgment.revision,
        choice: i < agrees ? "agree" : "disagree",
      });
    }
    return `eval/judgments/${store.path.pathname.split("/").at(-1)}`;
  } finally {
    await store.close();
  }
}

Deno.test("lint/fidelity complete a synthetic sequence through actual unchanged cores and separate evaluator cost", async () => {
  const record: CorpusCase = {
    id: "s",
    set: "dev",
    kind: "sequence",
    settings: null,
    dreams: Array.from(
      { length: 4 },
      () => ({ raw_text: "나는 파란 장갑을 가짜 마당에 두었다.", expected_clarity: "vivid" }),
    ),
  };
  const result = await evaluateCase(record, config, new FixtureLlm(), options);
  assertEquals(result.status, "success");
  assert(result.metrics);
  for (const d of result.dreams) {
    assert(d.metrics);
    assertEquals(d.fidelity?.status, "success");
    assertEquals(d.model_calls.filter((c) => c.role === "judge").length, 1);
    assertEquals(d.model_calls.find((c) => c.role === "judge")!.promptVersion, "fidelity.v1");
    assertEquals(d.measurement_cost_complete, true);
  }
  const summary = summarize([result], false);
  assert(summary.prose_metrics);
  assertEquals(summary.fidelity.measured, 4);
  assertEquals(summary.fidelity.pass_rate, 1);
  assertEquals(summary.fidelity.calibrated, false);
  assertEquals(summary.gate_units, 0);
});
Deno.test("failed fidelity call does not erase generated scene or count as pipeline failure, nor pretend free measurement", async () => {
  const fixture = new FixtureLlm();
  const result = await evaluateCase(makeRecord("d"), config, {
    structured(request) {
      if (request.role === "judge") throw new Error("synthetic private provider body");
      return fixture.structured(request);
    },
  }, options);
  const d = result.dreams[0];
  assertEquals(result.status, "success");
  assert(d.scene);
  assertEquals(d.fidelity?.status, "failed");
  assertEquals(d.measurement_cost_complete, false);
  assertEquals(d.cost_complete, true);
  assert(!JSON.stringify(result).includes("synthetic private provider body"));
  assertEquals(summarize([result]).fidelity.pass_rate, null);
});
Deno.test("actual runner CLI flags save metrics/audit privately, and measurement flags change resume identity", async () => {
  const temp = await Deno.makeTempDir({ prefix: "mumumong-measured-run-" }),
    root = new URL(`file://${temp}/`);
  try {
    await Deno.mkdir(new URL("eval/configs/", root), { recursive: true });
    await Deno.mkdir(new URL("eval/fixtures/", root), { recursive: true });
    await Deno.writeTextFile(new URL("eval/configs/m.json", root), JSON.stringify(config));
    await Deno.copyFile(
      new URL("../../eval/fixtures/sample.jsonl", import.meta.url),
      new URL("eval/fixtures/sample.jsonl", root),
    );
    const run = await runEvaluation(
      { config: "eval/configs/m.json", set: "fixtures", concurrency: 2, resume: false, ...options },
      root,
      new Date("2026-01-01"),
    );
    assertEquals(run.summary.fidelity.measured, 6);
    const quality = JSON.parse(
      await Deno.readTextFile(new URL("quality_metrics.json", run.directory)),
    );
    assertEquals(quality.fidelity, undefined); // Fake model can never calibrate a gate.
    assertEquals(
      (await Deno.stat(new URL("fidelity_audit.json", run.directory))).mode! & 0o777,
      0o600,
    );
    await assertRejects(
      () =>
        runEvaluation({
          config: "eval/configs/m.json",
          set: "fixtures",
          concurrency: 1,
          resume: true,
        }, root),
      EvalError,
      "RESUME_MATCH_NOT_FOUND",
    );
    const resumed = await runEvaluation({
      config: "eval/configs/m.json",
      set: "fixtures",
      concurrency: 1,
      resume: true,
      ...options,
    }, root);
    assertEquals(resumed.skipped, 3);
  } finally {
    await Deno.remove(root, { recursive: true });
  }
});
Deno.test("runner rejects missing or same-as-final/aux judge before reading corpus or making requests", async () => {
  const temp = await Deno.makeTempDir(), root = new URL(`file://${temp}/`);
  try {
    await Deno.mkdir(new URL("eval/configs/", root), { recursive: true });
    for (const judge of [null, config.models.write, config.models.write_aux]) {
      await Deno.writeTextFile(
        new URL("eval/configs/m.json", root),
        JSON.stringify({ ...config, models: { ...config.models, judge } }),
      );
      await assertRejects(
        () =>
          runEvaluation({
            config: "eval/configs/m.json",
            set: "dev",
            concurrency: 1,
            resume: false,
            fidelity: true,
          }, root),
        EvalError,
        judge === null ? "FIDELITY_MODEL_REQUIRED" : "FIDELITY_REQUIRES_DIFFERENT_MODEL",
      );
    }
  } finally {
    await Deno.remove(root, { recursive: true });
  }
});
Deno.test("fidelity stays absent from gates until 12/15 user audit agrees; refresh then supplies verified metric", async () => {
  const t = await setup();
  try {
    let quality = JSON.parse(await Deno.readTextFile(new URL("quality_metrics.json", t.directory)));
    assertEquals(quality.fidelity, undefined);
    const votes = await audit(t);
    assertEquals(await calibrateFidelity("eval/runs/a", votes, t.root), {
      reviewed: 15,
      agreed: 12,
      agreement: .8,
      gate_eligible: true,
    });
    assertEquals(await calibrated(config.models.judge, t.root), true);
    await refreshMeasurements("eval/runs/a", t.root);
    quality = JSON.parse(await Deno.readTextFile(new URL("quality_metrics.json", t.directory)));
    assertEquals(quality.fidelity, { passed: 15, total: 15 });
    await Deno.mkdir(new URL("eval/runs/b/", t.root));
    for (const name of ["config.json", "results.jsonl", "quality_metrics.json"]) {
      await Deno.copyFile(new URL(name, t.directory), new URL(`eval/runs/b/${name}`, t.root));
    }
    assertEquals(
      (await prepareAB("eval/runs/a", "eval/runs/b", t.root)).judgment.stats!.B.fidelity_rate,
      1,
    );
    assertEquals(
      JSON.parse(await Deno.readTextFile(new URL("summary.json", t.directory))).fidelity.calibrated,
      true,
    );
    const file = new URL(votes, t.root);
    const changed = JSON.parse(await Deno.readTextFile(file));
    changed.revision++;
    await Deno.writeTextFile(file, JSON.stringify(changed));
    assertEquals(await calibrated(config.models.judge, t.root), false);
    assertEquals(
      (await prepareAB("eval/runs/a", "eval/runs/b", t.root)).judgment.stats!.B.fidelity_rate,
      null,
    );
    await refreshMeasurements("eval/runs/a", t.root);
    assertEquals(
      JSON.parse(await Deno.readTextFile(new URL("quality_metrics.json", t.directory))).fidelity,
      undefined,
    );
  } finally {
    await t.cleanup();
  }
});
Deno.test("audit below 80 percent, incomplete votes, fixture calibration and changed results all fail closed", async () => {
  const t = await setup();
  try {
    const votes = await audit(t, 11);
    await assertRejects(
      () => calibrateFidelity("eval/runs/a", votes, t.root),
      EvalError,
      "FIDELITY_AGREEMENT_BELOW_80",
    );
    const value = JSON.parse(await Deno.readTextFile(new URL(votes, t.root)));
    value.items[0].audit = null;
    await Deno.writeTextFile(new URL(votes, t.root), JSON.stringify(value));
    await assertRejects(
      () => calibrateFidelity("eval/runs/a", votes, t.root),
      EvalError,
      "FIDELITY_AUDIT_INCOMPLETE",
    );
  } finally {
    await t.cleanup();
  }
  const f = await setup(false, "fixtures", true);
  try {
    assertEquals(
      (await calibrateFidelity("eval/runs/a", await audit(f, 15), f.root)).gate_eligible,
      false,
    );
    assertEquals(await calibrated(config.models.judge, f.root), false);
  } finally {
    await f.cleanup();
  }
  const changed = await setup();
  try {
    const votes = await audit(changed, 15);
    await Deno.writeTextFile(
      new URL("results.jsonl", changed.directory),
      (await Deno.readTextFile(new URL("results.jsonl", changed.directory))) + "\n",
    );
    await assertRejects(() => calibrateFidelity("eval/runs/a", votes, changed.root), EvalError);
  } finally {
    await changed.cleanup();
  }
});
Deno.test("Q08 report refuses incomplete/uncalibrated/fixture inputs and emits numbers only for complete mocked measurements", async () => {
  const t = await setup(true);
  try {
    await assertRejects(
      () => baselineReport("eval/runs/a", undefined, t.root),
      EvalError,
      "FIDELITY_CALIBRATION_REQUIRED",
    );
    await calibrateFidelity("eval/runs/a", await audit(t, 15), t.root);
    await refreshMeasurements("eval/runs/a", t.root);
    const result = await baselineReport("eval/runs/a", undefined, t.root);
    assertEquals(result.cases, 21);
    assertEquals(result.corpus_dreams, 30);
    assertEquals(result.scene_measurements, 30);
    assertEquals(result.aa_verified, false);
    const report = await Deno.readTextFile(new URL("baseline_report.md", t.directory));
    assert(!report.includes("파란 장갑"));
    assert(!report.includes("가짜 마당"));
    assert(report.includes("미검증"));
  } finally {
    await t.cleanup();
  }
  const f = await setup(false, "fixtures", true);
  try {
    await assertRejects(
      () => baselineReport("eval/runs/a", undefined, f.root),
      EvalError,
      "BASELINE_REQUIRES_REAL_DEV",
    );
  } finally {
    await f.cleanup();
  }
});
Deno.test("measurement and baseline tools lock holdout and redact malformed-path errors", async () => {
  const t = await setup(false, "holdout");
  try {
    await assertRejects(
      () => refreshMeasurements("eval/runs/a", t.root),
      EvalError,
      "HOLDOUT_LOCKED_UNTIL_Q32",
    );
    await assertRejects(
      () => calibrateFidelity("eval/runs/a", "eval/judgments/private", t.root),
      EvalError,
      "HOLDOUT_LOCKED_UNTIL_Q32",
    );
    await assertRejects(
      () => baselineReport("eval/runs/a", undefined, t.root),
      EvalError,
      "HOLDOUT_LOCKED_UNTIL_Q32",
    );
    const original = console.log, output: string[] = [];
    console.log = (v) => output.push(String(v));
    try {
      assertEquals(await baselineMain(["private original text"], t.root), 1);
    } finally {
      console.log = original;
    }
    assert(!output.join("").includes("private original text"));
  } finally {
    await t.cleanup();
  }
});

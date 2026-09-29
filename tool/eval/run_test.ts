import { assert, assertEquals, assertRejects, assertThrows } from "@std/assert";
import configJson from "../../eval/configs/baseline_v10.json" with { type: "json" };
import type { StructuredCall } from "../../supabase/functions/_shared/llm_port.ts";
import { SCENE_LOOP_POLICY } from "../../supabase/functions/_shared/scene_loop_policy.ts";
import { configSchema, type CorpusCase, EvalError } from "./config.ts";
import { FixtureLlm } from "./fixture_llm.ts";
import { type CaseResult, evaluateCase, summarize } from "./pipeline.ts";
import { main, parseArgs, runEvaluation } from "./run.ts";

const config = configSchema.parse(configJson);

Deno.test("eval config accepts only registered models across three providers without changing baseline", () => {
  for (
    const name of [
      "groq:openai/gpt-oss-120b",
      "anthropic:claude-sonnet-5",
      "anthropic:claude-sonnet-4-6",
      "openai:gpt-4.1-2025-04-14",
      "openai:gpt-4.1",
    ]
  ) {
    assertEquals(
      configSchema.safeParse({ ...config, models: { ...config.models, write: name } }).success,
      true,
    );
  }
  for (const name of ["anthropic:unregistered", "unknown:model", "openai:openai/gpt-oss-120b"]) {
    assertEquals(
      configSchema.safeParse({ ...config, models: { ...config.models, write: name } }).success,
      false,
    );
  }
  assertEquals(config.models.write, "groq:openai/gpt-oss-120b");
});
const fixtureFile = new URL("../../eval/fixtures/sample.jsonl", import.meta.url);
async function fixtures(): Promise<CorpusCase[]> {
  return (await Deno.readTextFile(fixtureFile)).trim().split("\n").map((line) => JSON.parse(line));
}

async function temporaryRoot() {
  const path = await Deno.makeTempDir({ prefix: "mumumong-q03-test-" });
  const root = new URL(`file://${path}/`);
  await Deno.mkdir(new URL("eval/configs/", root), { recursive: true });
  await Deno.mkdir(new URL("eval/fixtures/", root), { recursive: true });
  await Deno.writeTextFile(new URL("eval/configs/baseline_v10.json", root), JSON.stringify(config));
  await Deno.copyFile(fixtureFile, new URL("eval/fixtures/sample.jsonl", root));
  return { root, cleanup: () => Deno.remove(root, { recursive: true }) };
}

Deno.test("fixture single2 and sequence1 finish through unchanged cores, with valid provenance", async () => {
  const inputs = await fixtures();
  const results = await Promise.all(
    inputs.map((input) => evaluateCase(input, config, new FixtureLlm())),
  );
  assertEquals(results.map((result) => result.status), ["success", "success", "success"]);
  assertEquals(results.map((result) => result.dreams.length), [1, 1, 4]);
  for (const result of results) {
    for (const dream of result.dreams) {
      assertEquals(dream.attempts, 1);
      assertEquals(dream.fallback, false);
      const extraction = dream.stages.find((stage) => stage.stage === "extract")!.output as {
        rows: { id: string }[];
      };
      const ids = new Set(extraction.rows.map((row) => row.id));
      for (
        const passage of dream.scene!.passages! as {
          origin: string;
          source_element_ids: string[];
        }[]
      ) {
        assertEquals(passage.origin, "D");
        assert(
          passage.source_element_ids.length > 0 &&
            passage.source_element_ids.every((id) => ids.has(id)),
        );
      }
    }
  }
  assertEquals(summarize(results, false).gate_units, 0);
});

Deno.test("sequence second E2 sees first committed entity and auto-links it; E7 history advances", async () => {
  const result = await evaluateCase((await fixtures())[2], config, new FixtureLlm());
  const firstCommit = result.dreams[0].stages.find((stage) => stage.stage === "commit")!.output as {
    entities: { id: string }[];
  };
  const secondLink = result.dreams[1].stages.find((stage) => stage.stage === "link")!.output as {
    input_entity_ids: string[];
    decisions: { auto: { entity_id: string }[] };
  };
  assertEquals(secondLink.input_entity_ids, firstCommit.entities.map((entity) => entity.id));
  assertEquals(secondLink.decisions.auto[0].entity_id, firstCommit.entities[0].id);
  assertEquals(result.scenes.map((scene) => scene.order_key), ["s0001", "s0002", "s0003", "s0004"]);
  assertEquals(
    result.dreams.map((dream) =>
      (dream.stages.find((stage) => stage.stage === "remember")!.output as { nextVersion: number })
        .nextVersion
    ),
    [1, 2, 3, 4],
  );
});

Deno.test("context projections match production loaders and recall settings remain independent", async () => {
  const fake = new FixtureLlm();
  const calls: StructuredCall[] = [];
  const llm = {
    structured<T>(call: StructuredCall) {
      calls.push(call);
      return fake.structured<T>(call);
    },
  };
  const record = { ...(await fixtures())[2], settings: { style: "lyrical" as const } };
  await evaluateCase(record, config, llm);
  const plans = calls.filter((call) => call.role === "plan");
  const plan2 = plans[1].input as {
    existing_scenes: Record<string, unknown>[];
    narrative_memory: Record<string, unknown>;
  };
  assertEquals(Object.keys(plan2.existing_scenes[0]).sort(), [
    "id",
    "open_image",
    "order_key",
    "placement",
    "title",
  ]);
  assertEquals(Object.keys(plan2.narrative_memory).sort(), [
    "motifs",
    "open_threads",
    "story_so_far",
  ]);
  const write2 = calls.filter((call) => call.role === "write")[1].input as {
    settings: { style: string };
    recent_scenes: { passages: Record<string, unknown>[] }[];
  };
  assertEquals(write2.settings.style, "lyrical");
  assertEquals(Object.keys(write2.recent_scenes[0].passages[0]).sort(), [
    "locked",
    "order_key",
    "origin",
    "text",
  ]);
  assertEquals(config.settings.style, "plain");
  const linkInput = calls.find((call) => call.role === "link")!.input as {
    ambiguous: { element: Record<string, unknown>; candidates: Record<string, unknown>[] }[];
  };
  assertEquals(Object.keys(linkInput.ambiguous[0].element).sort(), [
    "detail",
    "id",
    "label",
    "type",
  ]);
  assertEquals(Object.keys(linkInput.ambiguous[0].candidates[0]).sort(), [
    "aliases",
    "description",
    "id",
    "role_name",
    "type",
  ]);
});

Deno.test("retry/fallback uses shared policy and stops at relaxed acceptance", async () => {
  const fake = new FixtureLlm();
  const llm = {
    async structured<T>(call: StructuredCall) {
      const reply = await fake.structured<T>(call);
      if (call.role !== "write") return reply;
      const value = reply.value as { passages: { text: string }[] };
      value.passages = [value.passages[0]];
      value.passages[0].text = "가짜 문장";
      return reply;
    },
  };
  const result = await evaluateCase((await fixtures())[0], config, llm);
  assertEquals(result.status, "success");
  assertEquals(result.dreams[0].attempts, SCENE_LOOP_POLICY.fallbackWriteAttempt + 1);
  assertEquals(result.fallback, true);
  const validations = result.dreams[0].stages.filter((stage) => stage.stage === "validate");
  assertEquals(
    validations.map((stage) => (stage.output as { outcome: { profile: string } }).outcome.profile),
    ["strict", "strict", "strict", "relaxed"],
  );
  // Both length and passage-count violations are counted on each strict attempt.
  assertEquals(summarize([result]).validation_codes.V4, 6);
});

Deno.test("terminal invalid provenance fails and does not pretend to commit", async () => {
  const fake = new FixtureLlm();
  const llm = {
    async structured<T>(call: StructuredCall) {
      const reply = await fake.structured<T>(call);
      if (call.role === "write") {
        const value = reply.value as { passages: { source_element_ids: string[] }[] };
        for (const passage of value.passages) {
          passage.source_element_ids = [
            "11111111-1111-4111-8111-111111111111",
          ];
        }
      }
      return reply;
    },
  };
  const result = await evaluateCase((await fixtures())[0], config, llm);
  assertEquals(result.status, "failed");
  assertEquals(result.failed_stage, "validate");
  assertEquals(result.code, "VALIDATION_TERMINAL");
  assertEquals(result.scenes.length, 0);
});

Deno.test("failure isolation and redaction: arbitrary transport messages never reach result or log", async () => {
  const privateMarker = "PRIVATE-SYNTHETIC-ERROR-MARKER";
  const inputs = await fixtures();
  const failed = await evaluateCase(inputs[0], config, {
    structured() {
      throw new Error(privateMarker);
    },
  });
  const success = await evaluateCase(inputs[1], config, new FixtureLlm());
  assertEquals([failed.status, success.status], ["failed", "success"]);
  assertEquals(failed.failed_stage, "extract");
  assertEquals(failed.code, "MODEL_CALL_FAILED");
  assert(!JSON.stringify(failed).includes(privateMarker));
  assertEquals(failed.dreams[0].cost_complete, false);
  const summary = summarize([failed, success]);
  assertEquals([summary.success, summary.failed], [1, 1]);
  assertEquals(summary.cost_krw.complete, false);
});

Deno.test("failed sequence stops before later dreams consume broken state", async () => {
  const fake = new FixtureLlm();
  const llm = {
    structured<T>(call: StructuredCall) {
      if (call.role === "remember") throw new Error("synthetic failure");
      return fake.structured<T>(call);
    },
  };
  const result = await evaluateCase((await fixtures())[2], config, llm);
  assertEquals(result.status, "failed");
  assertEquals(result.failed_stage, "remember");
  assertEquals(result.dreams.length, 1);
});

Deno.test("CLI validates flags and locks holdout before reads", () => {
  for (
    const args of [
      [],
      ["--set", "other"],
      ["--set", "fixtures", "--concurrency", "0"],
      ["--set", "fixtures", "--cases", "../escape"],
      ["--set", "fixtures", "--cases", "f01,f01"],
    ]
  ) {
    assertThrows(() => parseArgs(args), EvalError);
  }
  const error = assertThrows(() => parseArgs(["--set", "holdout"]), EvalError);
  assertEquals(error.message, "HOLDOUT_LOCKED_UNTIL_Q32");
  assertEquals(parseArgs(["--set", "fixtures", "--lint", "--fidelity"]).fidelity, true);
});

Deno.test("config cannot contain credentials, unknown settings or future engine versions", () => {
  assertEquals(configSchema.safeParse({ ...config, apiKey: "synthetic" }).success, false);
  assertEquals(configSchema.safeParse({ ...config, engine_version: "v11" }).success, false);
  assertEquals(
    configSchema.safeParse({ ...config, settings: { ...config.settings, unknown: "synthetic" } })
      .success,
    false,
  );
});

Deno.test("run persists private outputs, resume skips success and retries failed checkpoints without duplicate lines", async () => {
  const task = await temporaryRoot();
  try {
    const options = parseArgs(["--set", "fixtures", "--concurrency", "2"]);
    const first = await runEvaluation(options, task.root);
    assertEquals(first.summary.success, 3);
    const rows = (await Deno.readTextFile(new URL("results.jsonl", first.directory))).trim().split(
      "\n",
    );
    assertEquals(rows.length, 3);
    const before = await Deno.readTextFile(new URL(".cases/f01.json", first.directory));
    const resumed = await runEvaluation({ ...options, resume: true }, task.root);
    assertEquals(resumed.skipped, 3);
    assertEquals(await Deno.readTextFile(new URL(".cases/f01.json", first.directory)), before);
    const failed = { ...first.results[1], status: "failed" } as CaseResult;
    await Deno.writeTextFile(new URL(".cases/f02.json", first.directory), JSON.stringify(failed));
    const repaired = await runEvaluation({ ...options, resume: true }, task.root);
    assertEquals([repaired.skipped, repaired.summary.success], [2, 3]);
    assertEquals(
      (await Deno.readTextFile(new URL("results.jsonl", first.directory))).trim().split("\n")
        .length,
      3,
    );
    const mode = (await Deno.stat(new URL("results.jsonl", first.directory))).mode;
    if (mode !== null) assertEquals(mode & 0o777, 0o600);
    await assertRejects(() => runEvaluation(options, task.root), EvalError, "RUN_EXISTS");
  } finally {
    await task.cleanup();
  }
});

Deno.test("resume rejects different corpus, and live run lock prevents concurrent writers", async () => {
  const task = await temporaryRoot();
  try {
    const options = parseArgs(["--set", "fixtures"]);
    const first = await runEvaluation(options, task.root);
    await Deno.writeTextFile(new URL(".lock", first.directory), String(Deno.pid));
    await assertRejects(
      () => runEvaluation({ ...options, resume: true }, task.root),
      EvalError,
      "RUN_LOCKED",
    );
    await Deno.remove(new URL(".lock", first.directory));
    await Deno.writeTextFile(
      new URL("eval/fixtures/sample.jsonl", task.root),
      (await Deno.readTextFile(fixtureFile)).replace("f01", "f99"),
    );
    await assertRejects(
      () => runEvaluation({ ...options, resume: true }, task.root),
      EvalError,
      "RESUME_MATCH_NOT_FOUND",
    );
  } finally {
    await task.cleanup();
  }
});

Deno.test("synthetic sentinel stays separate and contributes zero gate units, even when failed", async () => {
  const task = await temporaryRoot();
  const priorKey = Deno.env.get("GROQ_API_KEY");
  Deno.env.delete("GROQ_API_KEY");
  try {
    await Deno.mkdir(new URL("eval/corpus/", task.root));
    await Deno.writeTextFile(
      new URL("eval/corpus/sentinel.jsonl", task.root),
      JSON.stringify({ ...(await fixtures())[0], set: "sentinel", expected_clarity: null }),
    );
    const run = await runEvaluation(parseArgs(["--set", "sentinel"]), task.root);
    assertEquals(run.summary.gate_units, 0);
    assertEquals(run.summary.failed, 1);
  } finally {
    if (priorKey !== undefined) Deno.env.set("GROQ_API_KEY", priorKey);
    await task.cleanup();
  }
});

Deno.test("CLI logs contain fixed codes only, never supplied argument contents", async () => {
  const messages: string[] = [];
  const original = console.log;
  console.log = (value) => messages.push(String(value));
  try {
    assertEquals(await main(["PRIVATE-SYNTHETIC-ARGUMENT"]), 1);
    assertEquals(await main(["--set", "holdout"]), 1);
  } finally {
    console.log = original;
  }
  assert(!messages.join("").includes("PRIVATE-SYNTHETIC"));
  assert(
    messages.every((message) =>
      Object.keys(JSON.parse(message)).every((key) => ["event", "status", "code"].includes(key))
    ),
  );
});

Deno.test("runner isolates invalid per-case settings and case selection rejects unknown IDs", async () => {
  const task = await temporaryRoot();
  try {
    const records = await fixtures();
    records[0].settings = { invalid: "synthetic" } as CorpusCase["settings"];
    await Deno.writeTextFile(
      new URL("eval/fixtures/sample.jsonl", task.root),
      records.map((record) => JSON.stringify(record)).join("\n"),
    );
    const run = await runEvaluation(parseArgs(["--set", "fixtures"]), task.root);
    assertEquals([run.summary.success, run.summary.failed], [2, 1]);
    assertEquals([run.results[0].failed_stage, run.results[0].code], [
      "settings",
      "SETTINGS_INVALID",
    ]);
    await assertRejects(
      () => runEvaluation(parseArgs(["--set", "fixtures", "--cases", "missing"]), task.root),
      EvalError,
      "CASE_UNKNOWN",
    );
  } finally {
    await task.cleanup();
  }
});

Deno.test("partial-case run only processes selected ID and resumes after stale PID lock", async () => {
  const task = await temporaryRoot();
  try {
    const options = parseArgs(["--set", "fixtures", "--cases", "f02"]);
    const run = await runEvaluation(options, task.root);
    assertEquals(run.results.map((result) => result.id), ["f02"]);
    await Deno.writeTextFile(new URL(".lock", run.directory), "999999999");
    const resumed = await runEvaluation({ ...options, resume: true }, task.root);
    assertEquals(resumed.skipped, 1);
  } finally {
    await task.cleanup();
  }
});

Deno.test("all calls including optional polish contribute cost; metrics use per-dream nearest-rank", async () => {
  const fake = new FixtureLlm();
  const llm = {
    async structured<T>(call: StructuredCall) {
      const result = await fake.structured<T>(call);
      return { ...result, model: "openai/gpt-oss-120b", tokensIn: 1000, tokensOut: 1000 };
    },
  };
  const inputs = await fixtures();
  const results = await Promise.all(inputs.map((record) => evaluateCase(record, config, llm)));
  assertEquals(results[0].dreams[0].model_calls.map((call) => call.role), [
    "extract",
    "plan",
    "write",
    "polish",
  ]);
  assertEquals(results[0].dreams[0].cost_krw, 4 * 1.05);
  results.flatMap((result) => result.dreams).forEach((dream, index) => {
    dream.latency_ms = (index + 1) * 10;
  });
  assertEquals(summarize(results).latency_ms, { p50: 30, p95: 60 });
  assertEquals(summarize(results).cost_krw.complete, true);
});

Deno.test("evaluation cost completeness reads provider registry rather than Groq-only whitelist", async () => {
  const fake = new FixtureLlm();
  for (
    const [model, perCall, complete] of [["anthropic:claude-sonnet-5", 16.8, true], [
      "openai:gpt-4.1-2025-04-14",
      14,
      true,
    ], ["unregistered", 0, false]] as const
  ) {
    const result = await evaluateCase((await fixtures())[0], config, {
      async structured<T>(call: StructuredCall) {
        return { ...await fake.structured<T>(call), model, tokensIn: 1000, tokensOut: 1000 };
      },
    });
    assertEquals(result.status, "success");
    assertEquals(result.dreams[0].cost_complete, complete);
    assertEquals(result.dreams[0].cost_krw, result.dreams[0].model_calls.length * perCall);
  }
});

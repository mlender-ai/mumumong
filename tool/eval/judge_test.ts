import { assert, assertAlmostEquals, assertEquals, assertRejects, assertThrows } from "@std/assert";
import configJson from "../../eval/configs/baseline_v10.json" with { type: "json" };
import { configSchema, type CorpusCase, digest, EvalError, PROMPT_VERSIONS } from "./config.ts";
import { FixtureLlm } from "./fixture_llm.ts";
import { evaluateCase } from "./pipeline.ts";
import { prepareAB } from "./judge_inputs.ts";
import { prepareAux } from "./judge_aux.ts";
import { JudgeStore } from "./judge_store.ts";
import { type Judgment, judgmentSchema, leftSide, privatePath } from "./judgment.ts";
import { parseArgs, requestHandler, startJudge } from "./judge.ts";
import { buildReport, main as reportMain, signP } from "./report.ts";
import { judgePage } from "./judge_page.ts";
import { createDemo } from "./judge_demo.ts";

const marker = "SYNTHETIC_PRIVATE_MARKER";
const config = configSchema.parse(configJson);
async function task() {
  const dir = await Deno.makeTempDir({ prefix: "mumumong-q05-test-" });
  const root = new URL(`file://${dir}/`);
  const text = await Deno.readTextFile(
    new URL("../../eval/fixtures/sample.jsonl", import.meta.url),
  );
  const cases = text.trim().split(/\r?\n/).map((line) => JSON.parse(line) as CorpusCase);
  await Deno.mkdir(new URL("eval/fixtures/", root), { recursive: true });
  await Deno.writeTextFile(new URL("eval/fixtures/sample.jsonl", root), text);
  const results = await Promise.all(
    cases.map((record) => evaluateCase(record, config, new FixtureLlm())),
  );
  const manifest = {
    ...config,
    prompt_versions: PROMPT_VERSIONS,
    identity: { set: "fixtures", corpus_sha256: await digest(text), fixture_llm: true },
  };
  for (const name of ["a", "b"]) {
    const directory = new URL(`eval/runs/${name}/`, root);
    await Deno.mkdir(directory, { recursive: true });
    await Deno.writeTextFile(new URL("config.json", directory), JSON.stringify(manifest));
    await Deno.writeTextFile(
      new URL("results.jsonl", directory),
      results.map((result) => JSON.stringify(result)).join("\n") + "\n",
    );
  }
  const modify = async (name: string, update: (rows: typeof results) => void) => {
    const rows = structuredClone(results);
    update(rows);
    await Deno.writeTextFile(
      new URL(`eval/runs/${name}/results.jsonl`, root),
      rows.map((row) => JSON.stringify(row)).join("\n") + "\n",
    );
  };
  return {
    root,
    cases,
    results,
    manifest,
    modify,
    cleanup: () => Deno.remove(dir, { recursive: true }),
  };
}
const prepare = (root: URL) => prepareAB("eval/runs/a", "eval/runs/b", root);

Deno.test("demo creates two complete real Q03 fixture runs with no quality gate eligibility", async () => {
  const t = await task();
  try {
    const runs = await createDemo(t.root);
    const p = await prepareAB(runs.a, runs.b, t.root);
    assertEquals(p.judgment.items.length, 3);
    assertEquals(p.judgment.gate_eligible, false);
    assertEquals(p.judgment.stats!.A.dream_count, 6);
    assertEquals(p.judgment.stats!.B.max_cost_krw, 0);
  } finally {
    await t.cleanup();
  }
});
function submission(state: Awaited<ReturnType<JudgeStore["state"]>>, choice = "left") {
  return { id: "id" in state ? state.id : "", revision: state.revision, choice };
}

Deno.test("AB loads Q03-shaped fixture outputs, common cases, four-scene sequence and private originals", async () => {
  const t = await task();
  try {
    const p = await prepare(t.root);
    assertEquals(p.judgment.items.map((item) => item.kind), ["single", "single", "sequence"]);
    assertEquals(p.display.get("fs1")!.A!.length, 4);
    assertEquals(p.display.get("fs1")!.originals.length, 4);
    assertEquals(p.judgment.gate_eligible, false);
    assertEquals([p.judgment.stats!.A.provenance_errors, p.judgment.stats!.B.v2_compliance], [
      0,
      1,
    ]);
    const store = await JudgeStore.open(p, t.root);
    try {
      const state = await store.state();
      const body = JSON.stringify(state);
      for (
        const secret of [
          "seed",
          "identity",
          "models",
          "prompt_versions",
          "origin",
          "source_element_ids",
          "groq",
          "baseline_v10",
        ]
      ) assert(!body.includes('"' + secret + '":') && !body.includes('"' + secret + ":"));
      assert(JSON.stringify(await store.state(0, true)).includes('"origin":"D"'));
      assertEquals(
        Object.keys(JSON.parse(await Deno.readTextFile(store.path))).includes("originals"),
        false,
      );
    } finally {
      await store.close();
    }
  } finally {
    await t.cleanup();
  }
});

Deno.test("saved seed reproduces per-case placement with both sides represented", async () => {
  const seed = "0123456789abcdef0123456789abcdef";
  const first = await Promise.all(
    Array.from({ length: 100 }, (_, i) => leftSide(seed, `case${i}`)),
  );
  const second = await Promise.all(
    Array.from({ length: 100 }, (_, i) => leftSide(seed, `case${i}`)),
  );
  assertEquals(first, second);
  assert(first.includes("A") && first.includes("B"));
});

Deno.test("every vote saves atomically, maps visible sides, resumes seed/votes and keeps file private", async () => {
  const t = await task();
  try {
    const store = await JudgeStore.open(await prepare(t.root), t.root);
    const state = await store.state(), originalSeed = store.judgment.seed;
    await store.submit({
      ...submission(state),
      winner_not_ready: true,
      reasons: ["engaging"],
      problems: ["too_short"],
    });
    const expected = await leftSide(originalSeed, "f01");
    assertEquals(store.judgment.items[0].vote!.winner, expected);
    assertEquals(store.judgment.items[0].vote!.not_ready[expected], true);
    const path = store.path;
    if (Deno.build.os !== "windows") {
      assertEquals((await Deno.stat(path)).mode! & 0o777, 0o600);
      assertEquals((await Deno.stat(new URL("./", path))).mode! & 0o777, 0o700);
    }
    await store.close();
    const resumed = await JudgeStore.open(await prepare(t.root), t.root);
    try {
      assertEquals(resumed.judgment.seed, originalSeed);
      assertEquals((await resumed.state()).position, 1);
      const restored = await resumed.state(0);
      assert("choice" in restored);
      assertEquals(restored.choice, "left");
      assertEquals(resumed.judgment.revision, 1);
      const names = [];
      for await (const entry of Deno.readDir(new URL("./", path))) names.push(entry.name);
      assertEquals(names.filter((name) => name.endsWith(".tmp")), []);
    } finally {
      await resumed.close();
    }
  } finally {
    await t.cleanup();
  }
});

Deno.test("one-sided pipeline failures auto-lose, both failures auto-tie and do not enter manual queue", async () => {
  const t = await task();
  try {
    await t.modify("a", (rows) => {
      rows[0].status = "failed";
      rows[2].status = "failed";
    });
    await t.modify("b", (rows) => {
      rows[1].status = "failed";
      rows[2].status = "failed";
    });
    const store = await JudgeStore.open(await prepare(t.root), t.root);
    try {
      assertEquals((await store.state()).done, true);
      const report = buildReport(store.judgment);
      assertEquals(report.wins, { A: 1, B: 1, tie: 1 });
      assertEquals(report.automatic, { A_failed: 1, B_failed: 1, both_failed: 1 });
      await assertRejects(
        () => store.submit({ id: "f01", revision: 0, choice: "left" }),
        EvalError,
        "ITEM_NOT_EDITABLE",
      );
    } finally {
      await store.close();
    }
  } finally {
    await t.cleanup();
  }
});

Deno.test("successful pipeline with incomplete manuscript is an automatic product loss, not a fake success", async () => {
  const t = await task();
  try {
    await t.modify("b", (rows) => {
      rows[0].scenes = [];
      rows[0].dreams[0].scene = null;
    });
    const p = await prepare(t.root);
    assertEquals(p.judgment.items[0].vote!.automatic, "B_failed");
    assertEquals(p.judgment.stats!.B.failures, 1);
  } finally {
    await t.cleanup();
  }
});

Deno.test("intersection only; same runs and no common cases are rejected", async () => {
  const t = await task();
  try {
    await t.modify("b", (rows) => {
      rows.splice(0, 1);
    });
    assertEquals((await prepare(t.root)).judgment.items.length, 2);
    await assertRejects(
      () => prepareAB("eval/runs/a", "eval/runs/a/", t.root),
      EvalError,
      "SAME_RUN",
    );
    await t.modify("b", (rows) => {
      rows.forEach((row) => row.id = "unknown" + row.id);
    });
    await assertRejects(() => prepare(t.root), EvalError, "NO_COMMON_CASES");
  } finally {
    await t.cleanup();
  }
});

Deno.test("holdout is rejected before results or corpus reads, and changed corpus is not silently substituted", async () => {
  const t = await task();
  try {
    await Deno.writeTextFile(
      new URL("eval/runs/a/config.json", t.root),
      JSON.stringify({ ...t.manifest, identity: { ...t.manifest.identity, set: "holdout" } }),
    );
    await Deno.writeTextFile(new URL("eval/runs/a/results.jsonl", t.root), marker);
    await assertRejects(() => prepare(t.root), EvalError, "HOLDOUT_LOCKED_UNTIL_Q32");
    await assertRejects(
      () => prepareAux("fidelity-audit", "eval/runs/a/fidelity_audit.json", "eval/runs/a", t.root),
      EvalError,
      "HOLDOUT_LOCKED_UNTIL_Q32",
    );
    await Deno.writeTextFile(
      new URL("eval/runs/a/config.json", t.root),
      JSON.stringify(t.manifest),
    );
    await t.modify("a", () => {});
    await Deno.writeTextFile(new URL("eval/fixtures/sample.jsonl", t.root), marker);
    await assertRejects(() => prepare(t.root), EvalError, "CORPUS_MISMATCH");
  } finally {
    await t.cleanup();
  }
});

Deno.test("quality evidence is bound to exact result hash and case IDs; absent metrics remain unknown", async () => {
  const t = await task();
  try {
    const text = await Deno.readTextFile(new URL("eval/runs/b/results.jsonl", t.root));
    const quality = {
      results_sha256: await digest(text),
      case_ids: t.results.map((r) => r.id),
      fidelity: { passed: 2, total: 3 },
      reference_proximity: 7,
    };
    const file = new URL("eval/runs/b/quality_metrics.json", t.root);
    await Deno.writeTextFile(file, JSON.stringify(quality));
    const p = await prepare(t.root);
    assertEquals(p.judgment.stats!.A.fidelity_rate, null);
    assertEquals(p.judgment.stats!.B.fidelity_rate, 2 / 3);
    assertEquals(p.judgment.stats!.B.reference_proximity, 7);
    await Deno.writeTextFile(file, JSON.stringify({ ...quality, results_sha256: "0".repeat(64) }));
    await assertRejects(() => prepare(t.root), EvalError, "QUALITY_METRICS_INVALID");
  } finally {
    await t.cleanup();
  }
});

Deno.test("final provenance and adaptation ratio use actual elements and Unicode code points, not historical retry codes", async () => {
  const t = await task();
  try {
    await t.modify("b", (rows) => {
      const scene = rows[0].dreams[0].scene!;
      const passage = scene.passages![0] as {
        text: string;
        origin: string;
        source_element_ids: string[];
      };
      passage.source_element_ids = ["unknown-source"];
      passage.text = "가나다";
      passage.origin = "C";
      scene.passages = [passage, {
        ...passage,
        origin: "D",
        text: "😀😀😀😀😀",
        source_element_ids: (rows[0].dreams[0].stages[0].output as { rows: { id: string }[] }).rows
          .map((r) => r.id),
      }];
    });
    const p = await prepare(t.root);
    assertEquals(p.judgment.stats!.B.provenance_errors, 1);
    assertEquals(p.judgment.stats!.B.v2_compliance, 5 / 6);
  } finally {
    await t.cleanup();
  }
});

Deno.test("concurrent votes are serialized and stale revisions fail; lock prevents another writer", async () => {
  const t = await task();
  try {
    const store = await JudgeStore.open(await prepare(t.root), t.root);
    try {
      await assertRejects(
        () => JudgeStore.open(store.prepared, t.root),
        EvalError,
        "JUDGMENT_LOCKED",
      );
      const state = await store.state();
      const results = await Promise.allSettled([
        store.submit(submission(state)),
        store.submit(submission(state, "right")),
      ]);
      assertEquals(results.map((result) => result.status), ["fulfilled", "rejected"]);
      assertEquals(store.judgment.revision, 1);
      await assertRejects(
        () => store.submit({ ...submission(state), reasons: [marker] }),
        EvalError,
        "SUBMISSION_INVALID",
      );
    } finally {
      await store.close();
    }
  } finally {
    await t.cleanup();
  }
});

Deno.test("save failure keeps in-memory judgment unchanged and changed run fingerprints block resume", async () => {
  const t = await task();
  try {
    const store = await JudgeStore.open(await prepare(t.root), t.root);
    const original = new URL(`${store.path.href}.backup`);
    await Deno.rename(store.path, original);
    await Deno.mkdir(store.path);
    await assertRejects(
      async () => store.submit(submission(await store.state())),
      EvalError,
      "JUDGMENT_SAVE_FAILED",
    );
    assertEquals(store.judgment.revision, 0);
    await Deno.remove(store.path);
    await Deno.rename(original, store.path);
    await store.close();
    await t.modify("b", (rows) => {
      rows[0].cost_krw = 100;
    });
    await assertRejects(
      async () => JudgeStore.open(await prepare(t.root), t.root),
      EvalError,
      "JUDGMENT_INPUT_CHANGED",
    );
  } finally {
    await t.cleanup();
  }
});

Deno.test("dead writer lock can be recovered while symlinks and traversal cannot escape private inputs", async () => {
  const t = await task();
  try {
    const store = await JudgeStore.open(await prepare(t.root), t.root), path = store.path;
    await store.close();
    await Deno.writeTextFile(new URL(`${path.href}.lock`), "999999999");
    const recovered = await JudgeStore.open(await prepare(t.root), t.root);
    await recovered.close();
    await assertRejects(
      () => privatePath(t.root, "eval/runs/../../secrets", "runs"),
      EvalError,
      "PRIVATE_PATH_REQUIRED",
    );
    const outside = new URL("outside.json", t.root);
    await Deno.writeTextFile(outside, marker);
    await Deno.symlink(outside.pathname, new URL("eval/runs/escaped.json", t.root));
    await assertRejects(
      () => privatePath(t.root, "eval/runs/escaped.json", "runs"),
      EvalError,
      "PRIVATE_PATH_REQUIRED",
    );
  } finally {
    await t.cleanup();
  }
});

Deno.test("HTTP protects loopback host, origin, session token, caches and blind metadata", async () => {
  const t = await task();
  try {
    const store = await JudgeStore.open(await prepare(t.root), t.root);
    try {
      const handle = requestHandler(store, "http://127.0.0.1:8787", "token", "nonce");
      for (
        const request of [
          new Request("http://evil.test/"),
          new Request("http://127.0.0.1:8787/", { headers: { origin: "http://evil.test" } }),
          new Request("http://127.0.0.1:8787/api/state"),
        ]
      ) assertEquals((await handle(request)).status, 403);
      const html = await handle(new Request("http://127.0.0.1:8787/"));
      assertEquals(html.headers.get("cache-control"), "no-store");
      assert(html.headers.get("content-security-policy")!.includes("frame-ancestors 'none'"));
      const body = await html.text();
      assert(!body.includes("groq:"));
      assert(!body.includes(marker));
      assert(!/<(?:script|link)[^>]+(?:src|href)=/i.test(body));
      const request = (body: string) =>
        new Request("http://127.0.0.1:8787/api/vote", {
          method: "POST",
          headers: { "x-judge-token": "token", "content-type": "application/json" },
          body,
        });
      assertEquals((await (await handle(request(marker))).json()).code, "SUBMISSION_INVALID");
      await store.submit(submission(await store.state()));
      assertEquals(
        (await handle(request(JSON.stringify({ id: "f01", revision: 0, choice: "tie" })))).status,
        409,
      );
    } finally {
      await store.close();
    }
  } finally {
    await t.cleanup();
  }
});

Deno.test("real HTTP server binds only 127.0.0.1 and vote crosses API to durable file to report", async () => {
  const t = await task();
  try {
    const reservation = Deno.listen({ hostname: "127.0.0.1", port: 0 });
    const port = (reservation.addr as Deno.NetAddr).port;
    reservation.close();
    const running = await startJudge(
      ["--a", "eval/runs/a", "--b", "eval/runs/b", "--port", String(port)],
      t.root,
      () => {},
    );
    const { store, server, url: origin } = running;
    try {
      assertEquals(server.addr.transport, "tcp");
      assertEquals((server.addr as Deno.NetAddr).hostname, "127.0.0.1");
      const html = await fetch(origin);
      assertEquals(html.status, 200);
      const page = await html.text();
      const token = page.match(/const token="([a-f0-9]+)"/)![1];
      const headers = {
        "x-judge-token": token,
        "content-type": "application/json",
        origin,
      };
      const state = await (await fetch(origin + "/api/state", { headers })).json();
      const result = await fetch(origin + "/api/vote", {
        method: "POST",
        headers,
        body: JSON.stringify(submission(state, "tie")),
      });
      assertEquals(result.status, 200);
      await result.json();
      const judgment = judgmentSchema.parse(JSON.parse(await Deno.readTextFile(store.path)));
      assertEquals(buildReport(judgment).wins, { A: 0, B: 0, tie: 1 });
    } finally {
      await running.close();
    }
  } finally {
    await t.cleanup();
  }
});

Deno.test("adding later quality measurements refreshes gate metadata without discarding blind votes or seed", async () => {
  const t = await task();
  try {
    const store = await JudgeStore.open(await prepare(t.root), t.root);
    await store.submit(submission(await store.state(), "tie"));
    const savedSeed = store.judgment.seed;
    await store.close();
    const text = await Deno.readTextFile(new URL("eval/runs/b/results.jsonl", t.root));
    await Deno.writeTextFile(
      new URL("eval/runs/b/quality_metrics.json", t.root),
      JSON.stringify({
        results_sha256: await digest(text),
        case_ids: t.results.map((r) => r.id),
        fidelity: { passed: 3, total: 3 },
      }),
    );
    const refreshed = await JudgeStore.open(await prepare(t.root), t.root);
    try {
      assertEquals(refreshed.judgment.seed, savedSeed);
      assertEquals(refreshed.judgment.items[0].vote!.winner, "tie");
      assertEquals(refreshed.judgment.stats!.B.fidelity_rate, 1);
      assertEquals(refreshed.judgment.revision, 2);
    } finally {
      await refreshed.close();
    }
  } finally {
    await t.cleanup();
  }
});

Deno.test("one-sided exact sign test excludes ties and matches known binomial tails", () => {
  assertEquals(signP(0, 0), 1);
  assertAlmostEquals(signP(7, 0), 1 / 128);
  assertAlmostEquals(signP(9, 1), 11 / 1024);
  assertAlmostEquals(signP(12, 3), 576 / 32768);
  assertAlmostEquals(signP(6, 1), 8 / 128);
  assert(signP(600, 400) < 0.05 && signP(600, 400) > 0);
  assertThrows(() => signP(-1, 3), EvalError, "COUNTS_INVALID");
});

function eligible(gate: "G1" | "G2" | "G3"): Judgment {
  const holdout = gate === "G3";
  const cases = holdout ? 7 : 21, dreams = holdout ? 10 : 30;
  const stats = {
    engine_version: "v10" as const,
    models: { write: "synthetic_baseline", plan: "synthetic_plan" },
    settings_sha256: "synthetic_settings",
    prompt_versions: { ...PROMPT_VERSIONS },
    cases,
    failures: 0,
    dream_count: dreams,
    mean_cost_krw: 100,
    max_cost_krw: 199,
    p95_ms: 89000,
    provenance_errors: 0,
    v2_compliance: 1,
    fidelity_rate: 0.95,
    reference_proximity: 5,
  };
  const A = structuredClone(stats),
    B = {
      ...structuredClone(stats),
      engine_version: gate === "G1" ? "v10" as const : "v11" as const,
      reference_proximity: 7,
    };
  if (gate === "G1") B.models.write = "synthetic_candidate";
  return {
    version: 1,
    mode: "ab",
    seed: "0".repeat(32),
    revision: cases,
    identity: "0".repeat(64),
    set: holdout ? "holdout" : "dev",
    gate_eligible: true,
    stats: { A, B },
    items: Array.from({ length: cases }, (_, i) => ({
      id: `synthetic${i}`,
      kind: i < (holdout ? 6 : 18) ? "single" as const : "sequence" as const,
      clarity: i < (holdout ? 6 : 18)
        ? ["fragment", "partial", "vivid"][Math.floor(i / (holdout ? 2 : 6))] as
          | "fragment"
          | "partial"
          | "vivid"
        : "mixed" as const,
      vote: {
        winner: "B" as const,
        automatic: "none" as const,
        not_ready: { A: false, B: false },
        reasons: ["engaging" as const],
        problems: [],
      },
      audit: null,
    })),
  };
}
function gateResult(judgment: Judgment, gate: "G1" | "G2" | "G3") {
  return buildReport(judgment, gate).gate as {
    result: string;
    checks: { code: string; status: string }[];
  };
}

for (const gate of ["G1", "G2", "G3"] as const) {
  Deno.test(`${gate} gate arithmetic passes only complete synthetic measurement evidence; missing fidelity fails closed`, () => {
    const judgment = eligible(gate);
    assertEquals(gateResult(judgment, gate).result, "PASS");
    judgment.stats!.B.fidelity_rate = null;
    const failed = gateResult(judgment, gate);
    assertEquals(failed.result, "FAIL");
    assertEquals(failed.checks.find((row) => row.code === "FIDELITY")!.status, "unverified");
  });
}

Deno.test("gates reject fixture/sample bias, missing judgments, changed frozen prompts, excess cost and missing reference", () => {
  const fixture = eligible("G1");
  fixture.set = "fixtures";
  fixture.gate_eligible = false;
  assertEquals(gateResult(fixture, "G1").result, "FAIL");
  const incomplete = eligible("G1");
  incomplete.items[0].vote = null;
  assertEquals(gateResult(incomplete, "G1").result, "FAIL");
  const changed = eligible("G1");
  changed.stats!.B.prompt_versions.write = "write.v11";
  assertEquals(gateResult(changed, "G1").result, "FAIL");
  const cost = eligible("G1");
  cost.stats!.B.max_cost_krw = 201;
  assertEquals(gateResult(cost, "G1").result, "FAIL");
  const reference = eligible("G2");
  reference.stats!.B.reference_proximity = null;
  assertEquals(
    gateResult(reference, "G2").checks.find((row) => row.code === "REFERENCE_PROXIMITY")!.status,
    "unverified",
  );
});

Deno.test("report gives side-specific readiness, automatic counts, reason chips and single/sequence/clarity breakdown", () => {
  const judgment = eligible("G1");
  judgment.items[0].vote!.not_ready.A = true;
  judgment.items[1].vote!.winner = "tie";
  judgment.items[2].vote!.winner = "A";
  const report = buildReport(judgment);
  assertEquals(report.wins, { A: 1, B: 19, tie: 1 });
  assertEquals((report.reasons as Record<string, number>).engaging, 21);
  assertEquals(Object.keys(report.by_kind as object), ["sequence", "single"]);
  assertEquals(Object.keys(report.by_clarity as object), ["fragment", "mixed", "partial", "vivid"]);
  assertEquals((report.not_ready as { A: { count: number } }).A.count, 1);
});

Deno.test("auxiliary pick, fifteen-case fidelity audit and paragraph annotation store and report without gates", async () => {
  const t = await task();
  try {
    await Deno.mkdir(new URL("eval/reference/", t.root));
    const sources = [
      {
        mode: "pick" as const,
        path: "eval/runs/candidates.json",
        text: JSON.stringify([{ id: "candidate1", text: "지어낸 예시." }]),
        choice: "keep",
      },
      {
        mode: "fidelity-audit" as const,
        path: "eval/runs/a/fidelity_audit.json",
        text: JSON.stringify({
          items: Array.from(
            { length: 15 },
            (_, i) => ({
              id: `audit${i}`,
              raw_text: "지어낸 꿈.",
              text: "지어낸 장면.",
              finding: "지어낸 판정.",
            }),
          ),
        }),
        choice: "agree",
      },
      {
        mode: "annotate" as const,
        path: "eval/reference/works.jsonl",
        text: JSON.stringify({ id: "reference1", paragraphs: ["지어낸 문단."], labels: ["동작"] }),
        choice: "keep",
      },
    ];
    for (const source of sources) {
      await Deno.writeTextFile(new URL(source.path, t.root), source.text);
      const prepared = await prepareAux(
        source.mode,
        source.path,
        source.mode === "fidelity-audit" ? "eval/runs/a" : undefined,
        t.root,
      );
      const store = await JudgeStore.open(prepared, t.root);
      try {
        assertEquals(store.judgment.gate_eligible, false);
        if (source.mode === "fidelity-audit") assertEquals(store.judgment.items.length, 15);
        await store.submit({
          ...submission(await store.state(), source.choice),
          ...(source.mode === "annotate"
            ? { annotations: [{ paragraph: 0, labels: ["동작"], note: "지어낸 메모" }] }
            : {}),
        });
        assertEquals(buildReport(store.judgment).judged, 1);
        assertThrows(() => buildReport(store.judgment, "G1"), EvalError, "GATE_REQUIRES_AB");
      } finally {
        await store.close();
      }
    }
  } finally {
    await t.cleanup();
  }
});

Deno.test("pro mode blindly compares common synthetic cases against rewrites and forces their origin to C", async () => {
  const t = await task();
  try {
    await Deno.mkdir(new URL("eval/pro/", t.root));
    const path = "eval/pro/rewrites.jsonl";
    await Deno.writeTextFile(
      new URL(path, t.root),
      t.results.map((r) => JSON.stringify({ id: r.id, kind: r.kind, scenes: r.scenes })).join("\n"),
    );
    const prepared = await prepareAux("pro", path, "eval/runs/a", t.root);
    assertEquals(prepared.judgment.items.length, 3);
    assertEquals(prepared.display.get("f01")!.B![0].passages[0].origin, "C");
    assertEquals(prepared.judgment.gate_eligible, false);
    assertThrows(() => buildReport(prepared.judgment, "G1"), EvalError, "GATE_REQUIRES_AB");
  } finally {
    await t.cleanup();
  }
});

Deno.test("CLI rejects LAN flags, duplicate flags and malformed inputs without printing private data", async () => {
  for (
    const args of [["--host", "0.0.0.0"], ["--a", "a", "--b", "b", "--port", "65536"], [
      "--a",
      "a",
      "--b",
      "b",
      "--port",
      "8787",
      "--port",
      "8788",
    ], ["--mode", "pick", "--a", "a"]]
  ) assertThrows(() => parseArgs(args), EvalError, "USAGE");
  assertEquals(parseArgs(["--mode", "fidelity-audit", "--run", "eval/runs/a"]).port, "8787");
  const messages: string[] = [];
  assertEquals(
    await reportMain([marker, "--gate", "INVALID"], undefined, (line) => messages.push(line)),
    1,
  );
  assertEquals(messages.some((line) => line.includes(marker)), false);
  const html = judgePage("token", "nonce");
  assert(html.includes("textContent=text"));
  assert(!html.includes("innerHTML"));
  assert(!html.includes('<input id="sources" type="checkbox" checked'));
});

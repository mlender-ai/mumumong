import { deepStrictEqual, strictEqual } from "node:assert";
import { fileURLToPath } from "node:url";
import { summaryLines, validateCorpusTexts } from "./validate_corpus.ts";

const fixture = await Deno.readTextFile(
  new URL("../../eval/fixtures/sample.jsonl", import.meta.url),
);
const script = fileURLToPath(new URL("./validate_corpus.ts", import.meta.url));
const config = fileURLToPath(new URL("./deno.json", import.meta.url));
const privacyScript = fileURLToPath(new URL("../check_eval_privacy.sh", import.meta.url));
const fakeSingle = {
  id: "test1",
  set: "dev",
  kind: "single",
  raw_text: "synthetic test input",
  expected_clarity: "partial",
  settings: null,
};
function check(value: unknown) {
  return validateCorpusTexts([{ text: JSON.stringify(value) }]);
}
async function cli(path: string) {
  return await new Deno.Command(Deno.execPath(), {
    args: ["run", "--config", config, "--allow-read", script, path],
    stdout: "piped",
    stderr: "piped",
  }).output();
}
const decode = (bytes: Uint8Array) => new TextDecoder().decode(bytes);

Deno.test("synthetic fixture counts singles separately from sequence dreams", () => {
  const { issues, summary } = validateCorpusTexts([{ text: fixture }]);
  deepStrictEqual(issues, []);
  strictEqual(summary.dev.single, 2);
  strictEqual(summary.dev.sequence, 1);
  strictEqual(summary.dev.dreams, 6);
  deepStrictEqual(summary.dev.singleClarity, { fragment: 1, partial: 1, vivid: 0 });
  deepStrictEqual(summary.dev.allClarity, { fragment: 2, partial: 2, vivid: 2, unclassified: 0 });
  strictEqual(summaryLines(summary)[0].includes("gate_units=3"), true);
});

Deno.test("schema rejects malformed fields and missing required fields", () => {
  for (
    const fields of [
      { id: "bad-id" },
      { set: "training" },
      { kind: "other" },
      { raw_text: "   " },
      { raw_text: 123 },
      { expected_clarity: "unknown" },
      { expected_clarity: null },
      { settings: "plain" },
      { unexpected: "test" },
    ]
  ) strictEqual(check({ ...fakeSingle, ...fields }).issues[0]?.code, "SCHEMA_INVALID");
  for (const key of ["id", "set", "kind", "raw_text", "expected_clarity", "settings"]) {
    const record: Record<string, unknown> = { ...fakeSingle };
    delete record[key];
    strictEqual(check(record).issues[0]?.code, "SCHEMA_INVALID");
  }
  deepStrictEqual(check({ ...fakeSingle, settings: { style: "plain" } }).issues, []);
});

Deno.test("sequence requires four ordered dreams with per-dream clarity", () => {
  const dream = { raw_text: "synthetic", expected_clarity: "vivid", recall_answers: {} };
  for (const count of [0, 3, 4, 5]) {
    const result = check({
      id: "seq1",
      set: "dev",
      kind: "sequence",
      dreams: Array.from({ length: count }, () => dream),
      settings: null,
    });
    strictEqual(result.issues.length, count === 4 ? 0 : 1);
  }
  strictEqual(
    check({
      id: "seq1",
      set: "holdout",
      kind: "sequence",
      dreams: [dream, dream, dream, { raw_text: "synthetic" }],
      settings: null,
    }).issues[0]?.code,
    "SCHEMA_INVALID",
  );
});

Deno.test("recall accepts S05 slot strings and rejects arbitrary keys or values", () => {
  deepStrictEqual(
    check({
      ...fakeSingle,
      recall_answers: {
        object: "test",
        company: "test",
        place: "test",
        feeling: "test",
        light: "test",
      },
    }).issues,
    [],
  );
  for (const recall_answers of [{ other: "test" }, { object: 2 }, []]) {
    strictEqual(check({ ...fakeSingle, recall_answers }).issues[0]?.code, "SCHEMA_INVALID");
  }
});

Deno.test("IDs must be unique across files and sets", () => {
  const { issues } = validateCorpusTexts([
    { text: JSON.stringify(fakeSingle) },
    { text: JSON.stringify({ ...fakeSingle, set: "holdout" }) },
  ]);
  deepStrictEqual(issues, [{ file: 2, line: 1, code: "DUPLICATE_ID" }]);
});

Deno.test("sentinel is separate and never contributes gate units", () => {
  const text = JSON.stringify({ ...fakeSingle, set: "sentinel", expected_clarity: null });
  const { issues, summary } = validateCorpusTexts([{ text, expectedSet: "sentinel" }]);
  deepStrictEqual(issues, []);
  strictEqual(summary.dev.dreams + summary.holdout.dreams, 0);
  strictEqual(summary.sentinel.allClarity.unclassified, 1);
  strictEqual(summaryLines(summary)[2].includes("gate_units=0"), true);
  strictEqual(validateCorpusTexts([{ text, expectedSet: "dev" }]).issues[0]?.code, "SET_MISMATCH");
});

Deno.test("empty input fails but CRLF and blank separators are accepted", () => {
  strictEqual(validateCorpusTexts([{ text: " \n\r\n" }]).issues[0]?.code, "EMPTY_CORPUS");
  deepStrictEqual(
    validateCorpusTexts([{ text: `\r\n${JSON.stringify(fakeSingle)}\r\n` }]).issues,
    [],
  );
});

Deno.test("CLI success outputs only counts and failure never echoes private-looking input", async () => {
  const dir = await Deno.makeTempDir({ prefix: "mumumong-eval-cli-" });
  const marker = "SYNTHETIC_SECRET_MARKER";
  try {
    const path = `${dir}/dev.jsonl`;
    await Deno.writeTextFile(
      path,
      JSON.stringify({ ...fakeSingle, raw_text: marker, notes: marker }),
    );
    const valid = await cli(path);
    strictEqual(valid.code, 0);
    strictEqual(decode(valid.stderr), "");
    strictEqual(decode(valid.stdout).includes(marker), false);
    strictEqual(decode(valid.stdout).trim().split("\n").length, 3);
    for (
      const content of [
        `{"${marker}":"${marker}",`,
        JSON.stringify({ ...fakeSingle, recall_answers: { [marker]: marker } }),
        `${JSON.stringify(fakeSingle)}\n${JSON.stringify(fakeSingle)}`,
      ]
    ) {
      await Deno.writeTextFile(path, content);
      const result = await cli(path);
      strictEqual(result.code, 1);
      strictEqual(decode(result.stdout), "");
      strictEqual(decode(result.stderr).includes(marker), false);
      strictEqual(decode(result.stderr).includes(dir), false);
      strictEqual(/^FAIL file=1 line=\d+ code=[A-Z_]+\n$/.test(decode(result.stderr)), true);
    }
  } finally {
    await Deno.remove(dir, { recursive: true });
  }
});

Deno.test("CLI enforces reserved set filenames and safely handles unreadable paths", async () => {
  const dir = await Deno.makeTempDir({ prefix: "mumumong-eval-path-" });
  try {
    const path = `${dir}/sentinel.jsonl`;
    await Deno.writeTextFile(path, JSON.stringify(fakeSingle));
    const mismatch = await cli(path);
    strictEqual(mismatch.code, 1);
    strictEqual(decode(mismatch.stderr), "FAIL file=1 line=1 code=SET_MISMATCH\n");
    const unreadable = await cli(`${dir}/missing.jsonl`);
    strictEqual(unreadable.code, 1);
    strictEqual(decode(unreadable.stderr), "FAIL file=1 code=READ_FAILED\n");
  } finally {
    await Deno.remove(dir, { recursive: true });
  }
});

Deno.test("privacy guard blocks forced staging in all three private directories", async () => {
  const dir = await Deno.makeTempDir({ prefix: "mumumong-eval-git-" });
  const git = async (args: string[]) => {
    const result = await new Deno.Command("git", { args, cwd: dir }).output();
    strictEqual(result.code, 0);
    return result;
  };
  const guard = () => new Deno.Command("bash", { args: [privacyScript], cwd: dir }).output();
  try {
    await git(["init", "--quiet"]);
    await Deno.writeTextFile(
      `${dir}/.gitignore`,
      "/eval/corpus/\n/eval/runs/\n/eval/judgments/\n",
    );
    for (const directory of ["corpus", "runs", "judgments"]) {
      await Deno.mkdir(`${dir}/eval/${directory}`, { recursive: true });
      const relative = `eval/${directory}/privacy-probe.jsonl`;
      await Deno.writeTextFile(`${dir}/${relative}`, "SYNTHETIC_PRIVATE_MARKER\n");
      strictEqual(decode((await git(["status", "--short", "--", relative])).stdout), "");
      strictEqual((await guard()).code, 0);
      await git(["add", "-f", "--", relative]);
      const blocked = await guard();
      strictEqual(blocked.code, 1);
      strictEqual(decode(blocked.stdout), "");
      strictEqual(decode(blocked.stderr).includes(relative), false);
      strictEqual(decode(blocked.stderr).includes("SYNTHETIC_PRIVATE_MARKER"), false);
      await git(["rm", "--cached", "--", relative]);
    }
    strictEqual((await guard()).code, 0);
  } finally {
    await Deno.remove(dir, { recursive: true });
  }
});

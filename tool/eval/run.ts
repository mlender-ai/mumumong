import { createProductionLlm } from "../../supabase/functions/_shared/llm_adapter.ts";
import { logEvent } from "../../supabase/functions/_shared/log.ts";
import {
  configSchema,
  type CorpusCase,
  digest,
  EvalError,
  type EvalSet,
  failureCode,
  PROMPT_VERSIONS,
} from "./config.ts";
import { FixtureLlm } from "./fixture_llm.ts";
import { type CaseResult, evaluateCase, summarize } from "./pipeline.ts";
import { validateCorpusTexts } from "./validate_corpus.ts";

const ROOT = new URL("../../", import.meta.url);
export interface Options {
  config: string;
  set: EvalSet;
  cases?: string[];
  concurrency: number;
  resume: boolean;
}

export function parseArgs(args: string[]): Options {
  const options: Options = {
    config: "eval/configs/baseline_v10.json",
    set: "fixtures",
    concurrency: 4,
    resume: false,
  };
  let hasSet = false;
  for (let index = 0; index < args.length; index++) {
    const flag = args[index];
    if (flag === "--resume") {
      options.resume = true;
      continue;
    }
    if (flag === "--fidelity" || flag === "--lint") {
      throw new EvalError("MEASUREMENT_NOT_IMPLEMENTED");
    }
    if (!["--config", "--set", "--cases", "--concurrency"].includes(flag)) {
      throw new EvalError("USAGE");
    }
    const value = args[++index];
    if (!value || value.startsWith("--")) throw new EvalError("USAGE");
    if (flag === "--config") options.config = value;
    if (flag === "--set") {
      if (!["dev", "holdout", "fixtures", "sentinel"].includes(value)) throw new EvalError("USAGE");
      options.set = value as EvalSet;
      hasSet = true;
    }
    if (flag === "--cases") {
      options.cases = value.split(",");
      if (
        options.cases.some((id) => !/^[A-Za-z0-9]+$/.test(id)) ||
        new Set(options.cases).size !== options.cases.length
      ) throw new EvalError("USAGE");
      options.cases.sort();
    }
    if (flag === "--concurrency") {
      if (!/^[1-9][0-9]*$/.test(value) || Number(value) > 32) throw new EvalError("USAGE");
      options.concurrency = Number(value);
    }
  }
  if (!hasSet) throw new EvalError("USAGE");
  // Q-32 owns the one-time holdout gate. Fail before reading any corpus/config.
  if (options.set === "holdout") throw new EvalError("HOLDOUT_LOCKED_UNTIL_Q32");
  return options;
}

async function atomicWrite(path: URL, contents: string): Promise<void> {
  const temporary = new URL(`${path.href}.${crypto.randomUUID()}.tmp`);
  await Deno.writeTextFile(temporary, contents, { mode: 0o600 });
  await Deno.rename(temporary, path);
}

async function git(args: string[]): Promise<string> {
  const output = await new Deno.Command("git", { args, cwd: ROOT, stdout: "piped", stderr: "null" })
    .output();
  if (!output.success) throw new EvalError("GIT_METADATA_FAILED");
  return new TextDecoder().decode(output.stdout).trim();
}

async function sourceFingerprint(): Promise<string> {
  const sources: { path: string; sha256: string }[] = [];
  async function visit(relative: string) {
    for await (const entry of Deno.readDir(new URL(relative, ROOT))) {
      const path = `${relative}${entry.name}`;
      if (entry.isDirectory) await visit(`${path}/`);
      else if (entry.isFile && (path.endsWith(".ts") || entry.name === "deno.json")) {
        sources.push({ path, sha256: await digest(await Deno.readTextFile(new URL(path, ROOT))) });
      }
    }
  }
  await visit("supabase/functions/");
  await visit("tool/eval/");
  return digest(JSON.stringify(sources.sort((a, b) => a.path.localeCompare(b.path))));
}

async function acquireLock(directory: URL): Promise<() => Promise<void>> {
  const path = new URL(".lock", directory);
  try {
    const pid = Number(await Deno.readTextFile(path));
    if (!Number.isSafeInteger(pid) || pid <= 0) throw new EvalError("RUN_LOCK_INVALID");
    if (Deno.build.os === "windows") throw new EvalError("RUN_LOCKED");
    const alive = await new Deno.Command("kill", {
      args: ["-0", String(pid)],
      stdout: "null",
      stderr: "null",
    }).output();
    if (alive.success) throw new EvalError("RUN_LOCKED");
    await Deno.remove(path);
  } catch (error) {
    if (!(error instanceof Deno.errors.NotFound)) throw error;
  }
  try {
    await Deno.writeTextFile(path, String(Deno.pid), { createNew: true, mode: 0o600 });
  } catch {
    throw new EvalError("RUN_LOCKED");
  }
  return () => Deno.remove(path);
}

export async function runEvaluation(options: Options, root = ROOT, now = new Date()) {
  if (options.set === "holdout") throw new EvalError("HOLDOUT_LOCKED_UNTIL_Q32");
  let config;
  try {
    config = configSchema.parse(JSON.parse(await Deno.readTextFile(new URL(options.config, root))));
  } catch {
    throw new EvalError("CONFIG_INVALID");
  }
  const corpusPath = options.set === "fixtures"
    ? "eval/fixtures/sample.jsonl"
    : `eval/corpus/${options.set}.jsonl`;
  let text: string;
  try {
    text = await Deno.readTextFile(new URL(corpusPath, root));
  } catch {
    throw new EvalError("CORPUS_READ_FAILED");
  }
  const expectedSet = options.set === "fixtures" ? "dev" : options.set;
  if (validateCorpusTexts([{ text, expectedSet }]).issues.length) {
    throw new EvalError("CORPUS_INVALID");
  }
  const all = text.split(/\r?\n/).filter((line) => line.trim()).map((line) =>
    JSON.parse(line) as CorpusCase
  );
  if (options.cases?.some((id) => !all.some((record) => record.id === id))) {
    throw new EvalError("CASE_UNKNOWN");
  }
  const records = all.filter((record) => !options.cases || options.cases.includes(record.id));
  const hash = (await digest(JSON.stringify(config))).slice(0, 6);
  const commit = await git(["rev-parse", "HEAD"]);
  const diffHash = await digest(
    await git(["diff", "HEAD", "--", "supabase/functions", "tool/eval", "deno.json"]),
  );
  const identity = {
    config,
    set: options.set,
    case_ids: records.map((record) => record.id),
    corpus_sha256: await digest(text),
    git_commit: commit,
    tracked_diff_sha256: diffHash,
    source_sha256: await sourceFingerprint(),
    prompt_versions: PROMPT_VERSIONS,
    fixture_llm: options.set === "fixtures",
  };
  const runsRoot = new URL("eval/runs/", root);
  await Deno.mkdir(runsRoot, { recursive: true, mode: 0o700 });
  let directory: URL | undefined;
  if (options.resume) {
    const matches: string[] = [];
    for await (const entry of Deno.readDir(runsRoot)) {
      if (
        entry.isDirectory && entry.name.startsWith(`${config.label}-`) &&
        entry.name.endsWith(`-${hash}`)
      ) matches.push(entry.name);
    }
    for (const name of matches.sort().reverse()) {
      try {
        const previous = JSON.parse(
          await Deno.readTextFile(new URL(`${name}/config.json`, runsRoot)),
        );
        if (JSON.stringify(previous.identity) === JSON.stringify(identity)) {
          directory = new URL(`${name}/`, runsRoot);
          break;
        }
      } catch { /* Ignore incomplete manifests, never print their contents. */ }
    }
    if (!directory) throw new EvalError("RESUME_MATCH_NOT_FOUND");
  } else {
    const timestamp = now.toISOString().replace(/[-:T]/g, "").slice(0, 12);
    directory = new URL(`${config.label}-${timestamp}-${hash}/`, runsRoot);
    await Deno.mkdir(directory, { recursive: true, mode: 0o700 });
    try {
      await Deno.writeTextFile(
        new URL("config.json", directory),
        JSON.stringify(
          {
            ...config,
            prompt_versions: PROMPT_VERSIONS,
            git_commit: commit,
            created_at: now.toISOString(),
            identity,
          },
          null,
          2,
        ) + "\n",
        { createNew: true, mode: 0o600 },
      );
    } catch {
      throw new EvalError("RUN_EXISTS_USE_RESUME");
    }
  }
  const unlock = await acquireLock(directory);
  try {
    const casesRoot = new URL(".cases/", directory);
    await Deno.mkdir(casesRoot, { recursive: true, mode: 0o700 });
    const results = new Map<string, CaseResult>();
    if (options.resume) {
      for (const record of records) {
        try {
          const result = JSON.parse(
            await Deno.readTextFile(new URL(`${record.id}.json`, casesRoot)),
          ) as CaseResult;
          if (result.id === record.id && result.status === "success") {
            results.set(record.id, result);
          }
        } catch { /* Missing/failed checkpoints are retried as a whole case. */ }
      }
    }
    const skipped = results.size;
    const pending = records.filter((record) => !results.has(record.id));
    const llm = options.set === "fixtures" ? new FixtureLlm() : createProductionLlm((name) => {
      if (!name.startsWith("MODEL_")) return undefined;
      const role = name.slice(6).toLowerCase() as keyof typeof config.models;
      return config.models[role] ?? undefined;
    });
    let checkpoint = Promise.resolve();
    const ordered = () =>
      records.flatMap((record) => results.has(record.id) ? [results.get(record.id)!] : []);
    const save = () => {
      checkpoint = checkpoint.then(async () => {
        await atomicWrite(
          new URL("results.jsonl", directory),
          ordered().map((result) => JSON.stringify(result)).join("\n") + "\n",
        );
        await atomicWrite(
          new URL("summary.json", directory),
          JSON.stringify(
            summarize(ordered(), !["fixtures", "sentinel"].includes(options.set)),
            null,
            2,
          ) + "\n",
        );
      });
      return checkpoint;
    };
    let cursor = 0;
    await Promise.all(
      Array.from({ length: Math.min(options.concurrency, pending.length) }, async () => {
        while (cursor < pending.length) {
          const record = pending[cursor++];
          const result = await evaluateCase(record, config, llm);
          await atomicWrite(new URL(`${record.id}.json`, casesRoot), JSON.stringify(result));
          results.set(record.id, result);
          await save();
          logEvent("eval_case", { dream_id: record.id, status: result.status });
        }
      }),
    );
    await save();
    const summary = summarize(ordered(), !["fixtures", "sentinel"].includes(options.set));
    logEvent("eval_success", { count: summary.success });
    logEvent("eval_failed", { count: summary.failed });
    logEvent("eval_skipped", { count: skipped });
    return { directory, summary, skipped, results: ordered() };
  } finally {
    await unlock();
  }
}

export async function main(args: string[]): Promise<number> {
  try {
    const result = await runEvaluation(parseArgs(args));
    return result.summary.failed ? 1 : 0;
  } catch (error) {
    logEvent("eval_failed", { status: "failed", code: failureCode(error) });
    return 1;
  }
}

if (import.meta.main) Deno.exit(await main(Deno.args));

import baseline from "../../eval/configs/baseline_v10.json" with { type: "json" };
import { parseArgs, runEvaluation } from "./run.ts";
import { parseArgs as parseJudgeArgs, startJudge } from "./judge.ts";
import { ROOT } from "./judge_inputs.ts";
import { EvalError } from "./config.ts";
import { safeCode } from "./judgment.ts";

// Convenience demonstration only: two Q-03 fixture runs, never private corpus or an LLM.
export async function createDemo(root = ROOT) {
  await Deno.mkdir(new URL("eval/runs/", root), { recursive: true, mode: 0o700 });
  const identifier = crypto.randomUUID().slice(0, 8);
  const paths: string[] = [];
  for (const side of ["a", "b"]) {
    const config = `eval/runs/q05demo-${identifier}-${side}.json`;
    await Deno.writeTextFile(
      new URL(config, root),
      JSON.stringify({ ...baseline, label: `q05demo_${identifier}_${side}` }),
      { mode: 0o600, createNew: true },
    );
    const result = await runEvaluation(parseArgs(["--set", "fixtures", "--config", config]), root);
    const name = result.directory.href.slice(new URL("eval/runs/", root).href.length).replace(
      /\/$/,
      "",
    );
    paths.push(`eval/runs/${name}`);
  }
  return { a: paths[0], b: paths[1] };
}
if (import.meta.main) {
  try {
    if (Deno.args.length !== 0 && (Deno.args.length !== 2 || Deno.args[0] !== "--port")) {
      throw new EvalError("USAGE");
    }
    parseJudgeArgs(["--a", "eval/runs/demo-a", "--b", "eval/runs/demo-b", ...Deno.args]);
    const runs = await createDemo();
    const running = await startJudge(["--a", runs.a, "--b", runs.b, ...Deno.args]);
    const shutdown = () => {
      void running.close();
    };
    Deno.addSignalListener("SIGINT", shutdown);
    Deno.addSignalListener("SIGTERM", shutdown);
    await running.server.finished;
    await running.close();
  } catch (error) {
    console.log(JSON.stringify({ event: "judge_demo_failed", code: safeCode(error) }));
    Deno.exit(1);
  }
}

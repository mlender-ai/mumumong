import { EvalError } from "./config.ts";
import { prepareAB, ROOT } from "./judge_inputs.ts";
import { type AuxMode, prepareAux } from "./judge_aux.ts";
import { JudgeStore } from "./judge_store.ts";
import { safeCode, seed } from "./judgment.ts";
import { judgePage } from "./judge_page.ts";

export function parseArgs(args: string[]) {
  const options: Record<string, string> = { mode: "ab", port: "8787" };
  const seen = new Set<string>();
  for (let i = 0; i < args.length; i++) {
    const key = args[i];
    if (
      !["--a", "--b", "--port", "--mode", "--run", "--candidates", "--reference", "--pro"].includes(
        key,
      ) || !args[i + 1] || args[i + 1].startsWith("--") ||
      seen.has(key)
    ) throw new EvalError("USAGE");
    seen.add(key);
    options[key.slice(2)] = args[++i];
  }
  if (
    !/^[1-9][0-9]{0,4}$/.test(options.port) || Number(options.port) > 65535 ||
    !["ab", "pro", "fidelity-audit", "pick", "annotate"].includes(options.mode)
  ) throw new EvalError("USAGE");
  const needed = options.mode === "ab"
    ? ["a", "b"]
    : options.mode === "pro"
    ? ["a", "pro"]
    : options.mode === "fidelity-audit"
    ? ["run"]
    : options.mode === "pick"
    ? ["candidates"]
    : ["reference"];
  if (
    needed.some((key) => !options[key]) ||
    Object.keys(options).some((key) => !["mode", "port", ...needed].includes(key))
  ) throw new EvalError("USAGE");
  return options;
}
export function requestHandler(store: JudgeStore, origin: string, token: string, nonce: string) {
  const html = judgePage(token, nonce);
  const headers = {
    "cache-control": "no-store",
    "referrer-policy": "no-referrer",
    "x-content-type-options": "nosniff",
    "content-security-policy":
      `default-src 'none'; script-src 'nonce-${nonce}'; style-src 'unsafe-inline'; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'`,
    "cross-origin-opener-policy": "same-origin",
  };
  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...headers, "content-type": "application/json" },
    });
  return async (request: Request): Promise<Response> => {
    const url = new URL(request.url);
    if (
      url.origin !== origin ||
      request.headers.get("host") && request.headers.get("host") !== new URL(origin).host ||
      request.headers.get("origin") && request.headers.get("origin") !== origin ||
      request.headers.get("sec-fetch-site") === "cross-site"
    ) return json({ code: "LOCAL_REQUEST_REQUIRED" }, 403);
    if (url.pathname === "/" && request.method === "GET") {
      return new Response(html, {
        headers: { ...headers, "content-type": "text/html; charset=utf-8" },
      });
    }
    if (request.headers.get("x-judge-token") !== token) {
      return json({ code: "LOCAL_SESSION_REQUIRED" }, 403);
    }
    try {
      if (url.pathname === "/api/state" && request.method === "GET") {
        const value = url.searchParams.get("index");
        if (
          value !== null && (!/^\d+$/.test(value) || Number(value) > store.judgment.items.length)
        ) throw new EvalError("INDEX_INVALID");
        return json(
          await store.state(
            value === null ? undefined : Number(value),
            url.searchParams.get("sources") === "1",
          ),
        );
      }
      if (url.pathname === "/api/vote" && request.method === "POST") {
        if (request.headers.get("content-type") !== "application/json") {
          throw new EvalError("SUBMISSION_INVALID");
        }
        const text = await request.text();
        if (text.length > 300000) throw new EvalError("SUBMISSION_INVALID");
        let body: unknown;
        try {
          body = JSON.parse(text);
        } catch {
          throw new EvalError("SUBMISSION_INVALID");
        }
        await store.submit(body);
        return json({ status: "saved", revision: store.judgment.revision });
      }
      return json({ code: "NOT_FOUND" }, 404);
    } catch (error) {
      return json(
        { code: safeCode(error) },
        error instanceof EvalError && error.code === "REVISION_CONFLICT" ? 409 : 400,
      );
    }
  };
}
export async function startJudge(
  args: string[],
  root = ROOT,
  log: (text: string) => void = console.log,
) {
  const options = parseArgs(args);
  const prepared = options.mode === "ab"
    ? await prepareAB(options.a, options.b, root)
    : await prepareAux(
      options.mode as AuxMode,
      options.candidates ?? options.reference ?? options.pro ??
        `${options.run.replace(/\/$/, "")}/fidelity_audit.json`,
      options.a ?? options.run,
      root,
    );
  const store = await JudgeStore.open(prepared, root);
  const token = seed(), nonce = seed();
  const origin = `http://127.0.0.1:${options.port}`;
  let server: Deno.HttpServer;
  try {
    server = Deno.serve({
      hostname: "127.0.0.1",
      port: Number(options.port),
      onListen: () =>
        log(
          JSON.stringify({
            event: "judge_started",
            url: origin,
            mode: options.mode,
            cases: store.judgment.items.length,
          }),
        ),
      onError: () => new Response("LOCAL_SERVER_ERROR", { status: 500 }),
    }, requestHandler(store, origin, token, nonce));
  } catch {
    await store.close();
    throw new EvalError("SERVER_START_FAILED");
  }
  let closing: Promise<void> | undefined;
  const close = () =>
    closing ??= (async () => {
      await server.shutdown();
      await store.close();
    })();
  return { store, server, close, url: origin };
}
if (import.meta.main) {
  try {
    const running = await startJudge(Deno.args);
    const shutdown = () => {
      void running.close();
    };
    Deno.addSignalListener("SIGINT", shutdown);
    Deno.addSignalListener("SIGTERM", shutdown);
    await running.server.finished;
    await running.close();
  } catch (error) {
    console.log(JSON.stringify({ event: "judge_failed", code: safeCode(error) }));
    Deno.exit(1);
  }
}

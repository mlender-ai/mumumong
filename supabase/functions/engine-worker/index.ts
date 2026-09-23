import { logEvent } from "../_shared/log.ts";
import { json } from "../_shared/pipeline.ts";
import { serviceRoleClient } from "../_shared/supabase.ts";
import { authorizedWorker } from "../_shared/worker_auth.ts";
import { isTerminalFailure, retryDelaySeconds, stageFunction } from "./worker.ts";
import { createClient } from "@supabase/supabase-js";

interface ClaimedJob {
  id: string;
  dream_id: string | null;
  type: string;
  attempt: number;
}

function continueInBackground(
  url: string,
  serviceKey: string,
  delaySeconds = 0,
): void {
  const runtime = (globalThis as unknown as {
    EdgeRuntime?: { waitUntil(promise: Promise<unknown>): void };
  }).EdgeRuntime;
  if (!runtime) return;
  runtime.waitUntil(
    (async () => {
      if (delaySeconds > 0) {
        await new Promise((resolve) => setTimeout(resolve, delaySeconds * 1000));
      }
      await fetch(url, {
        method: "POST",
        headers: { apikey: serviceKey, "content-type": "application/json" },
        body: "{}",
      });
    })().catch(() => undefined),
  );
}

Deno.serve(async (request: Request): Promise<Response> => {
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const baseUrl = Deno.env.get("SUPABASE_URL");
  if (!serviceKey || !baseUrl) return json({ error: "server_not_configured" }, 500);
  const client = serviceRoleClient();

  const serviceCall = authorizedWorker(request, serviceKey);
  let userId: string | null = null;
  if (!serviceCall) {
    const token = request.headers.get("authorization")?.replace(/^Bearer\s+/u, "") ?? "";
    const publicKey = Deno.env.get("SUPABASE_ANON_KEY");
    if (!token || !publicKey) return json({ error: "forbidden" }, 403);
    const auth = createClient(baseUrl, publicKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await auth.auth.getUser(token);
    if (error || !data.user) return json({ error: "forbidden" }, 403);
    userId = data.user.id;
  }

  const { data, error } = userId
    ? await client.rpc("claim_job_for_user", { p_user_id: userId })
    : await client.rpc("claim_job");
  if (error) return json({ error: "claim_failed" }, 500);
  if (!data?.id) return json({ ok: true, idle: true });
  const job = data as ClaimedJob;
  const functionName = stageFunction(job.type);
  if (!functionName) {
    await client.from("jobs").update({ status: "failed", error: "unsupported_stage" }).eq(
      "id",
      job.id,
    );
    return json({ ok: false, job_id: job.id, terminal: true });
  }

  let stageResponse: Response | null = null;
  let body: Record<string, unknown> = {};
  try {
    stageResponse = await fetch(`${baseUrl}/functions/v1/${functionName}`, {
      method: "POST",
      headers: { apikey: serviceKey, "content-type": "application/json" },
      body: JSON.stringify({ job_id: job.id }),
      signal: AbortSignal.timeout(60_000),
    });
    body = await stageResponse.json() as Record<string, unknown>;
  } catch {
    stageResponse = null;
  }

  if (stageResponse?.ok && body.terminal !== true) {
    await client.from("jobs").update({ status: "done", error: null }).eq("id", job.id);
    logEvent("engine_worker_done", {
      job_id: job.id,
      dream_id: job.dream_id ?? undefined,
      stage: job.type,
      attempt: job.attempt,
      status: "done",
    });
    continueInBackground(`${baseUrl}/functions/v1/engine-worker`, serviceKey);
    return json({ ok: true, job_id: job.id, stage: job.type });
  }

  const terminal = isTerminalFailure(
    stageResponse?.status ?? null,
    job.attempt,
    body.terminal === true,
  );
  const stageCode = typeof body.code === "string" ? body.code : null;
  if (terminal) {
    await client.from("jobs").update({
      status: "failed",
      error: body.terminal === true
        ? "validation_terminal"
        : stageCode
        ? `stage_${stageCode}`
        : "attempts_exhausted",
    }).eq("id", job.id);
    if (job.dream_id && job.type !== "remember") {
      await client.from("dreams").update({ status: "failed" }).eq("id", job.dream_id);
    }
  } else {
    const retryAfter = retryDelaySeconds(job.attempt);
    const availableAt = new Date(Date.now() + retryAfter * 1000).toISOString();
    await client.from("jobs").update({
      status: "queued",
      error: stageCode ? `stage_${stageCode}` : `stage_http_${stageResponse?.status ?? 0}`,
      available_at: availableAt,
    }).eq("id", job.id);
    continueInBackground(`${baseUrl}/functions/v1/engine-worker`, serviceKey, retryAfter);
  }
  logEvent("engine_worker_failed", {
    job_id: job.id,
    dream_id: job.dream_id ?? undefined,
    stage: job.type,
    attempt: job.attempt,
    status: terminal ? "failed" : "queued",
    code: stageResponse ? `http_${stageResponse.status}` : "unreachable",
  });
  return json(
    {
      ok: false,
      job_id: job.id,
      terminal,
      code: stageResponse ? `http_${stageResponse.status}` : "unreachable",
      stage_code: typeof body.code === "string" ? body.code : undefined,
    },
    terminal ? 200 : 202,
  );
});

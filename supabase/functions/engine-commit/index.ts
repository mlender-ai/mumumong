// WO-E6 · Commit — Edge Function entrypoint.
//
// Thin by design: the job row supplies the input, `runCommit` does the work, and
// the result comes back as JSON. The worker (WO-14) invokes this.

import { logEvent } from "../_shared/log.ts";
import { serviceRoleClient } from "../_shared/supabase.ts";
import { placementSchema, sceneDraftSchema } from "../_shared/contract.ts";
import { claritySchema } from "../_shared/contract.ts";
import { loadJob } from "../_shared/jobs.ts";
import { type CommitInput, CommitInputError, runCommit } from "./commit.ts";
import { SupabaseCommitGateway } from "./gateway.ts";
import { authorizedWorker } from "../_shared/worker_auth.ts";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (!authorizedWorker(request, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"))) {
    return json({ error: "forbidden" }, 403);
  }
  if (request.method !== "POST") return new Response("method not allowed", { status: 405 });

  let body: Record<string, unknown>;
  try {
    body = await request.json();
    if (!body || typeof body !== "object" || Array.isArray(body)) {
      return json({ error: "body must be an object" }, 400);
    }
  } catch {
    return json({ error: "body must be JSON" }, 400);
  }

  const jobId = typeof body.job_id === "string" ? body.job_id : null;
  if (!jobId) return json({ error: "job_id is required" }, 400);

  const client = serviceRoleClient();
  const job = await loadJob(client, jobId);
  if (!job) return json({ error: "job not found" }, 404);
  if (job.type !== "commit") return json({ error: "wrong job stage" }, 400);
  if (!job.dream_id) return json({ error: "commit requires a dream" }, 400);

  // Section C: a stage reads its input from jobs.payload.
  const payload = job.payload;

  const placement = placementSchema.safeParse(payload.placement);
  if (!placement.success) return json({ error: "payload placement is invalid" }, 400);

  const clarity = claritySchema.safeParse(payload.clarity);
  if (!clarity.success) return json({ error: "payload clarity is invalid" }, 400);

  let draft: CommitInput["draft"];
  if (placement.data !== "standalone") {
    const parsed = sceneDraftSchema.safeParse(payload.draft);
    if (!parsed.success) {
      // E5 should have caught this; reaching here means the pipeline skipped it.
      logEvent("engine_commit_rejected", { job_id: jobId, stage: "commit", code: "V1" });
      return json({ error: "draft does not match the scene schema" }, 400);
    }
    draft = parsed.data;
  }

  const started = Date.now();
  try {
    const result = await runCommit(new SupabaseCommitGateway(client), {
      jobId,
      userId: job.user_id,
      dreamId: job.dream_id,
      volumeId: job.volume_id,
      clarity: clarity.data,
      placement: placement.data,
      draft,
      sceneOrderKey: typeof payload.scene_order_key === "string"
        ? payload.scene_order_key
        : undefined,
      links: payload.links as CommitInput["links"],
      existingSceneId: typeof payload.scene_id === "string" ? payload.scene_id : undefined,
    });

    logEvent("engine_commit_done", {
      job_id: jobId,
      dream_id: job.dream_id,
      scene_id: result.sceneId ?? undefined,
      stage: "commit",
      status: result.archivedOnly ? "archived_only" : "done",
      ms: Date.now() - started,
    });

    return json(result);
  } catch (error) {
    const invalid = error instanceof CommitInputError;
    logEvent("engine_commit_failed", {
      job_id: jobId,
      stage: "commit",
      code: invalid ? "invalid_input" : "commit_failed",
    });
    return json({ error: invalid ? "invalid_input" : "commit_failed" }, invalid ? 400 : 500);
  }
});

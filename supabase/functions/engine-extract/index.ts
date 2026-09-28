import { logEvent } from "../_shared/log.ts";
import { createProductionLlm } from "../_shared/llm_adapter.ts";
import { runExtract } from "./core.ts";
import { loadJob } from "../_shared/jobs.ts";
import {
  enqueueStage,
  json,
  mergeJobPayload,
  recordCoreRuns,
  requestJobId,
} from "../_shared/pipeline.ts";
import { serviceRoleClient } from "../_shared/supabase.ts";
import { authorizedWorker } from "../_shared/worker_auth.ts";

Deno.serve(async (request: Request): Promise<Response> => {
  if (!authorizedWorker(request, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"))) {
    return json({ error: "forbidden" }, 403);
  }
  const jobId = await requestJobId(request);
  if (!jobId) return json({ error: "job_id is required" }, 400);

  const client = serviceRoleClient();
  const job = await loadJob(client, jobId);
  if (!job) return json({ error: "job not found" }, 404);
  if (job.type !== "extract" || !job.dream_id) return json({ error: "wrong job stage" }, 400);

  if (job.payload.extract_complete === true) {
    return json({ ok: true, reused: true });
  }

  const { data: dream, error: dreamError } = await client.from("dreams")
    .select("raw_text, recall_answers")
    .eq("id", job.dream_id)
    .single();
  if (dreamError || !dream) return json({ error: "dream unavailable" }, 500);

  try {
    const core = await runExtract({ dreamId: job.dream_id, dream }, createProductionLlm());
    const { normalized, rows } = core;

    const { error: deleteError } = await client.from("dream_elements").delete()
      .eq("dream_id", job.dream_id);
    if (deleteError) throw new Error("elements_delete");
    if (rows.length > 0) {
      const { error: insertError } = await client.from("dream_elements").insert(rows);
      if (insertError) throw new Error("elements_insert");
    }
    const { error: dreamWriteError } = await client.from("dreams").update({
      clarity: normalized.clarity,
      sensitive_flags: normalized.sensitive_flags,
      status: "processing",
    }).eq("id", job.dream_id);
    if (dreamWriteError) throw new Error("dream_write");

    const payload = await mergeJobPayload(client, jobId, job.payload, core.nextPayloadPatch);
    await recordCoreRuns(client, {
      jobId,
      stage: "extract",
      modelRuns: core.modelRuns,
      validation: { schema: true, elements: rows.length },
    });
    await enqueueStage(client, {
      userId: job.user_id,
      dreamId: job.dream_id,
      volumeId: job.volume_id,
      type: "link",
      payload,
    });
    logEvent("engine_extract_done", {
      job_id: jobId,
      dream_id: job.dream_id,
      stage: "extract",
      count: rows.length,
      ms: core.modelRuns[0].latencyMs,
    });
    return json({ ok: true, count: rows.length, clarity: normalized.clarity });
  } catch (error) {
    const code = error instanceof Error ? error.message.slice(0, 64) : "unknown";
    logEvent("engine_extract_failed", {
      job_id: jobId,
      dream_id: job.dream_id,
      stage: "extract",
      code,
    });
    return json({ error: "extract_failed", code }, 500);
  }
});

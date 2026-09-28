import { loadJob } from "../_shared/jobs.ts";
import { createProductionLlm } from "../_shared/llm_adapter.ts";
import { runPlan } from "./core.ts";
import { logEvent } from "../_shared/log.ts";
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
  if (job.type !== "plan" || !job.dream_id) return json({ error: "wrong job stage" }, 400);

  try {
    const volumeQuery = await client.from("volumes")
      .select("adaptation, style, narrative_voice, genre_profile, genre_directive")
      .eq("id", job.volume_id).single();
    const dreamQuery = await client.from("dreams")
      .select("raw_text, recall_answers")
      .eq("id", job.dream_id).single();
    const memoryQuery = await client.from("narrative_memory")
      .select("story_so_far, open_threads, motifs")
      .eq("volume_id", job.volume_id).maybeSingle();
    const scenesQuery = await client.from("scenes")
      .select("id, order_key, title, placement, open_image")
      .eq("volume_id", job.volume_id).order("order_key", { ascending: false }).limit(12);
    if (volumeQuery.error || dreamQuery.error || memoryQuery.error || scenesQuery.error) {
      throw new Error("plan_inputs");
    }

    const core = await runPlan({
      dream: dreamQuery.data,
      volume: volumeQuery.data,
      memory: memoryQuery.data,
      existingScenes: scenesQuery.data ?? [],
      payload: job.payload,
    }, createProductionLlm());
    const { plan } = core;
    const payload = await mergeJobPayload(client, jobId, job.payload, core.nextPayloadPatch);
    await recordCoreRuns(client, {
      jobId,
      stage: "plan",
      modelRuns: core.modelRuns,
      validation: { schema: true, placement: plan.placement },
    });
    await enqueueStage(client, {
      userId: job.user_id,
      dreamId: job.dream_id,
      volumeId: job.volume_id,
      type: core.nextStage,
      payload,
      keySuffix: plan.placement === "standalone" ? undefined : "0",
    });
    logEvent("engine_plan_done", {
      job_id: jobId,
      dream_id: job.dream_id,
      stage: "plan",
      status: plan.placement,
      ms: core.modelRuns[0].latencyMs,
    });
    return json({ ok: true, placement: plan.placement });
  } catch (error) {
    logEvent("engine_plan_failed", {
      job_id: jobId,
      stage: "plan",
      code: error instanceof Error ? error.message.slice(0, 64) : "unknown",
    });
    return json({ error: "plan_failed" }, 500);
  }
});

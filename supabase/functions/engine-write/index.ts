import { loadJob } from "../_shared/jobs.ts";
import { createProductionLlm } from "../_shared/llm_adapter.ts";
import { writeState } from "../_shared/scene_loop_policy.ts";
import type { LockedPassage } from "../_shared/stage_context.ts";
import { runWrite } from "./core.ts";
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
  if (job.type !== "write" || !job.dream_id) return json({ error: "wrong job stage" }, 400);

  try {
    const dreamQuery = await client.from("dreams")
      .select("raw_text, recall_answers, sensitive_flags")
      .eq("id", job.dream_id).single();
    const volumeQuery = await client.from("volumes")
      .select("adaptation, style, narrative_voice, genre_profile, genre_directive")
      .eq("id", job.volume_id).single();
    const memoryQuery = await client.from("narrative_memory")
      .select("story_so_far, open_threads, world_rules, motifs")
      .eq("volume_id", job.volume_id).maybeSingle();
    const entitiesQuery = await client.from("entities")
      .select("id, type, role_name, description, aliases, mention_count")
      .eq("volume_id", job.volume_id).order("mention_count", { ascending: false }).limit(20);
    const recentScenesQuery = await client.from("scenes")
      .select("id, title, open_image, passages(order_key,text,origin,locked)")
      .eq("volume_id", job.volume_id).order("order_key", { ascending: false }).limit(2);
    if (
      dreamQuery.error || volumeQuery.error || memoryQuery.error || entitiesQuery.error ||
      recentScenesQuery.error
    ) throw new Error("write_inputs");

    let lockedPassages: LockedPassage[] = [];
    if (typeof job.payload.attach_to_scene_id === "string") {
      const lockedQuery = await client.from("passages")
        .select("text, order_key")
        .eq("scene_id", job.payload.attach_to_scene_id)
        .eq("locked", true);
      if (lockedQuery.error) throw new Error("locked_inputs");
      lockedPassages = lockedQuery.data ?? [];
    }

    const { isFallback, writeAttempt } = writeState(job.payload);
    const core = await runWrite({
      dream: dreamQuery.data,
      volume: volumeQuery.data,
      memory: memoryQuery.data,
      entities: entitiesQuery.data ?? [],
      recentScenes: recentScenesQuery.data ?? [],
      lockedPassages,
      payload: job.payload,
      writeAttempt,
      isFallback,
    }, createProductionLlm());
    const payload = await mergeJobPayload(client, jobId, job.payload, core.nextPayloadPatch);
    await recordCoreRuns(client, {
      jobId,
      stage: "write",
      modelRuns: [core.auditRun],
      validation: { schema: true, passages: core.passageCount },
      isFallback,
    });
    await enqueueStage(client, {
      userId: job.user_id,
      dreamId: job.dream_id,
      volumeId: job.volume_id,
      type: "validate",
      payload,
      keySuffix: String(writeAttempt),
    });
    logEvent("engine_write_done", {
      job_id: jobId,
      dream_id: job.dream_id,
      stage: "write",
      count: core.passageCount,
      attempt: writeAttempt,
      status: isFallback ? "fallback" : "draft",
      ms: core.primaryLatencyMs,
    });
    return json({ ok: true, passages: core.passageCount, attempt: writeAttempt });
  } catch (error) {
    logEvent("engine_write_failed", {
      job_id: jobId,
      stage: "write",
      attempt: job.attempt,
      code: error instanceof Error ? error.message.slice(0, 64) : "unknown",
    });
    return json({ error: "write_failed" }, 500);
  }
});

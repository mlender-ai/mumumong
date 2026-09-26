import {
  ADAPTATION_BUDGETS,
  adaptationSchema,
  claritySchema,
  lengthCapFor,
} from "../_shared/contract.ts";
import { loadJob } from "../_shared/jobs.ts";
import { callStructured, QUALITY_MODEL } from "../_shared/llm.ts";
import { logEvent } from "../_shared/log.ts";
import {
  enqueueStage,
  json,
  mergeJobPayload,
  recordModelRun,
  requestJobId,
} from "../_shared/pipeline.ts";
import { PLAN_PROMPT_VERSION, PLAN_SYSTEM } from "../_shared/prompts/plan.v1.ts";
import { planJsonSchema, planOutputSchema } from "../_shared/stage_contracts.ts";
import { serviceRoleClient } from "../_shared/supabase.ts";
import { authorizedWorker } from "../_shared/worker_auth.ts";
import { enforcePlan, nextSceneOrderKey } from "./plan.ts";

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
    const memoryQuery = await client.from("narrative_memory")
      .select("story_so_far, open_threads, motifs")
      .eq("volume_id", job.volume_id).maybeSingle();
    const scenesQuery = await client.from("scenes")
      .select("id, order_key, title, placement, open_image")
      .eq("volume_id", job.volume_id).order("order_key", { ascending: false }).limit(12);
    if (volumeQuery.error || memoryQuery.error || scenesQuery.error) throw new Error("plan_inputs");

    const clarity = claritySchema.parse(job.payload.clarity);
    const adaptation = adaptationSchema.parse(volumeQuery.data.adaptation);
    const lengthCap = lengthCapFor(clarity, adaptation);
    const result = await callStructured<unknown>({
      model: QUALITY_MODEL,
      schemaName: "mumumong_plan_v1",
      schema: planJsonSchema,
      system: PLAN_SYSTEM,
      input: {
        elements: job.payload.elements ?? [],
        links: job.payload.links ?? [],
        clarity,
        adaptation,
        adaptation_budget: ADAPTATION_BUDGETS[adaptation],
        length_cap: lengthCap,
        narrative_memory: memoryQuery.data ?? {},
        existing_scenes: scenesQuery.data ?? [],
        genre_profile: volumeQuery.data.genre_profile,
        genre_directive: volumeQuery.data.genre_directive,
        is_first_dream: (scenesQuery.data ?? []).length === 0,
      },
      temperature: 0.3,
      maxTokens: 1800,
    });
    const parsed = planOutputSchema.parse(result.value);
    const scenes = scenesQuery.data ?? [];
    const elementIds = Array.isArray(job.payload.elements)
      ? job.payload.elements
        .map((element) =>
          element && typeof element === "object" && "id" in element
            ? (element as { id?: unknown }).id
            : null
        )
        .filter((id): id is string => typeof id === "string")
      : [];
    const plan = enforcePlan(parsed, {
      lengthCap,
      cRatioMax: ADAPTATION_BUDGETS[adaptation].cRatioMax,
      validSceneIds: new Set(scenes.map((scene) => scene.id as string)),
      isFirstDream: scenes.length === 0,
      firstDreamElementIds: elementIds,
    });
    const payload = await mergeJobPayload(client, jobId, job.payload, {
      plan_complete: true,
      placement: plan.placement,
      attach_to_scene_id: plan.attach_to_scene_id,
      beats: plan.beats,
      target_length: plan.target_length,
      scene_title: plan.scene_title,
      scene_order_key: nextSceneOrderKey(scenes.map((scene) => scene.order_key as string)),
      is_first_dream: scenes.length === 0,
      adaptation,
      style: volumeQuery.data.style,
      narrative_voice: volumeQuery.data.narrative_voice,
    });
    await recordModelRun(client, {
      jobId,
      stage: "plan",
      promptVersion: PLAN_PROMPT_VERSION,
      result,
      validation: { schema: true, placement: plan.placement },
    });
    await enqueueStage(client, {
      userId: job.user_id,
      dreamId: job.dream_id,
      volumeId: job.volume_id,
      type: plan.placement === "standalone" ? "commit" : "write",
      payload,
      keySuffix: plan.placement === "standalone" ? undefined : "0",
    });
    logEvent("engine_plan_done", {
      job_id: jobId,
      dream_id: job.dream_id,
      stage: "plan",
      status: plan.placement,
      ms: result.latencyMs,
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

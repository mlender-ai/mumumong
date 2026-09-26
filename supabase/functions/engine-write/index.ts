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
import { WRITE_FALLBACK, WRITE_PROMPT_VERSION, WRITE_SYSTEM } from "../_shared/prompts/write.v1.ts";
import { writeJsonSchema, writeOutputSchema } from "../_shared/stage_contracts.ts";
import { serviceRoleClient } from "../_shared/supabase.ts";
import { authorizedWorker } from "../_shared/worker_auth.ts";
import { fallbackTarget, toSceneDraft } from "./write.ts";

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

    let lockedPassages: unknown[] = [];
    if (typeof job.payload.attach_to_scene_id === "string") {
      const lockedQuery = await client.from("passages")
        .select("text, order_key")
        .eq("scene_id", job.payload.attach_to_scene_id)
        .eq("locked", true);
      if (lockedQuery.error) throw new Error("locked_inputs");
      lockedPassages = lockedQuery.data ?? [];
    }

    const isFallback = job.payload.is_fallback === true;
    const writeAttempt = typeof job.payload.write_attempt === "number"
      ? job.payload.write_attempt
      : 0;
    const baseTarget = typeof job.payload.target_length === "number"
      ? job.payload.target_length
      : 700;
    const result = await callStructured<unknown>({
      model: QUALITY_MODEL,
      schemaName: "mumumong_write_v1",
      schema: writeJsonSchema,
      system: `${WRITE_SYSTEM}${isFallback ? `\n\n${WRITE_FALLBACK}` : ""}`,
      input: {
        settings: {
          adaptation: volumeQuery.data.adaptation,
          style: volumeQuery.data.style,
          narrative_voice: volumeQuery.data.narrative_voice,
          target_length: isFallback ? fallbackTarget(baseTarget) : baseTarget,
        },
        volume_bible: {
          entities: entitiesQuery.data ?? [],
          genre_profile: volumeQuery.data.genre_profile,
          genre_directive: volumeQuery.data.genre_directive,
        },
        narrative_memory: memoryQuery.data ?? {},
        recent_scenes: recentScenesQuery.data ?? [],
        today: {
          raw_text: dreamQuery.data.raw_text,
          recall_answers: dreamQuery.data.recall_answers,
          sensitive_flags: dreamQuery.data.sensitive_flags,
          elements: job.payload.elements ?? [],
          links: job.payload.links ?? [],
          beats: job.payload.beats ?? [],
          placement: job.payload.placement,
          scene_title: job.payload.scene_title,
        },
        locked_passages: lockedPassages,
        validation_feedback: job.payload.validation_feedback ?? [],
      },
      temperature: isFallback ? 0.2 : 0.8,
      maxTokens: 5000,
    });
    const parsed = writeOutputSchema.parse(result.value);
    const draft = toSceneDraft(parsed, {
      validEntityIds: new Set(
        (entitiesQuery.data ?? []).map((entity) => entity.id as string),
      ),
      isFirstScene: job.payload.is_first_dream === true,
    });
    const payload = await mergeJobPayload(client, jobId, job.payload, {
      write_complete: true,
      write_attempt: writeAttempt,
      is_fallback: isFallback,
      draft,
    });
    await recordModelRun(client, {
      jobId,
      stage: "write",
      promptVersion: WRITE_PROMPT_VERSION,
      result,
      validation: { schema: true, passages: parsed.passages.length },
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
      count: parsed.passages.length,
      attempt: writeAttempt,
      status: isFallback ? "fallback" : "draft",
      ms: result.latencyMs,
    });
    return json({ ok: true, passages: parsed.passages.length, attempt: writeAttempt });
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

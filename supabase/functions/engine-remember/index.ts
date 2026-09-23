import { loadJob } from "../_shared/jobs.ts";
import { callStructured, LIGHT_MODEL, ModelCallError } from "../_shared/llm.ts";
import { logEvent } from "../_shared/log.ts";
import { json, mergeJobPayload, recordModelRun, requestJobId } from "../_shared/pipeline.ts";
import { REMEMBER_PROMPT_VERSION, REMEMBER_SYSTEM } from "../_shared/prompts/remember.v1.ts";
import { rememberJsonSchema, rememberOutputSchema } from "../_shared/stage_contracts.ts";
import { serviceRoleClient } from "../_shared/supabase.ts";
import { authorizedWorker } from "../_shared/worker_auth.ts";
import { blendGenreProfile, normalizeMemory } from "./remember.ts";
import { ZodError } from "zod";

Deno.serve(async (request: Request): Promise<Response> => {
  if (!authorizedWorker(request, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"))) {
    return json({ error: "forbidden" }, 403);
  }
  const jobId = await requestJobId(request);
  if (!jobId) return json({ error: "job_id is required" }, 400);
  const client = serviceRoleClient();
  const job = await loadJob(client, jobId);
  if (!job) return json({ error: "job not found" }, 404);
  if (job.type !== "remember" || !job.dream_id) return json({ error: "wrong job stage" }, 400);
  const sceneId = typeof job.payload.scene_id === "string" ? job.payload.scene_id : null;
  if (!sceneId) return json({ error: "scene_id is required" }, 400);

  try {
    const sceneQuery = await client.from("scenes")
      .select("id, title, placement, open_image, passages(order_key,text,origin)")
      .eq("id", sceneId).single();
    const memoryQuery = await client.from("narrative_memory")
      .select("version, story_so_far, open_threads, world_rules, motifs")
      .eq("volume_id", job.volume_id).maybeSingle();
    const volumeQuery = await client.from("volumes")
      .select("genre_profile")
      .eq("id", job.volume_id).single();
    if (sceneQuery.error || memoryQuery.error || volumeQuery.error) {
      throw new Error("remember_inputs");
    }

    const result = await callStructured<unknown>({
      model: LIGHT_MODEL,
      schemaName: "mumumong_remember_v1",
      schema: rememberJsonSchema,
      system: REMEMBER_SYSTEM,
      input: {
        previous: memoryQuery.data ?? {},
        committed_scene: sceneQuery.data,
      },
      temperature: 0.2,
      maxTokens: 1800,
    });
    const memory = normalizeMemory(rememberOutputSchema.parse(result.value));
    const nextVersion = ((memoryQuery.data?.version as number | undefined) ?? 0) + 1;
    const { error: memoryError } = await client.from("narrative_memory").upsert({
      volume_id: job.volume_id,
      version: nextVersion,
      story_so_far: memory.story_so_far,
      open_threads: memory.open_threads,
      world_rules: memoryQuery.data?.world_rules ?? [],
      motifs: memory.motifs,
      updated_at: new Date().toISOString(),
    });
    if (memoryError) throw new Error("memory_write");

    const previousProfile = (volumeQuery.data.genre_profile ?? {}) as Record<string, number>;
    const { error: profileError } = await client.from("volumes").update({
      genre_profile: blendGenreProfile(previousProfile, memory.genre_scores),
    }).eq("id", job.volume_id);
    if (profileError) throw new Error("genre_write");

    await mergeJobPayload(client, jobId, job.payload, {
      remember_complete: true,
      memory_version: nextVersion,
    });
    await recordModelRun(client, {
      jobId,
      stage: "remember",
      promptVersion: REMEMBER_PROMPT_VERSION,
      result,
      validation: {
        story_chars: [...memory.story_so_far].length,
        threads: memory.open_threads.length,
      },
    });
    logEvent("engine_remember_done", {
      job_id: jobId,
      dream_id: job.dream_id,
      scene_id: sceneId,
      stage: "remember",
      count: memory.open_threads.length,
      ms: result.latencyMs,
    });
    return json({ ok: true, memory_version: nextVersion });
  } catch (error) {
    const known = new Set(["remember_inputs", "memory_write", "genre_write"]);
    const code = error instanceof ModelCallError
      ? error.code
      : error instanceof ZodError
      ? "schema_invalid"
      : error instanceof Error && known.has(error.message)
      ? error.message
      : "unknown";
    logEvent("engine_remember_failed", {
      job_id: jobId,
      stage: "remember",
      code,
    });
    return json({ error: "remember_failed", code }, 500);
  }
});

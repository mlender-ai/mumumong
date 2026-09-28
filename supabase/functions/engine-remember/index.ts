import { loadJob } from "../_shared/jobs.ts";
import { ModelCallError } from "../_shared/llm.ts";
import { createProductionLlm } from "../_shared/llm_adapter.ts";
import { runRemember } from "./core.ts";
import { logEvent } from "../_shared/log.ts";
import { json, mergeJobPayload, recordCoreRuns, requestJobId } from "../_shared/pipeline.ts";
import { serviceRoleClient } from "../_shared/supabase.ts";
import { authorizedWorker } from "../_shared/worker_auth.ts";
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

    const core = await runRemember({
      committedScene: sceneQuery.data,
      previous: memoryQuery.data,
      previousProfile: (volumeQuery.data.genre_profile ?? {}) as Record<string, number>,
    }, createProductionLlm());
    const { memory, nextVersion } = core;
    const { error: memoryError } = await client.from("narrative_memory").upsert({
      volume_id: job.volume_id,
      version: nextVersion,
      story_so_far: memory.story_so_far,
      open_threads: memory.open_threads,
      world_rules: core.worldRules,
      motifs: memory.motifs,
      updated_at: new Date().toISOString(),
    });
    if (memoryError) throw new Error("memory_write");

    const { error: profileError } = await client.from("volumes").update({
      genre_profile: core.genreProfile,
    }).eq("id", job.volume_id);
    if (profileError) throw new Error("genre_write");

    await mergeJobPayload(client, jobId, job.payload, core.nextPayloadPatch);
    await recordCoreRuns(client, {
      jobId,
      stage: "remember",
      modelRuns: core.modelRuns,
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
      ms: core.modelRuns[0].latencyMs,
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

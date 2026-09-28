import { loadJob } from "../_shared/jobs.ts";
import { createProductionLlm } from "../_shared/llm_adapter.ts";
import { runLink } from "./core.ts";
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
import type { LinkElement, LinkEntity } from "./link.ts";

Deno.serve(async (request: Request): Promise<Response> => {
  if (!authorizedWorker(request, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"))) {
    return json({ error: "forbidden" }, 403);
  }
  const jobId = await requestJobId(request);
  if (!jobId) return json({ error: "job_id is required" }, 400);
  const client = serviceRoleClient();
  const job = await loadJob(client, jobId);
  if (!job) return json({ error: "job not found" }, 404);
  if (job.type !== "link" || !job.dream_id) return json({ error: "wrong job stage" }, 400);

  try {
    const elementsQuery = await client.from("dream_elements")
      .select("id, type, label, detail")
      .eq("dream_id", job.dream_id);
    const entitiesQuery = await client.from("entities")
      .select("id, type, role_name, aliases, description")
      .eq("volume_id", job.volume_id);
    if (elementsQuery.error || entitiesQuery.error) throw new Error("link_inputs");
    const elements = (elementsQuery.data ?? []) as LinkElement[];
    const entities = (entitiesQuery.data ?? []) as LinkEntity[];
    const core = await runLink({
      elements,
      entities,
      dreamId: job.dream_id,
      volumeId: job.volume_id,
    }, createProductionLlm());
    const { decisions, rows } = core;

    const { error: clearError } = await client.from("link_decisions").delete()
      .eq("dream_id", job.dream_id)
      .eq("kind", "entity_merge")
      .in("status", ["auto", "pending"]);
    if (clearError) throw new Error("link_clear");

    if (rows.length > 0) {
      const { error } = await client.from("link_decisions").insert(rows);
      if (error) throw new Error("link_write");
    }

    const payload = await mergeJobPayload(client, jobId, job.payload, core.nextPayloadPatch);
    await recordCoreRuns(client, {
      jobId,
      stage: "link",
      modelRuns: core.modelRuns,
      validation: {
        schema: true,
        auto: decisions.auto.length,
        pending: decisions.pending ? 1 : 0,
      },
    });
    await enqueueStage(client, {
      userId: job.user_id,
      dreamId: job.dream_id,
      volumeId: job.volume_id,
      type: "plan",
      payload,
    });
    logEvent("engine_link_done", {
      job_id: jobId,
      dream_id: job.dream_id,
      stage: "link",
      count: (core.nextPayloadPatch.links as unknown[]).length,
    });
    return json({ ok: true, auto: decisions.auto.length, pending: decisions.pending ? 1 : 0 });
  } catch (error) {
    logEvent("engine_link_failed", {
      job_id: jobId,
      stage: "link",
      code: error instanceof Error ? error.message.slice(0, 64) : "unknown",
    });
    return json({ error: "link_failed" }, 500);
  }
});

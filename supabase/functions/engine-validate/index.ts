// WO-E5 · Validate — Edge Function entrypoint.
//
// Loads the facts the rules need (today's elements, the volume registry, the
// locked passages of the attach target), runs the deterministic checks, and
// records a text-free audit row in `generation_runs`.

import { logEvent } from "../_shared/log.ts";
import { serviceRoleClient } from "../_shared/supabase.ts";
import {
  adaptationSchema,
  claritySchema,
  type DreamElement,
  type RegistryEntity,
} from "../_shared/contract.ts";
import { loadJob } from "../_shared/jobs.ts";
import { enqueueStage, mergeJobPayload } from "../_shared/pipeline.ts";
import { runValidate, VALIDATE_PROMPT_VERSION } from "./core.ts";
import { engineVersion } from "../_shared/model_config.ts";
import type { LockedPassage } from "../_shared/stage_context.ts";
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
  if (job.type !== "validate") return json({ error: "wrong job stage" }, 400);
  if (!job.dream_id) return json({ error: "validate requires a dream" }, 400);

  // Section C: a stage reads its input from jobs.payload.
  const payload = job.payload;

  const clarity = claritySchema.safeParse(payload.clarity);
  if (!clarity.success) return json({ error: "payload clarity is invalid" }, 400);

  const adaptation = adaptationSchema.safeParse(payload.adaptation);
  if (!adaptation.success) return json({ error: "payload adaptation is invalid" }, 400);

  const started = Date.now();

  const elementsQuery = await client
    .from("dream_elements")
    .select("id, label, salience")
    .eq("dream_id", job.dream_id);
  if (elementsQuery.error) {
    logEvent("engine_validate_failed", { job_id: jobId, stage: "validate", code: "elements" });
    return json({ error: "elements unavailable" }, 500);
  }

  const registryQuery = await client
    .from("entities")
    .select("id, role_name, aliases")
    .eq("volume_id", job.volume_id);
  if (registryQuery.error) {
    logEvent("engine_validate_failed", { job_id: jobId, stage: "validate", code: "registry" });
    return json({ error: "registry unavailable" }, 500);
  }

  // Only a `fragment_attach` plan can collide with existing locked passages.
  const attachSceneId = typeof payload.attach_to_scene_id === "string"
    ? payload.attach_to_scene_id
    : null;
  let lockedPassages: LockedPassage[] = [];
  if (attachSceneId) {
    const lockedQuery = await client
      .from("passages")
      .select("text")
      .eq("scene_id", attachSceneId)
      .eq("locked", true);
    if (lockedQuery.error) {
      logEvent("engine_validate_failed", { job_id: jobId, stage: "validate", code: "locked" });
      return json({ error: "locked passages unavailable" }, 500);
    }
    lockedPassages = lockedQuery.data ?? [];
  }

  const core = await runValidate({
    payload,
    elements: (elementsQuery.data ?? []) as DreamElement[],
    registry: (registryQuery.data ?? []) as RegistryEntity[],
    lockedPassages,
  });
  const { outcome, audit, isFallback } = core;

  // `validation` holds codes and counts only: never a violation message, which
  // quotes elements and entities for the retry prompt.
  const { error: runError } = await client.from("generation_runs").insert({
    job_id: jobId,
    stage: "validate",
    model: "rules",
    validation: audit,
    c_ratio: outcome.cRatio,
    latency_ms: Date.now() - started,
    prompt_version: VALIDATE_PROMPT_VERSION,
    is_fallback: isFallback,
    engine_version: engineVersion(),
  });
  if (runError) {
    // A missing audit row must not fail a validation that already ran.
    logEvent("engine_validate_audit_failed", { job_id: jobId, stage: "validate" });
  }

  let next: string | null = null;
  const terminal = core.next.terminal;
  if (core.next.stage === "commit") {
    const nextPayload = await mergeJobPayload(client, jobId, payload, core.nextPayloadPatch);
    next = await enqueueStage(client, {
      userId: job.user_id,
      dreamId: job.dream_id,
      volumeId: job.volume_id,
      type: "commit",
      payload: nextPayload,
    });
  } else if (terminal) {
    await client.from("dreams").update({ status: "failed" }).eq("id", job.dream_id);
  } else {
    next = await enqueueStage(client, {
      userId: job.user_id,
      dreamId: job.dream_id,
      volumeId: job.volume_id,
      type: "write",
      payload: { ...payload, ...core.nextPayloadPatch },
      keySuffix: String(core.next.writeAttempt),
    });
  }

  logEvent("engine_validate_done", {
    job_id: jobId,
    dream_id: job.dream_id,
    stage: "validate",
    status: outcome.action,
    count: outcome.violations.length,
    ms: Date.now() - started,
  });

  return json({ ...outcome, audit, next_job_id: next, terminal });
});

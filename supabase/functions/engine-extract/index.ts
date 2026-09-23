import { logEvent } from "../_shared/log.ts";
import { callStructured, LIGHT_MODEL } from "../_shared/llm.ts";
import { loadJob } from "../_shared/jobs.ts";
import {
  enqueueStage,
  json,
  mergeJobPayload,
  recordModelRun,
  requestJobId,
} from "../_shared/pipeline.ts";
import { EXTRACT_PROMPT_VERSION, EXTRACT_SYSTEM } from "../_shared/prompts/extract.v1.ts";
import { extractJsonSchema, extractOutputSchema } from "../_shared/stage_contracts.ts";
import { serviceRoleClient } from "../_shared/supabase.ts";
import { deterministicUuid } from "../_shared/uuid.ts";
import { authorizedWorker } from "../_shared/worker_auth.ts";
import { normalizeExtract, postgresSpan } from "./extract.ts";

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
    const result = await callStructured<unknown>({
      model: LIGHT_MODEL,
      schemaName: "mumumong_extract_v1",
      schema: extractJsonSchema,
      system: EXTRACT_SYSTEM,
      input: { raw_text: dream.raw_text, recall_answers: dream.recall_answers ?? {} },
      temperature: 0,
      maxTokens: 1600,
    });
    const parsed = extractOutputSchema.parse(result.value);
    const normalized = normalizeExtract(dream.raw_text as string, parsed);
    const rows = await Promise.all(normalized.elements.map(async (element, index) => ({
      id: await deterministicUuid(
        `element:${job.dream_id}:${index}:${element.source}:${element.type}:${element.label}`,
      ),
      dream_id: job.dream_id,
      type: element.type,
      label: element.label,
      detail: element.detail,
      salience: element.salience,
      source: element.source,
      span: postgresSpan(element.span),
    })));

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

    const elements = rows.map((row) => ({
      id: row.id,
      type: row.type,
      label: row.label,
      detail: row.detail,
      salience: row.salience,
      source: row.source,
      span: row.span,
    }));
    const payload = await mergeJobPayload(client, jobId, job.payload, {
      extract_complete: true,
      elements,
      clarity: normalized.clarity,
      empty_slots: normalized.empty_slots,
      sensitive_flags: normalized.sensitive_flags,
    });
    await recordModelRun(client, {
      jobId,
      stage: "extract",
      promptVersion: EXTRACT_PROMPT_VERSION,
      result,
      validation: { schema: true, elements: elements.length },
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
      count: elements.length,
      ms: result.latencyMs,
    });
    return json({ ok: true, count: elements.length, clarity: normalized.clarity });
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

import { loadJob } from "../_shared/jobs.ts";
import { callStructured, LIGHT_MODEL, type StructuredResult } from "../_shared/llm.ts";
import { logEvent } from "../_shared/log.ts";
import {
  enqueueStage,
  json,
  mergeJobPayload,
  recordModelRun,
  requestJobId,
} from "../_shared/pipeline.ts";
import { LINK_PROMPT_VERSION, LINK_SYSTEM } from "../_shared/prompts/link.v1.ts";
import {
  linkJsonSchema,
  type LinkModelOutput,
  linkModelOutputSchema,
} from "../_shared/stage_contracts.ts";
import { serviceRoleClient } from "../_shared/supabase.ts";
import { authorizedWorker } from "../_shared/worker_auth.ts";
import { chooseDecisions, type LinkElement, type LinkEntity, ruleMatch } from "./link.ts";

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
    const rules = ruleMatch(elements, entities);

    let modelResult: StructuredResult<LinkModelOutput> | null = null;
    if (rules.ambiguous.length > 0) {
      modelResult = await callStructured<LinkModelOutput>({
        model: LIGHT_MODEL,
        schemaName: "mumumong_link_v1",
        schema: linkJsonSchema,
        system: LINK_SYSTEM,
        input: { ambiguous: rules.ambiguous },
        temperature: 0,
        maxTokens: 1000,
      });
      linkModelOutputSchema.parse(modelResult.value);
    }
    const decisions = chooseDecisions([
      ...rules.accepted,
      ...(modelResult?.value.matches ?? []),
    ]);

    const { error: clearError } = await client.from("link_decisions").delete()
      .eq("dream_id", job.dream_id)
      .eq("kind", "entity_merge")
      .in("status", ["auto", "pending"]);
    if (clearError) throw new Error("link_clear");

    const rows: Record<string, unknown>[] = decisions.auto.map((match) => ({
      volume_id: job.volume_id,
      dream_id: job.dream_id,
      kind: "entity_merge",
      status: "auto",
      payload: match,
      decided_at: new Date().toISOString(),
    }));
    if (decisions.pending) {
      const pendingElement = elements.find((item) => item.id === decisions.pending!.element_id);
      const pendingEntity = entities.find((item) => item.id === decisions.pending!.entity_id);
      rows.push({
        volume_id: job.volume_id,
        dream_id: job.dream_id,
        kind: "entity_merge",
        status: "pending",
        payload: {
          ...decisions.pending,
          question: `오늘 꿈의 '${pendingElement?.label ?? "요소"}', 원고의 '${
            pendingEntity?.role_name ?? "대상"
          }'과 같은 대상일까요?`,
          element_label: pendingElement?.label,
          entity_role_name: pendingEntity?.role_name,
        },
        decided_at: null,
      });
    }
    if (rows.length > 0) {
      const { error } = await client.from("link_decisions").insert(rows);
      if (error) throw new Error("link_write");
    }

    const links = [
      ...decisions.auto.map((match) => ({ ...match, status: "auto" })),
      ...(decisions.pending ? [{ ...decisions.pending, status: "pending" }] : []),
    ];
    const payload = await mergeJobPayload(client, jobId, job.payload, {
      link_complete: true,
      links,
    });
    if (modelResult) {
      await recordModelRun(client, {
        jobId,
        stage: "link",
        promptVersion: LINK_PROMPT_VERSION,
        result: modelResult,
        validation: {
          schema: true,
          auto: decisions.auto.length,
          pending: decisions.pending ? 1 : 0,
        },
      });
    }
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
      count: links.length,
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

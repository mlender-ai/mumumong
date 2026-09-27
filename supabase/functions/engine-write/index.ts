import { loadJob } from "../_shared/jobs.ts";
import { callStructured, LIGHT_MODEL, QUALITY_MODEL } from "../_shared/llm.ts";
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
import { fallbackTarget, FIRST_SCENE_OPENING_CONTRACT, toSceneDraft } from "./write.ts";
import {
  aggregateModelResults,
  expandedOpening,
  needsOpeningExpansion,
  OPENING_EXPANSION_SCHEMA,
  OPENING_EXPANSION_SYSTEM,
  prepareOpeningProvenance,
} from "./opening_expansion.ts";
import { OPENING_POLISH_SYSTEM, shouldUsePolishedOpening } from "./opening_polish.ts";

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
    const feedbackCodes = Array.isArray(job.payload.validation_feedback)
      ? job.payload.validation_feedback.flatMap((feedback) =>
        feedback && typeof feedback === "object" && "code" in feedback &&
          typeof feedback.code === "string"
          ? [feedback.code]
          : []
      )
      : [];
    const retryDirective = feedbackCodes.length === 0
      ? ""
      : `\n\n이번 출력은 재생성이다. 이전 초안의 ${
        feedbackCodes.join(
          ", ",
        )
      } 위반을 반드시 수정한다. target_length=${baseTarget}이며 첫 장면이면 최소 ${
        Math.max(350, Math.floor(baseTarget * 0.7))
      }자를 쓴다.`;
    const result = await callStructured<unknown>({
      model: QUALITY_MODEL,
      schemaName: "mumumong_write_v1",
      schema: writeJsonSchema,
      system: `${WRITE_SYSTEM}${retryDirective}${isFallback ? `\n\n${WRITE_FALLBACK}` : ""}`,
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
          is_first_scene: job.payload.is_first_dream === true,
          protagonist_contract: {
            protagonist: "the user who recorded the dream",
            relationship_terms_are_third_parties: true,
            preserve_agent_recipient_goal_cause_and_sequence: true,
          },
          opening_contract: job.payload.is_first_dream === true
            ? FIRST_SCENE_OPENING_CONTRACT
            : null,
        },
        locked_passages: lockedPassages,
        validation_feedback: job.payload.validation_feedback ?? [],
      },
      temperature: isFallback ? 0.2 : writeAttempt === 0 ? 0.75 : 0.45,
      maxTokens: job.payload.is_first_dream === true ? 8000 : 5000,
    });
    let parsed = writeOutputSchema.parse(result.value);
    let measuredResult = result;
    const openingElements =
      job.payload.is_first_dream === true && Array.isArray(job.payload.elements)
        ? job.payload.elements.flatMap((element) => {
          if (!element || typeof element !== "object") return [];
          const candidate = element as Record<string, unknown>;
          return typeof candidate.id === "string" && typeof candidate.label === "string" &&
              typeof candidate.salience === "string"
            ? [{ id: candidate.id, label: candidate.label, salience: candidate.salience }]
            : [];
        })
        : [];
    const provenancePlan = prepareOpeningProvenance(parsed, openingElements);
    const hasMissingHighElements = provenancePlan.addedIds.some((ids) => ids.length > 0);
    if (
      !isFallback &&
      (needsOpeningExpansion(parsed, job.payload.is_first_dream === true, baseTarget) ||
        hasMissingHighElements)
    ) {
      parsed = provenancePlan.output;
      const expansionCalls = parsed.passages.map((passage, index) =>
        callStructured<unknown>({
          model: LIGHT_MODEL,
          schemaName: "mumumong_opening_passage_v1",
          schema: OPENING_EXPANSION_SCHEMA,
          system: OPENING_EXPANSION_SYSTEM,
          input: {
            origin: passage.origin,
            text: passage.text,
            position: index + 1,
            passage_count: parsed.passages.length,
            previous_passage: index > 0 ? parsed.passages[index - 1].text : null,
            next_passage: index + 1 < parsed.passages.length
              ? parsed.passages[index + 1].text
              : null,
            raw_text: dreamQuery.data.raw_text,
            source_elements: job.payload.elements ?? [],
            narrative_voice: volumeQuery.data.narrative_voice,
            style: volumeQuery.data.style,
            required_labels: provenancePlan.requiredLabels[index],
          },
          temperature: 0.45,
          maxTokens: 900,
        })
      );
      const settledExpansions = await Promise.allSettled(expansionCalls);
      const expansions = [];
      const expandedTexts = parsed.passages.map((passage) => passage.text);
      for (let index = 0; index < settledExpansions.length; index += 1) {
        const settled = settledExpansions[index];
        if (settled.status !== "fulfilled") continue;
        const expanded = settled.value;
        const expandedValue = expanded.value as { text?: unknown };
        if (typeof expandedValue.text !== "string" || expandedValue.text.trim().length === 0) {
          continue;
        }
        expansions.push(expanded);
        expandedTexts[index] = expandedValue.text;
      }
      parsed = expandedOpening(provenancePlan, expandedTexts);
      measuredResult = aggregateModelResults(result, expansions);
    }
    if (!isFallback && job.payload.is_first_dream === true) {
      try {
        const polished = await callStructured<unknown>({
          model: QUALITY_MODEL,
          schemaName: "mumumong_opening_polish_v1",
          schema: writeJsonSchema,
          system: OPENING_POLISH_SYSTEM,
          input: {
            raw_text: dreamQuery.data.raw_text,
            source_elements: job.payload.elements ?? [],
            expanded_draft: parsed,
            planned_title: job.payload.scene_title,
            target_length: baseTarget,
            narrative_voice: volumeQuery.data.narrative_voice,
            style: volumeQuery.data.style,
            adaptation: volumeQuery.data.adaptation,
            protagonist_contract: {
              protagonist: "the user who recorded the dream",
              relationship_terms_are_third_parties: true,
              preserve_agent_recipient_goal_cause_and_sequence: true,
            },
          },
          temperature: 0.35,
          maxTokens: 8000,
        });
        measuredResult = aggregateModelResults(measuredResult, [polished]);
        const candidate = writeOutputSchema.safeParse(polished.value);
        const candidateMissingHigh = candidate.success
          ? prepareOpeningProvenance(candidate.data, openingElements).addedIds.some((ids) =>
            ids.length > 0
          )
          : true;
        if (
          candidate.success && !candidateMissingHigh &&
          shouldUsePolishedOpening(parsed, candidate.data, baseTarget)
        ) {
          parsed = candidate.data;
        }
      } catch {
        // Expansion output is still validated normally when optional polishing fails.
      }
    }
    const draft = toSceneDraft(parsed, {
      validEntityIds: new Set(
        (entitiesQuery.data ?? []).map((entity) => entity.id as string),
      ),
      isFirstScene: job.payload.is_first_dream === true,
      plannedTitle: typeof job.payload.scene_title === "string"
        ? job.payload.scene_title
        : undefined,
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
      result: measuredResult,
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

import { type LlmPort, type ModelRun, modelRun } from "../_shared/llm_port.ts";
import type {
  DreamContext,
  EntityRow,
  LockedPassage,
  NarrativeMemory,
  RecentScene,
  VolumeContext,
} from "../_shared/stage_context.ts";
import { fallbackTarget } from "../_shared/scene_loop_policy.ts";
import { WRITE_FALLBACK, WRITE_PROMPT_VERSION, WRITE_SYSTEM } from "../_shared/prompts/write.v1.ts";
import { writeJsonSchema, writeOutputSchema } from "../_shared/stage_contracts.ts";
import { FIRST_SCENE_OPENING_CONTRACT, toSceneDraft } from "./write.ts";
import {
  aggregateModelResults,
  expandedOpening,
  needsOpeningExpansion,
  OPENING_EXPANSION_SCHEMA,
  OPENING_EXPANSION_SYSTEM,
  prepareOpeningProvenance,
} from "./opening_expansion.ts";
import { OPENING_POLISH_SYSTEM, shouldUsePolishedOpening } from "./opening_polish.ts";
export type WriteJobPayload = Record<string, unknown>;
export interface WriteCoreInput {
  dream: DreamContext;
  volume: VolumeContext;
  memory: NarrativeMemory | null;
  entities: EntityRow[];
  recentScenes: RecentScene[];
  lockedPassages: LockedPassage[];
  payload: WriteJobPayload;
  writeAttempt: number;
  isFallback: boolean;
}
export interface WriteCoreResult {
  sceneDraft: Record<string, unknown>;
  modelRuns: ModelRun[];
  nextPayloadPatch: Record<string, unknown>;
  passageCount: number;
  primaryLatencyMs: number;
  auditRun: ModelRun;
}
export async function runWrite(
  {
    dream,
    volume,
    memory,
    entities,
    recentScenes,
    lockedPassages,
    payload,
    writeAttempt,
    isFallback,
  }: WriteCoreInput,
  llm: LlmPort,
): Promise<WriteCoreResult> {
  const baseTarget = typeof payload.target_length === "number" ? payload.target_length : 700;
  const feedbackCodes = Array.isArray(payload.validation_feedback)
    ? payload.validation_feedback.flatMap((feedback) =>
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
  const result = await llm.structured<unknown>({
    role: "write",
    schemaName: "mumumong_write_v1",
    schema: writeJsonSchema,
    system: `${WRITE_SYSTEM}${retryDirective}${isFallback ? `\n\n${WRITE_FALLBACK}` : ""}`,
    input: {
      settings: {
        adaptation: volume.adaptation,
        style: volume.style,
        narrative_voice: volume.narrative_voice,
        target_length: isFallback ? fallbackTarget(baseTarget) : baseTarget,
      },
      volume_bible: {
        entities: entities ?? [],
        genre_profile: volume.genre_profile,
        genre_directive: volume.genre_directive,
      },
      narrative_memory: memory ?? {},
      recent_scenes: recentScenes ?? [],
      today: {
        raw_text: dream.raw_text,
        recall_answers: dream.recall_answers,
        sensitive_flags: dream.sensitive_flags,
        elements: payload.elements ?? [],
        links: payload.links ?? [],
        beats: payload.beats ?? [],
        placement: payload.placement,
        scene_title: payload.scene_title,
        is_first_scene: payload.is_first_dream === true,
        protagonist_contract: {
          protagonist: "the user who recorded the dream",
          relationship_terms_are_third_parties: true,
          preserve_agent_recipient_goal_cause_and_sequence: true,
        },
        opening_contract: payload.is_first_dream === true ? FIRST_SCENE_OPENING_CONTRACT : null,
      },
      locked_passages: lockedPassages,
      validation_feedback: payload.validation_feedback ?? [],
    },
    temperature: isFallback ? 0.2 : writeAttempt === 0 ? 0.75 : 0.45,
    maxTokens: payload.is_first_dream === true ? 8000 : 5000,
  });
  let parsed = writeOutputSchema.parse(result.value);
  const modelRuns: ModelRun[] = [modelRun("write", WRITE_PROMPT_VERSION, result)];
  let measuredResult = result;
  const openingElements = payload.is_first_dream === true && Array.isArray(payload.elements)
    ? payload.elements.flatMap((element) => {
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
    (needsOpeningExpansion(parsed, payload.is_first_dream === true, baseTarget) ||
      hasMissingHighElements)
  ) {
    parsed = provenancePlan.output;
    const expansionCalls = parsed.passages.map((passage, index) =>
      llm.structured<unknown>({
        role: "write_aux",
        schemaName: "mumumong_opening_passage_v1",
        schema: OPENING_EXPANSION_SCHEMA,
        system: OPENING_EXPANSION_SYSTEM,
        input: {
          origin: passage.origin,
          text: passage.text,
          position: index + 1,
          passage_count: parsed.passages.length,
          previous_passage: index > 0 ? parsed.passages[index - 1].text : null,
          next_passage: index + 1 < parsed.passages.length ? parsed.passages[index + 1].text : null,
          raw_text: dream.raw_text,
          source_elements: payload.elements ?? [],
          narrative_voice: volume.narrative_voice,
          style: volume.style,
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
    modelRuns.push(
      ...expansions.map((expanded) => modelRun("write_aux", WRITE_PROMPT_VERSION, expanded)),
    );
    measuredResult = aggregateModelResults(result, expansions);
  }
  if (!isFallback && payload.is_first_dream === true) {
    try {
      const polished = await llm.structured<unknown>({
        role: "polish",
        schemaName: "mumumong_opening_polish_v1",
        schema: writeJsonSchema,
        system: OPENING_POLISH_SYSTEM,
        input: {
          raw_text: dream.raw_text,
          source_elements: payload.elements ?? [],
          expanded_draft: parsed,
          planned_title: payload.scene_title,
          target_length: baseTarget,
          narrative_voice: volume.narrative_voice,
          style: volume.style,
          adaptation: volume.adaptation,
          protagonist_contract: {
            protagonist: "the user who recorded the dream",
            relationship_terms_are_third_parties: true,
            preserve_agent_recipient_goal_cause_and_sequence: true,
          },
        },
        temperature: 0.35,
        maxTokens: 8000,
      });
      modelRuns.push(modelRun("polish", WRITE_PROMPT_VERSION, polished));
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
      (entities ?? []).map((entity) => entity.id as string),
    ),
    isFirstScene: payload.is_first_dream === true,
    plannedTitle: typeof payload.scene_title === "string" ? payload.scene_title : undefined,
  });

  return {
    sceneDraft: draft,
    modelRuns,
    passageCount: parsed.passages.length,
    primaryLatencyMs: result.latencyMs,
    // Preserve v10's existing single aggregated database audit; the offline runner
    // also receives per-call metadata without changing the operational baseline.
    auditRun: modelRun("write", WRITE_PROMPT_VERSION, measuredResult),
    nextPayloadPatch: {
      write_complete: true,
      write_attempt: writeAttempt,
      is_fallback: isFallback,
      draft,
    },
  };
}

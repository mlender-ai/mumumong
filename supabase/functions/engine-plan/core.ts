import {
  ADAPTATION_BUDGETS,
  adaptationSchema,
  claritySchema,
  lengthCapFor,
} from "../_shared/contract.ts";
import { modelRun, type StructuredLlmPort } from "../_shared/llm_port.ts";
import type {
  DreamContext,
  NarrativeMemory,
  RecentScene,
  VolumeContext,
} from "../_shared/stage_context.ts";
import { PLAN_PROMPT_VERSION, PLAN_SYSTEM } from "../_shared/prompts/plan.v1.ts";
import { planJsonSchema, planOutputSchema } from "../_shared/stage_contracts.ts";
import { enforcePlan, nextSceneOrderKey } from "./plan.ts";
export interface PlanCoreInput {
  dream: DreamContext;
  volume: VolumeContext;
  memory: NarrativeMemory | null;
  existingScenes: RecentScene[];
  payload: Record<string, unknown>;
}
export async function runPlan(
  { dream, volume, memory, existingScenes, payload }: PlanCoreInput,
  llm: StructuredLlmPort,
) {
  const clarity = claritySchema.parse(payload.clarity);
  const adaptation = adaptationSchema.parse(volume.adaptation);
  const lengthCap = lengthCapFor(clarity, adaptation);
  const result = await llm.structured<unknown>({
    role: "plan",
    schemaName: "mumumong_plan_v1",
    schema: planJsonSchema,
    system: PLAN_SYSTEM,
    input: {
      raw_text: dream.raw_text,
      recall_answers: dream.recall_answers,
      elements: payload.elements ?? [],
      links: payload.links ?? [],
      clarity,
      adaptation,
      adaptation_budget: ADAPTATION_BUDGETS[adaptation],
      length_cap: lengthCap,
      narrative_memory: memory ?? {},
      existing_scenes: existingScenes ?? [],
      genre_profile: volume.genre_profile,
      genre_directive: volume.genre_directive,
      is_first_dream: (existingScenes ?? []).length === 0,
      protagonist_contract: {
        protagonist: "the user who recorded the dream",
        preserve_agent_recipient_goal_and_sequence: true,
      },
    },
    temperature: 0.3,
    maxTokens: 1800,
  });
  const parsed = planOutputSchema.parse(result.value);
  const scenes = existingScenes ?? [];
  const elementIds = Array.isArray(payload.elements)
    ? payload.elements
      .map((element) =>
        element && typeof element === "object" && "id" in element
          ? (element as { id?: unknown }).id
          : null
      )
      .filter((id): id is string => typeof id === "string")
    : [];
  const firstDreamElements = Array.isArray(payload.elements)
    ? payload.elements.flatMap((element) => {
      if (!element || typeof element !== "object") return [];
      const candidate = element as Record<string, unknown>;
      if (typeof candidate.label !== "string") return [];
      return [{
        label: candidate.label,
        type: typeof candidate.type === "string" ? candidate.type : undefined,
        salience: typeof candidate.salience === "string" ? candidate.salience : undefined,
      }];
    })
    : [];
  const plan = enforcePlan(parsed, {
    lengthCap,
    cRatioMax: ADAPTATION_BUDGETS[adaptation].cRatioMax,
    validSceneIds: new Set(scenes.map((scene) => scene.id as string)),
    isFirstDream: scenes.length === 0,
    firstDreamElementIds: elementIds,
    firstDreamElements,
    rawText: dream.raw_text,
  });

  return {
    plan,
    modelRuns: [modelRun("plan", PLAN_PROMPT_VERSION, result)],
    nextStage: plan.placement === "standalone" ? "commit" : "write",
    nextPayloadPatch: {
      plan_complete: true,
      placement: plan.placement,
      attach_to_scene_id: plan.attach_to_scene_id,
      beats: plan.beats,
      target_length: plan.target_length,
      scene_title: plan.scene_title,
      scene_order_key: nextSceneOrderKey(scenes.map((scene) => scene.order_key as string)),
      is_first_dream: scenes.length === 0,
      adaptation,
      style: volume.style,
      narrative_voice: volume.narrative_voice,
    },
  };
}

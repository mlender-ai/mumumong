import { sceneDraftSchema } from "../../supabase/functions/_shared/contract.ts";
import { estimatedCostKrw } from "../../supabase/functions/_shared/llm.ts";
import type {
  LlmPort,
  ModelRun,
  StructuredCall,
} from "../../supabase/functions/_shared/llm_port.ts";
import { writeState } from "../../supabase/functions/_shared/scene_loop_policy.ts";
import type {
  EntityRow,
  NarrativeMemory,
  RecentScene,
  VolumeContext,
} from "../../supabase/functions/_shared/stage_context.ts";
import { deterministicUuid } from "../../supabase/functions/_shared/uuid.ts";
import { runExtract } from "../../supabase/functions/engine-extract/core.ts";
import { runLink } from "../../supabase/functions/engine-link/core.ts";
import { runPlan } from "../../supabase/functions/engine-plan/core.ts";
import { nextSceneOrderKey } from "../../supabase/functions/engine-plan/plan.ts";
import { runWrite } from "../../supabase/functions/engine-write/core.ts";
import { runValidate } from "../../supabase/functions/engine-validate/core.ts";
import { runRemember } from "../../supabase/functions/engine-remember/core.ts";
import { buildCommitPayload } from "../../supabase/functions/engine-commit/commit.ts";
import {
  type CorpusCase,
  EvalError,
  failureCode,
  PROMPT_VERSIONS,
  type RunConfig,
  settingsSchema,
} from "./config.ts";

export interface VolumeState {
  scenes: RecentScene[];
  entities: EntityRow[];
  memory: NarrativeMemory | null;
  volume: VolumeContext;
}
export interface StageOutput {
  stage: string;
  output: unknown;
}
export interface DreamResult {
  dream_id: string;
  expected_clarity: string | null;
  status: "success" | "failed";
  failed_stage?: string;
  code?: string;
  stages: StageOutput[];
  scene: RecentScene | null;
  attempts: number;
  fallback: boolean;
  model_calls: (ModelRun & { status: "success" | "failed" })[];
  cost_krw: number;
  cost_complete: boolean;
  latency_ms: number;
}
export interface CaseResult {
  id: string;
  kind: CorpusCase["kind"];
  status: "success" | "failed";
  failed_stage?: string;
  code?: string;
  dreams: DreamResult[];
  scenes: RecentScene[];
  fallback: boolean;
  cost_krw: number;
  latency_ms: number;
}

// Record successful optional calls too, even when a later core/parse fails.
// Failed transport usage is unknowable: report a lower bound, never claim a free failure.
function measuredLlm(llm: LlmPort, calls: DreamResult["model_calls"]): LlmPort {
  return {
    async structured<T>(request: StructuredCall) {
      const start = performance.now();
      try {
        const result = await llm.structured<T>(request);
        calls.push({
          role: request.role,
          model: result.model,
          tokensIn: result.tokensIn,
          tokensOut: result.tokensOut,
          latencyMs: result.latencyMs,
          promptVersion: request.role === "judge"
            ? "not_implemented"
            : PROMPT_VERSIONS[request.role],
          status: "success",
        });
        return result;
      } catch {
        calls.push({
          role: request.role,
          model: "unknown",
          tokensIn: 0,
          tokensOut: 0,
          latencyMs: performance.now() - start,
          promptVersion: request.role === "judge"
            ? "not_implemented"
            : PROMPT_VERSIONS[request.role],
          status: "failed",
        });
        throw new EvalError("MODEL_CALL_FAILED");
      }
    },
  };
}

export async function evaluateCase(
  record: CorpusCase,
  config: RunConfig,
  llm: LlmPort,
): Promise<CaseResult> {
  const start = performance.now();
  const state: VolumeState = {
    scenes: [],
    entities: [],
    memory: null,
    volume: { ...config.settings, genre_profile: {}, genre_directive: null },
  };
  const dreams: DreamResult[] = [];
  const finish = (): CaseResult => {
    const failed = dreams.find((dream) => dream.status === "failed");
    return {
      id: record.id,
      kind: record.kind,
      status: failed ? "failed" : "success",
      ...(failed ? { failed_stage: failed.failed_stage, code: failed.code } : {}),
      dreams,
      scenes: dreams.flatMap((dream) => dream.scene ? [dream.scene] : []),
      fallback: dreams.some((dream) => dream.fallback),
      cost_krw: dreams.reduce((sum, dream) => sum + dream.cost_krw, 0),
      latency_ms: performance.now() - start,
    };
  };
  try {
    state.volume = {
      ...state.volume,
      ...settingsSchema.parse({ ...config.settings, ...record.settings }),
    };
  } catch {
    return { ...finish(), status: "failed", failed_stage: "settings", code: "SETTINGS_INVALID" };
  }
  const inputs = record.kind === "single" ? [record] : record.dreams;
  const volumeId = await deterministicUuid(`eval:volume:${record.id}`);
  for (const [index, input] of inputs.entries()) {
    const dreamId = await deterministicUuid(`eval:dream:${record.id}:${index}`);
    const started = performance.now();
    const result: DreamResult = {
      dream_id: dreamId,
      expected_clarity: input.expected_clarity,
      status: "failed",
      stages: [],
      scene: null,
      attempts: 0,
      fallback: false,
      model_calls: [],
      cost_krw: 0,
      cost_complete: true,
      latency_ms: 0,
    };
    const port = measuredLlm(llm, result.model_calls);
    let stage = "extract";
    try {
      const dream = {
        raw_text: input.raw_text,
        recall_answers: input.recall_answers ?? null,
        sensitive_flags: [] as string[],
      };
      let payload: Record<string, unknown> = {};
      const extract = await runExtract({ dreamId, dream }, port);
      result.stages.push({ stage, output: extract });
      payload = { ...payload, ...extract.nextPayloadPatch };
      dream.sensitive_flags = extract.normalized.sensitive_flags;
      stage = "link";
      const link = await runLink({
        dreamId,
        volumeId,
        elements: extract.rows.map(({ id, type, label, detail }) => ({ id, type, label, detail })),
        entities: state.entities.map(({ id, type, role_name, aliases, description }) => ({
          id,
          type,
          role_name,
          aliases,
          description,
        })),
      }, port);
      // IDs demonstrate continuity without serializing the input dream again.
      result.stages.push({
        stage,
        output: { ...link, input_entity_ids: state.entities.map((entity) => entity.id) },
      });
      payload = { ...payload, ...link.nextPayloadPatch };
      stage = "plan";
      const plan = await runPlan({
        dream,
        volume: state.volume,
        memory: state.memory
          ? {
            story_so_far: state.memory.story_so_far,
            open_threads: state.memory.open_threads,
            motifs: state.memory.motifs,
          }
          : null,
        existingScenes: [...state.scenes].reverse().slice(0, 12).map((scene) => ({
          id: scene.id,
          order_key: scene.order_key,
          title: scene.title,
          placement: scene.placement,
          open_image: scene.open_image,
        })),
        payload,
      }, port);
      result.stages.push({ stage, output: plan });
      payload = { ...payload, ...plan.nextPayloadPatch };
      if (plan.nextStage === "write") {
        while (true) {
          stage = "write";
          const { writeAttempt, isFallback } = writeState(payload);
          result.attempts++;
          result.fallback ||= isFallback;
          const write = await runWrite({
            dream,
            volume: state.volume,
            memory: state.memory
              ? {
                story_so_far: state.memory.story_so_far,
                open_threads: state.memory.open_threads,
                motifs: state.memory.motifs,
                world_rules: state.memory.world_rules,
              }
              : null,
            entities: [...state.entities].sort((a, b) =>
              (b.mention_count ?? 0) - (a.mention_count ?? 0)
            ).slice(0, 20),
            recentScenes: [...state.scenes].reverse().slice(0, 2).map((scene) => ({
              id: scene.id,
              title: scene.title,
              open_image: scene.open_image,
              passages: scene.passages?.map((passage) => {
                const row = passage as Record<string, unknown>;
                return {
                  order_key: row.order_key,
                  text: row.text,
                  origin: row.origin,
                  locked: false,
                };
              }),
            })),
            lockedPassages: [],
            payload,
            writeAttempt,
            isFallback,
          }, port);
          result.stages.push({ stage, output: write });
          payload = { ...payload, ...write.nextPayloadPatch };
          stage = "validate";
          const validate = await runValidate({
            payload,
            elements: extract.rows,
            registry: state.entities,
            lockedPassages: [],
          }, port);
          result.stages.push({ stage, output: validate });
          payload = { ...payload, ...validate.nextPayloadPatch };
          if (validate.next.stage === "commit") break;
          if (validate.next.terminal) throw new EvalError("VALIDATION_TERMINAL");
          // The core uses sceneLoopNext; writeState above reads its next attempt.
        }
        stage = "commit";
        const draft = sceneDraftSchema.parse(payload.draft);
        const commit = buildCommitPayload({
          jobId: dreamId,
          userId: volumeId,
          dreamId,
          volumeId,
          clarity: extract.normalized.clarity,
          placement: plan.plan.placement,
          draft,
          links: link.decisions.auto.map((match) => ({
            entity_id: match.entity_id,
            status: "auto" as const,
          })),
          sceneOrderKey: nextSceneOrderKey(state.scenes.map((scene) => scene.order_key!)),
        });
        const scene: RecentScene = {
          ...commit.scene,
          id: await deterministicUuid(`eval:scene:${dreamId}`),
          title: commit.scene.title ?? null,
          open_image: commit.open_image ?? null,
          passages: [...commit.passages],
        };
        result.scene = scene;
        if (record.kind === "sequence") {
          state.scenes.push(scene);
          for (const entity of draft.new_entities ?? []) {
            if (
              entity.from_element && !extract.rows.some((row) => row.id === entity.from_element)
            ) throw new EvalError("COMMIT_SOURCE_MISSING");
            const roleName = entity.role_name.trim();
            let existing = state.entities.find((entry) => entry.role_name === roleName);
            if (!existing) {
              existing = {
                id: await deterministicUuid(`eval:entity:${volumeId}:${roleName}`),
                role_name: roleName,
                type: entity.type ?? "person",
                mention_count: 0,
              };
              state.entities.push(existing);
            }
            existing.description = entity.description ?? existing.description ?? null;
            existing.aliases = [
              ...new Set([...(existing.aliases ?? []), ...(entity.aliases ?? [])]),
            ].sort();
            existing.mention_count = (existing.mention_count ?? 0) + 1;
          }
          for (const id of commit.used_entities ?? []) {
            const existing = state.entities.find((entity) => entity.id === id);
            if (!existing) throw new EvalError("COMMIT_ENTITY_MISSING");
            existing.mention_count = (existing.mention_count ?? 0) + 1;
          }
          result.stages.push({
            stage,
            output: { scene, entities: structuredClone(state.entities) },
          });
          stage = "remember";
          const remember = await runRemember({
            committedScene: {
              id: scene.id,
              title: scene.title,
              placement: scene.placement,
              open_image: scene.open_image,
              passages: scene.passages?.map((passage) => {
                const row = passage as Record<string, unknown>;
                return { order_key: row.order_key, text: row.text, origin: row.origin };
              }),
            },
            previous: state.memory,
            previousProfile: state.volume.genre_profile,
          }, port);
          state.memory = {
            story_so_far: remember.memory.story_so_far,
            open_threads: remember.memory.open_threads,
            motifs: remember.memory.motifs,
            version: remember.nextVersion,
            world_rules: remember.worldRules,
          };
          state.volume.genre_profile = remember.genreProfile;
          result.stages.push({ stage, output: remember });
        }
      }
      result.status = "success";
    } catch (error) {
      result.failed_stage = stage;
      result.code = failureCode(error);
    }
    result.cost_krw = result.model_calls.reduce(
      (sum, call) => sum + estimatedCostKrw(call.model, call.tokensIn, call.tokensOut),
      0,
    );
    result.cost_complete = result.model_calls.every((call) =>
      call.status === "success" &&
      ["fixture", "openai/gpt-oss-20b", "openai/gpt-oss-120b"].includes(call.model)
    );
    result.latency_ms = performance.now() - started;
    dreams.push(result);
    // A failed sequence stops: later dreams must not use a broken history.
    if (result.status === "failed") break;
  }
  return finish();
}

export function summarize(results: CaseResult[], gateEligible = true) {
  const dreams = results.flatMap((result) => result.dreams);
  const violations: Record<string, number> = {};
  for (const dream of dreams) {
    for (const stage of dream.stages.filter((stage) => stage.stage === "validate")) {
      const output = stage.output as Awaited<ReturnType<typeof runValidate>>;
      for (const violation of output.outcome.violations) {
        violations[violation.code] = (violations[violation.code] ?? 0) + 1;
      }
    }
  }
  const latencies = dreams.map((dream) => dream.latency_ms).sort((a, b) => a - b);
  const quantile = (p: number) => latencies[Math.max(0, Math.ceil(latencies.length * p) - 1)] ?? 0;
  const costs = dreams.map((dream) => dream.cost_krw);
  return {
    success: results.filter((result) => result.status === "success").length,
    failed: results.filter((result) => result.status === "failed").length,
    fallback: results.filter((result) => result.fallback).length,
    gate_units: gateEligible ? results.length : 0,
    dreams: dreams.length,
    dream_success: dreams.filter((dream) => dream.status === "success").length,
    dream_failed: dreams.filter((dream) => dream.status === "failed").length,
    dream_fallback: dreams.filter((dream) => dream.fallback).length,
    validation_codes: violations,
    cost_krw: {
      mean_per_dream: costs.reduce((a, b) => a + b, 0) / (costs.length || 1),
      max_per_dream: Math.max(0, ...costs),
      complete: dreams.every((dream) => dream.cost_complete),
    },
    latency_ms: { p50: quantile(0.5), p95: quantile(0.95) },
  };
}

import { type LlmPort, modelRun } from "../_shared/llm_port.ts";
import type { NarrativeMemory, RecentScene } from "../_shared/stage_context.ts";
import { REMEMBER_PROMPT_VERSION, REMEMBER_SYSTEM } from "../_shared/prompts/remember.v1.ts";
import { rememberJsonSchema, rememberOutputSchema } from "../_shared/stage_contracts.ts";
import { blendGenreProfile, normalizeMemory } from "./remember.ts";
export interface RememberCoreInput {
  committedScene: RecentScene;
  previous: NarrativeMemory | null;
  previousProfile: Record<string, number>;
}
export async function runRemember(
  { committedScene, previous, previousProfile }: RememberCoreInput,
  llm: LlmPort,
) {
  const result = await llm.structured<unknown>({
    role: "remember",
    schemaName: "mumumong_remember_v1",
    schema: rememberJsonSchema,
    system: REMEMBER_SYSTEM,
    input: {
      previous: previous ?? {},
      committed_scene: committedScene,
    },
    temperature: 0.2,
    maxTokens: 1800,
  });
  const memory = normalizeMemory(rememberOutputSchema.parse(result.value));
  const nextVersion = ((previous?.version as number | undefined) ?? 0) + 1;

  return {
    memory,
    nextVersion,
    worldRules: previous?.world_rules ?? [],
    genreProfile: blendGenreProfile(previousProfile, memory.genre_scores),
    modelRuns: [modelRun("remember", REMEMBER_PROMPT_VERSION, result)],
    nextPayloadPatch: { remember_complete: true, memory_version: nextVersion },
  };
}

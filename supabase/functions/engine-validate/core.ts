import {
  adaptationSchema,
  claritySchema,
  type DreamElement,
  type RegistryEntity,
} from "../_shared/contract.ts";
import type { LlmPort } from "../_shared/llm_port.ts";
import { sceneLoopNext, validationProfile, writeState } from "../_shared/scene_loop_policy.ts";
import type { LockedPassage } from "../_shared/stage_context.ts";
import { lockedPassageHash } from "../_shared/text.ts";
import { auditRecord, validateSceneDraft } from "./validate.ts";

export const VALIDATE_PROMPT_VERSION = "e5.rules.v3";
export interface ValidateCoreInput {
  payload: Record<string, unknown>;
  elements: DreamElement[];
  registry: RegistryEntity[];
  lockedPassages: LockedPassage[];
}

// v10 validation is deterministic. The optional port makes that absence of model
// calls explicit to callers that pass the same fake/production port to every stage.
export async function runValidate(input: ValidateCoreInput, _llm?: LlmPort) {
  const { payload, elements, registry, lockedPassages } = input;
  const { isFallback, writeAttempt } = writeState(payload);
  const lockedPassageHashes = await Promise.all(
    lockedPassages.map((row) => lockedPassageHash(row.text)),
  );
  const outcome = await validateSceneDraft({
    draft: payload.draft,
    clarity: claritySchema.parse(payload.clarity),
    adaptation: adaptationSchema.parse(payload.adaptation),
    elements,
    registry,
    lockedPassageHashes,
    minimumChars: payload.is_first_dream === true && typeof payload.target_length === "number"
      ? Math.max(350, Math.floor(payload.target_length * 0.7))
      : undefined,
    minimumPassages: payload.is_first_dream === true ? 7 : undefined,
    profile: validationProfile(isFallback),
  });
  const audit = auditRecord(outcome);
  const next = sceneLoopNext(outcome.action, writeAttempt, isFallback);
  const nextPayloadPatch = next.stage === "commit"
    ? { validation_complete: true, validation_audit: audit }
    : next.stage === "write"
    ? {
      write_attempt: next.writeAttempt,
      is_fallback: next.isFallback,
      validation_feedback: outcome.violations.map((violation) => ({
        code: violation.code,
        message: violation.message,
      })),
    }
    : {};
  return { outcome, audit, next, nextPayloadPatch, modelRuns: [], isFallback };
}

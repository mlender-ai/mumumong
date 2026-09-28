import type { ValidationAction, ValidationProfile } from "../engine-validate/validate.ts";

export const SCENE_LOOP_POLICY = {
  lastRegularWriteAttempt: 2,
  fallbackWriteAttempt: 3,
  fallbackTargetRatio: 0.6,
  strictProfile: "strict",
  fallbackProfile: "relaxed",
} as const;

export function writeState(payload: Record<string, unknown>): {
  writeAttempt: number;
  isFallback: boolean;
} {
  return {
    writeAttempt: typeof payload.write_attempt === "number" ? payload.write_attempt : 0,
    isFallback: payload.is_fallback === true,
  };
}

export function fallbackTarget(targetLength: number): number {
  return Math.max(1, Math.floor(targetLength * SCENE_LOOP_POLICY.fallbackTargetRatio));
}

export function validationProfile(isFallback: boolean): ValidationProfile {
  return isFallback ? SCENE_LOOP_POLICY.fallbackProfile : SCENE_LOOP_POLICY.strictProfile;
}

export function sceneLoopNext(
  action: ValidationAction,
  currentWriteAttempt: number,
  isFallback: boolean,
): {
  stage: "commit" | "write" | null;
  writeAttempt: number;
  isFallback: boolean;
  terminal: boolean;
} {
  if (action === "accept") {
    return { stage: "commit", writeAttempt: currentWriteAttempt, isFallback, terminal: false };
  }
  if (isFallback || action === "discard") {
    return { stage: null, writeAttempt: currentWriteAttempt, isFallback, terminal: true };
  }
  const fallback = currentWriteAttempt >= SCENE_LOOP_POLICY.lastRegularWriteAttempt;
  return {
    stage: "write",
    writeAttempt: fallback ? SCENE_LOOP_POLICY.fallbackWriteAttempt : currentWriteAttempt + 1,
    isFallback: fallback,
    terminal: false,
  };
}

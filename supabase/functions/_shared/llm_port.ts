import type { ModelRole, UsageMetadata } from "./llm/types.ts";
export type {
  LlmPort,
  ModelRole,
  StructuredCall,
  StructuredLlmPort,
  StructuredResult,
  TextCall,
  TextResult,
} from "./llm/types.ts";

// Metadata only. A core result must never include model bodies in its audit records.
export interface ModelRun {
  readonly role: ModelRole;
  readonly model: string;
  readonly tokensIn: number;
  readonly tokensOut: number;
  readonly latencyMs: number;
  readonly promptVersion: string;
}

export function modelRun(
  role: ModelRole,
  promptVersion: string,
  result: UsageMetadata,
): ModelRun {
  return {
    role,
    promptVersion,
    model: result.model,
    tokensIn: result.tokensIn,
    tokensOut: result.tokensOut,
    latencyMs: result.latencyMs,
  };
}

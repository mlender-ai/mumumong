import type { StructuredResult } from "./llm.ts";

export type { StructuredResult };
export type ModelRole =
  | "extract"
  | "link"
  | "plan"
  | "write"
  | "write_aux"
  | "polish"
  | "remember"
  | "judge";

export interface StructuredCall {
  readonly role: ModelRole;
  readonly schemaName: string;
  readonly schema: Record<string, unknown>;
  readonly system: string;
  readonly input: unknown;
  readonly temperature: number;
  readonly maxTokens: number;
}

export interface LlmPort {
  structured<T>(request: StructuredCall): Promise<StructuredResult<T>>;
}

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
  result: StructuredResult<unknown>,
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

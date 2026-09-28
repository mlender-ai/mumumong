export type ModelRole =
  | "extract"
  | "link"
  | "plan"
  | "write"
  | "write_aux"
  | "polish"
  | "remember"
  | "judge";
export interface GenerationCall {
  readonly system: string;
  readonly temperature: number;
  readonly maxTokens: number;
}
export interface StructuredCall extends GenerationCall {
  readonly role: ModelRole;
  readonly schemaName: string;
  readonly schema: Record<string, unknown>;
  readonly input: unknown;
}
export interface TextCall extends GenerationCall {
  readonly role: ModelRole;
  readonly user: string;
}
export interface UsageMetadata {
  readonly model: string;
  readonly tokensIn: number;
  readonly tokensOut: number;
  readonly latencyMs: number;
}
export interface StructuredResult<T> extends UsageMetadata {
  readonly value: T;
}
export interface TextResult extends UsageMetadata {
  readonly text: string;
}
export interface StructuredLlmPort {
  structured<T>(request: StructuredCall): Promise<StructuredResult<T>>;
}
export interface LlmPort extends StructuredLlmPort {
  text(request: TextCall): Promise<TextResult>;
}
export interface StructuredRequest extends Omit<StructuredCall, "role"> {
  readonly model: string;
  /// Adapter tests only. Cores cannot pass credentials in a role-based call.
  readonly apiKey?: string;
}
export interface TextRequest extends Omit<TextCall, "role"> {
  readonly model: string;
  readonly apiKey?: string;
}
export interface ModelAdapter {
  structured<T>(request: StructuredRequest): Promise<StructuredResult<T>>;
  text(request: TextRequest): Promise<TextResult>;
}
export interface AdapterDependencies {
  readonly fetcher?: typeof fetch;
  readonly readSecret?: (name: string) => string | undefined;
  readonly sleep?: (ms: number) => Promise<void>;
}
export class ModelCallError extends Error {
  constructor(readonly code: string) {
    super(code);
    this.name = "ModelCallError";
  }
}

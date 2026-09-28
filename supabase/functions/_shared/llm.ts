import { createGroqAdapter } from "./llm/groq.ts";
import type { StructuredRequest, StructuredResult } from "./llm/types.ts";

export const LIGHT_MODEL = "openai/gpt-oss-20b";
export const QUALITY_MODEL = "openai/gpt-oss-120b";
export { ModelCallError } from "./llm/types.ts";
export type { StructuredRequest, StructuredResult } from "./llm/types.ts";
export { estimatedCostKrw } from "./llm/registry.ts";

// Compatibility entrypoint for existing Groq tests and callers.
export function callStructured<T>(
  request: StructuredRequest,
  fetcher: typeof fetch = fetch,
): Promise<StructuredResult<T>> {
  return createGroqAdapter({ fetcher }).structured<T>(request);
}

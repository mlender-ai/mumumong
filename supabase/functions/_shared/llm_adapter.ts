import { callStructured, ModelCallError } from "./llm.ts";
import type { LlmPort, StructuredCall, StructuredResult } from "./llm_port.ts";
import { configuredModel, type EnvironmentReader } from "./model_config.ts";

// Q-02 preserves the existing Groq transport. Additional providers belong to Q-04.
export function createProductionLlm(read?: EnvironmentReader): LlmPort {
  return {
    async structured<T>(request: StructuredCall): Promise<StructuredResult<T>> {
      const { provider, model } = configuredModel(request.role, read);
      if (provider !== "groq") throw new ModelCallError("provider_not_supported");
      const { role: _role, ...parameters } = request;
      return await callStructured<T>({ ...parameters, model });
    },
  };
}

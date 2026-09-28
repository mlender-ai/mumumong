import { configuredModel, type EnvironmentReader } from "../model_config.ts";
import { adapterFor, resolveModel } from "./registry.ts";
import type { AdapterDependencies, LlmPort, StructuredCall } from "./types.ts";

export function createProductionLlm(
  read?: EnvironmentReader,
  deps: AdapterDependencies = {},
): LlmPort {
  function adapter(role: Parameters<typeof configuredModel>[0]) {
    const selected = configuredModel(role, read);
    const definition = resolveModel(`${selected.provider}:${selected.model}`);
    return { adapter: adapterFor(definition, deps), model: selected.model };
  }
  return {
    async structured<T>(request: StructuredCall) {
      const selected = adapter(request.role);
      const { role: _role, ...parameters } = request;
      return await selected.adapter.structured<T>({ ...parameters, model: selected.model });
    },
    async text(request) {
      const selected = adapter(request.role);
      const { role: _role, ...parameters } = request;
      return await selected.adapter.text({ ...parameters, model: selected.model });
    },
  };
}

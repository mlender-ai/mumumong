import { LIGHT_MODEL, QUALITY_MODEL } from "./llm.ts";
import type { ModelRole } from "./llm_port.ts";

export type EnvironmentReader = (name: string) => string | undefined;
export const DEFAULT_MODELS: Readonly<Record<ModelRole, string>> = {
  extract: `groq:${LIGHT_MODEL}`,
  link: `groq:${LIGHT_MODEL}`,
  plan: `groq:${QUALITY_MODEL}`,
  write: `groq:${QUALITY_MODEL}`,
  write_aux: `groq:${LIGHT_MODEL}`,
  polish: `groq:${QUALITY_MODEL}`,
  remember: `groq:${LIGHT_MODEL}`,
  judge: `groq:${LIGHT_MODEL}`,
};

export function configuredModel(
  role: ModelRole,
  read: EnvironmentReader = (name) => Deno.env.get(name),
): { provider: string; model: string } {
  const value = read(`MODEL_${role.toUpperCase()}`)?.trim() || DEFAULT_MODELS[role];
  const separator = value.indexOf(":");
  if (separator < 1 || separator === value.length - 1 || /\s/u.test(value)) {
    throw new Error("model_config_invalid");
  }
  return { provider: value.slice(0, separator), model: value.slice(separator + 1) };
}

export function engineVersion(read: EnvironmentReader = (name) => Deno.env.get(name)): string {
  return read("ENGINE_VERSION")?.trim() || "v10";
}

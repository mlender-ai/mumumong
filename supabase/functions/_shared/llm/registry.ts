import { createGroqAdapter } from "./groq.ts";
import { createAnthropicAdapter } from "./anthropic.ts";
import { createOpenAiAdapter } from "./openai.ts";
import { type AdapterDependencies, type ModelAdapter, ModelCallError } from "./types.ts";

export type Provider = "groq" | "anthropic" | "openai";
export interface ModelDefinition {
  readonly provider: Provider;
  readonly id: string;
  readonly aliases: readonly string[];
  readonly usdPerMillion: { readonly input: number; readonly output: number };
  readonly features: {
    readonly structured: "json_schema" | "forced_tool";
    readonly text: boolean;
    readonly temperature: boolean;
  };
  readonly verifiedAt: string;
  readonly source: string;
}
// Standard uncached text rates verified from primary provider pages on 2026-09-29.
// Registry presence is compatibility metadata, not a quality winner or production switch.
export const MODELS: readonly ModelDefinition[] = [
  {
    provider: "groq",
    id: "openai/gpt-oss-20b",
    aliases: [],
    usdPerMillion: { input: 0.075, output: 0.30 },
    features: { structured: "json_schema", text: true, temperature: true },
    verifiedAt: "2026-09-29",
    source: "https://console.groq.com/docs/models",
  },
  {
    provider: "groq",
    id: "openai/gpt-oss-120b",
    aliases: [],
    usdPerMillion: { input: 0.15, output: 0.60 },
    features: { structured: "json_schema", text: true, temperature: true },
    verifiedAt: "2026-09-29",
    source: "https://console.groq.com/docs/models",
  },
  {
    provider: "anthropic",
    id: "claude-sonnet-5",
    aliases: [],
    usdPerMillion: { input: 2, output: 10 },
    features: { structured: "forced_tool", text: true, temperature: false },
    verifiedAt: "2026-09-29",
    source: "https://platform.claude.com/docs/en/models/sonnet-5/overview",
  },
  {
    provider: "anthropic",
    id: "claude-sonnet-4-6",
    aliases: [],
    usdPerMillion: { input: 3, output: 15 },
    features: { structured: "forced_tool", text: true, temperature: false },
    verifiedAt: "2026-09-29",
    source: "https://platform.claude.com/docs/en/models/sonnet-4-6/overview",
  },
  {
    provider: "openai",
    id: "gpt-4.1-2025-04-14",
    aliases: ["gpt-4.1"],
    usdPerMillion: { input: 2, output: 8 },
    features: { structured: "json_schema", text: true, temperature: true },
    verifiedAt: "2026-09-29",
    source: "https://developers.openai.com/api/docs/models/gpt-4.1",
  },
];

export function resolveModel(name: string): ModelDefinition {
  const separator = name.indexOf(":");
  if (separator < 1) throw new ModelCallError("model_config_invalid");
  const provider = name.slice(0, separator);
  if (!["groq", "anthropic", "openai"].includes(provider)) {
    throw new ModelCallError("provider_not_supported");
  }
  const id = name.slice(separator + 1);
  const definition = MODELS.find((entry) =>
    entry.provider === provider && (entry.id === id || entry.aliases.includes(id))
  );
  if (!definition) throw new ModelCallError("model_not_registered");
  return definition;
}

export function adapterFor(model: ModelDefinition, deps: AdapterDependencies = {}): ModelAdapter {
  switch (model.provider) {
    case "groq":
      return createGroqAdapter(deps);
    case "anthropic":
      return createAnthropicAdapter(deps, model.features.temperature);
    case "openai":
      return createOpenAiAdapter(deps);
  }
}

export function priceFor(name: string): ModelDefinition["usdPerMillion"] | undefined {
  return MODELS.find((entry) =>
    [entry.id, ...entry.aliases].some((id) => name === id || name === `${entry.provider}:${id}`)
  )?.usdPerMillion;
}

export function estimatedCostKrw(
  model: string,
  tokensIn: number,
  tokensOut: number,
  krwPerUsd = 1400,
): number {
  const price = priceFor(model);
  if (!price) return 0;
  return Number(
    (((tokensIn * price.input + tokensOut * price.output) / 1_000_000) * krwPerUsd).toFixed(6),
  );
}

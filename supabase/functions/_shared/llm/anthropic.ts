import { z } from "zod";
import { apiKey, envelope, transport } from "./transport.ts";
import {
  type AdapterDependencies,
  type ModelAdapter,
  ModelCallError,
  type StructuredRequest,
  type TextRequest,
} from "./types.ts";

const messageEnvelope = z.object({
  model: z.string().optional(),
  stop_reason: z.string().nullable().optional(),
  content: z.array(
    z.object({
      type: z.string(),
      name: z.string().optional(),
      input: z.unknown().optional(),
      text: z.string().optional(),
    }),
  ),
  usage: z.object({
    input_tokens: z.number().nonnegative(),
    output_tokens: z.number().nonnegative(),
  }),
});

export function createAnthropicAdapter(
  deps: AdapterDependencies = {},
  supportsTemperature = false,
): ModelAdapter {
  async function call(request: StructuredRequest | TextRequest, structured: boolean) {
    const key = apiKey("ANTHROPIC_API_KEY", /^sk-ant-[A-Za-z0-9_-]+$/u, request.apiKey, deps);
    const started = Date.now();
    const schemaRequest = request as StructuredRequest;
    const response = await transport(deps)("https://api.anthropic.com/v1/messages", {
      "x-api-key": key,
      "content-type": "application/json",
      "anthropic-version": "2023-06-01",
    }, {
      model: request.model,
      system: request.system,
      max_tokens: request.maxTokens,
      ...(supportsTemperature ? { temperature: request.temperature } : {}),
      thinking: { type: "disabled" },
      messages: [{
        role: "user",
        content: structured ? JSON.stringify(schemaRequest.input) : (request as TextRequest).user,
      }],
      ...(structured
        ? {
          tools: [{
            name: schemaRequest.schemaName,
            description: "Return the requested structured output.",
            input_schema: schemaRequest.schema,
          }],
          tool_choice: {
            type: "tool",
            name: schemaRequest.schemaName,
            disable_parallel_tool_use: true,
          },
        }
        : {}),
    });
    const value = await envelope(response, messageEnvelope);
    if (value.stop_reason === "max_tokens") throw new ModelCallError("provider_truncated_output");
    if (value.stop_reason === "refusal") throw new ModelCallError("provider_refusal");
    return {
      value,
      usage: {
        model: `anthropic:${value.model ?? request.model}`,
        tokensIn: value.usage.input_tokens,
        tokensOut: value.usage.output_tokens,
        latencyMs: Date.now() - started,
      },
    };
  }
  return {
    async structured<T>(request: StructuredRequest) {
      const { value, usage } = await call(request, true);
      const blocks = value.content.filter((block) =>
        block.type === "tool_use" && block.name === request.schemaName
      );
      if (blocks.length !== 1 || blocks[0].input === undefined) {
        throw new ModelCallError("provider_missing_tool_output");
      }
      return { ...usage, value: blocks[0].input as T };
    },
    async text(request) {
      const { value, usage } = await call(request, false);
      const text = value.content.filter((block) => block.type === "text").map((block) =>
        block.text ?? ""
      ).join("");
      if (!text) throw new ModelCallError("provider_empty_output");
      return { ...usage, text };
    },
  };
}

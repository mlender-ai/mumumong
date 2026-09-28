import { apiKey, chatContent, chatEnvelope, envelope, parseJson, transport } from "./transport.ts";
import {
  type AdapterDependencies,
  type ModelAdapter,
  ModelCallError,
  type StructuredRequest,
  type TextRequest,
} from "./types.ts";

export function createOpenAiAdapter(deps: AdapterDependencies = {}): ModelAdapter {
  async function call(request: StructuredRequest | TextRequest, structured: boolean) {
    const key = apiKey("OPENAI_API_KEY", /^sk-[A-Za-z0-9_-]+$/u, request.apiKey, deps);
    const started = Date.now();
    const schemaRequest = request as StructuredRequest;
    const response = await transport(deps)("https://api.openai.com/v1/chat/completions", {
      authorization: `Bearer ${key}`,
      "content-type": "application/json",
    }, {
      model: request.model,
      messages: [{ role: "system", content: request.system }, {
        role: "user",
        content: structured ? JSON.stringify(schemaRequest.input) : (request as TextRequest).user,
      }],
      temperature: request.temperature,
      max_completion_tokens: request.maxTokens,
      store: false,
      ...(structured
        ? {
          response_format: {
            type: "json_schema",
            json_schema: {
              name: schemaRequest.schemaName,
              strict: true,
              schema: schemaRequest.schema,
            },
          },
        }
        : {}),
    });
    const value = await envelope(response, chatEnvelope);
    if (value.choices?.[0]?.finish_reason === "length") {
      throw new ModelCallError("provider_truncated_output");
    }
    return {
      content: chatContent(value),
      model: `openai:${value.model ?? request.model}`,
      tokensIn: value.usage?.prompt_tokens ?? 0,
      tokensOut: value.usage?.completion_tokens ?? 0,
      latencyMs: Date.now() - started,
    };
  }
  return {
    async structured<T>(request: StructuredRequest) {
      const { content, ...usage } = await call(request, true);
      return { ...usage, value: parseJson<T>(content) };
    },
    async text(request) {
      const { content, ...usage } = await call(request, false);
      return { ...usage, text: content };
    },
  };
}

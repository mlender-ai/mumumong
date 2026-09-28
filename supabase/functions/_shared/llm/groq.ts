import {
  apiKey,
  chatContent,
  chatEnvelope,
  discardBody,
  envelope,
  parseJson,
  transport,
} from "./transport.ts";
import type { AdapterDependencies, ModelAdapter, StructuredRequest, TextRequest } from "./types.ts";

// Preserve v10's endpoint, payload, schema-400 fallback, and bare model audit names.
export function createGroqAdapter(deps: AdapterDependencies = {}): ModelAdapter {
  async function call(request: StructuredRequest | TextRequest, structured: boolean) {
    const key = apiKey("GROQ_API_KEY", /^gsk_[A-Za-z0-9_-]+$/u, request.apiKey, deps);
    const started = Date.now();
    const send = transport(deps);
    const body = {
      model: request.model,
      messages: [{ role: "system", content: request.system }, {
        role: "user",
        content: structured
          ? JSON.stringify((request as StructuredRequest).input)
          : (request as TextRequest).user,
      }],
      temperature: request.temperature,
      max_completion_tokens: request.maxTokens,
      ...(request.model.startsWith("openai/gpt-oss-") ? { reasoning_effort: "low" } : {}),
    };
    const schemaRequest = request as StructuredRequest;
    let response = await send("https://api.groq.com/openai/v1/chat/completions", {
      authorization: `Bearer ${key}`,
      "content-type": "application/json",
    }, {
      ...body,
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
    if (structured && response.status === 400) {
      await discardBody(response);
      response = await send("https://api.groq.com/openai/v1/chat/completions", {
        authorization: `Bearer ${key}`,
        "content-type": "application/json",
      }, { ...body, response_format: { type: "json_object" } });
    }
    const value = await envelope(response, chatEnvelope);
    return {
      content: chatContent(value),
      model: value.model ?? request.model,
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

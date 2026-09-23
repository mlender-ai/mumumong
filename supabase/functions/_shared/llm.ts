export const LIGHT_MODEL = "openai/gpt-oss-20b";
export const QUALITY_MODEL = "openai/gpt-oss-120b";

export interface StructuredRequest {
  readonly model: string;
  readonly schemaName: string;
  readonly schema: Record<string, unknown>;
  readonly system: string;
  readonly input: unknown;
  readonly temperature: number;
  readonly maxTokens: number;
  /// Test seam only. Production callers use the Edge Function secret.
  readonly apiKey?: string;
}

export interface StructuredResult<T> {
  readonly value: T;
  readonly model: string;
  readonly tokensIn: number;
  readonly tokensOut: number;
  readonly latencyMs: number;
}

export class ModelCallError extends Error {
  constructor(readonly code: string) {
    super(code);
  }
}

type Fetcher = typeof fetch;

export async function callStructured<T>(
  request: StructuredRequest,
  fetcher: Fetcher = fetch,
): Promise<StructuredResult<T>> {
  const apiKey = (request.apiKey ?? Deno.env.get("GROQ_API_KEY"))?.trim();
  if (!apiKey) throw new ModelCallError("provider_not_configured");
  if (!/^gsk_[A-Za-z0-9_-]+$/u.test(apiKey)) {
    throw new ModelCallError("provider_invalid_key_format");
  }

  const started = Date.now();
  let response: Response;
  try {
    response = await fetcher("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        authorization: `Bearer ${apiKey}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: request.model,
        messages: [
          { role: "system", content: request.system },
          { role: "user", content: JSON.stringify(request.input) },
        ],
        temperature: request.temperature,
        max_completion_tokens: request.maxTokens,
        reasoning_effort: "low",
        response_format: {
          type: "json_schema",
          json_schema: {
            name: request.schemaName,
            strict: true,
            schema: request.schema,
          },
        },
      }),
      signal: AbortSignal.timeout(55_000),
    });
  } catch (error) {
    const message = error instanceof Error ? error.message.toLowerCase() : "";
    const category = message.includes("header")
      ? "invalid_header"
      : message.includes("timed out") || message.includes("timeout")
      ? "timeout"
      : message.includes("dns") || message.includes("resolve")
      ? "dns"
      : message.includes("certificate") || message.includes("tls")
      ? "tls"
      : message.includes("sending request")
      ? "request_failed"
      : "other";
    const name = error instanceof Error
      ? error.name.toLowerCase().replace(/[^a-z0-9_-]/gu, "_").slice(0, 24)
      : "unknown";
    const cause = error instanceof Error && "cause" in error && error.cause &&
        typeof error.cause === "object" && "code" in error.cause &&
        typeof error.cause.code === "string"
      ? error.cause.code.toLowerCase().replace(/[^a-z0-9_-]/gu, "_").slice(0, 24)
      : "none";
    throw new ModelCallError(`provider_unreachable:${category}:${name}:${cause}`);
  }

  if (!response.ok) {
    // The provider body can echo request content. Never include it in the error.
    throw new ModelCallError(`provider_http_${response.status}`);
  }

  const envelope = await response.json() as {
    model?: string;
    choices?: { message?: { content?: string } }[];
    usage?: { prompt_tokens?: number; completion_tokens?: number };
  };
  const content = envelope.choices?.[0]?.message?.content;
  if (!content) throw new ModelCallError("provider_empty_output");

  let value: T;
  try {
    value = JSON.parse(content) as T;
  } catch {
    throw new ModelCallError("provider_invalid_json");
  }

  return {
    value,
    model: envelope.model ?? request.model,
    tokensIn: envelope.usage?.prompt_tokens ?? 0,
    tokensOut: envelope.usage?.completion_tokens ?? 0,
    latencyMs: Date.now() - started,
  };
}

const USD_PER_MILLION: Readonly<Record<string, { input: number; output: number }>> = {
  "openai/gpt-oss-20b": { input: 0.075, output: 0.30 },
  "openai/gpt-oss-120b": { input: 0.15, output: 0.60 },
};

export function estimatedCostKrw(
  model: string,
  tokensIn: number,
  tokensOut: number,
  krwPerUsd = 1400,
): number {
  const price = USD_PER_MILLION[model];
  if (!price) return 0;
  return Number(
    (((tokensIn * price.input + tokensOut * price.output) / 1_000_000) * krwPerUsd).toFixed(6),
  );
}

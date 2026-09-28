import { z } from "zod";
import { type AdapterDependencies, ModelCallError } from "./types.ts";

export function apiKey(
  name: string,
  pattern: RegExp,
  testKey: string | undefined,
  deps: AdapterDependencies,
): string {
  const key = (testKey ?? (deps.readSecret ?? ((name) => Deno.env.get(name)))(name))?.trim();
  if (!key) throw new ModelCallError("provider_not_configured");
  if (!pattern.test(key)) throw new ModelCallError("provider_invalid_key_format");
  return key;
}

function unreachable(error: unknown): ModelCallError {
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
  const name = error instanceof Error &&
      ["Error", "TypeError", "AbortError", "TimeoutError"].includes(error.name)
    ? error.name.toLowerCase()
    : "unknown";
  const cause =
    error instanceof Error && "cause" in error && error.cause && typeof error.cause === "object" &&
      "code" in error.cause &&
      ["ENOTFOUND", "ECONNRESET", "ECONNREFUSED", "ETIMEDOUT", "EAI_AGAIN"].includes(
        String(error.cause.code),
      )
      ? String(error.cause.code).toLowerCase()
      : "none";
  return new ModelCallError(`provider_unreachable:${category}:${name}:${cause}`);
}

// One logical call shares this retry budget, including Groq's schema-mode fallback.
export function transport(deps: AdapterDependencies) {
  let retries = 0;
  const sleep = deps.sleep ?? ((ms) => new Promise<void>((resolve) => setTimeout(resolve, ms)));
  const fetcher = deps.fetcher ?? fetch;
  return async (
    url: string,
    headers: Record<string, string>,
    body: Record<string, unknown>,
  ): Promise<Response> => {
    while (true) {
      let response: Response;
      try {
        response = await fetcher(url, {
          method: "POST",
          headers,
          body: JSON.stringify(body),
          signal: AbortSignal.timeout(55_000),
        });
      } catch (error) {
        throw unreachable(error);
      }
      if (
        (response.status === 429 || response.status >= 500 && response.status <= 599) && retries < 2
      ) {
        await discardBody(response);
        await sleep(500 * 2 ** retries++);
        continue;
      }
      return response;
    }
  };
}

export async function discardBody(response: Response): Promise<void> {
  try {
    await response.body?.cancel();
  } catch {
    // A failed stream cancellation must never expose provider/private body errors.
  }
}

export async function envelope<T>(response: Response, schema: z.ZodType<T>): Promise<T> {
  if (!response.ok) {
    await discardBody(response);
    throw new ModelCallError(`provider_http_${response.status}`);
  }
  let value: unknown;
  try {
    value = await response.json();
  } catch {
    throw new ModelCallError("provider_invalid_envelope");
  }
  const parsed = schema.safeParse(value);
  if (!parsed.success) throw new ModelCallError("provider_invalid_envelope");
  return parsed.data;
}

export function parseJson<T>(text: string): T {
  try {
    return JSON.parse(text) as T;
  } catch {
    throw new ModelCallError("provider_invalid_json");
  }
}

export const chatEnvelope = z.object({
  model: z.string().optional(),
  choices: z.array(z.object({
    message: z.object({
      content: z.string().nullable().optional(),
      refusal: z.string().nullable().optional(),
    }),
    finish_reason: z.string().nullable().optional(),
  })).optional(),
  usage: z.object({
    prompt_tokens: z.number().nonnegative().optional(),
    completion_tokens: z.number().nonnegative().optional(),
  }).optional(),
});

export function chatContent(value: z.infer<typeof chatEnvelope>): string {
  const message = value.choices?.[0]?.message;
  if (message?.refusal) throw new ModelCallError("provider_refusal");
  if (!message?.content) throw new ModelCallError("provider_empty_output");
  return message.content;
}

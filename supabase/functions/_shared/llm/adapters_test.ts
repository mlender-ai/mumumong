import { assert, assertEquals, assertRejects } from "@std/assert";
import { z } from "zod";
import { createGroqAdapter } from "./groq.ts";
import { createAnthropicAdapter } from "./anthropic.ts";
import { createOpenAiAdapter } from "./openai.ts";
import { createProductionLlm } from "./port.ts";
import { estimatedCostKrw, priceFor, resolveModel } from "./registry.ts";
import {
  type AdapterDependencies,
  type ModelAdapter,
  ModelCallError,
  type StructuredRequest,
} from "./types.ts";
import { runExtract } from "../../engine-extract/core.ts";

const marker = "SYNTHETIC_PRIVATE_MARKER";
const outputSchema = z.object({ ok: z.boolean() });
const request: Omit<StructuredRequest, "model" | "apiKey"> = {
  schemaName: "synthetic_output",
  schema: {
    type: "object",
    properties: { ok: { type: "boolean" } },
    required: ["ok"],
    additionalProperties: false,
  },
  system: "Return synthetic test output.",
  input: { private: marker },
  temperature: 0.75,
  maxTokens: 128,
};
const providers: {
  name: string;
  model: string;
  key: string;
  factory: (deps: AdapterDependencies) => ModelAdapter;
}[] = [
  {
    name: "groq",
    model: "openai/gpt-oss-120b",
    key: "gsk_test_only_key",
    factory: createGroqAdapter,
  },
  {
    name: "anthropic",
    model: "claude-sonnet-5",
    key: "sk-ant-test_only_key",
    factory: createAnthropicAdapter,
  },
  {
    name: "openai",
    model: "gpt-4.1-2025-04-14",
    key: "sk-proj-test_only_key",
    factory: createOpenAiAdapter,
  },
];
function response(
  provider: string,
  value: unknown = { ok: true },
  text?: string,
  schemaName = request.schemaName,
) {
  return new Response(JSON.stringify(
    provider === "anthropic"
      ? {
        content: text === undefined
          ? [{ type: "tool_use", name: schemaName, input: value }]
          : [{ type: "text", text }],
        usage: { input_tokens: 10, output_tokens: 4 },
        stop_reason: text === undefined ? "tool_use" : "end_turn",
      }
      : {
        choices: [{ message: { content: text ?? JSON.stringify(value) } }],
        usage: { prompt_tokens: 10, completion_tokens: 4 },
      },
  ));
}

for (const provider of providers) {
  Deno.test(`${provider.name} failed body cancellation cannot leak private stream errors`, async () => {
    const adapter = provider.factory({
      fetcher: () =>
        Promise.resolve(
          new Response(
            new ReadableStream({
              cancel() {
                throw new Error(marker);
              },
            }),
            { status: 403 },
          ),
        ),
    });
    const error = await assertRejects(
      () => adapter.structured({ ...request, model: provider.model, apiKey: provider.key }),
      ModelCallError,
      "provider_http_403",
    );
    assertEquals(error.message.includes(marker), false);
  });
  Deno.test(`${provider.name} structured output and usage are normalized; provider parameters stay isolated`, async () => {
    let body: Record<string, unknown> = {};
    let headers: Headers | undefined;
    const adapter = provider.factory({
      fetcher: (_url, init) => {
        body = JSON.parse(init!.body as string);
        headers = new Headers(init!.headers);
        return Promise.resolve(response(provider.name));
      },
    });
    const result = await adapter.structured({
      ...request,
      model: provider.model,
      apiKey: provider.key,
    });
    assertEquals(outputSchema.parse(result.value), { ok: true });
    assertEquals([result.tokensIn, result.tokensOut], [10, 4]);
    assertEquals(body.model, provider.model);
    if (provider.name === "anthropic") {
      assertEquals(headers!.get("anthropic-version"), "2023-06-01");
      assertEquals(body.tools, [{
        name: request.schemaName,
        description: "Return the requested structured output.",
        input_schema: request.schema,
      }]);
      assertEquals(body.tool_choice, {
        type: "tool",
        name: request.schemaName,
        disable_parallel_tool_use: true,
      });
      assertEquals(body.thinking, { type: "disabled" });
      assertEquals("temperature" in body, false);
      assertEquals("response_format" in body, false);
    } else {
      assertEquals(body.response_format, {
        type: "json_schema",
        json_schema: { name: request.schemaName, strict: true, schema: request.schema },
      });
      assertEquals(body.temperature, request.temperature);
    }
    assertEquals("reasoning_effort" in body, provider.name === "groq");
    if (provider.name === "groq") assertEquals(body.reasoning_effort, "low");
    if (provider.name === "openai") assertEquals(body.store, false);
  });

  Deno.test(`${provider.name} schema violation is rejected by caller Zod contract, not silently accepted as valid`, async () => {
    const adapter = provider.factory({
      fetcher: () => Promise.resolve(response(provider.name, { ok: marker })),
    });
    const result = await adapter.structured({
      ...request,
      model: provider.model,
      apiKey: provider.key,
    });
    assertEquals(outputSchema.safeParse(result.value).success, false);
  });

  Deno.test(`${provider.name} plain text sends a string without structured-output instructions`, async () => {
    let body: Record<string, unknown> = {};
    const adapter = provider.factory({
      fetcher: (_url, init) => {
        body = JSON.parse(init!.body as string);
        return Promise.resolve(response(provider.name, undefined, "synthetic prose"));
      },
    });
    const result = await adapter.text({
      model: provider.model,
      apiKey: provider.key,
      system: "synthetic system",
      user: marker,
      temperature: 0.4,
      maxTokens: 64,
    });
    assertEquals(result.text, "synthetic prose");
    assertEquals((body.messages as { content: string }[]).at(-1)!.content, marker);
    for (const field of ["response_format", "tools", "tool_choice", "input_schema"]) {
      assertEquals(field in body, false);
    }
  });

  Deno.test(`${provider.name} 429/5xx retry twice with exponential backoff, then succeed`, async () => {
    const delays: number[] = [];
    let calls = 0;
    const adapter = provider.factory({
      sleep: (ms) => {
        delays.push(ms);
        return Promise.resolve();
      },
      fetcher: () => {
        calls++;
        return Promise.resolve(
          calls < 3
            ? new Response(marker, { status: calls === 1 ? 429 : 503 })
            : response(provider.name),
        );
      },
    });
    const result = await adapter.structured({
      ...request,
      model: provider.model,
      apiKey: provider.key,
    });
    assertEquals(result.value, { ok: true });
    assertEquals(calls, 3);
    assertEquals(delays, [500, 1000]);
  });

  Deno.test(`${provider.name} retry exhaustion and 4xx failure never expose response bodies`, async () => {
    for (const status of [401, 403, 422, 429, 500, 502, 503]) {
      let calls = 0;
      const adapter = provider.factory({
        sleep: () => Promise.resolve(),
        fetcher: () => {
          calls++;
          return Promise.resolve(new Response(marker, { status }));
        },
      });
      const error = await assertRejects(
        () => adapter.structured({ ...request, model: provider.model, apiKey: provider.key }),
        ModelCallError,
        `provider_http_${status}`,
      );
      assertEquals(calls, status === 429 || status >= 500 ? 3 : 1);
      assertEquals(error.message.includes(marker), false);
    }
  });

  Deno.test(`${provider.name} malformed credentials never reach fetch; own secret reader and trimming work`, async () => {
    let calls = 0;
    const names: string[] = [];
    const adapter = provider.factory({
      readSecret: (name) => {
        names.push(name);
        return ` ${provider.key} `;
      },
      fetcher: () => {
        calls++;
        return Promise.resolve(response(provider.name));
      },
    });
    await adapter.structured({ ...request, model: provider.model });
    assertEquals(names, [`${provider.name.toUpperCase()}_API_KEY`]);
    await assertRejects(
      () => adapter.structured({ ...request, model: provider.model, apiKey: `${marker}\n` }),
      ModelCallError,
      "provider_invalid_key_format",
    );
    assertEquals(calls, 1);
    const missing = provider.factory({
      readSecret: () => undefined,
      fetcher: () => {
        calls++;
        return Promise.resolve(response(provider.name));
      },
    });
    await assertRejects(
      () => missing.structured({ ...request, model: provider.model }),
      ModelCallError,
      "provider_not_configured",
    );
    assertEquals(calls, 1);
  });

  Deno.test(`${provider.name} malformed envelope and transport errors are metadata-only and not retried`, async () => {
    let calls = 0;
    const adapter = provider.factory({
      fetcher: () => {
        calls++;
        throw Object.assign(new Error(marker), { name: marker, cause: { code: marker } });
      },
    });
    const error = await assertRejects(
      () => adapter.structured({ ...request, model: provider.model, apiKey: provider.key }),
      ModelCallError,
      "provider_unreachable",
    );
    assertEquals(error.message.includes(marker), false);
    assertEquals(calls, 1);
    const malformed = provider.factory({ fetcher: () => Promise.resolve(new Response(marker)) });
    await assertRejects(
      () => malformed.structured({ ...request, model: provider.model, apiKey: provider.key }),
      ModelCallError,
      "provider_invalid_envelope",
    );
  });

  Deno.test(`${provider.name} real extract core enforces its unchanged Zod schema after adapter decoding`, async () => {
    const adapter = provider.factory({
      fetcher: (_url, init) => {
        const body = JSON.parse(init!.body as string);
        return Promise.resolve(
          response(provider.name, { ok: marker }, undefined, body.tools?.[0]?.name),
        );
      },
    });
    const port = {
      structured<T>(call: Parameters<ReturnType<typeof createProductionLlm>["structured"]>[0]) {
        return adapter.structured<T>({ ...call, model: provider.model, apiKey: provider.key });
      },
    };
    await assertRejects(() =>
      runExtract({
        dreamId: "11111111-1111-4111-8111-111111111111",
        dream: { raw_text: "synthetic", recall_answers: null },
      }, port), z.ZodError);
  });
}

Deno.test("Groq schema-400 fallback shares the two-retry budget and text 400 fails immediately", async () => {
  const formats: string[] = [];
  const delays: number[] = [];
  const statuses = [503, 400, 429, 429];
  const adapter = createGroqAdapter({
    sleep: (ms) => {
      delays.push(ms);
      return Promise.resolve();
    },
    fetcher: (_url, init) => {
      formats.push(JSON.parse(init!.body as string).response_format.type);
      return Promise.resolve(new Response(marker, { status: statuses.shift()! }));
    },
  });
  await assertRejects(
    () => adapter.structured({ ...request, model: providers[0].model, apiKey: providers[0].key }),
    ModelCallError,
    "provider_http_429",
  );
  assertEquals(formats, ["json_schema", "json_schema", "json_object", "json_object"]);
  assertEquals(delays, [500, 1000]);
  let calls = 0;
  const textAdapter = createGroqAdapter({
    fetcher: () => {
      calls++;
      return Promise.resolve(new Response(marker, { status: 400 }));
    },
  });
  await assertRejects(
    () =>
      textAdapter.text({
        model: providers[0].model,
        apiKey: providers[0].key,
        system: "synthetic",
        user: "synthetic",
        temperature: 0,
        maxTokens: 10,
      }),
    ModelCallError,
    "provider_http_400",
  );
  assertEquals(calls, 1);
});

Deno.test("Anthropic requires the selected tool once and OpenAI never falls back on schema-400", async () => {
  for (
    const content of [[], [{ type: "tool_use", name: "wrong", input: {} }], [{
      type: "tool_use",
      name: request.schemaName,
      input: {},
    }, { type: "tool_use", name: request.schemaName, input: {} }]]
  ) {
    const adapter = createAnthropicAdapter({
      fetcher: () =>
        Promise.resolve(
          new Response(JSON.stringify({ content, usage: { input_tokens: 1, output_tokens: 1 } })),
        ),
    });
    await assertRejects(
      () => adapter.structured({ ...request, model: providers[1].model, apiKey: providers[1].key }),
      ModelCallError,
      "provider_missing_tool_output",
    );
  }
  let calls = 0;
  const adapter = createOpenAiAdapter({
    fetcher: () => {
      calls++;
      return Promise.resolve(new Response(marker, { status: 400 }));
    },
  });
  await assertRejects(
    () => adapter.structured({ ...request, model: providers[2].model, apiKey: providers[2].key }),
    ModelCallError,
    "provider_http_400",
  );
  assertEquals(calls, 1);
});

Deno.test("role port routes structured and text to selected provider without cross-provider fallback", async () => {
  const urls: string[] = [];
  const port = createProductionLlm(
    (key) => key === "MODEL_WRITE" ? "anthropic:claude-sonnet-5" : undefined,
    {
      readSecret: (name) => name === "ANTHROPIC_API_KEY" ? providers[1].key : providers[0].key,
      fetcher: (url, init) => {
        urls.push(String(url));
        const body = JSON.parse(init!.body as string);
        return Promise.resolve(
          response(
            String(url).includes("anthropic") ? "anthropic" : "groq",
            { ok: true },
            "tools" in body || "response_format" in body ? undefined : "synthetic prose",
          ),
        );
      },
    },
  );
  await port.structured({ ...request, role: "write" });
  await port.structured({ ...request, role: "plan" });
  assertEquals(
    (await port.text({
      role: "write",
      system: "synthetic",
      user: "synthetic",
      temperature: 0.5,
      maxTokens: 32,
    })).text,
    "synthetic prose",
  );
  assertEquals(urls, [
    "https://api.anthropic.com/v1/messages",
    "https://api.groq.com/openai/v1/chat/completions",
    "https://api.anthropic.com/v1/messages",
  ]);
});

Deno.test("registry verifies model availability, provider isolation, alias pricing and unknown cost", () => {
  assertEquals(resolveModel("openai:gpt-4.1").id, "gpt-4.1-2025-04-14");
  assertEquals(resolveModel("anthropic:claude-sonnet-5").features.temperature, false);
  assertEquals(estimatedCostKrw("groq:openai/gpt-oss-20b", 1e6, 1e6), 525);
  assertEquals(estimatedCostKrw("anthropic:claude-sonnet-5", 1e6, 1e6), 16800);
  assertEquals(estimatedCostKrw("openai:gpt-4.1-2025-04-14", 1e6, 1e6), 14000);
  assertEquals(priceFor("gpt-4.1"), priceFor("openai:gpt-4.1-2025-04-14"));
  assertEquals(priceFor("unregistered"), undefined);
  assertEquals(estimatedCostKrw("unregistered", 1e6, 1e6), 0);
  assertEquals(priceFor("openai:openai/gpt-oss-20b"), undefined);
  assert(resolveModel("groq:openai/gpt-oss-120b").source.startsWith("https://"));
});

Deno.test("new providers reject refusals and truncated output without exposing content", async () => {
  for (const stop_reason of ["max_tokens", "refusal"]) {
    const adapter = createAnthropicAdapter({
      fetcher: () =>
        Promise.resolve(
          new Response(
            JSON.stringify({
              stop_reason,
              content: [{ type: "text", text: marker }],
              usage: { input_tokens: 1, output_tokens: 1 },
            }),
          ),
        ),
    });
    const error = await assertRejects(
      () =>
        adapter.text({
          model: providers[1].model,
          apiKey: providers[1].key,
          system: "synthetic",
          user: marker,
          temperature: 0.5,
          maxTokens: 32,
        }),
      ModelCallError,
    );
    assertEquals(error.message.includes(marker), false);
  }
  for (const message of [{ content: marker, refusal: marker }, { content: marker }]) {
    const adapter = createOpenAiAdapter({
      fetcher: () =>
        Promise.resolve(
          new Response(
            JSON.stringify({
              choices: [{ message, finish_reason: "refusal" in message ? "stop" : "length" }],
            }),
          ),
        ),
    });
    const error = await assertRejects(
      () =>
        adapter.text({
          model: providers[2].model,
          apiKey: providers[2].key,
          system: "synthetic",
          user: marker,
          temperature: 0.5,
          maxTokens: 32,
        }),
      ModelCallError,
    );
    assertEquals(error.message.includes(marker), false);
  }
});

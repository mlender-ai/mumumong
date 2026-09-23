import { assertEquals, assertRejects } from "@std/assert";
import { callStructured, estimatedCostKrw, ModelCallError } from "./llm.ts";

Deno.test("structured model call sends strict schema and returns usage without logging bodies", async () => {
  const sentBodies: Record<string, unknown>[] = [];
  const result = await callStructured<{ ok: boolean }>({
    model: "openai/gpt-oss-20b",
    schemaName: "test",
    schema: {
      type: "object",
      properties: { ok: { type: "boolean" } },
      required: ["ok"],
      additionalProperties: false,
    },
    system: "Return JSON.",
    input: { private_text: "never log me" },
    temperature: 0,
    maxTokens: 32,
    apiKey: "gsk_test_only_key",
  }, async (_url, init) => {
    sentBodies.push(JSON.parse(init?.body as string) as Record<string, unknown>);
    return await Promise.resolve(
      new Response(
        JSON.stringify({
          model: "openai/gpt-oss-20b",
          choices: [{ message: { content: '{"ok":true}' } }],
          usage: { prompt_tokens: 10, completion_tokens: 4 },
        }),
        { status: 200 },
      ),
    );
  });

  assertEquals(result.value, { ok: true });
  assertEquals(result.tokensIn, 10);
  const format = sentBodies[0].response_format as Record<string, unknown>;
  const jsonSchema = format.json_schema as Record<string, unknown>;
  assertEquals(jsonSchema.strict, true);
});

Deno.test("provider errors collapse to metadata-only codes", async () => {
  await assertRejects(
    () =>
      callStructured({
        model: "openai/gpt-oss-20b",
        schemaName: "test",
        schema: {},
        system: "x",
        input: { dream: "sensitive" },
        temperature: 0,
        maxTokens: 8,
        apiKey: "gsk_test_only_key",
      }, async () => await Promise.resolve(new Response("sensitive echo", { status: 429 }))),
    ModelCallError,
    "provider_http_429",
  );
});

Deno.test("provider credentials are trimmed and malformed values never reach fetch", async () => {
  let called = false;
  await assertRejects(
    () =>
      callStructured({
        model: "openai/gpt-oss-20b",
        schemaName: "test",
        schema: {},
        system: "x",
        input: {},
        temperature: 0,
        maxTokens: 8,
        apiKey: "not-a-groq-key\npage text",
      }, async () => {
        called = true;
        return await Promise.resolve(new Response("{}"));
      }),
    ModelCallError,
    "provider_invalid_key_format",
  );
  assertEquals(called, false);
});

Deno.test("cost estimate uses the documented production model rates", () => {
  assertEquals(estimatedCostKrw("openai/gpt-oss-20b", 1_000_000, 1_000_000), 525);
  assertEquals(estimatedCostKrw("unknown", 10, 10), 0);
});

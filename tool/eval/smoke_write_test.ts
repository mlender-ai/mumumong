import { assertEquals, assertRejects } from "@std/assert";
import { z } from "zod";
import { createProductionLlm } from "../../supabase/functions/_shared/llm/port.ts";
import { WRITE_SYSTEM } from "../../supabase/functions/_shared/prompts/write.v1.ts";
import { FixtureLlm } from "./fixture_llm.ts";
import { main, smokeWrite } from "./smoke_write.ts";

Deno.test("E4 smoke routes only write to Anthropic with frozen prompt and prints metadata only", async () => {
  let calls = 0;
  const fixture = new FixtureLlm();
  const port = createProductionLlm(
    (name) => name === "MODEL_WRITE" ? "anthropic:claude-sonnet-5" : undefined,
    {
      readSecret: () => "sk-ant-synthetic_key",
      fetcher: async (url, init) => {
        calls++;
        assertEquals(String(url), "https://api.anthropic.com/v1/messages");
        const body = JSON.parse(init!.body as string);
        assertEquals(body.system, WRITE_SYSTEM);
        const result = await fixture.structured({
          role: "write",
          system: body.system,
          schema: {},
          schemaName: body.tools[0].name,
          input: JSON.parse(body.messages[0].content),
          temperature: 0.75,
          maxTokens: 5000,
        });
        return new Response(
          JSON.stringify({
            model: "claude-sonnet-5",
            content: [{ type: "tool_use", name: body.tools[0].name, input: result.value }],
            usage: { input_tokens: 100, output_tokens: 50 },
          }),
        );
      },
    },
  );
  const result = await smokeWrite(port);
  assertEquals(calls, 1);
  assertEquals(result.status, "success");
  assertEquals(result.model, "anthropic:claude-sonnet-5");
  assertEquals(result.prompt_version, "write.v10");
  assertEquals([result.passage_count, result.tokens_in, result.tokens_out], [7, 100, 50]);
  assertEquals(
    Object.keys(result).sort(),
    [
      "event",
      "status",
      "model",
      "prompt_version",
      "calls",
      "passage_count",
      "tokens_in",
      "tokens_out",
      "latency_ms",
    ].sort(),
  );
});

Deno.test("E4 smoke rejects an adapter-decoded output that violates the existing stage contract", async () => {
  await assertRejects(
    () =>
      smokeWrite({
        structured: () =>
          Promise.resolve({
            value: {} as never,
            model: "synthetic",
            tokensIn: 0,
            tokensOut: 0,
            latencyMs: 0,
          }),
      }),
    z.ZodError,
  );
});

Deno.test("live E4 smoke preflight fails closed without credentials and redacts malformed model settings", async () => {
  const messages: string[] = [];
  const log = (value: string) => {
    messages.push(value);
  };
  assertEquals(
    await main((name) => name === "MODEL_WRITE" ? "anthropic:claude-sonnet-5" : undefined, log),
    1,
  );
  assertEquals(JSON.parse(messages[0]).code, "provider_not_configured");
  assertEquals(await main(() => "SYNTHETIC_PRIVATE_SETTING", log), 1);
  assertEquals(messages.some((value) => value.includes("SYNTHETIC_PRIVATE_SETTING")), false);
});

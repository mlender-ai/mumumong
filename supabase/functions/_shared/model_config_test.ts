import { assertEquals, assertThrows } from "@std/assert";
import { configuredModel, DEFAULT_MODELS, engineVersion } from "./model_config.ts";
import { createProductionLlm } from "./llm_adapter.ts";
import { assertRejects } from "@std/assert";
import { ModelCallError } from "./llm.ts";
import type { ModelRole } from "./llm_port.ts";

Deno.test("model role defaults preserve all existing Groq mappings", () => {
  const light = ["extract", "link", "write_aux", "remember", "judge"];
  for (const role of Object.keys(DEFAULT_MODELS) as ModelRole[]) {
    assertEquals(configuredModel(role, () => undefined), {
      provider: "groq",
      model: light.includes(role) ? "openai/gpt-oss-20b" : "openai/gpt-oss-120b",
    });
  }
  assertEquals(engineVersion(() => undefined), "v10");
  assertEquals(engineVersion(() => " v11 "), "v11");
});

Deno.test("role overrides are isolated and malformed configuration never echoes its value", async () => {
  const env = (key: string) => key === "MODEL_WRITE" ? "anthropic:synthetic-model" : undefined;
  assertEquals(configuredModel("write", env), { provider: "anthropic", model: "synthetic-model" });
  assertEquals(configuredModel("plan", env).provider, "groq");
  assertThrows(
    () => configuredModel("write", () => "sensitive value"),
    Error,
    "model_config_invalid",
  );
  await assertRejects(
    () =>
      createProductionLlm(env).structured({
        role: "write",
        schemaName: "synthetic",
        schema: {},
        system: "synthetic",
        input: {},
        temperature: 0,
        maxTokens: 1,
      }),
    ModelCallError,
    "provider_not_supported",
  );
});

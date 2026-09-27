import { assertEquals } from "@std/assert";
import { corsHeaders, corsPreflight, json } from "./pipeline.ts";

Deno.test("browser function responses expose the required CORS headers", () => {
  const response = json({ ok: true });
  assertEquals(response.headers.get("access-control-allow-origin"), "*");
  assertEquals(
    response.headers.get("access-control-allow-headers"),
    corsHeaders["access-control-allow-headers"],
  );
});

Deno.test("OPTIONS is answered without invoking function behavior", () => {
  const response = corsPreflight(
    new Request("https://example.test/functions/v1/engine-worker", {
      method: "OPTIONS",
    }),
  );
  assertEquals(response?.status, 204);
  assertEquals(response?.headers.get("access-control-allow-origin"), "*");
});

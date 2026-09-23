import { assertEquals } from "@std/assert";
import { isTerminalFailure, retryDelaySeconds, stageFunction } from "./worker.ts";

Deno.test("worker retry schedule is bounded", () => {
  assertEquals([1, 2, 3, 99].map(retryDelaySeconds), [1, 4, 15, 15]);
});

Deno.test("worker routes only implemented pipeline stages", () => {
  assertEquals(stageFunction("extract"), "engine-extract");
  assertEquals(stageFunction("link_patch"), null);
});

Deno.test("worker retries transient failures but stops on stage, client, or attempt terminal", () => {
  assertEquals(isTerminalFailure(500, 1, false), false);
  assertEquals(isTerminalFailure(null, 2, false), false);
  assertEquals(isTerminalFailure(400, 1, false), true);
  assertEquals(isTerminalFailure(500, 3, false), true);
  assertEquals(isTerminalFailure(200, 1, true), true);
});

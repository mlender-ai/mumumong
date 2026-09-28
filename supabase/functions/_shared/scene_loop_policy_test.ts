import { assertEquals } from "@std/assert";
import {
  fallbackTarget,
  sceneLoopNext,
  validationProfile,
  writeState,
} from "./scene_loop_policy.ts";

Deno.test("shared scene loop preserves every regular, fallback and terminal branch", () => {
  for (const action of ["retry", "regenerate_passages"] as const) {
    for (const attempt of [0, 1, 2]) {
      assertEquals(sceneLoopNext(action, attempt, false), {
        stage: "write",
        writeAttempt: attempt + 1,
        isFallback: attempt === 2,
        terminal: false,
      });
    }
    assertEquals(sceneLoopNext(action, 3, true).terminal, true);
  }
  for (const isFallback of [true, false]) {
    assertEquals(sceneLoopNext("accept", 3, isFallback).stage, "commit");
    assertEquals(sceneLoopNext("discard", 0, isFallback).terminal, true);
  }
});

Deno.test("shared write defaults, relaxed profile and fallback length stay unchanged", () => {
  assertEquals(writeState({}), { writeAttempt: 0, isFallback: false });
  assertEquals(writeState({ write_attempt: 3, is_fallback: true }), {
    writeAttempt: 3,
    isFallback: true,
  });
  assertEquals(validationProfile(false), "strict");
  assertEquals(validationProfile(true), "relaxed");
  assertEquals(fallbackTarget(1201), 720);
  assertEquals(fallbackTarget(0), 1);
});

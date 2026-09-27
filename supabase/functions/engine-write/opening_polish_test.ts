import { assertEquals } from "@std/assert";
import type { WriteOutput } from "../_shared/stage_contracts.ts";
import { shouldUsePolishedOpening } from "./opening_polish.ts";

function output(paragraphs: number, chars: number): WriteOutput {
  return {
    scene: { title: "책상", kind: "prologue", placement: "continuation", open_image: "책상" },
    passages: Array.from({ length: paragraphs }, (_, index) => ({
      origin: "D" as const,
      text: "가".repeat(Math.floor(chars / paragraphs) + (index < chars % paragraphs ? 1 : 0)),
      source_element_ids: ["00000000-0000-4000-8000-000000000001"],
      c_reason: null,
    })),
    new_entities: [],
    used_entities: [],
    open_image: "책상",
  };
}

Deno.test("opening polish must keep the scene substantial and mobile-readable", () => {
  const current = output(8, 600);
  assertEquals(shouldUsePolishedOpening(current, output(8, 560), 700), true);
  assertEquals(shouldUsePolishedOpening(current, output(8, 480), 700), false);
  assertEquals(shouldUsePolishedOpening(current, output(6, 600), 700), false);
  assertEquals(shouldUsePolishedOpening(current, output(10, 600), 700), false);
});

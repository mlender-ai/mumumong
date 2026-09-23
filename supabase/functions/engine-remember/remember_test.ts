import { assertEquals } from "@std/assert";
import { blendGenreProfile, normalizeMemory } from "./remember.ts";

Deno.test("memory caps story and threads while preferring open threads", () => {
  const memory = normalizeMemory({
    story_so_far: "가".repeat(1600),
    open_threads: [
      ...Array.from(
        { length: 5 },
        (_, index) => ({ id: `o${index}`, text: "열림", status: "open" as const }),
      ),
      { id: "c1", text: "닫힘", status: "closed" },
    ],
    genre_scores: {
      mystery: 0,
      surreal: 0,
      drama: 0,
      romance: 0,
      horror: 0,
      fantasy: 0,
      sf: 0,
    },
    motifs: [],
  });
  assertEquals([...memory.story_so_far].length, 1500);
  assertEquals(memory.open_threads.length, 5);
  assertEquals(memory.open_threads.every((thread) => thread.status === "open"), true);
});

Deno.test("genre profile uses the fixed 70/30 blend", () => {
  assertEquals(blendGenreProfile({ mystery: 0.5 }, { mystery: 1, drama: 0.5 }), {
    mystery: 0.65,
    drama: 0.15,
  });
});

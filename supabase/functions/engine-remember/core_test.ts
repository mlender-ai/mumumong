import { assertEquals } from "@std/assert";
import { FakeLlm, TEST_ELEMENT_ID } from "../_shared/testing/fake_llm.ts";
import { REMEMBER_SYSTEM } from "../_shared/prompts/remember.v1.ts";
import { runRemember } from "./core.ts";

Deno.test("remember core preserves request, memory version and genre blending", async () => {
  const llm = new FakeLlm([{
    story_so_far: "synthetic summary",
    open_threads: [{ id: "t1", text: "synthetic thread", status: "open" }],
    genre_scores: { mystery: 0, surreal: 0, drama: 0, romance: 0, horror: 0, fantasy: 0, sf: 0 },
    motifs: ["synthetic"],
  }]);
  const previous = {
    version: 2,
    story_so_far: "",
    open_threads: [],
    world_rules: ["rule"],
    motifs: [],
  };
  const committedScene = {
    id: TEST_ELEMENT_ID,
    title: "구슬",
    open_image: "synthetic",
    passages: [],
  };
  const core = await runRemember(
    { committedScene, previous, previousProfile: { mystery: 0.8 } },
    llm,
  );
  assertEquals(core.nextVersion, 3);
  assertEquals(core.worldRules, ["rule"]);
  assertEquals(core.genreProfile.mystery, 0.56);
  assertEquals(llm.calls[0].input, { previous, committed_scene: committedScene });
  assertEquals([
    llm.calls[0].role,
    llm.calls[0].system,
    llm.calls[0].temperature,
    llm.calls[0].maxTokens,
  ], ["remember", REMEMBER_SYSTEM, 0.2, 1800]);
});

import { assertEquals } from "@std/assert";
import { fallbackTarget, toSceneDraft } from "./write.ts";

Deno.test("write normalization removes null optionals and preserves provenance", () => {
  const draft = toSceneDraft({
    scene: { title: "문", kind: "dream", placement: "continuation", open_image: "문이 흔들렸다" },
    passages: [{
      origin: "D",
      text: "물이 찼다.",
      source_element_ids: ["00000000-0000-4000-8000-000000000001"],
      c_reason: null,
    }],
    new_entities: [{
      role_name: "우산 든 여자",
      type: "person",
      description: null,
      aliases: [],
      from_element: "00000000-0000-4000-8000-000000000001",
    }],
    used_entities: [],
    open_image: "문이 흔들렸다",
  });
  assertEquals("c_reason" in (draft.passages as Record<string, unknown>[])[0], false);
  assertEquals(fallbackTarget(1201), 720);
});

Deno.test("write normalization drops used entity ids the model was not given", () => {
  const known = "00000000-0000-4000-8000-000000000101";
  const unknown = "00000000-0000-4000-8000-000000000202";
  const draft = toSceneDraft({
    scene: { title: "문", kind: "dream", placement: "continuation", open_image: "문" },
    passages: [{
      origin: "D",
      text: "문이 열렸다.",
      source_element_ids: ["00000000-0000-4000-8000-000000000001"],
      c_reason: null,
    }],
    new_entities: [],
    used_entities: [known, unknown],
    open_image: "문",
  }, { validEntityIds: new Set([known]) });
  assertEquals(draft.used_entities, [known]);
});

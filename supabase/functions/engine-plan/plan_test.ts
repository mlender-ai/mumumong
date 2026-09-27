import { assertEquals } from "@std/assert";
import { enforcePlan, nextSceneOrderKey, normalizeSceneTitle } from "./plan.ts";

Deno.test("plan clamps length, adaptation beats, and invalid fragment targets", () => {
  const invalid = enforcePlan({
    placement: "fragment_attach",
    attach_to_scene_id: "00000000-0000-4000-8000-000000000009",
    beats: [{ kind: "D", element_ids: ["00000000-0000-4000-8000-000000000001"], note: "x" }],
    target_length: 9000,
    scene_title: "문",
  }, { lengthCap: 700, cRatioMax: 0.15, validSceneIds: new Set() });
  assertEquals(invalid.placement, "standalone");
  assertEquals(invalid.beats, []);
  assertEquals(invalid.target_length, 700);
});

Deno.test("the first dream is always planned as a manuscript prologue", () => {
  const elementId = "00000000-0000-4000-8000-000000000001";
  const first = enforcePlan({
    placement: "standalone",
    attach_to_scene_id: null,
    beats: [],
    target_length: 900,
    scene_title: "첫 문",
  }, {
    lengthCap: 1000,
    cRatioMax: 0.35,
    validSceneIds: new Set(),
    isFirstDream: true,
    firstDreamElementIds: [elementId],
    firstDreamElements: [{
      label: "여왕개미의 책상",
      type: "object",
      salience: "high",
    }],
    rawText: "여왕개미의 책상을 가져왔다.",
  });
  assertEquals(first.placement, "continuation");
  assertEquals(first.beats, [{
    kind: "D",
    element_ids: [elementId],
    note: "사용자의 의도와 행동으로 여는 첫 장면",
  }]);
  assertEquals(first.scene_title, "여왕개미의 책상");
});

Deno.test("meta titles fall back to a concrete high-salience dream image", () => {
  assertEquals(
    normalizeSceneTitle("첫 꿈의 서막", [
      { label: "남자친구", type: "person", salience: "high" },
      { label: "여왕개미의 책상", type: "object", salience: "high" },
    ]),
    "여왕개미의 책상",
  );
  assertEquals(normalizeSceneTitle("붉은 책상", []), "붉은 책상");
});

Deno.test("the first title uses an exact possessed object phrase from the source", () => {
  assertEquals(
    normalizeSceneTitle("어두운 책상", [
      { label: "여왕개미", type: "person", salience: "high" },
      { label: "책상", type: "object", salience: "high" },
    ], {
      preferSourceImage: true,
      rawText: "남자친구에게 주려고 여왕개미의 책상을 가져왔다.",
    }),
    "여왕개미의 책상",
  );
});

Deno.test("the source possessive title survives coarse element extraction", () => {
  assertEquals(
    normalizeSceneTitle("어두움", [
      { label: "남자친구", type: "person", salience: "high" },
      { label: "작은 책상", type: "object", salience: "high" },
    ], {
      preferSourceImage: true,
      rawText: "여왕개미의 책상이 딱 맞을 것 같아서 가져왔다.",
    }),
    "여왕개미의 책상",
  );
});

Deno.test("scene order keys advance deterministically", () => {
  assertEquals(nextSceneOrderKey(["s0001", "s0010", "intro"]), "s0011");
});

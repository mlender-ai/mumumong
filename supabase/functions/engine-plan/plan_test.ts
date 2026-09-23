import { assertEquals } from "@std/assert";
import { enforcePlan, nextSceneOrderKey } from "./plan.ts";

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

Deno.test("scene order keys advance deterministically", () => {
  assertEquals(nextSceneOrderKey(["s0001", "s0010", "intro"]), "s0011");
});

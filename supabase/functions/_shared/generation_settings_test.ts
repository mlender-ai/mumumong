import { assertEquals, assertStrictEquals, assertThrows } from "@std/assert";
import { pinnedGenerationVolume } from "./generation_settings.ts";

const current = {
  adaptation: "balanced",
  style: "lyrical",
  narrative_voice: "third_person_past",
  genre_profile: { mystery: 0.8 },
  genre_directive: { mode: "keep" },
};
const snapshot = {
  version: 1,
  adaptation: "faithful",
  style: "plain",
  narrative_voice: "first_person_past",
};

Deno.test("pinned preferences override current preferences only; baseline input stays unchanged", () => {
  assertStrictEquals(pinnedGenerationVolume(current, {}), current);
  assertEquals(
    pinnedGenerationVolume(current, {
      generation_settings_version: 1,
      generation_settings: snapshot,
    }),
    {
      ...current,
      adaptation: "faithful",
      style: "plain",
      narrative_voice: "first_person_past",
    },
  );
  assertEquals(current.style, "lyrical");
});
Deno.test("malformed or mismatched snapshots fail closed", () => {
  for (
    const raw of [
      null,
      [],
      4,
      { ...snapshot, version: 0 },
      { ...snapshot, version: 1.5 },
      { ...snapshot, adaptation: "unknown" },
      { ...snapshot, style: "unknown" },
      { ...snapshot, narrative_voice: "unknown" },
    ]
  ) {
    assertThrows(() => pinnedGenerationVolume(current, { generation_settings: raw }));
  }
  assertThrows(() =>
    pinnedGenerationVolume(current, {
      generation_settings_version: 2,
      generation_settings: snapshot,
    })
  );
});

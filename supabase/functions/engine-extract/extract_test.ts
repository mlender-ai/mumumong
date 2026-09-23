import { assertEquals } from "@std/assert";
import { normalizeExtract, postgresSpan } from "./extract.ts";

Deno.test("extract normalizes unicode spans and applies clarity boundaries", () => {
  const output = normalizeExtract("🌙 붉은 문이 열리고 물이 찼다", {
    elements: [
      {
        type: "object",
        label: "붉은 문",
        detail: null,
        salience: "high",
        source: "raw",
        span: null,
      },
      { type: "event", label: "열리고", detail: null, salience: "mid", source: "raw", span: null },
      {
        type: "event",
        label: "물이 찼다",
        detail: null,
        salience: "mid",
        source: "raw",
        span: null,
      },
      {
        type: "emotion",
        label: "불안",
        detail: null,
        salience: "low",
        source: "recall",
        span: [1, 2],
      },
    ],
    clarity: "vivid",
    empty_slots: [],
    sensitive_flags: [],
  });
  assertEquals(output.elements[0].span, [2, 6]);
  assertEquals(output.elements[3].span, null);
  assertEquals(output.clarity, "partial");
  assertEquals(postgresSpan(output.elements[0].span), "[2,6)");
});

Deno.test("three elements remain fragment even with three events", () => {
  const output = normalizeExtract("달렸다 넘어졌다 일어났다", {
    elements: ["달렸다", "넘어졌다", "일어났다"].map((label) => ({
      type: "event" as const,
      label,
      detail: null,
      salience: "mid" as const,
      source: "raw" as const,
      span: null,
    })),
    clarity: "vivid",
    empty_slots: [],
    sensitive_flags: [],
  });
  assertEquals(output.clarity, "fragment");
});

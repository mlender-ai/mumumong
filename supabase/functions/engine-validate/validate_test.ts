import { assert, assertEquals, assertFalse } from "@std/assert";
import type { DreamElement, RegistryEntity } from "../_shared/contract.ts";
import { lengthCapFor } from "../_shared/contract.ts";
import { lockedPassageHash } from "../_shared/text.ts";
import {
  auditRecord,
  measureCRatio,
  type ValidateInput,
  validateSceneDraft,
  type ViolationCode,
} from "./validate.ts";

const UMBRELLA = "11111111-1111-4111-8111-111111111111";
const CORRIDOR = "22222222-2222-4222-8222-222222222222";
const STAIRS = "33333333-3333-4333-8333-333333333333";

const ELEMENTS: DreamElement[] = [
  { id: UMBRELLA, label: "붉은 우산", salience: "high" },
  { id: CORRIDOR, label: "복도", salience: "mid" },
];

const REGISTRY: RegistryEntity[] = [
  { id: "44444444-4444-4444-8444-444444444444", role_name: "우산 든 여자", aliases: ["그 여자"] },
];

/// 60 characters of D text and 20 of C text: a 25% C ratio, inside `balanced`.
const DREAM_TEXT =
  "복도에 물이 차 있었다. 붉은 우산이 천장에 매달려 천천히 돌고 있었다. 물은 발목을 넘었다.";
const ADAPTED_TEXT = "그 복도는 이층의 복도와 닮아 있었다.";

function baseDraft(): Record<string, unknown> {
  return {
    scene: { placement: "continuation", title: "붉은 문" },
    passages: [
      { origin: "D", text: DREAM_TEXT, source_element_ids: [UMBRELLA, CORRIDOR] },
      { origin: "C", text: ADAPTED_TEXT, c_reason: "이층 복도와 오늘의 복도를 잇는 전이" },
    ],
    open_image: "문틈으로 새어 나오는 물소리",
  };
}

function input(overrides: Partial<ValidateInput> = {}): ValidateInput {
  return {
    draft: baseDraft(),
    clarity: "partial",
    adaptation: "balanced",
    elements: ELEMENTS,
    registry: REGISTRY,
    ...overrides,
  };
}

function codes(violations: readonly { code: ViolationCode }[]): ViolationCode[] {
  return violations.map((violation) => violation.code).sort();
}

Deno.test("a conforming draft is accepted", async () => {
  const result = await validateSceneDraft(input());
  assert(result.ok, `expected accept, got ${JSON.stringify(codes(result.violations))}`);
  assertEquals(result.action, "accept");
  assertEquals(result.violations.length, 0);
});

// --- The seven injected violations (WO-E5 completion condition) ---

Deno.test("V1 detects a draft that breaks the schema", async () => {
  const draft = baseDraft();
  delete draft.open_image;
  const result = await validateSceneDraft(input({ draft }));
  assertEquals(codes(result.violations), ["V1"]);
  assertEquals(result.action, "retry");
});

Deno.test("V2 detects a C ratio over the adaptation budget", async () => {
  const draft = baseDraft();
  // Swap the origins so 60 of 80 characters are adaptation: 75% > 35%.
  draft.passages = [
    { origin: "C", text: DREAM_TEXT, c_reason: "전이" },
    { origin: "D", text: ADAPTED_TEXT, source_element_ids: [UMBRELLA] },
  ];
  const result = await validateSceneDraft(input({ draft }));
  assert(codes(result.violations).includes("V2"));
  assertEquals(result.action, "retry");
});

Deno.test("V3 detects an entity in neither today's elements nor the registry", async () => {
  const draft = baseDraft();
  draft.new_entities = [{ role_name: "계단 아래의 아이" }];
  const result = await validateSceneDraft(input({ draft }));
  assertEquals(codes(result.violations), ["V3"]);
});

Deno.test("V3 rejects used entity ids outside the volume registry", async () => {
  const draft = baseDraft();
  draft.used_entities = [STAIRS];
  const result = await validateSceneDraft(input({ draft }));
  assertEquals(codes(result.violations), ["V3"]);
});

Deno.test("V4 detects a draft over the clarity length cap", async () => {
  const cap = lengthCapFor("partial", "balanced");
  const draft = baseDraft();
  draft.passages = [
    { origin: "D", text: "물".repeat(cap + 1), source_element_ids: [UMBRELLA, CORRIDOR] },
  ];
  const result = await validateSceneDraft(input({ draft }));
  const violation = result.violations.find((entry) => entry.code === "V4");
  assert(violation, "expected V4");
  assertEquals(violation.observed, cap + 1);
  assertEquals(violation.allowed, cap);
});

Deno.test("V5 detects an unused high-salience element", async () => {
  const draft = baseDraft();
  // Provenance cites only the mid-salience element.
  draft.passages = [
    { origin: "D", text: DREAM_TEXT, source_element_ids: [CORRIDOR] },
    { origin: "C", text: ADAPTED_TEXT, c_reason: "전이" },
  ];
  const result = await validateSceneDraft(input({ draft }));
  assertEquals(codes(result.violations), ["V5"]);
});

Deno.test("V6 discards a draft that carries a U passage", async () => {
  const draft = baseDraft();
  (draft.passages as unknown[]).push({ origin: "U", text: "내가 직접 쓴 문단." });
  const result = await validateSceneDraft(input({ draft }));
  assertEquals(codes(result.violations), ["V6"]);
  assertEquals(result.action, "discard");
});

Deno.test("V7 detects a banned meta-dream expression", async () => {
  const draft = baseDraft();
  // The D passage stays long enough that the C ratio remains inside budget,
  // so V7 is the only violation and its narrower action survives.
  draft.passages = [
    {
      origin: "D",
      text: "눈을 떠보니 " + DREAM_TEXT,
      source_element_ids: [UMBRELLA, CORRIDOR],
    },
    { origin: "C", text: ADAPTED_TEXT, c_reason: "전이" },
  ];
  const result = await validateSceneDraft(input({ draft }));
  const violation = result.violations.find((entry) => entry.code === "V7");
  assert(violation, "expected V7");
  assertEquals(violation.passageIndices, [0]);
  assertEquals(result.action, "regenerate_passages");
});

// --- V6 hash path and boundary behavior ---

Deno.test("V6 discards a draft that reproduces a locked passage", async () => {
  const locked = "내가 직접 이어 쓴 문단이다.";
  const draft = baseDraft();
  draft.passages = [
    { origin: "D", text: DREAM_TEXT, source_element_ids: [UMBRELLA, CORRIDOR] },
    // Same text, whitespace reflowed: the hash normalizes, so this still trips.
    { origin: "C", text: "내가 직접   이어 쓴 문단이다.", c_reason: "전이" },
  ];
  const result = await validateSceneDraft(
    input({ draft, lockedPassageHashes: [await lockedPassageHash(locked)] }),
  );
  assertEquals(codes(result.violations), ["V6"]);
  assertEquals(result.action, "discard");
});

Deno.test("every banned expression is caught", async () => {
  const samples = [
    "그는 꿈에서 깨어 물을 마셨다.",
    "복도는 마치 꿈처럼 길었다.",
    "그것은 꿈이었다고 그는 생각했다.",
    "눈을 떠보니 아침이었다.",
    "꿈속에서 본 계단이 있었다.",
  ];
  for (const sample of samples) {
    const draft = baseDraft();
    draft.passages = [{ origin: "D", text: sample, source_element_ids: [UMBRELLA, CORRIDOR] }];
    const result = await validateSceneDraft(input({ draft }));
    assert(
      result.violations.some((entry) => entry.code === "V7"),
      `expected V7 for: ${sample}`,
    );
  }
});

Deno.test("faithful budget rejects a ratio that balanced accepts", async () => {
  // 25% C: inside balanced (35%), over faithful (15%).
  const balanced = await validateSceneDraft(input({ adaptation: "balanced" }));
  assertFalse(balanced.violations.some((entry) => entry.code === "V2"));

  const faithful = await validateSceneDraft(input({ adaptation: "faithful" }));
  assert(faithful.violations.some((entry) => entry.code === "V2"));
});

Deno.test("free admits an invented entity only when the adaptation introduced it", async () => {
  const draft = baseDraft();
  draft.new_entities = [{ role_name: "계단 아래의 아이" }];
  draft.passages = [
    { origin: "D", text: DREAM_TEXT, source_element_ids: [UMBRELLA, CORRIDOR] },
    { origin: "C", text: "계단 아래의 아이가 물을 보고 있었다.", c_reason: "전이" },
  ];

  const free = await validateSceneDraft(input({ draft, adaptation: "free" }));
  assertFalse(free.violations.some((entry) => entry.code === "V3"));

  // The same draft in balanced is a V3: only `free` may invent a named entity.
  const balanced = await validateSceneDraft(input({ draft, adaptation: "balanced" }));
  assert(balanced.violations.some((entry) => entry.code === "V3"));
});

Deno.test("an entity resolved through from_element passes V3", async () => {
  const draft = baseDraft();
  draft.new_entities = [{ role_name: "천장의 우산", from_element: UMBRELLA }];
  const result = await validateSceneDraft(input({ draft }));
  assertFalse(result.violations.some((entry) => entry.code === "V3"));
});

Deno.test("an entity resolved through a registry alias passes V3", async () => {
  const draft = baseDraft();
  draft.new_entities = [{ role_name: "그 여자" }];
  const result = await validateSceneDraft(input({ draft }));
  assertFalse(result.violations.some((entry) => entry.code === "V3"));
});

// --- E5-relaxed fallback profile ---

Deno.test("relaxed applies V1, V3 and V6 only", async () => {
  const draft = baseDraft();
  // Over budget, over length, missing high salience, and a banned expression.
  draft.passages = [
    { origin: "C", text: "눈을 떠보니 " + "물".repeat(4000), c_reason: "전이" },
  ];
  const relaxed = await validateSceneDraft(input({ draft, profile: "relaxed" }));
  assertEquals(relaxed.violations.length, 0);
  assertEquals(relaxed.action, "accept");
  assertEquals(relaxed.profile, "relaxed");

  const strict = await validateSceneDraft(input({ draft }));
  assertEquals(codes(strict.violations), ["V2", "V4", "V5", "V7"]);
});

Deno.test("relaxed still discards a locked passage and still rejects bad schema", async () => {
  const withLocked = baseDraft();
  (withLocked.passages as unknown[]).push({ origin: "U", text: "내 문단." });
  const locked = await validateSceneDraft(input({ draft: withLocked, profile: "relaxed" }));
  assertEquals(codes(locked.violations), ["V6"]);
  assertEquals(locked.action, "discard");

  const broken = baseDraft();
  delete broken.open_image;
  const schema = await validateSceneDraft(input({ draft: broken, profile: "relaxed" }));
  assertEquals(codes(schema.violations), ["V1"]);

  const invented = baseDraft();
  invented.new_entities = [{ role_name: "계단 아래의 아이" }];
  const entity = await validateSceneDraft(input({ draft: invented, profile: "relaxed" }));
  assertEquals(codes(entity.violations), ["V3"]);
});

// --- Measurement ---

Deno.test("measureCRatio counts code points, not UTF-16 units", () => {
  const draft = {
    scene: { placement: "standalone" as const },
    passages: [
      { origin: "D" as const, text: "𝑎𝑏", source_element_ids: [UMBRELLA] },
      { origin: "C" as const, text: "𝑐𝑑" },
    ],
    open_image: "x",
  };
  // Four astral characters: eight UTF-16 units, four code points.
  const { cRatio, totalChars } = measureCRatio(draft);
  assertEquals(totalChars, 4);
  assertEquals(cRatio, 0.5);
});

Deno.test("a D passage without provenance is rejected even without high salience", async () => {
  const draft = baseDraft();
  draft.passages = [
    { origin: "D", text: DREAM_TEXT },
    { origin: "C", text: ADAPTED_TEXT, c_reason: "전이" },
  ];
  for (const profile of ["strict", "relaxed"] as const) {
    const result = await validateSceneDraft(input({ draft, elements: [], profile }));
    assertEquals(codes(result.violations), ["V1"]);
  }
});

Deno.test("unknown provenance is rejected in strict and fallback profiles", async () => {
  for (const profile of ["strict", "relaxed"] as const) {
    const result = await validateSceneDraft(input({ elements: [], profile }));
    assert(result.violations.some((entry) => entry.code === "V1"));
  }
});

Deno.test("an element list with no high salience never trips V5", async () => {
  const draft = baseDraft();
  draft.passages = [{ origin: "D", text: DREAM_TEXT, source_element_ids: [STAIRS] }];
  const result = await validateSceneDraft(
    input({ draft, elements: [{ id: STAIRS, label: "계단", salience: "low" }] }),
  );
  assertFalse(result.violations.some((entry) => entry.code === "V5"));
});

// --- Audit record must never carry dream or generated text ---

Deno.test("auditRecord keeps codes and counts but drops messages", async () => {
  const draft = baseDraft();
  draft.new_entities = [{ role_name: "계단 아래의 아이" }];
  draft.passages = [
    { origin: "D", text: "눈을 떠보니 " + DREAM_TEXT, source_element_ids: [CORRIDOR] },
    { origin: "C", text: ADAPTED_TEXT, c_reason: "전이" },
  ];

  const result = await validateSceneDraft(input({ draft }));
  const audit = auditRecord(result);

  // The violations themselves quote the element and entity for the retry prompt.
  assert(result.violations.some((entry) => entry.message.includes("붉은 우산")));
  assert(result.violations.some((entry) => entry.message.includes("계단 아래의 아이")));

  // The audit row must not. It is what reaches generation_runs and the logs.
  const serialized = JSON.stringify(audit);
  assertFalse(serialized.includes("붉은 우산"));
  assertFalse(serialized.includes("계단 아래의 아이"));
  assertFalse(serialized.includes(DREAM_TEXT));
  assertFalse(serialized.includes(ADAPTED_TEXT));
  assertFalse(serialized.includes("message"));

  assertEquals(audit.codes, ["V3", "V5", "V7"]);
  assertEquals(audit.ok, false);
  assertEquals(audit.action, "retry");
  assertEquals(audit.total_chars, result.totalChars);
});

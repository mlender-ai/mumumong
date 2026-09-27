import { assertEquals, assertThrows } from "@std/assert";
import type { WriteOutput } from "../_shared/stage_contracts.ts";
import {
  aggregateModelResults,
  expandedOpening,
  needsOpeningExpansion,
  prepareOpeningProvenance,
} from "./opening_expansion.ts";

const output: WriteOutput = {
  scene: { title: "책상", kind: "prologue", placement: "continuation", open_image: "책상" },
  passages: [{
    origin: "D",
    text: "짧은 문단",
    source_element_ids: ["00000000-0000-4000-8000-000000000001"],
    c_reason: null,
  }],
  new_entities: [],
  used_entities: [],
  open_image: "책상",
};

Deno.test("a short first scene requests passage expansion", () => {
  assertEquals(needsOpeningExpansion(output, true, 700), true);
  assertEquals(needsOpeningExpansion(output, false, 700), false);
  assertEquals(
    needsOpeningExpansion(
      {
        ...output,
        passages: [{ ...output.passages[0], text: "가".repeat(490) }],
      },
      true,
      700,
    ),
    false,
  );
});

Deno.test("opening expansion changes only passage text", () => {
  const plan = prepareOpeningProvenance(output, []);
  const expanded = expandedOpening(plan, ["확장된 문단"]);
  assertEquals(expanded.passages[0], { ...output.passages[0], text: "확장된 문단" });
  assertThrows(() => expandedOpening(plan, []), Error, "opening_expansion_count");
});

Deno.test("missing high-salience provenance is kept only when expansion names it", () => {
  const highId = "00000000-0000-4000-8000-000000000002";
  const plan = prepareOpeningProvenance(output, [{
    id: highId,
    label: "여왕개미의 책상",
    salience: "high",
  }]);
  assertEquals(plan.requiredLabels, [["여왕개미의 책상"]]);
  assertEquals(plan.output.passages[0].source_element_ids.includes(highId), true);

  const named = expandedOpening(plan, ["나는 여왕개미의 책상을 바라보았다."]);
  assertEquals(named.passages[0].source_element_ids.includes(highId), true);
  const unnamed = expandedOpening(plan, ["나는 커다란 물건을 바라보았다."]);
  assertEquals(unnamed.passages[0].source_element_ids.includes(highId), false);
});

Deno.test("model usage includes the opening expansion calls", () => {
  const result = aggregateModelResults({
    value: output,
    model: "quality",
    tokensIn: 10,
    tokensOut: 20,
    latencyMs: 30,
  }, [{
    value: { text: "확장" },
    model: "quality",
    tokensIn: 2,
    tokensOut: 3,
    latencyMs: 4,
  }]);
  assertEquals(result.tokensIn, 12);
  assertEquals(result.tokensOut, 23);
  assertEquals(result.latencyMs, 34);
});

import { assertEquals } from "@std/assert";
import { chooseDecisions, normalizeLabel, ruleMatch } from "./link.ts";

const element = {
  id: "00000000-0000-4000-8000-000000000001",
  type: "person",
  label: "우산 든 여자는",
};
const entity = {
  id: "00000000-0000-4000-8000-000000000002",
  type: "person",
  role_name: "우산 든 여자",
  aliases: ["복도의 여자"],
};

Deno.test("link rules handle exact aliases and normalized Korean particles", () => {
  assertEquals(normalizeLabel("우산 든 여자는"), "우산든여자");
  const result = ruleMatch([element], [entity]);
  assertEquals(result.accepted[0].confidence, 0.85);
  assertEquals(result.ambiguous.length, 0);
});

Deno.test("link decisions auto all strong matches and cap pending to one", () => {
  const decisions = chooseDecisions([
    { element_id: "e1", entity_id: "n1", confidence: 0.95, reason: "exact" },
    { element_id: "e2", entity_id: "n2", confidence: 0.51, reason: "weak" },
    { element_id: "e3", entity_id: "n3", confidence: 0.79, reason: "best" },
  ]);
  assertEquals(decisions.auto.length, 1);
  assertEquals(decisions.pending?.element_id, "e3");
});

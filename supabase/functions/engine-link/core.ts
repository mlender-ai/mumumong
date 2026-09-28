import { modelRun, type StructuredLlmPort, type StructuredResult } from "../_shared/llm_port.ts";
import { LINK_PROMPT_VERSION, LINK_SYSTEM } from "../_shared/prompts/link.v1.ts";
import {
  linkJsonSchema,
  type LinkModelOutput,
  linkModelOutputSchema,
} from "../_shared/stage_contracts.ts";
import { chooseDecisions, type LinkElement, type LinkEntity, ruleMatch } from "./link.ts";
export interface LinkCoreInput {
  elements: LinkElement[];
  entities: LinkEntity[];
  dreamId: string;
  volumeId: string;
}
export async function runLink(
  { elements, entities, dreamId, volumeId }: LinkCoreInput,
  llm: StructuredLlmPort,
) {
  const rules = ruleMatch(elements, entities);

  let modelResult: StructuredResult<LinkModelOutput> | null = null;
  if (rules.ambiguous.length > 0) {
    modelResult = await llm.structured<LinkModelOutput>({
      role: "link",
      schemaName: "mumumong_link_v1",
      schema: linkJsonSchema,
      system: LINK_SYSTEM,
      input: { ambiguous: rules.ambiguous },
      temperature: 0,
      maxTokens: 1000,
    });
    linkModelOutputSchema.parse(modelResult.value);
  }
  const decisions = chooseDecisions([
    ...rules.accepted,
    ...(modelResult?.value.matches ?? []),
  ]);

  const rows: Record<string, unknown>[] = decisions.auto.map((match) => ({
    volume_id: volumeId,
    dream_id: dreamId,
    kind: "entity_merge",
    status: "auto",
    payload: match,
    decided_at: new Date().toISOString(),
  }));
  if (decisions.pending) {
    const pendingElement = elements.find((item) => item.id === decisions.pending!.element_id);
    const pendingEntity = entities.find((item) => item.id === decisions.pending!.entity_id);
    rows.push({
      volume_id: volumeId,
      dream_id: dreamId,
      kind: "entity_merge",
      status: "pending",
      payload: {
        ...decisions.pending,
        question: `오늘 꿈의 '${pendingElement?.label ?? "요소"}', 원고의 '${
          pendingEntity?.role_name ?? "대상"
        }'과 같은 대상일까요?`,
        element_label: pendingElement?.label,
        entity_role_name: pendingEntity?.role_name,
      },
      decided_at: null,
    });
  }

  const links = [
    ...decisions.auto.map((match) => ({ ...match, status: "auto" })),
    ...(decisions.pending ? [{ ...decisions.pending, status: "pending" }] : []),
  ];

  return {
    decisions,
    rows,
    modelRuns: modelResult ? [modelRun("link", LINK_PROMPT_VERSION, modelResult)] : [],
    nextPayloadPatch: { link_complete: true, links },
  };
}

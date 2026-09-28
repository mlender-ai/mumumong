import { type LlmPort, type ModelRun, modelRun } from "../_shared/llm_port.ts";
import type { DreamContext } from "../_shared/stage_context.ts";
import { EXTRACT_PROMPT_VERSION, EXTRACT_SYSTEM } from "../_shared/prompts/extract.v1.ts";
import { extractJsonSchema, extractOutputSchema } from "../_shared/stage_contracts.ts";
import { deterministicUuid } from "../_shared/uuid.ts";
import { normalizeExtract, postgresSpan } from "./extract.ts";

export interface ExtractCoreInput {
  dreamId: string;
  dream: DreamContext;
}
export async function runExtract({ dreamId, dream }: ExtractCoreInput, llm: LlmPort) {
  const result = await llm.structured<unknown>({
    role: "extract",
    schemaName: "mumumong_extract_v1",
    schema: extractJsonSchema,
    system: EXTRACT_SYSTEM,
    input: { raw_text: dream.raw_text, recall_answers: dream.recall_answers ?? {} },
    temperature: 0,
    maxTokens: 1600,
  });
  const parsed = extractOutputSchema.parse(result.value);
  const normalized = normalizeExtract(dream.raw_text as string, parsed);
  const rows = await Promise.all(normalized.elements.map(async (element, index) => ({
    id: await deterministicUuid(
      `element:${dreamId}:${index}:${element.source}:${element.type}:${element.label}`,
    ),
    dream_id: dreamId,
    type: element.type,
    label: element.label,
    detail: element.detail,
    salience: element.salience,
    source: element.source,
    span: postgresSpan(element.span),
  })));

  const elements = rows.map(({ dream_id: _dreamId, ...element }) => element);
  const modelRuns: ModelRun[] = [modelRun("extract", EXTRACT_PROMPT_VERSION, result)];
  return {
    normalized,
    rows,
    modelRuns,
    nextPayloadPatch: {
      extract_complete: true,
      elements,
      clarity: normalized.clarity,
      empty_slots: normalized.empty_slots,
      sensitive_flags: normalized.sensitive_flags,
    },
  };
}

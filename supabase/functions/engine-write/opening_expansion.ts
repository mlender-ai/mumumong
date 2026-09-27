import type { StructuredResult } from "../_shared/llm.ts";
import type { WriteOutput } from "../_shared/stage_contracts.ts";
import { countChars } from "../_shared/text.ts";

export const OPENING_EXPANSION_SCHEMA: Record<string, unknown> = {
  type: "object",
  properties: {
    text: { type: "string" },
  },
  required: ["text"],
  additionalProperties: false,
};

export const OPENING_EXPANSION_SYSTEM =
  `당신은 꿈을 바탕으로 쓴 연재소설 첫 장면의 문단 하나를 확장한다.
JSON의 text 하나만 출력한다. 80~120자의 한국어 소설 문단으로 쓴다.
입력 문단의 사건, 행위자, 대상, 목적, 시점, 시제와 origin을 바꾸지 않는다.
required_labels가 있으면 모든 표기를 글자 그대로 문단에 포함한다. 다른 말로 바꾸거나 생략하지 않는다.
같은 사실을 되풀이하거나 의미를 해설하지 말고, 인물의 관찰·판단·동작이 이어지는 현재의 장면으로 만든다.
origin=D이면 raw_text와 source_elements에 있는 사실만 쓴다. 크기·색·감정·대사·소유 관계를 새로 만들지 않는다.
origin=C이면 연결에 필요한 감각이나 즉각적인 변화만 보탠다. 새 인물, 새 사건, 꿈 해석, 결말을 만들지 않는다.
앞뒤 문단을 복사하지 않고 자연스럽게 이어지게 한다. “꿈”, 교훈, 요약을 언급하지 않는다.`;

type OpeningElement = {
  readonly id: string;
  readonly label: string;
  readonly salience: string;
};

export type OpeningProvenancePlan = {
  readonly output: WriteOutput;
  readonly requiredLabels: readonly (readonly string[])[];
  readonly addedIds: readonly (readonly string[])[];
};

export function prepareOpeningProvenance(
  output: WriteOutput,
  elements: readonly OpeningElement[],
): OpeningProvenancePlan {
  const used = new Set(output.passages.flatMap((passage) => passage.source_element_ids));
  const missing = elements.filter((element) =>
    element.salience === "high" && !used.has(element.id)
  );
  const dreamIndices = output.passages.flatMap((passage, index) =>
    passage.origin === "D" ? [index] : []
  );
  const requiredLabels = output.passages.map((): string[] => []);
  const addedIds = output.passages.map((): string[] => []);
  const passages = output.passages.map((passage) => ({ ...passage }));
  if (dreamIndices.length > 0) {
    for (let index = 0; index < missing.length; index += 1) {
      const element = missing[index];
      const passageIndex = dreamIndices[index % dreamIndices.length];
      passages[passageIndex] = {
        ...passages[passageIndex],
        source_element_ids: [...passages[passageIndex].source_element_ids, element.id],
      };
      requiredLabels[passageIndex].push(element.label);
      addedIds[passageIndex].push(element.id);
    }
  }
  return {
    output: { ...output, passages },
    requiredLabels,
    addedIds,
  };
}

export function needsOpeningExpansion(
  output: WriteOutput,
  isFirstScene: boolean,
  targetLength: number,
): boolean {
  if (!isFirstScene) return false;
  const total = output.passages.reduce((sum, passage) => sum + countChars(passage.text), 0);
  return total < Math.max(350, Math.floor(targetLength * 0.7));
}

export function expandedOpening(
  plan: OpeningProvenancePlan,
  texts: readonly string[],
): WriteOutput {
  const output = plan.output;
  if (texts.length !== output.passages.length) {
    throw new Error("opening_expansion_count");
  }
  return {
    ...output,
    passages: output.passages.map((passage, index) => ({
      ...passage,
      text: texts[index].trim(),
      source_element_ids: passage.source_element_ids.filter((id) => {
        const addedIndex = plan.addedIds[index].indexOf(id);
        return addedIndex < 0 || texts[index].includes(plan.requiredLabels[index][addedIndex]);
      }),
    })),
  };
}

export function aggregateModelResults<T>(
  primary: StructuredResult<T>,
  additional: readonly StructuredResult<unknown>[],
): StructuredResult<T> {
  return {
    ...primary,
    tokensIn: primary.tokensIn + additional.reduce((sum, result) => sum + result.tokensIn, 0),
    tokensOut: primary.tokensOut + additional.reduce((sum, result) => sum + result.tokensOut, 0),
    latencyMs: primary.latencyMs + additional.reduce((sum, result) => sum + result.latencyMs, 0),
  };
}

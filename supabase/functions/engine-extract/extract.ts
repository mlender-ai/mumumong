import type { ExtractOutput } from "../_shared/stage_contracts.ts";

export function normalizeExtract(rawText: string, output: ExtractOutput): ExtractOutput {
  const chars = [...rawText.normalize("NFC")];
  const elements = output.elements.map((element) => {
    if (element.source !== "raw") return { ...element, span: null };
    const label = [...element.label.normalize("NFC")];
    if (label.length === 0) return { ...element, span: null };

    let start = -1;
    for (let index = 0; index <= chars.length - label.length; index += 1) {
      if (label.every((char, offset) => chars[index + offset] === char)) {
        start = index;
        break;
      }
    }
    return {
      ...element,
      span: start < 0 ? null : [start, start + label.length] as [number, number],
    };
  });

  const events = elements.filter((element) => element.type === "event").length;
  const clarity = elements.length <= 3
    ? "fragment"
    : events === 0
    ? "fragment"
    : events <= 2
    ? "partial"
    : "vivid";
  return { ...output, elements, clarity };
}

export function postgresSpan(span: [number, number] | null): string | null {
  return span ? `[${span[0]},${span[1]})` : null;
}

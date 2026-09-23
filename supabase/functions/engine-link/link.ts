export interface LinkElement {
  readonly id: string;
  readonly type: string;
  readonly label: string;
  readonly detail?: string | null;
}

export interface LinkEntity {
  readonly id: string;
  readonly type: string;
  readonly role_name: string;
  readonly aliases?: readonly string[];
  readonly description?: string | null;
}

export interface LinkMatch {
  readonly element_id: string;
  readonly entity_id: string;
  readonly confidence: number;
  readonly reason: string;
}

const PARTICLES = /(은|는|이|가|을|를|과|와|의|에|에서|으로|로)$/u;

export function normalizeLabel(value: string): string {
  return value.normalize("NFC").toLowerCase().replace(/\s+/gu, "").replace(PARTICLES, "");
}

export function ruleMatch(elements: readonly LinkElement[], entities: readonly LinkEntity[]): {
  accepted: LinkMatch[];
  ambiguous: { element: LinkElement; candidates: LinkEntity[] }[];
} {
  const accepted: LinkMatch[] = [];
  const ambiguous: { element: LinkElement; candidates: LinkEntity[] }[] = [];

  for (const element of elements) {
    const candidates = entities.filter((entity) => entity.type === element.type);
    let best: LinkMatch | null = null;
    for (const entity of candidates) {
      const aliases = entity.aliases ?? [];
      let confidence = 0;
      let reason = "";
      if (element.label === entity.role_name) {
        confidence = 0.95;
        reason = "label_exact";
      } else if (aliases.includes(element.label)) {
        confidence = 0.90;
        reason = "alias_exact";
      } else {
        const needle = normalizeLabel(element.label);
        const names = [entity.role_name, ...aliases].map(normalizeLabel);
        if (names.includes(needle)) {
          confidence = 0.85;
          reason = "normalized_exact";
        } else if (names.some((name) => name.includes(needle) || needle.includes(name))) {
          confidence = 0.60;
          reason = "substring";
        }
      }
      if (confidence > (best?.confidence ?? 0)) {
        best = { element_id: element.id, entity_id: entity.id, confidence, reason };
      }
    }
    if (best && best.confidence >= 0.85) accepted.push(best);
    else if (candidates.length > 0) ambiguous.push({ element, candidates });
  }
  return { accepted, ambiguous };
}

export function chooseDecisions(matches: readonly LinkMatch[]): {
  auto: LinkMatch[];
  pending: LinkMatch | null;
} {
  const auto = matches.filter((match) => match.confidence >= 0.85);
  const pending = matches
    .filter((match) => match.confidence >= 0.50 && match.confidence < 0.85)
    .sort((a, b) => b.confidence - a.confidence)[0] ?? null;
  return { auto, pending };
}

// WO-E5 · Validate
//
// Rule-based validation of an E4 scene draft. Every check in this file is
// deterministic: no model is called, so the same draft always validates the
// same way and the checks are testable without a provider.
//
// Scope note: PDR §24 assigns a lightweight model to part of V5 (judging that a
// high-salience element was used meaningfully, not merely referenced) and part
// of V7 (real-name exposure and the §25 safety bar). Those refinements are not
// implemented here because no model provider is configured yet. What is
// implemented is the structural core of both, which is sound on its own:
// V5 reads declared provenance (`source_element_ids`), which is stronger
// evidence than the string matching PDR §24 calls insufficient, and V7 applies
// the banned-expression regexes from the work order.

import {
  ADAPTATION_BUDGETS,
  type AdaptationLevel,
  type Clarity,
  type DreamElement,
  lengthCapFor,
  type RegistryEntity,
  type SceneDraft,
  sceneDraftSchema,
} from "../_shared/contract.ts";
import { countChars, lockedPassageHash } from "../_shared/text.ts";

export const VIOLATION_CODES = ["V1", "V2", "V3", "V4", "V5", "V6", "V7"] as const;
export type ViolationCode = (typeof VIOLATION_CODES)[number];

/// `discard` is V6 only: a draft that carries a locked passage is a bug, not a
/// retryable generation. `regenerate_passages` is V7's narrower remedy.
export type ValidationAction = "accept" | "retry" | "regenerate_passages" | "discard";

export interface Violation {
  readonly code: ViolationCode;
  /// Written for the E4 retry prompt, so it may name elements and entities.
  /// Never pass this to `logEvent`: it can carry generated content.
  readonly message: string;
  readonly passageIndices?: readonly number[];
  readonly observed?: number;
  readonly allowed?: number;
}

/// `relaxed` is the `E5-relaxed` fallback profile: V1, V3 and V6 only. Rejecting
/// a fallback draft on budget or length would leave the user with nothing.
export type ValidationProfile = "strict" | "relaxed";

export interface ValidationOutcome {
  readonly ok: boolean;
  readonly action: ValidationAction;
  readonly violations: readonly Violation[];
  readonly cRatio: number;
  readonly totalChars: number;
  readonly profile: ValidationProfile;
}

export interface ValidateInput {
  /// Raw E4 output. Unvalidated on purpose — V1 is what validates it.
  readonly draft: unknown;
  readonly clarity: Clarity;
  readonly adaptation: AdaptationLevel;
  readonly elements: readonly DreamElement[];
  readonly registry: readonly RegistryEntity[];
  /// Hashes of the `U` passages in the target scene, via `lockedPassageHash`.
  readonly lockedPassageHashes?: readonly string[];
  readonly profile?: ValidationProfile;
}

export const BANNED_EXPRESSIONS: readonly RegExp[] = [
  /꿈(에서|을)\s*(깨|깨어)/u,
  /마치\s*꿈\s*처럼/u,
  /그것은\s*꿈이었/u,
  /눈을\s*떠보니/u,
  /꿈속에서/u,
];

const ACTION_RANK: Readonly<Record<ValidationAction, number>> = {
  accept: 0,
  regenerate_passages: 1,
  retry: 2,
  discard: 3,
};

function strongerAction(a: ValidationAction, b: ValidationAction): ValidationAction {
  return ACTION_RANK[a] >= ACTION_RANK[b] ? a : b;
}

function normalizeName(value: string): string {
  return value.normalize("NFC").replace(/\s+/gu, "").toLowerCase();
}

function outcome(
  violations: readonly Violation[],
  cRatio: number,
  totalChars: number,
  profile: ValidationProfile,
): ValidationOutcome {
  let action: ValidationAction = "accept";
  for (const violation of violations) {
    const candidate: ValidationAction = violation.code === "V6"
      ? "discard"
      : violation.code === "V7"
      ? "regenerate_passages"
      : "retry";
    action = strongerAction(action, candidate);
  }
  return { ok: violations.length === 0, action, violations, cRatio, totalChars, profile };
}

/// V2 numerator/denominator. Exported so E6 can record the same `c_ratio` the
/// draft was validated against into `generation_runs`.
export function measureCRatio(draft: SceneDraft): { cRatio: number; totalChars: number } {
  let total = 0;
  let adapted = 0;
  for (const passage of draft.passages) {
    const chars = countChars(passage.text);
    total += chars;
    if (passage.origin === "C") adapted += chars;
  }
  return { cRatio: total === 0 ? 0 : adapted / total, totalChars: total };
}

export async function validateSceneDraft(input: ValidateInput): Promise<ValidationOutcome> {
  const profile = input.profile ?? "strict";

  // V1 — schema. Nothing else can run against an unparsed draft.
  const parsed = sceneDraftSchema.safeParse(input.draft);
  if (!parsed.success) {
    const paths = parsed.error.issues
      .map((issue) => issue.path.join(".") || "(root)")
      .slice(0, 5);
    return outcome(
      [{
        code: "V1",
        message: `출력이 스키마를 위반했다: ${paths.join(", ")}`,
        observed: parsed.error.issues.length,
      }],
      0,
      0,
      profile,
    );
  }

  const draft = parsed.data;
  const { cRatio, totalChars } = measureCRatio(draft);

  // V6 — a locked passage in the output is discarded immediately, so it
  // short-circuits before the retryable checks.
  const v6 = await checkLockedPassages(draft, input.lockedPassageHashes ?? []);
  if (v6) return outcome([v6], cRatio, totalChars, profile);

  const violations: Violation[] = [];
  const knownElements = new Set(input.elements.map((element) => element.id));
  if (
    draft.passages.some((passage) =>
      (passage.source_element_ids ?? []).some((id) => !knownElements.has(id))
    )
  ) {
    violations.push({ code: "V1", message: "출처 요소가 현재 꿈에 존재하지 않는다." });
  }

  // V3 runs in both profiles: an invented entity is never acceptable output.
  violations.push(...checkNewEntities(draft, input));

  if (profile === "strict") {
    const budget = ADAPTATION_BUDGETS[input.adaptation];

    if (cRatio > budget.cRatioMax) {
      violations.push({
        code: "V2",
        message: `연결 문장 비율이 예산을 초과했다 (${Math.round(cRatio * 100)}% > ${
          Math.round(budget.cRatioMax * 100)
        }%)`,
        observed: cRatio,
        allowed: budget.cRatioMax,
      });
    }

    const cap = lengthCapFor(input.clarity, input.adaptation);
    if (totalChars > cap) {
      violations.push({
        code: "V4",
        message: `총 길이가 상한을 초과했다 (${totalChars}자 > ${cap}자)`,
        observed: totalChars,
        allowed: cap,
      });
    }

    violations.push(...checkHighSalienceUsage(draft, input.elements));
    violations.push(...checkBannedExpressions(draft));
  }

  return outcome(violations, cRatio, totalChars, profile);
}

async function checkLockedPassages(
  draft: SceneDraft,
  lockedHashes: readonly string[],
): Promise<Violation | null> {
  const userAuthored = draft.passages
    .map((passage, index) => ({ passage, index }))
    .filter((entry) => entry.passage.origin === "U")
    .map((entry) => entry.index);

  if (userAuthored.length > 0) {
    return {
      code: "V6",
      message: "생성 출력에 U 문단이 포함되었다. 잠긴 문단은 입력으로만 참조한다.",
      passageIndices: userAuthored,
      observed: userAuthored.length,
    };
  }

  if (lockedHashes.length === 0) return null;

  const locked = new Set(lockedHashes);
  const reproduced: number[] = [];
  for (let index = 0; index < draft.passages.length; index += 1) {
    const hash = await lockedPassageHash(draft.passages[index].text);
    if (locked.has(hash)) reproduced.push(index);
  }

  if (reproduced.length === 0) return null;
  return {
    code: "V6",
    message: "생성 출력이 잠긴 문단을 재현했다.",
    passageIndices: reproduced,
    observed: reproduced.length,
  };
}

function checkNewEntities(draft: SceneDraft, input: ValidateInput): Violation[] {
  const entities = draft.new_entities ?? [];
  if (entities.length === 0) return [];

  const elementIds = new Set(input.elements.map((element) => element.id));
  const allowedNames = new Set<string>();
  for (const element of input.elements) allowedNames.add(normalizeName(element.label));
  for (const entity of input.registry) {
    allowedNames.add(normalizeName(entity.role_name));
    for (const alias of entity.aliases ?? []) allowedNames.add(normalizeName(alias));
  }

  const adaptedText = draft.passages
    .filter((passage) => passage.origin === "C")
    .map((passage) => passage.text.normalize("NFC"))
    .join("\n");

  const policy = ADAPTATION_BUDGETS[input.adaptation].unresolvedNamedEntity;
  const unresolved: string[] = [];

  for (const entity of entities) {
    if (entity.from_element && elementIds.has(entity.from_element)) continue;
    if (allowedNames.has(normalizeName(entity.role_name))) continue;
    // `free` admits an invented entity only when the adaptation itself
    // introduced it, which is what a C tag means (PDR §24 V3).
    if (policy === "c_tagged_only" && adaptedText.includes(entity.role_name.normalize("NFC"))) {
      continue;
    }
    unresolved.push(entity.role_name);
  }

  if (unresolved.length === 0) return [];
  return [{
    code: "V3",
    message: `오늘 요소도 레지스트리도 아닌 엔티티가 생성되었다: ${unresolved.join(", ")}`,
    observed: unresolved.length,
  }];
}

function checkHighSalienceUsage(
  draft: SceneDraft,
  elements: readonly DreamElement[],
): Violation[] {
  const used = new Set<string>();
  for (const passage of draft.passages) {
    for (const id of passage.source_element_ids ?? []) used.add(id);
  }

  const missing = elements
    .filter((element) => element.salience === "high" && !used.has(element.id))
    .map((element) => element.label);

  if (missing.length === 0) return [];
  return [{
    code: "V5",
    message: `salience가 high인 요소가 사용되지 않았다: ${missing.join(", ")}`,
    observed: missing.length,
  }];
}

function checkBannedExpressions(draft: SceneDraft): Violation[] {
  const offending: number[] = [];
  for (let index = 0; index < draft.passages.length; index += 1) {
    const text = draft.passages[index].text.normalize("NFC");
    if (BANNED_EXPRESSIONS.some((pattern) => pattern.test(text))) offending.push(index);
  }

  if (offending.length === 0) return [];
  return [{
    code: "V7",
    message: "금지된 메타 꿈 표현이 사용되었다.",
    passageIndices: offending,
    observed: offending.length,
  }];
}

/// Strips a validation outcome down to what is safe to persist in
/// `generation_runs.validation` and to log.
///
/// `Violation.message` names elements and entities so the E4 retry prompt can
/// quote them. That is generated content, and AGENTS.md forbids it in logs and
/// analytics, so it is dropped here rather than at each call site.
export function auditRecord(outcome: ValidationOutcome): Record<string, unknown> {
  return {
    ok: outcome.ok,
    action: outcome.action,
    profile: outcome.profile,
    codes: outcome.violations.map((violation) => violation.code),
    c_ratio: Number(outcome.cRatio.toFixed(4)),
    total_chars: outcome.totalChars,
    passage_indices: outcome.violations
      .flatMap((violation) => violation.passageIndices ?? [])
      .sort((a, b) => a - b),
  };
}

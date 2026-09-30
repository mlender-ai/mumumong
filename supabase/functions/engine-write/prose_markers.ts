// Q-21 parser/assembler preparation. This module is pure and does not switch
// the production v10 writer or add any model prompt.
import { type SceneDraft, sceneDraftSchema } from "../_shared/contract.ts";
import { type PlanV7, type PlanV7Beat } from "../_shared/stage_contracts.ts";

export type ProseParagraph = { beatId: string; text: string };
export type ProseParseIssue =
  | {
    code: "V1";
    kind: "unmarked" | "unknown_beat" | "multiple_markers";
    paragraph: number;
    beatId?: string;
  }
  | { code: "V5"; missingBeatIds: string[] };

type ParseCommon = {
  paragraphs: ProseParagraph[];
  orderDeviation: boolean;
};
export type ParsedProse = ParseCommon & { ok: true; issues: [] };
export type ParseResult = ParsedProse | (ParseCommon & { ok: false; issues: ProseParseIssue[] });

const marker = /^\[\[b(\d+)\]\]\s*/u;
const embeddedMarker = /\[\[b\d+\]\]/u;

export function parseProse(text: string, beats: readonly PlanV7Beat[]): ParseResult {
  if (!beats.length || beats.some((beat, index) => beat.id !== `b${index + 1}`)) {
    throw new Error("invalid_plan_beat_sequence");
  }
  const byId = new Map(beats.map((beat, index) => [beat.id, { beat, index }]));
  const paragraphs: ProseParagraph[] = [];
  const issues: ProseParseIssue[] = [];
  const usedDreamBeats = new Set<string>();
  let lastBeatIndex = -1;
  let orderDeviation = false;

  const blocks = text.trim().split(/\r?\n\s*\r?\n/u).filter((block) => block.trim());
  for (const [index, block] of blocks.entries()) {
    const trimmed = block.trim();
    const match = marker.exec(trimmed);
    if (!match) {
      issues.push({ code: "V1", kind: "unmarked", paragraph: index + 1 });
      continue;
    }
    const beatId = `b${match[1]}`;
    const body = trimmed.slice(match[0].length).trim();
    // A marker-only block is discarded, including for D coverage.
    if (!body) continue;
    const target = byId.get(beatId);
    if (!target) {
      issues.push({ code: "V1", kind: "unknown_beat", paragraph: index + 1, beatId });
      continue;
    }
    if (embeddedMarker.test(body)) {
      issues.push({ code: "V1", kind: "multiple_markers", paragraph: index + 1 });
      continue;
    }
    if (target.index < lastBeatIndex) orderDeviation = true;
    lastBeatIndex = target.index;
    if (target.beat.kind === "D") usedDreamBeats.add(beatId);
    paragraphs.push({ beatId, text: body });
  }

  const missingBeatIds = beats.filter((beat) => beat.kind === "D" && !usedDreamBeats.has(beat.id))
    .map((beat) => beat.id);
  if (missingBeatIds.length) issues.push({ code: "V5", missingBeatIds });
  return issues.length
    ? { ok: false, paragraphs, issues, orderDeviation }
    : { ok: true, paragraphs, issues: [], orderDeviation };
}

export function assembleSceneDraft(plan: PlanV7, parsed: ParsedProse): SceneDraft {
  const beats = new Map(plan.beats.map((beat) => [beat.id, beat]));
  const passages = parsed.paragraphs.map((paragraph) => {
    const beat = beats.get(paragraph.beatId);
    if (!beat) throw new Error("unknown_plan_beat");
    return {
      origin: beat.kind,
      text: paragraph.text,
      source_element_ids: [...beat.element_ids],
      ...(beat.kind === "C" ? { c_reason: beat.fact } : {}),
    };
  });
  const draft = sceneDraftSchema.safeParse({
    scene: {
      title: plan.scene_title,
      placement: plan.placement,
      open_image: plan.open_image,
    },
    passages,
    open_image: plan.open_image,
    new_entities: plan.new_entities.map((entity) => ({
      role_name: entity.role_name,
      type: entity.type,
      ...(entity.from_element ? { from_element: entity.from_element } : {}),
    })),
    used_entities: [...plan.used_entities],
  });
  if (!draft.success) throw new Error("invalid_scene_draft");
  return draft.data;
}

/// Feedback has only issue categories, paragraph indexes and beat IDs, never
/// generated prose or a dream quote.
export function formatProseParseFeedback(issues: readonly ProseParseIssue[]): string {
  const lines: string[] = [];
  const v1 = issues.filter((issue) => issue.code === "V1");
  if (v1.length) {
    lines.push("모든 문단은 [[b번호]]로 시작하고 한 문단에 비트 하나만 써야 한다.");
    const unknown = v1.filter((issue) => issue.kind === "unknown_beat")
      .map((issue) => issue.beatId).filter((id): id is string => !!id);
    if (unknown.length) lines.push(`대본에 없는 번호 ${[...new Set(unknown)].join(", ")}를 썼다.`);
    const positions = v1.filter((issue) => issue.kind !== "unknown_beat")
      .map((issue) => issue.paragraph);
    if (positions.length) lines.push(`${positions.join(", ")}번째 문단의 표시를 고친다.`);
  }
  const missing = issues.filter((issue) => issue.code === "V5")
    .flatMap((issue) => issue.missingBeatIds);
  if (missing.length) {
    lines.push(`${[...new Set(missing)].join(", ")} 비트가 빠졌다. 모든 꿈 비트를 쓴다.`);
  }
  return lines.join(" ");
}

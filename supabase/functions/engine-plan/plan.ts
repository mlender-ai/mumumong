import type { PlanOutput } from "../_shared/stage_contracts.ts";

type TitleElement = {
  label: string;
  type?: string;
  salience?: string;
};

const META_TITLE = /(?:^첫\s*(?:문|장|꿈)|꿈의\s*(?:시작|서막)|프롤로그|서막)/u;

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/gu, "\\$&");
}

export function normalizeSceneTitle(
  title: string,
  elements: readonly TitleElement[] = [],
  options: { preferSourceImage?: boolean; rawText?: string } = {},
): string {
  const cleaned = title.trim().replace(/^["'“”‘’]+|["'“”‘’]+$/gu, "").slice(0, 24);
  if (!options.preferSourceImage && cleaned.length > 0 && !META_TITLE.test(cleaned)) {
    return cleaned;
  }

  const typeOrder = ["object", "event", "place", "sensory", "person", "emotion"];
  const candidates = [...elements]
    .filter((element) => element.label.trim().length > 0)
    .sort((left, right) => {
      const salience = Number(right.salience === "high") - Number(left.salience === "high");
      if (salience !== 0) return salience;
      const leftType = typeOrder.indexOf(left.type ?? "");
      const rightType = typeOrder.indexOf(right.type ?? "");
      return (leftType < 0 ? typeOrder.length : leftType) -
        (rightType < 0 ? typeOrder.length : rightType);
    });

  const rawText = options.rawText?.normalize("NFC") ?? "";
  const objects = candidates.filter((element) => element.type === "object");
  const people = candidates.filter((element) => element.type === "person");
  const possessedNoun =
    /([가-힣A-Za-z0-9]{1,12}의\s+[가-힣A-Za-z0-9]{1,12}?)(?:을|를|이|가|은|는|에|에서|과|와|\s|$)/u
      .exec(rawText)?.[1];
  if (possessedNoun) return possessedNoun.replace(/\s+/gu, " ").slice(0, 24);
  for (const object of objects) {
    const objectLabel = object.label.trim().replace(/[을를이가은는]$/u, "");
    const sourcePhrase = new RegExp(
      `([가-힣A-Za-z0-9]{1,12}의\\s*${escapeRegExp(objectLabel)})`,
      "u",
    ).exec(rawText)?.[1];
    if (sourcePhrase) return sourcePhrase.replace(/\s+/gu, " ").slice(0, 24);
  }
  for (const object of objects) {
    for (const person of people) {
      const possessed = `${person.label.trim()}의 ${object.label.trim()}`;
      if (rawText.includes(possessed)) return possessed.slice(0, 24);
    }
  }
  return candidates[0]?.label.trim().slice(0, 24) || "낯선 사물";
}

export function enforcePlan(
  output: PlanOutput,
  input: {
    lengthCap: number;
    cRatioMax: number;
    validSceneIds: ReadonlySet<string>;
    isFirstDream?: boolean;
    firstDreamElementIds?: readonly string[];
    firstDreamElements?: readonly TitleElement[];
    rawText?: string;
  },
): PlanOutput {
  const targetLength = Math.max(1, Math.min(output.target_length, input.lengthCap));
  const sceneTitle = normalizeSceneTitle(output.scene_title, input.firstDreamElements, {
    preferSourceImage: input.isFirstDream,
    rawText: input.rawText,
  });
  if (input.isFirstDream && output.placement === "standalone") {
    const elementIds = input.firstDreamElementIds ?? [];
    return {
      ...output,
      placement: "continuation",
      attach_to_scene_id: null,
      beats: elementIds.length > 0
        ? [{
          kind: "D",
          element_ids: [...elementIds],
          note: "사용자의 의도와 행동으로 여는 첫 장면",
        }]
        : output.beats,
      target_length: targetLength,
      scene_title: sceneTitle,
    };
  }
  if (output.placement === "standalone") {
    return {
      ...output,
      attach_to_scene_id: null,
      beats: [],
      target_length: targetLength,
      scene_title: sceneTitle,
    };
  }
  let placement: PlanOutput["placement"] = output.placement;
  let attach = output.attach_to_scene_id;
  if (placement === "fragment_attach" && (!attach || !input.validSceneIds.has(attach))) {
    placement = input.isFirstDream ? "continuation" : "standalone";
    attach = null;
  }
  if (placement === "standalone") {
    return {
      ...output,
      placement,
      attach_to_scene_id: null,
      beats: [],
      target_length: targetLength,
      scene_title: sceneTitle,
    };
  }

  const maxC = Math.floor(output.beats.length * input.cRatioMax);
  let keptC = 0;
  const beats = output.beats.filter((beat) => {
    if (beat.kind === "D") return true;
    keptC += 1;
    return keptC <= maxC;
  });
  return {
    ...output,
    placement,
    attach_to_scene_id: attach,
    beats,
    target_length: targetLength,
    scene_title: sceneTitle,
  };
}

export function nextSceneOrderKey(existing: readonly string[]): string {
  const largest = existing.reduce((max, value) => {
    const match = /^s(\d+)$/u.exec(value);
    return Math.max(max, match ? Number(match[1]) : 0);
  }, 0);
  return `s${String(largest + 1).padStart(4, "0")}`;
}

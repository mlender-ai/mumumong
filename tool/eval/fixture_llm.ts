import type {
  LlmPort,
  StructuredCall,
  StructuredResult,
} from "../../supabase/functions/_shared/llm_port.ts";
import { GENRE_KEYS } from "../../supabase/functions/_shared/stage_contracts.ts";
import { EvalError } from "./config.ts";

// This is deliberately synthetic, not a quality model. Never use it for private sets.
export class FixtureLlm implements LlmPort {
  structured<T>(request: StructuredCall): Promise<StructuredResult<T>> {
    const input = request.input as Record<string, unknown>;
    let value: unknown;
    switch (request.role) {
      case "extract": {
        const raw = input.raw_text as string;
        const label = raw.includes("파란 장갑") ? "파란 장갑" : [...raw].slice(0, 6).join("");
        value = {
          elements: [{
            type: "object",
            label,
            detail: null,
            salience: "high",
            source: "raw",
            span: null,
          }],
          clarity: "fragment",
          empty_slots: [],
          sensitive_flags: [],
        };
        break;
      }
      case "link":
        value = { matches: [] };
        break;
      case "plan":
        value = {
          placement: "continuation",
          attach_to_scene_id: null,
          beats: [{
            kind: "D",
            element_ids: (input.elements as { id: string }[]).map((element) => element.id),
            note: "synthetic fixture beat",
          }],
          target_length: 700,
          scene_title: "가짜 장면",
        };
        break;
      case "write": {
        const today = input.today as {
          elements: { id: string; label: string; type: string }[];
        };
        const registry = (input.volume_bible as { entities: { id: string }[] }).entities;
        value = {
          scene: {
            title: "가짜 장면",
            kind: "dream",
            placement: "continuation",
            open_image: "가짜 이미지",
          },
          passages: Array.from({ length: 7 }, (_, index) => ({
            origin: "D",
            text: `${today.elements[0].label} ${index + 1} `.repeat(10),
            source_element_ids: today.elements.map((element) => element.id),
            c_reason: null,
          })),
          new_entities: today.elements.map((element) => ({
            role_name: element.label,
            type: element.type,
            description: null,
            aliases: [],
            from_element: element.id,
          })),
          used_entities: registry.map((entity) => entity.id),
          open_image: "가짜 이미지",
        };
        break;
      }
      case "write_aux":
        value = { text: input.text };
        break;
      case "polish":
        value = input.expanded_draft;
        break;
      case "remember":
        value = {
          story_so_far: "synthetic fixture memory",
          open_threads: [],
          genre_scores: Object.fromEntries(GENRE_KEYS.map((key) => [key, 0])),
          motifs: [],
        };
        break;
      default:
        throw new EvalError("FIXTURE_ROLE_UNSUPPORTED");
    }
    return Promise.resolve({
      value: value as T,
      model: "fixture",
      tokensIn: 0,
      tokensOut: 0,
      latencyMs: 0,
    });
  }
}

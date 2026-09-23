import { z } from "zod";
import { CLARITIES, PLACEMENT_KINDS, SALIENCES } from "./contract.ts";

export const ELEMENT_TYPES = [
  "person",
  "place",
  "object",
  "event",
  "emotion",
  "sensory",
] as const;

export const GENRE_KEYS = [
  "mystery",
  "surreal",
  "drama",
  "romance",
  "horror",
  "fantasy",
  "sf",
] as const;

export const extractOutputSchema = z.object({
  elements: z.array(z.object({
    type: z.enum(ELEMENT_TYPES),
    label: z.string().min(1),
    detail: z.string().nullable(),
    salience: z.enum(SALIENCES),
    source: z.enum(["raw", "recall"]),
    span: z.tuple([z.number().int().nonnegative(), z.number().int().positive()]).nullable(),
  })),
  clarity: z.enum(CLARITIES),
  empty_slots: z.array(z.string()).max(3),
  sensitive_flags: z.array(z.enum(["death", "sexual", "violence"])),
});
export type ExtractOutput = z.infer<typeof extractOutputSchema>;

export const extractJsonSchema: Record<string, unknown> = {
  type: "object",
  properties: {
    elements: {
      type: "array",
      items: {
        type: "object",
        properties: {
          type: { type: "string", enum: ELEMENT_TYPES },
          label: { type: "string" },
          detail: { type: ["string", "null"] },
          salience: { type: "string", enum: SALIENCES },
          source: { type: "string", enum: ["raw", "recall"] },
          span: {
            anyOf: [
              { type: "array", items: { type: "integer" }, minItems: 2, maxItems: 2 },
              { type: "null" },
            ],
          },
        },
        required: ["type", "label", "detail", "salience", "source", "span"],
        additionalProperties: false,
      },
    },
    clarity: { type: "string", enum: CLARITIES },
    empty_slots: { type: "array", items: { type: "string" }, maxItems: 3 },
    sensitive_flags: {
      type: "array",
      items: { type: "string", enum: ["death", "sexual", "violence"] },
    },
  },
  required: ["elements", "clarity", "empty_slots", "sensitive_flags"],
  additionalProperties: false,
};

export const linkModelOutputSchema = z.object({
  matches: z.array(z.object({
    element_id: z.string().uuid(),
    entity_id: z.string().uuid(),
    confidence: z.number().min(0).max(1),
    reason: z.string(),
  })),
});
export type LinkModelOutput = z.infer<typeof linkModelOutputSchema>;

export const linkJsonSchema: Record<string, unknown> = {
  type: "object",
  properties: {
    matches: {
      type: "array",
      items: {
        type: "object",
        properties: {
          element_id: { type: "string", format: "uuid" },
          entity_id: { type: "string", format: "uuid" },
          confidence: { type: "number", minimum: 0, maximum: 1 },
          reason: { type: "string" },
        },
        required: ["element_id", "entity_id", "confidence", "reason"],
        additionalProperties: false,
      },
    },
  },
  required: ["matches"],
  additionalProperties: false,
};

export const planOutputSchema = z.object({
  placement: z.enum(PLACEMENT_KINDS),
  attach_to_scene_id: z.string().uuid().nullable(),
  beats: z.array(z.discriminatedUnion("kind", [
    z.object({
      kind: z.literal("D"),
      element_ids: z.array(z.string().uuid()).min(1),
      note: z.string(),
    }),
    z.object({ kind: z.literal("C"), element_ids: z.array(z.string().uuid()), note: z.string() }),
  ])),
  target_length: z.number().int().positive(),
  scene_title: z.string(),
});
export type PlanOutput = z.infer<typeof planOutputSchema>;

export const planJsonSchema: Record<string, unknown> = {
  type: "object",
  properties: {
    placement: { type: "string", enum: PLACEMENT_KINDS },
    attach_to_scene_id: { type: ["string", "null"], format: "uuid" },
    beats: {
      type: "array",
      items: {
        type: "object",
        properties: {
          kind: { type: "string", enum: ["D", "C"] },
          element_ids: { type: "array", items: { type: "string", format: "uuid" } },
          note: { type: "string" },
        },
        required: ["kind", "element_ids", "note"],
        additionalProperties: false,
      },
    },
    target_length: { type: "integer", minimum: 1 },
    scene_title: { type: "string" },
  },
  required: ["placement", "attach_to_scene_id", "beats", "target_length", "scene_title"],
  additionalProperties: false,
};

export const writeOutputSchema = z.object({
  scene: z.object({
    title: z.string(),
    kind: z.enum(["prologue", "dream", "interlude", "ending"]),
    placement: z.enum(PLACEMENT_KINDS),
    open_image: z.string().min(1),
  }),
  passages: z.array(z.object({
    origin: z.enum(["D", "C"]),
    text: z.string().min(1),
    source_element_ids: z.array(z.string().uuid()),
    c_reason: z.string().nullable(),
  })).min(1),
  new_entities: z.array(z.object({
    role_name: z.string().min(1),
    type: z.string(),
    description: z.string().nullable(),
    aliases: z.array(z.string()),
    from_element: z.string().uuid().nullable(),
  })),
  used_entities: z.array(z.string().uuid()),
  open_image: z.string().min(1),
});
export type WriteOutput = z.infer<typeof writeOutputSchema>;

export const writeJsonSchema: Record<string, unknown> = {
  type: "object",
  properties: {
    scene: {
      type: "object",
      properties: {
        title: { type: "string" },
        kind: { type: "string", enum: ["prologue", "dream", "interlude", "ending"] },
        placement: { type: "string", enum: PLACEMENT_KINDS },
        open_image: { type: "string" },
      },
      required: ["title", "kind", "placement", "open_image"],
      additionalProperties: false,
    },
    passages: {
      type: "array",
      minItems: 1,
      items: {
        type: "object",
        properties: {
          origin: { type: "string", enum: ["D", "C"] },
          text: { type: "string" },
          source_element_ids: { type: "array", items: { type: "string", format: "uuid" } },
          c_reason: { type: ["string", "null"] },
        },
        required: ["origin", "text", "source_element_ids", "c_reason"],
        additionalProperties: false,
      },
    },
    new_entities: {
      type: "array",
      items: {
        type: "object",
        properties: {
          role_name: { type: "string" },
          type: { type: "string" },
          description: { type: ["string", "null"] },
          aliases: { type: "array", items: { type: "string" } },
          from_element: { type: ["string", "null"], format: "uuid" },
        },
        required: ["role_name", "type", "description", "aliases", "from_element"],
        additionalProperties: false,
      },
    },
    used_entities: { type: "array", items: { type: "string", format: "uuid" } },
    open_image: { type: "string" },
  },
  required: ["scene", "passages", "new_entities", "used_entities", "open_image"],
  additionalProperties: false,
};

export const rememberOutputSchema = z.object({
  story_so_far: z.string().max(1500),
  open_threads: z.array(z.object({
    id: z.string(),
    text: z.string(),
    status: z.enum(["open", "closed"]),
  })).max(5),
  genre_scores: z.object({
    mystery: z.number().min(0).max(1),
    surreal: z.number().min(0).max(1),
    drama: z.number().min(0).max(1),
    romance: z.number().min(0).max(1),
    horror: z.number().min(0).max(1),
    fantasy: z.number().min(0).max(1),
    sf: z.number().min(0).max(1),
  }),
  motifs: z.array(z.string()),
});
export type RememberOutput = z.infer<typeof rememberOutputSchema>;

export const rememberJsonSchema: Record<string, unknown> = {
  type: "object",
  properties: {
    story_so_far: { type: "string", maxLength: 1500 },
    open_threads: {
      type: "array",
      maxItems: 5,
      items: {
        type: "object",
        properties: {
          id: { type: "string" },
          text: { type: "string" },
          status: { type: "string", enum: ["open", "closed"] },
        },
        required: ["id", "text", "status"],
        additionalProperties: false,
      },
    },
    genre_scores: {
      type: "object",
      properties: Object.fromEntries(
        GENRE_KEYS.map((key) => [key, { type: "number", minimum: 0, maximum: 1 }]),
      ),
      required: GENRE_KEYS,
      additionalProperties: false,
    },
    motifs: { type: "array", items: { type: "string" } },
  },
  required: ["story_so_far", "open_threads", "genre_scores", "motifs"],
  additionalProperties: false,
};

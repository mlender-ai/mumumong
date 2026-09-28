export interface DreamContext {
  raw_text: string;
  recall_answers: Record<string, string> | null;
  sensitive_flags?: string[];
}

export interface VolumeContext {
  adaptation: string;
  style: string;
  narrative_voice: string;
  genre_profile: Record<string, number>;
  genre_directive: unknown;
}

export interface NarrativeMemory {
  version?: number;
  story_so_far: string;
  open_threads: unknown[];
  world_rules?: unknown[];
  motifs: unknown[];
}

export interface RecentScene {
  id: string;
  order_key?: string;
  title: string | null;
  placement?: string;
  open_image: string | null;
  passages?: unknown[];
}

export interface EntityRow {
  id: string;
  type: string;
  role_name: string;
  description?: string | null;
  aliases?: string[];
  mention_count?: number;
}

export interface LockedPassage {
  text: string;
  order_key?: string;
}

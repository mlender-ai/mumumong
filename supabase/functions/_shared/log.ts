const ALLOWED_KEYS = new Set([
  "dream_id",
  "volume_id",
  "scene_id",
  "passage_id",
  "job_id",
  "user_id",
  "stage",
  "status",
  "code",
  "ms",
  "count",
  "attempt",
  "origin",
  "mode",
  "env",
]);

type LogFields = Readonly<Record<string, unknown>>;

export function logEvent(name: string, fields: LogFields = {}): void {
  const safe: Record<string, unknown> = {};

  for (const [key, value] of Object.entries(fields)) {
    if (!ALLOWED_KEYS.has(key)) continue;
    if (typeof value === "string" && value.length > 64) continue;
    safe[key] = value;
  }

  console.log(JSON.stringify({ event: name, ...safe }));
}

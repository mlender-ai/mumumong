// Character counting and hashing helpers.
//
// Never log the values passed through here: every string in this module is
// either dream text or generated manuscript text.

/// Counts Unicode code points, not UTF-16 units, so that a surrogate pair
/// (an emoji, a rare CJK glyph) counts as one character.
///
/// PDR §17 states its budgets in characters without excluding whitespace, so
/// whitespace is counted. V2 is a ratio, where the choice cancels out; V4 is
/// the cap where it matters, and counting whitespace is the stricter reading.
export function countChars(text: string): number {
  let count = 0;
  for (const _ of text) count += 1;
  return count;
}

/// Normalizes a passage before hashing so that reflowed whitespace does not
/// read as an edit. NFC keeps decomposed Hangul from hashing differently.
export function normalizeForHash(text: string): string {
  return text.normalize("NFC").replace(/\s+/gu, " ").trim();
}

export async function sha256Hex(text: string): Promise<string> {
  const bytes = new TextEncoder().encode(text);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

export async function lockedPassageHash(text: string): Promise<string> {
  return await sha256Hex(normalizeForHash(text));
}

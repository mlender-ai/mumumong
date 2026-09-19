// Deterministic UUIDs for job idempotency keys.
//
// `jobs` is unique on (user_id, idempotency_key) and, while a job is queued or
// running, on (dream_id, type). A retried stage therefore has to present the
// same key it used the first time, which rules out `crypto.randomUUID()`.

import { sha256Hex } from "./text.ts";

/// Derives a stable RFC 4122 version 5 style UUID from `name`. The same name
/// always yields the same UUID, so re-running a stage re-presents the same
/// idempotency key instead of inserting a second job.
export async function deterministicUuid(name: string): Promise<string> {
  const hex = await sha256Hex(name);
  const bytes = hex.slice(0, 32).match(/.{2}/gu)!.map((pair) => parseInt(pair, 16));

  // Version 5 in the high nibble of byte 6, RFC 4122 variant in byte 8.
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  const out = bytes.map((byte) => byte.toString(16).padStart(2, "0")).join("");
  return [
    out.slice(0, 8),
    out.slice(8, 12),
    out.slice(12, 16),
    out.slice(16, 20),
    out.slice(20, 32),
  ].join("-");
}

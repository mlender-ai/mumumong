// The job row the engine stages read their input from.
//
// WO section C states that a stage reads its input from `jobs.payload`, so the
// row is the source of truth for the owner, dream and volume — not the request
// body, which the worker composes.

import type { SupabaseClient } from "@supabase/supabase-js";

export interface EngineJob {
  readonly id: string;
  readonly user_id: string;
  readonly dream_id: string | null;
  readonly volume_id: string;
  readonly type: string;
  readonly attempt: number;
  readonly payload: Record<string, unknown>;
}

export async function loadJob(
  client: SupabaseClient,
  jobId: string,
): Promise<EngineJob | null> {
  const { data, error } = await client
    .from("jobs")
    .select("id, user_id, dream_id, volume_id, type, attempt, payload")
    .eq("id", jobId)
    .maybeSingle();

  if (error) throw new Error(`job read failed: ${error.code ?? error.message}`);
  if (!data) return null;

  return {
    id: data.id as string,
    user_id: data.user_id as string,
    dream_id: (data.dream_id ?? null) as string | null,
    volume_id: data.volume_id as string,
    type: data.type as string,
    attempt: (data.attempt ?? 0) as number,
    payload: (data.payload ?? {}) as Record<string, unknown>,
  };
}

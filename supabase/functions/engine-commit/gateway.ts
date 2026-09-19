// The live `CommitGateway`. Each method is one statement against the
// service-role client, so `commit.ts` stays the only place that decides
// anything and remains testable without a database.

import type { SupabaseClient } from "@supabase/supabase-js";
import type { CommitGateway, CommitPayload, EnqueueRequest } from "./commit.ts";

const UNIQUE_VIOLATION = "23505";

export class SupabaseCommitGateway implements CommitGateway {
  constructor(private readonly client: SupabaseClient) {}

  async commitScene(
    dreamId: string,
    volumeId: string,
    payload: CommitPayload,
  ): Promise<string> {
    const { data, error } = await this.client.rpc("commit_scene", {
      p_dream_id: dreamId,
      p_volume_id: volumeId,
      p_payload: payload,
    });
    if (error) throw new Error(`commit_scene failed: ${error.code ?? error.message}`);
    if (typeof data !== "string") throw new Error("commit_scene returned no scene id");
    return data;
  }

  async markArchivedOnly(dreamId: string): Promise<void> {
    const { error } = await this.client
      .from("dreams")
      .update({ status: "archived_only" })
      .eq("id", dreamId);
    if (error) throw new Error(`archive failed: ${error.code ?? error.message}`);
  }

  async mergeJobPayload(jobId: string, patch: Record<string, unknown>): Promise<void> {
    const { data, error } = await this.client
      .from("jobs")
      .select("payload")
      .eq("id", jobId)
      .single();
    if (error) throw new Error(`job read failed: ${error.code ?? error.message}`);

    const current = (data?.payload ?? {}) as Record<string, unknown>;
    const { error: writeError } = await this.client
      .from("jobs")
      .update({ payload: { ...current, ...patch } })
      .eq("id", jobId);
    if (writeError) throw new Error(`job write failed: ${writeError.code ?? writeError.message}`);
  }

  async enqueueJob(request: EnqueueRequest): Promise<string | null> {
    const { data, error } = await this.client
      .from("jobs")
      .insert({
        user_id: request.userId,
        dream_id: request.dreamId,
        volume_id: request.volumeId,
        type: request.type,
        status: "queued",
        idempotency_key: request.idempotencyKey,
        payload: request.payload,
      })
      .select("id")
      .single();

    if (!error) return data.id as string;

    // Either (user_id, idempotency_key) or the active (dream_id, type) index
    // already holds this job. Both mean the next stage is queued, so a retry
    // is a no-op rather than a failure.
    if (error.code === UNIQUE_VIOLATION) return null;

    throw new Error(`enqueue failed: ${error.code ?? error.message}`);
  }
}

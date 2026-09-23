import type { SupabaseClient } from "@supabase/supabase-js";
import { estimatedCostKrw, type StructuredResult } from "./llm.ts";
import { deterministicUuid } from "./uuid.ts";

const UNIQUE_VIOLATION = "23505";

export async function mergeJobPayload(
  client: SupabaseClient,
  jobId: string,
  current: Record<string, unknown>,
  patch: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const payload = { ...current, ...patch };
  const { error } = await client.from("jobs").update({ payload }).eq("id", jobId);
  if (error) throw new Error(`job_payload:${error.code ?? "write"}`);
  return payload;
}

export async function enqueueStage(
  client: SupabaseClient,
  input: {
    userId: string;
    dreamId: string;
    volumeId: string;
    type: string;
    payload: Record<string, unknown>;
    keySuffix?: string;
  },
): Promise<string | null> {
  const suffix = input.keySuffix ? `:${input.keySuffix}` : "";
  const idempotencyKey = await deterministicUuid(
    `${input.type}:${input.dreamId}${suffix}`,
  );
  const { data, error } = await client.from("jobs").insert({
    user_id: input.userId,
    dream_id: input.dreamId,
    volume_id: input.volumeId,
    type: input.type,
    status: "queued",
    idempotency_key: idempotencyKey,
    payload: input.payload,
  }).select("id").single();
  if (!error) return data.id as string;
  if (error.code === UNIQUE_VIOLATION) return null;
  throw new Error(`enqueue:${error.code ?? "write"}`);
}

export async function recordModelRun(
  client: SupabaseClient,
  input: {
    jobId: string;
    stage: string;
    promptVersion: string;
    result: StructuredResult<unknown>;
    validation?: Record<string, unknown>;
    cRatio?: number;
    isFallback?: boolean;
  },
): Promise<void> {
  const { error } = await client.from("generation_runs").insert({
    job_id: input.jobId,
    stage: input.stage,
    model: input.result.model,
    tokens_in: input.result.tokensIn,
    tokens_out: input.result.tokensOut,
    latency_ms: input.result.latencyMs,
    validation: input.validation ?? {},
    c_ratio: input.cRatio,
    cost_krw: estimatedCostKrw(
      input.result.model,
      input.result.tokensIn,
      input.result.tokensOut,
    ),
    prompt_version: input.promptVersion,
    is_fallback: input.isFallback ?? false,
  });
  if (error) throw new Error(`generation_run:${error.code ?? "write"}`);
}

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

export async function requestJobId(request: Request): Promise<string | null> {
  if (request.method !== "POST") return null;
  try {
    const body = await request.json() as Record<string, unknown>;
    return typeof body.job_id === "string" ? body.job_id : null;
  } catch {
    return null;
  }
}

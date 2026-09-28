import { z } from "zod";
import { createProductionLlm } from "../../supabase/functions/_shared/llm/port.ts";
import { resolveModel } from "../../supabase/functions/_shared/llm/registry.ts";
import { apiKey } from "../../supabase/functions/_shared/llm/transport.ts";
import {
  ModelCallError,
  type StructuredLlmPort,
} from "../../supabase/functions/_shared/llm/types.ts";
import { runWrite, type WriteCoreInput } from "../../supabase/functions/engine-write/core.ts";

// Newly invented synthetic input only; never reads corpus/holdout or writes manuscripts to a DB.
export const SMOKE_ELEMENT_ID = "11111111-1111-4111-8111-111111111111";
export const SMOKE_INPUT: WriteCoreInput = {
  dream: {
    raw_text: "나는 빈 정류장에서 파란 장갑을 주웠다. 장갑 안에는 작은 종이별이 있었다.",
    recall_answers: null,
    sensitive_flags: [],
  },
  volume: {
    adaptation: "faithful",
    style: "plain",
    narrative_voice: "first_person_past",
    genre_profile: {},
    genre_directive: null,
  },
  memory: null,
  entities: [],
  recentScenes: [],
  lockedPassages: [],
  payload: {
    is_first_dream: false,
    placement: "continuation",
    scene_title: "파란 장갑",
    target_length: 700,
    elements: [{
      id: SMOKE_ELEMENT_ID,
      type: "object",
      label: "파란 장갑",
      detail: "종이별이 들어 있다",
      salience: "high",
      source: "raw",
      span: null,
    }],
    links: [],
    beats: [{ kind: "D", element_ids: [SMOKE_ELEMENT_ID], note: "장갑을 주워 안을 확인한다" }],
  },
  writeAttempt: 0,
  isFallback: false,
};

export async function smokeWrite(llm: StructuredLlmPort) {
  const result = await runWrite(SMOKE_INPUT, llm);
  if (result.modelRuns.length !== 1 || result.modelRuns[0].role !== "write") {
    throw new ModelCallError("model_smoke_unexpected_calls");
  }
  const run = result.modelRuns[0];
  return {
    event: "e4_smoke",
    status: "success",
    model: run.model,
    prompt_version: run.promptVersion,
    calls: result.modelRuns.length,
    passage_count: result.passageCount,
    tokens_in: run.tokensIn,
    tokens_out: run.tokensOut,
    latency_ms: run.latencyMs,
  };
}

export async function main(
  read = (name: string) => Deno.env.get(name),
  log: (value: string) => void = console.log,
): Promise<number> {
  try {
    const selected = read("MODEL_WRITE");
    if (!selected || resolveModel(selected).provider !== "anthropic") {
      throw new ModelCallError("model_smoke_requires_anthropic");
    }
    apiKey("ANTHROPIC_API_KEY", /^sk-ant-[A-Za-z0-9_-]+$/u, undefined, { readSecret: read });
    log(JSON.stringify(await smokeWrite(createProductionLlm(read, { readSecret: read }))));
    return 0;
  } catch (error) {
    // No stack, Zod issues, provider body or user-supplied configuration is printed.
    const code = error instanceof z.ZodError
      ? "STAGE_SCHEMA_INVALID"
      : error instanceof ModelCallError && /^[a-z0-9_:]+$/u.test(error.code)
      ? error.code
      : "SMOKE_FAILED";
    log(JSON.stringify({ event: "e4_smoke", status: "failed", code }));
    return 1;
  }
}
if (import.meta.main) Deno.exit(await main());

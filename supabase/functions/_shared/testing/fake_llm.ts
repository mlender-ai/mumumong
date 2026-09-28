import type {
  LlmPort,
  StructuredCall,
  StructuredResult,
  TextCall,
  TextResult,
} from "../llm_port.ts";
import { DEFAULT_MODELS } from "../model_config.ts";

// Synthetic tests only; never captures production or private evaluation inputs.
export class FakeLlm implements LlmPort {
  readonly calls: StructuredCall[] = [];
  readonly textCalls: TextCall[] = [];
  constructor(private readonly outputs: unknown[]) {}
  text(request: TextCall): Promise<TextResult> {
    this.textCalls.push(request);
    const output = this.outputs.shift();
    if (output instanceof Error) return Promise.reject(output);
    if (typeof output !== "string") return Promise.reject(new Error("fake_missing_text"));
    return Promise.resolve({
      text: output,
      model: DEFAULT_MODELS[request.role].slice(5),
      tokensIn: 10,
      tokensOut: 20,
      latencyMs: 5,
    });
  }
  structured<T>(request: StructuredCall): Promise<StructuredResult<T>> {
    this.calls.push(request);
    const output = this.outputs.shift();
    if (output instanceof Error) return Promise.reject(output);
    if (output === undefined) return Promise.reject(new Error("fake_missing_output"));
    return Promise.resolve({
      value: output as T,
      model: DEFAULT_MODELS[request.role].slice(5),
      tokensIn: 10,
      tokensOut: 20,
      latencyMs: 5,
    });
  }
}

export const TEST_ELEMENT_ID = "11111111-1111-4111-8111-111111111111";
export const TEST_ENTITY_ID = "22222222-2222-4222-8222-222222222222";
export const TEST_VOLUME = {
  adaptation: "balanced",
  style: "plain",
  narrative_voice: "first_person_past",
  genre_profile: {},
  genre_directive: null,
};

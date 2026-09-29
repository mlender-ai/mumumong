import { validateCorpusTexts } from "./validate_corpus.ts";
import { parseWorks } from "./reference_contract.ts";
import { ROOT } from "./judge_inputs.ts";

// Read-only readiness metadata. Never read holdout, print data, fetch a provider or show a key.
export async function qualityPreflight(
  root = ROOT,
  readSecret = (name: string) => Deno.env.get(name),
) {
  let dev = { available: false, valid: false, cases: 0, dreams: 0, full: false };
  try {
    const text = await Deno.readTextFile(new URL("eval/corpus/dev.jsonl", root));
    const checked = validateCorpusTexts([{ text, expectedSet: "dev" }]), c = checked.summary.dev;
    dev = {
      available: true,
      valid: checked.issues.length === 0,
      cases: c.single + c.sequence,
      dreams: c.dreams,
      full: !checked.issues.length && c.single === 18 && c.sequence === 3 &&
        Object.values(c.singleClarity).every((n) => n === 6),
    };
  } catch { /* Missing/unreadable is not ready. */ }
  let reference = { available: false, valid: false, positive: 0, control: 0, directly_labeled: 0 };
  try {
    const rows = parseWorks(await Deno.readTextFile(new URL("eval/reference/works.jsonl", root)));
    reference = {
      available: true,
      valid: true,
      positive: rows.filter((r) => r.group === "positive").length,
      control: rows.filter((r) => r.group === "control").length,
      directly_labeled: rows.filter((r) => r.labels).length,
    };
  } catch { /* Do not forward parser/private body errors. */ }
  const credentials = Object.fromEntries(
    ["GROQ_API_KEY", "OPENAI_API_KEY", "ANTHROPIC_API_KEY"].map((
      key,
    ) => [key, !!readSecret(key)?.trim()]),
  );
  return {
    dev,
    reference,
    credentials,
    holdout: "locked_until_Q32",
    measured_baseline_ready: dev.full && credentials.GROQ_API_KEY && credentials.OPENAI_API_KEY,
  };
}
if (import.meta.main) console.log(JSON.stringify(await qualityPreflight()));

import { Ajv } from "ajv";
import schema from "../../eval/corpus.schema.json" with { type: "json" };

type Clarity = "fragment" | "partial" | "vivid";
type SetName = "dev" | "holdout" | "sentinel";
type Dream = { expected_clarity: Clarity | null };
type RecordShape = Dream & {
  id: string;
  set: SetName;
  kind: "single" | "sequence";
  dreams?: Dream[];
};
type Counts = {
  single: number;
  sequence: number;
  dreams: number;
  singleClarity: Record<Clarity, number>;
  allClarity: Record<Clarity | "unclassified", number>;
};
export type CorpusSummary = Record<SetName, Counts>;
export type CorpusIssue = {
  file: number;
  line: number;
  code: "INVALID_JSON" | "SCHEMA_INVALID" | "DUPLICATE_ID" | "SET_MISMATCH" | "EMPTY_CORPUS";
};

const validateRecord = new Ajv({ strict: true }).compile(schema);
const sets: SetName[] = ["dev", "holdout", "sentinel"];

function emptyCounts(): Counts {
  return {
    single: 0,
    sequence: 0,
    dreams: 0,
    singleClarity: { fragment: 0, partial: 0, vivid: 0 },
    allClarity: { fragment: 0, partial: 0, vivid: 0, unclassified: 0 },
  };
}

// Errors expose fixed codes and numeric locations only. Never forward parser/Ajv errors:
// their messages, property paths, and parameters can contain private input text.
export function validateCorpusTexts(
  inputs: { text: string; expectedSet?: SetName }[],
): { summary: CorpusSummary; issues: CorpusIssue[] } {
  const summary: CorpusSummary = {
    dev: emptyCounts(),
    holdout: emptyCounts(),
    sentinel: emptyCounts(),
  };
  const issues: CorpusIssue[] = [];
  const ids = new Set<string>();
  let records = 0;
  inputs.forEach((input, fileIndex) => {
    input.text.split(/\r?\n/).forEach((line, lineIndex) => {
      if (!line.trim()) return;
      const location = { file: fileIndex + 1, line: lineIndex + 1 };
      let value: unknown;
      try {
        value = JSON.parse(line);
      } catch {
        issues.push({ ...location, code: "INVALID_JSON" });
        return;
      }
      if (!validateRecord(value)) {
        issues.push({ ...location, code: "SCHEMA_INVALID" });
        return;
      }
      const record = value as RecordShape;
      if (ids.has(record.id)) {
        issues.push({ ...location, code: "DUPLICATE_ID" });
        return;
      }
      ids.add(record.id);
      if (input.expectedSet && record.set !== input.expectedSet) {
        issues.push({ ...location, code: "SET_MISMATCH" });
        return;
      }
      records++;
      const counts = summary[record.set];
      counts[record.kind]++;
      const dreams = record.kind === "sequence" ? record.dreams! : [record];
      counts.dreams += dreams.length;
      for (const dream of dreams) counts.allClarity[dream.expected_clarity ?? "unclassified"]++;
      if (record.kind === "single" && record.expected_clarity !== null) {
        counts.singleClarity[record.expected_clarity]++;
      }
    });
  });
  if (records === 0 && issues.length === 0) {
    issues.push({ file: 0, line: 0, code: "EMPTY_CORPUS" });
  }
  return { summary, issues };
}

export function summaryLines(summary: CorpusSummary): string[] {
  return sets.map((set) => {
    const c = summary[set];
    const singles = c.singleClarity;
    const all = c.allClarity;
    return `set=${set} single=${c.single} sequence=${c.sequence} dreams=${c.dreams} ` +
      `gate_units=${set === "sentinel" ? 0 : c.single + c.sequence} ` +
      `single_fragment=${singles.fragment} single_partial=${singles.partial} single_vivid=${singles.vivid} ` +
      `fragment=${all.fragment} partial=${all.partial} vivid=${all.vivid} unclassified=${all.unclassified}`;
  });
}

async function main(): Promise<number> {
  if (Deno.args.length === 0) {
    console.error("FAIL code=USAGE");
    return 1;
  }
  const inputs: { text: string; expectedSet?: SetName }[] = [];
  for (const path of Deno.args) {
    const basename = path.replaceAll("\\", "/").split("/").at(-1);
    const expectedSet = sets.find((set) => basename === `${set}.jsonl`);
    try {
      inputs.push({ text: await Deno.readTextFile(path), expectedSet });
    } catch {
      console.error(`FAIL file=${inputs.length + 1} code=READ_FAILED`);
      return 1;
    }
  }
  const { summary, issues } = validateCorpusTexts(inputs);
  if (issues.length) {
    for (const issue of issues) {
      console.error(`FAIL file=${issue.file} line=${issue.line} code=${issue.code}`);
    }
    return 1;
  }
  for (const line of summaryLines(summary)) console.log(line);
  return 0;
}

if (import.meta.main) Deno.exit(await main());

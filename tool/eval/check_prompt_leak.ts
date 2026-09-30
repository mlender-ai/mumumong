import { parseWorks } from "./reference_contract.ts";
import { validateCorpusTexts } from "./validate_corpus.ts";

const MIN_MATCH_CHARACTERS = 8;
const ROOT = new URL("../../", import.meta.url);

type PromptFile = { file: string; text: string };
export type PromptLeak = { file: string; line: number };
type CheckResult =
  | { code: "OK"; leaks: [] }
  | { code: "PROMPT_LEAK"; leaks: PromptLeak[] }
  | {
    code:
      | "DEV_MISSING"
      | "DEV_INVALID"
      | "REFERENCE_MISSING"
      | "REFERENCE_INVALID"
      | "PROMPTS_MISSING"
      | "PROMPTS_UNREADABLE";
    leaks: [];
  };

// NFC and whitespace folding detect literal copy-paste across line wrapping.
// The line map belongs only to the prompt; no private source text is returned.
function normalized(text: string): { characters: string[]; lines: number[] } {
  const characters: string[] = [];
  const lines: number[] = [];
  let line = 1;
  for (const character of text.normalize("NFC")) {
    if (/\s/u.test(character)) {
      if (characters.at(-1) !== " ") {
        characters.push(" ");
        lines.push(line);
      }
      if (character === "\n") line++;
    } else {
      characters.push(character);
      lines.push(line);
    }
  }
  return { characters, lines };
}

function windows(texts: readonly string[]): Set<string> {
  const result = new Set<string>();
  for (const text of texts) {
    const characters = normalized(text).characters;
    for (let index = 0; index <= characters.length - MIN_MATCH_CHARACTERS; index++) {
      const segment = characters.slice(index, index + MIN_MATCH_CHARACTERS).join("");
      if (/[^\s]/u.test(segment)) result.add(segment);
    }
  }
  return result;
}

export function scanPromptLeaks(
  privateTexts: readonly string[],
  prompts: readonly PromptFile[],
): PromptLeak[] {
  const privateWindows = windows(privateTexts);
  const hits = new Map<string, PromptLeak>();
  for (const prompt of prompts) {
    const { characters, lines } = normalized(prompt.text);
    let previousHit = -2;
    for (let index = 0; index <= characters.length - MIN_MATCH_CHARACTERS; index++) {
      const segment = characters.slice(index, index + MIN_MATCH_CHARACTERS).join("");
      if (!privateWindows.has(segment)) continue;
      if (index === previousHit + 1) {
        previousHit = index;
        continue;
      }
      const hit = { file: prompt.file, line: lines[index] };
      hits.set(`${hit.file}:${hit.line}`, hit);
      previousHit = index;
    }
  }
  return [...hits.values()].sort((a, b) => a.file.localeCompare(b.file) || a.line - b.line);
}

type DreamText = {
  raw_text: string;
  recall_answers?: Record<string, string>;
};
type DevRecord = DreamText & {
  kind: "single" | "sequence";
  dreams?: DreamText[];
};

function devTexts(text: string): string[] {
  const records = text.split(/\r?\n/).filter((line) => line.trim()).map((line) =>
    JSON.parse(line) as DevRecord
  );
  const dreams = records.flatMap((record) =>
    record.kind === "sequence" ? record.dreams! : [record]
  );
  return dreams.flatMap((dream) => [
    dream.raw_text,
    ...Object.values(dream.recall_answers ?? {}),
  ]);
}

async function promptFiles(root: URL): Promise<PromptFile[]> {
  const files: PromptFile[] = [];
  async function visit(relative: string): Promise<void> {
    let entries: Deno.DirEntry[];
    try {
      entries = [];
      for await (const entry of Deno.readDir(new URL(relative, root))) entries.push(entry);
    } catch (error) {
      if (error instanceof Deno.errors.NotFound) return;
      throw error;
    }
    for (const entry of entries) {
      if (entry.isSymlink) continue;
      const file = `${relative}${entry.name}`;
      if (entry.isDirectory) await visit(`${file}/`);
      else if (entry.isFile) {
        files.push({ file, text: await Deno.readTextFile(new URL(file, root)) });
      }
    }
  }
  await visit("supabase/functions/_shared/prompts/");
  await visit("supabase/functions/_shared/style/");
  return files;
}

/// Does not open holdout or sentinel, and never returns private text.
export async function checkPromptLeakRoot(root = ROOT): Promise<CheckResult> {
  let dev: string;
  try {
    dev = await Deno.readTextFile(new URL("eval/corpus/dev.jsonl", root));
  } catch {
    return { code: "DEV_MISSING", leaks: [] };
  }
  if (validateCorpusTexts([{ text: dev, expectedSet: "dev" }]).issues.length) {
    return { code: "DEV_INVALID", leaks: [] };
  }
  let reference: string;
  try {
    reference = await Deno.readTextFile(new URL("eval/reference/works.jsonl", root));
  } catch {
    return { code: "REFERENCE_MISSING", leaks: [] };
  }
  let works;
  try {
    works = parseWorks(reference);
  } catch {
    return { code: "REFERENCE_INVALID", leaks: [] };
  }
  let prompts: PromptFile[];
  try {
    prompts = await promptFiles(root);
  } catch {
    return { code: "PROMPTS_UNREADABLE", leaks: [] };
  }
  if (!prompts.length) return { code: "PROMPTS_MISSING", leaks: [] };
  const privateTexts = [
    ...devTexts(dev),
    ...works.flatMap((work) => [work.opening, work.ending, work.next_opening ?? ""]),
  ];
  const leaks = scanPromptLeaks(privateTexts, prompts);
  return leaks.length ? { code: "PROMPT_LEAK", leaks } : { code: "OK", leaks: [] };
}

if (import.meta.main) {
  const result = await checkPromptLeakRoot();
  if (result.code === "PROMPT_LEAK") {
    for (const leak of result.leaks) {
      console.error(`FAIL file=${leak.file} line=${leak.line}`);
    }
  } else {
    console.log(result.code === "OK" ? "OK" : `FAIL code=${result.code}`);
  }
  Deno.exit(result.code === "OK" ? 0 : 1);
}

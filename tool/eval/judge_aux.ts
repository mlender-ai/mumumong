import { z } from "zod";
import { digest, EvalError } from "./config.ts";
import { type DisplayItem, loadRun, type Prepared, ROOT } from "./judge_inputs.ts";
import { type JudgmentItem, privatePath, sceneSchema, seed } from "./judgment.ts";

const identifier = z.string().regex(/^[A-Za-z0-9_-]{1,80}$/);
const candidateSchema = z.object({ id: identifier, text: z.string().min(1) }).strict();
const referenceSchema = z.object({
  id: identifier,
  title: z.string().optional(),
  paragraphs: z.array(z.string().min(1)).min(1).max(1000),
  labels: z.array(z.string().min(1).max(40)).min(1).max(12).optional(),
}).strict();
const auditSchema = z.object({
  id: identifier,
  raw_text: z.string(),
  text: z.string().min(1),
  finding: z.string().min(1),
}).strict();
const rewriteSchema = z.object({
  id: identifier,
  kind: z.enum(["single", "sequence"]),
  scenes: z.array(sceneSchema).min(1).max(4),
}).strict();
export type AuxMode = "fidelity-audit" | "pick" | "annotate" | "pro";

export async function prepareAux(
  mode: AuxMode,
  path: string,
  runPath?: string,
  root = ROOT,
): Promise<Prepared> {
  if (mode === "fidelity-audit") {
    if (!runPath) throw new EvalError("USAGE");
    await loadRun(runPath, root); // Reject holdout before opening audit text.
  }
  const file = await privatePath(
    root,
    path,
    mode === "pick" ? "runs" : mode === "annotate" ? "reference" : mode === "pro" ? "pro" : "runs",
  );
  let text: string;
  try {
    text = await Deno.readTextFile(file);
  } catch {
    throw new EvalError("AUX_INPUT_INVALID");
  }
  const display = new Map<string, DisplayItem>();
  let items: JudgmentItem[] = [];
  let fingerprint = await digest(text);
  try {
    if (mode === "fidelity-audit") {
      const audits = z.object({ items: z.array(auditSchema).min(15) }).strict().parse(
        JSON.parse(text),
      ).items.slice(0, 15);
      items = audits.map((row) => {
        display.set(row.id, {
          id: row.id,
          originals: [row.raw_text],
          text: row.text,
          paragraphs: [row.finding],
        });
        return { id: row.id, kind: "audit", clarity: "unclassified", vote: null, audit: null };
      });
    } else if (mode === "pick") {
      const rows = z.array(candidateSchema).min(1).max(1000).parse(JSON.parse(text));
      items = rows.map((row) => {
        display.set(row.id, { id: row.id, originals: [], text: row.text });
        return { id: row.id, kind: "candidate", clarity: "unclassified", vote: null, audit: null };
      });
    } else if (mode === "annotate") {
      const rows = text.trim().split(/\r?\n/).map((line) =>
        referenceSchema.parse(JSON.parse(line))
      );
      items = rows.map((row) => {
        display.set(row.id, {
          id: row.id,
          originals: [],
          text: row.title,
          paragraphs: row.paragraphs,
          labels: row.labels ?? ["동작", "감각", "대사", "설명", "첫 문장 훅", "장면 끝 당김"],
        });
        return { id: row.id, kind: "reference", clarity: "unclassified", vote: null, audit: null };
      });
    } else {
      if (!runPath) throw new EvalError("USAGE");
      const run = await loadRun(runPath, root);
      if (run.manifest.identity.set !== "fixtures") {
        throw new EvalError("PRO_REQUIRES_SYNTHETIC_FIXTURES");
      }
      const rows = text.trim().split(/\r?\n/).map((line) => rewriteSchema.parse(JSON.parse(line)));
      const corpusText = await Deno.readTextFile(new URL("eval/fixtures/sample.jsonl", root));
      if (await digest(corpusText) !== run.manifest.identity.corpus_sha256) {
        throw new EvalError("CORPUS_MISMATCH");
      }
      const corpus = corpusText.trim().split(/\r?\n/).map((line) =>
        JSON.parse(line) as { id: string; raw_text?: string; dreams?: { raw_text: string }[] }
      );
      items = run.results.flatMap((result) => {
        const pro = rows.find((row) => row.id === result.id);
        if (!pro) return [];
        if (pro.kind !== result.kind || pro.scenes.length !== (pro.kind === "single" ? 1 : 4)) {
          throw new EvalError("CASE_MISMATCH");
        }
        const source = corpus.find((record) => record.id === result.id);
        if (!source) throw new EvalError("CASE_MISMATCH");
        display.set(result.id, {
          id: result.id,
          originals: source.dreams?.map((dream) => dream.raw_text) ?? [source.raw_text!],
          A: result.scenes,
          B: pro.scenes.map((scene) => ({
            ...scene,
            passages: scene.passages.map((p) => ({ text: p.text, origin: "C" as const })),
          })),
        });
        return [{
          id: result.id,
          kind: result.kind,
          clarity: "unclassified" as const,
          audit: null,
          vote: result.status === "failed"
            ? {
              winner: "B" as const,
              automatic: "A_failed" as const,
              not_ready: { A: true, B: null },
              reasons: [],
              problems: [],
            }
            : null,
        }];
      });
      fingerprint = await digest(fingerprint + run.fingerprint);
    }
    if (!items.length || new Set(items.map((item) => item.id)).size !== items.length) {
      throw new EvalError("AUX_INPUT_INVALID");
    }
  } catch (error) {
    if (error instanceof EvalError) throw error;
    throw new EvalError("AUX_INPUT_INVALID");
  }
  return {
    nameA: mode,
    display,
    judgment: {
      version: 1,
      mode,
      seed: seed(),
      revision: 0,
      identity: fingerprint,
      set: "auxiliary",
      gate_eligible: false,
      stats: null,
      items,
    },
  };
}

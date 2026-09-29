import { z } from "zod";
import { EvalError } from "./config.ts";
import { type Prepared, ROOT } from "./judge_inputs.ts";
import {
  atomicSave,
  type AuditVote,
  type Judgment,
  judgmentSchema,
  leftSide,
  LOSS_PROBLEMS,
  WIN_REASONS,
} from "./judgment.ts";

export const submissionSchema = z.object({
  id: z.string(),
  revision: z.number().int().nonnegative(),
  choice: z.enum(["left", "right", "tie", "agree", "disagree", "keep", "reject"]),
  not_ready_left: z.boolean().default(false),
  not_ready_right: z.boolean().default(false),
  winner_not_ready: z.boolean().default(false),
  reasons: z.array(z.enum(WIN_REASONS)).max(3).default([]),
  problems: z.array(z.enum(LOSS_PROBLEMS)).max(4).default([]),
  annotations: z.array(
    z.object({
      paragraph: z.number().int().nonnegative(),
      labels: z.array(z.string().min(1).max(40)).max(12),
      note: z.string().max(240),
    }).strict(),
  ).max(1000).optional(),
}).strict();
export type Submission = z.infer<typeof submissionSchema>;

async function lock(path: URL) {
  const file = new URL(`${path.href}.lock`);
  try {
    const pid = Number(await Deno.readTextFile(file));
    if (!Number.isSafeInteger(pid) || pid <= 0 || Deno.build.os === "windows") {
      throw new EvalError("JUDGMENT_LOCKED");
    }
    const output = await new Deno.Command("kill", {
      args: ["-0", String(pid)],
      stdout: "null",
      stderr: "null",
    }).output();
    if (output.success) throw new EvalError("JUDGMENT_LOCKED");
    await Deno.remove(file);
  } catch (error) {
    if (!(error instanceof Deno.errors.NotFound)) throw error;
  }
  try {
    await Deno.writeTextFile(file, String(Deno.pid), { createNew: true, mode: 0o600 });
  } catch {
    throw new EvalError("JUDGMENT_LOCKED");
  }
  return async () => {
    try {
      await Deno.remove(file);
    } catch { /* Lock is owned by this session. */ }
  };
}

export class JudgeStore {
  private queued = Promise.resolve();
  private constructor(
    readonly prepared: Prepared,
    readonly path: URL,
    public judgment: Judgment,
    private unlock: () => Promise<void>,
  ) {}
  static async open(prepared: Prepared, root = ROOT): Promise<JudgeStore> {
    const directory = new URL("eval/judgments/", root);
    await Deno.mkdir(directory, { recursive: true, mode: 0o700 });
    if ((await Deno.lstat(directory)).isSymlink) throw new EvalError("PRIVATE_PATH_REQUIRED");
    if (
      [prepared.nameA, prepared.nameB].some((name) =>
        name !== undefined && !/^[A-Za-z0-9_-]{1,180}$/.test(name)
      )
    ) throw new EvalError("RUN_NAME_INVALID");
    const name = prepared.judgment.mode === "ab"
      ? `${prepared.nameA}__${prepared.nameB}`
      : `${prepared.judgment.mode}-${prepared.judgment.identity.slice(0, 16)}`;
    const path = new URL(`${name}.json`, directory);
    try {
      if ((await Deno.lstat(path)).isSymlink) throw new EvalError("PRIVATE_PATH_REQUIRED");
    } catch (error) {
      if (!(error instanceof Deno.errors.NotFound)) throw error;
    }
    const unlock = await lock(path);
    try {
      let judgment = prepared.judgment;
      try {
        judgment = judgmentSchema.parse(JSON.parse(await Deno.readTextFile(path)));
        if (
          judgment.identity !== prepared.judgment.identity ||
          judgment.mode !== prepared.judgment.mode ||
          JSON.stringify(judgment.items.map(({ id, kind, clarity }) => ({ id, kind, clarity }))) !==
            JSON.stringify(
              prepared.judgment.items.map(({ id, kind, clarity }) => ({ id, kind, clarity })),
            )
        ) throw new EvalError("JUDGMENT_INPUT_CHANGED");
      } catch (error) {
        if (!(error instanceof Deno.errors.NotFound)) {
          if (error instanceof EvalError) throw error;
          throw new EvalError("JUDGMENT_INVALID");
        }
        await atomicSave(path, judgment);
      }
      if (
        JSON.stringify(judgment.stats) !== JSON.stringify(prepared.judgment.stats) ||
        judgment.gate_eligible !== prepared.judgment.gate_eligible
      ) {
        judgment.stats = prepared.judgment.stats;
        judgment.gate_eligible = prepared.judgment.gate_eligible;
        judgment.revision++;
        await atomicSave(path, judgment);
      }
      return new JudgeStore(prepared, path, judgment, unlock);
    } catch (error) {
      await unlock();
      throw error;
    }
  }
  async close() {
    await this.queued;
    await this.unlock();
  }
  async state(index?: number, sources = false) {
    const items = this.judgment.items;
    const pending = items.findIndex((item) => item.vote === null && item.audit === null);
    const position = index ?? pending;
    const item = position >= 0 && position < items.length ? items[position] : undefined;
    const common = {
      mode: this.judgment.mode,
      demo: this.judgment.set === "fixtures",
      revision: this.judgment.revision,
      total: items.length,
      completed: items.filter((item) => item.vote !== null || item.audit !== null).length,
      automatic:
        items.filter((item) => item.vote?.automatic !== "none" && item.vote !== null).length,
      position,
    };
    if (!item) return { ...common, done: true };
    if (item.vote && item.vote.automatic !== "none") return { ...common, done: false, skip: true };
    const display = this.prepared.display.get(item.id)!;
    const left = await leftSide(this.judgment.seed, item.id);
    const opposite = left === "A" ? "B" : "A";
    const scenes = (side: "A" | "B") =>
      display[side]?.map((scene) => ({
        title: scene.title ?? "",
        passages: scene.passages.map((passage) => ({
          text: passage.text,
          ...(sources
            ? { origin: passage.origin ?? "", source_element_ids: passage.source_element_ids ?? [] }
            : {}),
        })),
      }));
    return {
      ...common,
      done: false,
      id: item.id,
      kind: item.kind,
      originals: display.originals,
      left: scenes(left),
      right: scenes(opposite),
      text: display.text,
      paragraphs: display.paragraphs,
      labels: display.labels,
      choice: item.vote
        ? item.vote.winner === "tie" ? "tie" : item.vote.winner === left ? "left" : "right"
        : item.audit?.choice ?? null,
      not_ready_left: item.vote?.not_ready[left] ?? false,
      not_ready_right: item.vote?.not_ready[opposite] ?? false,
      reasons: item.vote?.reasons ?? [],
      problems: item.vote?.problems ?? [],
      annotations: item.audit?.annotations ?? [],
    };
  }
  submit(value: unknown): Promise<void> {
    const operation = this.queued.then(async () => {
      let input: Submission;
      try {
        input = submissionSchema.parse(value);
      } catch {
        throw new EvalError("SUBMISSION_INVALID");
      }
      if (input.revision !== this.judgment.revision) throw new EvalError("REVISION_CONFLICT");
      const snapshot = structuredClone(this.judgment);
      const item = snapshot.items.find((item) => item.id === input.id);
      if (!item || item.vote && item.vote.automatic !== "none") {
        throw new EvalError("ITEM_NOT_EDITABLE");
      }
      if (["ab", "pro"].includes(snapshot.mode)) {
        if (!["left", "right", "tie"].includes(input.choice)) {
          throw new EvalError("SUBMISSION_INVALID");
        }
        const left = await leftSide(snapshot.seed, item.id), right = left === "A" ? "B" : "A";
        const winner = input.choice === "tie" ? "tie" : input.choice === "left" ? left : right;
        const not_ready = { A: false, B: false };
        not_ready[left] = input.not_ready_left;
        not_ready[right] = input.not_ready_right;
        if (input.winner_not_ready) {
          if (winner === "tie") {
            not_ready.A = true;
            not_ready.B = true;
          } else not_ready[winner] = true;
        }
        item.vote = {
          winner,
          automatic: "none",
          not_ready,
          reasons: [...new Set(input.reasons)],
          problems: [...new Set(input.problems)],
        };
      } else {
        const allowed = snapshot.mode === "fidelity-audit"
          ? ["agree", "disagree"]
          : ["keep", "reject"];
        if (!allowed.includes(input.choice)) throw new EvalError("SUBMISSION_INVALID");
        if (snapshot.mode === "annotate") {
          const display = this.prepared.display.get(item.id)!;
          if (
            !input.annotations || new Set(input.annotations.map((row) =>
                row.paragraph
              )).size !== input.annotations.length ||
            input.annotations.some((row) =>
              row.paragraph >= display.paragraphs!.length ||
              row.labels.some((label) => !display.labels!.includes(label))
            )
          ) throw new EvalError("SUBMISSION_INVALID");
        }
        item.audit = {
          choice: input.choice as AuditVote["choice"],
          ...(snapshot.mode === "annotate" ? { annotations: input.annotations } : {}),
        };
      }
      snapshot.revision++;
      try {
        await atomicSave(this.path, snapshot);
      } catch {
        throw new EvalError("JUDGMENT_SAVE_FAILED");
      }
      this.judgment = snapshot;
    });
    this.queued = operation.catch(() => {});
    return operation;
  }
}

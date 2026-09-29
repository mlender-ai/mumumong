import { startJudge } from "./judge.ts";
import { ROOT } from "./judge_inputs.ts";
import { savePrivateText } from "./measurements.ts";

// Freshly invented synthetic prose. No referenced work, user dream, API or DB is used.
export async function createReferenceDemo(root = ROOT) {
  const instance = crypto.randomUUID();
  const path = `eval/reference/demo-${instance}/works.jsonl`;
  const file = new URL(path, root);
  await Deno.mkdir(new URL("./", file), { recursive: true, mode: 0o700 });
  const rows = [
    {
      id: `demo1${instance.slice(0, 8)}`,
      group: "positive",
      genre: "미스터리/호러",
      voice: "first",
      synthetic: true,
      opening:
        "우편함 안에서 초인종이 울렸다.\n나는 문을 열지 않은 채 우편함 덮개를 눌렀다. 접힌 종이 한 장이 손등을 밀어냈다.",
      ending: "종이 아래쪽에는 내일 날짜가 찍혀 있었다. 초인종이 다시 울렸다.",
    },
    {
      id: `demo2${instance.slice(0, 8)}`,
      group: "control",
      genre: "판타지",
      voice: "third",
      synthetic: true,
      opening:
        "도서관의 의자가 한 칸씩 물러났다.\n그녀는 빈자리에 책을 내려놓았다. 책등보다 먼저 그림자가 책상 끝에 닿았다.",
      ending: "책은 그대로인데 의자 하나가 더 사라졌다.",
    },
  ];
  await savePrivateText(file, rows.map((r) => JSON.stringify(r)).join("\n") + "\n");
  return path;
}
if (import.meta.main) {
  try {
    const server = await startJudge([
      "--mode",
      "annotate",
      "--reference",
      await createReferenceDemo(),
      "--port",
      "8788",
    ]);
    for (const signal of ["SIGINT", "SIGTERM"] as const) {
      Deno.addSignalListener(signal, () => {
        void server.close();
      });
    }
    await server.server.finished;
  } catch {
    console.error("REFERENCE_DEMO_FAILED");
    Deno.exit(1);
  }
}

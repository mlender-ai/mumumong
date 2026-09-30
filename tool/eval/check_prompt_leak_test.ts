import { assertEquals } from "@std/assert";
import { checkPromptLeakRoot, scanPromptLeaks } from "./check_prompt_leak.ts";

async function syntheticRoot() {
  const path = await Deno.makeTempDir({ prefix: "mumumong-prompt-leak-test-" });
  const root = new URL(`file://${path}/`);
  await Deno.mkdir(new URL("eval/corpus/", root), { recursive: true });
  await Deno.mkdir(new URL("eval/reference/", root), { recursive: true });
  await Deno.mkdir(new URL("supabase/functions/_shared/prompts/", root), {
    recursive: true,
  });
  return { root, cleanup: () => Deno.remove(root, { recursive: true }) };
}

function devLine(rawText: string) {
  return JSON.stringify({
    id: "synth1",
    set: "dev",
    kind: "single",
    raw_text: rawText,
    expected_clarity: "vivid",
    settings: null,
  });
}

function referenceLine(opening: string) {
  return JSON.stringify({
    id: "synthetic_reference",
    group: "positive",
    genre: "기타",
    voice: "first",
    opening,
    ending: "나무가 창문을 두드린다.",
    synthetic: true,
  });
}

Deno.test("prompt leak scanner detects an eight-character Unicode match and reports only prompt locations", () => {
  const privatePhrase = "초록달팽이가 종이배를 접는다";
  const found = scanPromptLeaks([privatePhrase], [{
    file: "supabase/functions/_shared/prompts/plan.v7.ts",
    text: "const rule = '새 문장을 쓰자';\nconst copied = '초록달팽이가\n종이배를 접는다';",
  }]);
  assertEquals(found, [
    { file: "supabase/functions/_shared/prompts/plan.v7.ts", line: 2 },
  ]);
  assertEquals(JSON.stringify(found).includes(privatePhrase), false);
});

Deno.test("seven characters and unrelated prose do not trigger the leak guard", () => {
  assertEquals(
    scanPromptLeaks(["가나다라마바사"], [{ file: "a.ts", text: "가나다라마바사" }]),
    [],
  );
  assertEquals(
    scanPromptLeaks(["비밀의 파란 새가 날아간다"], [{ file: "a.ts", text: "노란 꽃이 핀다" }]),
    [],
  );
});

Deno.test("local guard combines dev and reference text but never opens holdout", async () => {
  const { root, cleanup } = await syntheticRoot();
  try {
    await Deno.writeTextFile(
      new URL("eval/corpus/dev.jsonl", root),
      `${devLine("달빛 우산을 접고 집으로 돌아왔다")}\n`,
    );
    await Deno.writeTextFile(
      new URL("eval/corpus/holdout.jsonl", root),
      "This is deliberately not valid JSON or a readable evaluation record",
    );
    await Deno.writeTextFile(
      new URL("eval/reference/works.jsonl", root),
      `${referenceLine("유리별이 흐르는 기차역에서 기다렸다")}\n`,
    );
    await Deno.writeTextFile(
      new URL("supabase/functions/_shared/prompts/write.v11.ts", root),
      "const style = '유리별이 흐르는 기차역에서';",
    );
    const result = await checkPromptLeakRoot(root);
    assertEquals(result.code, "PROMPT_LEAK");
    assertEquals(result.leaks, [{
      file: "supabase/functions/_shared/prompts/write.v11.ts",
      line: 1,
    }]);
    const report = JSON.stringify(result);
    assertEquals(report.includes("유리별이"), false);
    assertEquals(report.includes("달빛 우산"), false);
  } finally {
    await cleanup();
  }
});

Deno.test("missing private inputs fail closed with fixed metadata codes", async () => {
  const { root, cleanup } = await syntheticRoot();
  try {
    assertEquals((await checkPromptLeakRoot(root)).code, "DEV_MISSING");
    await Deno.writeTextFile(
      new URL("eval/corpus/dev.jsonl", root),
      `${devLine("모래시계가 거꾸로 흘렀다")}\n`,
    );
    assertEquals((await checkPromptLeakRoot(root)).code, "REFERENCE_MISSING");
    await Deno.writeTextFile(
      new URL("eval/reference/works.jsonl", root),
      `${referenceLine("창가에서 초록 종이를 접었다")}\n`,
    );
    await Deno.writeTextFile(
      new URL("supabase/functions/_shared/prompts/write.v11.ts", root),
      "const unrelated = '완전히 다른 문장입니다';",
    );
    assertEquals((await checkPromptLeakRoot(root)).code, "OK");
  } finally {
    await cleanup();
  }
});

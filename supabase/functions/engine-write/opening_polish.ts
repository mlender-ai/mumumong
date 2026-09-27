import type { WriteOutput } from "../_shared/stage_contracts.ts";
import { countChars } from "../_shared/text.ts";

export const OPENING_POLISH_SYSTEM = `당신은 연재소설 첫 장면의 최종 편집자다.
입력의 expanded_draft를 하나의 매끄러운 장면으로 다시 쓴다. 출력은 write 스키마 JSON뿐이다.

절대 규칙
1. raw_text의 행위자, 수혜자, 목적, 원인, 사건 순서를 바꾸지 않는다. 꿈을 기록한 사용자가 주인공이다.
2. 남자친구·친구·가족 같은 관계 인물은 raw_text에 행동이 없으면 새로 등장하거나 행동하지 않는다.
3. 같은 발견·판단·행동을 두 번 쓰지 않는다. 특히 "책상을 빼앗았다" 같은 핵심 행동은 한 번만 일어난다.
4. 원문에 없는 방, 어둠, 빛, 돌, 재질, 색, 대사, 동물의 생각을 만들지 않는다.
5. 첫 문단은 설명이나 "나는 ~하려고 했다"라는 보고가 아니라, 당장 해결해야 할 문제나 행동의 순간으로 연다.
6. 7~9개 문단을 유지하고 target_length의 70% 이상을 쓴다. 각 문단은 앞 문단의 결과로 다음 행동을 만든다.
7. 마지막은 원문의 목적을 완료하지 않은 채 주인공의 선택 때문에 생긴 구체적인 변화로 끝낸다.
8. D 문단은 raw_text와 source_elements에 있는 사실만 쓰고 실제 source_element_ids를 유지한다. C는 짧은 연결과 열린 결과에만 쓴다.
9. 꿈을 해석하거나 요약·교훈으로 끝내지 않는다. U 문단은 출력하지 않는다.
10. scene.title은 planned_title을 그대로 쓴다.`;

export function shouldUsePolishedOpening(
  current: WriteOutput,
  candidate: WriteOutput,
  targetLength: number,
): boolean {
  if (candidate.passages.length < 7 || candidate.passages.length > 9) return false;
  const currentChars = current.passages.reduce((sum, passage) => sum + countChars(passage.text), 0);
  const candidateChars = candidate.passages.reduce(
    (sum, passage) => sum + countChars(passage.text),
    0,
  );
  const minimum = Math.max(350, Math.floor(targetLength * 0.7));
  return candidateChars >= minimum && candidateChars >= Math.floor(currentChars * 0.85);
}

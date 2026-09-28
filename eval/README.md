# MUMUMONG evaluation corpus (Q-01)

`corpus.schema.json`은 JSONL의 한 레코드를 검증하는 JSON Schema다.
레포는 public이므로 실제 꿈, 생성 원고, 판정 데이터는 아래 비공개 디렉터리에만 둔다.

```text
eval/
  README.md                # 커밋: 규격·절차
  corpus.schema.json       # 커밋: 레코드 스키마
  configs/                 # 커밋: 본문·키 없는 설정 (Q-03에서 구현)
  fixtures/sample.jsonl    # 커밋: 새로 지어낸 가짜 꿈만
  corpus/                  # 비공개: dev.jsonl, holdout.jsonl, sentinel.jsonl
  runs/                    # 비공개: 생성 결과
  judgments/               # 비공개: 사람 판정
```

`fixtures/sample.jsonl`은 Q-01 테스트용으로 새로 지어낸 가짜 꿈이다.
사용자가 전달한 꿈이나 실제 꿈을 변형해 만들지 않았다.
single 2개와 4개 꿈이 이어지는 sequence 1개, 총 6개 가짜 꿈을 포함한다.
fixture 결과는 문장 품질의 기준선이나 게이트 점수가 아니다.

## 레코드 규격

각 줄은 JSON 객체 하나다. 빈 줄은 무시한다. `id`는 영문·숫자만 허용하며
여러 파일을 함께 검증해도 중복되지 않아야 한다. 알 수 없는 필드는 거부한다.

| 필드 | single | sequence |
|---|---|---|
| `id`, `set`, `kind` | 필수. `set`: dev / holdout, `kind`: single | 필수. `set`: dev / holdout, `kind`: sequence |
| `raw_text` | 필수. 공백뿐인 문자열 금지. 깬 직후 기록 그대로 | `dreams` 내부 각 꿈에 필수 |
| `expected_clarity` | 필수. 사용자 판단: fragment / partial / vivid | 각 꿈에 필수 |
| `recall_answers` | 선택. 슬롯→문자열 맵 | 각 꿈에서 선택 |
| `settings` | 필수. null이면 향후 run config 기본값 사용 | 동일 |
| `notes` | 선택. 비공개 사용자 메모 | 없음 |
| `dreams` | 없음 | 정확히 4개. 배열 순서가 처리 순서 |

S05 슬롯 키는 `object`, `company`, `place`, `feeling`, `light`다.
`settings`는 현재 객체 또는 null만 검증한다. 러너 설정의 세부 규격은 Q-03 범위다.
본문을 다듬거나 모델로 clarity를 대신 정하지 않는다.

## 수집 목표

| 세트 | single | sequence | 판정 단위 | 꿈 개수 |
|---|---|---|---:|---:|
| dev | 18: fragment / partial / vivid 각 6 | 3 × 4개 | 21 | 30 |
| holdout | 6: 각 2 | 1 × 4개 | 7 | 10 |

관계 인물, 끝나지 않은 행동, 대사, 동물, 주어 생략이 많은 문장을 고르게 수집한다.
검증기는 현재 개수만 보고하며 수집 목표를 강제하지 않는다. 소규모 fixture도 검증 가능하다.
single clarity 분포와 sequence를 포함한 전체 꿈 clarity 분포는 별도 수치다.

holdout은 튜닝에 사용하지 않는다. 사람이 내용을 열거나 엔진 평가를 실행하는 시점은
Q-32 최종 게이트 단 한 번이다. 한 번 본 holdout은 소모된 것으로 처리한다.
형식 검증은 아래 도구로 수행하고 원문을 콘솔·채팅·CI 아티팩트에 출력하지 않는다.

## 과적합 감시용 sentinel

기존 여왕개미 꿈은 `corpus/sentinel.jsonl`에만 두며 dev / holdout에 섞지 않는다.
레코드는 `set: "sentinel"`, `kind: "single"`을 사용한다. 게이트 판정 단위는 항상 0이다.
사람이 clarity를 아직 지정하지 않았다면 **sentinel에서만** `expected_clarity: null`을 허용한다.
dev / holdout에는 null을 허용하지 않는다. 감시용 실행과 러너 연동은 Q-03에서 구현한다.

## 로컬 형식 검증

레포 루트에서 실행한다 (`deno`가 없다면 `npx deno`로 바꾼다).

```bash
deno run --config tool/eval/deno.json --allow-read tool/eval/validate_corpus.ts eval/fixtures/sample.jsonl
deno run --config tool/eval/deno.json --allow-read tool/eval/validate_corpus.ts eval/corpus/dev.jsonl
bash tool/check_eval_privacy.sh
```

여러 파일 경로를 함께 전달하면 전체 ID 중복도 검사한다.
`dev.jsonl`, `holdout.jsonl`, `sentinel.jsonl` 파일명은 해당 `set`만 허용한다.
검증 성공 출력은 세트·종류·clarity별 개수뿐이다.
실패 출력은 파일 순번·줄 번호·고정 오류 코드뿐이며 경로, 원문, 메모,
JSON 파서 오류 원문, 스키마 오류 경로를 출력하지 않는다. 오류가 있으면 종료 코드 1이다.

## 유출 차단

루트 `.gitignore`가 corpus / runs / judgments 전체를 제외하고,
CI가 Git index의 추적 파일을 검사한다. `git add -f`로 넣어도 CI가 실패한다.
위 폴더의 내용을 외부 경로에 복사해 커밋하거나 fixture로 옮기지 않는다.
CI는 지어낸 fixture와 유출 방지 테스트만 실행한다.
API 호출, 평가 러너, 블라인드 판정, 기준선 측정은 Q-01에 포함하지 않는다.

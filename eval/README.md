# MUMUMONG evaluation corpus and offline runner (Q-01–Q-10 tooling)

`corpus.schema.json`은 JSONL의 한 레코드를 검증하는 JSON Schema다.
레포는 public이므로 실제 꿈, 생성 원고, 판정 데이터는 아래 비공개 디렉터리에만 둔다.

```text
eval/
  README.md                # 커밋: 규격·절차
  corpus.schema.json       # 커밋: 레코드 스키마
  configs/                 # 커밋: 본문·키 없는 실행 설정
  fixtures/sample.jsonl    # 커밋: 새로 지어낸 가짜 꿈만
  corpus/                  # 비공개: dev.jsonl, holdout.jsonl, sentinel.jsonl
  runs/                    # 비공개: 생성 결과
  judgments/               # 비공개: 사람 판정
  reference/               # 비공개: 레퍼런스 작품과 라벨링 입력
  pro/                     # 비공개: 작가 재작성본
```

`fixtures/sample.jsonl`은 Q-01 테스트용으로 새로 지어낸 가짜 꿈이다.
사용자가 전달한 꿈이나 실제 꿈을 변형해 만들지 않았다.
single 2개와 4개 꿈이 이어지는 sequence 1개, 총 6개 가짜 꿈을 포함한다.
fixture 결과는 문장 품질의 기준선이나 게이트 점수가 아니다.

Q-10 설정 생성·전송 없는 사전 점검·자동 선별의 실행 절차와 미검증 범위는
`docs/quality/Q10_BAKEOFF_PREPARATION.md`에 있다. 자동 선별 생존은 G1 승자 선정이 아니다.
실제 dev·로컬 키·Q-07 사람 검수·Q-08 기준선이 준비되기 전에는 모델 교체를 하지 않는다.

## 레코드 규격

각 줄은 JSON 객체 하나다. 빈 줄은 무시한다. `id`는 영문·숫자만 허용하며
여러 파일을 함께 검증해도 중복되지 않아야 한다. 알 수 없는 필드는 거부한다.

| 필드 | single | sequence |
|---|---|---|
| `id`, `set`, `kind` | 필수. `set`: dev / holdout, `kind`: single | 필수. `set`: dev / holdout, `kind`: sequence |
| `raw_text` | 필수. 공백뿐인 문자열 금지. 깬 직후 기록 그대로 | `dreams` 내부 각 꿈에 필수 |
| `expected_clarity` | 필수. 사용자 판단: fragment / partial / vivid | 각 꿈에 필수 |
| `recall_answers` | 선택. 슬롯→문자열 맵 | 각 꿈에서 선택 |
| `settings` | 필수. null이면 run config 기본값 사용 | 동일 |
| `notes` | 선택. 비공개 사용자 메모 | 없음 |
| `dreams` | 없음 | 정확히 4개. 배열 순서가 처리 순서 |

S05 슬롯 키는 `object`, `company`, `place`, `feeling`, `light`다.
형식 검증기는 `settings`의 객체/null 여부를 확인하며, 러너가 설정의 enum·필드까지 검증한다.
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
dev / holdout에는 null을 허용하지 않는다. `--set sentinel`은 별도 감시 실행이며
summary의 gate_units는 항상 0이다. fixture 실행도 gate_units가 0이다.

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
Q-05의 reference / pro 입력도 동일하게 차단한다.
위 폴더의 내용을 외부 경로에 복사해 커밋하거나 fixture로 옮기지 않는다.
CI는 지어낸 fixture와 유출 방지 테스트만 실행한다.
Q-01 자체는 API 호출이나 품질 평가를 포함하지 않는다.

## Q-03 오프라인 러너

레포 루트에서 실행한다. 루트 `deno.json`이 기존 코어의 의존성을 해석한다.
fixture는 결정론적 `LlmPort`로만 실행되며 네트워크·API 키·Supabase DB가 필요 없다.
기본 concurrency는 4이며 최대 32다.

```bash
deno run -A tool/eval/run.ts --config eval/configs/baseline_v10.json --set fixtures
deno run -A tool/eval/run.ts --config eval/configs/baseline_v10.json --set fixtures --resume
deno run -A tool/eval/run.ts --config eval/configs/baseline_v10.json --set dev --cases d01,d02,s1 --concurrency 4
deno run -A tool/eval/run.ts --config eval/configs/baseline_v10.json --set sentinel
```

dev / sentinel은 설정에서 선택한 등록 공급자(Groq / Anthropic / OpenAI)를 실제 호출한다.
로컬 환경에 해당 공급자 키를 설정하되 명령 출력·설정·레포에
복사하지 않는다. 엔진 모델 역할은 설정에서 읽으며 운영의 `MODEL_*` 값에 영향받지 않는다.
Q-03 러너는 현재 v10만 지원한다. Q-06/Q-07이 추가한 `--lint` / `--fidelity`는
`baseline_v10_measured.json`으로 실행할 수 있다. 충실도는 실제 15건 사람 검수 전에는
게이트 판정 근거가 아니다.
`--set holdout`은 코퍼스를 읽기 전에 차단된다. Q-32의 1회 게이트에서만 해제할 예정이다.
fixture 원고는 단순 반복 텍스트이며 문장 품질 측정에 사용할 수 없다.

출력은 `eval/runs/<label>-<UTC YYYYMMDDHHmm>-<config SHA256 앞 6자리>/`다.

- `config.json`: 설정, 전체 프롬프트 버전, git 커밋, 소스/코퍼스 SHA256, 세트·선택 ID.
  버전 상수가 없는 expansion / polish는 동결 기준 커밋을 기록한다.
- `results.jsonl`: 케이스별 1줄, 각 꿈의 단계 출력·검증·시도·fallback·최종 출처 문단,
  개별 모델 호출의 토큰·비용 추정·지연. sequence는 scenes 배열과 각 꿈의 E7 결과를 포함한다.
- `summary.json`: 케이스/꿈 성공·실패·fallback, 검증 코드별 **발생 건수**(재시도 포함),
  꿈당 비용 평균/최대, 꿈 전체 처리 지연 p50/p95(nearest-rank).
- `.cases/`: 케이스별 원자적 checkpoint. `.lock`: 동시 writer 차단용 PID.

비용은 공급자 레지스트리 단가와 기존 환율 상수를 재사용한 추정치다. 개별 확장·polish 호출을
포함하므로 운영의 레거시 단일 합산 audit보다 정확한 역할별 산정이다.
사용량을 알 수 없는 호출 실패나 미등록 모델 단가가 있으면 `cost_complete: false` /
summary의 `cost_krw.complete: false`이며 숫자는 **알려진 비용의 하한**이다.
fixture는 비용 0이며 실제 LLM 비용·지연의 증거가 아니다.

`--resume`은 동일 설정·세트·선택 ID·코퍼스·git 커밋·소스 지문을 가진 가장 최근 런을 찾는다.
성공한 케이스만 건너뛰고 실패/미완료 케이스는 처음부터 다시 실행한다.
sequence 중간부터 이어 붙이지 않으므로 인물·기억 상태가 일관된다.
checkpoint와 집계를 원자적으로 교체해 같은 ID의 중복 결과 줄이 남지 않는다.
같은 분에 새 런 이름이 겹치면 기존 런을 덮어쓰지 않고 `--resume` 안내 코드로 실패한다.
살아 있는 writer의 lock은 거부하며 중단된 PID의 lock은 다음 resume에서 회수한다
(macOS/Linux; Windows stale-lock 자동 회수는 지원하지 않는다).
실패 sequence는 그 꿈에서 중단하고 나머지 **케이스**는 계속한다.
실패가 하나라도 있으면 CLI 종료 코드는 1이다. 콘솔에는 ID·상태·수치·고정 코드만 남긴다.
출력 디렉터리는 0700, 결과 파일은 0600으로 만든다.

### 운영 커밋과의 차이

E1/E2/E3/E4/E5/E7 코어와 `writeState`/코어 내부 `sceneLoopNext`, `buildCommitPayload`,
`nextSceneOrderKey`를 재사용한다. 재시도 0–2 / fallback 3, expansion / polish,
정규화·검증 규칙은 운영과 동일하다. 단계 입력도 운영 select 필드와 최근 장면/인물 상한에
맞춘다. 첫 single은 빈 상태에서 E1–E5까지 처리하며 E7을 호출하지 않는다.
sequence는 승인된 장면을 추가하고 role_name으로 인물을 upsert하며 description/aliases를
병합한다. 신규 인물과 사용 인물의 mention_count를 각각 증가시킨 후 E7 기억/장르를 갱신한다.
standalone은 원고에 장면을 추가하지 않고 E7도 생략한다.

이것은 `commit_scene`의 **평가용 근사**다. DB 트랜잭션·RLS·row lock·큐·중복 커밋 RPC,
entity_mentions/progress_events·MU·보관함 상태·장면 이동·사용자 편집은 구현하지 않는다.
엔티티/장면 ID는 평가용 결정론적 UUID이며 실제 DB의 UUID/타임스탬프와 다르다.
모든 케이스는 새 볼륨이며 U 편집/잠금 문단이 없고 fragment_attach도 새 평가 장면으로
추가한다. 실사용자의 대기 중인 연결 질문을 응답하지 않는다(운영처럼 auto 연결만 사용).
DB 정합성/실제 앱 동작/사람 판정의 대체가 아니라, 같은 생성 코어의 품질 비교용 경로다.

## Q-05 블라인드 판정

`deno run -A tool/eval/judge_demo.ts`로 키 없이 가짜 데이터 데모를 연다.
실제 비교는 `judge.ts --a eval/runs/<기준선> --b eval/runs/<후보>`로 실행한다.
저장 후 `report.ts eval/judgments/<기준선>__<후보>.json [--gate G1|G2|G3]`를 실행한다.
서버는 127.0.0.1에만 바인딩하며 원고/원문은 화면 외 로그에 출력하지 않는다.
fixture/sentinel은 품질 게이트에 통과하지 않는다. 누락된 측정도 통과로 간주하지 않는다.
입력 형식, 추가 모드, 판정 재개, 품질 메트릭 계약은 `docs/Q05_BLIND_JUDGING.md`를 따른다.

## Q-06–Q-09 측정 묶음

`baseline_v10_measured.json --set fixtures --lint --fidelity`로 키 없이 측정 연결을 검증할 수 있다.
실제 dev에서는 config의 공급자 키와 사용자 코퍼스가 필요하다. 원래 `baseline_v10.json`은 바꾸지 않았다.
충실도는 실제 15건 검수에서 12건 이상 동의하기 전까지 게이트 수치로 사용하지 않는다.
`measurements.ts calibrate/refresh`, `baseline_report.ts`, `reference_profile.ts analyze/score`가 이를 연결한다.
레퍼런스는 사용자가 직접 수집/라벨링하며 크롤러나 LLM 업로드를 사용하지 않는다.
`reference_demo.ts`는 새로 지어낸 예시를 8788에서 보여주는 화면 검증용이며 실제 프로파일이 아니다.
전체 명령과 미검증 경계: `docs/quality/Q06_Q09_IMPLEMENTATION.md`.

## Q-25 프롬프트 유출 사전 검사

`tool/eval/check_prompt_leak.ts`는 로컬의 dev 꿈·리콜 답변과 레퍼런스
`works.jsonl`을 프롬프트·문체 파일과 대조한다. NFC·공백 접기를 적용해
8글자 이상 일치하면 실패하고 프롬프트 파일명·줄 번호만 출력한다.
holdout과 sentinel은 열지 않으며, 꿈·레퍼런스 원문이나 일치 구절을 출력하지 않는다.
두 비공개 입력 중 하나가 없거나 유효하지 않으면 성공으로 간주하지 않는다.

```bash
npx deno run --allow-read=eval/corpus/dev.jsonl,eval/reference/works.jsonl,supabase/functions/_shared/prompts,supabase/functions/_shared/style tool/eval/check_prompt_leak.ts
```

이 검사는 Q-25 튜닝 라운드의 선행 안전장치만 준비한 것이다. 실제 라운드·G2는
Q-08/Q-09 실측과 Q-10 모델 판정 이후에 진행한다.

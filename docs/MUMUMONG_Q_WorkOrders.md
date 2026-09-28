# MUMUMONG 문장 품질 개선 작업지시서 (Q-시리즈) v1.1

**목표:** 무무몽의 장면 문장을 "AI가 요약한 꿈"에서 "다시 읽고 싶은 소설"로 끌어올린다.
**방법:** 규칙을 더 붙이지 않는다. **기준 → 측정 → 모델 → 구조 → 문체 → 게이트 → 데이터** 순서로 바꾼다.
**기준 레퍼런스:** **카카오페이지 국내 웹소설.** 번역 문체가 아니라 한국어 고유의 문체와 모바일 호흡이 가장 잘 녹아 있기 때문이다 (사용자 결정).

> **v1.1 변경 요약**
> v1.0은 "좋은 문장"의 기준을 모델 출력과 사용자 판정에서만 찾았다. 모델이 만든 예시를 고르고, 사용자가 이긴 쪽의 분포를 임계값으로 쓰는 구조였다. **순환이다. 모델의 문체 감각이 천장이 된다.**
> v1.1은 기준을 **이미 독자가 증명한 작품**(카카오페이지 웹소설)과 **프로 작가**에게서 가져온다.
> - **Q-09 신설** 레퍼런스 분석 — 몰입 문법을 수치·패턴으로 추출
> - **Q-06 확장** 웹소설 호흡 지표 7종 추가
> - **Q-12 신설** 경쟁 AI 집필 도구 기준선 (선택)
> - **Q-20 보완** 도입·끝맺음 유형을 레퍼런스 분포에서 선택
> - **Q-22 교체** 모델 생성 예시 → **작가 외주** 예시 + 고쳐 쓰기 쌍
> - **Q-30 교체** 임계값 = 레퍼런스 분포 (사용자 선호 분포 아님)
> - **Q-41 신설** 행동 기반 몰입 측정 (완독률·체류·재독)
> - **게이트 G2·G3에 레퍼런스 근접도 추가**, 라운드마다 **프로 대비 승률** 추적
>
> **가져오는 것과 가져오지 않는 것.** 가져오는 것은 한국어 고유의 문장 호흡, 모바일 단문과 문단, 첫 문장 훅, 장면 끝 당김이다. 가져오지 않는 것은 장르 문법(회귀·빙의·환생, 상태창·시스템창, 사이다 구조)과 회차 분량(5,000자 등)이다. 꿈은 이런 플롯을 공급하지 못하고, 흉내 내면 각색이 꿈을 덮는다.
**기준 커밋:** `edfc13c` (write.v10 / plan.v6 / gpt-oss-120b on Groq)

공통 규칙은 `AGENTS.md`, `CLAUDE.md`, `docs/MUMUMONG_M1_WorkOrders.md` 상단을 따른다. 이 문서는 그 아래에 놓인다.

---

## 0. 이 시리즈의 원칙 (모든 Q-WO에 적용)

1. **측정 없이 프롬프트를 바꾸지 않는다.** 모든 품질 변경은 평가 세트 실행 + 블라인드 판정을 거친다. 판정 없는 프롬프트 변경은 배포 금지다.
2. **한 번에 한 변수만 바꾼다.** 모델을 바꾸는 라운드에서는 프롬프트를 고정한다. 프롬프트를 바꾸는 라운드에서는 모델을 고정한다.
3. **dev와 holdout을 분리한다.** 튜닝은 dev로만 한다. holdout은 최종 게이트(Q-32)에서 **단 한 번** 연다. 한 번 본 holdout은 소모된 것이다.
4. **꿈 원문과 생성 결과는 레포에 절대 들어가지 않는다.** 이 레포는 public이다. 평가 데이터는 `.gitignore` + CI 가드로 이중 차단한다. 콘솔 출력에도 ID와 수치만 남긴다.
5. **v10과 v11을 공존시킨 뒤 컷오버한다.** `ENGINE_VERSION` 플래그로 전환하고, 롤백은 환경변수 하나로 가능해야 한다.
6. **실패를 규칙 추가로 고치지 않는다.** 실패를 보면 먼저 분류한다. 사실 오류 → 대본(plan) 또는 검증기. 문장 문제 → 문체 바이블 또는 린터. 둘 다 아니면 모델 한계다. **특정 꿈의 문장을 프롬프트에 넣는 순간 과적합이다** (v10의 규칙 18·21·27이 그 사례다).

---

## 1. 진단 요약 (코드 근거)

| # | 원인 | 근거 | 해결 WO |
|---|---|---|---|
| 1 | 작가 모델의 한국어 문학 산문 한계 | `_shared/llm.ts` — `QUALITY_MODEL = "openai/gpt-oss-120b"`, `reasoning_effort: "low"` | Q-04, Q-10 |
| 2 | 문체가 정의된 적 없음 | `style: "plain"` enum 문자열만 전달. 레포에 문체 정의 0곳 | Q-22 |
| 3 | 규칙 누적 32개, 특정 테스트 꿈 과적합 | `prompts/write.v1.ts` 규칙 18(특정 문장 인용)·21·27(개미)·polish 규칙 3("책상을 빼앗았다") | Q-20, Q-21, 이관표 §5.1 |
| 4 | 분량 강제 → 패딩 | 규칙 22·30, `FIRST_SCENE_OPENING_CONTRACT.paragraph_range [7,9]`, V4 `minimumChars`/`minimumPassages` | Q-23 |
| 5 | 문단 단위 고립 확장 → 리듬 붕괴 | `opening_expansion.ts` — 문단별로 경량 모델(20b)이 따로 확장, `opening_polish`가 재수선 | Q-23 |
| 6 | 사실 충실성과 문장력을 한 호출에 몰아넣음 | E4가 raw_text + beats + 설정 JSON 전체를 받아 둘 다 떠안음 | Q-20, Q-21 |
| 7 | 산문을 JSON으로 출력 | `response_format: json_schema` 안에서 문단을 문자열로 생성 | Q-21 |
| 8 | 평가 체계 부재 | 오프라인 실행 경로 없음. 스테이지 로직이 `index.ts`에서 DB I/O와 결합 | Q-01~Q-08 |
| 9 | **좋은 문장의 외부 기준 부재** | 문체 정의·예시·임계값 어디에도 실제 작품 근거가 없음 | **Q-09, Q-22, Q-30** |

**8·9번이 1~7번의 원인이다.** 한 꿈의 실패를 고치면 다른 꿈이 깨지는데 그걸 볼 수단이 없으니 규칙만 쌓였다.

---

## 2. 전체 로드맵과 게이트

| 단계 | WO | 내용 | 시간 | 실행 | 게이트 |
|---|---|---|---:|---|---|
| **P0 측정** | Q-01 | 평가 코퍼스 규격 + 유출 차단 | 2h | 원격 가능 | — |
| | Q-02 | 스테이지 코어 분리 + engine_version 기록 | 10h | 원격 가능 | 기존 테스트 전부 통과, 동작 불변 |
| | Q-03 | 오프라인 평가 러너 | 8h | 원격 가능 (실행은 로컬) | fixture로 single·sequence 완주 |
| | Q-04 | 멀티 프로바이더 LLM 계층 | 6h | 원격 가능 | 어댑터 3종 스텁 테스트 |
| | Q-05 | 블라인드 A/B 판정 도구 + 리포트 | 6h | 원격 가능 | fixture 2런으로 판정·리포트 |
| | Q-06 | 한국어 산문 린터 | 5h | 원격 가능 | 지표별 단위 테스트 |
| | Q-07 | 충실도 판정기 | 5h | 원격 가능 | 사람 일치율 ≥80% (Q-08에서) |
| | Q-08 | 기준선 측정 | 1h + 판정 | **로컬** | 기준선 수치 확정 |
| | **Q-09** | **레퍼런스 분석 (카카오페이지 웹소설)** | 6h + 사용자 4h | 원격 가능 (실행은 로컬) | 레퍼런스 프로파일 확정 |
| **P1 모델** | Q-10 | 작가 모델 베이크오프 | 3h + 판정 2h | **로컬** | **G1** |
| | Q-11 | 승자 모델 운영 반영 (선택, 조기 개선) | 3h | **로컬** | 고지·동의 버전 갱신 |
| | **Q-12** | **경쟁 AI 집필 도구 기준선 (선택)** | 2h + 사용자 1h | **로컬** | — |
| **P2 구조** | Q-20 | 장면 대본 (plan.v7) | 6h | 원격 가능 | 스키마·정규화 테스트 |
| | Q-21 | 산문 작가 v11 (평문 + 비트 마커) | 8h | 원격 가능 | 파서·조립 테스트 |
| | Q-22 | 문체 바이블 3종 + **작가 외주** | 6h + 외주 관리 | 원격 + **사용자** | 작가 예시 9편·고쳐 쓰기 쌍 30개 |
| | Q-23 | 분량 정책 복원, expansion·polish 제거(v11) | 3h | 원격 가능 | v11 경로 호출 검증 |
| | Q-24 | 연속성 컨텍스트 | 3h | 원격 가능 | sequence 판정 |
| | Q-25 | v11 튜닝 라운드 (dev, 최대 3회) | 6h + 판정 3h | **로컬** | **G2** |
| **P3 게이트** | Q-30 | 린터 소프트 게이트 (V9) | 3h | 원격 가능 | 임계값 = 선호 출력의 p90 |
| | Q-31 | 충실도 게이트 (V8) 운영 반영 | 4h | 원격 가능 | 비용·지연 상한 |
| | Q-32 | holdout 게이트 + 컷오버 | 3h + 판정 30m | **로컬** | **G3** |
| **P4 데이터** | Q-40 | 편집 선호 데이터 수집 | 5h | 원격 가능 | RLS·동의 테스트 |
| | **Q-41** | **행동 기반 몰입 측정** | 4h | 원격 가능 | engine_version별 완독률 |
| | | **합계** | **≈ 114h + 사용자 약 16h + 외주 기간** | | 주 17h 기준 약 7주 |

**작가 외주는 가장 먼저 발주한다.** 납품까지 수 주가 걸릴 수 있다. Q-09 브리프가 나오는 즉시(P0 중반) 발주하면 Q-22 시점에 맞출 수 있다. 외주가 늦으면 Q-22 임시 경로로 진행하고 납품 후 교체한다.

**조기 개선 경로:** Q-01 → Q-08 → Q-10 → Q-11이면 약 3주 만에 운영 문장 품질이 먼저 오른다. 모델 교체가 가장 큰 레버이기 때문이다. P2는 그 위에서 진행한다.

**"원격 가능"** = 코드와 단위 테스트는 Claude Code 원격에서 가능하다는 뜻이다. **실제 평가 실행은 항상 로컬이다.** 코퍼스와 API 키가 로컬에만 있기 때문이다.

---

## 3. 판정 기준 (게이트 정의)

### 3.1 부호검정 임계값

블라인드 A/B에서 "비슷함"을 뺀 판정 수(n)에 대해 한쪽 승리가 아래 이상이면 **단측 p ≤ 0.05로 유의**하다. 리포트 스크립트(Q-05)가 정확 이항검정으로 계산한다. 아래 표는 참고용이다.

| 유효 판정 n | 필요 승수 |
|---:|---:|
| 7 | 7 |
| 10 | 9 |
| 15 | 12 |
| 18 | 13 |
| 21 | 15 |
| 24 | 17 |
| 30 | 20 |

dev 한 라운드는 **21개 판정 단위**(single 18 + sequence 3)다. 비슷함이 없으면 15승이 필요하다.

### 3.2 게이트

| 게이트 | 비교 | 통과 조건 |
|---|---|---|
| **G1** (Q-10) | 후보 모델 vs 기준선, 둘 다 v10 프롬프트 | ① 부호검정 p ≤ 0.05 ② 충실도 통과율 ≥ 기준선 − 3%p ③ 파이프라인 실패율 ≤ 5% ④ 꿈당 비용 ≤ 200원 |
| **G2** (Q-25) | v11 vs v10, 둘 다 G1 승자 모델 | ① p ≤ 0.05 ② 충실도 ≥ v10 ③ 출처 오류 0건 ④ V2(C 비율) 준수 100% ⑤ "출시 수준 아님" ≤ 25% ⑥ **레퍼런스 근접도 ≥ v10 + 2** |
| **G3** (Q-32) | v11 vs v10, **holdout** | ① 승 ≥ 패 ② "출시 수준 아님" ≤ 20% ③ 충실도 ≥ v10 ④ 비용 ≤ 200원 ⑤ p95 ≤ 90초 ⑥ **레퍼런스 근접도 ≥ v10** |

G3가 부호검정이 아닌 이유: holdout은 판정 단위 7개라 유의성을 기대할 수 없다. **holdout은 "dev에서 이긴 게 과적합이 아니었는가"를 확인하는 회귀 검사다.**

**레퍼런스 근접도**(Q-09): 핵심 지표 10개 중 실행 결과의 중앙값이 레퍼런스 양성 그룹의 p25–p75 안에 드는 지표 수. 0~10점. **사람 판정을 대체하지 않는다.** 판정이 "좋아졌다"고 말할 때 그 방향이 실제 작품 쪽인지 확인하는 보조 지표다.

**프로 대비 승률**(Q-22 납품 후): 같은 가짜 꿈에 대해 **우리 출력 vs 작가 재작성본** 블라인드 판정. 게이트가 아니라 **천장까지의 거리**를 추적하는 지표다. 라운드마다 기록한다. 30% 안팎이면 상당히 가까워진 것이다.

**"출시 수준 아님"은 절대 기준이다.** 상대 비교에서 이겨도 둘 다 나쁠 수 있다. 판정자가 이긴 쪽에도 체크할 수 있어야 한다 (Q-05).

---

# P0 · 측정 기반

## Q-01 · 평가 코퍼스 규격과 유출 차단

**목적:** 사용자가 모은 꿈을 받아낼 형식을 정하고, 그 꿈이 public 레포로 새는 경로를 코드로 막는다.

**디렉터리**

```
eval/
  README.md               ← 커밋. 규격·절차 설명
  corpus.schema.json      ← 커밋. JSON Schema
  configs/                ← 커밋. 러너 설정
  fixtures/sample.jsonl   ← 커밋. 지어낸 가짜 꿈 3개 (테스트용, 실제 꿈 금지)
  corpus/                 ← gitignore. dev.jsonl, holdout.jsonl
  runs/                   ← gitignore. 실행 결과
  judgments/              ← gitignore. 판정 결과
```

**레코드 형식 (`eval/corpus.schema.json`)**

```jsonc
// single — 첫 장면 평가용
{
  "id": "d01",                        // 영문+숫자, 코퍼스 내 유일
  "set": "dev",                       // dev | holdout
  "kind": "single",
  "raw_text": "…",                    // 깬 직후 기록한 그대로. 다듬지 않는다
  "recall_answers": { "object": "…" }, // 선택. S05 슬롯 키
  "expected_clarity": "partial",      // fragment | partial | vivid — 사용자 판단
  "settings": null,                   // null이면 run config 기본값 사용
  "notes": ""                         // 선택. 사용자 메모
}

// sequence — 연속성 평가용. 순서대로 처리된다
{
  "id": "s1",
  "set": "dev",
  "kind": "sequence",
  "dreams": [
    { "raw_text": "…", "recall_answers": {}, "expected_clarity": "vivid" }
    // … 4개
  ],
  "settings": null
}
```

**규모 (사용자 수집 기준)**

| 세트 | single | sequence | 판정 단위 |
|---|---|---|---:|
| dev | 18 (fragment 6 / partial 6 / vivid 6) | 3 × 꿈 4개 | 21 |
| holdout | 6 (2 / 2 / 2) | 1 × 꿈 4개 | 7 |
| **합계** | | | 꿈 40개 |

과거 실패 영역이 골고루 들어가도록 권장한다: 관계 인물(남자친구·엄마 등), 끝나지 않은 행동, 대사, 동물, 주어 생략이 심한 문장.

**구현**

1. `[수정] .gitignore`에 추가:
   ```
   /eval/corpus/
   /eval/runs/
   /eval/judgments/
   ```
2. `[신규] tool/check_eval_privacy.sh`
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   tracked=$(git ls-files eval/corpus eval/runs eval/judgments)
   if [ -n "$tracked" ]; then
     echo "FAIL: 평가 데이터가 추적되고 있다. 즉시 git rm --cached 하라." >&2
     exit 1
   fi
   echo "OK"
   ```
3. `[수정] .github/workflows/ci.yml` — 기존 `Log safety check` 스텝 다음에 추가.
4. `[신규] tool/eval/validate_corpus.ts` — 스키마 검증, id 중복, 세트별·clarity별 개수 출력. **raw_text를 출력하지 않는다.**
5. `[신규] eval/fixtures/sample.jsonl` — 지어낸 꿈 3개 (single 2, sequence 1). 실제 꿈이 아님을 README에 명시.
6. `[수정] AGENTS.md`, `CLAUDE.md` — "평가 데이터(eval/corpus·runs·judgments)는 절대 커밋·출력하지 않는다" 한 줄 추가.

**완료 조건**
- `eval/corpus/`에 파일을 만들고 `git status`에 나타나지 않는다
- `git add -f`로 강제 추가 후 CI 스크립트가 실패한다
- `validate_corpus.ts eval/fixtures/sample.jsonl`이 개수만 출력하고 통과한다

**하지 말 것:** 샘플 fixture에 실제 꿈을 넣지 마라. 사용자에게 받은 꿈으로 테스트 fixture를 만들지 마라.

---

## Q-02 · 스테이지 코어 분리와 engine_version 기록

**목적:** 오프라인 평가가 운영과 **같은 코드**를 돌리게 한다. 지금은 `engine-*/index.ts`가 DB 조회·LLM 호출·저장을 한 함수에 섞고 있어서, 평가하려면 코드를 복제해야 한다. 복제하면 평가가 운영과 달라진다.

**원칙: 동작을 1도 바꾸지 않는 리팩터링이다.** 기존 테스트 전부와 `tool/cloud_pipeline_smoke.mjs`가 그대로 통과해야 한다.

**구현**

1. **`[신규] _shared/llm_port.ts`** — 스테이지가 의존할 LLM 인터페이스.
   ```ts
   export interface LlmPort {
     structured<T>(req: StructuredCall): Promise<StructuredResult<T>>;
   }
   export interface StructuredCall {
     role: ModelRole;            // 아래 참조. 모델명은 스테이지가 모른다
     schemaName: string;
     schema: Record<string, unknown>;
     system: string;
     input: unknown;
     temperature: number;
     maxTokens: number;
   }
   export type ModelRole =
     | "extract" | "link" | "plan" | "write" | "write_aux" | "polish" | "remember" | "judge";
   ```
   Q-04에서 `text()`를 추가한다. 지금은 `structured`만.

2. **`[신규] _shared/model_config.ts`** — 역할 → 모델 매핑. 운영은 환경변수에서 읽고, 기본값은 **현재 값 그대로**.
   ```ts
   // 기본값 = 현재 운영 동작
   extract: "groq:openai/gpt-oss-20b", link: …, plan: "groq:openai/gpt-oss-120b",
   write: "groq:openai/gpt-oss-120b", write_aux: "groq:openai/gpt-oss-20b",
   polish: "groq:openai/gpt-oss-120b", remember: …, judge: …
   // 환경변수: MODEL_WRITE=anthropic:claude-… 형식으로 역할별 덮어쓰기
   ```
   현재 각 `index.ts`가 `LIGHT_MODEL`/`QUALITY_MODEL`을 어느 호출에 쓰는지 **정확히 그대로** 역할에 대응시킨다.

3. **스테이지마다 `core.ts` 신설** — `engine-extract/core.ts`, `engine-link/core.ts`, `engine-plan/core.ts`, `engine-write/core.ts`, `engine-validate/core.ts`, `engine-remember/core.ts`.
   ```ts
   // 예: engine-write/core.ts
   export interface WriteCoreInput {        // index.ts가 DB에서 읽던 것 전부
     dream: { raw_text; recall_answers; sensitive_flags };
     volume: { adaptation; style; narrative_voice; genre_profile; genre_directive };
     memory: NarrativeMemory | null;
     entities: EntityRow[];
     recentScenes: RecentScene[];
     lockedPassages: LockedPassage[];
     payload: WriteJobPayload;              // elements, links, beats, placement, …
     writeAttempt: number;
     isFallback: boolean;
   }
   export async function runWrite(input: WriteCoreInput, llm: LlmPort): Promise<WriteCoreResult>;
   ```
   - `index.ts`는 **로드 → `runX` → 저장**만 남긴다.
   - expansion·polish도 `runWrite` 안으로 들어간다 (v10 경로 보존).
   - `WriteCoreResult`는 `sceneDraft`, `modelRuns[]`(role·model·tokens·latency·promptVersion), `nextPayloadPatch`를 담는다.

4. **`[신규] 마이그레이션 0014_engine_version.sql`**
   ```sql
   alter table public.generation_runs
     add column engine_version text not null default 'v10';
   ```
   `recordModelRun`이 `engine_version`을 기록하게 한다. 값은 `ENGINE_VERSION` 환경변수, 기본 `v10`.

5. **retry·fallback 상수를 한 곳으로** — 현재 write→validate 재시도 횟수, fallback 진입 조건, relaxed 검증 프로파일이 흩어져 있으면 `_shared/scene_loop_policy.ts`로 모은다. Q-03 러너가 이것을 **import**한다 (복제 금지).

**완료 조건**
- `deno task verify` 통과, 기존 스테이지 테스트 전부 통과
- 각 `core.ts`에 fake `LlmPort`로 도는 테스트 1개 이상
- `supabase test db` 통과 (0014 포함)
- 로컬에서 `tool/cloud_pipeline_smoke.mjs` 1회 통과 → 운영 동작 불변 확인
- `generation_runs.engine_version = 'v10'`으로 기록됨

**하지 말 것:** 이 WO에서 프롬프트·모델·임계값을 하나도 바꾸지 마라.

---

## Q-03 · 오프라인 평가 러너

**목적:** 코퍼스 전체를 운영과 같은 코어로 돌려서 결과를 파일로 남긴다.

**CLI**

```bash
deno run -A tool/eval/run.ts \
  --config eval/configs/baseline_v10.json \
  --set dev                 # dev | holdout | fixtures
  [--cases d01,d02,s1]      # 부분 실행
  [--concurrency 4]
  [--resume]                # 완료된 케이스 건너뜀
  [--fidelity] [--lint]     # Q-07, Q-06 연결 후
```

**설정 파일 (`eval/configs/*.json`, 커밋)**

```json
{
  "label": "baseline_v10",
  "engine_version": "v10",
  "models": {
    "extract": "groq:openai/gpt-oss-20b",
    "link": "groq:openai/gpt-oss-20b",
    "plan": "groq:openai/gpt-oss-120b",
    "write": "groq:openai/gpt-oss-120b",
    "write_aux": "groq:openai/gpt-oss-20b",
    "polish": "groq:openai/gpt-oss-120b",
    "remember": "groq:openai/gpt-oss-20b",
    "judge": null
  },
  "settings": {
    "style": "plain",
    "adaptation": "balanced",
    "narrative_voice": "first_person_past"
  }
}
```

**실행 흐름**

- **single:** 빈 볼륨 상태에서 E1 → E2 → E3 → E4 → E5 (재시도·fallback 루프 포함). 첫 장면이므로 `is_first_dream = true`.
- **sequence:** 인메모리 `VolumeState`를 만들고 꿈을 순서대로 처리한다. 각 꿈 뒤에 **커밋 등가 처리**를 한다.
  - 장면 추가 (order_key는 `nextSceneOrderKey` 재사용)
  - 엔티티 upsert (role_name 기준), mention_count 증가
  - E7 실행 후 narrative_memory 교체
  - 이것은 `commit_scene` RPC의 근사다. 차이는 README에 명시한다. 품질 평가 목적에는 충분하다.
- 재시도·fallback은 Q-02의 `scene_loop_policy.ts`를 import해서 **운영과 같은 규칙**으로 돈다.
- 실패한 케이스는 크래시하지 않고 `status: "failed"` + 실패 스테이지 + 코드로 기록한다.

**출력 (`eval/runs/<run_id>/`, gitignore)**

`run_id = <label>-<YYYYMMDDHHmm>-<config 해시 6자리>`

| 파일 | 내용 |
|---|---|
| `config.json` | 실행 설정 사본 + 프롬프트 버전 전체 + git 커밋 해시 |
| `results.jsonl` | 케이스당 1줄. 스테이지별 출력, 최종 장면(문단별 origin·text·element ids), 검증 결과, 시도 횟수, fallback 여부, 비용, 지연. sequence는 `scenes[]` |
| `summary.json` | 성공·실패·fallback 수, 검증 위반 코드 분포, 꿈당 비용 평균·최대, 지연 p50·p95 |

**콘솔 출력:** 케이스 id, 상태, 집계 수치만. **꿈 원문·생성 문장을 절대 출력하지 않는다.** 로깅은 `_shared/log.ts`의 허용목록을 쓴다.

**완료 조건**
- `--set fixtures`로 fake `LlmPort`(결정론적 응답) 실행 시 single 2 + sequence 1이 완주
- sequence에서 두 번째 꿈의 E2가 첫 꿈에서 만든 엔티티를 본다 (테스트로 증명)
- `--resume`이 완료 케이스를 건너뛴다
- 실행 후 `git status`에 `eval/runs/`가 나타나지 않는다

---

## Q-04 · 멀티 프로바이더 LLM 계층

**목적:** Groq 외의 모델을 작가 후보로 쓸 수 있게 한다. 현재 `callStructured`는 Groq URL과 `gsk_` 키 형식이 하드코딩되어 있다.

**구조**

```
_shared/llm/
  types.ts        StructuredCall · TextCall · 결과 타입 · ModelCallError
  registry.ts     "provider:model" → 어댑터, 단가(입력·출력 USD/1M), 기능 플래그
  groq.ts         현재 구현 이전 (동작 동일)
  anthropic.ts    신규
  openai.ts       신규
  port.ts         LlmPort 구현: role → model_config → registry → 어댑터
```

**요구사항**

1. **`text()` 추가** — Q-21의 산문 작가는 JSON이 아니라 평문을 받는다.
   ```ts
   text(req: TextCall): Promise<TextResult>;   // system, user(문자열), temperature, maxTokens
   ```
2. **구조화 출력 방식은 어댑터가 책임진다.**
   - Groq: 현재 방식 유지 (strict → 400이면 json_object 폴백)
   - Anthropic: 스키마를 도구 입력 스키마로 정의하고 해당 도구 호출을 강제
   - OpenAI: `json_schema` strict
   - 어느 경우든 **최종 검증은 기존 Zod 계약**이 한다
3. **공급자별 전용 파라미터는 어댑터 안에 가둔다.** `reasoning_effort: "low"`는 Groq/gpt-oss 전용이다. 다른 어댑터로 새지 않게 한다.
4. **키 형식 검사**는 어댑터별로. 키는 Edge Function secret에서만 읽는다.
5. **재시도:** 429·5xx에 한해 지수 백오프 2회. 4xx는 즉시 실패.
6. **프라이버시 (기존 규칙 유지):** 응답 본문을 에러 메시지·로그에 절대 넣지 않는다. 현재 `callStructured`의 에러 분류 방식을 그대로 따른다.
7. **단가:** `registry.ts`의 단가는 **구현 시점에 각 공급사 가격 페이지에서 확인해 기입**한다. 이 문서에 적지 않는다 (버전 사고 재발 방지). `estimatedCostKrw`가 레지스트리를 읽게 바꾼다.
8. **모델 ID도 이 문서에 확정하지 않는다.** 각 공급사 문서에서 현재 ID를 확인해 레지스트리에 넣는다.

**완료 조건**
- 어댑터 3종 각각 fetch 스텁 테스트: 정상, 스키마 위반, 429 재시도, 4xx 즉시 실패, 본문 미노출
- Groq 경로 동작 불변 (기존 `llm_test.ts` 통과)
- `MODEL_WRITE=anthropic:<id>`로 로컬에서 E4 1회 실제 호출 성공 (로컬 검증)

---

## Q-05 · 블라인드 A/B 판정 도구

**목적:** 사용자가 두 실행 결과를 **어느 쪽인지 모른 채** 비교하게 한다. 이 도구가 품질 개선의 유일한 판정 수단이다.

**CLI**

```bash
deno run -A tool/eval/judge.ts --a eval/runs/<runA> --b eval/runs/<runB> [--port 8787]
deno run -A tool/eval/report.ts eval/judgments/<runA>__<runB>.json
```

**서버**
- **`127.0.0.1`에만 바인딩한다.** LAN 노출 옵션을 만들지 않는다.
- 외부 리소스(CDN 폰트·스크립트)를 불러오지 않는다. 단일 HTML, 시스템 폰트.
- 판정할 때마다 `eval/judgments/<runA>__<runB>.json`에 원자적으로 저장한다 (임시 파일 → rename). 중단 후 재실행하면 이어서 한다.

**판정 화면**

```
┌────────────────────────────────────────┐
│ 12 / 21                     s2 · 연속   │
│ ▸ 원본 꿈 보기 (접힘)                    │
│ ─────────────────────────────────────  │
│  [ 왼쪽 ]              [ 오른쪽 ]        │  ← 좁은 화면에선 위아래로 쌓음
│  본문 (앱 Reader처럼                     │
│  부리 서체·들여쓰기,                     │
│  출처 표시 없음)                         │
│ ─────────────────────────────────────  │
│  [1] 왼쪽  [2] 오른쪽  [3] 비슷함        │
│  ☐ 이긴 쪽도 출시 수준 아님               │
│  이긴 이유: 자연스럽다 · 꿈에 충실 · 더 읽고 싶다 │
│  진 쪽 문제: AI·번역투 · 사실 오류 · 늘어짐 · 너무 짧음 │
│                          [n] 다음        │
└────────────────────────────────────────┘
```

- **좌우 배치는 케이스마다 무작위**, 시드를 판정 파일에 저장한다. 실행 라벨을 화면에 절대 표시하지 않는다.
- 비교 대상은 두 실행에 **공통으로 존재하는 케이스**다.
- 한쪽만 파이프라인 실패한 케이스는 **실패한 쪽의 패배**로 자동 기록하고 화면에 띄우지 않는다. 사용자가 아무것도 못 받는 것은 실제 제품 실패다.
- sequence는 장면 4개를 제목과 함께 이어서 보여준다. 하나의 판정 단위다.
- "출처 보기" 토글은 기본 OFF다. 판정 대상은 읽는 경험이다. 충실도는 Q-07이 잰다.
- 단축키: `1` `2` `3` `n`.

**리포트 (`report.ts`) 출력**
- 승·패·비슷함, **정확 이항 부호검정 단측 p값** (비슷함 제외)
- 파이프라인 실패로 인한 자동 패배 수 (별도 표기)
- 양쪽의 "출시 수준 아님" 비율
- 이유 칩 집계
- clarity별(fragment·partial·vivid)·종류별(single·sequence) 분해
- **게이트 판정:** 인자로 `--gate G1|G2|G3`를 받으면 §3.2 조건을 자동 판정해 PASS/FAIL 출력

**추가 모드 (Q-07·Q-22에서 사용)**
- `--mode fidelity-audit --run <run>` : 충실도 판정기 결과 15개를 보여주고 사용자가 동의/비동의 체크
- `--mode pick --candidates <file>` : 문체 예시 후보 중 고르기
- `--mode annotate --reference eval/reference/works.jsonl` : 레퍼런스 작품 라벨링 (Q-09). 문단 번호 탭, 선택지 칩, 한 줄 메모
- `--mode pro --a <run> --pro eval/pro/rewrites.jsonl` : 우리 출력 vs 작가 재작성본 블라인드 판정 (Q-22 납품 후, 프로 대비 승률)

**완료 조건**
- fixture로 만든 두 실행에서 판정 → 리포트 → 게이트 판정까지 동작
- 좌우 무작위가 판정 파일의 시드로 재현된다
- 서버가 `0.0.0.0`으로 바인딩되지 않는다 (테스트)

---

## Q-06 · 한국어 산문 린터

**목적:** AI 한국어 소설의 버릇을 숫자로 잰다. v10의 규칙 29번("나는 ~하려고 했다 연속 금지")이 말로 막으려던 것을 측정으로 바꾼다.

**위치:** `supabase/functions/_shared/prose_lint.ts` — 순수 함수. 러너(Q-03)와 검증기(Q-30)가 공유한다.

```ts
export function lintProse(paragraphs: readonly string[], voice: NarrativeVoice): ProseMetrics;
```

**지표 정의**

| 키 | 정의 | 비고 |
|---|---|---|
| `ending_top_share` | 가장 흔한 문장 종결(마지막 어절의 끝 2음절, 예 "했다")이 전체 문장에서 차지하는 비율 | 단조로움 |
| `ending_max_run` | 같은 종결이 연속된 최대 문장 수 | 3 이상이 누적되면 리듬 붕괴 |
| `subject_lead_rate` | 문두가 시점 주어로 시작하는 문장 비율. 1인칭 `나는·나도·내가`, 3인칭 `그는·그녀는·그가·그녀가` | 한국어는 주어를 생략한다 |
| `translationese_per_1k` | 1,000자당 번역투 패턴 수: `것이었다`, `에 대해(서)?`, `(을\|를) 가지고 있`, `되어지`, `에 있어(서)?`, `로 인해`, 문두 `그것은`, `중 하나` | |
| `named_emotion_per_1k` | 1,000자당 감정 명명: `(불안\|두려움\|공포\|슬픔\|그리움\|외로움\|안도\|설렘\|긴장)(감)?(이\|가)? (밀려\|몰려\|엄습\|차올\|스며\|피어)`, `(기분\|느낌\|감정)이 들었다`, `느껴졌다` | 감정은 몸과 사물로 |
| `simile_per_1k` | 1,000자당 `마치`, `듯이` | "처럼"은 제외 (정상 빈도가 높음) |
| `conj_lead_rate` | 문두 `그리고·그러자·그래서·하지만·그런데·그러나·그러고는` 비율 | |
| `sent_len_mean`, `sent_len_cv` | 문장 길이(자) 평균과 변동계수(표준편차/평균) | CV가 낮으면 단조로움 |
| `para_count`, `para_len_mean` | 문단 수와 평균 길이 | |
| `dialogue_ratio` | `“ ”` 또는 `" "` 안의 글자 비율 | |
| `meta_dream_hits` | V7 금지 표현 정규식 적중 수 | 기존 `BANNED_EXPRESSIONS` 재사용 |

**웹소설 호흡 지표 (v1.1 추가, Q-09 레퍼런스와 비교할 핵심 지표)**

| 키 | 정의 | 비고 |
|---|---|---|
| `one_sentence_para_rate` | 한 문장짜리 문단 비율 | 모바일 웹소설의 대표 호흡 |
| `mobile_lines_per_para` | 문단 글자 수 ÷ 20의 평균 (모바일 한 줄 ≈ 20자 환산) | 한 화면에 들어오는 밀도 |
| `present_tense_share` | 현재형 종결 문장 비율. 마지막 어절이 `다`로 끝나되 끝 3음절 안에 `었·았·였·했·겠`이 없는 문장 | 과거형 서술 속 현재형 혼용은 국내 1인칭 웹소설의 고유한 속도 장치 |
| `short_sentence_rate` | 8자 이하 초단문 비율 | 속말·단정·끊어 치기 |
| `ellipsis_dash_per_1k` | 1,000자당 `…`·`—` | 호흡 조절 부호 |
| `dialogue_para_rate` | 대사로 시작하는 문단 비율 | `dialogue_ratio`(글자 비율)와 별도 |
| `first_sentence_len` | 첫 문장 글자 수 | 도입 훅의 길이 |

**핵심 지표 10개 (레퍼런스 근접도 계산용):** `sent_len_mean`, `sent_len_cv`, `ending_top_share`, `subject_lead_rate`, `one_sentence_para_rate`, `mobile_lines_per_para`, `present_tense_share`, `short_sentence_rate`, `dialogue_ratio`, `first_sentence_len`.
번역투·감정 명명·직유 지표는 레퍼런스 중앙값이 0에 가까워 "범위 안"을 판정하기 어렵다. 근접도에서 빼고 Q-30에서 상한으로만 쓴다.

**측정하지 않는 것:** 대괄호 `[ ]` 상태창·시스템창 기호. 장르 문법이므로 레퍼런스에서도 제외한다.

**문장 분리:** `.` `!` `?` `…` 뒤에 공백·줄바꿈·문자열 끝, 따옴표 안의 마침표는 따옴표가 닫힐 때까지 한 문장으로 본다.

**임계값을 이 WO에서 정하지 않는다.** 지표만 산출한다. 임계값은 Q-30에서 **사용자가 이긴 쪽으로 고른 출력의 분포**로 정한다.

**러너 연동:** `--lint`면 각 결과에 `metrics`를 붙이고, `summary.json`에 지표별 중앙값·p90을 넣는다.

**완료 조건:** 지표마다 양성·음성 예문 단위 테스트. 따옴표 안 마침표, 말줄임표, 문두 공백 등 경계 사례 포함.

---

## Q-07 · 충실도 판정기

**목적:** 규칙 32개를 걷어낼 때 **사실 충실성이 무너지지 않았음을 증명**할 수단. v10 규칙의 대부분은 충실성 방어용이었다. 판정기 없이 규칙을 지우면 그게 무너져도 모른다.

**위치:** `_shared/fidelity_judge.ts` — `LlmPort.structured`, role `judge`.

**입력:** raw_text, recall_answers, elements, 생성 장면(문단별 origin·text·source_element_ids), narrative_voice

**출력 스키마**

```json
{
  "protagonist_is_recorder": true,
  "paragraphs": [
    {
      "index": 2,
      "origin": "D",
      "contradictions": [
        { "type": "agent_flip|recipient_flip|order|completion|attribute|other",
          "detail": "…" }
      ],
      "invented_concrete": ["원문에 없는 '빨간' 색"]
    }
  ],
  "missing_high_elements": ["el_…"]
}
```

- **판정 대상은 D 문단의 사실 변경·발명이다.** C 문단의 연결 서술은 발명이 허용된 영역이므로 contradictions만 본다.
- **감각적 질감(동작의 속도, 시선, 망설임)은 발명으로 치지 않는다.** 새 사물·인물·사건·속성(크기·색·재질·소유)만 발명이다. 판정기 프롬프트에 이 경계를 명시한다.
- `pass = protagonist_is_recorder && 모든 문단 contradictions 없음 && D 문단 invented_concrete 없음 && missing_high_elements 없음`
- **판정 모델은 작가 모델과 다른 모델**로 설정한다 (자기 선호 편향 방지).

**신뢰 검증 (필수):** Q-08에서 기준선 실행 결과 중 15건을 `judge.ts --mode fidelity-audit`로 사용자가 검수한다. **일치율 80% 미만이면 판정기 프롬프트를 고치고 재검수한다.** 검수를 통과하기 전에는 게이트 조건으로 쓰지 않는다.

**러너 연동:** `--fidelity`면 각 결과에 판정을 붙이고 `summary.json`에 통과율과 위반 유형 분포를 넣는다. `detail` 문자열은 `results.jsonl`에만 저장하고 콘솔에 출력하지 않는다.

---

## Q-08 · 기준선 측정 (로컬, 사용자 참여)

**선행:** Q-01~Q-07, 사용자의 dev 코퍼스 30개 준비

**절차**
1. `validate_corpus.ts`로 코퍼스 검증
2. `baseline_v10` 설정으로 dev 실행 (`--lint --fidelity`)
3. **충실도 판정기 검수** (Q-07, 15건, 일치율 ≥80%)
4. **권장: A/A 판정** — 같은 설정을 한 번 더 실행해 dev 10건만 기준선 vs 기준선으로 판정한다. 같은 것끼리인데 한쪽이 7승 이상이면 모델의 출력 편차나 판정 노이즈가 크다는 뜻이다. 이후 라운드 해석에 반영한다.
5. 결과를 `docs/quality/Q-08_baseline.md`에 기록한다 (**수치만**, 꿈·문장 인용 금지): 실패율, fallback율, 위반 분포, 충실도 통과율, 린터 지표 중앙값·p90, 꿈당 비용, 지연

**완료 조건:** `docs/quality/Q-08_baseline.md` 커밋. 이후 모든 비교의 기준이 된다.

---

## Q-09 · 레퍼런스 분석: 카카오페이지 웹소설의 몰입 문법

**목적:** "흡입력"의 기준을 모델이나 감이 아니라 **이미 독자가 증명한 작품**에서 가져온다. 에이전트는 흡입력을 느끼지 못한다. 그래서 흡입력이 검증된 작품의 **구조와 호흡을 숫자로 옮겨** 에이전트가 따라갈 수 있는 목표로 만든다.

**선행:** Q-06 (린터), Q-05 (판정 도구의 `annotate` 모드 추가)

### 작품 선정 (사용자)

| 기준 | 내용 |
|---|---|
| 출처 | 카카오페이지 연재작, **국내 작가 원작.** 번역 작품 제외 (목적이 한국어 고유 문체다) |
| 양성 그룹 | 네가 1화를 읽고 **실제로 다음 화를 눌렀던** 작품 **25편** |
| 대조군 (권장) | 1~3화에서 **이탈한** 작품 **5~8편**. 어떤 지표가 몰입을 가르는지 보기 위해서다 |
| 시점 | 1인칭 작품이 절반 이상 (무무몽 기본 시점이 `first_person_past`) |
| 장르 분산 | 현판·로판·판타지·로맨스·미스터리/호러 등. **한 장르가 40%를 넘지 않게** |
| 배경 | 현대 배경 우선. 꿈은 대부분 현대 일상을 재료로 한다 |

### 수집 단위 (작품당)

| 필드 | 분량 | 용도 |
|---|---|---|
| `opening` | 1화 첫 약 2,000자 | 도입 호흡, 첫 문장, 첫 사건 위치 |
| `ending` | 1화 마지막 약 600자 | 장면 끝 당김 |
| `next_opening` | 2화 첫 약 500자 (선택) | 회차 연결 방식 → 장면 간 연속성(Q-24) 참고 |

```jsonc
// eval/reference/works.jsonl  (gitignore)
{ "id": "r01", "group": "positive", "genre": "현판", "voice": "first",
  "opening": "…", "ending": "…", "next_opening": "…" }
```

### 수집·보관 규칙 (필수)

1. **네가 정당하게 열람할 수 있는 회차에서만** 직접 옮겨 적거나 붙여넣는다. **크롤러·스크래퍼·앱 추출·DRM 우회를 만들지 않는다.** 에이전트에게 수집 자동화를 시키지 마라.
2. 원문은 `eval/reference/`(gitignore)에만 둔다. **레포·문서·프롬프트·문체 예시·테스트 fixture에 원문을 인용하지 않는다.** 작품명도 커밋하지 않는다. 로컬 매니페스트에만 둔다.
3. **결정론 지표는 로컬 코드로만 계산한다.** 원문을 LLM에 보내지 않는다.
4. 라벨링은 **사용자가 직접** 한다 (아래). LLM 사전 라벨링을 쓰려면 API 데이터를 학습에 쓰지 않는 공급자로, **첫 문장과 마지막 문단만** 보낸다. 기본은 쓰지 않는 것이다.
5. `.gitignore`에 `/eval/reference/` 추가. `check_eval_privacy.sh` 대상에 포함.
6. `check_prompt_leak.ts`(Q-25)의 비교 대상에 레퍼런스 원문을 추가한다. **프롬프트에 레퍼런스 문장이 새어 들어가면 실패한다.**

### 사용자 라벨링 (`judge.ts --mode annotate`, 작품당 약 5분)

| 라벨 | 선택지 |
|---|---|
| `opening_type` 첫 문장 | 대사 / 행동 / 상황 제시 / 감각 / 속말·독백 / 설명 |
| `first_event_para` 첫 사건 | 인물이 무언가를 하거나 무언가가 일어나기 시작하는 **문단 번호**를 탭 |
| `reveal_by_2000` 2,000자 안에 드러난 것 | ☐ 주인공의 처지 ☐ 당장의 목표·문제 ☐ 이 이야기의 이상함(장르 약속) |
| `ending_type` 1화의 끝 | 새 인물·존재 등장 / 새 정보·반전 / 위기 직전 / 선택 직전 / 대사 한 줄 / 여운 이미지 |
| `hook_note` (선택) | "왜 다음 화를 눌렀나" 한 줄. 네 말로. **원문 인용 금지** |

### 분석 (`tool/eval/reference_profile.ts`)

1. 전 작품에 `lintProse` 실행 (`opening`, `ending` 각각)
2. 양성 그룹 지표별 **p10 / p25 / p50 / p75 / p90**
3. 라벨 분포: `opening_type`·`ending_type` 비율, `first_event_para` 중앙값, `reveal_by_2000` 항목별 비율
4. **대조군이 있으면** 양성 vs 대조군 중앙값 차이를 지표별로 계산. 표본이 작으니 **방향만 본다.** 유의성 주장은 하지 않는다
5. 1인칭 / 3인칭을 나눠서도 계산 (시점별로 호흡이 다를 수 있다)

### 산출물

| 파일 | 커밋 | 내용 |
|---|---|---|
| `_shared/reference_profile.ts` | ✅ | 지표별 분위수, 라벨 분포, 시점별 분해. **숫자만** |
| `_shared/reference_proximity.ts` | ✅ | `referenceProximity(metrics) → { inBand, of: 10, byMetric }` |
| `docs/quality/Q-09_reference_profile.md` | ✅ | 수치 표 + **몰입 문법 스펙** (아래). 원문·작품명 없음 |
| `eval/reference/manifest.json` | ❌ | 작품명·로컬 메모 |

**몰입 문법 스펙 (문서의 핵심 섹션):** 10줄 이내의 원칙. **모든 원칙은 근거 수치를 달고 있어야 한다.** 수치 없는 원칙은 쓰지 않는다. 예시 형식:

> - 첫 문장은 행동 또는 대사로 연다 — 양성 그룹 `opening_type` 행동 40%, 대사 28% *(예시 수치, 실제 값으로 대체)*
> - 한 문장 문단이 문단의 절반 안팎이다 — `one_sentence_para_rate` p50 0.48 *(예시)*

이 스펙이 Q-20(대본 구성), Q-22(문체 원칙·외주 브리프), Q-30(임계값)의 공통 근거가 된다.

**장르 문법 제외 목록을 스펙에 명시한다:** 회귀·빙의·환생 설정, 상태창·시스템창, 사이다 구조, 회차 분량. 레퍼런스에 있어도 무무몽 목표가 아니다.

**완료 조건**
- 양성 25편 이상 수집·라벨링 완료
- `reference_profile.ts` 생성, `referenceProximity` 단위 테스트 (합성 데이터)
- `Q-09_reference_profile.md`에 몰입 문법 스펙과 근거 수치
- `git ls-files`에 원문·작품명이 없음 (CI 가드 통과)
- **Q-08 기준선의 레퍼런스 근접도를 계산해 기록** — 지금 v10이 실제 작품에서 얼마나 떨어져 있는지가 첫 번째 숫자다

---

# P1 · 모델

## Q-10 · 작가 모델 베이크오프

**목적:** 가장 싸고 가장 큰 레버부터 검증한다. **프롬프트는 v10 그대로 두고 작가 모델만 바꾼다** (원칙 2).

**후보:** 기준선(`gpt-oss-120b`) + 한국어 산문에 강하다고 판단되는 프런티어 모델 **3개 이내**. 한국어 특화 모델을 API로 쓸 수 있으면 1개 포함을 권장한다. **어느 모델이 이길지 이 문서가 정하지 않는다.** 그걸 정하는 게 이 WO다.

**교체 범위:** v10에서 문장을 만드는 호출 전체(`write`, `write_aux`, `polish`)를 후보 모델로 바꾼다. `extract`, `link`, `plan`, `remember`는 고정한다.

**절차**

1. 후보별 설정 파일 `eval/configs/bakeoff_<후보>.json` 생성
2. **자동 1차 선별:** 전 후보를 dev에 `--lint --fidelity`로 실행. 아래에 해당하면 탈락
   - 파이프라인 실패율 > 5%
   - 충실도 통과율 < 기준선 − 5%p
   - 꿈당 비용 > 200원
3. **사람 판정:** 생존 후보를 각각 **기준선 대비** 블라인드 판정 (후보당 21단위, 약 25~30분)
4. G1을 통과한 후보가 2개 이상이면 **그 둘끼리** 한 번 더 판정
5. `docs/quality/Q-10_model_decision.md` 기록: 후보별 자동 지표, 판정 결과·p값, 비용, 지연, 결정과 이유

**완료 조건:** G1 통과 모델 1개 확정. **통과 모델이 없으면** 그 사실을 기록하고 P2로 넘어간다. 그 경우 P2는 기준선 모델 위에서 진행한다.

---

## Q-11 · 승자 모델 운영 반영 (선택, 조기 개선)

**목적:** P2를 기다리지 않고 운영 문장 품질을 먼저 올린다.

**필수 선행 — 이걸 빼먹으면 출시 불가:**
1. **공급자 고지 갱신.** PDR §25는 꿈 원문이 어느 회사로 가는지 명시하도록 요구한다. 새 공급자가 추가되면 S01 온보딩 고지 문안을 갱신하고, 그 공급자의 API 약관(학습 사용 여부·보존 기간)을 확인해 **사실대로** 적는다.
2. **`consent_version` 증가.** 기존 사용자는 다음 실행 시 새 고지에 다시 동의해야 E4 호출이 진행된다. 동의 전 제출된 꿈은 큐에 대기한다.
3. **Edge Function secret 등록** (staging → prod 순).

**반영:** `MODEL_WRITE`, `MODEL_WRITE_AUX`, `MODEL_POLISH` 환경변수만 바꾼다. 코드 변경 없음.

**완료 조건:** staging에서 `tool/cloud_pipeline_smoke.mjs` 통과 → prod 반영 → 첫 24시간 `generation_runs`의 실패율·비용·지연을 확인해 `docs/quality/Q-10_model_decision.md`에 추가 기록.

---

## Q-12 · 경쟁 AI 집필 도구 기준선 (선택)

**목적:** 국내 AI 웹소설 집필 도구의 출력을 판정 대상에 섞어 "업계 수준 대비 어디쯤인가"를 본다.

**절차**
1. 공개 이용 가능한 도구 1~2개 선택
2. dev single 중 6개(fragment·partial·vivid 각 2)를 **사용자 본인의 꿈으로 한정해** 수동 입력. 각 도구의 이용약관에서 입력 데이터 처리 조건을 먼저 확인한다
3. 결과를 `eval/runs/competitor-<도구>-<ts>/results.jsonl`에 Q-03과 같은 형식으로 수동 저장 (origin은 전부 `C`로 표기, 출처 비교 대상 아님)
4. Q-10 승자와 블라인드 판정. 게이트 아님, 기록만

**완료 조건:** `docs/quality/Q-12_competitor.md`에 승패와 이유 칩 분포 (도구명·수치만).

---

# P2 · 구조 (v11)

**P2의 모든 변경은 `ENGINE_VERSION=v11`일 때만 활성화된다.** v10 경로는 컷오버(Q-32)까지 한 줄도 바꾸지 않는다.

## 설계 개요: 사실과 문장의 분리

```
v10:  E3 plan(beats, 느슨) ──▶ E4 write(raw_text+beats+설정 JSON 전부 → JSON 산문, 규칙 32개)
                                  └▶ expansion(문단별 고립 확장) └▶ polish(재수선)

v11:  E3 plan.v7  "장면 대본"   사실만 확정. 비트마다 행위자·행동·대상·상태. 문장 없음
          │
          ▼
      E4 write.v11 "산문화"     대본 + 문체 바이블 → 평문. 문단마다 [[b번호]] 마커
          │                     raw_text도 JSON 설정도 받지 않는다
          ▼
      assemble (코드)            마커 → origin·source_element_ids 결정론적 부여
          │                     → 기존 SceneDraft 계약 그대로 (E5·E6 무변경)
          ▼
      E5 validate               V1~V7 + V8 충실도(Q-31) + V9 린터(Q-30)
```

**핵심 이득 셋:**
1. **출처가 결정론적이 된다.** 지금은 모델이 스스로 "이 문단은 D"라고 라벨을 붙인다. v11에서는 문단이 가리키는 비트의 종류로 코드가 정한다. 모델이 출처 라벨을 틀릴 수 없다.
2. **작가 모델이 문장에만 집중한다.** 사실 확정은 대본 단계가 끝냈다.
3. **E5·E6가 바뀌지 않는다.** 조립 결과가 기존 `SceneDraft` 계약과 같기 때문이다.

---

## Q-20 · 장면 대본 (plan.v7)

**`[신규] _shared/prompts/plan.v7.ts`**, **`[수정] stage_contracts.ts`** (v7 스키마 추가, v6 유지)

**출력 스키마 (v7)**

```ts
{
  placement, attach_to_scene_id, scene_title, target_length,   // v6와 동일
  beats: [
    {
      id: "b1",                                   // b1부터 순서대로
      kind: "D" | "C",
      element_ids: string[],                      // D는 1개 이상
      fact: string,                               // 한 문장 평서문. 역할명. 문체 없음
      actor: string | null,                       // 역할명 또는 "나"(기록자)
      action: string,
      target: string | null,
      recipient: string | null,
      purpose: string | null,
      status: "attempted" | "interrupted" | "ongoing" | "completed" | null
    }
  ],
  open_image: string,                             // 장면을 닫지 않는 마지막 이미지 한 줄
  hook_beat: "b1" | null,                         // 첫 장면이면 반드시 "b1"
  opening_type: "dialogue" | "action" | "situation" | "sense" | "inner_voice",   // v1.1
  ending_type: "new_presence" | "new_info" | "brink" | "choice" | "line" | "image", // v1.1
  new_entities: [ { role_name, type, from_element } ],   // v10에선 writer가 냈음
  used_entities: string[]                                 // v10에선 writer가 냈음
}
```

`open_image`, `new_entities`, `used_entities`를 작가에서 대본으로 옮긴다. 이것들은 문장이 아니라 사실이다.

**plan.v7 시스템 프롬프트 초안** (v10 규칙 중 충실성 관련을 **일반화해서** 이관)

```
당신은 꿈 기록을 소설 장면의 대본으로 옮기는 편집자다. 문장을 쓰지 않는다. 사실만 확정한다.

사실 확정
1. 꿈을 기록한 사람이 주인공이다. 기록자와의 관계로 불린 인물(남자친구, 엄마, 친구 등)은 다른 인물이다.
2. 한국어 원문에서 생략된 주어가 문맥상 기록자의 행동이면 기록자("나")로 복원한다.
3. 누가(actor)·무엇을(action)·무엇에(target)·누구에게(recipient)·왜(purpose)를 원문대로 옮긴다. 방향을 뒤집지 않는다.
4. 원문이 끝내지 않은 행동은 끝내지 않는다. status로 표시한다.
5. 원문에 없는 속성(크기·색·재질·소유·감정)을 D 비트의 fact에 넣지 않는다.
6. 사건 순서는 원문 순서를 따른다.
7. salience가 high인 요소는 반드시 D 비트 하나 이상에 들어간다.
8. 인물은 역할명으로 부른다. 입력에 없는 이름을 만들지 않는다.
9. 사람이든 동물이든 다른 존재의 속마음은 원문에 있을 때만 fact에 쓴다.

장면 구성
- 비트 수는 재료에 비례한다: fragment 1~3, partial 3~6, vivid 5~9.
- C 비트는 사실 사이를 잇는 데만 쓰고, 수는 adaptation_budget 안에 둔다.
- 첫 장면이면: b1은 주인공의 즉각적인 행동이나 문제다. 이미 진행 중인 이야기처럼 시작하지 않는다.
  이상 징후 → 주인공의 선택 → 그 선택의 결과로 흐르되, 원문의 최종 목적은 완료하지 않는다.
- open_image는 원문 요소나 C 비트에서만 가져온다. 결말·해석·교훈이 아니다.
- opening_type과 ending_type은 {reference_opening_types}와 {reference_ending_types}의 비율을 참고해 고르되,
  꿈 재료가 허락하는 것만 고른다. 원문에 말이 없으면 dialogue로 열지 않는다.
- 첫 사건(주인공이 무언가를 하거나 무언가가 일어나는 비트)은 {reference_first_event}번째 비트 안에 둔다.
- scene_title은 꿈 속 구체적인 사물·장소·행동에서 2~12자로 짓는다. 작품 바깥을 설명하는 제목 금지.

(배치 판정 규칙은 plan.v6에서 그대로 가져온다)
```

`{reference_*}` 자리표시자는 Q-09 `reference_profile.ts`에서 채운다. **레퍼런스 분포를 프롬프트에 숫자로 넣는다. 레퍼런스 원문은 절대 넣지 않는다.**

**코드 측 정규화 (`enforcePlan` 확장, v7 전용)**
- 모든 `element_ids`가 입력 elements에 존재 → 아니면 해당 id 제거, D 비트가 비면 C로 강등하지 말고 **V1 위반으로 재시도**
- high salience 요소가 어떤 D 비트에도 없으면 재시도 (피드백: 누락 element id 목록)
- 첫 장면이면 `hook_beat === "b1"`이고 b1이 D
- `opening_type === "dialogue"`인데 b1 요소 중 발화가 없으면 → `action`으로 정규화
- `opening_type`·`ending_type`은 작가 프롬프트의 `[설정]` 블록에 한 줄로 전달된다 (Q-21)
- 비트 수가 clarity 범위를 벗어나면 재시도
- beat id가 `b1..bN` 연속
- `scene_title` 정규화는 기존 `normalizeSceneTitle` 재사용

**완료 조건:** v7 스키마 테스트, 정규화 규칙별 테스트, fixture로 v7 계획 생성 후 러너에서 확인.

**하지 말 것:** 대본에 문장·묘사·분위기를 넣지 마라. `fact`는 건조한 평서문이다. 문체는 전부 Q-21·Q-22의 몫이다.

---

## Q-21 · 산문 작가 v11

**`[신규] _shared/prompts/write.v11.ts`**, **`[신규] engine-write/prose_markers.ts`**, **`[수정] engine-write/core.ts`** (v11 분기)

### 입력: JSON이 아니라 원고 청탁서처럼

`LlmPort.text()`로 호출한다. user 메시지는 아래 형식의 평문이다.

```
[설정]
시점: 1인칭 과거 / 문체: 담백하게 / 분량: 약 900자, 넘지 않는다
여는 방식: 행동으로 연다 / 닫는 방식: 선택 직전에서 멈춘다

[이전 장면의 끝]            ← 첫 장면이면 이 블록 생략
(직전 장면 마지막 2문단 원문)

[지금까지의 이야기]         ← 첫 장면이면 생략
(story_so_far)

[이번 장면 대본]
b1 · 꿈 · 나는 책상 위의 상자를 들어 올린다 (진행 중)
b2 · 꿈 · 상자 안에서 개미들이 줄지어 나온다
b3 · 연결 · 상자를 내려놓을지 망설이는 순간으로 잇는다
b4 · 꿈 · 나는 상자를 엄마에게 가져간다 (시도, 미완료)

[마지막 이미지]
상자 틈으로 계속 빠져나오는 검은 줄
```

(위 대본 내용은 형식 예시다. **이 예시를 프롬프트 파일에 넣지 마라.**)

### 시스템 프롬프트 초안 (write.v11)

```
당신은 한국어 소설가다. 주어진 장면 대본을 소설의 한 장면으로 쓴다.

대본의 각 비트는 이미 확정된 사실이다. 사실을 더하거나 바꾸지 않는다.
대신 그 사실이 벌어지는 순간을 쓴다. 몸의 움직임, 손에 닿는 것, 눈에 들어오는 것, 망설임과 판단.
'연결' 비트는 앞뒤 사실을 잇는 짧은 문단으로 쓴다.
이 이야기는 꿈이 아니라 지금 실제로 벌어지는 일처럼 쓴다.

{voice_section}

{style_section}
예시는 문체만 참고한다. 예시의 소재·사물·문장을 가져오지 않는다.

출력 형식
- 문단마다 맨 앞에 그 문단이 쓰는 비트 번호를 [[b1]]처럼 붙인다.
- 한 문단은 한 비트만 쓴다. 한 비트를 여러 문단으로 나눠도 된다.
- 문단 사이는 빈 줄 하나. 번호 표시 외에 제목·설명·메모를 쓰지 않는다.
- 마지막 문단은 [마지막 이미지]로 끝난다.
{sensitive_line}
{retry_feedback}
```

**`voice_section` — first_person_past (기본값)**
```
시점은 1인칭 과거다. 화자 "나"는 이 꿈을 꾼 사람이다.
"나는"을 문장마다 쓰지 않는다. 주어가 분명하면 생략한다.
다른 사람과 생물의 속마음은 쓰지 않는다. 보이는 행동과 들리는 말만 쓴다.
```
**third_person_past**는 같은 구조로 "초점 인물은 꿈을 꾼 사람이다"로 쓴다.

**`sensitive_line`** — `sensitive_flags`가 있을 때만 주입: `자극적인 세부를 쓰지 않는다. 암시와 생략으로 처리한다.`

**`retry_feedback`** — 코드가 위반 목록으로 생성 (아래 참조). 첫 시도에는 없다.

**이 프롬프트에서 사라진 것:** origin 라벨링, element id, JSON 형식, 제목 생성, 엔티티 목록, 분량 하한, 문단 수 강제, 특정 꿈 대응 규칙, 금지 표현 목록. 전부 코드·대본·검증기로 옮겨갔다 (§5.1 이관표).

### 파서와 조립 (`prose_markers.ts`, 순수 함수)

```ts
export function parseProse(text: string, beats: PlanBeat[]): ParseResult;
export function assembleSceneDraft(plan: PlanV7, parsed: ParsedProse): SceneDraft;
```

**파싱 규칙**
- 빈 줄 기준으로 문단을 나눈다. 각 문단은 `^\[\[b(\d+)\]\]\s*`로 시작해야 한다
- 첫 마커 앞 텍스트, 마커 없는 문단, 존재하지 않는 비트 번호 → **V1 위반**
- 마커만 있고 본문이 빈 문단은 제거
- 모든 D 비트가 한 문단 이상에 등장 → 아니면 **V5 위반** (누락 비트 번호를 피드백에 담음)
- C 비트는 누락 허용
- 비트 순서가 뒤바뀌면 **허용하되 기록**한다 (`order_deviation: true`). 문학적 재배치일 수 있다. 사실 순서 위반 여부는 V8이 본다

**조립 규칙**
- `origin` = 문단이 가리키는 비트의 `kind`
- `source_element_ids` = 비트의 `element_ids`
- `c_reason` = C 비트의 `fact`
- `scene.title` = `plan.scene_title`, `open_image` = `plan.open_image`
- `new_entities`, `used_entities` = 대본에서 그대로
- **결과는 기존 `SceneDraft` 계약과 완전히 같은 모양이다.** E5·E6은 수정하지 않는다

### 재시도 피드백 (코드 생성, 한국어)

| 위반 | 피드백 예 |
|---|---|
| V1 | `모든 문단은 [[b번호]]로 시작해야 한다. 대본에 없는 번호(b7)를 썼다.` |
| V2 | `연결 문단 비율이 42%다. 35% 이하로 줄이고 꿈 비트 문단을 늘린다.` |
| V4 | `1,340자다. 1,100자를 넘지 않는다.` |
| V5 | `b2, b4 비트가 빠졌다. 모든 꿈 비트를 쓴다.` |
| V7 | `금지 표현이 2곳 있다. 꿈이라는 사실을 드러내지 않는다.` |
| V8 (Q-31) | `3번째 문단이 대본에 없는 사실(색)을 추가했다. 대본의 사실만 쓴다.` |
| V9 (Q-30) | `같은 종결어미가 6문장 연속이다. 종결을 섞는다.` |

**피드백에 생성 문장을 인용하지 않는다.** 위반 종류·위치·수치만.

### 이어 붙이기 (`fragment_attach`)
대상 장면의 마지막 2문단을 `[이전 장면의 끝]`으로 주고, 작가는 새 문단 1~2개만 쓴다. 잠긴(U) 문단이 끝에 있어도 **맥락으로만** 제공된다. 작가 출력은 마커 문단뿐이므로 U 문단을 복사할 경로가 없다. V6은 그대로 유지한다.

**완료 조건**
- 파서: 정상, 첫 마커 앞 텍스트, 없는 번호, D 비트 누락, 빈 문단, 순서 뒤바뀜 — 각각 테스트
- 조립: origin·element ids가 비트에서 결정론적으로 나온다 (모델 출력과 무관함을 테스트로 증명)
- 조립 결과가 기존 `SceneDraft` Zod 스키마를 통과
- 재시도 피드백 포맷 테스트 (생성 문장 미포함 확인)

---

## Q-22 · 문체 바이블 3종과 작가 외주

**목적:** 문체를 금지 규칙이 아니라 **레퍼런스 수치 + 프로 작가 예시**로 정의한다. v1.0의 "모델이 만든 후보 중 고르기"는 폐기한다. 모델의 문체 감각이 천장이 되기 때문이다.

### 22-A. 문체 구조의 재정의

**기본 레지스터 = Q-09 레퍼런스 프로파일(국내 웹소설체).** 담백/서정/영화적은 별개의 문체가 아니라 **이 레지스터 안의 변주**다. 모든 문체의 핵심 지표는 레퍼런스 **p10–p90 안**에 머문다.

| 문체 | 레지스터 안에서의 이동 (목표 방향) |
|---|---|
| 담백하게 (기본) | `one_sentence_para_rate`·`short_sentence_rate` → p75 쪽, 수식어 최소, 비유 장면당 1개 이하 |
| 서정적으로 | `sent_len_cv` → p75 쪽 (긴 문장과 초단문의 대비), 감각 묘사 비중 ↑, `ellipsis_dash_per_1k` 허용 범위 상단 |
| 영화적으로 | `present_tense_share`·`dialogue_para_rate` → p75 쪽, 컷 단위 문단, 시각·청각 디테일 |

`_shared/style/*.ts`에 **목표 방향**을 코드로 둔다. Q-30 린터 게이트가 문체별로 다른 밴드를 쓴다.

```ts
export interface StyleBible {
  version: string;                         // "plain.v2"
  principles: string[];                    // 긍정형 5개 이내, 각 원칙은 Q-09 스펙 근거에서 도출
  exemplars: { id: string; text: string; source: "pro" | "interim" }[];  // 3개
  targets: Partial<Record<CoreMetric, "p25" | "p50" | "p75">>;           // 레지스터 내 목표 위치
}
```

**공통 원칙은 Q-09 몰입 문법 스펙에서 가져온다.** v1.0의 공통 원칙 초안(주어 생략, 감정은 몸으로, 문장 길이 섞기, 한 문단 한 움직임, 의미는 장면으로)은 **스펙 수치가 뒷받침하는 것만** 남긴다.

**시제:** 기본 시점은 `first_person_past`지만, 레퍼런스에서 확인되는 **과거형 서술 속 현재형 혼용**은 `present_tense_share` 범위 안에서 허용한다. 시점 설정 위반이 아니라 국내 웹소설의 속도 장치다. Q-21 voice_section에 "서술은 과거형이 기본이지만 긴박한 순간에는 현재형을 섞을 수 있다"를 추가한다. **Q-09에서 이 혼용이 실제로 확인되지 않으면 이 줄을 넣지 않는다.**

### 22-B. 작가 외주 (주 경로)

**이 시리즈에서 가장 비싸고 가장 가치 있는 항목이다.** 발주는 Q-09 스펙이 나오는 즉시 한다 (§2 참조).

**작가 조건**
- 카카오페이지 또는 동급 플랫폼 **유료 연재 경력**
- 1인칭 현대물 경험
- **1명**을 원칙으로 한다. 여러 명이면 문체가 섞인다

**납품물**

| 구분 | 내용 | 분량 |
|---|---|---|
| **A. 문체 예시** | 지어낸 상황 3개 × 문체 3종 = **9편**. 1인칭, 각 300~450자. Q-09 스펙과 22-A 표를 브리프로 전달 | 약 4,000자 |
| **B. 고쳐 쓰기 쌍** | **지어낸 꿈 30개**로 우리 엔진이 쓴 장면을 작가가 다시 쓴다. **조건: 대본(beats)의 사실을 바꾸지 않는다.** 사실을 바꾸면 이 쌍이 "각색으로 꿈을 덮는 법"을 가르치게 된다 | 30편 |
| **C. 고친 이유 (선택)** | B의 각 편에 문단별 한 줄 메모. "왜 이렇게 고쳤나" | — |

**B에 가짜 꿈을 쓰는 이유:** 이 쌍은 작가 프롬프트의 퓨샷으로 들어가 **모든 사용자에게 전송될 수 있다.** 실제 꿈(사용자 본인 것 포함)을 쓰면 공개 레포와 프롬프트로 새어나간다. 가짜 꿈 30개는 작가에게 함께 발주하거나 사용자가 지어서 준다. dev·holdout 코퍼스와 겹치지 않게 한다 (`check_prompt_leak.ts`가 확인).

**B의 원고(엔진 초안)는 Q-10 승자 모델 + v10으로 만든다.** v11이 나오면 v11 초안으로 10편을 추가 발주할지 그때 판단한다.

**계약서에 반드시 들어갈 조건**
1. **저작권 양도** (2차적저작물작성권 포함)
2. **AI 프롬프트·평가·모델 학습 이용의 명시적 허락**
3. **인간 창작 보증** — AI 생성 문장을 납품하지 않는다. AI가 쓴 걸 받으면 v1.0의 순환이 그대로 돌아온다
4. **기존 저작물 문장 미사용 보증**
5. 비밀유지

**납품물의 쓰임**

| 납품물 | 쓰임 |
|---|---|
| A | 문체 바이블 `exemplars` (source: `"pro"`) |
| B | ① 작가 프롬프트에 **대조 퓨샷 1쌍**("엔진 초안 → 작가 원고")을 문체별로 넣는 실험 (Q-25 한 라운드) ② **프로 대비 승률** 측정 앵커 (§3.2) ③ Q-40 데이터와 함께 향후 학습 시드 |
| C | 공통 원칙 문구 다듬기. 작가의 말을 **추상화해서** 원칙으로 옮긴다. 그대로 인용하지 않는다 |

B 전체는 `eval/pro/rewrites.jsonl`(gitignore)에 둔다. 퓨샷으로 채택된 1~3쌍만 `_shared/style/`에 커밋한다 (가짜 꿈 기반이라 커밋 가능).

### 22-C. 임시 경로 (외주 납품 전)

1. 공통 원칙과 문체별 원칙을 Q-09 스펙 수치로 작성
2. Q-10 승자 모델로 상황 3개 × 문체 3종 × 후보 5개 생성
3. **레퍼런스 근접도로 1차 필터** — 문체별 목표 밴드를 벗어난 후보 제거
4. 남은 후보 중 사용자가 선택 (`judge.ts --mode pick`)
5. `source: "interim"`으로 표시
6. **작가 A 납품 후 교체하고, Q-25에서 interim vs pro 한 라운드를 판정한다.** pro가 지면 그 사실 자체가 중요한 정보다. 브리프가 잘못됐거나 작가 선정이 잘못된 것이다

### 22-D. 공통 제약 (v1.0 유지)

- 실제 꿈으로 예시를 만들지 않는다
- 출간 작품·레퍼런스 원문을 인용하지 않는다
- 꿈에 자주 나올 사물을 예시 소재로 피한다
- `exemplar_overlap` 지표 유지 (출력과 예시 사이 6글자 이상 공통 부분 문자열. 3 이상이면 라운드 무효)

**완료 조건**
- 문체당 원칙 ≤5줄, 예시 3개, 각 300~450자, 문체별 바이블 전체 2,000자 이하 (테스트)
- 각 원칙에 Q-09 근거 수치가 주석으로 달려 있음
- 문체별 `targets`가 레퍼런스 p10–p90 밖을 가리키지 않음 (테스트)
- 외주 계약서에 22-B 조건 5개 포함 (사용자 확인)

---

## Q-23 · 분량 정책 복원 (v11)

**목적:** PDR P2 "부풀리지 않는다"로 되돌린다. 패딩이 AI 냄새의 정체다.

**v11 경로에서:**
1. `target_length` = 대본의 `target_length` (≤ `lengthCapFor(clarity, adaptation)`). 첫 장면만 상한에 ×1.3 허용. **하한 없음.**
2. V4는 **상한만** 검사한다. `minimumChars`, `minimumPassages`를 v11에서 넘기지 않는다.
3. `FIRST_SCENE_OPENING_CONTRACT`의 `paragraph_range`, `minimum_target_ratio`, `passage_length_chars`, `provenance_mix`를 v11에서 쓰지 않는다. `stages`(훅 → 욕구 → 이상 → 선택 → 결과)는 plan.v7의 장면 구성 원칙으로 이미 옮겨갔다.
4. `opening_expansion`, `opening_polish`를 v11에서 호출하지 않는다.

**완료 조건**
- fake `LlmPort` 스파이로 v11 경로에서 `write_aux`·`polish` 역할이 **호출되지 않음**을 테스트
- v11에서 짧은 장면이 V4 하한 위반을 받지 않음을 테스트
- v10 경로의 동작 불변 (기존 테스트 통과)

**코드 삭제는 컷오버 후(Q-32)에 한다.** 지금은 분기만.

---

## Q-24 · 연속성 컨텍스트 (v11)

**목적:** 장면이 바뀌어도 같은 책처럼 읽히게 한다.

1. 첫 장면이 아니면 `[이전 장면의 끝]`에 직전 장면 마지막 2문단을 **출처와 무관하게** 원문 그대로 넣는다. 문체의 연속성은 요약이 아니라 실제 문장에서 온다.
2. `[지금까지의 이야기]`에 story_so_far (≤1,500자)와 열린 스레드 목록.
3. 작가 프롬프트 `voice_section` 뒤에 한 줄 추가 (첫 장면이 아닐 때만):
   - `continuation`: `이전 장면의 끝에서 바로 이어진다. 앞 장면을 다시 요약하지 않는다.`
   - `motif`·`interlude`: `시간이나 장소가 바뀐다. 첫 문장에서 전환을 짧게 보여주고, 앞 장면을 요약하지 않는다.`
4. 러너 지표 `recap_overlap`: 새 장면 첫 문단과 이전 장면 사이 6글자 이상 공통 부분 문자열 수. 높으면 요약 반복이다.

**완료 조건:** sequence fixture에서 두 번째 장면 호출에 이전 장면 끝이 포함됨을 테스트. dev sequence 3개로 Q-25 판정에 포함.

---

## Q-25 · v11 튜닝 라운드 (dev만, 최대 3회)

**비교 기준:** v10 + G1 승자 모델 (없으면 기준선 모델)

**라운드 규칙**
1. **라운드마다 바꾸는 것은 하나다.** 대본 프롬프트, 작가 프롬프트, 문체 바이블 중 하나. 가설을 먼저 쓴다.
2. `docs/quality/Q-25_rounds.md`에 기록한다: 라운드 번호, 가설 한 줄, 바꾼 파일, 자동 지표 변화, 판정 결과. **꿈·문장 인용 금지.**
3. 판정은 **현재 최고 버전 vs 새 버전**으로 한다. 이긴 쪽이 다음 라운드의 기준이 된다.
4. 매 라운드 **레퍼런스 근접도**와 (납품 후) **프로 대비 승률**을 함께 기록한다. 판정은 이겼는데 근접도가 떨어지면, 모델이 레퍼런스와 다른 방향의 "그럴듯함"으로 가고 있다는 신호다. 다음 라운드 가설에 반영한다.
5. 마지막 라운드의 최고 버전이 v10 기준선을 상대로 **G2**를 통과해야 P3로 간다.

**과적합 방지 장치 (필수)**

`[신규] tool/eval/check_prompt_leak.ts` — 로컬 전용. 프롬프트·바이블 파일(`_shared/prompts/`, `_shared/style/`)에서 **코퍼스 꿈 또는 레퍼런스 원문(`eval/reference/`)과 8글자 이상 겹치는 부분 문자열**을 찾으면 실패한다. **v10 규칙 18번이 정확히 이 사고다.** 라운드마다 실행한다. 출력은 파일명과 줄 번호만, 겹친 문자열은 출력하지 않는다.

**3라운드 안에 G2를 못 넘으면:** 멈추고 `Q-25_rounds.md`의 판정 이유 칩 분포를 들고 전략을 다시 짠다. 네 번째 라운드를 돌리지 마라.

---

# P3 · 운영 게이트와 컷오버

## Q-30 · 린터 소프트 게이트 (V9)

**임계값 산출 (v1.1 교체):** **Q-09 레퍼런스 양성 그룹 분포**에서 가져온다. v1.0의 "사용자가 고른 출력의 p90"은 순환이라 폐기한다.
- 핵심 지표 10개: 문체별 목표 밴드 = 레퍼런스 **p10–p90**. 밴드 밖이면 초과로 본다
- 번역투·감정 명명·직유: 레퍼런스 **p90을 상한**으로 쓴다
- `_shared/prose_lint_thresholds.ts`가 `reference_profile.ts`에서 **자동 산출**한다. 손으로 숫자를 적지 않는다

**동작 (v11만):**
- V1~V7 통과 후 린터 실행
- 임계값을 넘는 지표가 **2개 이상**이면 1회 재생성, 피드백은 해당 지표만 (Q-21 표 형식)
- 재생성 후에도 넘으면 **그대로 통과시킨다.** 문체 때문에 꿈을 실패시키지 않는다
- 결과는 `generation_runs.validation`에 지표 수치로 기록

**완료 조건:** 임계값 초과 → 재생성 1회 → 통과를 테스트. 재시도 총량이 기존 상한을 넘지 않음을 테스트.

---

## Q-31 · 충실도 게이트 (V8) 운영 반영

**선행:** Q-07 검수 일치율 ≥80%

**동작 (v11만):**
- V1~V7 통과 후 충실도 판정기 실행 (Q-30보다 먼저)
- `contradictions` 있음 → 재생성, 피드백에 문단 순번과 위반 유형만
- D 문단 `invented_concrete` 있음 → 재생성, 같은 방식
- 재시도 상한 도달 → 기존 fallback 경로
- 판정기 호출은 `generation_runs`에 role `judge`로 기록

**운영 상한:** 판정기가 p95 지연을 **15초 이상** 늘리거나 꿈당 비용을 **50% 이상** 늘리면, 더 가벼운 판정 모델로 바꾸고 Q-07 검수를 다시 한다.

**완료 조건:** 위반 유형별 재생성 테스트, fallback 전이 테스트, 비용·지연 측정치 기록.

---

## Q-32 · holdout 게이트와 컷오버

**절차**
1. `check_prompt_leak.ts`를 **holdout 포함**으로 실행 → 통과
2. v11 최종 설정과 v10(승자 모델)을 holdout에 실행 (`--lint --fidelity`)
3. 블라인드 판정 (7단위) → `report.ts --gate G3`
4. **G3 통과 시:**
   - staging에서 `ENGINE_VERSION=v11` → `tool/cloud_pipeline_smoke.mjs` 통과
   - prod에서 `ENGINE_VERSION=v11`
   - **v10 경로를 14일 유지한다.** 롤백은 환경변수 하나
   - 14일 동안 `generation_runs`를 engine_version별로 비교: 실패율, fallback율, 비용, 지연
   - 14일 후 정리 커밋: `write.v1.ts`(v10), `opening_expansion.ts`, `opening_polish.ts`, `plan.v6.ts`, V4 하한 코드, `FIRST_SCENE_OPENING_CONTRACT`의 미사용 필드 삭제
5. **G3 실패 시:** holdout은 이미 소모됐다. **사용자가 새 holdout 꿈 10개를 모은 뒤에만** 다시 G3를 시도한다. 같은 holdout으로 재시도하면 그건 dev다.

**완료 조건:** prod 전환, 14일 모니터링 기록, 정리 커밋. `docs/STATUS.md`에 "AI 생성: write.v11 / plan.v7 / <모델>" 갱신.

---

# P4 · 데이터 플라이휠

## Q-40 · 편집 선호 데이터 수집

**목적:** 파인튜닝을 지금 하지 않는다. 대신 **나중에 쓸 수 있는 유일한 고유 데이터를 지금부터 쌓는다.** 사용자가 AI 문단을 고친 기록은 "AI 문장 → 사람이 더 낫다고 판단한 문장" 쌍이다. 이 데이터는 무무몽에만 쌓인다.

**마이그레이션 `0015_passage_edits.sql`**

```sql
alter table public.passages
  add column engine_version text,
  add column prompt_version text,
  add column model text;
-- E6 commit에서 채운다. 기존 행은 null.

create table public.passage_edits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  passage_id uuid not null references public.passages (id) on delete cascade,
  before_text text not null,
  after_text text not null,
  edit_ratio numeric not null check (edit_ratio between 0 and 1),
  origin_before public.passage_origin not null,
  style public.writing_style,
  adaptation public.adaptation_level,
  narrative_voice text,
  engine_version text, prompt_version text, model text,
  created_at timestamptz not null default now()
);
-- RLS: 소유자만 select. insert는 user_edit_passage RPC 내부에서만.
```

- `passage_id` cascade: 사용자가 꿈을 삭제해 파생 문단이 지워지면 편집 기록도 지워진다. 삭제 의도를 존중한다.
- **기록은 `user_edit_passage` RPC 안에서 같은 트랜잭션으로** 한다. 앱에서 따로 쓰지 않는다.
- `edit_ratio`는 문자 단위 편집 거리 / 긴 쪽 길이.

**동의**
- `profiles.consent_training boolean not null default false`
- S16 설정에 토글: "내 수정 기록을 문장 품질 개선에 사용하는 데 동의" — **기본 OFF**
- **편집 기록 저장 자체는 동의와 무관하다** (사용자 본인의 원고 이력이고 본인만 읽는다). **품질 개선(학습·분석) 목적의 추출은 `consent_training = true`인 행만** 가능하다. 이 경계를 PDR §25 고지에 추가한다.
- 이 WO는 **수집만** 한다. 추출·학습 파이프라인은 만들지 않는다.

**운영 지표 (본문 없음)**
- `passage_edited` 분석 이벤트에 `edit_ratio` 구간(0–0.1 / 0.1–0.3 / 0.3+)만 추가
- engine_version별 편집률과 "원문으로 되돌리기" 비율을 월 1회 확인. **편집률 자체를 최적화 목표로 삼지 않는다.** 많이 고치는 사용자가 더 몰입한 사용자일 수 있다.

**완료 조건:** RLS 테스트(타 사용자 접근 불가), RPC 원자성 테스트, 꿈 삭제 시 cascade 테스트, 동의 기본값 테스트, 로그 무본문 확인.

---

## Q-41 · 행동 기반 몰입 측정

**목적:** 흡입력의 최종 판정자는 유저다. 몰입은 설문으로는 못 재지만 **행동으로는 잴 수 있다.** engine_version과 문체별로 실제 읽기 행동을 비교한다.

**현재 상태:** 앱의 분석 이벤트는 7종(`dream_saved`, `reveal_viewed`, `processing_completed` 등)이고, **장면을 끝까지 읽었는지 기록하는 이벤트가 없다.** 이 WO가 그 공백을 메운다.

**마이그레이션 `0016_reading_events.sql`**

```sql
create table public.reading_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  scene_id uuid not null references public.scenes (id) on delete cascade,
  kind text not null check (kind in ('reveal_open','reveal_complete','reader_open','scene_complete')),
  max_progress numeric check (max_progress between 0 and 1),   -- 스크롤 도달률
  dwell_ms integer check (dwell_ms >= 0),
  created_at timestamptz not null default now()
);
-- RLS: 소유자 insert/select. 본문 없음, 메타데이터만.
```

- Q-40에서 `passages`에 추가한 `engine_version`·`prompt_version`·`model`을 **장면 단위로 조회하는 뷰**를 만든다
- 앱: S07 리빌과 S08 Reader에서 장면별 최대 스크롤 도달률과 체류를 기록. `scene_complete` = 도달률 ≥ 0.9
- `AppLog` 허용 키에 `engine_version`, `style`을 추가한다 (문자열 64자 제한 유지)
- **체류 시간 이상치를 자른다.** 앱이 백그라운드로 가면 타이머를 멈추고, 5분 초과 체류는 5분으로 자른다

**지표 (서비스 롤 전용 뷰 `v_immersion_by_engine`)**

| 지표 | 정의 | 뜻 |
|---|---|---|
| **리빌 완독률** | `reveal_complete` / `reveal_open` | 방금 만든 장면을 끝까지 읽었나. **가장 직접적인 흡입력 지표** |
| 장면당 체류 중앙값 | 완독한 장면의 `dwell_ms` 중앙값 | 너무 짧으면 훑기, 적당하면 읽기 |
| 재독률 | 꿈을 기록하지 않은 날 `reader_open`이 있는 사용자 비율 | 꿈이 없어도 돌아오는가 (밤 루프) |
| 다음 꿈 기록률 | 리빌 후 7일 내 다음 꿈 제출 | 이야기가 다음을 기다리게 만드는가 |

**해석 규칙**
- engine_version별 비교는 **같은 기간·같은 사용자군**에서만 한다. 컷오버 전후 비교에는 계절·신규 유입 효과가 섞인다. **v10 경로를 유지하는 14일(Q-32)이 유일한 동시 비교 창이다.** 그 기간에 사용자를 무작위로 v10/v11에 나눠 배정하는 것을 Q-32에 추가 검토한다
- 사용자 수가 적은 동안은 **방향만 본다.** 수치를 게이트로 쓰지 않는다
- **이 지표를 직접 최적화 목표로 삼지 않는다.** 장면을 짧게 만들면 완독률은 쉽게 오른다. 완독률은 레퍼런스 근접도·사람 판정과 **함께** 본다

**완료 조건:** RLS 테스트, 백그라운드 전환 시 타이머 정지 테스트, 뷰 쿼리 테스트, 로그에 본문 없음 확인.

---

# §5. 부록

## 5.1 write.v10 규칙 32개 이관표

v11에서 작가 프롬프트는 약 15줄로 줄어든다. 나머지 규칙은 사라지는 게 아니라 **더 맞는 자리로 옮겨간다.**

| # | v10 규칙 요지 | v11에서의 자리 |
|---:|---|---|
| 1 | 문단마다 origin 표시 | **코드** — 마커 → 비트 kind (Q-21) |
| 2 | D 문단 element id | **코드** — 비트 element_ids |
| 3 | high salience 사용 | **대본** 원칙 7 + **파서** D 비트 누락 검사 |
| 4 | 역할명 | **대본** 원칙 8 |
| 5 | 해석·교훈 금지 | **공통 원칙** "의미는 장면으로만 남긴다" (긍정형) |
| 6 | 꿈 메타 표현 금지 | **검증기 V7** (정규식). 작가 프롬프트에 목록을 넣지 않는다. 목록 자체가 모델을 점화한다. V7 적중률이 오르면 그때 재검토 |
| 7 | 장면을 닫지 않음 | **대본** `open_image` + 작가 "마지막 이미지로 끝난다" |
| 8 | narrative_voice | **작가** voice_section |
| 9 | U 문단 출력 금지 | **코드** — 출력은 마커 문단뿐 + V6 유지 |
| 10 | 민감 콘텐츠 | **작가** 조건부 1줄 |
| 11 | 입력 id만 사용 | **코드** — 작가는 id를 출력하지 않음 |
| 12 | 기록자 = 주인공, 관계 인물은 제3자 | **대본** 원칙 1 |
| 13 | 생략된 주어 복원 | **대본** 원칙 2 |
| 14 | 첫 장면 훅 | **대본** 장면 구성 (`hook_beat`) |
| 15 | 1인칭 "나", 타인 내면 단정 금지 | **작가** voice_section |
| 16 | 제목 고정 | **코드** — 대본 `scene_title` |
| 17 | 행위자·대상·수혜자 보존 | **대본** 원칙 3 + **V8** |
| 18 | 특정 테스트 문장 목적 유지 | **삭제.** 일반화된 형태가 대본 원칙 3·4에 있음 |
| 19 | 크기·색 발명 금지 | **대본** 원칙 5 + **V8** `invented_concrete` |
| 20 | 미완료 의도 완료 금지 | **대본** 원칙 4 (`status`) + **V8** |
| 21 | 동물 생각 단정 금지 | **대본** 원칙 9 + **작가** voice_section (일반화) |
| 22 | 분량 70% 이상, 문단당 글자 수 | **삭제** (Q-23) |
| 23 | opening_contract 5단계 | **대본** 장면 구성 |
| 24 | 즉각 목표 | **대본** 장면 구성 |
| 25 | 이상 징후를 보여주기 | **작가** "순간을 쓴다" + **공통 원칙** |
| 26 | 첫 장면 끝 = 선택의 결과 | **대본** 장면 구성 + `open_image` |
| 27 | 개미 대사 금지 | **삭제.** 21과 통합되어 일반화됨 |
| 28 | 문단당 하나의 행동, 문장 길이 섞기 | **공통 원칙** + **린터** `sent_len_cv` |
| 29 | "나는 ~하려고 했다" 연속 보고 금지 | **린터** `subject_lead_rate`, `ending_max_run` + **공통 원칙** |
| 30 | D 문단 최소 5개 | **삭제.** 비트 수는 재료에 비례 |
| 31 | validation_feedback 반영 | **코드** — 재시도 피드백 생성기 |
| 32 | JSON 외 출력 금지 | **삭제.** 평문 + 마커 |

**요약:** 삭제는 5개(18·22·27·30·32)뿐이다. 나머지 27개는 코드·대본·검증기·원칙 중 더 맞는 자리로 옮겨간다. 작가 프롬프트에 남는 것은 시점·민감 콘텐츠·출력 형식 정도다.

## 5.2 하지 말 것

- **특정 꿈의 문장을 프롬프트·바이블·테스트 fixture에 넣지 마라.** `check_prompt_leak.ts`가 막는다.
- **한 라운드에 두 가지를 바꾸지 마라.** 무엇 때문에 좋아졌는지 알 수 없게 된다.
- **holdout을 튜닝 중에 열지 마라.** 한 번 보면 dev다.
- **판정 없이 프롬프트를 운영에 올리지 마라.**
- **문제를 규칙 추가로 고치지 마라.** 먼저 분류하라: 사실 문제 → 대본·V8, 문장 문제 → 바이블·린터, 형식 문제 → 코드.
- **평가 데이터·꿈·생성 문장을 커밋·콘솔·로그·문서에 남기지 마라.** `docs/quality/` 기록은 수치만.
- **레퍼런스 작품을 자동 수집하지 마라.** 크롤러·스크래퍼·앱 추출·DRM 우회 금지. 사용자가 정당하게 열람한 회차에서 직접 옮긴다.
- **레퍼런스 원문을 LLM에 보내거나, 프롬프트·예시·문서·커밋에 넣지 마라.** 레퍼런스는 숫자로만 제품에 들어간다.
- **웹소설의 장르 문법을 가져오지 마라.** 회귀·빙의·환생, 상태창, 사이다 구조, 회차 분량은 무무몽의 목표가 아니다. 가져오는 건 호흡과 구조뿐이다.
- **작가 외주 원고를 AI로 쓰게 두지 마라.** 인간 창작 보증을 계약에 넣는다.
- **파인튜닝을 시작하지 마라.** Q-40 데이터가 수백 건 쌓이고, v11이 한계에 닿았다는 판정 근거가 생긴 뒤에 별도로 검토한다.

## 5.3 사용자가 직접 하는 일

| 시점 | 할 일 | 예상 시간 |
|---|---|---|
| Q-08 전 | dev 꿈 30개 → `eval/corpus/dev.jsonl` | (수집 기간) |
| **Q-09** | **카카오페이지 국내 웹소설 양성 25편 + 대조군 5~8편 선정, 도입·끝 옮기기, 라벨링** | **약 4시간** |
| **Q-09 직후** | **작가 외주 발주** (22-B 브리프·계약 조건) | 발주 1~2시간 + 납품 대기 |
| Q-08 | 충실도 판정기 검수 15건, A/A 판정 10건 (권장) | 30분 |
| Q-10 | 후보 모델 판정 (생존 후보당 21단위) | 1~2시간 |
| Q-22 | 임시 예시 선택 (외주 납품 전), 납품물 검수 | 2시간 |
| Q-22 납품 후 | 프로 대비 판정 (`--mode pro`) | 30분 |
| Q-25 | 라운드당 판정 21단위 × 최대 3회 | 1.5시간 |
| Q-32 전 | holdout 꿈 10개 → `eval/corpus/holdout.jsonl` | (수집 기간) |
| Q-32 | holdout 판정 7단위 | 15분 |

**holdout 꿈은 Q-32 전까지 파일로만 넣고 읽지 마라.** 수집 시점에 이미 봤겠지만, 튜닝 중에 다시 들여다보지 않는 것이 핵심이다.

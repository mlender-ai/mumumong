# MUMUMONG M1 개발 지시서

**문서 버전:** v0.3 — D1·D2·D6 사용자 결정 반영

**대상 마일스톤:** M1 — 로컬 프로토타입을 실제 백엔드·AI 파이프라인에 연결
**전제:** 1인 개발, 주 15~20시간, iOS 단일 출시, 구현은 Codex 위임
**연결 문서:** `MUMUMONG_PDR_v0.1.md` (이하 PDR), `MUMUMONG_Visual_System_v0.1.md` (이하 VS)

### 근거 표기 규칙

이 문서의 모든 판단에는 아래 표기를 붙인다.

| 표기 | 의미 |
|---|---|
| `[기획]` | PDR 또는 VS에 명시된 사실 |
| `[보고]` | 사용자가 이번 요청에서 서술한 현재 구현 상태 |
| `[제안]` | 이 문서에서 새로 제안하는 결정 |

> **코드 검증 완료 (v0.2)**
> `github.com/mlender-ai/mumumong` (public, main, 2 commits)을 직접 클론해 확인했다. 이 문서의 `[코드]` 표기는 실제 파일을 읽은 결과다. v0.1에서 "확인 필요"로 남겼던 C1~C6은 §2.3에 확정 결과로 대체했다.
>
> **사용자 결정 반영 (v0.3)**
> D1은 설정형 서술 시점(기본값 3인칭 과거형), D2는 iOS 온디바이스 STT 전용, D6는 WO-00 저장소 재편 승인으로 확정했다.

## 1. Executive Summary

**판단: WO-00부터 착수할 수 있다. 선행 결정 D1·D2·D6은 확정됐다.**

PDR은 화면(S01~S16)과 파이프라인(E1~E7)의 **기능 명세** 수준에서는 구현 가능하다. 부족한 것은 기능이 아니라 **계약(contract)**이다. 구체적으로 세 가지가 비어 있다.

1. **E1~E7의 API 스키마가 없다.** 단계별 입출력 JSON이 확정되지 않아 Codex가 임의 해석한다.
2. **실패 상태의 상태 기계가 없다.** PDR은 "재시도 1회 후 폴백"까지만 말하고, 그 사이 사용자가 보는 화면과 DB 상태를 정의하지 않았다.
3. **PDR §31의 결정 중 POV(31-3)와 STT 방식(31-4)은 확정됐다.** 길이 선택 시점(31-2)은 S02 착수 전 확정하며, 나머지 2건은 M2 이후로 미뤄도 된다.

**M1 범위 (권고):**

> **꿈 기록 → 로컬 저장 → 기억 보강 → 비동기 AI 처리 → 검증 → DB 커밋 → 리빌 → 원고·보관함 갱신**
> 이 한 줄이 **실제 데이터와 실제 LLM으로** 끝까지 돌아가는 것.

**M1에서 제외 (M2로 이월):** 완결 파이프라인(C1~C6), PDF, 푸시 알림, 장르 카드(D3), 여백 출처 표시, 도트 셰이더 고도화, 중편. 모두 PDR에서 삭제 금지로 지정된 항목은 **이월이지 삭제가 아니다.**

**예상 소요: 약 142시간 (8~9주).** 코드 확인 결과 데이터 계층이 전무해 v0.1 추정(134h)보다 늘었다. 상세는 §8.

**최대 위험 3개**

| 위험 | 영향 | 대응 |
|---|---|---|
| 파이프라인 7단계를 한 번에 붙이려다 디버깅 불가 상태에 빠짐 | 일정 2배 | Mock 엔진을 먼저 만들고(W0), 단계별로 실제 모델 교체 |
| 데이터 계층이 **존재하지 않는데**(§2.2 C2·C3) 화면부터 Supabase에 붙임 | UI 전면 재작성 | 도메인 모델 → Repository 인터페이스 → Memory 구현체 → 화면 배선 순서 고정 |
| 꿈 원문이 로그·에러 리포트에 유출 | 신뢰 붕괴, 복구 불가 | 로깅 래퍼를 코드로 강제(§9), CI에서 금지 패턴 검사 |

---

## 2. 현재 구현 진단 `[코드 확인 완료]`

### 2.1 저장소 실측

| 항목 | 실측값 |
|---|---|
| 구조 | `lib/` **평면 7파일**, 하위 폴더 없음 |
| 코드량 | 2,207줄 (capture_flow 688 / reader 355 / archive 291 / design_system 263 / home 242 / dot_field 220 / main 148) |
| 의존성 | **`cupertino_icons` 하나뿐.** 상태관리·DB·네트워크 패키지 0개 |
| 테스트 | `test/widget_test.dart` 위젯 테스트 2개 |
| CI | `.github/workflows/ci.yml` 존재 — format / analyze / test / build web |
| 플랫폼 | `ios/`, `web/`. android 없음 |
| 문서 | `docs/` 에 PDR·VS·STATUS, 루트에 `AGENTS.md` |

### 2.2 C1~C6 확정 결과

| # | v0.1 가정 | **실측** | 영향 |
|---|---|---|---|
| C1 | Riverpod일 수도 | **상태관리 라이브러리 없음.** 전부 `StatefulWidget` + `setState` | Riverpod 신규 도입. 마이그레이션할 기존 구조가 없어 오히려 깨끗함 |
| C2 | 도메인 모델이 UI와 분리되었을 수도 | **도메인 모델이 존재하지 않는다.** 유일한 데이터 클래스는 `archive_screen.dart`의 private `_DreamEntry`(date/firstLine/clarity/status 전부 String·int) | **WO-06/07이 "이식"이 아니라 "신규 작성"으로 바뀐다** |
| C3 | 메모리 저장소가 단일 지점일 수도 | **저장소 자체가 없다.** `_MumumongShellState`가 `_progress`, `_dreams`, `_scenes`를 원시값으로 들고 있고, 진척은 `_progress + .06` 하드코딩. Reader 문단과 Archive 목록은 위젯 리터럴 | 치환할 대상이 없으므로 데이터 계층을 바닥부터 만든다 |
| C4 | 스트림 기반일 수도 | **`Timer.periodic` 기반.** `_processingTimer`, `_processingStage` 정수 | WO-13은 배선이 아니라 `capture_flow.dart` 처리 구간 재작성 |
| C5 | 셰이더일 수도 | **`CustomPainter`** (`DotCoverPainter`, `MemoryParticlePainter`) | **셰이더 WO는 불필요.** VS §6.2의 Field 렌더러를 CustomPainter로 유지 |
| C6 | `origin` 필드 유무 | **`PassageOrigin { dream, connection, user }` enum이 `reader_screen.dart`에 있다.** 단 이것은 *위젯 파라미터*이고, `source_element_ids`·`locked`·`id`는 없다 | 개념은 이미 코드에 있음. 데이터로 승격하는 작업 |

### 2.3 이 발견이 바꾸는 것

**프로토타입은 "데이터가 메모리에 있는 앱"이 아니라 "내용이 하드코딩된 UI 껍데기"다.** STATUS.md의 `In-memory state only`라는 표현이 실제보다 후하다. Reader의 문단 5개는 `ReaderPassage(origin: PassageOrigin.dream, ...)` 위젯 리터럴이고, Archive 목록도 고정 배열이다.

세 가지 결과가 따라온다.

1. **"기존 Repository를 Drift로 치환"이라는 v0.1 계획은 성립하지 않는다.** 도메인 모델·Repository·Memory 구현체를 전부 새로 쓴 뒤, 4개 화면을 거기에 연결한다.
2. **대신 잃을 것이 없다.** 버릴 추상화가 없고, 브랜드 토큰(`MongColor`, `MongMotion`, 타입 스케일)은 VS와 정확히 일치하게 이미 구현되어 있다. **v0.1이 걱정한 "프로토타입 결합도" 위험은 사실상 없다.**
3. **화면 UI는 자산이 맞다.** 다만 자산은 *레이아웃과 인터랙션*이지 *데이터 흐름*이 아니다.

### 2.4 잘 되어 있는 것 (건드리지 말 것)

- `design_system.dart`의 색·모션 토큰이 VS §3.1/§8.2와 **1:1로 일치**한다. Night Paper 5색도 있다.
- `AGENTS.md`에 비타협 규칙 10개(출처 태그, U 잠금, C 예산, 로그 무본문, clarity 0.9 상한 등)가 이미 정리되어 있다. **이 문서의 WO는 AGENTS.md를 대체하지 않고 그 아래에 놓인다.**
- CI가 이미 돌고 있다. 새 워크플로를 만들지 말고 기존 `ci.yml`에 스텝을 추가한다.
- `docs/STATUS.md`에 "시뮬레이션이 실제로 넘어가면 갱신" 규칙이 있다. **모든 WO의 완료 조건에 STATUS.md 갱신을 포함시킨다.**

## 3. 기획서 누락·충돌 보고

### 3.1 확정된 요구사항 (그대로 구현 가능)

| 영역 | 절 | 상태 |
|---|---|---|
| 기록 화면 규칙 (선택지 0개, 1탭 저장, 04시 경계) | PDR §12 / S04 | 확정 |
| 기억 보강 고정 문항 10종과 슬롯 | PDR §12 / S05 | 확정 |
| 배치 방식 5종과 사용자 표시 문구 | PDR §13 | 확정 |
| 각색 수준 3종 → C 예산·엔티티·길이 배수 | PDR §17 | 확정 |
| MU 계산식과 clarity 판정 | PDR §15 | 확정 |
| 생성 규칙 10개 | PDR §24 | 확정 |
| 검증기 V1~V7 | PDR §24 | 확정 |
| 컨텍스트 레이어 L0~L5와 예산 | PDR §22 | 확정 |
| 프라이버시 원칙 (로그 무본문, 역할명, 음성 삭제) | PDR §25 | 확정 |

### 3.2 M1 의사결정 상태

| # | 항목 | 근거 | 막히는 작업 | 권고 |
|---|---|---|---|---|
| **B1** | **서술 시점(POV)** | PDR §31-3 | E4 프롬프트 전체 | **설정값으로 주입. 기본값은 3인칭 과거형이고, 1인칭 과거형을 선택 가능하게 한다.** |
| **B2** | **STT 방식** | PDR §31-4 | S04, 프라이버시 고지 문안 | **iOS 온디바이스 `SFSpeechRecognizer` 전용. 서버 폴백 없음.** |
| **B3** | **길이 선택 시점** | PDR §31-2 (미결) | S02, `volumes.format` | **단편 고정으로 시작.** M1에서 `format` 컬럼은 두되 UI 선택은 제거 |

### 3.3 미결정 — M1을 막지 않는 것 (M2로 이월)

| # | 항목 | 근거 |
|---|---|---|
| B4 | "자유롭게" 모드 포함 여부 | PDR §31-1 — M1은 `faithful`/`balanced` 2종만 구현 |
| B5 | 완결 시 D 문단 통일 범위 | PDR §31-5 — 완결 파이프라인 자체가 M2 |

### 3.4 구현자가 임의 해석하게 되는 부분 (명세 필요)

이것이 이번 문서의 핵심 산출물이다. 아래 9개는 PDR에 **개념은 있으나 계약이 없다.**

| # | 공백 | PDR 근거 | 이 문서의 해결 |
|---|---|---|---|
| G1 | E1~E7 단계별 입출력 JSON 스키마 | §13 표에 "입력/출력"만 서술 | §5.7 + 별첨 작업지시서 |
| G2 | `jobs` 상태 전이와 실패 시 UI·DB 상태 | §13 "재시도 1회 → 폴백" | §6.7 상태 기계 |
| G3 | 연결 결정(D1) 이후 텍스트 반영 방식 | §14 "연결 문장 1개만 추가 생성" — 어디에 삽입? | §5.8 |
| G4 | `order_key` fractional index 생성 규칙 | §23 주석만 존재 | §6.3 |
| G5 | clarity 판정의 "사건" 정의 | §15 "사건 1~2개면 partial" — 사건이 무엇? | §5.7 E1 스키마에서 `event` 타입 요소 수로 확정 |
| G6 | 오프라인 중 기록의 dream_date 처리 | §12 04시 규칙만 존재 | §6.6 |
| G7 | 프롤로그 판정 조건 | §13 "첫 꿈" — 재시도·삭제 후에는? | `volumes`에 `prologue_scene_id`, null이면 프롤로그 |
| G8 | 보강 답변이 원고에 반영되는 경로 | §12 "`source=recall`로 저장" — E4가 쓰는가? | §5.7 E1에서 elements로 병합, D 문단 출처로 사용 |
| G9 | 진척 Δ 사유의 산출 시점 | §15 템플릿만 존재 | E6 커밋 트랜잭션에서 `progress_events`에 기록 |

### 3.5 충돌하는 요구사항

| # | 충돌 | 판정 |
|---|---|---|
| **X1** | PDR §24-4는 **역할명 사용**을 강제하고, 1인칭에서는 화자를 역할명으로 부를 수 없다 | **POV를 L1 설정값으로 주입하고 기본값을 3인칭 과거형으로 둔다.** 1인칭 과거형에서는 화자만 역할명 규칙의 예외이며, 그 밖의 등장인물은 역할명을 유지한다. |
| **X2** | PDR §13은 clarity=fragment일 때 `fragment_attach`(기존 장면에 덧붙임)를 허용한다. 그러나 §24-8은 U 문단 불변을 요구한다. 덧붙일 대상 장면에 U 문단이 있으면? | **[제안]** `fragment_attach`는 대상 장면의 **끝에만 append**한다. 기존 문단 사이에 삽입하지 않는다. U 문단이 있어도 안전하다 |
| **X3** | PDR §20은 원문 수정 시 "자동 재생성하지 않는다"고 한다. 그러나 §15 MU는 clarity에 의존하고, clarity는 E1 결과다. 원문을 수정하면 MU가 어긋난다 | **[제안]** 원문 수정 시 **clarity와 MU를 재계산하지 않는다.** MU는 최초 커밋 시점에 `progress_events`로 확정된 값이다. "다시 쓰기"를 선택할 때만 이전 이벤트를 취소하고 새로 기록한다 |
| **X4** | PDR §7 밤 루프는 "열린 장면"을 핵심 트리거로 삼는데, `open_threads`는 E7이 만든다. E7이 실패하면 밤 알림 문구가 없다 | **[제안]** E4 출력의 `open_image`(§24 스키마에 이미 존재)를 `scenes.open_image`로 저장한다. E7 실패와 무관하게 밤 알림 소스가 확보된다 |

### 3.6 M1에서 제거·연기 권고

| 항목 | PDR 근거 | 조치 | 이유 |
|---|---|---|---|
| 중편(novella) | §16 | 연기 | 3개월 내 완결자가 나오지 않는다 (§31-2) |
| 각색 "자유롭게" | §17 | 연기 | B4 미결. 2종으로 파이프라인 검증 충분 |
| 장르 카드 D3 | §18 | 연기 | 장면 4개 이상에서만 뜬다. M1 테스트 범위 밖 |
| 여백 출처 표시 | §19 | 연기 | 출처 시트가 핵심. 여백은 보조 |
| 완결·PDF | §16 | **M2 확정** | 삭제 아님. M1에서 `status` 값과 잠금 정책은 미리 구현 |
| 푸시 알림 | §26 | M2 | 로컬 알림으로 대체 가능하나 M1 범위 밖 |
| 도트 셰이더 | VS §6.3 | 연기 | 현재 커버 구현을 유지 (C5 확인 후 판단) |

---

## 4. PDR Coverage Matrix

`구현` = 실제 동작 / `시뮬` = UI만 있고 실물 없음 / `없음` = 미착수

### 4.1 화면 S01~S16

| 화면 | 기획 요구사항 (PDR) | 현재 상태 | 부족한 부분 | 우선순위 | 권고 |
|---|---|---|---|---|---|
| S01 온보딩 | 3장, AI 처리 고지 동의 §25 | 없음 `[보고]` | 전체 | **M1 필수** | 고지 동의 없이 LLM 호출 불가. 최소 구현 |
| S02 볼륨 설정 | 각색·문체 선택 §17 | 미확인 | 기본값 선택 상태, 단편 고정(B3) | M1 | 선택 2종(각색 2 × 문체 3)만 |
| S03 원고 홈 | 도트 커버, 진척, Δ 라인 §15 | UI 구현 / **진척은 `+.06` 하드코딩** `[코드]` | MU 기반 실데이터, Δ 사유 산출 | M1 | 신규 배선 |
| S04 기록 | 음성·텍스트, 초안 자동저장, 04시 §12 | 텍스트 구현 / 음성은 **3초 후 고정 문장 주입** `[코드]` | 실제 녹음·STT, 초안, 오프라인 | **M1 필수** | §5.5 |
| S05 기억 보강 | 고정 문항 10종, ≤3, 건너뛰기 §12 | 구현 | 문항 은행 소스 확인, 슬롯 판정 연동 | M1 | E1 결과로 슬롯 선택 |
| S06 처리 중 | 실제 파이프라인 단계 연동 VS §10 | **`Timer.periodic` 시뮬** `[코드]` | `jobs` 구독, 20초 규칙, 실패 UI | **M1 필수** | 처리 구간 재작성 |
| S07 리빌 | 새 문단 표시, 연결 결정, Δ §14 | 구현 | 실생성 결과 바인딩, `first_read_at` | M1 | — |
| S08 Reader | 목차, 러닝헤더, 이어 읽기, Night §15.2 | UI 구현 / **문단이 위젯 리터럴** `[코드]` | 실데이터 렌더링, 스크롤 위치 영속화 | M1 | 신규 배선 |
| S09 출처 시트 | 배지, 날짜, 원문 발췌 강조 §19 | UI 구현 / **고정 텍스트** `[코드]` | `span` 기반 강조, 실데이터 | M1 | E1이 `span` 산출 |
| S10 편집 | 인라인 편집, U 잠금, 되돌리기 §19 | 없음 `[보고]` | 전체 | **M1 필수** | U 잠금은 삭제 금지 항목 |
| S11 디렉팅 카드 | 장르 §18 | 없음 | 전체 | M2 | 연기 |
| S12 보관함 | 월별, 상태 필터 §20 | UI 구현 / **고정 배열, `status`가 String** `[코드]` | 실데이터, enum 4종 | M1 | 신규 배선 |
| S13 꿈 상세 | 원문 수정, 넣기·빼기, 삭제 §20 | 미확인 | 삭제 시 파생 처리 (a)/(b) | M1 | §6.8 |
| S14 완결 | C1~C6 §16 | 없음 | 전체 | **M2** | `status` enum만 미리 |
| S15 완성본 | PDF, 부록 §16 | 없음 | 전체 | M2 | — |
| S16 설정 | 잠금, 알림, 내보내기·삭제 §25 | 없음 | 계정 삭제, 데이터 내보내기 | M1 부분 | 삭제·내보내기는 심사 요건 |

### 4.2 파이프라인 E1~E7

| 단계 | 기획 요구사항 (PDR §13) | 현재 상태 | 부족한 부분 | 우선순위 | 권고 |
|---|---|---|---|---|---|
| E1 Extract | elements[], clarity, sensitive_flags, 빈 슬롯 | **시뮬** | 스키마, 모델 호출, `span` 산출 | M1 필수 | 경량 모델 |
| E2 Link | 엔티티 매칭 신뢰도 3구간 | **시뮬** | 레지스트리 조회, 임계값 로직 | M1 필수 | 규칙 + 경량 모델 |
| E3 Plan | placement, 비트 계획 | 없음 `[보고]` | 전체 | M1 필수 | 고성능 모델 |
| E4 Write | 출처 태그 JSON | **시뮬** | 스키마, 프롬프트, L0~L5 조립 | M1 필수 | 고성능 모델 |
| E5 Validate | V1~V7 | **시뮬** | 규칙 검증기, 재시도, 폴백 | M1 필수 | 규칙 우선 |
| E6 Commit | 단일 트랜잭션 | 없음 | RPC, progress_events | M1 필수 | §6.5 |
| E7 Remember | story_so_far, open_threads, genre | 없음 | 전체 | M1 필수 | 실패해도 커밋은 유지 |

### 4.3 인프라

| 영역 | 요구 | 현재 | 우선순위 |
|---|---|---|---|
| 인증 | Apple 로그인 | 없음 | M1 필수 |
| DB | Supabase + RLS §25 | 없음 | M1 필수 |
| 로컬 | 초안, 오프라인 큐 | 없음 | M1 필수 |
| 로깅 | 무본문 원칙 §25 | 없음 | **M1 필수 (선행)** |
| 분석 | 이벤트 19종 §29 | 없음 | M1 부분 (핵심 8종) |
| 환경 | dev/stg/prod 분리 | 없음 | M1 필수 |

---

## 5. 권고 기술 아키텍처

### 5.1 상태관리 — **Riverpod (권고)**

| 선택지 | 장점 | 단점 |
|---|---|---|
| **Riverpod 2.x + codegen** | 비동기 상태와 스트림 구독이 1급, `AsyncValue`로 로딩·에러 표현, Repository 교체가 override 한 줄 | 학습 곡선, codegen 빌드 단계 |
| Bloc | 상태 전이가 명시적, 파이프라인과 궁합 | 보일러플레이트가 1인 개발에 과함 |

**권고: Riverpod.** 결정적 이유는 **Mock 전환**이다. `repositoryProvider`를 `ProviderScope(overrides:)`로 갈아끼우면 `--dart-define=USE_MOCK=true` 하나로 전체 앱이 메모리 모드로 돌아간다 (§5.11). `jobs` 실시간 구독도 `StreamProvider`로 그대로 받는다.

**[코드] 현재 상태관리 라이브러리가 없다**(§2.2 C1). 전 화면이 `setState`다. 마이그레이션할 기존 구조가 없으므로 Riverpod을 **처음부터 깨끗하게** 넣을 수 있다. 단 `pubspec.yaml`에 의존성이 `cupertino_icons` 하나뿐이라, 패키지 도입 자체가 WO-00의 일이 된다.

### 5.2 로컬 DB — **Drift (권고)**

| 선택지 | 장점 | 단점 |
|---|---|---|
| **Drift (SQLite)** | 타입 안전 쿼리, migration 도구, 스트림 쿼리, Postgres와 스키마 개념 일치 | 초기 설정 비용 |
| Isar | 빠르고 간단 | 유지보수 상태 불확실, 관계 표현이 약함 |
| Hive / SharedPrefs | 매우 단순 | 큐·관계·인덱스 부적합 |

**권고: Drift.** 오프라인 큐와 초안을 모두 담아야 하고, 원격 스키마와 대칭이라 동기화 로직이 단순해진다. `[코드]` 현재 로컬 저장이 전무하므로 기존 데이터 마이그레이션 부담이 없다.

> **[제안] 로컬 DB 암호화:** 꿈 원문이 기기에 평문 저장된다. M1은 iOS 기본 파일 보호(`NSFileProtectionComplete`)에 의존하고, M2에서 SQLCipher 도입을 검토한다. 결정 D4로 올린다.

### 5.3 오프라인 큐 — **Outbox 패턴 (권고)**

```
[사용자 저장]
   → local.dreams INSERT (source of truth, 즉시)
   → local.outbox INSERT (op=create_dream, payload, idempotency_key)
   → OutboxWorker: 연결 있으면 순차 전송 → 성공 시 삭제, 실패 시 지수 백오프
```

- **로컬이 진실의 원천이다.** 저장 성공 응답은 로컬 커밋 시점에 준다. 네트워크를 기다리지 않는다. PDR §12 "초안 자동저장, 오프라인 큐"의 요구를 만족한다.
- `idempotency_key = uuid v4`를 클라이언트가 생성한다. 서버는 이 키로 중복 삽입을 막는다 (§6.4).
- 백오프: 1s → 4s → 15s → 60s → 5m, 최대 6회. 이후 `failed`로 표시하고 보관함에 재시도 버튼을 노출한다.
- 순서 보장: `outbox`는 `created_at` 순차 처리. 한 건이 실패하면 **같은 dream에 대한 후속 op는 대기**하고, 다른 dream은 진행한다.

### 5.4 Realtime vs Polling — **둘 다, 역할 분리 (권고)**

| 용도 | 방식 |
|---|---|
| S06 처리 화면 (앱 전면, 활성) | **Realtime 구독** (`jobs` 행의 `status` 변화) |
| Realtime 연결 실패·백그라운드 복귀 | **Polling 폴백** (3초 간격, 최대 2분) |
| 앱 재시작 후 미완료 작업 확인 | 진입 시 1회 조회 |

- Realtime만 믿으면 네트워크 전환(와이파이→LTE)에서 단계 표시가 멈춘다. **폴백은 필수다.**
- 구독 대상은 `jobs` 테이블 한 곳으로 한정한다. `passages`까지 구독하면 비용과 복잡도가 늘고 얻는 게 없다.

### 5.5 STT — **iOS 온디바이스 전용 (확정)** `[B2 해결]`

| 선택지 | 장점 | 단점 |
|---|---|---|
| **`SFSpeechRecognizer` (`requiresOnDeviceRecognition = true`)** | **음성이 기기를 떠나지 않는다.** 무료, 실시간 부분 결과 → VS §9 도트 모션 연동 가능 | 잠결 발화 정확도 미검증, iOS 버전·언어팩 의존 |
| 서버 STT (Whisper 등) | 정확도 우위 가능성 | 음성 업로드 필요 → PDR §25 "음성은 STT 후 삭제" 원칙과 충돌 확대, 비용, 지연 |

**확정: 온디바이스 전용.** 프라이버시 포지셔닝과 정합하고, 실시간 부분 결과가 도트 모션의 입력이 된다.

**필수 안전장치:** 인식 품질이 나빠도 **사용자가 텍스트를 직접 고칠 수 있으므로 치명적이지 않다.** 다만 아래를 반드시 구현한다.

- 온디바이스 인식 불가(언어팩 없음, 구형 기기)이면 **자동으로 텍스트 입력으로 전환**하고 안내한다. 서버 STT로 조용히 폴백하지 않는다.
- 인식 결과는 항상 편집 가능한 텍스트로 보여준다. 확정 전에 저장하지 않는다.
- **PDR §31-4의 검증(기상 직후 녹음 10건)은 여전히 수행한다.** 실패하면 M2에서 서버 STT를 옵트인으로 추가하고, 그때 고지 문안을 갱신한다.

### 5.6 서버리스 작업 큐 — **Postgres 큐 + Edge Function 워커 (권고)**

```
클라이언트 ──POST /enqueue──▶ Edge Function: enqueue
                                 └─ jobs INSERT (type=extract, status=queued)
                                 └─ 즉시 worker 비동기 invoke

               pg_cron (10초) ──▶ Edge Function: worker
                                 └─ claim_job() RPC (SKIP LOCKED)
                                 └─ 단계 실행 → 다음 jobs INSERT → worker 재invoke
```

| 선택지 | 장점 | 단점 |
|---|---|---|
| **Postgres `jobs` 테이블 + Edge Function** | 인프라 추가 없음, 상태가 DB에 있어 Realtime 구독 그대로, 디버깅 쉬움 | 직접 구현할 부분 있음 |
| 외부 큐 (QStash 등) | 재시도·스케줄 내장 | 의존성·비용 추가, 상태가 두 곳으로 분산 |

**권고: Postgres 큐.** 1인 개발에서 **상태가 한 곳에 있다는 것**이 가장 큰 가치다.

**단계 분리 원칙:** 각 Edge Function 호출은 **한 단계만** 실행한다. E1~E7을 한 번에 돌리면 타임아웃과 재시도 단위가 망가진다. PDR §13의 "별도 호출, 멱등, 재시도 가능" 요구와 일치한다.

**타임아웃:** 단계당 60초. 초과하면 `jobs.status='failed'`, `error='timeout'`.

### 5.7 E1~E7 모델과 API 경계

> **단계별 상세 계약(요청·응답 JSON, 프롬프트 골격, 검증 규칙)은 별첨 `MUMUMONG_M1_WorkOrders.md`의 WO-E1~WO-E7에 있다.** 여기서는 경계만 정의한다.

| 단계 | 모델 등급 | LLM 호출 | 온도 | 입력 예산 | 산출 |
|---|---|---|---|---|---|
| E1 Extract | 경량 | 1회 | 0.0 | ~2k | `elements[]`, `clarity`, `empty_slots[]`, `sensitive_flags[]` |
| E2 Link | 규칙 + 경량 | 0~1회 | 0.0 | ~3k | `matches[]` (confidence), `question` (≤1) |
| E3 Plan | 고성능 | 1회 | 0.3 | ~8k | `placement`, `beats[]` |
| E4 Write | 고성능 | 1회 (재시도 최대 2) | 0.8 | ~10k | `scene`, `passages[]`, `new_entities[]`, `open_image` |
| E5 Validate | **규칙 우선**, V5·V7만 경량 | 0~1회 | 0.0 | ~4k | `pass` / `fail(reasons[])` |
| E6 Commit | LLM 없음 | 0회 | — | — | scene/passage/progress_event |
| E7 Remember | 경량 | 1회 | 0.2 | ~6k | `story_so_far`, `open_threads`, `genre_scores` |

**API 경계 원칙**

1. **모든 LLM 호출은 Edge Function 안에서만 한다.** 클라이언트는 API 키를 갖지 않는다.
2. **모든 단계 출력은 JSON 스키마로 강제한다.** 구조화 출력(structured output) 또는 tool use를 쓴다. 자유 텍스트 파싱을 하지 않는다.
3. **단계 간 데이터는 DB를 경유한다.** `jobs.payload`(jsonb)에 이전 단계 결과를 저장하고 다음 단계가 읽는다. 함수 간 직접 전달을 하지 않는다. 재시도가 가능해야 하기 때문이다.
4. **프롬프트는 버전 관리한다.** `generation_runs.prompt_version`에 기록한다. 품질 회귀를 추적하려면 필수다.
5. L0·L1·L2는 프롬프트 캐시 대상이다. 캐시 경계를 프롬프트 앞쪽에 배치한다.

### 5.8 연결 결정(D1) 반영 방식 `[G3 해결]`

PDR §14는 "재작성하지 않고 연결 문장 1개만 추가 생성"이라고만 한다. 구체안:

```
사용자가 "같은 사람" 선택
  → entities 병합 (survivor = 등장 횟수가 많은 쪽, loser는 aliases로 흡수)
  → entity_mentions 재지정
  → E4-mini 호출: 해당 장면의 해당 인물 첫 등장 문단 직후에 삽입할 C 문단 1개 생성
     입력: 두 장면의 해당 문단, 병합된 엔티티 설명
     제약: 1~2문장, origin='C', c_reason='연결 결정: {entity}'
  → passages INSERT (order_key = 대상 문단과 다음 문단 사이)
  → progress_events (+0.5 MU, reason=link)
```

- "다른 사람"이면 LLM 호출이 없다. 엔티티만 분리하고 +0.5 MU를 기록한다.
- "모르겠음"이면 `status='ambiguous'`. 호출 없음. MU는 동일하게 +0.5 (응답 자체가 기여다).

### 5.9 출처 태그와 U 잠금 보장 `[삭제 금지 항목]`

**3중 방어**

| 층 | 방법 |
|---|---|
| LLM | E4 출력 스키마에 `origin` 필수. `D`면 `source_element_ids` 1개 이상 (V1) |
| 앱 | 편집 저장 시 `origin='U'`, `locked=true`로 설정. 엔진 결과 병합 시 locked 문단은 제외 |
| **DB** | **트리거로 강제 (아래)** |

```sql
create or replace function guard_locked_passage() returns trigger
language plpgsql as $$
begin
  if old.locked and current_setting('app.user_edit', true) is distinct from 'on' then
    raise exception 'locked passage % cannot be modified by engine', old.id;
  end if;
  return new;
end $$;

create trigger trg_guard_locked
before update or delete on passages
for each row execute function guard_locked_passage();
```

- 사용자 편집 RPC 안에서만 `set_config('app.user_edit','on',true)`를 호출한다.
- 엔진(Edge Function)은 이 설정을 하지 않으므로 **코드에 버그가 있어도 U 문단을 건드릴 수 없다.** PDR §24 V6("즉시 폐기, 버그로 취급")을 DB 레벨로 끌어올린 것이다.

### 5.10 로그 무본문 구조 `[삭제 금지 항목]`

**원칙만으로는 반드시 새어나간다. 구조로 막는다.**

1. **로깅 래퍼만 사용한다.** `AppLog.i(event, {ids})`. `print`/`debugPrint`/`console.log` 직접 호출을 금지한다.
2. **필드 허용목록(allowlist).** 로그 페이로드는 `Map<String, Object>`를 받되, 래퍼가 허용 키(`dream_id`, `job_id`, `volume_id`, `stage`, `ms`, `code`, `count`…) 외를 **런타임에 제거**한다.
3. **CI 금지 패턴 검사.** `raw_text`, `passage.text`, `story_so_far`, `transcript`가 로깅·분석 호출부에 나타나면 빌드를 실패시킨다.
4. **Edge Function:** LLM 요청·응답 본문을 로깅하지 않는다. `generation_runs`에는 토큰 수, 지연, 검증 결과, C 비율, 비용만 저장한다 (PDR §23에 이미 "본문 텍스트 저장 금지" 명시).
5. **크래시 리포트:** Sentry 등을 쓸 경우 `beforeSend`에서 문자열 길이 40자 초과 필드를 마스킹한다. **M1에서는 크래시 리포터를 아예 붙이지 않는 것**이 가장 안전하다.
6. **에러 메시지:** 예외에 원문을 담지 않는다. `DreamProcessingException(dreamId, stage, code)`만 쓴다.

### 5.11 환경 분리와 Mock

| 환경 | Supabase | 앱 | 데이터 |
|---|---|---|---|
| dev | 로컬 `supabase start` | `--dart-define=ENV=dev` | 시드 스크립트 |
| staging | 별도 프로젝트 | TestFlight 내부 | 실데이터 유사, 실계정 없음 |
| prod | 별도 프로젝트 | App Store | 실데이터 |

- **Supabase 프로젝트를 환경별로 분리한다.** 스키마만 나누면 RLS 사고 시 실데이터가 노출된다.
- 마이그레이션은 `supabase/migrations/`에 파일로 관리하고 CI에서 staging → prod 순으로 적용한다.
- **Mock 엔진:** `EngineClient` 인터페이스에 구현체 2개를 둔다.
  - `MockEngineClient`: 고정 지연 + 사전 정의 응답 3종(성공, 검증 실패 후 성공, 최종 폴백). **UI와 상태 기계 전체를 LLM 없이 테스트**한다.
  - `RemoteEngineClient`: Edge Function 호출.
  - 전환은 `--dart-define=ENGINE=mock|remote`.
- **W0에서 Mock을 먼저 만든다.** 이것이 §1의 최대 위험 1번에 대한 대응이다.

---

## 6. 수정 데이터 모델

PDR §23 초안을 기준으로 **누락된 제약과 정책**을 채운다. 변경점만 표기한다.

### 6.1 마이그레이션 단위

| 파일 | 내용 |
|---|---|
| `0001_init_enums.sql` | enum 타입 정의 |
| `0002_core_tables.sql` | volumes, dreams, dream_elements |
| `0003_manuscript.sql` | entities, entity_mentions, scenes, passages, link_decisions |
| `0004_memory_progress.sql` | narrative_memory, progress_events |
| `0005_jobs.sql` | jobs, generation_runs, claim_job() |
| `0006_rls.sql` | 전 테이블 RLS 정책 |
| `0007_triggers_rpc.sql` | U 잠금 트리거, commit_scene() RPC, recompute_progress() |

**[제안]** PDR의 `text check (...)` 대신 **Postgres enum**을 쓴다. 타입 안전성과 Dart codegen 매핑이 개선된다.

### 6.2 누락된 제약 — 전체 목록

| 테이블 | 누락 | 추가 |
|---|---|---|
| volumes | user당 active 1개 보장 없음 | **부분 유니크 인덱스** (§6.3) |
| volumes | `vol_no` 중복 가능 | `unique (user_id, vol_no)` |
| volumes | POV가 자유 문자열이고 기본값이 없음 | `narrative_voice` enum, 기본값 `third_person_past` |
| dreams | volume_id FK 정책 없음 | `references volumes on delete set null` |
| dreams | 조회 인덱스 없음 | `index (user_id, dream_date desc)`, `index (user_id, status)` |
| dream_elements | FK cascade 없음 | `references dreams on delete cascade` |
| entities | 볼륨 내 역할명 중복 | `unique (volume_id, role_name)` |
| entity_mentions | PK 없음 | `primary key (entity_id, scene_id, coalesce(passage_id, ...))` → **대리키 + 유니크**로 변경 |
| scenes | 순서 유니크 없음 | `unique (volume_id, order_key)` |
| scenes | 조회 인덱스 | `index (volume_id, order_key)` |
| passages | FK cascade | `references scenes on delete cascade` |
| passages | 순서 유니크 | `unique (scene_id, order_key)` |
| passages | **D 문단 무결성** | `check (origin <> 'D' or array_length(source_element_ids,1) >= 1)` |
| passages | **U 잠금 일관성** | `check (origin <> 'U' or locked = true)` |
| link_decisions | 중복 질문 | `unique (dream_id, kind, (payload->>'element_id'))` |
| progress_events | 재계산 인덱스 | `index (volume_id, created_at)` |
| jobs | **중복 실행 방지** | §6.4 |
| jobs | 폴링 인덱스 | `index (status, created_at) where status = 'queued'` |
| generation_runs | FK | `references jobs on delete cascade` |

### 6.3 핵심 추가 DDL

```sql
-- 한 사용자당 active/completable/completing 볼륨은 1개
create unique index uq_volume_active
  on volumes (user_id)
  where status in ('active','completable','completing');

-- 장면·문단 순서: fractional index (문자열 비교로 정렬)  [G4 해결]
-- 규칙: 'a0' 기준, 두 키 사이 삽입 시 중간 문자열 생성 (LexoRank 방식)
--   맨 뒤 추가:  last='a5' → 'a6'
--   사이 삽입:  'a2'와 'a3' 사이 → 'a2V'
-- Dart/TS 양쪽에 동일 구현을 두고, 유닛 테스트로 교차 검증한다.
alter table scenes   add constraint chk_order_key check (order_key ~ '^[a-zA-Z0-9]+$');
alter table passages add constraint chk_order_key check (order_key ~ '^[a-zA-Z0-9]+$');

-- open_image 저장  [X4 해결]
alter table scenes add column open_image text;

-- 프롤로그 판정  [G7 해결]
alter table volumes add column prologue_scene_id uuid references scenes(id);
```

### 6.4 작업 큐 중복 실행 방지

```sql
-- 같은 dream의 같은 단계는 하나만 살아 있다
create unique index uq_job_active
  on jobs (dream_id, type)
  where status in ('queued','running');

-- 클라이언트 중복 요청 차단 (오프라인 재전송 대비)
alter table jobs add column idempotency_key uuid not null;
create unique index uq_job_idem on jobs (user_id, idempotency_key);

-- 워커의 원자적 점유
create or replace function claim_job() returns jobs
language plpgsql security definer as $$
declare j jobs;
begin
  select * into j from jobs
   where status = 'queued' and attempt < 3
   order by created_at
   for update skip locked
   limit 1;
  if not found then return null; end if;
  update jobs set status='running', attempt=attempt+1, updated_at=now()
   where id = j.id returning * into j;
  return j;
end $$;
```

- `for update skip locked`가 **동시 워커 중복 실행을 막는 핵심**이다. pg_cron과 즉시 invoke가 겹쳐도 안전하다.
- `running` 상태가 5분 이상이면 좀비로 간주하고 `queued`로 되돌리는 정리 작업을 pg_cron(1분)으로 둔다.

### 6.5 E6 Commit 트랜잭션 경계

**한 RPC, 한 트랜잭션.** Edge Function이 여러 번 INSERT 하지 않는다.

```sql
create or replace function commit_scene(
  p_dream_id uuid, p_volume_id uuid, p_payload jsonb
) returns uuid
language plpgsql security definer as $$
declare v_scene_id uuid; v_mu numeric;
begin
  -- 1) 멱등: 이미 커밋된 dream이면 기존 scene_id 반환
  select id into v_scene_id from scenes
   where volume_id = p_volume_id and p_dream_id = any(source_dream_ids) limit 1;
  if found then return v_scene_id; end if;

  -- 2) scene INSERT
  -- 3) passages INSERT (origin, source_element_ids, c_reason 포함)
  -- 4) entities upsert + entity_mentions INSERT
  -- 5) dreams.status = 'in_manuscript', dreams.clarity 확정
  -- 6) MU 계산 → progress_events INSERT (reasons jsonb)
  -- 7) volumes.progress_mu = progress_mu + v_mu
  -- 8) volumes.status: 완결 조건 충족 시 'completable'
  return v_scene_id;
end $$;
```

**멱등성이 1번에 있다.** E6이 두 번 실행돼도 장면이 중복 생성되지 않는다. 워커 재시도의 안전망이다.

### 6.6 progress_mu 재계산 `[X3 반영]`

```sql
create or replace function recompute_progress(p_volume_id uuid) returns numeric ...
  -- sum(delta_mu) from progress_events where volume_id = p_volume_id
  -- volumes.progress_mu 갱신 후 반환
```

- 평상시에는 `volumes.progress_mu`를 증분 갱신한다 (읽기 성능).
- 재계산은 **꿈을 원고에서 뺄 때, 장면을 삭제할 때, 데이터 복구 시**에만 호출한다.
- **원문 수정으로는 재계산하지 않는다** (X3). MU는 커밋 시점에 확정된 이력이다.

### 6.7 상태 기계 `[G2 해결]`

**`jobs.status`**

```
queued ──claim──▶ running ──성공──▶ done ──(다음 단계 enqueue)
                     │
                     ├─실패(attempt<3)─▶ queued  (백오프 후)
                     └─실패(attempt>=3)─▶ failed
```

**`dreams.status`와 화면 대응**

| dreams.status | 조건 | S06 표시 | S12 보관함 표시 |
|---|---|---|---|
| `queued` | 로컬 저장 완료, 전송 대기 | "곧 시작합니다" | 회색 점 |
| `processing` | E1~E5 진행 중 | 단계 라벨 (VS §10) | 진행 표시 |
| `in_manuscript` | E6 커밋 성공 | 리빌로 전환 | 원고 반영 |
| `archived_only` | 사용자가 원고에서 뺌 / standalone 배치 | — | 기록만 |
| `failed` | 3회 실패 또는 폴백도 실패 | 실패 UI + 다시 시도 | 재시도 버튼 |

**E5 실패 경로 (PDR §13 "재시도 1회 → 폴백"의 구체화)**

```
E4 생성 → E5 검증
  ├ pass → E6
  ├ fail 1회차 → E4 재생성 (실패 사유를 프롬프트에 주입) → E5
  │     ├ pass → E6
  │     └ fail 2회차 → E4-fallback (충실 모드, C 0~1개, 축약) → E5-relaxed(V1,V3,V6만)
  │            ├ pass → E6 (generation_runs.is_fallback = true)
  │            └ fail → dreams.status='failed'
```

- **E7은 실패해도 E6 결과를 되돌리지 않는다.** `narrative_memory`가 갱신되지 않을 뿐이고, 다음 꿈 처리 시 재계산된다. 사용자에게는 아무것도 표시하지 않는다.
- **폴백으로 커밋된 장면**은 리빌 화면에 별도 표시를 하지 않는다. 사용자에게 품질 저하를 알릴 이유가 없다. 대신 `generation_runs.is_fallback`으로 운영 지표(§9)를 본다.

### 6.8 꿈 삭제·수정 시 파생 데이터 `[PDR §20 구체화]`

| 동작 | 처리 |
|---|---|
| **원문 수정** | `dreams.raw_text` 갱신, `raw_text_edited_at` 기록. **파생 장면·MU 불변** (X3). "이 꿈에서 온 장면 다시 쓰기" 버튼 노출 |
| **다시 쓰기** | 기존 장면의 `passages` 중 `origin='U'`는 **보존**, D·C 문단만 삭제 후 E3부터 재실행. 기존 `progress_events` 취소 이벤트(−MU) 기록 후 새 이벤트 |
| **원고에서 빼기** | scene 삭제(cascade로 passages), `dreams.status='archived_only'`, 취소 MU 이벤트, `recompute_progress()` |
| **꿈 삭제 (a) 기본** | scene·passages cascade 삭제, dream_elements cascade, dream 하드 삭제, 취소 MU 이벤트 |
| **꿈 삭제 (b)** | passages의 `source_dream_id=null`, `origin='D'→'C'`, `c_reason='출처 꿈이 삭제되었습니다'`, dream만 삭제 |

**(b)에서 U 문단은 그대로 둔다.** 사용자가 직접 쓴 문장은 꿈 삭제와 무관하다.

### 6.9 RLS 정책 초안

```sql
alter table volumes enable row level security;
create policy p_volumes on volumes for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
-- dreams, dream_elements(조인), entities(조인), scenes(조인), passages(조인),
-- link_decisions, narrative_memory, progress_events, jobs 동일 패턴
```

- **조인 기반 테이블**(dream_elements, passages 등)은 상위 테이블을 통해 소유권을 확인한다.
  ```sql
  create policy p_passages on passages for all using (
    exists (select 1 from scenes s join volumes v on v.id = s.volume_id
            where s.id = passages.scene_id and v.user_id = auth.uid())
  );
  ```
  성능을 위해 **`passages`에 `user_id` 비정규화 컬럼을 두는 것**을 권고한다. 조인 정책은 문단 수가 늘면 느려진다.
- `generation_runs`는 **클라이언트 접근 불가**로 둔다. 정책 없이 RLS만 켜면 service_role만 읽을 수 있다.
- Edge Function은 `service_role` 키를 쓰되, **함수 내부에서 항상 `user_id`를 명시적으로 검증**한다. RLS 우회 권한이므로 코드가 유일한 방어선이다.

---

## 7. 다음 마일스톤 범위 (M1)

각 항목은 사용자 시나리오 / 정상 / 실패 / 입출력 / 상태 / 보안 / 완료 조건 / 테스트를 포함한다.

### M1-1. Apple 로그인과 세션

- **시나리오:** 앱을 처음 열면 온보딩 3장 뒤 "Apple로 계속하기"를 누른다. 이후 실행에서는 바로 원고 홈으로 간다.
- **정상:** Sign in with Apple → Supabase `signInWithIdToken` → 세션 저장 → `volumes` 없으면 S02로, 있으면 S03으로.
- **실패:** 사용자 취소(무시하고 온보딩 유지), 네트워크 오류("연결을 확인해 주세요", 재시도 버튼), 토큰 만료(자동 갱신, 실패 시 재로그인 유도).
- **입출력:** in = Apple identity token / out = `auth.users.id`, 세션 JWT.
- **상태:** `unauthenticated` / `authenticating` / `authenticated` / `error`.
- **보안:** 세션 토큰은 Keychain(`flutter_secure_storage`)에 저장한다. SharedPreferences를 쓰지 않는다. **이름·이메일을 저장하지 않는다** (필요 없음, 수집 최소화).
- **완료 조건:** 앱 삭제 후 재설치해도 같은 Apple ID로 기존 데이터에 접근된다.
- **테스트:** 신규 가입 / 재로그인 / 취소 / 오프라인 시도 / 토큰 만료 시뮬레이션.

### M1-2. Supabase 스키마·마이그레이션·RLS

- **시나리오:** (개발자용) `supabase db reset`으로 로컬에 전체 스키마가 복원된다.
- **정상:** `0001`~`0007` 순차 적용, 시드 스크립트로 테스트 볼륨 1개 생성.
- **실패:** 마이그레이션 실패 시 전체 롤백. prod 적용 전 staging 필수.
- **보안:** **RLS 누락 테이블 0개.** CI에서 `pg_tables`를 훑어 `rowsecurity=false`인 public 테이블이 있으면 실패시킨다.
- **완료 조건:** 사용자 A의 세션으로 사용자 B의 `dreams`를 조회하면 0행이 반환된다 (자동 테스트).
- **테스트:** RLS 교차 접근 테스트 9개 테이블 × (select/insert/update/delete).

### M1-3. Repository 계층과 로컬 영속화

- **시나리오:** 비행기 모드에서 앱을 열면 기존 원고와 보관함이 그대로 보인다.
- **정상:** 모든 화면은 `Repository` 인터페이스만 본다. `DriftRepository`가 로컬을 읽고, `SyncService`가 백그라운드에서 원격과 맞춘다.
- **실패:** 동기화 충돌 시 **로컬 우선**. 단 `passages`는 서버 우선(엔진이 생성 주체이므로).
- **입출력:** 인터페이스 메서드 — `watchVolume()`, `watchDreams()`, `saveDreamDraft()`, `commitDream()`, `watchJob(dreamId)`, `updatePassage()`.
- **상태:** `synced` / `pending` / `conflict`.
- **보안:** 로컬 DB는 iOS 파일 보호에 의존한다 (D4 결정 대기).
- **완료 조건:** `ENGINE=mock`, 네트워크 차단 상태에서 기록 → 보관함 표시까지 동작한다.
- **테스트:** Repository 인터페이스에 대한 계약 테스트를 Memory/Drift 두 구현체에 동일하게 실행한다.

### M1-4. 꿈 초안 자동저장

- **시나리오:** 기록 중 전화가 온다. 돌아오면 쓰던 내용이 그대로 있다.
- **정상:** 텍스트 변경 500ms 디바운스 후 로컬 `dream_drafts`에 저장. 음성은 부분 인식 결과마다 저장. 앱 재시작 시 S04 진입하면 초안을 복원한다.
- **실패:** 저장 실패 시 조용히 재시도한다. 사용자에게 알리지 않는다 (기록 순간의 마찰 금지, PDR §12).
- **상태:** `empty` / `editing` / `draft_saved` / `submitted`.
- **보안:** 초안도 꿈 원문이다. 로그 금지 대상.
- **완료 조건:** 강제 종료 후 재실행해도 직전 입력이 남아 있다.
- **테스트:** 백그라운드 전환 / 강제 종료 / 저장 중 전송 / 초안 폐기.

### M1-5. 오프라인 처리 큐

- **시나리오:** 비행기에서 꿈을 기록한다. 착륙 후 앱을 열면 장면이 만들어져 있다.
- **정상:** §5.3 Outbox. 연결 복구 시 순차 전송 → `jobs` 생성 → 처리.
- **실패:** 6회 실패 후 `failed`. 보관함에 "다시 시도" 노출. 서버가 409(중복)를 반환하면 성공으로 처리한다.
- **상태:** outbox 항목 — `pending` / `sending` / `done` / `failed`.
- **완료 조건:** 기내 모드에서 꿈 3개 기록 → 연결 복구 → 3개 모두 순서대로 처리된다. 중복 생성 0건.
- **테스트:** 기내 모드 저장 / 전송 중 앱 종료 / 중복 키 재전송 / 부분 실패.

### M1-6. 실제 녹음과 STT `[B2: 온디바이스]`

- **시나리오:** 기상 직후 녹음 버튼을 1탭 하고 말한다. 말한 내용이 텍스트로 나타난다.
- **정상:** 마이크 권한 → `SFSpeechRecognizer(onDevice)` → 부분 결과 스트림 → VS §9 도트 연동 → 종료 시 최종 텍스트를 편집 가능 상태로 표시 → 저장.
- **실패:**
  - 권한 거부 → 텍스트 입력으로 전환하고 설정 안내를 1회 표시
  - 온디바이스 불가 → **자동으로 텍스트 모드 전환** (서버 STT 폴백 금지)
  - 인식 결과 공백 → "들리지 않았어요. 직접 적어보시겠어요?"
  - 5분 초과 → 자동 종료 후 저장
- **입출력:** in = 마이크 스트림 / out = `raw_text`, `input_mode='voice'`.
- **보안:** **오디오 파일을 디스크에 저장하지 않는다.** 스트림만 사용한다. 이것이 PDR §25 "STT 후 음성 삭제"보다 더 안전하다.
- **완료 조건:** 실제 기기에서 기상 직후 녹음 10건을 수행하고 정확도를 기록한다 (PDR §31-4 검증).
- **테스트:** 권한 3상태 / 무음 / 장시간 / 중단 / 백그라운드 전환.

### M1-7. E1~E7 파이프라인과 작업 큐

- **시나리오:** 저장 후 처리 화면이 실제 단계를 따라 움직이고, 끝나면 새 장면이 나온다.
- **정상:** §5.6 큐 → 각 Edge Function이 한 단계 실행 → `jobs` 갱신 → 클라이언트가 Realtime으로 라벨 전환 → E6 커밋 → 리빌.
- **실패:** §6.7 상태 기계. 폴백까지 실패하면 "장면을 만들지 못했어요. 꿈은 보관함에 저장되어 있어요." + 다시 시도.
- **상태:** `jobs.status` × 7단계.
- **보안:** LLM 호출은 Edge Function 내부에서만. 요청·응답 본문 로깅 금지.
- **완료 조건:** 실제 꿈 20건에 대해 성공률 ≥90%, p95 지연 ≤90초, `faithful` 모드 C 비율 ≤15% 준수.
- **테스트:** 단계별 유닛(스키마 검증) / 통합(20건 배치) / 재시도 / 폴백 / 타임아웃 / 중복 invoke.

### M1-8. 로그와 분석 이벤트

- **시나리오:** (운영) 어떤 단계에서 실패가 몰리는지 본다.
- **정상:** §5.10 래퍼. M1 핵심 이벤트 8종 — `dream_saved`, `recall_answered`, `recall_skipped`, `processing_completed`, `processing_failed`, `reveal_viewed`, `link_decided`, `passage_edited`.
- **보안:** 허용목록 강제. CI 금지 패턴 검사.
- **완료 조건:** 전체 플로우 1회 실행 후 로그와 분석 페이로드를 덤프해 **원문 조각이 0건**임을 확인한다.
- **테스트:** 로깅 래퍼 유닛 테스트(비허용 키 제거), CI grep 규칙.

### M1-9. 오류·재시도·폴백 UI

- **시나리오:** 처리에 실패했지만 꿈은 사라지지 않았다는 것을 안다.
- **정상/실패:** §6.7 표. VS §10 실패 모션(도트가 S0로 흩어짐).
- **문안 규칙:** 사과하지 않는다. 무엇이 안전한지 먼저 말하고 다음 행동을 준다 (VS §16).
- **완료 조건:** 네트워크·서버·검증 3종 실패를 강제 주입해 각각 올바른 화면이 나온다.

### M1-10. 테스트 데이터와 Mock 전환

- **시나리오:** (개발자) `ENGINE=mock`으로 LLM 비용 없이 전체 UI를 돌린다.
- **정상:** §5.11. 고정 응답 3종 + 지연 시뮬레이션.
- **완료 조건:** Mock 모드에서 기록→리빌까지 완주. 위젯 테스트가 Mock 위에서 동작.
- **테스트:** 골든 테스트(S03/S06/S07), 통합 테스트 1개(기록→리빌).

---

## 8. 세부 작업 백로그

> **Codex용 상세 작업지시서는 별첨 `MUMUMONG_M1_WorkOrders.md`에 있다.** 각 WO는 목적, 수정 파일, 구현 상세, 완료 조건, 테스트를 포함한다. 아래는 순서와 일정이다.

| 순서 | 작업 | 시간 | 선행 | 완료 기준 | 주요 위험 |
|---:|---|---:|---|---|---|
| 1 | **WO-00 저장소 재편 + 의존성 도입** | 5h | — | 폴더 구조 전환 후 기존 2개 테스트 통과 | 한 번에 해야 함. 나중에 하면 충돌 |
| 2 | WO-01 로깅 래퍼 + 기존 `ci.yml`에 검사 스텝 추가 | 3h | WO-00 | 금지 패턴 검사 통과 | **가장 먼저.** 나중엔 이미 샘 |
| 3 | WO-02 환경 분리 + Supabase 로컬 | 3h | WO-00 | `supabase db reset` 동작 | — |
| 4 | WO-03 마이그레이션 0001~0005 | 6h | WO-02 | 시드 삽입 성공 | enum 변경은 이후 비용 큼 |
| 5 | WO-04 RLS 0006 + 교차 접근 테스트 | 4h | WO-03 | 9테이블 교차 테스트 통과 | 조인 정책 성능 |
| 6 | WO-05 트리거·RPC 0007 | 5h | WO-03 | U 잠금 트리거 테스트 통과 | `security definer` 권한 |
| 7 | **WO-06 도메인 모델 신규 작성** | 6h | WO-00 | 모델 8종 + 직렬화 테스트 | **v0.1 대비 신규.** 기존 모델 없음 |
| 8 | WO-07 Repository 인터페이스 + MemoryRepository | 6h | WO-06 | 계약 테스트 골격 통과 | — |
| 9 | **WO-08 화면 4개를 Repository에 배선** | 10h | WO-07 | 하드코딩 리터럴 0개 | **v0.1 대비 신규.** Reader·Archive는 전면 |
| 10 | WO-09 Drift 로컬 스키마 + DriftRepository | 8h | WO-07 | 계약 테스트를 Drift로 통과 | — |
| 11 | WO-10 Apple 로그인 + 세션 | 5h | WO-04, WO-09 | 재설치 후 데이터 복원 | 심사 요건(계정 삭제) |
| 12 | WO-11 Mock 엔진 + 전환 구조 | 5h | WO-07 | Mock으로 기록→리빌 완주 | — |
| 13 | WO-12 초안 자동저장 | 3h | WO-09 | 강제 종료 복원 | — |
| 14 | WO-13 Outbox 큐 + 동기화 | 8h | WO-09, WO-10 | 기내모드 3건 무중복 | **버그 최다 구간** |
| 15 | WO-E1 Extract | 5h | WO-03 | 20건 스키마 100% 유효 | `span` 산출 난이도 |
| 16 | WO-E2 Link | 5h | WO-E1 | 임계값 3구간 동작 | 신뢰도 보정 |
| 17 | WO-E3 Plan | 4h | WO-E2 | placement 5종 분기 | — |
| 18 | WO-E4 Write + 프롬프트 | 10h | WO-E3 | 20건 생성, C 비율 준수 | **품질 반복 필요. 여유 확보** |
| 19 | WO-E5 검증기 V1~V7 | 6h | WO-E4 | 위반 7종 탐지 | — |
| 20 | WO-E6 commit_scene 연결 | 4h | WO-05, WO-E5 | 중복 호출 멱등 | 트랜잭션 경계 |
| 21 | WO-E7 Remember | 4h | WO-E6 | 요약 1.5k 상한 | — |
| 22 | WO-14 작업 큐 워커 + pg_cron | 6h | WO-E1~E7 | 동시 invoke 중복 0 | SKIP LOCKED 검증 |
| 23 | **WO-15 S06 처리 구간 재작성 (Timer→Stream)** | 7h | WO-14 | 네트워크 전환 시 지속 | **v0.1 5h → 7h.** 타이머 기반이라 재작성 |
| 24 | WO-16 실제 녹음·STT | 6h | WO-12 | 기상 녹음 10건 측정 | 정확도 미달 시 D2 재검토 |
| 25 | WO-17 S10 편집 + U 잠금 (앱) | 5h | WO-05, WO-09 | 트리거 위반 차단 | 편집 화면 자체가 신규 |
| 26 | WO-18 S09 출처 시트 실데이터 + span | 4h | WO-E1, WO-08 | 원문 강조 정확 | — |
| 27 | WO-19 S01 온보딩 + AI 고지 동의 | 3h | WO-10 | 동의 없이 호출 불가 | — |
| 28 | WO-20 S16 설정(계정 삭제·내보내기) | 4h | WO-10 | 삭제 시 전 테이블 제거 | 심사 요건 |
| 29 | WO-21 분석 이벤트 8종 | 3h | WO-01 | 무본문 덤프 확인 | — |
| 30 | WO-22 통합 테스트 + 실꿈 20건 리허설 | 8h | 전체 | 성공률 ≥90%, p95 ≤90s | — |
| | **합계** | **≈ 142h** | | | |

**주 17시간 기준 약 8~9주.**

**v0.1(134h)에서 달라진 점**

| 변경 | 시간 | 이유 |
|---|---:|---|
| WO-00 저장소 재편 신설 | +5h | 평면 7파일, 의존성 0개 `[코드]` |
| WO-06 도메인 모델 신설 | +6h | 이식할 모델이 없음 (C2) |
| WO-08 화면 배선 신설 | +10h | Reader·Archive가 위젯 리터럴 (C3) |
| WO-07 Repository 축소 | −2h | 계약만 정의, 이식 작업 없음 |
| WO-09 Drift 축소 | −0h | 마이그레이션할 기존 데이터 없음 |
| WO-15 처리 구간 | +2h | Timer 기반이라 배선이 아닌 재작성 (C4) |
| 셰이더 WO 삭제 | −0h | 이미 CustomPainter (C5) |

**8주가 길면 절삭 순서 (PDR §28 원칙 유지):**
1. WO-16 실제 STT → 텍스트 전용 출시 (−6h). 음성은 M2
2. WO-18 span 강조 → 원문 전문 표시로 단순화 (−2h)
3. WO-21 분석 → 이벤트 4종으로 축소 (−1.5h)

**절대 자르지 않는다:** WO-01(로깅), WO-04(RLS), WO-05(U 잠금), WO-E5(검증기), WO-20(계정 삭제).

---

## 9. 테스트·보안·프라이버시 체크리스트

### 9.1 출시 차단 항목 (하나라도 미달이면 TestFlight 배포 금지)

| # | 항목 | 검증 방법 |
|---|---|---|
| P1 | public 스키마 전 테이블 RLS 활성 | CI 쿼리 |
| P2 | 사용자 A가 B의 데이터 접근 불가 | 자동 교차 테스트 9테이블 |
| P3 | 로그·분석·에러에 꿈 원문 0건 | 전체 플로우 덤프 수동 검수 + CI grep |
| P4 | `generation_runs`에 본문 미저장 | 스키마에 text 컬럼 부재 확인 |
| P5 | U 문단을 엔진이 수정 불가 | 트리거 위반 테스트 |
| P6 | 오디오 파일 디스크 미저장 | 파일 시스템 검사 |
| P7 | 계정 삭제 시 전 테이블 하드 삭제 | 삭제 후 잔존 행 0 |
| P8 | 데이터 내보내기 동작 (JSON) | 실행 확인 |
| P9 | AI 처리 고지 동의 없이 LLM 호출 불가 | 코드 경로 검사 |
| P10 | 세션 토큰 Keychain 저장 | 구현 확인 |
| P11 | 만 14세 미만 가입 차단 (PDR §25) | 온보딩 확인 |
| P12 | 크래시 리포터 미부착 또는 마스킹 적용 | 의존성 확인 |

### 9.2 기능 테스트

| 층 | 항목 |
|---|---|
| 유닛 | MU 계산, clarity 판정, order_key 생성(Dart/TS 교차), 로깅 허용목록, 검증기 V1~V7 |
| DB | RLS 교차 접근, U 잠금 트리거, commit_scene 멱등, claim_job 동시성, cascade 삭제 |
| 통합 | 기록→리빌 전체(Mock), 기록→리빌 전체(실제), 오프라인 3건, 재시도, 폴백 |
| 위젯 | S03/S06/S07 골든 (Day/Night) |
| 수동 | 기상 직후 녹음 10건, 실제 꿈 20건 품질 검수 |

### 9.3 운영 지표 (M1 종료 시 확인)

| 지표 | 목표 |
|---|---|
| 파이프라인 성공률 (폴백 제외) | ≥ 90% |
| 폴백 발동률 | ≤ 8% |
| p95 처리 지연 | ≤ 90초 |
| `faithful` 모드 C 비율 | ≤ 15% |
| `balanced` 모드 C 비율 | ≤ 35% |
| 꿈 1건당 비용 | ≤ 200원 |
| 중복 장면 생성 | 0건 |

---

## 10. 사용자에게 필요한 최종 의사결정

| # | 결정 | 권고 | 근거 | 미결 시 영향 |
|---|---|---|---|---|
| **D1** | **서술 시점(POV)** | **확정 — 설정형. 기본 `third_person_past`, 선택 `first_person_past`** | L1 설정으로 E4에 주입한다. 1인칭에서는 화자만 역할명 규칙의 예외다 | 해소 |
| **D2** | **STT 방식** | **확정 — iOS 온디바이스, 서버 폴백 없음** | §5.5 — 프라이버시 포지셔닝과 정합. 실패 시 텍스트 전환 | 해소 |
| **D3** | **길이 선택** | **M1은 단편 고정.** UI 선택 제거, `format` 컬럼은 유지 | PDR §31-2 — 3개월 내 중편 완결자 없음 | S02 설계 불가 |
| **D4** | **로컬 DB 암호화** | **M1은 iOS 파일 보호로 충분. M2에서 SQLCipher 검토** | 꿈 원문이 기기에 평문 저장된다. 기기 잠금이 1차 방어 | 착수는 가능하나 나중에 마이그레이션 비용 |
| **D6** | **저장소 재편 (신규)** | **확정 — WO-00에서 폴더 구조 전환 + 기반 의존성 도입** | 평면 7파일·의존성 0개 상태에서 데이터 계층을 얹을 수 없다 | 해소 |
| **D5** | **일정** | **8~9주(142h) 수용 / 또는 §8 절삭으로 7주** | 데이터 계층 부재(§2.2)로 v0.1 추정에서 +8h. WO-E4 품질 반복과 WO-13 Outbox가 최대 변수 | 범위 초과로 M1이 끝나지 않음 |

---

## 11. 남은 의사결정 (3개)

1. **D3 길이 선택:** M1을 단편 고정으로 확정할 것인가?
2. **D5 일정:** 8주 전체를 가는가, 아니면 음성(WO-16)을 M2로 미루고 6주로 줄이는가?
3. **WO-E4 품질 기준:** 실제 꿈 20건의 합격·불합격을 누가 판정하며, PDR §28의 W1~2 게이트("5명 중 3명이 다시 읽고 싶다")를 그대로 쓸 것인가?

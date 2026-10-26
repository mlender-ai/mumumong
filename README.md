# 무무몽 MUMUMONG

> **에이전트 인수인계(2026-10-26):** [현재 배포·문서·변경 파일·QA·남은 작업·권한 제한 전체](/Users/cocteau/Documents/무무몽/docs/HANDOFF_2026-10-26.md). 아래 일부 개요는 이전 단계의 기록이며, 최신 구현·배포 상태는 인수인계와 [STATUS](/Users/cocteau/Documents/무무몽/docs/STATUS.md)를 우선 확인하세요. 최신 변경은 다수 미커밋 상태입니다.

[![CI](https://github.com/mlender-ai/mumumong/actions/workflows/ci.yml/badge.svg)](https://github.com/mlender-ai/mumumong/actions/workflows/ci.yml)

꿈을 기록하면 출처가 있는 소설이 쌓이는 Flutter 앱입니다. iOS 구현과 로그인 없는 공개 웹 체험을 함께 개발하고 있습니다. 실제 사용 준비와 소설 품질 검증은 진행 중입니다.

> 핵심 질문 하나 — 사람이 자신의 꿈에서 시작한 책 한 권을 실제로 완결하는가?
> 이 질문을 검증하지 않는 기능은 MVP에 넣지 않습니다.

| 정본 | 문서 |
|---|---|
| 제품 기획·PDR | [`docs/MUMUMONG_PRODUCT_PDR_v0.1.md`](docs/MUMUMONG_PRODUCT_PDR_v0.1.md) |
| 비주얼 시스템 | [`docs/MUMUMONG_VISUAL_SYSTEM_v0.1.md`](docs/MUMUMONG_VISUAL_SYSTEM_v0.1.md) |
| M1 개발 지시서 | [`docs/MUMUMONG_M1_Report.md`](docs/MUMUMONG_M1_Report.md) |
| M1 작업지시서 | [`docs/MUMUMONG_M1_WorkOrders.md`](docs/MUMUMONG_M1_WorkOrders.md) |
| 현재 구현 상태 | [`docs/STATUS.md`](docs/STATUS.md) |
| 2026-10-14 디자인 기준 | [`docs/DESIGN_DIRECTION_vNext.md`](docs/DESIGN_DIRECTION_vNext.md) |
| 현재 디자인 시스템(P3) | [`docs/MUMUMONG_DESIGN_SYSTEM_v0.7.md`](docs/MUMUMONG_DESIGN_SYSTEM_v0.7.md) |
| P0–P6 실행·검증 상태 | [`docs/UX_REBUILD_STATUS.md`](docs/UX_REBUILD_STATUS.md) |
| 에이전트 규칙 | [`AGENTS.md`](AGENTS.md) |

## 현재 범위

| 기능 | 구현·연결 | 현재 검증 경계 |
|---|---|---|
| 꿈 기록·초안·원고 저장 | Drift 영속 저장, Repository 스트림, Outbox | 로컬 계약/위젯 테스트; 실기기 유실·성능 확인 필요 |
| 생성·출처·편집 | mock/remote 엔진, Supabase 동기화, D/C/U·U 잠금 | 로컬 테스트 및 과거 hosted smoke 기록; 실제 문학적 품질 게이트 미완 |
| 소개·동의·첫 원고 | 인증/동의/원고 생성 경로 연결 | 공개 웹은 브라우저 종속 익명 체험 계정; Apple 설정/실기기 검증 미완 |
| Reader·보관함 | 본문·출처·편집, 정확한 활성 권 sceneId 진입·읽기 위치 저장/복원 | P1 로컬·시뮬레이터 검증; 실제 웹/기기 및 오프라인 콜드스타트 검수 필요 |
| 음성 | iOS 온디바이스 채널 구현 | 웹은 텍스트 전용; 실제 iPhone STT 검수 미완 |
| 완결·PDF | 상태 enum과 PDF 조판 코드 존재 | 스냅샷·완결·내보내기 UI 연결 미완 |
| 푸시·운영 복구 | 작업 큐/재시도 코드 존재 | 정기 worker 복구 스케줄·완료 푸시 미완 |

공개 체험: [mumumong-live-trial.vercel.app](https://mumumong-live-trial.vercel.app). 2026-10-14에 인증 없는 HTTP 200과 로컬 배포본의 JS 해시 일치를 확인했습니다. 이 확인은 동의→생성→결과 전체 흐름의 검증을 뜻하지 않습니다. 최신 상세 상태는 위 실행 문서를 따릅니다.

## 저장소 구조

| 경로 | 역할 |
|---|---|
| `lib/core/` | 디자인 토큰과 공통 기반 |
| `lib/domain/` | 불변 도메인 모델, Repository 계약, DB 직렬화, MU·명료도 순수 규칙 |
| `lib/data/` | Drift 저장·Memory fixture·mock/remote 엔진·인증·동기화·음성·내보내기 |
| `lib/di/` | Riverpod 기반 Repository 주입 경계 |
| `lib/ui/` | 화면별 Flutter UI |
| `test/ui/` | 핵심 화면 위젯 테스트 |
| `test/contract/` | 저장소 구현체가 공통으로 통과해야 하는 계약 테스트 |
| `assets/fonts/` | MaruBuri·Pretendard 및 배포 고지 |
| `assets/brand/` | 앱 아이콘 원본 |
| `docs/` | 제품·비주얼 정본과 현재 상태 |
| `.github/workflows/` | 자동 분석·테스트·웹 빌드 |
| `supabase/` | 로컬 설정, DB 마이그레이션·시드·제약 테스트 |

## 실행

```bash
cp .env.example .env
make dev
```

로컬 Supabase 없이 UI·Mock 엔진 모드만 실행하려면 `make mock`을 사용합니다.

`make mock`은 개발용 로컬 인증 경로와 seed가 있는 Drift 저장소, 고정 synthetic 응답 엔진을 사용합니다. 공개 웹 체험은 `ENV=staging`, `ENGINE=remote`, `AUTH=apple` 빌드이며 웹에서 익명 체험 경로를 제공합니다. `tool/visual_preview.dart`는 별도의 MemoryRepository 디자인 fixture이고 공개 생성 서비스가 아닙니다.

새로 만든 전용 로컬 DB에서만 아래 초기화 명령을 사용하세요. 기존 로컬 데이터가 있는 DB를 초기화하면 안 됩니다. 시드는 개발 전용 계정과 synthetic 원고를 생성합니다.

```bash
make db-reset
supabase test db
```

## 검증

```bash
flutter analyze
flutter test
flutter build web --release
```

## 현재 경계

- 실제 사용 준비 상태와 모델의 소설 품질은 별도의 검증 대상입니다. mock 성공을 hosted 성공으로 보고하지 않습니다.
- 체험 계정은 같은 브라우저의 세션에 종속됩니다. Safari와 설치한 PWA 사이의 계정/기록 이전은 구현되지 않았습니다. 설치 안내는 [`docs/LIVE_TRIAL.md`](docs/LIVE_TRIAL.md)를 참고하세요.
- P3에서 저장/생성/선택적 보강을 분리하고 첫 원고 기본값 시작, 문단 메뉴, 공통 UI와 기기별 표시 설정 저장을 연결했습니다. [현재 화면·검증 기록](docs/ux-review/2026-10-18-p3/README.md)과 [디자인 시스템 v0.7](docs/MUMUMONG_DESIGN_SYSTEM_v0.7.md)을 확인하세요. P1–P3는 공개 재배포하지 않았습니다. 비동기 복구/이후 생성 설정 변경은 P4, 완결·PDF UI는 P5입니다.
- 원문과 생성 문장은 분석·서버·에러 로그에 남기지 않습니다. Q-series 기준선과 개인정보 보호 규칙을 유지합니다.

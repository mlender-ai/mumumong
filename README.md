# 무무몽 MUMUMONG

[![CI](https://github.com/mlender-ai/mumumong/actions/workflows/ci.yml/badge.svg)](https://github.com/mlender-ai/mumumong/actions/workflows/ci.yml)

"꿈으로 쓰는 책"을 검증하기 위한 Flutter 기반 iOS MVP 프로토타입입니다.

> 핵심 질문 하나 — 사람이 자신의 꿈에서 시작한 책 한 권을 실제로 완결하는가?
> 이 질문을 검증하지 않는 기능은 MVP에 넣지 않습니다.

| 정본 | 문서 |
|---|---|
| 제품 기획·PDR | [`docs/MUMUMONG_PRODUCT_PDR_v0.1.md`](docs/MUMUMONG_PRODUCT_PDR_v0.1.md) |
| 비주얼 시스템 | [`docs/MUMUMONG_VISUAL_SYSTEM_v0.1.md`](docs/MUMUMONG_VISUAL_SYSTEM_v0.1.md) |
| 현재 구현 상태 | [`docs/STATUS.md`](docs/STATUS.md) |
| 에이전트 규칙 | [`AGENTS.md`](AGENTS.md) |

## 현재 범위

- 원고 홈: 도트 커버, MU 진척, 오늘의 증가 사유, 열린 장면
- 꿈 기록: 텍스트 및 음성 시뮬레이션, 입력량 기반 도트 생성
- 기억 보강: 고정 문항 3개와 전체 건너뛰기
- 처리: Extract → Link → Write → Validate 상태와 연동된 도트 변환
- 리빌: 출처가 표시된 새 문단, D1 연결 결정, D2 배치 변경
- Reader: 출처 마크 `● ○ │`, 원문 시트, Night Paper
- 꿈 보관함: 월별 목록, 상태 필터, 기록 상세

현재 데이터와 AI 처리는 상품 감각을 검증하기 위한 로컬 시뮬레이션입니다. Supabase, STT, E1~E7 서버 파이프라인은 아직 연결되지 않았습니다.

## 저장소 구조

| 경로 | 역할 |
|---|---|
| `lib/` | Flutter 앱과 도트 상태 언어 |
| `test/` | 핵심 화면 위젯 테스트 |
| `assets/fonts/` | MaruBuri·Pretendard 및 배포 고지 |
| `assets/brand/` | 앱 아이콘 원본 |
| `docs/` | 제품·비주얼 정본과 현재 상태 |
| `.github/workflows/` | 자동 분석·테스트·웹 빌드 |

## 실행

```bash
flutter pub get
flutter run
```

## 검증

```bash
flutter analyze
flutter test
flutter build web --release
```

## 현재 경계

- 음성 버튼은 STT 결과를 보여주는 시뮬레이션입니다.
- 데이터는 메모리에만 남아 앱을 재시작하면 초기화됩니다.
- Supabase, AI 모델, 푸시, 앱 잠금, PDF 출력은 아직 연결되지 않았습니다.
- 원문과 생성 문장은 향후에도 분석·서버·에러 로그에 남기지 않습니다.

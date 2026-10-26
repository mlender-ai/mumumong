# P4 첫 단위 — 생성 중 이탈·관찰 복원

2026-10-18. P4 전체 완료가 아니다. 설정 버전 변경, 정기 worker 복구와 OS 알림은 아직 남아 있다. 이 리뷰는 가상 꿈·Memory/mock·fake gateway·임시 SQLite만 사용한다. 실제 소설 품질/hosted 인증·AI의 증거가 아니다. 공개 Vercel은 재배포하지 않았다.

## 전후

| 상태 | P3 | P4 |
|---|---|---|
| 처리 | [기존](../2026-10-18-p3/day-390-844-normal-processing.png) | [나중에 확인하기](day-390-844-normal-processing.png) |
| 밤·큰 글자 | [기존](../2026-10-18-p3/night-375-667-large-processing.png) | [동일 위계](night-375-667-large-processing.png) |

P4 processing 10개 golden + 별도 도구 14장. 기존 P3 PNG는 전후 SHA-256 집계 `75206fb6e9a1e2361d41fddbc8fa1c1a837125f9aff5dbd451363794d3619cdf`로 동일하다. 나머지 90개 기존 golden도 재비교했다.

## 직접 조작한 웹

[생성 화면을 떠난 뒤 결과 도착](browser-home-result.jpg) → [해당 12번 장면 Reader](browser-reader.jpg). 화면을 떠나도 로컬 mock engine이 계속 진행했다. 첫 열람 마커와 실제 fixture 증가량을 사용한다.

둘째 가상 꿈은 캡처 전에 끝나 [새 장면 화면](browser-last-result.jpg)이 저장됐다. 이를 processing 화면의 증거로 표시하지 않는다. 고정된 ‘문 밖의 여자’ 본문은 **로컬 목업 데이터**이며 입력한 종이 고래/역의 실생성 결과가 아니다. 이 도구는 운영에 게시하지 않는다.

## 실제 실행

- Flutter 217개 통과: 새 11개는 UI/provider 복귀 3, 실제 SQLite 재열기 1, Memory/Drift 계약 2, remote fake retry/download 4, 동기화/U 편집 race 1이다. retry ACK 전에 route를 닫는 경우도 포함한다.
- 21초 후 이탈·단일 stream 공유·재진입 enqueue/retry 0회·연결 오류 후 관찰 복구·실제 실패 구분. 프로세스가 살아 있는 widget 가상 시간이며 물리기기 21초 측정이 아니다.
- SQLite close/reopen processing 복원→실패 메타데이터 저장→다시 열기. 원래 create/process Outbox 두 건만 유지한다.
- terminal 실패 ID 기반 동일 retry 키, active 단계/성공 commit 재사용, commit 뒤 remember 실패, 다운로드 실패에서 완료 미노출→같은 commit 다운로드 재시도. Fake gateway이지 실제 HTTP/RLS가 아니다.
- 결과 다운로드 중 U 편집이 ACK되어도 편집/잠금/원문 복원/열람 마커를 보존한다. 서버 mutation 스키마는 변경하지 않았다.
- 일반/미리보기 web release, 14장 도구 생성/재비교, 직접 Dart 분석/format, privacy/log guards, frozen diff 검사 통과. root `flutter analyze --no-pub`는 기존 한국어 경로 LSP JSON crash(exit 255)로 실패.
- localhost 390×844 실제 조작과 error/warn 로그 없음. 정적 서버·Memory/mock으로 API/계정/LLM 요청은 없다.
- iPhone 17 Pro / iOS 26.5 시뮬레이터에서 기존 7개와 새 1개가 각각 통과했다. 새 시나리오는 21초 실제 대기→화면 이탈→route 밖 mock 완료→SQLite 재열기→정확한 새 장면 Reader와 열람 마커/장면 중복 없음이다. 최초 테스트는 초기 DB/홈 로드 대기가 빠져 실패했고, 대기를 보완한 재실행은 35초에 통과했다. iOS simulator 무서명 build 통과. 실제 서버 process-kill이나 물리기기 검증이 아니다.

## 재현

```sh
flutter test --no-pub
flutter test --no-pub tool/ux_baseline_capture_test.dart
flutter test --no-pub integration_test/p4_generation_recovery_test.dart -d 8E9105D0-8358-49B1-8E15-B9ABF0A6DFB1
flutter build web --release --no-pub --target tool/visual_preview.dart --output build/p4-review
python3 -m http.server 4204 --bind 127.0.0.1 --directory build/p4-review
```

처리 golden은 이제 P4를 사용하며 나머지 P3 golden은 그대로 비교한다. 이전 전체 화면을 당시 코드로 재현하는 일과 새 기준 갱신을 구분한다. 새 기준을 의도적으로 만들 때만 `--update-goldens`를 쓴다.

## 남은 일

영속적인 reveal/growth/알림 소비 영수증, 오프라인·접수 대기 복원 경계, 꿈 원문/배치/연결의 동시 동기화 충돌, 이후 생성 설정/버전/Outbox/RPC/RLS, 정기 worker와 지원 알림. 큰 글자의 연결 오류 안내 전체, 실제 강제 종료/hosted 네트워크 복구, 물리 iPhone/PWA·STT·키보드/성능, 사람 검수는 미검증이다. 운영 반영 없음.

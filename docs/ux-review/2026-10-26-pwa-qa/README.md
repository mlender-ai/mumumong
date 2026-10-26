# PWA 로컬 QA / 실패 복구 — 2026-10-26

## 범위와 사용자 선택

Apple 계정·서명·TestFlight 작업은 이번 범위에서 제외한다. 공개 연령/AI 동의 제출·QA 계정 생성·인증 후 저장/AI 생성은 하지 않는다. 새로 지어낸 fixture와 로컬 저장소로 검사한다. 공개 주소의 무인증 첫 화면/정적 리소스 확인은 계정 전체 흐름 검증이 아니다.

## 재현된 문제와 수정

1. **초기 실행 실패의 흰 화면.** 로컬 서버4219가 bootstrap 요청에503을 반환할 때 기존 `web/index.html`은 내용/안내/재시도 없이 빈 페이지였다. [수정 전](startup-failure-before.png). 초기 HTML에 정적 시작/실패 안내와 수동 ‘다시 열기’를 추가했다. 다운로드/초기화 오류와 첫 프레임20초 초과를 처리하며 실제 `flutter-first-frame`에서만 시작 레이어를 제거한다. 사용자 입력 중에는 이 감시를 해제한다. 자동 새로고침·캐시/IndexedDB/인증 초기화를 추가하지 않았다.
2. **외부 렌더러 의존.** 설치된 Flutter3.44.6 기본 loader는 CanvasKit을 gstatic에서 요청한다. 이미 배포에 있는 엔진을 `canvasKitBaseUrl`로 같은 origin에서 읽도록 했다. 이것은 외부 다운로드 경계 제거이지 물리 기기 속도 개선 실측이나 오프라인 지원의 증거가 아니다. full/Chromium JS·WASM4개와 legacy worker retirement script를 배포 해시 검사에 추가했다. 기존 Flutter의 한 번뿐인 구형 worker 해제 경로는 유지하며 사용자 저장소는 건드리지 않는다.
3. **자동 저장 실패의 무안내.** 쓰기 실패를 주입한 Chrome/VM 회귀가 수정 전 ‘자동 저장하지 못했어요’ 표시0개로 실패했다. `DraftAutosave.saveFailed`는 실패/복구 전환만 알리고 입력 화면의 작은 정적 안내 슬롯만 갱신한다. 키 입력/선택마다 부모를 rebuild하지 않으며 같은 EditableText/FocusNode를 유지한다. 저장 실패 시 텍스트는 화면에 남고 기존 순차 재시도가 최신 초안을 저장한다. 정상 복구 후 안내가 사라지는 것도 검사했다. 실제 저장소가 영구적으로 막힌 경우 복사를 안내하며 무조건 저장 성공이라고 표시하지 않는다.

초기 loader 수정의 첫 로컬 빌드는 service-worker-version 토큰에 SDK가 삽입하는 따옴표/주석을 잘못 감싸 문법 오류가 났다. 브라우저 QA에서 `Unexpected identifier`를 발견해 **공개 배포 전에** 수정했다. 실제 SDK 치환 형태를 JS 테스트에 반영하고 컴파일된 `flutter_bootstrap.js`의 `node --check`를 배포 차단 조건에 추가했다. 이 실패 실험은 최종 통과로 계산하지 않는다.

Flutter 초기화 계약은 [공식 문서](https://docs.flutter.dev/platform-integration/web/initialization)와 설치된 SDK loader/first-frame 이벤트 소스로 확인했다. 사용자에게 예외 payload나 원문을 표시/기록하지 않는다.

## 실제 브라우저에서 확인한 흐름

- 실제 `lib/main.dart`의 로컬 dev/local-auth/Drift/IndexedDB 빌드. 기본 합성 seed7건에 가상 문장을 추가해8건으로 저장했다. MemoryRepository로 저장 성공을 대신하지 않았다.
- 한글·줄바꿈 입력 → 닫기 → 이어쓰기 → 꿈 저장 → 선택적 보강(밝음/혼자/평온) → 나중에 만들기 → 새로고침 → 보관함8건 → 같은 원문/보강 확인. [재접속 후 원문](local-record-after-reload.png).
- `tool/serve_pwa_qa.mjs`의 bootstrap/main/engine 일회성503 각각에서 실패 안내 → ‘다시 열기’ → 실제 앱 첫 화면 복원. 엔진503이 같은 origin의 WASM 요청에서 발생한 것도 확인했다. [엔진 실패 안내](engine-download-failure.png), [재시도 후](startup-recovered.png).
- 별도390×844 origin4220에서 가상 초안을 저장한 뒤 bootstrap503 → 수동 재시도 → 기록 화면 → 이어쓰기 → **같은 초안 복원**을 직접 확인했다. [모바일 실패 안내](mobile-startup-failure.png), [재시도 후 초안](mobile-draft-after-retry.png). 브라우저 저장소를 삭제하거나 DB 이름을 바꾸지 않았다.
- 로컬 합성 기록에서 명시적 생성 → 실제 mock job 상태/Orb → 나중에 확인하기 → 보관함의 동일 꿈/12번 장면 → Reader 진입을 확인했다. [로컬 mock 처리 화면](local-mock-processing.png). **엔진은 mock이며 결과는 고정 합성 문장이다. 입력에 맞는 실제 AI 소설/문학 품질/hosted 복구 성공으로 세지 않는다.** 이 로컬 빌드를 배포하지 않았다.
- iOS26.5 시뮬레이터 Safari 조작도 시도했으나 현재 앱 제어의 키 이벤트가 기기 주소 입력/제출로 전달되지 않았고 좌표 입력은 창 접근 오류가 났다. Safari/PWA 키보드 검증을 완료했다고 보고하지 않는다. 무서명 simulator 빌드 통과와 별개다.

## 최종 실행 검증

| 검사 | 실제 결과 |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test integration_test tool/drift_worker.dart` | 133파일, 변경0 |
| `flutter analyze --no-pub` | **실패 exit255**, 기존 한국어 경로 LSP JSON 오류 |
| `dart analyze lib test integration_test tool/drift_worker.dart` | No issues |
| `flutter test --no-pub --reporter expanded` | **309개 통과** |
| Chrome `capture_keyboard_test.dart` | **6개 통과**: 포커스/한글 조합/animated inset3조건, 읽기 실패/timeout, 쓰기 실패/복구 |
| `bash tool/test_web_durability.sh` | 실제 WASM/IndexedDB commit 지속성 **1개 통과** |
| `node --test tool/pwa_startup_test.mjs` | **5개 통과**, 고정 안내/timeout/첫 프레임 해제/config 전달/예외 redaction |
| `node --check build/pwa-qa/flutter_bootstrap.js` 및 release bootstrap | 통과 |
| `flutter build ios --simulator --no-codesign --no-pub` | 통과; 실제 마이크/키보드/기기 검사가 아님 |
| 로컬 dev web / 배포용 remote web release | 각각 통과 |
| shell syntax / git diff whitespace / log·평가 데이터 guard | 통과 |
| 동결4파일 `edfc13c` 비교 | 변경 없음 |

Flutter 검사/빌드는 공유 출력 충돌을 피하려고 순차 실행했다. 배포 스크립트가 같은 lockfile로 Worker를 다시 만들고 JS5/Chrome6/실제 IndexedDB1을 재실행했다. Worker SHA256은 이전 수정본과 같은 `af7417de6a9acf7417dac63d1ba166d0512fbe9c63080544f94c56afa83d1c76`이다. 새로운 의존성 버전 변경이나 스키마 migration은 없다.

## 실제 공개 배포

- URL: https://mumumong-live-trial.vercel.app/
- 빌드: **20261026T002059Z**
- deployment: **dpl_HYPcxk6Vx38tM7NLHbqhM5tWoUm5**, production READY/promoted.
- 원본 SHA256: `947ff4455d07830db4a6154ea94d9c2360e73637c6ce78e5c5f1c67f1caf0d21`.
- HEAD `6c4e296f9b3d5f06d6a50e9c1aac74b7d9f1d234` + 기존 dirty working tree. commit/push하지 않았다.
- 기존 team/project `mlender-ais-projects / prj_VtS5dNxLxW12SsJMykVDhnXPtiUe`를 확인했다. stage의 **23파일** 해시 → 같은 deployment promote → 공개 **23파일** 해시/HTTP200/빌드 식별 일치를 확인했다. Standard Protection은 유지하며 공개 production alias 외의 URL을 무단 공개하지 않았다.
- `lib/main.dart`, ENVstaging/ENGINEremote/AUTHapple 빌드다. 로컬 고정 결과 walkthrough를 배포하지 않았다. 인증/동의/DB/엔진/모델/서버 migration을 바꾸지 않았다.
- 공개390×844 소개의 첫 프레임/시작 레이어 제거와 브라우저 warn/error0개를 확인했다. [공개 진입 화면](public-release-entry.png). 동의/로그인/계정/꿈/소설은 제출하지 않았다.
- Vercel10분 bounded error scan은 exit0/로그 항목0개였다. 클라이언트·Supabase·실제 생성 전체의 정상 보증이나 지속 모니터링이 아니다. 새 telemetry/외부 로그 수집·반복 모니터를 추가하지 않았다.
- rollback 후보는 이전10/25 `dpl_8t5MxfyL6yCMYMzPZWUBmncNFhXt`(키보드/Drift 지속성 수정 포함)이다. 이번 초기화/저장 실패 안내는 없으므로 완전히 동등한 동작으로 설명하지 않는다. rollback은 실행하지 않았다.

## 남아 있는 것 / 미검증

- 실제 물리 iPhone의 설치 PWA/Safari 키보드·한국어 IME·화면 회전·터치 지연/FPS/메모리/기동 시간.
- 최초 document 자체가 오프라인에서 열리지 않는 cold-start와 오프라인 인증/동의/bootstrap. 이번 guard는 HTML을 받은 뒤의 실패를 다루며 service worker offline cache를 추가하지 않았다.
- 공개 인증 후 계정→저장→실제 AI→결과/출처→재접속 전체. 사용자의 ‘공개 동의 제출 없이 로컬만’ 선택 때문에 실행하지 않았다. 기존 V2/V5 생성 실패와 Q 품질 실측 필요도 그대로다.
- 웹 녹음은 온디바이스 iPhone native 기능이 아니며 설치만으로 지원되지 않는다. 서버 STT나 가짜 녹음을 추가하지 않았다. Apple/TestFlight 준비는 사용자가 제외했다.

업데이트 확인 시 작성 중인 내용을 먼저 복사하고 기존 앱/탭을 완전히 닫았다가 다시 연다. **기록을 보호하기 위해 브라우저 데이터 삭제나 PWA 제거/재설치를 요구하지 않는다.** 저장소/계정/원고를 초기화하지 않았으며 과거에 저장되지 않은 내용을 복구했다고 주장하지 않는다.

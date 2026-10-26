# 무무몽 QA·배포 기준

2026-10-25 사용자 요청으로 고정한 작업 기억. ‘품질 이슈 없음’은 보장 문구가 아니다. 실행 환경·단계·증거·미검증·잔여 장애를 구분한다. 테스트 수/스크린샷/빌드 성공을 실사용 완료로 대신하지 않는다.

## 이번에 빠졌던 검증

10/24 영상은 웹 기록 화면의 커서→키보드 출현→사라짐을 보여준다. VM 테스트는 `kIsWeb` 안내 행을 실행하지 않았고, 이미 열린 키보드의 배치만 검사했다. 공개 브라우저 QA도 소개/설치 안내에 머물렀다. 이 조합으로 입력창이 재생성되는 회귀를 놓쳤다.

## 반드시 확인할 경로

| 경계 | 통과 증거 | 통과로 대신할 수 없는 것 |
|---|---|---|
| 첫 입력 | 필드 탭 후 키보드 열림/유지, 한글 조합·줄바꿈·선택/붙여넣기 | 미리 지정한 inset의 스크린샷 |
| 키보드 전환 | 열림/닫힘/재열림 중 동일 EditableText/포커스/조합 보존, 저장 터치 가능 | VM 결과를 웹 결과로 전용 |
| 보존 | 자동 저장→닫기→이어쓰기→저장→보관함/재접속, 중복/유실 없음 | 고정 mock 결과 |
| 저장소 오류 | 로드 실패/지연에 명시적 복구, 기존 초안 유지 | 반응 없는 입력창·무한 조용한 재시도 |
| 음성 | 앱에서 권한/기기 지원/시작/부분 전사/정지/중단, 원음 파일/업로드 없음 | 웹 도움말, fake SpeechInput, simulator를 실기기 STT로 표현 |
| 조작감 | 입력 중 장식 정지·숨은 홈 정지·버튼 즉시 반응, 실기기 프레임/지연 측정 | repaint 알림 빈도를 실제 FPS로 표현 |
| 생성 | 실제 접수→작업→검증→저장→같은 입력의 결과/출처, 오류·재진입 | DB 본문 직접 수정, 검증 실패 무시 |
| 배포 | 검증한 production-stage와 promote 대상 동일, 공개 release.json/리소스 해시·핵심 조작 | 이전 배포 QA나 HTTP200만 확인 |
| PWA 초기화 | bootstrap/main/CanvasKit 다운로드 실패→명시적 다시 열기→첫 화면·조작 복원 | 흰 화면, 끝없는 로딩, 초기화 파일만200인 검사 |
| 자동 저장 오류 | 저장 실패 안내·입력/포커스 유지→저장소 복구 후 같은 초안 저장 | 오류를 숨긴 자동 재시도, 저장된 것으로 오해시키는 화면 |

375×667 /390×844 /430×932, 작은 화면 큰 글자·밝게/밤·브라우저/설치 PWA/네이티브를 구분한다. 실제 iPhone 키보드, 음성10건 정확도와 물리 프레임/터치 지연은 별도 필수 미검증 항목이다. 기기/서명 접근이 없으면 완료로 표시하지 않는다.

## 실행·배포 순서

1. 사용자 영상 확인 → 재현 실패 테스트 → 수정 → 같은 테스트 통과. 실제 꿈 대신 새로 지어낸 fixture만 사용한다.
2. format → `flutter analyze` → 실패 시 원인/직접 분석 별도 표기 → 전체 VM 테스트 → Chrome 입력 회귀 → `bash tool/test_web_durability.sh`의 실제 WASM/IndexedDB commit 회귀 → iOS simulator 테스트/빌드 → web release. Flutter 명령은 순차 실행한다. Worker는 `bash tool/build_drift_worker.sh`로 같은 lockfile에서 컴파일한다. Drift2.35.0의 트랜잭션 flush 버그 재도입 금지.
3. 사용한 저장소/엔진/인증과 빌드 ID를 명시한다. 로컬 mock QA는 hosted E2E가 아니다. 계정/동의 조작은 필요한 사용자 승인을 받고 수행한다.
4. production-stage → 필수 리소스 해시/빌드 식별 확인 → 가능한 핵심 조작 → 동일 배포 promote → 공개 주소 식별/리소스/조작/콘솔 재검사. 입력 회귀는 `deploy_live_trial.sh`가 Chrome에서 재실행한다.
5. 재현되는 입력 불능·데이터 유실·소유권/동의 우회는 승격 중단. 수정 범위 밖 실제 소설 검증 실패와 iPhone 서명/실기기 미검증도 숨기지 않는다. 웹 핫픽스는 녹음 가능한 iPhone 앱 배포가 아니다.
6. 배포 후 확인 범위/시간과 되돌릴 이전 배포를 기록한다. 장기 모니터링·사용자 체험은 실행/예약하지 않았으면 미실행이다. 무본문 로그·집계 메타데이터만 사용하고 개인 영상 프레임은 저장소 문서에 넣지 않는다.

PWA의 `web/flutter_bootstrap.js`는 같은 배포의 CanvasKit을 사용한다. 초기화 실패/20초 초과에는 저장소를 지우지 않는 수동 재시도를 제공하고 실제 `flutter-first-frame`에서만 HTML 시작 레이어를 제거한다. `node --test tool/pwa_startup_test.mjs`와 생성된 JS 문법 검사를 모두 실행한다. `node tool/serve_pwa_qa.mjs build/pwa-qa 4220 bootstrap-once`의 `bootstrap-once/main-once/engine-once`는 로컬 정적 파일 요청에만 일회성503을 주며 사용자 저장소를 수정하지 않는다. 오프라인 cold-start 지원을 새로 구현한 것은 아니며 실제 iPhone 설치 PWA와는 별도 검증이다.

## 완료 보고 형식

설치 PWA 막대 신고는 설치 origin/manifest scope·start URL/HTML redirect/worker client navigation부터 추적한다. ‘iOS라 안 됨’으로 단정하거나 fullscreen/CSS를 임의 변경하지 않는다. [Apple WWDC23](https://developer.apple.com/videos/play/wwdc2023/10120/?time=521)은 scope 밖 링크가 Safari View Controller를 연다고 설명한다. `node --test tool/pwa_install_test.mjs`는 동일 origin·앱 ID 보존·자동 이동/저장소 초기화 금지를 검사한다. 안내 페이지·모의 standalone boolean 검사는 실제 iPhone 아이콘 실행 성공이 아니다.

원인 / 변경 / 실제 실행한 검증 / 실제 공개 빌드 / 미검증·남은 장애. 물리 기기를 검사하지 않았다면 ‘iPhone에서 해결 확인’이라고 쓰지 않는다. 알려진 실패가 남으면 ‘전체 완료·품질 문제 없음’이라고 쓰지 않는다.

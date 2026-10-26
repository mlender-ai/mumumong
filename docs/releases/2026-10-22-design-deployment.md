# 디자인 v0.8 공개 체험 배포

2026-10-22 KST · 사용자 ‘디자인 작업 마무리해서 배포’ 요청에 따른 프런트 배포. P4/P5/P6나 Q 품질 작업 전체 완료가 아니다.

## 배포 대상과 출처

- 공개 주소: https://mumumong-live-trial.vercel.app/
- 팀 `mlender-ais-projects` / 프로젝트 `mumumong-live-trial`, ID `prj_VtS5dNxLxW12SsJMykVDhnXPtiUe`.
- 최종 배포 `dpl_GN1bS7Ru9WNuwyrm1vJCCB5UHytL`, production / READY. 고유 URL `https://mumumong-live-trial-4zapilykq-mlender-ais-projects.vercel.app`은 보호되어 있으며 공유에는 공개 주소를 사용한다.
- 이전 배포 `dpl_58a8Z2icumX6HNqTPcU7eKVAvLP3`는 롤백 대상으로 보존했다. 자동 rollback/계정 삭제/DB 초기화는 하지 않았다.
- HEAD `6c4e296f9b3d5f06d6a50e9c1aac74b7d9f1d234` + 기존 비커밋 작업 트리의 현재 앱을 로컬 빌드했다. HEAD 단독 재현 배포가 아니며 새 commit/push 없음.
- 보호 설정 `prod_deployment_urls_and_all_previews` 유지. 기존 공개 주소는 비로그인 HTTP200, 고유/preview URL 보호는 유지한다. 스테이지 HTTP 검사는 Vercel CLI 인증으로 접근했다.

## 포함·제외

공유 상부 블루/라일락 빛·부유 원고 오브젝트·선택적 중립 유리·Orb 대비·빈 홈 주 행동을 포함하는 디자인 v0.8과 기존 P1–P4 첫 단위의 로컬 검증된 앱 상태를 배포했다. 입력/STT 정적, 저장→명시적 생성→실제 job 관찰→로컬 결과 수신 후 리빌 계약은 유지한다.

진입점은 `lib/main.dart`. `ENV=staging / ENGINE=remote / AUTH=apple`, 기존 Supabase `dtdmfjovpufyyekdumga` 연동이며 웹은 기존 익명 체험 로그인이다. Vercel 배포 환경 production과 앱의 staging 체험 설정은 다른 의미다. 사용자에게 Vercel 계정을 요구하지 않는다. 실제 온보딩/개별 동의/첫 원고/클라우드 저장 경로를 사용한다.

`tool/visual_preview.dart`·가상 동의·고정 mock 결과·9상태 Orb 시험 화면은 게시하지 않았다. 가입 전 ‘가상 꿈 미리 보기’는 합성 예시임을 명시한 기존 읽기 전용 안내이며 입력 결과가 아니다. 실제 처리/네트워크 대기에는 native64px Flutter Thinking Orb를 사용한다.

서비스 키·모델 키는 클라이언트에 주입하지 않았다. 브라우저용 publishable key만 빌드에 사용했으며 파일/로그/이 문서에 복사하지 않았다. 엔진/프롬프트/모델/SQL/마이그레이션·실제 원고·평가 데이터는 변경하지 않았다.

## 실제 실행

- format `lib test`: 104파일, 변경 없음.
- 직접 Dart 분석 `lib test integration_test tool/visual_preview.dart tool/orb_motion_review.dart tool/ux_baseline_capture_test.dart`: No issues found.
- `flutter test --no-pub --reporter expanded`: **221개 통과**. 기존 golden 비교, 키보드/입력 정적/모션과 reduced-motion 검사 포함. 기준 이미지를 새로 갱신하지 않았다.
- 실제 remote/auth 웹 release `build/live-trial`: 최초46초 후 아래 누락을 발견해 **웹 단독52.1초 재빌드**했다. iOS simulator 무서명 build 통과(12.2초). 네이티브 통합 시나리오는 재실행하지 않았다.
- privacy/log guards와 diff 공백 검사 통과. frozen 네 파일은 edfc13c 대비 diff 없음.
- 프로젝트 확인 → `--prod --skip-domain` 준비 배포 → READY·필수 리소스 확인 → 같은 production 배포 `vercel promote` 성공 → 공개 주소 검증. 첫 배포의 누락을 발견해 아래와 같이 수정했으며 최종 ID는 위와 같다.
- `main.dart.js`: 3,672,452 bytes, SHA-256 `4a1f1cf394d18e7a45622303f1b673b0efb4f939aedf2656950b4b496d5b74d1`. 준비/공개 HTTP 응답 모두 로컬 파일과 동일하다.
- 최종 공개 주소에서 HTML/JS/bootstrap/service-worker/manifest/favicon/192·512 앱 아이콘/sqlite wasm/Drift worker/FontManifest/모든6폰트 **17개 파일이 비인증 HTTP200이고 로컬 해시와 일치**한다. 준비 배포에서도 FontManifest4 family/SQLite748,686 bytes를 인증 HTTP로 확인했다.
- 공개 앱 브라우저 390×844와 넓은 기본 폭에서 최신 소개→실제 Groq 고지·체크 비활성 상태를 확인했다. [소개](2026-10-22-onboarding.jpg), [실제 고지와 복구된 복사 아이콘](2026-10-22-consent.jpg). 체크/동의 제출은 하지 않았다.
- 복구 후 최종 새로고침 시점 이후 브라우저 error/warn은0건. Vercel 최종 배포 error 로그 조회는 ‘No logs found’였으며 정적 호스팅 로그가 없다는 뜻이지 Supabase/AI 오류까지 없다는 뜻은 아니다. 서버 로그 drain/장기 모니터링은 이번에 조회·설정하지 않았다.

### 배포 중 발견·수정한 누락

첫 배포 `dpl_8jNdT2vb8TRmnK4memgXgQaD1TMC`는 JS 해시와 READY만 통과했지만 브라우저에서 FontManifest 경고와 빠진 아이콘을 발견했다. 로컬 bundle에도 FontManifest/폰트/manifest/SQLite 등 리소스가 없었다. 웹·iOS 동시 빌드의 공유 중간 산출물 간섭을 의심했고, **웹만 순차 재빌드한 뒤 모두 복구**됐다. SDK 내부 원인을 확정한 것은 아니다. 첫 배포는 최종 결과가 아니며 공개 alias를 복구된 배포로 교체했다.

`tool/deploy_live_trial.sh`에 필수14개 리소스가 없거나 비어 있으면 게시 전에 중단하는 guard를 추가했다. `bash -n`, 불완전 디렉터리 거절, 완전한 재빌드 디렉터리 통과를 각각 실행했다. 폰트 manifest의4 family/6파일도 모두 존재한다. 이 수정은 배포 검사만 바꾸며 앱/엔진/DB 동작은 바꾸지 않는다. 앞으로 웹/iOS release 빌드는 순차 실행한다.

## 실패·미검증

`flutter analyze --no-pub`는 기존 한국어 경로 LSP JSON 파싱 오류로 exit255. 직접 분석 통과와 구분한다. Flutter/CLI 버전 업그레이드는 하지 않았다.

물리 iPhone/PWA 상태바·키보드·STT·터치 지연/frame timing, 이번 배포에서 새 계정·동의 제출 이후 실제 AI 생성/소설 충실도/모든 실패 복구, 다중 클라이언트/RLS 재검증은 미검증이다. 사용자 대신 동의를 제출하거나 기존 기록·세션을 지우지 않았다. 기존 브라우저/설치 PWA의 세션은 유지하며 온보딩 강제 재설정도 하지 않았다.

운영 AI 검증을 하지 않았으므로 ‘입력부터 실제 소설까지 새 배포에서 검증 완료’라고 표현하지 않는다. P4 잔여·완결/PDF/푸시·Q 실측은 기존 상태 문서대로 남아 있다.

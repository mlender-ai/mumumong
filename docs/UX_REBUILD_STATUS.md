# 무무몽 UX 재정비 실행 상태

최신 검증일: 2026-10-26 (KST). **시작 화면 단순화/Thinking Orb 통일 배포**는 build20261026T111252Z,READY이며 [최신 화면·검증·배포 기록](ux-review/2026-10-26-start-flow/README.md)을 따른다. 같은 날 설치 origin/브라우저 막대 및 초기 실행/저장 실패 보정과 이전10/25 입력/지속성 수정 및10/23 P4-3/비LLM P5/P6 범위와 SQL0001–0020/worker 배포는 유지한다. 아래 과거 항목의 ‘미착수/미배포’와 테스트 수는 당시 기록이며 물리기기/전체 제품 검증 보증이 아니다.

## 현재 페이즈 — P4 진행 중

### 10/26 시작 흐름 단순화 / 하나의 Thinking Orb

사용자가 설치 문제는 더 이상 나타나지 않는다고 보고했으며 설치 origin은 기억하지 못한다고 답했다. 소개/설정의 설치 안내를 제거하고 기존 install 링크는 같은 origin의 첫 화면으로만 연결한다. 계정/manifest/기록은 그대로다. 동의는 핵심 한 문장·필수 확인2개·펼치는 전체 고지로 정리하고 ‘동의 기록’ 내부 용어를 바꿨다. 첫 원고 설정도 제목/설명/시작과 선택 설정으로 묶었다. 원본 Libraries.dev의 ‘Thinking…’가 `composing`임을 직접 대조해 생산 Orb를 하나로 고정했다. 연결망/희박한 궤도로의 교체를 없애고, 실제 상태/입력 정적/동작 줄이기를 유지한다.

314개 VM/6개 Chrome 입력/실제IndexedDB1개/설치JS6개/초기화JS5개, 직접 분석/format/web/iOS simulator build 통과. 표준 Flutter 분석기 exit255는 남는다. 보호된 production-stage24리소스와 공개24리소스 해시 일치 후 같은 배포를 승격했다. 공개 소개→동의 화면까지만 확인했으며 제출/계정 생성·소설 생성은 하지 않았다. 물리기기/녹음/실제 품질·P4 잔여는 완료로 바꾸지 않는다. [상세 증거](ux-review/2026-10-26-start-flow/README.md).

### 10/26 설치 PWA의 브라우저 막대 — 후속 조사

Apple 공식 scope/설치 자료와 실제 구주소 응답에서 mobile-preview HTML·worker의 다른 도메인 강제 이동을 확인해 제거했다. 구주소는 설명/명시적 설치 안내, 정식 origin은 실제 browser/standalone 상태를 확인하는 `install.html`을 제공한다. manifest id/start/scope와 계정·기록은 유지한다. 정식24리소스/구주소2파일 stage→promote→공개 해시 일치,309개 Flutter 및 설치6/초기화5/Chrome6/IndexedDB1 통과. Flutter analyzer exit255는 남는다. 사용자 설치 origin은 확인 중이며 실제 iPhone 새 아이콘 실행은 미검증이다. 서버 배포로 기존 아이콘을 재바인딩하거나 기록을 자동 이전했다고 보고하지 않는다. [조사·수정·검증](ux-review/2026-10-26-pwa-install/README.md).

### 10/26 PWA 로컬 QA / 실패 복구

사용자 요청으로 Apple 계정·TestFlight 준비는 이번 범위에서 제외했다. 공개 동의/계정 생성 없이 로컬 QA만 수행했다. bootstrap503에서 흰 화면, 자동 저장 실패의 무안내를 재현하고 수동 재시도/정적 저장 실패 안내를 추가했다. CanvasKit을 같은 배포에서 로드하고 실제 첫 프레임에서만 HTML 시작 레이어를 제거한다. 입력/포커스·기록·동의·스키마·Q는 유지한다.309개 VM,6개 Chrome 입력,실제IndexedDB1개,JS초기화5개 및 iOS simulator 빌드 통과. Flutter 분석기의 기존 exit255는 남는다. 공개23파일 해시/390×844 소개만 확인했으며 실제 iPhone 설치 PWA, 키보드/터치 성능, 공개 인증 후 생성·오프라인 cold-start는 미검증이다. [재현/수정/증거/배포 경계](ux-review/2026-10-26-pwa-qa/README.md). P4/P6 전체 완료로 표시하지 않는다.

### 10/25 입력 불능 신고 / 배포 기준 강화

공개 웹의 키보드 출현→사라짐을 사용자 영상과 Chrome 회귀로 확인했다. 조건부 안내 행 제거 때 재생성되던 editor를 고정키/FocusNode로 보존한다. 기존 inset 스냅샷과 소개/설치 안내만의 브라우저 검수로는 이 문제를 잡지 못했다. 실제 웹 조작에서 저장 후 새로고침 유실도 발견해 Drift2.35.2/동일 버전 Worker로 수정했다. 초안 실패/timeout 복구, controller 기반 자동 저장, 입력 repaint 분리, 숨은 홈 모션 정지와 음성 세션/직접 편집 보호를 추가했다.308개 VM/5개 Chrome 입력/1개 실제 IndexedDB commit 검사를 통과했으며 실제 iPhone/녹음 성공으로 세지 않는다. [검증 기록](ux-review/2026-10-25-input-qa/README.md)과 [필수 QA 기준](QA_RELEASE_GATE.md)을 따른다. 아래10/23 검증은 역사적 기록이며 전체 사용성 보증이 아니다.

### 사용자 모바일 지적 후 보정 / iPhone 앱 준비

2026-10-23: Vercel 웹 체험을 네이티브 배포와 구분했다. 사용자 선택은 ‘기획서대로 iPhone 앱 준비’. 녹음 경로를 서버 STT로 바꾸지 않았다. native 마이크/정지 아이콘, 음성 불가→텍스트 전환 때 키보드 저장 버튼을 덮던 안내 수정, 배경30Hz repaint 알림/백그라운드 정지, 미사용RMS 제거 및 PDF 전용 Bold의 초기 다운로드3.35MB 분리를 적용했다. 현재 앱 초깃값·글래스 재질은 유지한다.299개 Flutter와 신규 native simulator1개/ARM64 무서명 archive/시뮬레이터 release 빌드 통과. 물리 FPS/STT10회/서명·TestFlight 설치는 미검증이다. 서명 인증서0개/개발팀 미설정으로 TestFlight는 미배포다. [준비·서명 단계](IOS_TESTFLIGHT_PREPARATION.md).

| 페이즈 | 현재 상태 |
|---|---|
| P0 기준선 | 감사·실행 상태 기록됨 |
| P1 Reader/복원 | 구현·로컬/시뮬레이터 검증, 원격·실기기 경계 남음 |
| P2 연속 화면/모션 | 구현·로컬 검증, 실기기 성능 미검증 |
| P3 공통 UX | 구현·로컬 검증, 사용자5명/hosted 전체 검수 미실행 |
| P4 생성 복귀/설정/운영 | 결과 소비·설정 버전·정기 worker 복구 구현. hosted CAS/멱등/충돌·cron 실행 검증. OS push·오프라인 cold-start·완전한 retry-intent 복원 남음 |
| P5 완결/완성본/PDF | 비LLM 제목/작가의 말→현재 문장 고정→PDF→다음 권 구현. 로컬·hosted RPC/RLS/동시 요청·simulator 검증. LLM 편집은 Q-32 이후, 물리 공유/독립 첫 작품 경험 남음 |
| P6 관측/최종 검수 | release.json·정적 파일 guard·안전한 운영 집계 구현. 사용자5명/물리 성능/실제 문학 품질·재방문 검수 남음 |

### 이번 묶음의 증거와 중단선

Flutter292개, Deno148개, 격리 SQL225개, 별도 완료 UI/PDF5개, 신규 iOS simulator1개 통과. 17쪽 합성 PDF의 모든 페이지를 렌더링했고 표지/차례/본문/공백/작가의 말/출처 부록을 확인했다. 긴 제목/장면30개 차례 회귀도 통과했다. hosted business-conflict의40001 자동 재시도 문제를0020 PT409 전진 migration으로 수정하고 실제409/동시 요청/소유권을 재검증했다. 앱에서 깨우지 않은 실제 AI2건은 cron으로 처리됐으나 **최종 V2/V5 검증 실패**로 끝났다. 성공한 결과·품질 판정으로 세지 않는다. 동결 규칙/DB 원고 직접 교정 없음. [상세 계약·검증·실패](ux-review/2026-10-23-release/README.md).

### P4-2 이후 장면 설정 — 2026-10-23

설정→이후 장면 설정에서 기존 각색·문체·시점 enum을 바꿀 수 있다. 기존 원고/U는 다시 쓰지 않는다. 원격 사용에서는 서버 확인값과 Outbox 대기값을 분리한다. 대기/충돌 중에는 새 생성만 막고 꿈 기록/원고 읽기를 유지한다. 충돌 시 서버 설정 사용 또는 이 기기의 선택 재적용을 명시적으로 고른다. 저장 실패는 선택을 유지하고, 응답 유실/재시도는 같은 mutation ID를 사용한다.

Drift v3→v4가 설정 버전/대기 변경을 추가한다. 생성 의도 시점의 확인 버전을 로컬 작업에 고정하고, 서버 SQL0017은 소유권/CAS/멱등 RPC, 버전 이력/RLS 및 작업 스냅샷을 제공한다. plan/write 진입점만 고정된 세 설정을 전달하고 동결 프롬프트/opening은 그대로다. 이후 설정 변경은 이미 시작한 생성/같은 꿈의 재시도에 섞이지 않는다. 공개 서버에는 아직 반영하지 않았다.

Flutter **286개**, Deno 엔진 **147개**, 격리 PostgreSQL **202개 항목**(업그레이드5+기존/신규197, cron1 제외), iOS 시뮬레이터 **1개 신규 시나리오** 통과. 직접 분석/format, 14화면 비교, unsigned iOS/일반·미리보기 web 빌드와 각각14리소스 guard 통과. 브라우저의 가상 온보딩→설정 저장 v2를 확인했다. root Flutter 분석은 기존 LSP exit255. 실제 hosted Auth/PostgREST·AI 호출·다중 기기/PWA·운영 스케줄/물리기기는 미검증이다. [계약·검증·배포 순서·화면](ux-review/2026-10-23-p4-settings/README.md).

다음 구현은 P4-3 worker 복구/지원 플랫폼 알림이다. P4 전체, P5/P6 완료로 표시하지 않는다.

### P4-1 결과/성장 소비 상태 — 2026-10-23

연출 예약을 읽음/완독과 분리해 Memory/Drift에 추가했다. schema2→3은 로컬 UI 영수증만 추가하고 과거 성장 이벤트를 backfill한다. 새 리빌과 성장 이벤트를 한번 처리하면 재진입/재마운트에서 반복하지 않는다. 읽기는 여전히 Reader의 실제 열람 마커를 사용한다. 숨은 탭/덮인 화면/background에서 예약하지 않으며, 영수증 저장 실패도 실제 원고 접근을 막거나 재생성하지 않는다. 계정 변경/전체 삭제 때 함께 정리한다.

Flutter **260개 및 관련 iOS 시뮬레이터2개 통과**, 직접 분석/format 및 기존14화면 비교 통과. SQLite migration/재열기·원고/U/초안/Outbox/읽기 위치 보존, 중복 예약·오류/가시성/foreground 복귀를 검사했다. root Flutter 분석은 기존 LSP exit255다. [P4-1 후속 계약·실행 증거·한계](ux-review/2026-10-23-p4-consumption/README.md). P4 전체 완료가 아니며 다음 구현 항목은 P4-2다.

## 여백·행동 위계 보정 — 2026-10-23

### 탐색 화면 후속

홈 주 행동280px/보조 행동 묶음, 중복 이어 읽기 제거, 실제 대기 상태만 표시를 적용했다. 기록을 저장한 뒤 ‘첫 꿈을 기다리고 있어요’로 남던 제목을 실제 보관 상태에 맞췄다. 보관함/설정 헤더를24px·8px·32px로 공유하고 설정 설명 대비를 높였다. 보관함은 제목/필터/목록을 함께 스크롤하며 큰 글자 날짜/상태가 깨지지 않게 했다. 실제 GNB inset과 끝32px 여백을 사용한다. 빈 상태/오류 재시도도 주 행동280px/간격32px를 공유한다.

Flutter250개(신규12) 및 직접 분석/format 통과, root Flutter 분석은 기존 LSP exit255다. [탐색 화면·최종 검증 기록](ux-review/2026-10-23-shell/README.md). 공개 반영/실제 AI/물리기기 성능을 검증한 것이 아니며 P4·P5 진행 상태는 바꾸지 않는다.

- 저장/결과의 강제 양끝 정렬을 제거해 설명과 행동을 32px 간격으로 묶었다. 소개/설정/저장/결과/첫 읽기 끝의 주 행동을 최대280px로 통일하고 보조 행동은 15px/400·낮은 위계·Wrap으로 공유한다. 메타/제목/설명의 위계를 분리하고 읽기 끝 설명을 secondary ink로 올렸다.
- 큰 진입 그라디언트/홈 표지/유리 재질은 유지한다. 입력/STT에 효과를 추가하지 않았고 생성/저장/출처/읽기 복귀의 실제 동작도 그대로다.
- Flutter **238개 통과**, 직접 Dart 분석/format 통과. root Flutter 분석은 기존 LSP JSON crash(exit255)로 실패했다. 고정 간격/버튼 폭 3크기와 작은 화면 긴 내용의 스크롤·실제 탭 검사를 추가했다.
- [v0.9 규격](MUMUMONG_DESIGN_SYSTEM_v0.9.md), [전후 화면과 검증 경계](ux-review/2026-10-23-spacing/README.md). 공개 재배포·계정/AI 실호출·물리기기 성능 검증은 하지 않았다. 기존 P4 잔여를 완료 처리하지 않는다.

## 첫 꿈 경험 첫 단위 — 2026-10-23

- 저장 후 ‘떠오른 만큼 남겼다면 충분해요’라는 정적 안내를 제공하고, 생성하지 않고 보관하는 선택을 유지한다. AI 공감/꿈 해석을 만든 것이 아니다.
- 해당 권에 실제 로컬 반영된 장면이 하나일 때만 첫 결과 안내를 사용하고 리빌의 +%를 숨긴다. 증가 이벤트/홈 진척 계산은 그대로다. 원문 보관과 먼저 읽기에 초점을 둔다. 원문/생성 본문을 수정하지 않는다.
- 첫 장면 Reader의 끝에 ‘꿈 원문 다시 보기’와 주 행동 ‘읽기 마치기’를 추가했다. 기존 출처 시트에서 실제 저장한 원문을 읽는다. 닫기는 원래 화면으로 복귀하며 생성·완결·PDF 저장 상태를 만들지 않는다. 여러 장면/빈 Reader에는 첫 장면 안내가 없다.
- 작은 화면1.6배 글자에서 홈 행동이 GNB에 가려지는 것을 발견해 실제 inset을 스크롤 viewport에 반영했다. 기존 큰 표지 높이는 유지한다.
- Flutter234개(13개 추가) 통과. 합성 Memory/mock으로 기록만 저장(생성0회), 첫 결과→원문→복귀→둘째 기록/명시적 생성, 본문/출처/잠금 불변과 여러 장면 회귀를 검증했다. 밝게/어둡게×4크기+작은 화면 큰 글자로 새20개 첫 결과/읽기 끝 golden과 변경된 저장10개를 비교했다. [실행 증거](ux-review/2026-10-22-first-dream/README.md).
- AI 감정 피드백, 정보량에 맞춘 첫 작품 길이, 독립 작품/연속 창작 선택·완결, hosted 품질/재방문 행동 검수는 미완료다. Q 동결·D/C/U·U 잠금을 유지한다. 이번 단위를 ‘첫 꿈 경험 전체 완성’으로 보고하지 않는다.

## 디자인 공개 배포 — 2026-10-22

사용자 요청으로 실제 remote/auth 앱을 기존 공개 주소에 반영했다. 검토용 가상 동의/고정 결과/9상태 Orb 리뷰는 로컬에만 남긴다. 최종 production `dpl_GN1bS7Ru9WNuwyrm1vJCCB5UHytL` READY, 공개 주소 비로그인 HTTP200. 사용자 데이터·세션은 초기화하지 않았다. 221개 테스트·format·직접 분석·웹/iOS simulator build 통과, Flutter 분석기의 기존 exit255는 남는다.

첫 배포에서 브라우저가 폰트/아이콘 누락을 드러냈다. 웹을 단독 재빌드해 복구했고 게시 전 필수 리소스 guard를 추가했다. 최종17개 HTTP 리소스는 모두200·로컬 해시 일치. 공개 모바일 소개→실제 고지만 조작했고 동의/계정/AI 생성은 제출하지 않았다. 전체 hosted AI 흐름·실기기·성능·P4 잔여는 미검증/미완료 그대로다. [배포·실패·복구 기록](releases/2026-10-22-design-deployment.md).

## 디자인 재대조 — 2026-10-19

- 첨부 이미지 7장, GitHub ElevenLabs/Stripe 커뮤니티 DESIGN.md, Libraries.dev의 9개 Orb 상태를 읽고 대조했다. 전면 확산 빛을 비대칭 상부 블루/라일락 초점으로, 소개/홈의 작은 벡터 원고 오브젝트와 중립 유리 행동으로 정리했다. 입력/STT에는 모션을 추가하지 않았다.
- 검토용 경로만 소개→가상 개별 동의→실제 첫 원고 설정 UI→빈 홈으로 시작한다. 무의미한 42%/이어 읽기를 제거했다. 소개/설정에서 9개 native64px Orb, 속도/정지/야간을 직접 확인할 수 있다. 상단 고정이라 컨트롤을 스크롤해도 사라지지 않는다. 설정에서 온보딩을 처음부터 다시 볼 수 있다.
- Flutter **221개**, format/직접 Dart 분석, 일반/미리보기 web release, iOS simulator 무서명 build 통과. 102개 새 golden과 별도 14화면 캡처, 390×844 브라우저 조작과 실제 Orb 프레임 녹화. `flutter analyze --no-pub`는 기존 한국어 경로 LSP JSON crash(exit255)로 실패했다. 네이티브 통합 테스트는 이번에 재실행하지 않았다(아래 7+1은 10/18 기록).
- 리뷰는 Memory/mock이며 합성 정책/고정 결과임을 표시하고 outbox worker를 비활성화한다. 실제 계정/AI/DB를 바꾸지 않는다. 공개 배포·Q/LLM/서버 SQL 변경 없음. 물리기기·PWA·hosted/RLS·실제 소설 품질/성능은 미검증이다.
- [디자인 시스템 v0.8](MUMUMONG_DESIGN_SYSTEM_v0.8.md), [화면·검증·재현](ux-review/2026-10-19-design/README.md). 후속 기능은 기존 P4 잔여이며 이번 시각 수정으로 완료 처리하지 않는다.

## P4 첫 단위 — 2026-10-18

### 달라진 동작

- 인증·동의를 통과한 shell이 `generationRecoveryProvider`를 수동 구독한다. 화면 위에 Reader/설정이 떠서 TickerMode가 멈춰도 구독을 유지하고, shell이 해제되면 취소한다. 처리 중 꿈을 저장소에서 찾고 같은 꿈의 job stream 하나를 공유한다. 구독 복원 자체는 enqueue/retry를 하지 않는다.
- 생성 화면에 ‘나중에 확인하기’를 추가했다. 보관함의 처리/실패 꿈은 같은 CaptureFlow로 돌아가며, 복귀만으로 생성 요청을 보내지 않는다. 실패/단계 메타데이터는 Memory/Drift에 보존한다. 중복 시작은 보강 답변을 바꾸지 않으며 완료된 꿈을 processing으로 되돌리지 않는다.
- stream·결과 다운로드 오류는 ‘연결을 확인하고 있어요’와 ‘상태 다시 확인’으로 분리했다. 이것은 관찰/다운로드만 재시작한다. 최초 접수 응답이 불명확할 때만 같은 키의 ‘접수 다시 확인’을 제공한다. 실제 terminal 실패에서만 ‘다시 시도’를 제공한다.
- 원격 retry는 모든 단계의 active job과 성공 commit을 먼저 확인한다. 새 재시도 키는 실제 failed job ID에서 UUID v5로 결정해 앱/클라이언트 재시작에도 동일하다. commit 뒤 remember가 실패해도 완성된 장면을 재생성하지 않는다. 완료는 다운로드가 성공한 뒤에만 전달하며 성공 다운로드를 poll마다 반복하지 않는다. 실패한 다운로드는 다음 동일 job 갱신에서 복구할 수 있다. polling 중복 HTTP와 취소 후 늦은 응답도 막았다.
- 결과 반영은 아직 전달되지 않은 문단 edit/revert, 다운로드 시작 시 pending이었으나 도중에 ACK된 편집, 다운로드 도중 새로 생긴 편집을 보존한다. 오래된 생성 스냅샷이 더 최신인 잠긴 U를 덮지 않게 했다. 첫 열람 마커는 단조롭게 병합해 null로 되돌리지 않는다. 다운로드 중 계정이 바뀌면 다른 소유자의 bundle을 반영하지 않는다. 원고를 직접 교정한 것이 아니라 기존 동기화 경계의 충돌 보호다.

### 실제 검증

- 전체 Flutter **217개 통과**(P3 206 + 11). 21초 대기→나가기→복귀, shared stream 단일 구독, 오류 후 상태 재확인 시 enqueue/retry 0회, 실제 실패만 재시도, 새 provider container 재구독을 검증했다. 재시도 ACK 전에 화면을 닫아도 접수 뒤 processing과 shell 구독이 이어지는 경우도 포함한다. 실패 이후 실제 queued/running은 다시 복구 대상으로 편입한다.
- 실제 임시 SQLite 파일을 닫고 재열어 processing 상태에서 관찰만 복원한 뒤 terminal 실패 메타데이터를 저장·다시 열었다. Outbox는 최초 create/process 두 건 그대로이며 재진입 요청을 추가하지 않았다. Memory/Drift 공통 계약은 중복 시작/완료 상태 보호와 실제 실패 저장을 확인했다.
- fake remote gateway로 접수 idempotency/충돌, terminal-only retry, 다른 클라이언트의 동일 retry 키, commit→remember 실패, 다운로드 오류→동일 commit 재다운로드, 다운로드 전 완료 미노출을 확인했다. **hosted/RLS 검증이 아니다.**
- CloudSync+실제 임시 SQLite fixture에서 U 편집이 HTTP 도중 ACK되어도 U/잠금/본문이 보존됨, revert 보존, 읽음 마커 유지를 확인했다. 서버 RPC/RLS와 스키마는 바꾸지 않았다.
- processing golden을 새 P4 디렉터리에 10개 생성·재비교했다(day/night × 4크기와 작은 화면 1.6배). 나머지 90개 기존 golden 비교도 통과했다. P3 PNG 전체의 SHA-256 집계가 전후 동일해 이전 시각 증거를 바꾸지 않았다. 별도 14화면 도구도 P4 경로에 생성·재비교했다.
- 일반/미리보기 web release 통과. localhost 390×844에서 가상 기록→생성→‘나중에 확인하기’→홈 진척/새 결과→해당 12번 장면 Reader를 조작했고 error/warn 로그는 없었다. 둘째 가상 꿈은 캡처 전에 완료돼 리빌 화면으로 넘어갔으므로 그 사진은 처리 화면의 증거로 쓰지 않는다. HTTP 서버는 정적 파일이며 계정·API·LLM 검증이 아니다.
- iPhone 17 Pro / iOS 26.5 시뮬레이터: 기존 **7개 + 신규 1개 각각 통과**. 신규는 21초 실제 대기→생성 화면 이탈→route 밖 mock 완료→SQLite 파일 재열기→해당 장면 Reader/열람 마커/장면 1개 유지다. 최초 시도에서는 테스트가 초기 DB/홈 비동기 로드를 기다리지 않아 실패했고, 명시적 대기를 넣은 재실행은 35초에 통과했다. iOS simulator 무서명 build도 통과했다. 실제 서버나 물리기기의 강제 종료 검증은 아니다.
- format 및 직접 Dart 분석 통과. root `flutter analyze --no-pub`는 기존 한국어 경로 LSP JSON crash(exit 255)로 실패했다. privacy/log guards·diff 공백 검사 통과, frozen 네 파일은 edfc13c 대비 diff 없음.

### 남은 범위·미검증

- P4-1의 영속적인 리빌/성장/알림 소비 영수증, 재시도 접수 대기의 완전한 Outbox 복원 및 오프라인 콜드스타트 인증·동의/bootstrap 검수는 남아 있다. 이번 재진입 테스트를 실제 서버의 앱 강제 종료→재시작 성공으로 확대 해석하지 않는다.
- 이번 충돌 보호는 문단 편집/되돌리기/열람에 한정된다. 꿈 원문·배치·연결 선택의 동시 동기화 충돌 및 큰 글자에서 연결 오류 안내 전체의 접근성 검수도 후속 범위다.
- **다음: P4-2 각색·문체·시점의 이후 생성분 설정 변경**, 설정 버전/Outbox/RPC/RLS 충돌 계약. 그다음 P4-3 정기 worker 복구와 지원 플랫폼 알림. STATUS상 durable cron은 여전히 미완이며 이번에는 worker/운영 스케줄을 변경하거나 조회하지 않았다. OS push도 없으며 완료 알림을 약속하지 않는다.
- 물리 iPhone/PWA·STT·프레임/터치 지연, hosted 계정·AI·RLS·동시 클라이언트·실제 강제 종료 복구, 사용자 5명 검수는 미검증이다. Q 실측 자료/키/레퍼런스는 미준비 상태 그대로이며 평가 데이터를 열지 않았다.
- 공개 Vercel 재배포·commit·push 없음. 엔진/프롬프트/모델/Q 기준선/SQL migration은 그대로, Drift 스키마 v2 유지. [P4 증거와 재현](ux-review/2026-10-18-p4/README.md).

## P3 결과 — 2026-10-18

### 구현한 흐름

- 소개에는 가상 꿈/문장 예시가 있되 실제 AI 결과가 아님을 명시한다. 현재 정책의 제공사 URL을 열고, 실패 시 주소 복사와 피드백을 제공한다. 연령/AI 개별 체크와 실제 동의 gate는 유지했다. 웹 체험의 브라우저 종속성/복구 한계 안내도 유지한다.
- 첫 원고는 balanced/plain/first-person-past로 바로 시작한다. 상세 설정은 선택적으로 펼치고 실제 선택값을 요약한다. 실패/재시도에도 선택을 유지하며 기존 cloud createVolume을 호출한다. 이번 UI 검증에서는 fake gateway이며 hosted 생성 재검증이 아니다.
- 저장 성공 뒤 주 행동 ‘장면 만들기’, 보조 ‘기억 더 보강하기/나중에 만들기’로 분리했다. 고정 3문항은 열었을 때만 보인다. 보강 완료/건너뛰기는 생성하지 않고 저장 단계로 돌아온다. queued 꿈은 보관함에서 같은 ID로 다시 시작한다.
- `saveRecallAnswers` 계약을 Memory/Drift에 추가했다. queued 상태의 답변만 저장하고, 처리 중의 변경은 거절한다. Drift는 저자 입력과 safe-upsert create 전달을 같은 transaction에 저장한다. 최초 create가 이미 전달됐어도 새 interaction ID로 보강을 전송한다. **process_dream은 명시적 생성 시작 때만** 기존 경로에서 추가한다. 새 LLM/엔진 규칙/서버 SQL은 없다.
- 홈의 주 행동은 로컬 본문과 첫 문단 열람 마커에 따라 새 장면 읽기/꿈 기록하기로 전환한다. Reader가 장면을 열면 기존 메타데이터 API로 첫 문단 마커를 기록한다. 완독 추적이 아니다. 저장/처리/실패 요약에서 보관함으로 이동할 수 있다.
- 설정은 화면과 읽기/데이터/보안/사용 안내의 허브→상세 구조다. JSON 데이터 사본과 완성본 PDF 영역을 구분한다(PDF UI는 여전히 P5). 테마·원고 글자 크기·출처 표시를 기기에 저장하고 실패 시 이전 값을 유지한다.
- UI 의미 색 역할, 최대 내용 폭, 480px 모달·시트, 선택·비활성/오류 상태를 공유한다. 앱 전체 밝게/어둡게/기기 설정을 연결했고 Reader의 밤 종이도 유지한다. Reader 설정에서 돌아올 때 테마가 오래된 진입값에 고정되지 않게 했다.
- 문단마다 출처/수정/원래 문장 메뉴가 있다. 편집과 꿈 원문 수정은 저장 중 중복 동작을 막고 실패 후 입력을 보존한다. U 잠금/출처 복원은 기존 Repository 동작이다. 페이드 중인 이전 단계 컨트롤은 터치/접근성 탐색에서 제외했다. 타이핑/STT에는 연출을 추가하지 않았다.

### 이번 실제 검증

- Flutter 전체 **206개 통과**. P2 183개보다 23개 증가. 100개 day/night golden(4크기+작은 화면 1.6배 글자, 흐름 5상태+공통 화면 5종) 재비교와 기존 keyboard/모션/동작 줄이기 검사를 포함한다. 별도 도구의 14개 캡처도 생성·재비교했다. 대표 밝은/야간/큰 글자/넓은 Reader를 육안 확인했다.
- Memory/Drift 계약과 임시 SQLite+Outbox: 저장만 한 꿈/보강은 재열기 후 queued, create 전달만 발생, 명시적 시작 뒤에만 process 전달. UI에서 보강→나중에→보관함→같은 ID 생성까지 확인했다.
- 기본/상세 원고 설정 payload와 실패 재시도, 실제 URL 전달/열기 실패→복사 피드백, 홈 주 행동 전환, 보이는 문단 메뉴의 편집 실패/입력 유지/재시도/복원, Reader에서 표시 설정 변경 후 복귀를 검증했다.
- iPhone 17 Pro / iOS 26.5 시뮬레이터 **7개 통합 시나리오 통과**: 새 SQLite 저장·보강 재열기→명시적 mock 생성, 네이티브 preference 채널 write/reload/새 controller, 기존 capture success/retry/fallback/fail, Reader SQLite 재열기/큰 글자 앵커. 물리기기나 hosted 검증이 아니다.
- localhost in-app browser 390×844: 앱 야간/원고 1.4배 선택→새로고침 복원, 기록→저장만 하고 나감→보관함→생성 시작→Orb→결과→같은 장면 Reader/문단 메뉴를 직접 조작했다. error/warn 로그 없음. 이 경로는 Memory/mock과 표시 설정 browser storage이며 서버 API/계정/LLM 요청은 없다.
- 일반 및 visual-preview web release, iOS simulator 무서명 build 통과. iOS build는 한 차례 integration build와 동시 실행해 Flutter.framework rsync 충돌이 있었고, 단독 재실행에서 14.8초에 통과했다. `flutter analyze --no-pub`는 기존 한국어 경로 LSP JSON crash(exit 255)로 실패했다. 직접 Dart 분석은 **No issues found**, format 107파일 변경 없음, privacy/log guards·diff 공백 검사 통과, frozen 네 파일을 edfc13c와 비교해 diff 없음.

[화면·동작·재현 기록](ux-review/2026-10-18-p3/README.md), [현재 디자인 시스템 v0.7](MUMUMONG_DESIGN_SYSTEM_v0.7.md). P2의 미적용/야간 후보 설명은 당시 기록이며 최신 범위는 이 P3 결과를 따른다.

### 미검증·다음 범위

- 실제 hosted 계정/동의/AI/RLS 전체 흐름, 사용자의 꿈 충실도/문학적 품질, 물리 iPhone/PWA 시스템 영역·키보드·STT·터치 지연/frame timing, 사용자 5명 사용성 실험은 미검증이다. 웹 시작 HTML/브라우저 크롬의 야간 시작 white flash도 남아 있다. 로컬 저장 검증을 운영 검증으로 보고하지 않는다.
- 기존 오프라인 콜드스타트 인증/동의/bootstrap gate는 우회하지 않았다. 비동기 생성 떠나기/복귀·stream 오류 구분·재시도/중복 방지·세밀한 결과 소비/알림은 P4, 이후 생성에 적용할 설정 변경도 P4다. 완결/PDF UI는 P5다.
- 생성 엔진·모델·Q 동결 파일·SQL/migration·실제 원고 DB는 바꾸지 않았다. 로컬 스키마도 v2 그대로다. 기존 transitive shared_preferences 2.5.5/url_launcher 6.3.2를 동일 버전 직접 의존성으로 선언했으며 새 버전을 올리지 않았다.
- 공개 Vercel **재배포 없음**. `http://127.0.0.1:4203/`는 가상 디자인 미리보기다. 커밋/원격 push도 하지 않았다.

## P2 결과 — 2026-10-15

### 달라진 화면과 모션

- 소개/홈: 큰 진입 화면·표지를 유지하면서 상부 블루·라일락 초점이 깨끗한 흰색으로 사라지는 `DreamAtmosphere`를 공유한다. 14초 반복은 painter/RepaintBoundary만 갱신하고 전면 blur filter/부모 frame rebuild는 하지 않는다.
- 기록: 약한 정적 분위기, UI 산세리프 필드와 ‘꿈 저장하기’ 행동. 키보드가 열리면 배경 빛을 숨긴다. 타이핑/STT 동안 Orb·beam·픽셀·오디오 레벨 연출은 없다.
- 실제 Repository 저장 성공 뒤 작은 32px 픽셀 스탬프가 650ms 한 번 모인다. 사용자 승인된 vNext의 제한된 픽셀 위치는 이곳 하나다.
- 처리: native 64px published Thinking Orb와 ‘소설을 만들고 있어요’만 중심에 둔다. 실제 job stage에 따라 working/connecting/composing/solving이 바뀐다. 큰 카드·카운터·타이머 완료 없음.
- 결과: 로컬 동기화 결과의 제목·첫 문단(최대 5줄)·실제 증가량, 한 주 행동 ‘새 장면 읽기’. 정확한 sceneId Reader 연결을 유지한다. 연결/배치는 보조 조정 시트로 옮겼으며 실제 Repository mutation을 유지한다.
- 공통 유리 행동: 중립 반투명 면/얇은 경계/한 겹 그림자, 푸른 광채 제거. 52px은 고정 높이가 아닌 최소 높이라 큰 글자가 늘어도 접근 가능. 눌림 scale .975/120ms. phase 전환 360ms, 동작 줄이기에서는 반복/긴 전환 생략.
- 같은 구조의 야간 ThemeData 후보를 네 화면에 적용·검증했다. **전역 theme 토글·영속 설정·밤 system bar는 구현한 것이 아니다**. P3에서 전체 적용한다.

공통 숫자/색/컴포넌트/모션 계약은 [디자인 방향의 P2 실행 규격](DESIGN_DIRECTION_vNext.md#p2-실행-규격--2026-10-15), 전후 화면은 [P2 리뷰](ux-review/2026-10-15-p2/README.md)를 따른다.

### 실제 검증

- 최종 Flutter 테스트 **183개** 통과(P1 169 + P2 14). 40개 day/night golden: 375×667, 390×844, 430×932, 1200×800 및 375×667 글자 1.6배의 네 화면. 추가 day/night 375×667 keyboard inset 290px/글자 1.5배에서 저장 행동 접근, 동작 줄이기, 14초 이후 실제 raster 변화 검증. 390px의 조정 시트 결정이 MemoryRepository에 저장됨을 검증했다.
- 폰트 로드한 widget 캡처 14개 생성·재비교. P1/P0 기준선은 덮어쓰지 않았다. 대표 밝은/밤/큰 글자/넓은 화면을 육안 확인했다.
- iPhone 17 Pro / iOS 26.5 시뮬레이터 **5개** 통합 시나리오: capture success/retry/fallback/fail, 실제 SQLite close/reopen+1.5배 글자 Reader bookmark. 성공 결과에서 새 장면 읽기→해당 전체 본문까지 확인했다.
- localhost in-app browser 390×844에서 소개→홈→입력→저장→Orb→결과→연결 시트→Reader 조작·육안 확인. error/warn 로그 없음. 가상 꿈/Memory/mock이므로 hosted 계정·AI의 증거가 아니다.
- format 98파일 변경 없음, 직접 `dart analyze lib test integration_test tool/visual_preview.dart tool/ux_baseline_capture_test.dart` No issues found. privacy/log guards·diff 공백·frozen 네 파일 diff 없음. `flutter analyze --no-pub`는 이전과 같은 한국어 경로 LSP JSON crash(exit 255)로 실패했다.
- 일반 web release와 별도 로컬 visual preview web release, iOS simulator 무서명 build 통과.

### 미검증·다음 범위

실제 iPhone/PWA 시스템 영역·키보드·touch latency/frame timing/STT, hosted 전체 흐름/소설 품질/실사용 데이터는 미검증이다. 물리기기 반응 측정 요구는 남아 있으며 시뮬레이터·widget 검사로 대체 완료라 하지 않는다. 서버/엔진/프롬프트/Q 기준선·동의/RLS/원고 DB를 변경하지 않았다.

공개 Vercel은 재배포하지 않았다. 로컬 `http://127.0.0.1:4202/`는 **가상 디자인 미리보기**다. 첫 원고 기본값 시작, 저장/보강 분리, 홈의 새 결과 행동, 전체 설정/컴포넌트·night 저장·출처/편집 발견성은 다음 **P3**이다. 생성 떠나기/복귀는 P4다.

## P1 결과 — 2026-10-15

### 달라진 동작

- 보관함의 파생 장면이 volumeId/sceneId를 전달해 해당 장면을 연다. 새 결과의 ‘원고에서 확인하기’도 해당 장면의 시작으로 직접 이동한다. 현재 원고에 없는 장면·다른 권의 ID를 주면 다른 본문으로 대체하지 않고 이유와 돌아가기 행동을 보여준다.
- 홈의 주 행동 ‘꿈 기록하기’를 유지하고 ‘이어 읽기’를 낮은 위계의 보조 경로로 연결했다. 이어 읽기는 마지막 장면·문단 위치를 복원한다. 처음 읽는 원고는 기존 기본 동작(마지막 장면)을 유지한다.
- 읽기 위치는 volume/scene/passage ID, 장면·문단 order key, 문단 안의 상대 위치, legacy scroll offset, 갱신 시각으로 저장한다. 글자 크기/레이아웃/문단 순서가 바뀌면 현재 문단의 새 위치를 계산한다. 삭제된 문단은 다음 order key의 문단(없으면 마지막 문단), 삭제된 저장 장면은 가까운 장면으로 복원한다.
- 스크롤 저장은 600ms debounce이며 장면 전환·화면 종료·백그라운드에서 flush한다. 저장은 직렬화한다. 소유권 변경이나 삭제 이후의 오래된 화면 저장은 Repository 검증에서 거절한다.
- Home/Archive/Reader 오류에 다시 불러오기를 연결했다. 실제로 비어 있는 보관함은 첫 꿈 기록, 필터만 빈 경우 전체 꿈 보기를 제공한다. 기기 연결 없음은 별도 안내하고 열린 앱의 로컬 본문은 유지한다.
- Reader 장면 선택도 공통 UI 서체를 사용하게 해 P0 widget 캡처의 fallback glyph 문제를 해결했다.

### 변경 범위

`ReaderPosition` 도메인/Repository 계약과 Memory·Drift 구현, `ReaderScreen`, `ArchiveScreen`, `HomeScreen`, shell/capture의 Reader 진입, 공유 상태 UI와 기기 연결 provider를 변경했다. 새로운 읽기 계약·장면 이동·오류/오프라인·폰트 크기 테스트 및 native SQLite 재열기 통합 테스트를 추가했다.

Drift 스키마 **1→2**는 `reader_positions`에 nullable sceneId/sceneOrderKey/passageId/passageOrderKey와 기본값 0인 passageFraction을 추가한다. 기존 offset/updatedAt, 꿈, 원고, 초안은 유지한다. 생성된 `database.g.dart`는 build_runner로 갱신했다. 서버 migration·엔진·프롬프트·모델·원고 DB 수정은 없었다. 실제 데이터 DB를 초기화하지 않았다.

### 실제 검증

- Memory/Drift 공통 계약: 읽기 위치 round trip, 다른 권/문단·유효하지 않은 위치 거절.
- 전용 임시 SQLite: v1 테이블→v2 migration이 offset/원고/초안을 보존하고, 파일 재열기 후 앵커를 복원.
- widget: 3개의 새 가상 꿈→정확한 3개 장면, 직접 결과 진입과 이어 읽기 분리, debounce/background flush, 삭제된 문단/장면, 잘못된 진입 ID, 실시간 글자 확대, 오류 재시도·빈 필터/빈 기록 행동, 연결 없음에서도 로컬 본문 유지.
- 계정 bootstrap fixture: 이전 소유자의 읽기 위치가 삭제됨.
- iPhone 17 Pro / iOS 26.5 **시뮬레이터**: Reader 화면을 닫고 실제 SQLite 파일을 다시 연 뒤 글자 크기 1.5배에서 문단 상대 위치 복원 통합 시나리오 통과. 별도 capture→reveal success/retry/fallback/fail 4개 통합 시나리오 통과. 모두 synthetic/mock이고 hosted LLM 검증이 아니다.
- 웹 release 및 iOS simulator 무서명 build 통과. format·직접 Dart 분석·로그/평가 프라이버시 guard·frozen 네 파일 diff 검사 통과. `flutter analyze`는 P0와 동일한 한국어 경로 LSP crash(exit 255)로 실패했다.
- 최종 `flutter test --no-pub --reporter expanded` **169개 통과**. P0의 154개보다 15개가 추가됐다. 별도의 시뮬레이터 통합 시나리오는 **5개 통과**다.
- format(`lib test integration_test` + 캡처 도구) 95파일 변경 없음, 직접 Dart 분석 `No issues found`. 현재 14개 화면 캡처 생성·육안 확인 및 재비교 통과.

### 증거와 미검증

[P1 화면 비교](ux-review/2026-10-15/README.md)에 P0/P1 홈·Reader 비교와 새 결과 직접 읽기·없는 장면·오프라인 화면을 정리했다. 밝은 테마 390×844의 widget renderer, Memory/mock fixture, 동작 줄이기 상태다. 브라우저/PWA·물리적 시스템 영역·모션·frame rate의 실측은 아니다.

- 실제 웹 IndexedDB/wasm DB migration, hosted 계정→보관함→Reader, 실제 iPhone에서 process 종료 후 재진입은 미검증.
- 연결이 끊긴 **이미 열린 앱**의 로컬 읽기는 구현·fixture 검증됐다. 앱을 새로 여는 경우 현재 인증/최신 동의/cloud bootstrap 게이트가 네트워크에 의존한다. 오프라인 콜드스타트를 모든 계정에서 지원한다고 주장하지 않는다. 이 경계는 P4 재진입 검수에서 같은 사용자·동의·읽기 전용 범위를 확인해야 한다. 이번에는 동의/인증 게이트를 우회하지 않았다.
- 완성된 권의 Reader는 P5 경계다. P1의 명시적 진입은 현재 활성 권 안에서 확인한다.
- 스크롤 pixel offset은 옛 앱의 데이터만 있으므로 해당 legacy 위치의 장면을 정확히 알 수 없다. v1 위치는 기존 기본 장면에서 offset을 보정한 뒤 새 앵커로 저장한다.
- 스키마 v2를 적용한 로컬 DB를 구버전 앱으로 열 때의 downgrade는 지원하지 않는다. 로컬 원고를 삭제하는 down migration을 만들지 않았다. 실제 배포 전에 앱 rollback과 DB 호환성 계획을 마련해야 한다.

공개 Vercel 주소는 **재배포하지 않았다**. 현재 공개판은 P0에서 확인한 10-13 산출물이다. 이번 변경은 로컬 구현/검증/리뷰 준비이며 다음 단계는 P2의 4개 연속 화면과 모션이다.

아래 P0 섹션의 기능표/미완 목록은 10-14의 역사적 기준선이다. Reader 연결과 위치 저장에 관한 최신 상태는 이 P1 결과를 따른다.

## P0 결과

현재 코드/배포/기능 기준선을 다시 확인하고 새 디자인 요구를 정본으로 기록했다. 앱 동작·엔진·DB는 변경하지 않았다. 추가한 실행 도구는 synthetic 화면 캡처용이다.

### 코드와 배포

| 항목 | 확인 결과 |
|---|---|
| 브랜치 | `main` |
| HEAD | `6c4e296f9b3d5f06d6a50e9c1aac74b7d9f1d234` — 진단 커밋과 같음 |
| 작업 트리 | P0 시작 전부터 다수의 UI/인증/문서/시험배포 파일이 수정·미추적 상태. 이 변경들을 보존함 |
| CodeGraph | `.codegraph/` 없음 |
| 공개 주소 | https://mumumong-live-trial.vercel.app |
| 배포 | `dpl_58a8Z2icumX6HNqTPcU7eKVAvLP3`, production, Ready, 생성 2026-10-13 19:09:15 KST |
| 공개 접근 | 인증 없이 HTTP 200 확인 |
| 로컬 배포본과 공개 JS | SHA-256 `f78dfd8ac26ce7d5e3a1ecce89d783a73bb97cb75e3d2df8196f2274434f8a42` 일치 |
| 배포 source commit | `vercel inspect`에서 확인 불가. JS 해시는 로컬 산출물과의 일치만 증명하며, dirty 소스를 HEAD와 같다고 판단하지 않음 |
| 공개 빌드 설정 | 배포 스크립트는 `ENV=staging / ENGINE=remote / AUTH=apple`; Supabase 전용 프로젝트 사용. 공개 JS의 define 설정을 별도로 역분석하지 않음 |
| 서버 엔진 버전·현재 migration 적용 | 이번 P0에서는 조회하지 않음. STATUS의 과거 기록과 구분 |

`README.md`는 영속 저장·서버 엔진이 미구현이라고 설명하고 있었으나 현재 코드에는 Drift, remote engine, cloud sync가 있다. 오래된 README를 현재 경계와 맞췄다. 예전 main과 현재 dirty 소스를 혼동하면 디자인과 연결 문제를 다시 만들 수 있다.

### 기능별 현재 판정

‘구현’은 코드가 존재함, ‘연결’은 앱이 그 경로를 호출함, ‘배포 확인’은 이번에 확인한 범위만 뜻한다. 과거 테스트 수나 hosted smoke는 이번 실행으로 계산하지 않는다.

| 항목 | 구현/연결 | 이번 배포 확인 | 남은 일 |
|---|---|---|---|
| Drift·초안·Outbox | 구현·앱 연결, 로컬 테스트 통과 | 전체 실사용 미검증 | 실기기/오프라인/재시작 통합 검수 |
| 소개·동의·첫 원고 | 구현·앱 연결, widget 캡처/검증 | 공개 산출물 접근·해시만 확인 | 웹 브라우저와 실제 계정 플로우 검수 |
| hosted 생성·동기화 | remote 경로 구현·앱 연결 | 이번에는 LLM 호출 안 함 | 성공/실패/복귀 검수, Q-series 실측 |
| 보관함→Reader | Reader는 열림 | 특정 장면 진입 미검증 | sceneId를 전달하고 소유/존재 확인(P1) |
| 읽기 위치 | offset 테이블만 존재, UI/Repository 계약 연결 없음 | 미구현 | scene/passage 앵커·저장·복원(P1) |
| 빈 상태·오류 | 안내 문구는 존재, 다수 재시도/기록 행동 없음 | 행동 미구현 | 구분된 상태와 복구 행동(P1) |
| 각색·문체·시점 | 최초 설정 가능; 설정 화면의 이후 변경 없음 | 이후 변경 미구현 | 선택적 상세 설정/변경 동기화(P3/P4) |
| 음성 | native 온디바이스 채널 구현, 웹 텍스트 전용 | 실기기 미검증 | STT 품질/권한/복귀 |
| 완결·PDF | enum·조판 코드만, 사용자 완결/스냅샷/export 연결 없음 | 미구현 | P5; LLM 완결 편집은 Q-32 이후 |
| worker 정기 복구·push | 정기 스케줄·완료 푸시 미완이라는 기존 기록 | 이번 조회 안 함 | P4에서 실제 상태 확인 |

### 진단과 현재 코드의 차이

- 진단은 보관함 화살표가 sheet만 닫는다고 설명했다. 현재 `archive_screen.dart`는 sheet를 닫은 뒤 `ReaderScreen()`을 열지만 sceneId를 전달하지 않는다.
- `ReaderScreen`은 선택된 장면이 없으면 `scenes.last`를 연다. 따라서 특정 꿈의 파생 장면과 다른 장면이 열릴 수 있다.
- `ReaderPositions`는 volumeId/offset/updatedAt만 가진다. Repository 계약과 Reader에 읽기 위치 저장/복원 호출이 없다.
- Home/Archive/Reader의 empty/error는 안내 문구로 끝나는 경로가 있다. 오류 재시도·첫 기록 행동은 다음 단계에서 연결해야 한다.
- 새 원고 설정은 “선택은 이후 생성분부터 바꿀 수 있어요”라고 안내하지만 설정 화면에 대응하는 변경 경로가 없다. P3/P4에서 약속과 동작을 일치시킨다.

## 새 디자인 기준

[`DESIGN_DIRECTION_vNext.md`](DESIGN_DIRECTION_vNext.md)가 2026-10-14 요구의 정본이다. v0.4/v0.6에는 우선순위 안내를 추가했다. AGENTS와 README도 같은 문서를 참조한다.

- 원페이지 원액션: 하나의 주 행동과 접근 가능한 보조 경로.
- 빛의 중심과 흰색 페이드: 전체를 균일한 블러로 채우지 않음.
- 소량의 픽셀/ASCII: 작은 기억 오브젝트 또는 저장/성장 전환.
- 입력/음성 전사는 여전히 차분하고 반응성이 좋아야 함.
- provenance/U 잠금/동의/RLS/무본문 로그/frozen 엔진은 유지.

P2의 네 화면 적용은 위 최신 결과를 따른다. 전체 UX 적용은 P3 예정이다. P0 캡처는 역사적 UI 기준선이며 새 리디자인 결과가 아니다.

## 실제 실행한 검증

환경: macOS, 원본 한국어 경로, Flutter 3.44.6 / Dart 3.12.2.

| 검증 | 결과 |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test` | 통과, 88파일 변경 없음 |
| `flutter analyze --no-pub` | **실패**: 분석 서버 LSP JSON `Unexpected end of input`, exit 255; 코드 진단 전에 종료 |
| `dart analyze lib test integration_test tool/visual_preview.dart` | 통과, No issues found |
| `flutter test --no-pub --reporter expanded` | **154개 통과** |
| `flutter build web --release --no-pub` | 통과, `build/web`; 기본 dev/mock 빌드, 공개 배포본과 구분 |
| 캡처 도구 `flutter test --no-pub --update-goldens tool/ux_baseline_capture_test.dart` | 1개 시나리오 통과, 11개 PNG 생성·육안 확인 |
| `flutter test --no-pub tool/ux_baseline_capture_test.dart` | 1개 시나리오 통과, 11개 이미지 재비교 일치 |
| `dart analyze lib test integration_test tool/visual_preview.dart tool/ux_baseline_capture_test.dart` 및 최종 도구 단독 분석 | 통과, No issues found |
| 최종 format(`lib test` + 캡처 도구)·`git diff --check` | 통과, 89파일 포맷 변경 없음·diff 공백 오류 없음 |
| frozen 4파일을 `edfc13c`와 비교 | diff 없음 |
| 공개 배포 inspect/HTTP/JS hash | Ready, 200, 로컬 배포본과 일치 |

위 결과는 이번에 실제 실행한 명령만 포함한다.

## 시각 증거

[`ux-baseline/2026-10-14/README.md`](ux-baseline/2026-10-14/README.md)에 11개 화면과 재현 명령을 정리했다. 390×844, 폰트 로드, 동작 줄이기, Flutter widget renderer, MemoryRepository/mock engine의 가상 데이터다. `kIsWeb=false`의 계정 버튼/음성 표시이므로 실제 웹 화면과 그대로 같다고 주장하지 않는다. 동의 fixture는 실제 동의가 아니며 결과는 고정 mock 응답이다.

관찰: 소개·표지가 넓은 저채도 색 면으로 이어지고, 첫 설정이 모든 선택을 동시에 노출한다. 보강은 저장 후 별도 선택 없이 바로 나온다. 이 세 부분은 새 기준의 공간 초점/행동 위계와 맞지 않으므로 P2/P3에서 수정한다. Reader 드롭다운 문구의 widget 캡처에 폰트 fallback glyph가 보인다. 실제 브라우저 재현 여부는 미검증이고 P3 글꼴 적용 검수에 남긴다.

## 미검증

- 실제 웹 브라우저에서 소개→동의→계정→생성→결과 전체 이동: 이번 P0에서 미실행. HTTP/산출물 확인과 구분한다.
- iPhone/PWA 시스템 영역·키보드·touch latency·frame rate·음성·push: 미실행.
- 375×667/430×932/넓은 웹/글자 확대/전체 밤 테마: P2/P3 검증 예정.
- 서버의 현재 migration·LLM 공급자/버전·worker 복구 실측: 이번 미실행.
- 이번 P0에 앱/iOS 코드 변경 없음. iOS simulator build·DB 테스트·hosted LLM smoke는 재실행하지 않음.
- 문학적 품질·개인 꿈 코퍼스·사람 블라인드 판단·holdout: 평가하지 않았음.

## 실행 체크리스트

- [x] P0 — 현재 코드/배포/기능 차이, 디자인 충돌, synthetic 기준 화면, 테스트/빌드 기준선 기록
- [x] P1 — 정확한 활성 권 장면 이동, 이어 읽기 앵커·복원, 빈 상태/오류 행동의 로컬 구현·검증 (위 실사용/오프라인 콜드스타트 경계는 미검증/후속)
- [x] P2 — 소개→기록→생성→새 장면 4화면과 상태 기반 모션의 로컬 구현·검증 (물리기기 성능/hosted/전역 night는 미검증·후속)
- [x] P3 — 공통 UI·기본값 시작·선택적 보강/저장 분리·표시 설정 저장·문단 메뉴의 로컬 구현/검증 (hosted/물리기기/사람 사용성은 미검증)
- [ ] P4 — 진행 중: 생성 복귀·소비 영수증·이후 설정 변경 구현/로컬 검증. 공개 반영·재시도/오프라인 경계·P4-3 운영 복구/알림 남음
- [ ] P5 — 완결 스냅샷, PDF 저장·재열람·다음 권
- [ ] P6 — 메타데이터 관측, 전체 흐름/반영 준비

각 페이즈 종료는 명시된 미검증 범위가 해결됐다는 뜻이 아니다. 사용자 요청대로 한 단위씩 진행한다. 다음 작업은 P4-3 운영 복구/알림이며 P4-1의 재시도/오프라인 경계 검수도 남는다. 운영 배포·운영 데이터 변경은 이번에 하지 않았다.

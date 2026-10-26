# 2026-10-26 Visual & UX Quality Recovery — P0 진단

지시서 "MUMUMONG Visual & UX Quality Recovery" + "Design System Foundation 추가 지시"의 P0 단계 기록이다. **코드·문서 정본·배포는 바꾸지 않았다.** 이 디렉터리의 `before/` 이미지는 실제 실행 화면이며, 생성 본문은 mock 엔진의 고정 합성 fixture다(실제 AI 결과 아님). 입력한 꿈 원문은 새로 지어낸 가짜 문장이다.

## 0. 실행 환경과 경계

| 항목 | 값 |
|---|---|
| 앱 진입 | `lib/main.dart`, `ENV=dev ENGINE=mock AUTH=local MOCK_CASE=success`, `flutter run` debug |
| 기기 | iPhone 17 Pro(402×874) · iPhone 17 Pro Max(440×956) · iPhone 17e(390×844, 홈만) 시뮬레이터, iOS 26.5 |
| 시작 흐름 | `tool/start_flow_review.dart` 웹 빌드(`build/start-flow-review`)를 `tool/serve_pwa_qa.mjs` 4226으로 열고 in-app 브라우저 390×844에서 캡처 |
| 큰 글자 | `simctl ui content_size extra-extra-extra-large` 로 홈만 확인 |
| 미검증 | 실기기, 실제 remote 생성, 음성(STT), Reduced Motion 실기기, 프레임/터치 지연 측정, 완성본/PDF 화면, 설정 상세(이후 장면 설정·기록 관리·앱 잠금) |

**환경 주의.** `flutter build ios --simulator`(서명 유무 무관)로 만든 `.app`을 `simctl install/launch`로 띄우면 `Supabase.initialize` → `flutter_secure_storage` 에서 `A required entitlement isn't present` 로 첫 프레임 전에 멈춰 흰 화면이 된다. `flutter run`으로 띄우면 정상이다. 원인(키체인 entitlement 임베딩 차이)은 확정하지 않았다. 사전 빌드 `.app`으로 QA하려면 이 경로를 먼저 고쳐야 한다.

## 1. 캡처 목록 (`before/`)

| # | 파일 | 화면 |
|---|---|---|
| 24 | `24-pwa-startup-layer-web390.jpg` | PWA HTML 시작 레이어(앱 로드 전) |
| 25 | `25-entry-web390.jpg` | 소개 01/02 |
| 22 | `22-consent-web390.jpg` | 동의 02/02 |
| 23 | `23-volume-setup-web390.jpg` | 첫 이야기 시작 |
| 26 | `26-auth-loading-web390.jpg` | 시작 준비 대기(Orb) |
| 01 / 27 / 29 / 21 | `01-home-17pro.png` `27-home-17promax.png` `29-home-17e.png` `21-home-xxxl-type-17pro.png` | 원고 홈(3크기, 큰 글자) |
| 02 / 03 / 28 | `02-capture-empty-17pro.png` `03-capture-keyboard-17pro.png` `28-capture-17promax.png` | 꿈 기록(빈 상태, 키보드 열림, 큰 화면) |
| 04 | `04-saved-17pro.png` | 저장 완료 + MemoryStamp |
| 05 | `05-recall-17pro.png` | 기억 보강 |
| 06 | `06-processing-17pro.png` | 생성 중(Thinking Orb) |
| 07 / 07b / 08 | `07-reveal-17pro.png` `07b-reveal-gradient-band-zoom.png` `08-reveal-adjust-sheet-17pro.png` | 새 장면 결과, 그라디언트 띠 확대, 장면 조정 시트 |
| 09–13 | `09-reader-17pro.png` … `13-reader-night-origins-17pro.png` | Reader, 문단 메뉴, 출처 시트, 밤 종이, 출처 마커 |
| 14–17 | `14-home-night-after-reader-17pro.png` … `17-appearance-night-17pro.png` | 야간 홈·보관함·설정·화면과 읽기 |
| 18–20 | `18-settings-light-17pro.png` `19-archive-light-17pro.png` `20-archive-dream-detail-17pro.png` | 밝은 설정·보관함·꿈 상세 |

## 2. 진단 — 기준별

표기: **현재** → **기대(지시서)** → 코드 원인 → 수정 위치.

### 2.1 Visual Identity

- **현재**: 소개(25)·홈(01)은 상부 블루/인디고 확산광 + 작은 반투명 원고 조각 + 'MUMUMONG' 문자 워드마크. 나머지 화면(기록·결과·Reader·보관함·설정)은 흰 바탕에 Pretendard 텍스트와 회색 pill 버튼이라 **일반 AI 앱/기본 Material 앱과 구분되는 요소가 거의 없다**. 꿈·기억을 표현하는 도트/하프톤 언어는 저장 직후 32px 스탬프(04) 하나뿐이다.
- **기대**: 도트/하프톤이 "꿈이 형태를 얻는" 상태 언어로 작동하고, 모든 화면이 한 에디토리얼 제품으로 읽혀야 한다.
- **원인**: 2026-10-14 vNext 결정으로 전면 도트 필드를 제거(`lib/core/design/dot_field.dart` 삭제)하고 "작은 기억 오브젝트 한 곳"으로 축소했다. 홈 커버는 `DreamAtmosphere(memoryObject: true)`의 고정 종이 아이콘이며 원고 성장과 연결되지 않는다(`lib/core/design/dream_atmosphere.dart:179-218`).
- **수정 위치**: `dream_atmosphere.dart`(커버 렌더러 교체), `lib/ui/home/home_screen.dart:266-308`(히어로), 워드마크 컴포넌트 신설. **정본 충돌 §4-A 결정 필요.**

### 2.2 Editorial Layout & Typography

- **현재**: 제목/본문 모두 Pretendard(600/400), Reader 본문만 MaruBuri 18/1.75. 레퍼런스(Research·ohm)의 세리프 디스플레이 제목, 큰 여백의 에디토리얼 위계가 없다. 홈 제목 "이름 없는 원고"와 "42%"가 같은 줄에서 경쟁한다(01). 워드마크 자간이 홈 2.4/소개 1.8로 다르다(`home_screen.dart:291`, `onboarding_screen.dart:152`).
- **기대**: 제목·메타·본문의 타입 스케일을 에디토리얼로 재정의하고 워드마크를 하나의 컴포넌트로 통일.
- **원인**: `design_system.dart:269-344`의 TextTheme가 UI 전용이고, 리더 본문 스타일이 reader/library/appearance 세 곳에 중복 정의돼 있다(인벤토리 §5).
- **수정 위치**: `design_system.dart` TextTheme, `MongWordmark` 신설, 중복 TextStyle 제거.

### 2.3 Brand Color Application

- **현재**: 바탕 `#FFFFFF`(iOS 상태바 띠 방지 목적, 10/08 결정). 블루는 확산광에만 쓰이고 버튼·칩·링크·토글에는 거의 쓰이지 않는다. 설정 토글은 **Material 기본 초록**(17). 칩 선택색은 `dreamMist`/`sky300`로 매우 약하다(19). 야간 테마는 푸른 검정 `#050C18`인데 Reader 야간 종이는 따뜻한 `#161513`으로 두 팔레트가 공존한다(12 vs 14).
- **기대**: Warm White + Warm Sky Blue가 브랜드 중심. 블루가 선택·강조·진행 상태에서 일관되게 쓰여야 함.
- **원인**: `MongColor.sky*`가 저채도 회청색(`#93B9CF` 등)이고 확산광 색(`#72CBF2/#288FD4/#5666CD`)과 다른 계열이다(`design_system.dart:14-21`, `dream_atmosphere.dart:152-176`). Switch 테마 미정의(`design_system.dart` ThemeData에 `switchTheme` 없음).
- **수정 위치**: `design_system.dart` 색 토큰·`switchTheme`·`chipTheme`, `reader_screen.dart:379-382` 야간 팔레트 통합. **정본 충돌 §4-C/D 결정 필요.**

### 2.4 Halftone / Dot Rendering

- **현재**: 전면 도트 없음. `MemoryStamp` 7셀/32px가 저장 후 650ms 한 번 모인다(04). 생성 중은 패키지 `thinking_orbs`의 `composing` 띠 Orb(06). 커버는 도트가 아니라 반투명 종이 아이콘.
- **기대**: 커버 렌더러(모티프 마스크·밀도·탈락·clarity≤0.9·volume seed), 입력량 반응 파티클, 저장 시 응집, 연결 시 편입, 성장 시 커버 합류.
- **원인**: 지시서가 참조한 `dot_field.dart`, `_doorMask()`, `_ProcessingDots`는 **현재 트리에 없다**(삭제/대체됨). 지시서는 10/14 이전 스냅샷 기준이다.
- **수정 위치**: 새 `lib/core/design/dot_cover.dart`(커버 렌더러), `MemoryStamp` 확장, Processing→Reveal 전환 페인터. **정본 충돌 §4-A/B 결정 필요.**

### 2.5 Motion Quality

- **현재**: 확산광 14s 반복(홈·소개만), 버튼 눌림 scale .975/120ms, 페이지 slide 5%/420ms, 단계 전환 AnimatedSwitcher 360ms(capture:766). 생성→결과는 fade/slide 전환뿐이고, 결과 문장의 등장 리듬·성장 연결 모션은 없다. 홈 진척 숫자만 900ms 카운트업(home:146).
- **기대**: Quiet→Reactive→Quiet, Processing→Reveal→Growth가 하나의 시각 서사.
- **원인**: 모션 토큰은 `MongMotion` 5개뿐이고 "Text Reveal / Particle Gathering / Manuscript Growth" 레시피가 없다. 처리 단계 값은 있으나(`capture_flow.dart:1201-1206`) 10/26 결정으로 Orb 모양을 `composing` 하나로 고정했다(`thinking_orb.dart`).
- **수정 위치**: `design_system.dart` MongMotion 확장, `capture_flow.dart` `_buildProcessing/_buildReveal`, 공용 전환 위젯. **정본 충돌 §4-B 결정 필요.**

### 2.6 Interaction Feedback

- **현재**: 주 CTA `GlassActionButton`은 흰 바탕 위에서 blur할 배경이 없어 **연회색 평면 pill**로 보인다(02, 04, 23). 보조 행동은 회색 TextButton이라 주/보조 차이가 형태뿐이다. 녹음 버튼은 로컬 구현(scale .94, Reduced Motion 미처리, `capture_flow.dart:950-983`). Reader 문단 옆 "…" 메뉴가 항상 노출돼 본문 오른쪽에 회색 점이 줄지어 보인다(09).
- **기대**: 유리 CTA는 레퍼런스처럼 내부 틴트/하이라이트가 있는 Level 2 글래스, 중요한 행동은 고대비 솔리드 허용, 제품 전체 동일한 눌림 촉감.
- **원인**: `GlassActionButton`의 그라디언트가 흰색 .66→.42뿐이고 블루 틴트가 없다(`design_system.dart:580-608`). `QuietTextButton`은 정의만 있고 사용 0건, raw `TextButton` 46개가 보조 행동을 대신한다(인벤토리 §4).
- **수정 위치**: `MongButton` variants(primary/secondary/glass/ghost) 신설 후 `EditorialButton`/`GlassActionButton`/raw TextButton 치환.

### 2.7 UX Flow & Hierarchy

- **현재**: 흐름 자체는 완성돼 있다(소개→동의→첫 설정→홈→기록→저장→(보강)→생성→결과→Reader→보관함). 첫 설정은 이미 "시작하기 + 선택 설정"으로 단순화됐다(23). 저장 후 "장면 만들기/보강/나중에" 분리도 돼 있다(04).
- **문제**: (a) 결과(07)의 "장면 조정하기" 시트가 mock 고정 질문을 보여 연결 결정 UX를 검증할 수 없다. (b) Reader 메뉴 "밤의 종이로 읽기"가 `UiPreferences.themeMode`를 저장해 **앱 전체가 어두워진다**(`reader_screen.dart:850-859`; 14-16). P3에서 앱 전역 테마와 연결한 의도적 동작이지만 메뉴 문구는 Reader 종이만 바꾸는 것으로 읽힌다. 문구를 "앱을 어둡게"로 바꾸거나 Reader 전용 야간 종이를 분리해야 한다. (c) 홈의 "42%" 숫자는 실제 MU 기반이지만 시각 성장 표현이 없다. (d) PWA 시작 레이어(24)가 흰 바탕 텍스트뿐이라 첫 인상이 비어 있다.
- **수정 위치**: `reader_screen.dart` 메뉴 액션 → `UiPreferences.readerNight` 분리, `web/index.html` 시작 레이어, 홈 커버 성장 표현.

### 2.8 Mobile Responsiveness

- **현재**: 17 Pro/Pro Max/17e 홈·기록 레이아웃 정상(01·27·29·28). 키보드 열림 시 에디터 축소, 저장 버튼 유지, 마이크 숨김(03). 글자 XXXL에서 홈 overflow 없음(21).
- **미검증**: 375×667은 시뮬레이터가 없어 기존 golden(테스트)로만 확인됨. Reader·보관함 큰 글자, 가로.

### 2.9 Accessibility

- **현재**: 공용 위젯은 `disableAnimations` 처리(확산광·스탬프·버튼). 로컬 녹음 버튼은 미처리. Semantics liveRegion/header 사용. 칩 선택 대비가 낮다(선택 `#EAF7FD` vs 비선택 `#F3F4F4`). 글래스 CTA 텍스트 대비는 흰 바탕에서 충분하나 색 배경 위 검증 없음.
- **수정 위치**: `MongButton`/`MongChip` 상태 토큰, 선택 대비 상향.

### 2.10 Performance

- **현재**: 확산광은 RepaintBoundary + 30Hz 샘플링(`sampled_motion.dart`), 백그라운드 정지. 화면당 `BackdropFilter` 2~3개(CTA마다). 처리 Orb는 패키지 자체 clock.
- **관찰(시뮬레이터)**: `DreamAtmosphere`의 페이드 경계에 격자형 띠가 캡처에 보인다(07b 확대, 01·04·07·27 모두 같은 위치). 1:1 크롭에서는 규칙적인 1px 격자라 Impeller의 그라디언트 ordered dithering이 축소 캡처에서 모아레로 보였을 가능성이 크다. **실기기 육안 확인 전까지 결함으로 확정하지 않는다**(DESIGN.md §14-6). 실기기에서도 보이면 radial 겹침 축소 또는 단일 패스 셰이더로 대응한다.
- **미측정**: 실기기 FPS·터치 지연. 지시서 P4에서 측정.

### 2.11 일관성(디자인 시스템 이탈) 요약

`lib/ui` 20개 파일 7,244줄을 스캔한 결과(상세는 인벤토리 보고): 하드코딩 색 17개(5파일), MongMotion 밖 duration/curve 5개, 로컬 radius 리터럴 4개(31·22·28·28), 로컬 버튼/표면/행 위젯 18개(10파일), raw `TextButton` 46개(10파일), TextStyle 리터럴 20개(9파일), 리더 본문 스타일 3중 정의, 행간 4종 혼재(1.55/1.6/1.65/1.75), 글래스 blur 22(GlassSurface) vs 18(MongGlass.blur) 불일치, `QuietTextButton`/`FlowingGradient` 미사용. 화면마다 헤더 패딩이 다르다(`_FlowHeader` 24,14,10,12 / Reader 14,8,16,10 / `MongPageHeader` 24,24,24,32).

## 3. 사용자 관점 8문항 — 현재 판정

| # | 질문 | 판정 | 근거 |
|---|---|---|---|
| 1 | 일반 AI 앱과 다른 브랜드로 느껴지는가 | 부분 | 소개·홈 확산광만 고유. 나머지는 범용 |
| 2 | 도트가 의미 있는 인터랙션인가 | 아니오 | 저장 스탬프 1회뿐 |
| 3 | 생성 과정이 로딩과 차별되는가 | 부분 | Orb + 문구. 단계·결과로의 연속성 없음 |
| 4 | 원고 성장이 시각적으로 느껴지는가 | 아니오 | 숫자(%)와 카운트업만 |
| 5 | Reader가 실제 독서에 적합한가 | 대체로 예 | MaruBuri 18/1.75, 밤 종이. 문단 메뉴 점·Material 드롭다운이 방해 |
| 6 | 스카이블루가 고유 인상을 만드는가 | 부분 | 확산광에만. 컨트롤·상태에 블루 부재, 토글은 초록 |
| 7 | 모션 제거해도 사용 가능한가 | 예 | Reduced Motion 경로 존재(로컬 녹음 버튼 제외) |
| 8 | 일관된 에디토리얼 제품으로 보이는가 | 아니오 | 2.11의 이탈, 화면별 헤더/버튼/행 구현 상이 |

## 4. 지시서와 현재 정본의 충돌 — 결정이 필요한 항목

AGENTS/CLAUDE 규칙("규칙 충돌 시 추측하지 말고 멈추고 보고")에 따라 기록한다. 결정 전에는 아래 항목에 손대지 않는다.

| | 지시서 요구 | 현재 정본(날짜) | 제안 |
|---|---|---|---|
| A | 도트/하프톤을 핵심 언어로: 커버 렌더러, **입력량에 반응하는 파티클**, 처리 도트 | vNext(10/14)·AGENTS: 전면 도트 그리드 금지, 작은 기억 오브젝트/전환 한 곳만. HANDOFF §4-5: **타이핑/말하기마다 장식 추가 금지** | 커버·저장·생성→결과 전환에는 도트 복원. 입력 중에는 **정적 유지**(저장 순간에만 응집). 입력량 반응 파티클은 제외 또는 키 입력과 분리된 저빈도 갱신으로 한정 |
| B | 생성 단계(Extract→Link→Write→Validate→Reveal)마다 시각 상태 변화 | 10/26 사용자 결정: Orb는 **composing 하나**, 상태별 모양 순환 금지 | Orb 모양은 고정하고, 단계는 **Orb 주변 도트의 밀도/정렬**로만 표현(정직한 추상 전환) |
| C | Warm White 바탕 | 10/08 결정: 시스템 바/GNB 띠 방지를 위해 `#FFFFFF` 고정 | 따뜻한 화이트(예: `#FBFAF7`)로 바꾸되 `SystemUiOverlayStyle`·PWA `theme-color`·`index.html` 배경을 같은 값으로 묶어 띠 재발 방지. 실기기 확인 필요 |
| D | 블루 단일 브랜드, 핑크/바이올렛 금지 | v0.8 확산광에 인디고 `#5666CD`(라일락) 포함, HANDOFF "스카이블루·라일락" | 인디고를 저채도 블루 계열로 치환하거나 "일시적 빛 번짐"으로만 축소 |
| E | Editorial Typography(세리프 디스플레이 제목 암시) | vNext: 에디토리얼 고정 → 산세리프 UI로 전환 | 제목만 MaruBuri(또는 지정 세리프)로 되돌리고 UI 라벨은 Pretendard 유지 |
| F | Capture → Emotional Reflection → Short Result → Complete/Continue/Archive | PDR: 해석·심리 의미 금지. vNext(10/22): AI 감정 응답은 범위 밖, 저장 후 짧은 수용 문구만 | 이번 작업은 UX 차이만 정리(§5). 감정 공감 문구는 별도 승인·엔진 작업 |
| G | `dot_field.dart` 등 파일 지정 | 해당 파일은 삭제됨(작업 트리 `D`) | 복원하지 않고 새 커버 렌더러로 구현 |
| H | `DESIGN.md`를 단일 정본으로, 토큰 확정 | CLAUDE.md: `design_system.dart` 토큰 값 변경 금지 | `DESIGN.md` 채택 시 CLAUDE.md 규칙을 "DESIGN.md를 먼저 읽고 토큰은 DESIGN.md와 1:1"로 개정 |
| I | 온보딩에 모션 워드마크 | HANDOFF: 큰 소개 화면·그라디언트 유지, 10/26 단순화 | 소개 첫 페이지의 확산광 위에 워드마크 모션만 추가(동의·설정 구조는 유지) |

## 5. 최신 제품 UX(Capture→Reflection→Short Result→Choose)와 현재 구현 차이

| 단계 | 현재 구현 | 차이 |
|---|---|---|
| Capture | 텍스트/음성 → 저장(04) | 동일 |
| Emotional Reflection | 저장 후 정적 수용 문구 "떠오른 만큼 남겼다면 충분해요" | AI 공감 없음. 추가하려면 해석 금지 규칙과 엔진 단계(E1 이후 짧은 응답) 설계가 필요 → **후속 작업** |
| Short Creative Result | 생성 → 첫 문단 리빌 → 장면이 **활성 권에 바로 편입**(progress +4%) | "독립 짧은 작품"이 아니라 원고 장면 추가 구조. 첫 장면만 예외 안내 |
| Complete / Continue / Archive | 결과 화면에 "새 장면 읽기 / 장면 조정하기", 보관함에 "기록만" 필터, 완결은 설정→내가 완성한 책 | 세 갈래 선택 UI 없음. 데이터 모델(standalone volume, scene detach)은 일부 존재(`placement_kind.standalone`, `removeDreamFromManuscript`) → UI만으로 1차 구현 가능, 완결 전환은 P5 계약 사용 |

## 6. 리서치 요약 (GitHub 디자인 시스템)

- **google-labs-code/design.md spec**: 섹션 순서 Overview → Colors → Typography → Layout → Elevation → Shapes → Components → Do/Don't, YAML 토큰 블록 병합, 중복 키 금지, WCAG 대비 체크. 모션/접근성 섹션은 spec에 없어 무무몽은 추가 섹션으로 둔다.
- **atmospheric-glass 예제**: Level 1 그라디언트+그레인, Level 2 blur 20/white .10, Level 3 blur 40/white .20, 1px white .20 테두리, 그림자 `0 8px 32px rgba(0,0,0,.1)`, 글래스 위 글자는 한 단계 굵게. 다크 배경 전제라 값은 그대로 못 쓴다.
- **mkbabb/glass-ui**: 5단계(wash 30% blur1 / quiet 50% blur3 / resting 65% blur12 / floating 80% blur16 / overlay 95% blur24), 대비는 "배경 최악 픽셀 기준 4.5:1", 눌림 scale .96, reduced-transparency 시 불투명 1.0·blur 0, 글래스 위에 글래스 중첩 금지, 매 프레임 blur 재계산 금지.
- **localyapper**: Level 0 `#f9f9f9` / 1 카드 `#FFF` / 2 플로팅 80% white blur 20, 경계는 선 대신 톤 차이, whisper shadow `0 8px 32px rgba(0,0,0,.04)`. 밝은 바탕 글래스의 가장 가까운 참고.
- **flutter_glass_ui_kit**: `BackdropFilter`+캐시된 `ImageFilter`, 기본 blur 80/opacity .1(과도), 성능 모드(low=blur 50%), 중첩 금지 권고. API 형태(GlassTheme/GlassContainer/GlassButton)만 참고.
- **theia-media `docs/design-system.md`**: 404. 저장소에는 `docs/field-testing.md`만 있어 참고 불가.

무무몽 적용 원칙(제안): Surface 4단계(Paper/Atmospheric/Glass/Elevated) 중 밝은 바탕 글래스는 localyapper·glass-ui resting~floating 값(white .65~.82, blur 12~20)에서 시작하고, 글래스 CTA에 **블루 틴트 하이라이트**를 넣어 흰 바탕에서도 유리로 읽히게 한다. 글래스 위 글래스 중첩 금지, 긴 본문 위 글래스 금지는 그대로.

## 7. 결정 후 작업 순서(제안)

1. §4 A~I 결정 → `DESIGN.md` 초안(토큰·Surface·컴포넌트·Dot 상태·모션 레시피·Do/Don't·QA 기준) → AGENTS/CLAUDE 규칙 갱신.
2. `design_system.dart`를 DESIGN.md와 1:1로 재정렬: 색(warm white·sky 계열 재정의·switch/chip 테마), TextTheme, MongMotion 확장, `MongButton/MongIconButton/MongSurface/MongInput/MongSheet/MongNavigation/MongProgress`.
3. `tool/ui_catalog.dart` 개발 전용 카탈로그(모든 variant·state·Surface level·Dot 상태·Reduced Motion) + golden.
4. Capture→Processing→Reveal→Home 성장 모션 한 벌 구현(확산광 띠 결함 수정 포함).
5. Home 커버 렌더러, Reader 크롬·문단 메뉴·드롭다운, Archive 위계, Onboarding 워드마크.
6. 시뮬레이터 3크기·큰 글자·Reduced Motion 재검증, 회귀(314 VM/Chrome/IndexedDB) 실행, after 스크린샷·녹화.

## 8. 이번 P0에서 실행한 검증

- `flutter run` iPhone 17 Pro / 17 Pro Max / 17e: 기동·홈·기록·저장·보강·생성(mock)·결과·Reader·보관함·설정 조작, 스크린샷 29장.
- `flutter build web --release --target tool/start_flow_review.dart` 통과, 4226 로컬 서버에서 소개/동의/첫 설정/대기 캡처.
- 코드/문서 변경 0. 공개 배포·계정·동의 제출·실제 모델 호출 0.

---

# P1 Visual Foundation — 2026-10-26

사용자 결정: §4의 A~I를 진단 문서 제안대로 확정(2026-10-26). 이 단위는 **디자인 시스템 정본과 공용 컴포넌트, 카탈로그**까지다. 개별 화면 재설계(Capture/Processing/Reveal, Home/Reader/Archive/Onboarding)는 다음 단위(P2/P3)에서 한다.

## P1-1. 만든 것

| 산출물 | 경로 | 내용 |
|---|---|---|
| 디자인 정본 | `DESIGN.md` | Brand Principles · 색/의미 역할 · 확산광 규칙 · 타이포 · 간격/반경/그림자 · Surface 0–3 · 컴포넌트와 상태 · Dot 상태 시스템 · 모션 토큰/레시피 · 접근성 · 화면별 규칙 · Do/Don't · 결정 기록 · QA 기준 |
| 규칙 | `AGENTS.md` 0항·비타협 규칙, `CLAUDE.md` 읽기 순서·토큰 규칙 | UI 작업 전 `DESIGN.md` 필독, 화면 로컬 스타일 금지 |
| 토큰·테마 | `lib/core/design/design_system.dart` | warm white `#FBFAF7`, sky 50–800, light* 4색(인디고→`lightSoft #5A8DD8`), 세리프 display/title/headline(MaruBuri), `MongMotion` 확장(settle/gather/growth/reveal/atmosphere, `pressScale`), `MongRadius`(tab/nav/chip), `MongShadow` 3단계, `MongGlass` 알파/시그마, `switchTheme`·`errorStyle`·`errorBorder`, `MongPalette.accent/accentSoft/accentInk/alertInk`, `manuscriptStyle()` |
| 컴포넌트 | 같은 파일 | `MongButton`(primary=Sky Glass / secondary=Frosted / solid / ghost, Disabled·Loading·lightContent·icon), `MongIconButton`(plain/glass/recording+active), `MongSurface`(paper/glass/elevated), `MongChip`, `MongWordmark`(정적/1회 모션). 기존 `GlassActionButton`·`EditorialButton`·`QuietTextButton`·`ChoiceChipEditorial`·`GlassSurface`는 새 컴포넌트의 별칭 |
| 도트 렌더러 | `lib/core/design/dot_cover.dart` | `DotCoverSpec`(seed·motif·density·clarity≤.9·jitter·dropout≥.1), `DotCover`/`DotCoverPainter`(volume seed 고정, 성장 전환 1회, 가장자리 blur), 모티프 abstract/door/window/moon, `DotState` enum, `dotSeedFor()` |
| 확산광 | `lib/core/design/dream_atmosphere.dart` | 빛 4색을 토큰으로, 야간 테마 hex 리터럴 제거, 야간 `switchTheme` |
| PWA 셸 | `web/index.html`, `web/manifest.json`, `web/install.html` | 배경·theme-color를 `#FBFAF7`로 통일(결정 C) |
| 카탈로그 | `tool/ui_catalog.dart` | 색·타이포·Surface·버튼 variant×state·IconButton·Chip/Switch/Checkbox·Input 상태·Sheet·Dot 모티프×clarity·성장 모션·MemoryStamp·Orb·모션 토큰. 밝게/어둡게·동작 줄이기 토글, 웹은 `?night=true&reduce=true` |
| 테스트 | `test/ui/design_foundation_test.dart` | 토큰 1:1(14개), 역할 전환, 버튼 4 variant 높이/눌림 .975/Reduced Motion Duration.zero, Loading/Disabled, Chip 선택 표현, 녹음 버튼 정지, DotCover 결정성·clarity 상한·밀도 증가, 카탈로그 3크기(375×1.6 야간 Reduced 포함) overflow 0 |
| 골든 | `goldens/` 162장 | 기존 6개 시각 테스트의 골든 경로를 이 디렉터리로 옮기고 재생성. 과거 리뷰 디렉터리의 증거는 그대로 둠 |

## P1-2. Before / After

| 화면 | Before | After(골든, 390×844 widget renderer) | 달라진 것 |
|---|---|---|---|
| 소개 | `before/25-entry-web390.jpg` | `goldens/day-390-844-normal-entry.png` | 세리프 제목, 따뜻한 바탕, Sky Glass CTA, 인디고 대신 저채도 블루 |
| 홈 | `before/01-home-17pro.png` | `goldens/day-390-844-normal-shell-home.png` | 세리프 제목, Sky Glass 주 행동, 바탕 warm white |
| 저장 완료 | `before/04-saved-17pro.png` | `goldens/day-390-844-normal-saved.png` | 제목 세리프, CTA 틴트 |
| 보관함 | `before/19-archive-light-17pro.png` | `goldens/day-390-844-normal-archive.png` | 선택 칩 accent 테두리+accentSoft 채움 |
| 설정 토글 | `before/17-appearance-night-17pro.png` | `after/catalog-05-iconbutton-chip-switch-17pro.png` | Material 초록 → sky500 |
| 컴포넌트 전체 | — | `after/catalog-01…11-*.png` | 시뮬레이터 iPhone 17 Pro 실행 캡처. `catalog-09/10/11`은 성장 모션 전·중·후 |

After 골든은 widget renderer(폰트 로드, 390×844 등 5크기×밝게/어둡게)이며 실기기 캡처가 아니다. 화면 자체의 레이아웃은 바꾸지 않았으므로 Reveal·Reader·Processing의 "After"는 다음 단위에서 만든다.

## P1-3. 카탈로그에서 발견해 고친 것

- ghost 버튼이 아이콘 없이도 `TextButton.icon`의 빈 아이콘 간격을 남김 → 아이콘 없으면 `TextButton`.
- 입력 오류 문구가 Material 기본 빨강 → `alert` 토큰(`errorStyle`).
- `DotCover`가 이전 spec 없이도 transition 0에서 시작해 거의 보이지 않음 → 이전 spec이 없으면 정착 상태로 그림.
- 카탈로그 헤더가 375×1.6에서 177px overflow → Wrap.

## P1-4. 검증 (실제 실행)

- `dart format --output=none --set-exit-if-changed lib test tool/ui_catalog.dart`: 128파일 변경 0
- `dart analyze lib test integration_test tool/ui_catalog.dart tool/drift_worker.dart tool/start_flow_review.dart`: No issues
- `flutter analyze --no-pub`: 기존 한글 경로 LSP crash(exit 255) 재현, 통과로 세지 않음
- `tool/check_log_safety.sh` · `tool/check_eval_privacy.sh`: OK
- `flutter test --no-pub`: **328개 통과**(기존 314 + 신규 14). 골든 162장은 `goldens/`에 재생성(`--update-goldens`는 경로를 옮긴 6개 시각 테스트에만)
- `flutter test --platform chrome test/ui/capture_keyboard_test.dart`: 6개 통과
- `bash tool/test_web_durability.sh`: 실제 IndexedDB commit 1개 통과
- `node --test tool/pwa_startup_test.mjs tool/pwa_install_test.mjs`: 11개 통과
- `flutter build web --release` → `node --check build/web/flutter_bootstrap.js`: 통과(기본 dev 빌드, 공개 배포 아님)
- `flutter build ios --simulator --no-codesign`: 통과(서명/TestFlight 아님)
- `git diff --check`: 통과. 동결 4파일 `edfc13c`와 동일
- 시뮬레이터 iPhone 17 Pro에서 `tool/ui_catalog.dart` 실행·조작·캡처 11장(`after/`). 성장 모션 전·중·후 확인, 동작 줄이기 토글은 카탈로그 테스트(375×1.6)로만 검증

## P1-5. 남은 것 / 미검증

- 화면 적용: `lib/ui` 안의 raw `TextButton` 46개·로컬 색/시간/스타일·`_FlowHeader`/Reader 상단바/GNB는 아직 그대로다(다음 단위에서 `MongButton.ghost`·`MongNavigation`·`MongPageHeader`로 치환).
- `MongInput`·`MongSheet`·`MongNavigation`·`MongProgress`는 DESIGN.md에 규격만 있고 전용 위젯은 없다(테마와 `MongSurface`로 표현). 화면 적용 단계에서 위젯화한다.
- Reader 야간 종이 `readerNightPaper`를 토큰으로만 올렸고 `reader_screen.dart`의 로컬 팔레트는 아직 치환하지 않았다.
- 실기기: warm white와 시스템 바 경계, 글래스 대비, 확산광 띠, 프레임은 미검증(시뮬레이터·widget renderer만).
- 공개 배포 없음. `build/live-trial`과 공개 빌드 `20261026T111252Z`는 그대로다.

---

# P2 Hero Interactions — 2026-10-26

Capture → Processing → Reveal → 원고 성장을 DESIGN.md §9 레시피대로 **하나의 서사**로 묶었다. 모든 모션은 실제 상태 변화(저장 성공, 실제 job 단계, 결과 동기화, 진척 이벤트)에만 반응하고 한 번 재생된 뒤 멈춘다. 입력 중에는 아무것도 움직이지 않는다. 엔진·저장·출처·동의 경로는 바꾸지 않았다.

## P2-1. 만든 것

| 산출물 | 경로 | 내용 |
|---|---|---|
| 모션 컴포넌트 | `lib/core/design/hero_motion.dart` | `ProcessingHalo`(Orb 주변 24개 도트, 단계 0 extract 흩어짐 → 1 link 4군집 → 2 write 고른 링 → 3 validate 조밀한 링, 단계 변경 시 `gather` 900ms 1회), `RevealEntrance`(자식마다 90ms 지연·320ms fade+6px rise, 타이핑 효과 없음) |
| 기억 조각 | `lib/core/design/dream_atmosphere.dart` `MemoryStamp` | `from` 원점(Orb 자리)에서 도착, sky500 → accentInk로 정착. `MemoryStampPainter.cellAt()` 공개 |
| 홈 커버 | `lib/core/design/dot_cover.dart` `homeCoverSpec()` | 밀도 .22+.62p, clarity .30+.60p(≤.9)로 **실제 진척**에서만 파생 |
| 기록 화면 | `lib/ui/capture/capture_flow.dart` | MongInput 토큰(raised 채움·hairline, 포커스 accent, 녹음 시 sky50 틴트+sky400 1.5px, 정적), `MongIconButton.recording`(펄스·RMS 없음), 웹 마이크 안내 `MongIconButton.glass`, 닫기 `MongIconButton.plain`, 단계 전환 `MongMotion.page`/`form`, raw `TextButton` 9개 → `MongButton.ghost`, 주 행동 `MongButton` |
| 생성 중 | 같은 파일 `_buildProcessing` | radial halo DecoratedBox 제거 → `ProcessingHalo(stage: _processingStage)` + Orb(composing 고정) |
| 결과 | 같은 파일 `_buildReveal` | `RevealEntrance(animate: _freshReveal)`로 조각 → 메타 → 세리프 제목 → 첫 문장 → 출처 순서 등장. 보관된 장면 재진입은 즉시 표시 |
| 홈 성장 | `lib/ui/home/home_screen.dart` | 히어로에 `DotCover(spec: homeCoverSpec, previous: 이전 진척 spec, transition: _growthController)`. 종이 아이콘(`memoryObject`) 제거. 컨트롤러 하나(`growth` 1400ms): 숫자는 `gather` 구간에서 카운트업, 커버는 끝까지 도착. 새 진척 영수증이 있을 때만 1회 |
| 테스트 | `test/ui/hero_motion_test.dart` | 단계별 레이아웃 반경 단조 감소·알파 증가·결정성, 단계 변경 1회 재생 후 정지, Reduced Motion 즉시 최종 프레임, 등장 stagger·완료 시 전부 가시, 조각 원점→격자 도착, 홈 spec 단조 증가·clarity 상한 |
| 골든 | `goldens/` | 변경 화면(capture/saved/processing/reveal/shell-home 등) 재생성 |

## P2-2. Before / After (시뮬레이터 iPhone 17 Pro, mock 엔진)

| 단계 | Before | After | 달라진 것 |
|---|---|---|---|
| 홈 | `before/01-home-17pro.png` | `after/01-home-17pro.png` | 종이 아이콘 → 진척 기반 도트 커버(46%) |
| 기록(빈) | `before/02-capture-empty-17pro.png` | `after/02-capture-empty-17pro.png` | 파란 박스 → paper 입력면, Sky Glass 저장, 글래스 녹음 버튼 |
| 기록(입력) | `before/03-capture-keyboard-17pro.png` | `after/03-capture-focused-17pro.png` | 포커스 테두리 accent. 입력 중 정적 유지 |
| 저장 | `before/04-saved-17pro.png` | `after/04-saved-17pro.png` | 조각 sky→ink 정착, 세리프 제목, ghost 보조 행동 |
| 생성 중 | `before/06-processing-17pro.png` | `after/05-processing-stage0-17pro.png` | Orb 주변 기억 도트(단계 0 흩어짐) |
| 생성→결과 전환 | — | `after/06-processing-to-reveal-transition-17pro.png` | 단계 3 조밀한 링이 결과로 크로스페이드, 조각이 위로 도착하는 프레임 |
| 결과 | `before/07-reveal-17pro.png` | `after/07-reveal-17pro.png` | 조각 + 리듬 등장 + 세리프 제목 |
| Reader | `before/09-reader-17pro.png` | `after/08-reader-17pro.png` | 바탕·제목만 변경(P3 범위) |
| 홈(성장 후) | `before/14-home-night-after-reader-17pro.png`(야간) | `after/09-home-after-growth-17pro.png` | 46% → 50%, 커버 도트 증가 |
| 녹화 | — | `after/flow-capture-to-growth-17pro.mp4` (84초, 720p) | 홈 → 기록 → 저장 → 생성(단계 전환) → 결과 → Reader → 홈 성장 |

## P2-3. 검증 (실제 실행)

- `dart format --output=none --set-exit-if-changed lib test tool/ui_catalog.dart`: 130파일 변경 0
- `dart analyze lib test integration_test tool/ui_catalog.dart tool/drift_worker.dart tool/start_flow_review.dart`: No issues
- `flutter analyze --no-pub`: 기존 한글 경로 LSP crash(exit 255), 통과로 세지 않음
- `tool/check_log_safety.sh` · `tool/check_eval_privacy.sh`: OK
- `flutter test --no-pub`: **333개 통과**(P1 328 + 신규 5). 변경 화면 골든은 `goldens/`에 재생성
- `flutter test --platform chrome test/ui/capture_keyboard_test.dart`: 6개 통과(같은 EditableText·포커스·IME 유지)
- `bash tool/test_web_durability.sh`: IndexedDB commit 1개 통과
- `node --test tool/pwa_startup_test.mjs tool/pwa_install_test.mjs`: 11개 통과
- `flutter build web --release` + bootstrap 문법 검사: 통과(공개 배포 아님)
- `flutter build ios --simulator --no-codesign`: 통과
- `git diff --check`: 통과. 동결 4파일 `edfc13c`와 동일
- 시뮬레이터 iPhone 17 Pro(mock 엔진): 홈 → 기록 → 저장 → 생성 → 결과 → Reader → 홈 성장 조작, 스크린샷 9장, 84초 녹화. 실기기·실제 생성 아님

## P2-4. 남은 것 / 미검증 / 조정 후보

- 생성 중 단계 0의 도트 알파(.34)는 warm paper 위에서 희미하다. 실기기에서 보고 .40 전후로 조정할 수 있다(토큰은 `ProcessingHaloPainter.layout`).
- 결과 조각의 원점 `Offset(120, 200)`은 Orb가 있던 화면 중앙의 근사값이다. 두 단계가 같은 좌표계를 공유하지 않으므로 정확한 핸드오프가 아니라 정직한 추상 전환이다.
- 보관된 장면 재진입(`_freshReveal == false`)은 모션 없이 즉시 표시한다(의도).
- Reader·보관함·온보딩·설정의 로컬 스타일(raw TextButton 37개, Reader 야간 팔레트, GNB)은 P3에서 치환한다.
- 실기기 프레임·글래스 대비·확산광 띠 미검증. 공개 배포·커밋 없음.

---

# P3 Screen Quality — 2026-10-26

Home·Reader·Archive·Onboarding을 DESIGN.md §11 규칙으로 정리하고, `lib/ui`에 남아 있던 로컬 스타일을 Mong 컴포넌트로 치환했다. 화면 로직·저장·출처·동의 경로는 바꾸지 않았다.

## P3-1. 만든 것

| 산출물 | 경로 | 내용 |
|---|---|---|
| 공용 컴포넌트 | `lib/core/design/design_system.dart` | `MongBottomNav`(pill 바 radius 31·hairline·whisper shadow·높이 62, 선택 탭 subtle pill 22), `MongContextBar`(44px leading/trailing, 24·14·16·12), `MongListRow`(제목·설명·chevron, destructive=alert), `MongSwitchRow`(adaptive 스위치의 트랙·썸 색을 토큰으로 고정), `MongSpace.panel` 28, `MongColor.readerNightMeta/readerNightLine` |
| GNB | `lib/main.dart` | 로컬 Container/`_BottomTab` 제거 → `MongBottomNav` |
| Onboarding | `lib/ui/auth/onboarding_screen.dart` | `MongWordmark(animate: 첫 페이지)`, 바탕 `context.canvas`, 제목 세리프 display(로컬 weight/자간 제거), 설명·캡션 토큰 색, 오류 패널 `MongSurface`, 보조 행동 ghost |
| Home | `lib/ui/home/home_screen.dart` | `MongWordmark`, "오늘의 변화" 메타(`progressReasonLabel`: 실제 ProgressEvent reasons에서만 "+4% · 새 장면 · 보강 2"), 보조 행동 4개 ghost |
| Reader | `lib/ui/reader/reader_screen.dart` | 야간 팔레트를 `readerNightPaper/Meta/Line` 토큰으로(따뜻한 종이 유지), 상단 `MongContextBar` + 메뉴 tooltip, Material 드롭다운 → 한 줄 장면 선택 행 + `장면 고르기` 시트(`MongListRow`, 현재 장면 표시), 문단 메뉴 점 16px·α.55로 약화(44px 터치 유지), 구분점·출처 마커·본문을 테마/`manuscriptStyle`로, 출처 하이라이트 야간 대응, 편집·되돌리기·읽기 끝 행동 ghost |
| Archive | `lib/ui/archive/archive_screen.dart` | `+` → `MongIconButton`, 파생 장면 `ListTile` → `MongListRow`, 행 화살표 → chevron 20, 시트 행동(원문 수정·꿈 삭제·취소) ghost |
| Settings | `settings_components.dart`, `settings_screen.dart`, `appearance_screen.dart`, `generation_settings_screen.dart` | `SettingsNavigationRow` → `MongListRow`, 상세 프레임 상단 `MongContextBar`+`MongIconButton`('설정으로 돌아가기' 유지), 토글 2개 `MongSwitchRow`, 미리보기 `manuscriptStyle`, 행간 리터럴 제거, 충돌 행동 ghost |
| Library | `lib/ui/library/library_screen.dart` | 완성본 표지에 `DotCover(homeCoverSpec(volumeId, 1))`(완성 상태에도 탈락·blur 유지), radius 토큰, 본문 `manuscriptStyle`, 행동 ghost |
| 기타 | `auth_gate.dart`, `policy_link.dart`, `capture_flow.dart` 다이얼로그 | raw `TextButton` → `MongButton.ghost`. **`lib/ui`의 raw TextButton 0개** |
| 테스트 | `test/ui/screen_quality_test.dart` | GNB 형태·선택 semantics, 목록 행 44px·chevron·alert, 컨텍스트 바 배치, 진척 사유 라벨(미지 타입 무시). `reader_navigation_test`(ListTile→MongListRow), `generation_settings_test`(지연 목록 스크롤) 선택자 갱신 |

## P3-2. Before / After (시뮬레이터 iPhone 17 Pro, mock)

| 화면 | Before | After | 달라진 것 |
|---|---|---|---|
| 홈 | `before/01-home-17pro.png` | `after/p3-01-home-17pro.png` | 도트 커버, 세리프 제목, "+4% · 새 장면" 사유, Sky Glass 주 행동, pill GNB |
| 보관함 | `before/19-archive-light-17pro.png` | `after/p3-02-archive-17pro.png` | 세리프 제목, accent 필터 칩, chevron 행, 월 헤더 메타 |
| 꿈 상세 | `before/20-archive-dream-detail-17pro.png` | `after/p3-03-archive-detail-17pro.png` | 파생 장면 행 `MongListRow`, ghost 행동 |
| Reader 출처 | `before/11-reader-source-sheet-17pro.png` | `after/p3-04-reader-source-sheet-17pro.png` | 컨텍스트 바, 약해진 문단 메뉴, 출처 마커 |
| Reader 장면 선택 | `before/09-reader-17pro.png`(드롭다운) | `after/p3-05-reader-scene-picker-17pro.png` | 드롭다운 → 선택 행 + 시트 |
| 설정 | `before/18-settings-light-17pro.png` | `after/p3-06-settings-17pro.png` | `MongListRow`, chevron, pill GNB |
| 설정 상세 | `before/17-appearance-night-17pro.png`(야간, 초록 토글) | `after/p3-07-settings-detail-17pro.png` | 컨텍스트 바, accent 칩, sky500 토글(adaptive 스위치 수정) |
| 온보딩 | `before/25-entry-web390.jpg` · `before/22-consent-web390.jpg` | `after/p3-08-onboarding-entry-17pro.png` · `after/p3-09-onboarding-consent-17pro.png` | 워드마크 1회 정착, 세리프 제목, Sky Glass CTA, 따뜻한 바탕 |

## P3-3. 검증 (실제 실행)

- `dart format --output=none --set-exit-if-changed lib test tool/ui_catalog.dart`: 131파일 변경 0
- `dart analyze lib test integration_test tool/ui_catalog.dart tool/drift_worker.dart tool/start_flow_review.dart`: No issues
- `flutter analyze --no-pub`: 기존 한글 경로 LSP crash(exit 255), 통과로 세지 않음
- `tool/check_log_safety.sh` · `tool/check_eval_privacy.sh`: OK
- `flutter test --no-pub`: **337개 통과**(P2 333 + 신규 4). 변경 화면 골든은 `goldens/`에 재생성(설정 토글 수정 후 p3_system/shell/generation_settings 재생성 포함)
- `flutter test --platform chrome test/ui/capture_keyboard_test.dart`: 6개 통과
- `bash tool/test_web_durability.sh`: IndexedDB commit 1개 통과
- `node --test tool/pwa_startup_test.mjs tool/pwa_install_test.mjs`: 11개 통과
- `flutter build web --release` + bootstrap 문법 검사: 통과(공개 배포 아님)
- `flutter build ios --simulator --no-codesign`: 통과
- `git diff --check`: 통과. 동결 4파일 `edfc13c`와 동일. `lib/ui` raw TextButton 0개
- 시뮬레이터 iPhone 17 Pro(mock): 홈·보관함·꿈 상세·Reader 출처/장면 선택·설정·설정 상세·온보딩 소개/동의 조작·캡처 9장. 실기기 아님

## P3-4. 남은 것 / 미검증

- Reader 편집 시트의 `TextStyle(color: _ink/_meta)` 몇 곳과 보관함·Reader 시트의 `backgroundColor` 분기는 토큰 색을 쓰지만 아직 공용 `MongSheet` 위젯은 아니다(규격만 DESIGN.md §7.6).
- `MongInput`·`MongProgress` 전용 위젯 없음(테마/`ProcessingHalo`/`DotCover`로 표현).
- 온보딩의 `ThinkingOrb(state: connecting)` 라벨은 접근성 설명만 다르고 모양은 composing.
- 실기기: warm white·글래스 대비·세리프 가독성·프레임 미검증. 공개 배포·커밋 없음.

---

# P4 UX & Quality Validation — 2026-10-26

DESIGN.md §10·§14 기준으로 접근성 가이드라인·글자 확대·키보드·Reduced Motion을 테스트 매트릭스로 고정하고, 시뮬레이터 3기종에서 반복 확인했다. 발견한 결함은 고쳤고 확인하지 못한 항목은 미검증으로 남긴다.

## P4-1. 매트릭스 테스트 (`test/ui/quality_validation_test.dart`, 8개)

| 검사 | 범위 | 결과 |
|---|---|---|
| Flutter 접근성 가이드라인 `iOSTapTargetGuideline`(44pt)·`labeledTapTargetGuideline`·`textContrastGuideline`(4.5:1) | 홈·보관함·설정·설정 상세·Reader·기록·저장·생성 중·결과, 밝게/어둡게 | 통과. **결함 1건 발견·수정**: 메타 잉크 `#74716B`가 기록 헤더의 확산광 틴트 위에서 4.22:1 → `ink3 = #6B6862`(paper 5.32 / paperShade 4.96 / sky50 5.12). DESIGN.md §2.1 갱신 |
| 글자 확대 1.6×(375×667), 2.0×(375×667·390×844·430×932) | 홈·보관함·설정·Reader·기록·저장·생성·결과 overflow 0, 주 행동 화면 안에 도달 | 통과 |
| 키보드 inset 290px + 1.6× (375×667) | 같은 EditableText 유지, 저장 버튼이 키보드 위 | 통과 |
| Reduced Motion(platform `disableAnimations`) | 홈·입력 중·저장·생성·결과에서 반복 애니메이션 0, 입력 중 Orb/Halo/Stamp 없음, 결과 즉시 최종 프레임 | 통과 |

하네스는 `platformDispatcher.textScaleFactorTestValue`/`accessibilityFeaturesTestValue`로 플랫폼 값을 주입한다(MediaQuery 조상으로 감싸면 실제 view inset을 가리므로).

## P4-2. 시뮬레이터 반복 검증

| 항목 | 기기 | 결과 |
|---|---|---|
| Dynamic Type XXXL 홈 | iPhone 17 Pro · 17e · 17 Pro Max | **결함 1건 발견·수정**: 17 Pro에서 보조 행동 "꿈 기록하기"가 GNB 뒤로 잘림(`p4-01-home-xxxl-before-fix-17pro.png`). 큰 글자(16pt→>20)에서는 히어로 높이를 .54→.40, 최소 340→240으로 줄여 설명·주/보조 행동이 GNB 위에 정착(`p4-01-home-xxxl-reduce-motion-17pro.png`, `p4-05-home-xxxl-17e.png`, `p4-05-home-xxxl-17promax.png`) |
| XXXL 기록 + 키보드 | 17 Pro | 저장 버튼이 키보드 위, 에디터 유지(`p4-02-capture-keyboard-xxxl-17pro.png`). 영문 하드웨어 입력이 한글 키보드 매핑으로 들어가는 것은 시뮬레이터 입력 도구의 특성 |
| XXXL 저장→생성→결과 | 17 Pro | 통과(`p4-03-reveal-xxxl-17pro.png`) |
| OS Reduce Motion | 17 Pro | **미검증**. `simctl ui`에는 Reduce Motion 옵션이 없고 `defaults write com.apple.Accessibility ReduceMotionEnabled`는 실행 중 앱에 전달되지 않아 Orb와 단계 전환이 계속 움직였다(`p4-04-processing-crossfade-os-reduce-motion-unverified-17pro.png`). Flutter 레벨 `disableAnimations` 경로는 테스트로 검증됨. 실기기 설정에서 확인 필요 |
| 일반 크기 흐름 3기종 | 17 Pro(P2/P3 캡처), 17 Pro Max·17e(P0 Before·P4 XXXL) | 통과 |

## P4-3. 검증 (실제 실행)

- `dart format --output=none --set-exit-if-changed lib test tool/ui_catalog.dart`: 132파일 변경 0
- `dart analyze lib test integration_test tool/ui_catalog.dart tool/drift_worker.dart tool/start_flow_review.dart`: No issues
- `flutter analyze --no-pub`: 기존 한글 경로 LSP crash(exit 255), 통과로 세지 않음
- `tool/check_log_safety.sh` · `tool/check_eval_privacy.sh`: OK
- `flutter test --no-pub`: **345개 통과**(P3 337 + 매트릭스 8). ink3·히어로 변경으로 골든 재생성
- `flutter test --platform chrome test/ui/capture_keyboard_test.dart`: 6개 통과
- `bash tool/test_web_durability.sh`: IndexedDB commit 1개 통과
- `node --test tool/pwa_startup_test.mjs tool/pwa_install_test.mjs`: 11개 통과
- `flutter build web --release` + bootstrap 문법 검사: 통과(공개 배포 아님)
- `flutter build ios --simulator --no-codesign`: 통과
- `git diff --check`: 통과. 동결 4파일 `edfc13c`와 동일
- 시뮬레이터: iPhone 17 Pro(XXXL 홈·기록+키보드·저장·생성·결과), 17e·17 Pro Max(XXXL 홈). 모두 mock 엔진·로컬 인증. 실기기 아님

## P4-4. 남은 문제 (우선순위)

1. **실기기 미검증**: warm white와 시스템 바 경계, 글래스 대비, 확산광 띠, 프레임/터치 지연, OS Reduce Motion, 한글 IME, STT. 시뮬레이터·widget renderer 결과를 실기기 완료로 쓰지 않는다.
2. **하이라이트 대비**: Reader 출처 시트의 `sky100` 하이라이트 위 `ink`는 통과하지만 야간 `nightAccentSoft` 위 `nightInk`는 가이드라인 검사 범위 밖(시트는 모달이라 테스트 트리에서 열지 않음).
3. **생성 단계 0 도트 알파 .34**: 종이 위에서 희미함. 실기기 확인 후 조정 후보(P2 기록).
4. **공용 위젯 미완**: `MongSheet`·`MongInput`·`MongProgress` 전용 위젯 없음(규격만). Reader 편집 시트 색 분기 로컬.
5. **홈 히어로 스크롤**: 콘텐츠를 위로 밀면 워드마크가 상태바 아래로 들어간다(의도된 edge-to-edge지만 큰 글자에서 눈에 띔). 상단 고정 헤더로 바꿀지 결정 필요.
6. **시뮬레이터 `.app` 직접 실행 불가**: `flutter build ios --simulator` 산출물을 `simctl launch`하면 키체인 entitlement 오류(P0 기록). `flutter run`으로만 QA 가능.
7. **커밋·배포 없음**: 작업 트리 dirty(P1~P4 전체). 공개 빌드는 `20261026T111252Z` 그대로.

## P4-5. 사용자 관점 8문항 — P0 대비

| # | 질문 | P0 | P4 | 근거 |
|---|---|---|---|---|
| 1 | 일반 AI 앱과 다른 브랜드인가 | 부분 | 대체로 예 | 세리프 제목·warm white·Sky Glass·도트 커버가 모든 화면에 일관 |
| 2 | 도트가 의미 있는 인터랙션인가 | 아니오 | 예(시뮬레이터) | 커버=진척, 저장=응집, 생성=단계, 결과=도착 |
| 3 | 생성 과정이 로딩과 차별되는가 | 부분 | 예 | Orb 주변 도트가 실제 단계에 반응, 결과로 연결 |
| 4 | 원고 성장이 시각적으로 느껴지는가 | 아니오 | 예 | 커버 도트 증가 + 사유 메타 + 카운트업 |
| 5 | Reader가 독서에 적합한가 | 대체로 예 | 예 | 크롬 최소화, 장면 선택 시트, 약한 문단 메뉴, 따뜻한 밤 종이 |
| 6 | 스카이블루가 고유 인상을 만드는가 | 부분 | 예 | 선택·포커스·토글·진척 사유·빛에 일관 |
| 7 | 모션 제거해도 사용 가능한가 | 예 | 예(테스트) | 모든 레시피가 최종 프레임으로 즉시 감 |
| 8 | 일관된 에디토리얼 제품인가 | 아니오 | 대체로 예 | 로컬 스타일 0, 공용 컴포넌트·토큰만 |

"예"는 시뮬레이터·테스트 기준이며 실기기·사용자 5명 검수는 아직이다.

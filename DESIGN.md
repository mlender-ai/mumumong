---
name: MUMUMONG
version: alpha
description: 무무몽 UI의 단일 정본. 토큰 값은 규범이고 산문은 적용 맥락이다.
---

# MUMUMONG Design System

**이 문서는 모든 UI 작업의 Single Source of Truth다.** `lib/core/design/design_system.dart`의 토큰·컴포넌트는 이 문서와 1:1이어야 한다. 새 스타일이 필요하면 화면에서 임의로 만들지 말고 **여기에 먼저 추가하고 공통 컴포넌트로 만든 뒤** 화면에 쓴다. 과거 문서(`docs/MUMUMONG_VISUAL_SYSTEM_v0.1.md`, `DESIGN_SYSTEM_v0.5~v0.9`, `DESIGN_DIRECTION_vNext.md`)와 다른 부분은 §13의 결정 기록이 우선한다.

제품 규칙(일곱 단계 루프, D/C/U 출처, U 잠금, 동의/RLS, 본문 없는 로그, frozen 엔진)은 `AGENTS.md`가 정본이며 이 문서가 바꾸지 않는다.

## 1. Brand Principles

- **A dream takes form, but never fully wakes.** 꿈은 작품이 되어도 완전히 선명해지지 않는다. 완성된 표지에도 도트의 탈락·잔상·흐릿한 경계가 남는다. clarity 상한 0.9.
- **Quiet → Reactive → Quiet.** 평상시는 정지. 사용자 행동이나 실제 상태 변화(저장 성공, 작업 단계, 결과 동기화, 진척 증가)에만 반응하고 다시 정착한다. 영구 반복 장식 금지.
- **Warm White + Warm Sky Blue + Atmospheric Blur + Soft Glass + Halftone Motion + Editorial Typography.** 블루가 유일한 브랜드 색이다. 핑크·바이올렛은 독립 색으로 쓰지 않는다.
- **한 화면, 하나의 시각적 주 행동.** 보조 행동과 뒤로가기는 접근 가능하되 낮은 위계로 둔다. 카드 대시보드·동급 CTA 나열 금지.
- **입력은 정적이고 즉각적이다.** 타이핑·전사 중에는 Orb, beam, 파티클, 전면 repaint를 추가하지 않는다. 도트는 저장 순간에 응집한다.
- **차갑고 기술적인 SaaS 대시보드나 화려한 AI 챗봇 UI가 되지 않는다.** 독서와 기록이 중심이다.

## 2. Colors

### 2.1 Primitives

```yaml
colors:
  paper: "#FBFAF7"        # Level 0 canvas (warm white)
  paperPure: "#FFFFFF"    # sheets, cards, inputs
  paperShade: "#F3F2EE"   # subtle warm surface
  line: "#E8E5DF"
  ink: "#1E1D1B"
  ink2: "#55524D"
  ink3: "#6B6862"           # meta ink: ≥4.5:1 on paper, paperShade and the atmosphere's lightest tint (was #74716B, 4.2:1 over sky haze)
  alert: "#9B514B"        # destructive text only
  sky50: "#EEF7FC"
  sky100: "#DDEFF9"
  sky200: "#BFE2F5"
  sky300: "#9ED3EF"
  sky400: "#72C0E7"
  sky500: "#4FAADD"       # brand sky blue
  sky600: "#2F8FC7"       # selected / focus / links
  sky700: "#1F6FA0"       # blue ink on paper (≥4.5:1)
  sky800: "#174F73"
  orbInk: "#294E72"       # thinking orb, light theme
  lightSky: "#72CBF2"     # atmosphere
  lightDeep: "#288FD4"    # atmosphere
  lightSoft: "#5A8DD8"    # atmosphere, low-saturation blue (replaces indigo #5666CD)
  lightHaze: "#E7F7FF"    # atmosphere
  nightCanvas: "#050C18"
  nightRaised: "#111C2B"
  nightSubtle: "#152131"
  nightInk: "#E8E5DF"
  nightInk2: "#BEC7D1"
  nightMeta: "#A5B2C1"
  nightLine: "#314055"
  nightSky: "#7FA3BA"
  readerNightPaper: "#161513"   # Reader-only night paper (warm)
  readerNightMeta: "#9C9891"    # Reader-only night meta on warm paper
  readerNightLine: "#2B2926"    # Reader-only night hairline
```

### 2.2 Semantic roles (`MongPalette` on `BuildContext`)

| 역할 | 밝게 | 어둡게 | 용도 |
|---|---|---|---|
| canvas | paper | nightCanvas | 화면 바탕 |
| raised | paperPure | nightRaised | 시트·모달·입력 |
| subtle | paperShade | nightSubtle | 칩 기본, 보조 면 |
| primaryInk | ink | nightInk | 본문·제목 |
| secondaryInk | ink2 | nightInk2 | 설명 |
| metaInk | ink3 | nightMeta | 메타·라벨 |
| hairline | line | nightLine | 경계 |
| accent | sky600 | nightSky | 선택·포커스·링크·토글 on |
| accentSoft | sky100 | #203D54 | 선택 배경 |
| accentInk | sky700 | nightSky | 파란 글자 |

규칙: 주 버튼을 파란색으로 채우지 않는다. 블루는 **선택·포커스·진행·빛**에 쓴다. 텍스트 대비는 배경의 가장 밝은/어두운 픽셀 기준 4.5:1 이상.

## 3. Atmospheric Gradient Rules (Surface Level 1)

- 구현: `DreamAtmosphere` 하나. 상부 12–48%에 초점, 40–96% 구간에서 canvas로 완전히 소멸. 하단 1/3은 항상 무색의 내용 평면이다.
- 색: lightSky, lightDeep, lightSoft, lightHaze 네 개의 radial light만 쓴다. 밤은 알파만 낮춘다.
- 어디에: 소개 첫 페이지, 원고 홈 커버, 생성 중, 완성본 표지. **기록·Reader·보관함·설정에는 쓰지 않는다**(기록은 strength 0.18 정지 상태만 허용).
- 모션: 14s 주기, painter만 repaint, 30Hz 샘플링, 백그라운드·Reduced Motion·숨은 route에서 정지. 전면 BackdropFilter 금지.
- 하나의 화면에 Atmosphere는 하나. 그 위에 긴 본문을 올리지 않는다.

## 4. Typography

UI는 Pretendard, 에디토리얼 제목과 원고 본문은 MaruBuri다. 제목을 세리프로 쓰는 것이 2026-10-26 결정(§13-E)이다.

```yaml
typography:
  display:      { fontFamily: MaruBuri,   fontSize: 36px, fontWeight: 400, lineHeight: 1.2,  letterSpacing: -0.6px }
  title:        { fontFamily: MaruBuri,   fontSize: 28px, fontWeight: 400, lineHeight: 1.3,  letterSpacing: -0.4px }
  headline:     { fontFamily: MaruBuri,   fontSize: 22px, fontWeight: 400, lineHeight: 1.35 }
  subtitle:     { fontFamily: Pretendard, fontSize: 18px, fontWeight: 600, lineHeight: 1.4 }
  manuscript:   { fontFamily: MaruBuri,   fontSize: 18px, fontWeight: 400, lineHeight: 1.75 }
  body:         { fontFamily: Pretendard, fontSize: 16px, fontWeight: 400, lineHeight: 1.55 }
  description:  { fontFamily: Pretendard, fontSize: 14px, fontWeight: 400, lineHeight: 1.5 }
  action:       { fontFamily: Pretendard, fontSize: 15px, fontWeight: 600, lineHeight: 1.25 }
  chip:         { fontFamily: Pretendard, fontSize: 13px, fontWeight: 500, lineHeight: 1.4 }
  meta:         { fontFamily: Pretendard, fontSize: 12px, fontWeight: 500, lineHeight: 1.4, letterSpacing: 0.44px, fontFeature: tnum }
  wordmark:     { fontFamily: Pretendard, fontSize: 15px, fontWeight: 700, letterSpacing: 2.4px }
```

- Flutter 매핑: display→`displayLarge`, title→`displayMedium`, headline→`headlineSmall`, subtitle→`titleMedium`, manuscript→`bodyLarge`, body→`bodyMedium`, description→`bodySmall`, action→`labelLarge`, chip→`labelMedium`, meta→`labelSmall`.
- 원고 본문 크기는 `readerScale` .9/1/1.2/1.4를 `manuscript`에만 곱한다. 리더 본문 스타일은 `manuscriptStyle(context, scale)` 한 곳에서만 만든다(세 곳 중복 금지).
- 행간은 1.2/1.3/1.35/1.4/1.55/1.75 외의 값을 쓰지 않는다.
- 워드마크 'MUMUMONG'은 `MongWordmark` 컴포넌트만 사용한다(자간 2.4 고정, 정적/모션 두 모드).
- 글자 확대 1.6배에서 어떤 텍스트도 잘리거나 고정 높이에 갇히지 않는다.

## 5. Layout, Spacing, Radius, Elevation

```yaml
spacing: { xxs: 4px, xs: 8px, sm: 12px, md: 16px, lg: 24px, xl: 32px, xxl: 48px, screen: 24px, modal: 24px }
rounded: { chip: 999px, pill: 999px, field: 20px, tab: 22px, panel: 28px, sheet: 28px, nav: 31px }
```

- 4px 리듬. 화면 좌우 24px. 설명→주 행동 32px(`MongFlowPage`). 주 행동 최대 280px, 최소 높이 52px(`MongActionGroup`). 보조 행동은 주 행동 아래 8px, Wrap, 최소 44px 터치.
- 내용 최대 폭: 입력·동의·설정 620px, 홈·보관함·Reader 720px, 시트·모달 480px.
- 헤더 리듬(`MongPageHeader`): 24 / 제목 영역 최소 48 / 설명까지 8 / 아래 32.
- Elevation은 그림자 세 단계만 쓴다.

```yaml
elevation:
  whisper: "0 8px 32px rgba(30,29,27,0.04)"    # 떠 있는 pill, GNB
  float:   "0 8px 24px rgba(59,80,106,0.07)"   # glass CTA, 녹음 컨트롤
  modal:   "0 12px 40px rgba(30,29,27,0.12)"   # 시트·모달
```

## 6. Surface & Glass Levels

| Level | 이름 | 값 | 어디에 |
|---|---|---|---|
| 0 | Paper | canvas, 평면, 그림자 없음 | 기록·Reader·보관함·설정의 바탕 |
| 1 | Atmospheric | §3 | 소개·홈 커버·생성 중·완성본 표지 |
| 2 | Frosted Glass | white α .72(눌림 .82), blur σ 16, 테두리 white α .72 바깥 + slate(#62778D) α .14, float shadow | 플로팅 CTA, 선택 컨트롤, 녹음 컨트롤, 보조 패널 |
| 2b | Sky Glass | Level 2 + 내부 그라디언트 sky100 α .9 → white α .55, 상단 하이라이트 white α .9 1px | **주 행동(Primary)**. 흰 바탕에서도 유리로 읽히게 하는 틴트 |
| 3 | Elevated Glass | white α .92, blur σ 20, 테두리 white α .8, modal shadow | 중요한 선택 시트·모달. 본문 가독성을 위해 불투명도 우선 |

규칙: 글래스 위에 글래스를 겹치지 않는다. 긴 본문 위에 글래스를 올리지 않는다. 매 프레임 blur를 다시 계산하는 루프를 만들지 않는다. Reduced Transparency(iOS)에서는 α 1.0·blur 0으로 떨어진다. 이 값들은 시뮬레이터 렌더링으로 1차 확정했고 실기기 대비·성능 확인 후 조정한다.

## 7. Components

모든 컴포넌트는 `design_system.dart`에 있고 상태 Default / Pressed / Focused / Selected / Disabled / Loading을 가진다. 눌림은 scale .975 / 120ms / `enter` 커브 하나로 통일한다(제품 전체 같은 촉감). Disabled는 α .48. Loading은 라벨 자리에 Orb 16px가 아니라 **라벨 유지 + 진행 상태 텍스트**로 표현한다.

### 7.1 MongButton

| variant | 표면 | 글자 | 용도 |
|---|---|---|---|
| primary | Sky Glass(2b) | ink | 화면의 유일한 주 행동 |
| secondary | Frosted Glass(2) | ink | 동급이 아닌 보조 행동 중 버튼 형태가 필요한 것 |
| solid | ink 채움, pill | paper | 고대비가 필요한 확인(삭제 확인, 완성 확정) |
| ghost | 투명, 44px 터치 | secondaryInk(15/400) | 보조 행동 기본값. raw `TextButton` 대신 사용 |

높이 min 52(ghost 44), pill, 패딩 24/14, 아이콘 19px + 8px 간격. `EditorialButton`·`GlassActionButton`·`QuietTextButton`은 `MongButton`의 별칭으로만 남기고 새 코드에서는 쓰지 않는다.

### 7.2 MongIconButton

default(투명, 44px), glass(Level 2, 52px 원), recording(52px 원, sky glass + 정지 시 ink 사각 아이콘, 활성 테두리 sky400). 녹음 중 RMS·beam·펄스 없음.

### 7.3 MongSurface

`level: paper | atmospheric | glass | elevated`, radius 기본 panel. 글래스는 `BackdropFilter` 한 번만.

### 7.4 MongInput

fill raised, 테두리 line 1px, radius field 20, 패딩 16, 힌트 secondaryInk. Focused: 테두리 accent 1.5px. Recording: 테두리 sky400 1.5px + 내부 sky50 틴트(정적). Error: 테두리 alert + 아래 12px 메시지. 포커스·IME 조합·EditableText key를 유지한다.

### 7.5 MongChip

선택: accentSoft 채움 + accent 테두리 + ink 글자. 비선택: subtle 채움 + line 테두리. min 44px, 패딩 16/12, chip 타입.

### 7.6 MongSheet

choice / confirmation / sourceOfStory. 바탕 raised(불투명), 상단 radius 28, handle 36×4 hairline, 내용 inset 24, 최대 폭 480. 제목 headline, 본문 body. 주 행동 하나.

### 7.7 MongNavigation

bottom: pill 바(radius nav 31, hairline, whisper shadow, 높이 62), 선택 탭 subtle pill(radius tab 22). contextual: 뒤로가기 44px + 메타 + 우측 44px 메뉴, 패딩 24/14/16/12.

### 7.8 MongProgress

dotDensity(커버 밀도), coverGrowth(증가 연출), processingState(Orb + 주변 도트). 숫자는 실제 MU에서만 파생한다.

### 7.9 ThinkingOrb

`thinking_orbs` 0.2.0 `composing` 64px 하나. 작업 단계는 접근성 라벨과 **주변 도트 밀도·정렬**로만 표현한다. 연결망(connecting)·희박 궤도(working)로 바꾸지 않는다.

## 8. Dot / Halftone State System

도트는 장식이 아니라 기억의 상태다. 전면 하프톤 그리드·ASCII 패턴은 쓰지 않는다. 도트는 아래 네 자리에만 산다.

| 자리 | 상태 | 표현 |
|---|---|---|
| 원고 홈 커버 | `settled`→`grown` | `DotCover`: volume seed 고정, 밀도 = 진척, 탈락률 = 1 − clarity(상한 .9), jitter, 가장자리 blur. 모티프 마스크: abstract / door / window / moon |
| 저장 순간 | `forming`→`gathering` | `MemoryStamp` 32px 7셀이 650ms 응집. sky500으로 나타나 ink로 정착 |
| 생성 중 | `gathering`→`merging` | Orb 주변 도트가 단계에 따라 흩어짐→정렬. 모양은 Orb 고정 |
| 결과→홈 | `merging`→`grown` | 결과의 첫 문장 아래 도트가 홈 커버 쪽으로 합류(한 번, 900ms) |

```yaml
dots:
  cellMin: 2px
  cellMax: 4px
  clarityMax: 0.9
  dropoutMin: 0.1       # 완성 상태에도 남는 탈락
  edgeBlurSigma: 1.5
  inkOnSettle: ink      # sky500 → ink, 240ms
```

입력 중에는 어떤 도트도 움직이지 않는다(§13-A).

## 9. Motion Tokens & Recipes

```yaml
motion:
  micro: 120ms          # 눌림, 토글
  base: 240ms           # 색/상태 전환
  page: 420ms           # 화면 전환 (slide 5% + fade)
  settle: 650ms         # MemoryStamp 응집
  gather: 900ms         # 도트 합류, 진척 카운트업
  growth: 1400ms        # 커버 밀도 증가
  reveal: 2400ms        # 결과 문장 등장 전체 길이 (문단당 지연 90ms, 각 320ms fade+6px rise)
  atmosphere: 14s       # Level 1 반복 (유일한 반복)
curves:
  enter: cubic-bezier(0.22, 1, 0.36, 1)
  page: cubic-bezier(0.65, 0, 0.35, 1)
  form: cubic-bezier(0.33, 0, 0.15, 1)
```

레시피: Press Feedback(micro, scale .975) · Glass Surface Transition(base, α만) · Particle Gathering(settle) · Dot Morphing(gather) · Text Reveal(reveal, 타이핑 효과 금지) · Manuscript Growth(growth) · Page Transition(page). Processing → Reveal → Growth는 별개 애니메이션 세 개가 아니라 **기억이 원고로 이동하는 하나의 서사**로 이어 붙인다. Reduced Motion에서는 모든 레시피가 최종 프레임으로 즉시 간다.

## 10. Accessibility / Reduced Motion

- 터치 44×44 이상. 글자 1.6배에서 레이아웃 유지(Wrap, 스크롤).
- `MediaQuery.disableAnimations`가 true면 반복 정지, 전환 Duration.zero, 도트 정지 프레임. 로컬 위젯도 예외 없음.
- 색만으로 상태를 전하지 않는다(선택 칩은 테두리+채움, 출처는 마커+라벨).
- 라이브 리전: 저장 완료, 생성 중, 결과 도착.

## 11. 화면별 Surface 사용 규칙

| 화면 | 바탕 | 허용 |
|---|---|---|
| Onboarding | Atmospheric(첫 페이지) → Paper(동의) | 워드마크 모션, Sky Glass CTA |
| Dream Capture | Paper | MongInput, 녹음 MongIconButton.recording, 정적 |
| AI Processing | Atmospheric(약) | Orb + 주변 도트 |
| Reveal | Paper | 에디토리얼 텍스트, 문장 등장, 도트 합류 |
| Manuscript Home | Atmospheric 커버 + Paper | DotCover, 최소 메타, 진척 |
| Reader | Paper(밤: readerNightPaper) | 글래스·그라디언트 없음. 크롬 최소 |
| Archive | Paper | 에디토리얼 목록, MongChip 필터 |
| Settings | Paper | 허브→상세, MongSwitch |

## 12. Do / Don't

**Do** 블루는 선택·포커스·빛에만 · 주 행동 하나 · 글래스는 플로팅 요소에만 · 모든 색/길이/시간은 토큰 · raw `TextButton`/`Switch`/`Container` 버튼 대신 Mong 컴포넌트 · 실기기에서 대비·성능 확인.

**Don't** 파란 불투명 주 버튼 · 전면 블러·전면 도트 · 타이핑 중 모션 · 가짜 퍼센트·타이머 · 영구 반복 장식 · 글래스 중첩 · 긴 본문 위 글래스 · 화면 로컬 TextStyle/Color/Duration · 핑크·바이올렛 브랜드 색 · Reader에 그라디언트.

## 13. 결정 기록 — 2026-10-26 (지시서 vs 이전 정본)

| | 결정 | 대체되는 규칙 |
|---|---|---|
| A | 도트는 커버·저장·생성→결과 전환에 복원. 입력 중 정적 유지 | vNext "작은 오브젝트 한 곳" 확대. HANDOFF 입력 정적 규칙은 유지 |
| B | Orb는 composing 고정. 단계는 주변 도트 밀도로 | 10/26 Orb 결정 유지 |
| C | 바탕을 warm white `#FBFAF7`로. 시스템 바·PWA theme-color·index.html을 같은 값으로 묶음 | 10/08 `#FFFFFF` 고정 |
| D | 인디고 `#5666CD` → `#5A8DD8`(저채도 블루) | v0.8 라일락 빛 |
| E | 제목(display/title/headline)만 MaruBuri 세리프, UI 라벨은 Pretendard | vNext 산세리프 제목 |
| F | 감정 공감 단계는 구현하지 않음(차이만 기록) | — |
| G | `dot_field.dart` 복원 대신 `DotCover` 신설 | — |
| H | 이 문서가 토큰 정본. `design_system.dart`는 이 문서를 따라 바꾼다 | CLAUDE.md "토큰 값 변경 금지" |
| I | 소개 첫 페이지에 워드마크 모션 추가, 동의·설정 구조 유지 | — |

## 14. Visual QA Acceptance Criteria

1. `tool/ui_catalog.dart`에서 모든 variant·state·Surface level·Dot 상태·Reduced Motion이 한 화면에서 확인되고 golden이 있다.
2. 소형(375×667)·일반(390×844)·대형(430×932 이상)과 글자 1.6배에서 overflow 0.
3. 입력 중 프레임에 Orb/도트/blur 변화 없음(테스트로 고정).
4. Reduced Motion에서 반복 애니메이션 0, 전환 즉시.
5. 하드코딩 Color/Duration/TextStyle이 `lib/ui`에 없다(`tool/check_design_tokens.sh`로 검사 예정).
6. 실기기: 글래스 대비 4.5:1, 확산광 띠·밴딩 없음, 홈/기록 60fps 체감. 시뮬레이터 캡처만으로 완료로 쓰지 않는다.
7. Before/After 스크린샷과 핵심 인터랙션 녹화가 `docs/ux-review/<date>/`에 있다.

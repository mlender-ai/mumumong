# MUMUMONG Design System v0.8

2026-10-19 · 레퍼런스 재대조와 온보딩/Orb 검토 경로. v0.7의 제품·접근성·상태 계약은 유지하고 아래 재질/빛/소개 규격만 대체한다. 운영 배포 문서가 아니다.

## 1. 참고 소스와 적용 판단

사용자가 전달한 `무무몽_디자인레퍼런스/IMG_0738.JPG`–`IMG_0744.JPG`를 직접 비교했다. 0738/0739의 상부 하늘빛과 아래 여백, 0740의 비대칭 인디고 초점, 0741의 작은 부유 오브젝트, 0742–0744의 분리된 처리 오브젝트를 조합한다. 화면 전체를 같은 농도의 블러로 덮거나 본문 위에 입자를 올리지 않는다.

공개 GitHub MD는 **커뮤니티의 관찰 문서**이며 해당 브랜드의 공식 디자인 시스템이 아니다. 문서/브랜드를 그대로 복제하지 않고 현재 코드와 충돌하지 않는 원칙만 취했다.

| 확인한 원문 | 적용 | 가져오지 않는 것 |
|---|---|---|
| [awesome-design-md / ElevenLabs](https://github.com/VoltAgent/awesome-design-md/blob/main/design-md/elevenlabs/DESIGN.md) | 절제된 제목 무게, 넉넉한 여백, 둥근 행동, 제한된 분위기 재질 | 크림색 전체 바탕·세리프 UI·검정 주 버튼 |
| [awesome-design-md / Stripe](https://github.com/VoltAgent/awesome-design-md/blob/main/design-md/stripe/DESIGN.md) | 상단 색 초점과 아래 명료한 콘텐츠/행동 영역 분리 | 마젠타 팔레트·보라색 채움 CTA·B2B 대시보드 |
| [Libraries.dev Orbs](https://libraries.dev/orbs) | 64px 처리 오브젝트, 상태별 모션, 속도·정지·밝은/어두운 비교 | 입력 중 반복 효과·가짜 처리 상태 |

Clay MD는 Clay.com의 B2B 사례라 주 참고에서 제외했고 Oura의 흙빛/크림·세리프도 현 브랜드와 달라 제외했다.

## 2. 토큰과 재질

공유 정의는 `lib/core/design/design_system.dart`. 화면/시트는 `canvas/raised/subtle/primaryInk/secondaryInk/metaInk/hairline` 의미 역할을 쓴다. 바탕 밝게 #FFFFFF, 어둡게 #050C18; 본문 #1E1D1B/#E8E5DF. GNB와 시스템 영역은 동일 canvas 역할을 유지한다. Reader 밤 종이는 #161513 유지.

- UI Pretendard / 원고 MaruBuri. 소개 36/1.20·500·자간 -1; 화면 제목 28/1.30·600, 시트 22/1.35, 상태 18/1.40, UI 본문 16/1.55, 설명 14/1.50, 행동 15/1.25, 메타 12/1.40, 원고 18/1.75. 글자 확대를 막지 않는다.
- 4px 리듬 `4/8/12/16/24/32/48`; 화면/시트 여백 24px. 최소 터치 44px. 주 행동 최소 높이 52px(고정 아님), pill. 입력 radius20 / 패널28 / 모달 최대 폭480. 입력·동의·설정 최대620, 홈/Reader720.
- `GlassActionButton`/`EditorialButton` 공통 renderer. 밝은 면은 #F4F8FC .66 → 흰색 .42, 누르면 .80/.64. 18px backdrop blur, 1px slate 경계 .14, #3B506A 그림자 .07·blur24·offset(0,8). 채움 블루/푸른 발광 테두리는 쓰지 않는다. 눌림 .975/120ms, 튀는 복원 없음. 야간은 밝은 잉크와 낮은 투명 흰색 면.
- 처리용 `orbInk #294E72`, 야간 #C8E6FA. 옅은 하늘색 자체를 입자 잉크로 쓰지 않아 밝은 바탕에서 사라지지 않게 한다.

## 3. 빛과 오브젝트

`DreamAtmosphere`가 비대칭 상부 인디고 #5666CD, 블루 #288FD4, 스카이 #72CBF2, 흰빛 #E7F7FF를 그린다. field 높이 40–96%에서 canvas로 소멸하고 상단 12%는 같은 시스템 바탕에서 이어진다. 소개 field는 화면 72%(330–680px). 홈은 기존 큰 라운드 표지와 16px inset을 유지한다.

소개/표지의 작은 반투명 원고 조각은 Painter 벡터다. Orb가 아니며 진행률을 뜻하지 않는다. 제목/본문과 겹치면 안 되므로 소개 글자 확대 1.25배 초과에서 숨긴다. 14초 중심 이동·작은 회전은 RepaintBoundary/CustomPainter만 갱신하고 부모를 프레임마다 재구성하지 않는다. 동작 줄이기에서는 정지한다.

입력과 음성 전사는 계속 정적이다. 키보드에서 약한 배경 빛도 숨긴다. 저장 성공의 기존 32px/650ms MemoryStamp만 유지한다. 전면 도트/ASCII/halftone은 복원하지 않는다.

## 4. 흐름과 Orb 확인

생산 화면의 주 행동 계약은 v0.7 유지. **빈 홈은 ‘꿈 기록하기’ 하나가 주 행동**이고 의미 없는 이어 읽기/42% 예시를 표시하지 않는다. 실제 미열람 결과가 있을 때는 새 장면 읽기가 주 행동이다.

로컬 `tool/visual_preview.dart`는 소개 → 가상 고지(두 개별 체크) → 실제 첫 원고 설정 UI → 빈 홈 → 기록 → 저장 → 명시적 생성 → 처리 → 결과 → Reader 순서다. 설정에서 ‘온보딩 다시 보기’로 로컬 Memory만 초기화한다. 실제 계정/정책/동의/CloudSync gate의 기본 동작을 우회하지 않는다.

소개와 검토용 설정의 **Orb 모션 보기**는 독립 컴포넌트 리뷰다. 9개 상태 working/searching/solving/listening/connecting/weaving/composing/breathing/shaping, .5–1.5배 속도, 정지/재생, 밝은/어두운 바탕을 비교한다. Orb는 상단에 고정하고 조절 영역만 스크롤한다. 기기 동작 줄이기에서는 정지/속도 조절을 비활성화하고 이유를 표시한다.

사용 라이브러리는 [leofmarciano의 Flutter 포트](https://github.com/leofmarciano/thinking_orbs) `thinking_orbs 0.2.0`, native64px. Libraries.dev 원본 React를 실행하거나 픽셀 단위로 동일하게 이식했다는 뜻은 아니다. 생산의 Orb는 실제 처리/네트워크 대기에만 사용하며 리뷰 화면은 ‘실제 생성 작업 아님’을 명시한다.

검토용 mock 단계 지연은 4초씩으로 상태를 볼 시간을 확보했다. 실제 처리 시간·완료율·모델 품질의 증거가 아니다. 결과 본문은 입력과 무관한 고정 합성 예시이며 새로고침하면 초기화된다. 서버·AI 호출과 Outbox worker는 없다. 실제 소설 테스트에는 이 빌드를 배포하지 않는다.

## 5. 검증과 한계

### 첫 꿈 경험 보완 — 2026-10-23

저장 성공 안내는 기록만 보관하는 선택을 수용한다. 해당 권에 로컬 반영된 장면이 하나일 때 첫 리빌은 +% 대신 장면 읽기·원문 보관을 강조한다. 첫 장면 Reader 끝의 주 행동은 ‘읽기 마치기’, 보조 행동은 실제 D 출처의 ‘꿈 원문 다시 보기’다. 읽기 종료는 작품 완결이나 완독 측정이 아니다. 홈 스크롤 영역은 실제 GNB inset을 피하고 큰 표지 높이는 유지한다. AI 감정 응답·분량 정책·생성 본문은 변경하지 않았다. [실행과 검증](ux-review/2026-10-22-first-dream/README.md).

[2026-10-19 검토 기록](ux-review/2026-10-19-design/README.md)에 실행 결과와 화면을 분리 기록한다. 실제 iPhone/PWA 시스템 영역·키보드·프레임/터치 지연, hosted 계정/AI/RLS와 소설 충실도는 이번에 검증하지 않았다. 로컬 리뷰를 생산 통합 완료라고 표현하지 않는다.

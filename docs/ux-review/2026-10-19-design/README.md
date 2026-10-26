# 레퍼런스 재대조 · 온보딩과 Orb 검토

2026-10-19 KST. 사용자 요청의 디자인/전체 흐름 검토만 우선했다. P4 잔여 기능을 완료한 것이 아니며 공개 Vercel은 **재배포하지 않았다**. 로컬 리뷰는 Memory/mock, 합성 정책, 고정 본문이고 계정·서버·AI 호출이 없다. 이 리뷰를 실제 소설 생성 체험용으로 게시하지 않는다.

## 직접 볼 경로

로컬 [디자인 검토](http://127.0.0.1:4205/)가 온보딩 첫 장에서 시작한다. 시작하기 → 가상 고지 두 개별 체크 → 첫 원고 기본/상세 설정 → 원고 없는 홈 → 꿈 기록/저장 → 명시적 생성 → Orb → 새 장면 → Reader. 설정의 ‘온보딩 다시 보기’는 이 Memory 세션만 초기화한다. 다른 기기에서는 이 localhost 주소로 접속할 수 없다.

소개/검토 설정의 ‘Orb 모션 보기’는 9상태 선택·.5–1.5배 속도·정지/재생·밝은/어두운 바탕을 제공한다. 실제 처리 화면과 달리 컴포넌트 리뷰임을 명시한다. 사용 코드는 `thinking_orbs 0.2.0` Flutter 포트이며 원본 React 실행이 아니다.

## 참고와 적용

첨부 7장(IMG_0738–0744)을 육안 대조했다. [ElevenLabs MD](https://github.com/VoltAgent/awesome-design-md/blob/main/design-md/elevenlabs/DESIGN.md)의 절제된 타이포/둥근 행동, [Stripe MD](https://github.com/VoltAgent/awesome-design-md/blob/main/design-md/stripe/DESIGN.md)의 상단 색 초점/깨끗한 아래 영역을 현재 스카이·라일락에 맞췄다. 두 MD는 브랜드 공식 명세가 아닌 공개 커뮤니티 분석이다. [Libraries.dev Orbs](https://libraries.dev/orbs) 상태/조절 범위를 대조했다. 세리프 UI·검정/보라 채움 CTA·크림 바탕·B2B 카드 대시보드는 도입하지 않았다.

구체 토큰·크기·재질·모션·검토/생산 경계는 [디자인 시스템 v0.8](../../MUMUMONG_DESIGN_SYSTEM_v0.8.md).

## 전후와 브라우저 증거

| 화면 | 이전 기준 | 이번 기준 |
|---|---|---|
| 소개 | [P3](../2026-10-18-p3/day-390-844-normal-entry.png) | [현재](day-390-844-normal-entry.png) |
| 야간 소개 | [P3](../2026-10-18-p3/night-390-844-normal-entry.png) | [현재](night-390-844-normal-entry.png) |
| 큰 글자 | [P3](../2026-10-18-p3/day-375-667-large-entry.png) | [장식 숨김](day-375-667-large-entry.png) |
| 처리 | [P4](../2026-10-18-p4/day-390-844-normal-processing.png) | [대비 조정](day-390-844-normal-processing.png) |

브라우저 390×844에서 [소개](browser-onboarding.jpg) → [가상 고지](browser-consent.jpg) → [첫 원고](browser-setup.jpg) → [빈 홈](browser-empty-home.jpg) → [합성 입력](browser-capture.jpg) → [처리](browser-processing.jpg) → [고정 예시 결과](browser-reveal.jpg) → [해당 Reader](browser-reader.jpg)를 조작했다. 처음 처리 캡처는 페이드 중이어서 버리고 둘째 합성 기록에서 안정된 처리 화면으로 다시 촬영했다. 입력한 유리 서점/종이 숲이 결과 본문에 반영되는 AI 시험이 아니다.

[Orb 조절 화면](browser-orb-review.jpg), [야간](browser-orb-night.jpg), [실제 브라우저 Orb 녹화](orb-motion.gif). 녹화는 24개 실제 스크린샷을 약 1.38초 동안 얻어 17fps GIF로 묶었다. 이 수치는 앱 FPS/성능 측정이 아니며 native64px 오브젝트를 확대·합성하지 않았다.

## 실제 실행한 검증

- 최종 `flutter test --no-pub --reporter expanded`: **221개 통과**, P4 217 + 새4. 새 검사는 빈 Memory/선택 설정, 소개·동의·설정·빈 홈·초기화, 모든9상태/야간/동작 줄이기, 실제 raster 프레임 변화와 정지 후 동일 프레임을 확인한다. 기존 preview4개도 새 온보딩 경로로 변경해 통과했다.
- day/night × 375×667·390×844·430×932·1200×800·375×667 1.6배 글자: 흐름50+공통50 및 별도 소개/고지2 **102개 golden** 생성·재비교. 키보드·모션·동작 줄이기 테스트 포함. 별도 합성 도구14장 생성·재비교. `01–14` 도구 캡처와 공통 fixture는 seeded 원고를 사용하므로 ‘빈 홈’의 증거는 browser-empty-home이다. 기존 P3/P4 캡처는 덮어쓰지 않았다.
- `dart format --output=none --set-exit-if-changed lib test tool/visual_preview.dart tool/orb_motion_review.dart tool/ux_baseline_capture_test.dart`: 107파일 변경 없음.
- `dart analyze lib test integration_test tool/visual_preview.dart tool/orb_motion_review.dart tool/ux_baseline_capture_test.dart`: No issues found.
- `flutter build web --release --no-pub`, preview 별도 release, `flutter build ios --simulator --no-codesign --no-pub`: 통과. 마지막 큰 글자 장식 숨김 이후 preview도 재빌드했다.
- privacy/log guards, `git diff --check` 통과. edfc13c 대비 frozen write/plan/opening_expansion/opening_polish 네 파일 diff 없음. 평가 데이터는 열거나 출력하지 않았다.
- 브라우저에서 composing·정지/재생·야간, 소개→결과/Reader를 실제 조작했고 error/warn 로그는 없었다. 최신 preview 재빌드 후 새로고침해 소개 첫 장을 확인하고 검토 탭으로 남겼다. 동작 줄이기는 widget raster 검사이며 실제 iOS 설정 검사는 아니다.

### 실패·미검증

- `flutter analyze --no-pub`는 한국어 원본 경로에서 기존 LSP JSON 파싱 오류로 exit255. 직접 Dart 분석 성공과 구분한다. ASCII 사본 성공으로 원본 성공을 주장하지 않는다.
- 첫 검토 테스트는 lazy ListView에서 Orb가 스크롤 밖으로 unmount되는 문제와 체크 뒤 pump 누락으로 실패했다. Orb 고정/컨트롤만 스크롤 및 테스트 대기를 수정한 뒤 최종221개 통과했다. 작은 화면 큰 글자와 오브젝트 겹침을 발견해 소개 장식을 숨기고 golden 재비교했다.
- 물리 iPhone/PWA 상태바·키보드·STT·터치 지연/frame timing, hosted 계정/동의/AI/RLS, 입력 충실도/문학적 품질, 사용자5명 검수는 **미검증**. 네이티브 통합 시나리오는 이번에 재실행하지 않았다(기존7+1은 P4 기록).
- 공개 배포/commit/push 없음. 서버 엔진/프롬프트/모델/SQL/Q/실제 원고 DB 변경 없음. 실제 인증/고지/첫 원고 생성 기본 callback은 유지한다.

## 재현

```sh
flutter test --no-pub
flutter test --no-pub tool/ux_baseline_capture_test.dart
flutter build web --release --no-pub --target tool/visual_preview.dart --output build/design-review
python3 -m http.server 4205 --bind 127.0.0.1 --directory build/design-review
```

현재 golden 경로는 이 날짜 디렉터리다. 이전 보고서 재현 명령은 역사적 코드/기준선용이며, 새 캡처를 옛 증거 폴더에 생성하지 않는다. `--update-goldens`는 의도적인 기준 갱신에만 사용한다.

다음 기능 범위는 기존 P4 잔여(영속 결과 소비/오프라인 복원·이후 생성 설정·worker/지원 알림)다. 디자인 시안의 사용성/무드는 사용자 검토 전 확정하지 않는다.

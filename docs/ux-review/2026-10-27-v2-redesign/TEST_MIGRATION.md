# V1 UI 테스트 → V2 이관 지도

2026-10-27 · 브랜치 `redesign/mumumong-v2`

V1이 기본 빌드인 동안 V1 테스트는 지우지 않는다. V2가 같은 사용자 규칙을 지키는지 V2 화면 위에서 다시 증명하는 것이 이관이다. 기본값을 `UI=v2`로 바꾸는 시점에 “V1 시각 전용” 테스트와 V1 화면을 함께 정리한다.

## 분류

| 분류 | 뜻 | 처리 |
|---|---|---|
| 공유 로직 | V1·V2가 같은 코드를 쓴다(동의 정책, 자동저장 클래스, 관문 규칙, BookStore 등) | 그대로 둔다. 이관 대상이 아니다 |
| 대응 있음 | 같은 규칙을 V2 테스트가 이미 증명한다 | V2 테스트 이름을 적어 둔다 |
| 이번 이관 | 이번 단계에서 V2 테스트로 옮겼다 | `test/v2/`에 같은 이름으로 있다 |
| 다음 이관 | V2에 같은 동작이 있지만 아직 테스트가 없다 | 우선순위 순서로 아래 목록에 둔다 |
| V1 시각 전용 | V1 디자인 시스템(`DESIGN.md`)의 토큰·오브·그라데이션·골든을 검사한다 | V2는 `design_test`·`components_test`·`quality_test`가 맡는다. V1 제거 때 삭제 |

## 파일별

| V1 파일 | 테스트 수 | 분류 | V2 쪽 |
|---|---|---|---|
| `ai_consent_test` | 3 | 공유 로직 | 정책·동의 기록 파싱은 V1·V2 공용 |
| `auth_gate_test` | 8 | 대응 있음 7, 이번 이관 1 | `gates_test` 전부. “고지 응답이 늦어도 Apple 시작 화면은 즉시 보인다”는 이번에 옮겼다 |
| `auth_transition_visual_test` | 2 | V1 시각 전용 | `gates_test` 가이드라인 |
| `capture_keyboard_test` | 3 | 다음 이관 (1순위) | 자동저장 실패 표시, IME 조합 유지, 초안 읽기 실패 재시도 |
| `design_foundation_test` | 9 | V1 시각 전용 | `design_test`, `components_test` |
| `design_review_test` | 4 | V1 시각 전용 | V1 디자인 검토 도구 |
| `design_system_test` | 5 | V1 시각 전용 | `components_test`, `quality_test` |
| `draft_autosave_test` | 12 | 공유 로직 6, 다음 이관 6 | `DraftAutosave` 직접 테스트는 공용. 화면 테스트(이어쓰기 한 번만 묻기, 음성 전사 표시, 늦은 음성 시작, 저장 실패 재시도, 입력 시 전사 중단, 일시 실패 재시도)는 V2 기록 화면으로 옮긴다 |
| `dream_flow_visual_test` | 4 | V1 시각 전용 | `quality_test` 동작 줄이기 |
| `first_dream_experience_test` | 4 | 다음 이관 (2순위) | 첫 꿈만 저장, 첫 결과와 출처, 기존 원고에는 첫 결과 후기 없음 |
| `flowing_gradient_test` | 5 | V1 시각 전용 4, 대응 있음 1 | 홈의 기록 진입은 `flow_test`·`quality_test` |
| `generation_settings_test` | 5 | 대응 있음 | `settings_test` 이후 장면 설정 4개와 가이드라인 |
| `hero_motion_test` | 5 | V1 시각 전용 | `design_test` 스웜·하프톤 |
| `mobile_delivery_test` | 7 | 공유 로직 1, V1 시각 전용 3, 다음 이관 3 | PDF 글꼴 자산은 공용. 숨은 홈 정지, 배경 진입 시 대기 정지, 웹 음성 안내 문구는 옮긴다 |
| `onboarding_visual_test` | 1 | V1 시각 전용 | `gates_test` 가이드라인 |
| `p3_flow_test` | 6 | 이번 이관 1, 다음 이관 5 | 첫 원고 설정 실패 후 선택 유지는 이번에 옮겼다. 설정 후 리더 갱신, 문단 고치기 실패, 저장·보강·이어쓰기, 결과 후 행동 전환, 정책 링크 복사는 다음 |
| `p3_system_visual_test` | 1 | V1 시각 전용 | `quality_test` |
| `p4_generation_recovery_test` | 3 | 다음 이관 (1순위) | 재시도 확인 대기 중 닫기, 21초 이탈·복귀, 새 컨테이너 재연결 |
| `presentation_consumption_test` | 5 | 이번 이관 | `presentation_test` 5개. V2는 공개가 공개 영수증만, 홈이 성장 영수증을 쓴다(DESIGN_V2 §11.1) |
| `processing_state_test` | 3 | 이번 이관 | `processing_test` 3개 |
| `quality_validation_test` | 4 | 대응 있음 | `quality_test` |
| `reader_edit_test` | 2 | 대응 있음 1, 다음 이관 1 | 고치기·U 잠금은 `flow_test`. 취소 시 원고 유지와 출처 시트 스크롤은 다음 |
| `reader_navigation_test` | 8 | 대응 있음 1, 다음 이관 7 (1순위) | 위치 저장은 `flow_test`. 큰 글자 복원, 저장 디바운스, 삭제된 문단·장면 대체, 글자 크기 변경 중 고정, 오류 재시도, 잘못된 장면 차단, 오프라인 읽기 |
| `repository_wiring_test` | 4 | 대응 있음 3, 다음 이관 1 | 홈·리더·기록→공개는 `flow_test`. 보관함 월별 묶음과 필터는 다음 |
| `screen_quality_test` | 4 | V1 시각 전용 3, 대응 있음 1 | 진척 사유는 `design_test` |
| `shell_layout_test` | 3 | V1 시각 전용 1, 대응 있음 1, 이번 이관 1 | 큰 글자 보관함은 `quality_test`. 홈 대기 요약은 `home_setup_test` |
| `start_flow_simplification_test` | 5 | 대응 있음 2, 이번 이관 1, V1 시각 전용 2 | 동의 세부는 선택·체크 두 개는 `gates_test`. 첫 원고 실패와 중복 시작 방지는 `home_setup_test` |
| `visual_preview_test` | 4 | V1 시각 전용 | 은퇴한 V1 미리보기 도구 |
| `widget_test` | 3 | 대응 있음 | `flow_test`, `quality_test` 키보드 |

## 통합 테스트 (실기기·시뮬레이터, `integration_test/`)

8개 모두 V1 화면을 띄운다. 네이티브 SQLite·키체인·음성 채널을 쓰므로 V2 판도 시뮬레이터에서 돌려야 한다. 다음 단계의 실기기 검증과 함께 옮긴다: 기록→공개 4종, 완성본 재시작·PDF·다음 권, 자동저장 재시작, 이후 장면 설정 재시작, 기기 마이크, 저장·보강 재시작, 긴 생성 이탈·복귀, 리더 위치 재시작.

## 다음 이관 순서

1. 데이터 손실과 생성 중복을 막는 것: `capture_keyboard` 3, `p4_generation_recovery` 3, `draft_autosave` 화면 6.
2. 읽기 경험: `reader_navigation` 7, `reader_edit` 1.
3. 첫 사용과 흐름: `first_dream_experience` 4, `p3_flow` 5, `repository_wiring` 1, `mobile_delivery` 3.
4. 통합 테스트 8.

## 진행

| 단계 | V2 테스트 | 옮긴 V1 테스트 |
|---|---|---|
| 1차 (2026-10-27) | `processing_test` 3, `presentation_test` 5, `home_setup_test` 2, `gates_test` +1 | 11 |

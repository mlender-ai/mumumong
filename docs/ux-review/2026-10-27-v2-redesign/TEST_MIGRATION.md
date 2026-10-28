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
| `capture_keyboard_test` | 3 | 이관 완료 (2차) | `capture_input_test`: 자동저장 실패 표시, IME 조합 유지(3개 화면 크기), 초안 읽기 실패 재시도(멈춤 포함) |
| `design_foundation_test` | 9 | V1 시각 전용 | `design_test`, `components_test` |
| `design_review_test` | 4 | V1 시각 전용 | V1 디자인 검토 도구 |
| `design_system_test` | 5 | V1 시각 전용 | `components_test`, `quality_test` |
| `draft_autosave_test` | 12 | 공유 로직 5, 이관 완료 7 (2차) | `DraftAutosave`를 직접 부르는 5개(저장 실패 재시도, 일시 실패 재시도, 제출·폐기 대기, 파일 DB 재시작)는 공용. 화면 7개는 `capture_input_test`: 선택만 바뀌면 저장 안 함, 500ms·백그라운드 저장, 이어쓰기 한 번만 묻기, 새로 쓰기와 음성 즉시 저장, 음성 전사 표시, 늦은 음성 시작, 입력 시 전사 중단 |
| `dream_flow_visual_test` | 4 | V1 시각 전용 | `quality_test` 동작 줄이기 |
| `first_dream_experience_test` | 4 | 이관 완료 4 (4차) | `first_use_test`: 첫 꿈만 저장, 첫 결과·출처·다음 꿈, 기존 원고에는 첫 결과 후기 없음, 첫 결과와 읽기 끝의 접근성(10개 화면 조건). V1 골든 비교는 V2 가이드라인 검사로 바꿨다 |
| `flowing_gradient_test` | 5 | V1 시각 전용 4, 대응 있음 1 | 홈의 기록 진입은 `flow_test`·`quality_test` |
| `generation_settings_test` | 5 | 대응 있음 | `settings_test` 이후 장면 설정 4개와 가이드라인 |
| `hero_motion_test` | 5 | V1 시각 전용 | `design_test` 스웜·하프톤 |
| `mobile_delivery_test` | 7 | 공유 로직 1, V1 시각 전용 3, 이관 완료 3 (4차) | PDF 글꼴 자산은 공용. `first_use_test`: 배경 전환 중 프레임 없음과 입력 유지, 숨은 홈 정지, 웹 음성 안내 |
| `onboarding_visual_test` | 1 | V1 시각 전용 | `gates_test` 가이드라인 |
| `p3_flow_test` | 6 | 이관 완료 6 (4차) | `first_use_test`: 설정 후 리더 종이 갱신, 첫 원고 기본값과 사용자 설정의 재시도 유지, 문단 고치기 실패 시 입력 유지와 되돌리기, 저장·보강·이어쓰기의 명시적 생성, 읽은 새 장면의 카드 전환, 정책 링크 복사. 1차 지도는 이 중 1개를 옮겼다고 적었지만 실제로 옮긴 것은 `start_flow`의 비슷한 테스트였다 |
| `p3_system_visual_test` | 1 | V1 시각 전용 | `quality_test` |
| `p4_generation_recovery_test` | 3 | 이관 완료 2 (2차), 공유 로직 1 | `recovery_test`: 재시도 확인 대기 중 닫기, 21초 이탈·복귀. 새 컨테이너 재연결은 화면 없는 Provider 테스트라 공용 |
| `presentation_consumption_test` | 5 | 이번 이관 | `presentation_test` 5개. V2는 공개가 공개 영수증만, 홈이 성장 영수증을 쓴다(DESIGN_V2 §11.1) |
| `processing_state_test` | 3 | 이번 이관 | `processing_test` 3개 |
| `quality_validation_test` | 4 | 대응 있음 | `quality_test` |
| `reader_edit_test` | 2 | 대응 있음 1, 이관 완료 1 (3차) | 고치기·U 잠금·되돌리기는 `flow_test`. 취소 시 원고 유지와 출처 시트는 `reader_test` |
| `reader_navigation_test` | 8 | 이관 완료 8 (3차) | `reader_test`: 보관함 꿈별 장면, 큰 글자 복원, 저장 디바운스·백그라운드 저장, 삭제된 문단·장면 대체, 글자 크기 변경 중 고정, 오류 재시도, 잘못된 장면 차단, 홈 재시도·빈 필터·오프라인 읽기. 1차 지도의 “대응 있음 1”도 V2 화면에서 다시 증명했다 |
| `repository_wiring_test` | 4 | 대응 있음 3, 이관 완료 1 (4차) | 홈·리더·기록→공개는 `flow_test`. 보관함 월별 묶음과 필터는 `first_use_test` |
| `screen_quality_test` | 4 | V1 시각 전용 3, 대응 있음 1 | 진척 사유는 `design_test` |
| `shell_layout_test` | 3 | V1 시각 전용 1, 대응 있음 1, 이번 이관 1 | 큰 글자 보관함은 `quality_test`. 홈 대기 요약은 `home_setup_test` |
| `start_flow_simplification_test` | 5 | 대응 있음 2, 이번 이관 1, V1 시각 전용 2 | 동의 세부는 선택·체크 두 개는 `gates_test`. 첫 원고 실패와 중복 시작 방지는 `home_setup_test` |
| `visual_preview_test` | 4 | V1 시각 전용 | 은퇴한 V1 미리보기 도구 |
| `widget_test` | 3 | 대응 있음 | `flow_test`, `quality_test` 키보드 |

## 통합 테스트 (시뮬레이터·실기기, `integration_test/`)

V1 파일 8개는 그대로 두고, 같은 이름의 V2 판을 `integration_test/v2/`에 두었다(5차). 공용 준비는 `integration_test/v2/harness.dart`다. 모두 QA 시뮬레이터 “MUMUMONG V2 QA”에서 돈다. 데이터는 임시 폴더의 SQLite 파일과 지어낸 꿈뿐이고, 엔진은 고정 mock이다.

| V1 파일 | 테스트 | V2 판이 증명하는 것 |
|---|---|---|
| `capture_to_reveal_test` | 1(엔진 케이스 4) | V2 기록→저장→장면 만들기→공개→리더. 실패 케이스는 공개 없이 재시도와 “꿈은 보관함에 저장” |
| `completed_book_test` | 1 | 완성본이 SQLite 재열기 후에도 남고 실제 글꼴 자산으로 PDF를 만든다. V2 완성본 화면의 “다음 권 시작”이 2권을 열고 첫 화면으로 돌아간다. 공유 시트는 열지 않는다 |
| `draft_autosave_test` | 1 | V2 기록 화면 자동저장이 SQLite 파일 재열기 뒤 “이어서 쓰기”로 복원되고 “새로 쓰기”가 지운다 |
| `generation_settings_test` | 1 | V2 설정 → 이후 장면 설정 저장이 재열기 뒤에도 남고 다음 작업에 버전 2가 찍힌다. 기존 원고와 U 문단은 그대로 |
| `native_voice_entry_test` | 1 | 네이티브 V2 기록 화면의 녹음 버튼이 웹 안내 없이 바로 인식을 시작하고, 인식을 쓸 수 없으면 안내 후 움직임 없이 멈추며 입력·자동저장이 그대로다. 실제 마이크·인식 정확도 시험은 아니다 |
| `p3_saved_flow_test` | 2 | 저장·기억 보강이 재열기 뒤에도 남고 생성 요청은 “장면 만들기” 전까지 0회. 두 번째 V1 테스트(환경설정 채널)는 화면이 없는 공용 로직이라, V2 판은 V2 읽기 설정 화면에서 고른 값이 네이티브 환경설정 채널을 거쳐 다시 읽히는지로 바꿨다 |
| `p4_generation_recovery_test` | 2 | V2 셸에서 긴 생성을 21초 기다린 뒤 떠나도 끝까지 완료되고, 재열기 후 홈의 “새 장면 읽기”가 바로 그 장면을 열어 첫 읽음을 남긴다. 이미 보인 공개는 재시작 뒤 “원고에 보관된 장면”으로 조용하고 읽음 표시를 남기지 않는다 |
| `reader_resume_test` | 1 | V2 리더 위치가 경로 닫기와 SQLite 재열기 뒤 큰 글자(1.5배)에서도 같은 문단·같은 비율로 복원된다 |

V2 판이 확인하지 않는 것: 실제 OS 앱 종료(저장소 재열기와 화면 재생성으로 대신한다), 실제 마이크, 실제 공유 시트, 실기기 키체인 잠금 해제, 실제 네트워크 끊김.

## 다음 이관 순서

1. 완료(2차): 데이터 손실과 생성 중복을 막는 것 12개.
2. 완료(3차): 읽기 경험 9개.
3. 완료(4차): 첫 사용과 흐름 14개.
4. 완료(5차): 통합 테스트 8개 파일(테스트 10개, 케이스 13개).

## 진행

| 단계 | V2 테스트 | 옮긴 V1 테스트 |
|---|---|---|
| 1차 (2026-10-27) | `processing_test` 3, `presentation_test` 5, `home_setup_test` 2, `gates_test` +1 | 11 |
| 2차 (2026-10-27) | `capture_input_test` 10(케이스 13), `recovery_test` 2 | 12 |
| 3차 (2026-10-27) | `reader_test` 9 | 9 |
| 4차 (2026-10-28) | `first_use_test` 14(케이스 23) | 14 |
| 5차 (2026-10-28) | `integration_test/v2/` 8개 파일, 테스트 10(케이스 13), QA 시뮬레이터 | 통합 10 |

4차까지 V1 UI 테스트 46개를 옮겼고, 5차에서 통합 테스트 8개 파일(테스트 10개)도 V2 판을 갖췄다. 이관 대상은 더 없다. V1 테스트와 V1 통합 테스트는 기본값이 `v1`인 동안 그대로 둔다.

1차 지도는 `draft_autosave` 화면 테스트를 6개, `p4` 이관 대상을 3개로 셌다. 2차에서 V1 코드를 다시 확인해 각각 7개와 2개로 고쳤다. 줄어든 1개는 화면 없는 Provider 테스트다.

3차에서 이관하다 V2의 빠진 동작을 하나 찾았다. V1은 홈·보관함·리더에서 오프라인이면 “네트워크 연결이 없어요. 기기에 저장된 기록은 계속 읽을 수 있어요.”를 보였는데 V2에는 없었다. `V2OfflineNotice`로 세 화면에 넣었다.

4차의 V2 차이: V2 대기 화면은 상태가 바뀔 때만 움직여 V1처럼 멈출 시계가 없다. 그래서 “배경에서 시계가 멈춘다”는 “배경 전환 중에도 프레임을 예약하지 않고 입력은 그대로”로 옮겼다. 홈의 새 장면 카드는 읽은 뒤 “최근 장면·이어 읽기”로 바뀌고, 기록 진입은 하단 내비에 늘 있다. 첫 결과 읽기 끝에서는 문단이 유리 헤더 밑으로 들어가 가려진 글자를 대비 검사가 읽으므로, 그 지점은 터치 영역과 라벨만 검사한다. 스크롤 전 리더의 대비는 `quality_test`가 확인한다.

5차의 V2 차이: V1 통합 테스트는 장면 번호를 `DREAM 008 → SCENE 12` 글자로 찾았지만 V2 공개 카드는 도트 글자라 의미 라벨 “꿈 8번에서 장면 12”로 찾는다. 완성본 화면은 지연 목록이라 “다음 권 시작”을 누르기 전에 스크롤한다. 저장·재열기 흐름에서는 생성 요청 횟수를 직접 세어 “명시적으로 요청하기 전에는 생성하지 않는다”를 V1보다 엄격하게 확인한다.

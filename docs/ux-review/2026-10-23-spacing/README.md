# 여백·톤앤매너 재정렬

2026-10-23 KST. 디자인 여백과 톤 불일치 지적에 대한 국소 수정이다. 생성/원문/출처/잠금/엔진/동의 기능을 바꾸지 않는다. 공개 사이트는10/22 배포 상태이며 이 수정은 로컬 검토용이다.

## 전후

- [이전 저장 화면](../2026-10-22-first-dream/browser-saved.jpg) → [수정 저장 화면](browser-saved.jpg)
- [이전 결과](../2026-10-22-first-dream/browser-first-result.jpg) → [수정 결과](browser-first-result.jpg)
- [소개](browser-entry.jpg), [첫 설정](browser-setup.jpg), [첫 읽기 끝](browser-reading-end.jpg)
- [작은 화면·큰 글자](day-375-667-large-reading-end.png), [야간](night-390-844-normal-first-result.png)

강제 `spaceBetween`으로 설명과 버튼이 멀리 떨어지던 저장/결과를 `MongFlowPage`로 묶었다. 화면 안쪽24px, 설명→행동32px. 묶음 바깥에는 여백을 두고 길어지면 스크롤한다. 소개/첫 설정/저장/결과/첫 읽기 끝은 `MongActionGroup`으로 주 행동 최대280px, 보조 행동15px/400·8px 간격·Wrap을 공유한다. 결과 상태는 메타로 낮추고 실제 제목을 강조하며 읽기 끝 설명은 secondary ink로 읽히게 했다.

큰 소개 그라디언트와 홈 표지를 유지했다. 배경/버튼 유리 재질을 또 바꾸거나 입력/STT에 모션을 더하지 않았다. [디자인 시스템 v0.9](../../MUMUMONG_DESIGN_SYSTEM_v0.9.md)에 코드와 동일한 규격을 기록했다.

## 실제 실행한 검증

- Flutter 전체 **238개 통과**(이전234 + 신규4). 고정32px 간격·280px 폭을390×844,1200×800,375×667/글자1.6배에서 측정한다.320×480 긴 내용에서 행동까지 스크롤하고 실제 탭을 확인한다. 기존 저장/첫 결과/원문/읽기 복귀·키보드·동작 줄이기 검사도 포함한다.
- 관련5파일49개 golden/동작 테스트를 갱신 후 전체 테스트에서 재비교했다. 이 폴더 PNG **75개**: 흐름30, 첫 결과/읽기 끝20, 소개1, 설정10, 도구14. 별도 도구의 캡처 생성·재비교도 각각 통과했다. 이전 날짜 증거를 덮어쓰지 않았다.
- format `lib test`105파일 변경 없음. 직접 `dart analyze lib test integration_test tool/visual_preview.dart tool/orb_motion_review.dart tool/ux_baseline_capture_test.dart` **No issues found**.
- `flutter analyze --no-pub`는 기존 한국어 경로의 LSP JSON FormatException(exit255)로 실패했다. 직접 분석 통과와 구분하며 ASCII 사본으로 대체하지 않았다.
- 순차 iOS simulator 무서명 build(9.3초 Xcode), 일반 web release(27.6초), 로컬 preview release(27.0초) 통과. 일반/검토 web 출력 각각 필수14리소스 guard 통과. 네이티브 통합 시나리오는 재실행하지 않았다.
- privacy/log guards·diff 공백 검사 통과. frozen write/plan/opening_expansion/opening_polish 네 파일은 edfc13c 대비 diff 없음. private 평가 데이터는 열거나 출력하지 않았다.
- localhost390×844에서 소개→가상 고지→설정→빈 홈→합성 기록/저장→명시적 mock 처리→결과→Reader/원문 시트→읽기 종료를 조작했다. 소개/설정/저장/결과/읽기 끝을 실제 브라우저에서 캡처했고 error/warn 로그는0건이다. 결과는 입력 기반 생성이 아닌 고정 예시다.

## 검토 경로와 한계

[로컬 검토 앱](http://127.0.0.1:4206/)은 소개→가상 고지→첫 원고 설정→빈 홈→합성 입력/저장→명시적 mock 처리→결과→Reader 경로다. **고정 소설은 입력을 반영한 AI 결과가 아니다.** 실제 계정/서버 동의/AI/Outbox 요청 없이 Memory에서 동작하며 새로고침하면 초기화된다. 이 빌드를 공개 서비스로 배포하지 않는다.

물리 iPhone/PWA 시스템 영역·키보드/STT/프레임·터치 성능, 실제 hosted 계정/AI/RLS와 문학적 품질·사용자 선호는 미검증이다. 이번 검사를 미적 완성이나 제품 전체 완료로 보고하지 않는다. 공개 재배포·commit·push 없음.

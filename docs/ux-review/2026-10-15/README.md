# P1 화면 증거

2026-10-15, Flutter widget renderer, 390×844, MemoryRepository/mock engine, 가상 꿈/고정 mock 소설, 동작 줄이기. 실제 AI 결과·물리 iPhone·웹 브라우저 사진이 아니다. 새 시각 리디자인은 P2부터 진행한다.

| 비교/동작 | P0 | P1 |
|---|---|---|
| 홈의 보조 ‘이어 읽기’ 연결 | [이전 홈](../../ux-baseline/2026-10-14/04-home.png) | [현재 홈](04-home.png) |
| Reader 장면 선택 UI 서체 | [이전 Reader](../../ux-baseline/2026-10-14/07-reader.png) | [현재 Reader](07-reader.png) |
| 새 결과에서 해당 장면의 시작 열기 | 기존은 홈으로 돌아감 | [직접 열린 장면](12-direct-reader.png) |
| 없는 명시적 장면 ID | 관련 안내 없음 | [돌아가기 안내](13-unavailable-reader.png) |
| 열린 앱의 기기 연결 없음 | 별도 상태 없음 | [로컬 읽기 유지](14-offline-reader.png) |

같은 가상 fixture로 소개·동의·첫 설정·홈·보관함·설정·Reader·기록·보강·처리·리빌·직접 읽기·잘못된 장면·오프라인의 14개 PNG를 생성하고 확인했다. 입력한 가상 꿈과 mock 결과는 일치하지 않는 fixture이므로 소설 충실도의 증거로 쓰지 않는다.

```sh
flutter test --no-pub --dart-define=UX_CAPTURE_DIR=../docs/ux-review/2026-10-15 tool/ux_baseline_capture_test.dart
```

위 명령은 **P1 당시 소스**에서의 재비교 명령이다. P2 소스에서는 모습이 달라진다. 캡처 도구 기본 출력도 P2 디렉터리로 변경했다. P0/P1 이미지는 역사적 기준선이므로 현재 소스로 update-goldens해 덮어쓰지 않는다. 새 비교 세트는 다른 `UX_CAPTURE_DIR`를 지정한다. 실제 전환은 widget/시뮬레이터 테스트로 별도 확인했으며 이 정지 이미지에서 모션이나 성능을 추정하지 않는다.

# P0 현재 화면 기준선

2026-10-14에 원본 작업 트리에서 실행·캡처한 현재 UI. 새 시안이 아니다.

- Flutter widget renderer, 390×844 논리 px, devicePixelRatio 1.
- Pretendard/MaruBuri/MaterialIcons 로드, 동작 줄이기.
- MemoryRepository와 mock engine. 새로 지은 가상 꿈을 입력하며 고정 mock 소설 결과가 나온다. 개인 데이터·실제 AI 생성 결과가 아니다.
- Onboarding policy는 시험용 fixture이고 실제 동의를 기록하지 않는다.
- widget renderer의 `kIsWeb=false` 분기. 웹에서는 체험 계정/텍스트 입력으로 달라진다. PWA 시스템 막대나 성능을 검증한 사진이 아니다.
- 전환 완료 뒤 캡처했다. 정지 화면이므로 애니메이션 평가 증거로 쓰지 않는다.

| 화면 | 캡처 |
|---|---|
| 소개 | [01-entry.png](01-entry.png) |
| 동의 | [02-consent.png](02-consent.png) |
| 첫 원고 설정 | [03-volume-setup.png](03-volume-setup.png) |
| 원고 홈 | [04-home.png](04-home.png) |
| 보관함 | [05-archive.png](05-archive.png) |
| 설정 | [06-settings.png](06-settings.png) |
| Reader | [07-reader.png](07-reader.png) |
| 기록 | [08-capture.png](08-capture.png) |
| 보강 | [09-recall.png](09-recall.png) |
| 생성 | [10-processing.png](10-processing.png) |
| 새 장면 | [11-reveal.png](11-reveal.png) |

당시 캡처는 위 P0 이미지로 보존한다. 캡처 도구는 현재 소스를 렌더링하며 P1부터는 새 `ux-review` 폴더로 출력한다. 현재 소스를 P0 이미지와 동일하다고 기대하지 않는다. 새 단계의 재비교:

```sh
flutter test --no-pub tool/ux_baseline_capture_test.dart
```

새 단계 캡처 생성(P0 원본을 덮어쓰지 않는다):

```sh
flutter test --no-pub --update-goldens tool/ux_baseline_capture_test.dart
```

P0의 Reader dropdown 일부 글자에는 font fallback glyph가 나타났다. P1에서 공통 UI 서체를 적용한 widget 캡처에서는 해결됐다. 실제 브라우저 확인은 별도 항목이다.

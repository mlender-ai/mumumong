# MUMUMONG — Claude Code Guide

Claude Code 전용 가이드. **저장소 규칙의 원본은 `AGENTS.md`다. 먼저 읽어라.**

이 파일은 `AGENTS.md`를 대체하지 않는다. Claude Code가 원격 세션에서 일할 때만 다른 점을 적는다.

---

## 시작할 때 읽을 것 (순서)

1. `AGENTS.md` — 비타협 규칙, 제품 루프, 워크플로
2. `docs/STATUS.md` — **지금 무엇이 실제로 구현됐는지.** 항상 여기가 진실이다
3. `docs/MUMUMONG_M1_WorkOrders.md` — 지시받은 WO 번호 항목만
4. 필요할 때만: `docs/MUMUMONG_M1_Report.md` (기술 결정 근거), `docs/MUMUMONG_PRODUCT_PDR_v0.1.md`, `docs/MUMUMONG_VISUAL_SYSTEM_v0.1.md`

`git log --oneline | head -15`로 직전 작업 흐름을 확인해라.

---

## 원격 환경 제약 — 가장 중요

이 저장소는 **Codex(로컬 macOS)와 Claude Code(원격 컨테이너)가 번갈아** 작업한다. 원격에는 macOS 전용 도구가 없다.

**작업 시작 시 무엇을 쓸 수 있는지 직접 확인해라. 가정하지 마라.**

```bash
flutter --version || echo "NO FLUTTER"
which supabase || echo "NO SUPABASE CLI"
which xcodebuild || echo "NO XCODE"
docker info >/dev/null 2>&1 || echo "NO DOCKER"
```

**결과에 따라 이렇게 행동한다.**

| 상황 | 행동 |
|---|---|
| Flutter 있음 | `dart format` · `flutter analyze` · `flutter test` · `flutter build web --release` 실행 |
| Xcode 없음 | `flutter build ios`를 **시도하지 마라.** 완료 보고에 "iOS 미검증 — 로컬에서 확인 필요"라고 적는다 |
| Supabase CLI 또는 Docker 없음 | `supabase db reset` / `supabase test db` 생략. SQL을 바꿨다면 **"DB 미검증"으로 명시** |
| Flutter 없음 | 코드를 고치지 말고 그 사실을 먼저 보고해라 |

### 절대 하지 말 것

- **실행하지 않은 명령의 결과를 보고하지 마라.** "빌드 통과"는 실제로 돌렸을 때만 쓴다
- 시뮬레이션된 동작을 구현된 것처럼 `docs/STATUS.md`에 쓰지 마라 (AGENTS.md 규칙)
- iOS 런타임·실기기 검증이 필요한 작업(STT, Drift 네이티브, 푸시)은 원격에서 **코드까지만** 작성하고, 검증은 로컬 담당으로 남긴다

---

## 이 프로젝트에서 특히 조심할 것

`AGENTS.md`의 규칙 중 실수가 잦았던 것들.

- **로그에 꿈 원문·생성 본문을 절대 넣지 마라.** `AppLog.event(name, {ids})`만 쓴다. `print`/`debugPrint` 직접 호출 금지. `tool/check_log_safety.sh`가 CI에서 막는다
- **D 문단은 실제로 존재하는 element id를 참조해야 한다.** 개수만 채우는 더미 UUID를 만들지 마라 (과거에 이 사고가 있었다)
- **U 문단은 어떤 경로로도 덮어쓰지 마라.** DB 트리거가 막지만 앱 코드에서도 지킨다
- **`progress_mu`는 `progress_events` 합계의 캐시다.** 저장할 때 클램프하지 마라. 클램프는 표시 계층에서만
- 진척·MU·clarity 계산은 `lib/domain/progress.dart`, `lib/domain/clarity.dart`의 순수 함수만 쓴다. 다른 곳에 중복 구현 금지

---

## 코드 구조

```
lib/
  core/    design(토큰·도트) · log · env
  domain/  model · progress · clarity · repository(인터페이스)
  data/    auth · engine(EngineClient + mock) · local(Drift) · memory
  di/      providers.dart — Riverpod
  ui/      auth · home · capture · reader · archive
supabase/  migrations 0001~0007 · tests · functions
```

- **화면은 `MumumongRepository` 인터페이스만 본다.** Drift·Supabase를 직접 호출하지 마라
- 저장소 구현을 추가·수정하면 `test/contract/repository_contract.dart`가 **memory와 Drift 양쪽에서** 통과해야 한다
- `lib/core/design/design_system.dart`의 토큰은 비주얼 시스템 문서와 1:1이다. **값을 바꾸지 마라**

---

## 작업 방식

1. **지시받은 WO 하나만 한다.** 범위를 넘는 리팩터링·개선 제안을 하지 마라
2. 규칙끼리 충돌하면 추측하지 말고 **멈추고 보고**한다
3. 기능이 시뮬레이션 → 실제 구현으로 넘어가면 `docs/STATUS.md`를 갱신한다. 갱신 안 하면 미완료
4. 테스트 없는 완료는 미완료다

### 완료 보고 형식

```
## WO-XX 완료

변경: <파일 목록>
구현: <핵심 3줄 이내>

검증 (실제 실행한 것만):
- dart analyze: 통과
- flutter test: NN개 통과
- flutter build web --release: 통과

미검증 (로컬 필요):
- flutter build ios --simulator: Xcode 없음
- supabase test db: Docker 없음

STATUS.md: 갱신함 / 해당 없음
```

**미검증 항목을 빠뜨리지 마라.** 다음 담당이 로컬에서 무엇을 돌려야 하는지가 이 목록이다.

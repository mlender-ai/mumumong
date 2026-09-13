# MUMUMONG M1 작업지시서 (Codex용)

각 WO는 **한 번에 구현하고 검증할 수 있는 단위**다. 순서는 `MUMUMONG_M1_Report.md` §8을 따른다.

**v0.3 — 저장소 코드 확인 및 D1·D2·D6 사용자 결정 반영.** 확인 결과는 `MUMUMONG_M1_Report.md` §2에 있다.

**확정 결정**

- D1: 서술 시점은 L1 설정으로 주입한다. 기본값은 `third_person_past`, 선택값은 `first_person_past`다.
- D2: STT는 iOS 온디바이스 전용이며 서버 폴백이 없다.
- D6: WO-00 저장소 재편을 승인한다.

**공통 규칙 (모든 WO에 적용)**

1. **`AGENTS.md`의 비타협 규칙이 이 문서보다 우선한다.** 충돌하면 작업을 멈추고 보고한다.
2. 꿈 원문, 생성 본문, 요약 텍스트를 로그·분석·예외 메시지에 포함하지 않는다.
3. 한 WO의 범위를 넘는 리팩터링을 하지 않는다. **단 WO-00은 예외다.**
4. 모든 WO는 테스트를 함께 제출한다. 테스트 없는 완료는 미완료다.
5. LLM 호출은 Edge Function 안에서만 한다. 클라이언트에 API 키를 두지 않는다.
6. **완료 전 필수 실행** (AGENTS.md 워크플로):
   ```bash
   dart format --output=none --set-exit-if-changed lib test
   flutter analyze && flutter test && flutter build web --release
   ```
7. **시뮬레이션이 실제 구현으로 넘어간 WO는 `docs/STATUS.md`를 갱신한다.** 갱신하지 않으면 미완료다.

**확인된 코드 전제 (v0.2)**

| 사실 | 영향 |
|---|---|
| `lib/`가 평면 7파일, 2,207줄 | WO-00에서 폴더 구조를 만든다 |
| 의존성이 `cupertino_icons` 하나 | 패키지 도입이 WO-00의 일 |
| 상태관리 없음, 전부 `setState` | Riverpod 신규 도입 |
| **도메인 모델 없음** (`_DreamEntry` private 1개뿐) | WO-06에서 신규 작성 |
| **Reader 문단·Archive 목록이 위젯 리터럴** | WO-08 배선이 실질 작업 |
| 처리 화면이 `Timer.periodic` | WO-15는 재작성 |
| `DotCover`는 `CustomPainter` | 셰이더 작업 없음 |
| `PassageOrigin` enum이 `reader_screen.dart`에 존재 | 위젯 파라미터 → 도메인 값으로 승격 |
| `design_system.dart` 토큰이 VS와 일치 | **건드리지 않는다** |
| `ci.yml` 존재 | 새 워크플로 금지, 스텝만 추가 |

**표기:** `[신규]` 새 파일 / `[수정]` 기존 파일 / `[이동]` WO-00에서 경로 변경됨

---

# A. 기반 (WO-00 ~ WO-05)

## WO-00 · 저장소 재편과 의존성 도입

**목적:** 데이터 계층을 얹을 수 있는 구조를 만든다. **지금이 가장 싸다** — 2,207줄이고 버릴 추상화가 없다.

**이 WO만 범위를 넘는 변경이 허용된다. 단 동작은 1도 바뀌면 안 된다.**

**1. 폴더 구조**

```
lib/
  main.dart
  core/
    design/design_system.dart      ← [이동] lib/design_system.dart 그대로
    design/dot_field.dart          ← [이동] lib/dot_field.dart 그대로
    log/app_log.dart               ← WO-01
    env/env.dart                   ← WO-02
  domain/                          ← WO-06
  data/                            ← WO-07·WO-09
  ui/
    home/home_screen.dart          ← [이동]
    capture/capture_flow.dart      ← [이동]
    reader/reader_screen.dart      ← [이동]
    archive/archive_screen.dart    ← [이동]
```

- **파일 내용은 import 경로 외에 바꾸지 않는다.** 이동과 로직 변경을 같은 커밋에 섞지 않는다.
- `PassageOrigin` enum은 `reader_screen.dart`에 그대로 둔다. WO-06에서 도메인으로 옮긴다.

**2. 의존성 추가 (`pubspec.yaml`)**

```yaml
dependencies:
  flutter_riverpod: ^3.4.3
  riverpod_annotation: ^4.0.7
  drift: ^2.35.0
  sqlite3_flutter_libs: ^0.6.0+eol
  path_provider: ^2.1.6
  supabase_flutter: ^2.17.2
  flutter_secure_storage: ^11.1.1
  connectivity_plus: ^7.3.1
  uuid: ^4.6.0
dev_dependencies:
  build_runner: ^2.15.1
  riverpod_generator: ^4.0.9
  drift_dev: ^2.35.0
  mocktail: ^1.0.5
```

버전은 현재 Dart SDK(`^3.12.2`)에서 해결되는 최신 안정 버전으로 맞춘다.

**3. `ProviderScope` 도입**

`main.dart`의 `runApp(const MumumongApp())`를 `runApp(const ProviderScope(child: MumumongApp()))`로 바꾼다. **이 WO에서는 Provider를 하나도 만들지 않는다.** 껍데기만 넣는다.

**4. `analysis_options.yaml`**

생성 파일 제외를 추가한다.

```yaml
analyzer:
  exclude: ['**/*.g.dart', '**/*.freezed.dart']
```

**완료 조건**
- `flutter analyze` 무경고, 기존 위젯 테스트 2개 통과
- `flutter build web --release`, `flutter build ios --simulator --no-codesign` 통과
- 앱 화면과 동작이 이전과 동일 (스크린샷 비교)

**테스트:** 기존 `test/widget_test.dart`를 `test/ui/` 아래로 옮기고 import만 수정해 통과시킨다.

---


## WO-01 · 로깅 래퍼와 CI 금지 패턴

**목적:** 원문 유출 경로를 코드로 차단한다. **반드시 첫 번째로 한다.**

**구현**

`[신규] lib/core/log/app_log.dart`  *(WO-00 구조)*

```dart
const _allowedKeys = {
  'dream_id','volume_id','scene_id','passage_id','job_id','user_id',
  'stage','status','code','ms','count','attempt','origin','mode','env',
};

class AppLog {
  static void event(String name, [Map<String, Object?> fields = const {}]) {
    final safe = <String, Object?>{};
    fields.forEach((k, v) {
      if (!_allowedKeys.contains(k)) return;           // 비허용 키는 제거
      if (v is String && v.length > 64) return;        // 긴 문자열은 본문 가능성
      safe[k] = v;
    });
    _sink(name, safe);
  }
}
```

- `dart:developer`/`print`/`debugPrint` 직접 호출을 전부 `AppLog`로 교체한다. `[코드]` 현재 `lib/`에 `print` 호출은 없다. 래퍼를 **미리** 넣어 이후 WO가 쓰게 하는 것이 목적이다.
- `[신규] lib/core/log/app_exception.dart` — `DreamProcessingException(dreamId, stage, code)`. 원문을 담는 생성자를 만들지 않는다.
- Edge Function 측 `[신규] supabase/functions/_shared/log.ts` — 동일한 허용목록 로직.

`[신규] tool/check_log_safety.sh`

```bash
#!/usr/bin/env bash
set -e
BAD='raw_text|passage\.text|story_so_far|transcript|rawText|passageText'
if grep -rnE "(print|debugPrint|console\.log)\s*\(.*($BAD)" lib supabase/functions; then
  echo "FAIL: 본문이 로그에 노출될 수 있습니다"; exit 1
fi
if grep -rn "print(" lib --include="*.dart" | grep -v "app_log.dart"; then
  echo "FAIL: AppLog 외 직접 print 사용"; exit 1
fi
echo "OK"
```

**CI 연결 — 새 워크플로를 만들지 않는다.** `[수정] .github/workflows/ci.yml`의 Analyze 스텝 **앞**에 추가한다.

```yaml
      - name: Log safety check
        run: bash tool/check_log_safety.sh
```

**완료 조건:** 스크립트 통과, CI 그린, `print` 직접 호출 0개.
**테스트:** `test/core/app_log_test.dart` — 비허용 키 제거, 64자 초과 문자열 제거, 허용 키 보존.
**STATUS.md:** 갱신 불필요 (사용자 기능 아님).

---

## WO-02 · 환경 분리와 Supabase 로컬

**구현**

- `[신규] supabase/` 디렉터리 초기화 (`supabase init`).
- `[신규] lib/core/env/env.dart` — `String.fromEnvironment('ENV')`로 dev/staging/prod 분기. URL·공개 publishable key(구 anon key)를 환경별 상수로 분리한다. **service_role·secret 키는 앱에 절대 넣지 않는다.** `supabase_flutter` 2.17 이상에서는 `publishableKey` 인자를 사용한다.
- `[신규] .env.example`, `[수정] .gitignore` — `.env*` 제외.
- `[신규] Makefile` — `make dev`, `make mock`, `make db-reset`.

**실행 인자**

| 인자 | 값 |
|---|---|
| `ENV` | `dev` \| `staging` \| `prod` |
| `ENGINE` | `mock` \| `remote` |

**완료 조건:** `supabase start` → `supabase db reset`이 성공하고, 앱이 로컬 인스턴스에 붙는다.

---

## WO-03 · 마이그레이션 0001~0005

**목적:** 보고서 §6의 스키마를 파일로 만든다.

**구현**

`[신규] supabase/migrations/0001_init_enums.sql`

```sql
create type volume_status   as enum ('active','completable','completing','completed');
create type volume_format   as enum ('short','novella');
create type adaptation_level as enum ('faithful','balanced','free');
create type writing_style   as enum ('plain','lyrical','cinematic');
create type narrative_voice as enum ('third_person_past','first_person_past');
create type dream_status    as enum ('queued','processing','in_manuscript','archived_only','failed');
create type dream_clarity   as enum ('fragment','partial','vivid');
create type element_type    as enum ('person','place','object','event','emotion','sensory');
create type passage_origin  as enum ('D','C','U');
create type scene_kind      as enum ('prologue','dream','interlude','ending');
create type placement_kind  as enum ('continuation','motif','interlude','fragment_attach','standalone');
create type job_status      as enum ('queued','running','done','failed');
create type job_type        as enum ('extract','link','plan','write','validate','commit','remember','link_patch');
```

`[신규] 0002_core_tables.sql` ~ `0005_jobs.sql` — 보고서 §6.2 제약 표를 **전부** 반영한다. 특히:

```sql
-- volumes
create unique index uq_volume_active on volumes (user_id)
  where status in ('active','completable','completing');
alter table volumes add constraint uq_volume_no unique (user_id, vol_no);
alter table volumes add column prologue_scene_id uuid;
alter table volumes add column narrative_voice narrative_voice not null
  default 'third_person_past';

-- dreams
create index idx_dreams_user_date on dreams (user_id, dream_date desc);
create index idx_dreams_user_status on dreams (user_id, status);

-- passages (user_id 비정규화: RLS 성능)
alter table passages add column user_id uuid not null;
alter table passages add constraint chk_d_has_source
  check (origin <> 'D' or coalesce(array_length(source_element_ids,1),0) >= 1);
alter table passages add constraint chk_u_locked
  check (origin <> 'U' or locked = true);
alter table passages add constraint uq_passage_order unique (scene_id, order_key);

-- scenes
alter table scenes add column open_image text;
alter table scenes add constraint uq_scene_order unique (volume_id, order_key);

-- jobs
alter table jobs add column idempotency_key uuid not null;
alter table jobs add column payload jsonb default '{}';
create unique index uq_job_idem on jobs (user_id, idempotency_key);
create unique index uq_job_active on jobs (dream_id, type)
  where status in ('queued','running');
create index idx_jobs_queued on jobs (created_at) where status = 'queued';
```

`[신규] supabase/seed.sql` — 테스트 사용자 1명, 볼륨 1개, 장면 2개, 문단 6개(D 4 / C 1 / U 1).

**완료 조건:** `supabase db reset`으로 전체 적용 + 시드 삽입 성공.
**테스트:** `[신규] supabase/tests/constraints_test.sql` — 제약 위반 삽입이 각각 실패하는지 확인 (D 문단에 source 없음, U 문단에 locked=false, active 볼륨 2개, 중복 order_key).

---

## WO-04 · RLS와 교차 접근 테스트

`[신규] 0006_rls.sql`

```sql
-- 직접 소유 테이블
alter table volumes enable row level security;
create policy p_volumes on volumes for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
-- dreams, passages, jobs, progress_events 동일 (user_id 보유)

-- 조인 소유 테이블
alter table dream_elements enable row level security;
create policy p_dream_elements on dream_elements for all using (
  exists (select 1 from dreams d
          where d.id = dream_elements.dream_id and d.user_id = auth.uid())
);
-- entities, entity_mentions, scenes, narrative_memory, link_decisions 동일

-- 클라이언트 접근 금지
alter table generation_runs enable row level security;
-- 정책을 만들지 않는다 → service_role만 접근
```

**완료 조건:** 아래 CI 쿼리가 0행을 반환한다.

```sql
select tablename from pg_tables
 where schemaname='public' and rowsecurity = false;
```

**테스트:** `[신규] supabase/tests/rls_test.sql` — 사용자 A 세션으로 B의 행에 select/insert/update/delete를 시도하고 모두 차단·0행임을 확인한다. 9개 테이블 전부.

---

## WO-05 · 트리거와 RPC (0007)

**구현**

1. **U 잠금 트리거** — 보고서 §5.9 코드 그대로.
2. **`commit_scene(p_dream_id, p_volume_id, p_payload)`** — §6.5. 멱등 체크를 맨 앞에 둔다.
3. **`recompute_progress(p_volume_id)`** — §6.6.
4. **`claim_job()`** — §6.4. `for update skip locked`.
5. **`user_edit_passage(p_passage_id, p_text)`** — 내부에서 `set_config('app.user_edit','on',true)` 후 UPDATE. 사용자 편집의 **유일한 경로**다.
6. **`reap_zombie_jobs()`** — `running` 상태가 5분 초과면 `queued`로 되돌린다. pg_cron 1분 주기.
7. **`delete_user_data(p_user_id)`** — 전 테이블 하드 삭제 (WO-18에서 사용).

**MU 계산 (commit_scene 내부, PDR §15)**

```
base    = clarity별 1.0 / 2.0 / 3.0
recall  = min(0.75, 0.25 × 유효 보강 답변 수)
user    = 0 (커밋 시점에는 U 문단 없음)
delta   = base + recall
reasons = [{"type":"new_scene","n":1}, {"type":"recall","n":k}]
```

**완료 조건:** 트리거가 엔진 경로의 U 문단 UPDATE를 막고, `user_edit_passage`는 통과한다.
**테스트:** `[신규] supabase/tests/rpc_test.sql`
- `commit_scene`을 같은 payload로 2회 호출 → 장면 1개
- U 문단 직접 UPDATE → 예외
- `user_edit_passage` → 성공
- `claim_job` 동시 2회 → 서로 다른 job 반환 또는 하나는 null

---

# B. 앱 기반 (WO-06 ~ WO-13)

## WO-06 · 도메인 모델 신규 작성 `[v0.2 신설]`

**배경:** `[코드]` 저장소에 도메인 모델이 없다. 유일한 데이터 클래스는 `archive_screen.dart`의 private `_DreamEntry`(date·firstLine이 String, status가 String)다. Reader 문단은 위젯 리터럴이다. **이식이 아니라 신규 작성이다.**

**구현** — `[신규] lib/domain/model/` 아래 불변 클래스로 작성한다.

| 파일 | 클래스 | 핵심 필드 |
|---|---|---|
| `volume.dart` | `Volume` | id, volNo, title?, format, adaptation, style, narrativeVoice, status, progressMu, targetMu, genreProfile, coverMotifId, prologueSceneId |
| `dream.dart` | `Dream` | id, volumeId?, dreamDate(`DateTime`), recordedAt, inputMode, rawText, recallAnswers, clarity?, status, isBackfill |
| `dream_element.dart` | `DreamElement` | id, dreamId, type, label, detail, salience, source, span(`(int,int)?`) |
| `scene.dart` | `Scene` | id, volumeId, orderKey, chapterNo?, kind, placement, title?, sourceDreamIds, openImage? |
| `passage.dart` | `Passage` | id, sceneId, orderKey, text, **origin**, sourceDreamId?, sourceElementIds, cReason?, originalText?, **locked**, firstReadAt? |
| `entity.dart` | `StoryEntity` | id, volumeId, type, roleName, description, aliases, status, mentionCount |
| `link_decision.dart` | `LinkDecision` | id, dreamId, kind, payload, status |
| `progress_event.dart` | `ProgressEvent` | id, volumeId, dreamId?, deltaMu, reasons, createdAt |
| `job_progress.dart` | `JobProgress` | dreamId, type, status, attempt, stageLabel |

**enum은 `lib/domain/model/enums.dart` 한 파일에 모은다.**

```dart
enum PassageOrigin { dream, connection, user }   // ← reader_screen.dart에서 [이동]
enum DreamClarity { fragment, partial, vivid }
enum DreamStatus { queued, processing, inManuscript, archivedOnly, failed }
enum PlacementKind { continuation, motif, interlude, fragmentAttach, standalone }
enum AdaptationLevel { faithful, balanced }       // free는 M1 제외 (D 결정 §31-1)
enum WritingStyle { plain, lyrical, cinematic }
enum NarrativeVoice { thirdPersonPast, firstPersonPast } // 기본 thirdPersonPast
enum VolumeStatus { active, completable, completing, completed }
enum SceneKind { prologue, dream, interlude, ending }
enum JobType { extract, link, plan, write, validate, commit, remember, linkPatch }
```

**규칙**

1. `PassageOrigin`을 `reader_screen.dart`에서 옮기고, `reader_screen.dart`는 `domain`에서 import한다. **enum 값 이름을 바꾸지 않는다** (`dream/connection/user` 유지). 기존 위젯 코드가 그대로 동작해야 한다.
2. **불변 클래스 + `copyWith`.** `freezed`는 쓰지 않는다. 빌드 시간과 의존성을 아낀다.
3. `toJson`/`fromJson`을 손으로 쓴다. enum은 **DB enum 문자열과 정확히 일치**시킨다 (`inManuscript` ↔ `'in_manuscript'`). 매핑 함수를 한 곳에 모은다.
4. MU 계산을 `lib/domain/progress.dart`에 **순수 함수**로 둔다.
   ```dart
   double materialUnits({required DreamClarity clarity, required int recallAnswers,
                         required int userPassages});
   ```
   PDR §15 공식 그대로. UI·DB 어디에도 중복 구현하지 않는다.
5. clarity 판정도 `lib/domain/clarity.dart`에 순수 함수로 둔다 (E1이 서버에서, 앱이 표시용으로 쓰므로 **Dart/TS 양쪽에 같은 규칙**이 필요하다. 교차 테스트 대상).

**완료 조건:** 모델 9종 + enum 매핑 + MU/clarity 순수 함수. `flutter analyze` 무경고.
**테스트:** `test/domain/` — 직렬화 왕복 9종, MU 계산 8케이스(PDR §15 표 전체), clarity 경계 6케이스.

---

## WO-07 · Repository 인터페이스와 MemoryRepository

**배경:** `[코드]` 현재 상태는 `_MumumongShellState`의 `_progress`/`_dreams`/`_scenes` 세 개의 원시값이고, 진척은 `_progress + .06` 하드코딩이다. 교체할 저장소가 없으므로 인터페이스를 **정의부터** 한다.

`[신규] lib/domain/repository/mumumong_repository.dart`

```dart
abstract class MumumongRepository {
  Stream<Volume?> watchActiveVolume();
  Stream<List<Dream>> watchDreams(DreamStatusFilter filter);
  Stream<List<Scene>> watchScenes(String volumeId);
  Stream<List<Passage>> watchPassages(String sceneId);
  Stream<List<ProgressEvent>> watchRecentProgress(String volumeId);
  Stream<JobProgress?> watchJob(String dreamId);

  Future<void> saveDraft(DreamDraft draft);
  Future<DreamDraft?> loadDraft();
  Future<void> clearDraft();
  Future<String> submitDream(DreamDraft draft);
  Future<void> answerRecall(String dreamId, Map<String, String> answers);
  Future<void> decideLink(String decisionId, LinkChoice choice);
  Future<void> changePlacement(String sceneId, PlacementKind kind);
  Future<void> editPassage(String passageId, String text);
  Future<void> revertPassage(String passageId);
  Future<void> markPassageRead(String passageId);
  Future<void> removeDreamFromManuscript(String dreamId);
  Future<void> deleteDream(String dreamId, DeleteMode mode);
}
```

- `[신규] lib/data/memory/memory_repository.dart` — **현재 화면들이 쓰던 하드코딩 값을 여기로 모은다.** Reader의 문단 5개, Archive의 고정 목록, 홈의 7 dreams / 11 scenes / 42%가 전부 이 구현체의 시드 데이터가 된다.
- `[신규] lib/di/providers.dart` — `repositoryProvider`. 기본값은 `MemoryRepository`.

**완료 조건:** `MemoryRepository`가 계약 테스트를 통과하고, 기존 화면은 **아직 수정하지 않은 상태**로 빌드가 통과한다.
**테스트:** `[신규] test/contract/repository_contract_test.dart` — 구현체 무관 공통 계약. WO-09에서 Drift로 재사용한다.

---

## WO-08 · 화면 4개를 Repository에 배선 `[v0.2 신설]`

**배경:** `[코드]` 이것이 v0.1이 놓친 실질 작업이다. Reader 문단과 Archive 목록이 위젯 리터럴이고, 홈 진척이 하드코딩이다. **화면당 순서대로 하나씩** 끝낸다. 한 번에 4개를 건드리지 않는다.

| 순서 | 화면 | 지금 `[코드]` | 바꿀 것 |
|---|---|---|---|
| 1 | `home_screen.dart` | `progress`/`dreams`/`scenes`를 부모가 props로 내려줌 | `ConsumerWidget` + `watchActiveVolume()`. 진척은 `progressMu / targetMu` |
| 2 | `archive_screen.dart` | `_DreamEntry` 고정 배열, `status`가 String | `watchDreams(filter)`. `_DreamEntry` 제거, `Dream` 사용. 월별 그룹핑은 `dreamDate` 기준 |
| 3 | `reader_screen.dart` | `ReaderPassage(...)` 리터럴 5개 | `watchScenes` + `watchPassages`. `ReaderPassage` 위젯은 그대로 두고 데이터만 주입 |
| 4 | `capture_flow.dart` | 로컬 `setState` 4단계 | `submitDream` → `answerRecall` → `watchJob` → 리빌. **처리 단계 연동은 WO-15에서** 한다. 여기서는 Mock 경로까지만 |

**규칙**

1. **`main.dart`의 `_MumumongShellState`에서 `_progress`/`_dreams`/`_scenes`를 제거한다.** 탭 인덱스만 남긴다.
2. **진척 증가 하드코딩(`_progress + .06`)을 삭제한다.** `ProgressEvent`에서 계산한다.
3. **위젯의 시각 구현을 바꾸지 않는다.** `DotCover`, `ReaderPassage`, `_ClarityDots`, `_ArchiveRow`는 파라미터 타입만 바뀐다. 레이아웃·모션·색은 그대로다.
4. Δ 라인은 `watchRecentProgress`의 최근 이벤트에서 PDR §15 템플릿으로 조립한다.
5. 성장 애니메이션(`_growthController`)은 **"새 ProgressEvent가 도착했고 아직 재생하지 않았을 때"** 1회 재생한다. 현재의 `animateGrowth` bool props를 이 조건으로 대체한다.

**완료 조건:**
- `lib/ui/` 전체에서 하드코딩된 꿈·문단·진척 리터럴 **0개** (grep으로 확인)
- 기존 위젯 테스트 2개가 `MemoryRepository` override 위에서 통과
- 스크린샷이 WO-00 이전과 동일

**테스트:** 화면별 위젯 테스트 4개. `ProviderScope(overrides: [repositoryProvider.overrideWithValue(FakeRepo())])`로 주입.
**STATUS.md:** `In-memory state only` → `Repository-backed, memory implementation` 로 갱신.

---

## WO-09 · Drift 로컬 스키마와 DriftRepository

**배경:** `[코드]` 현재 로컬 저장이 전무하다 (앱 재시작 시 초기화). 마이그레이션할 기존 데이터가 없어 스키마를 자유롭게 잡을 수 있다.

`[신규] lib/data/local/database.dart`

- 원격 스키마를 **대칭**으로 미러링한다: volumes, dreams, dream_elements, scenes, passages, entities, progress_events.
- 로컬 전용 테이블:

```dart
class DreamDrafts extends Table { /* id, text, inputMode, updatedAt */ }
class Outbox extends Table {
  TextColumn get id => text()();
  TextColumn get op => text()();            // create_dream | answer_recall | ...
  TextColumn get payload => text()();       // json
  TextColumn get idempotencyKey => text()();
  IntColumn  get attempt => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();
  TextColumn get status => text()();        // pending|sending|done|failed
}
class ReaderPositions extends Table { /* volumeId, offset */ }
class SyncState extends Table { /* tableName, lastSyncedAt */ }
```

- `[신규] lib/data/local/drift_repository.dart` — WO-07 인터페이스 구현. `watch*`는 Drift의 스트림 쿼리를 그대로 노출한다.
- enum은 WO-06의 매핑 함수를 재사용한다. **DB 문자열을 여기서 다시 정의하지 않는다.**

**완료 조건:** `repositoryProvider`를 `DriftRepository`로 바꿔도 화면이 동일하게 동작하고, 비행기 모드 재시작 후 데이터가 남는다.
**테스트:** `test/contract/repository_contract_test.dart`를 **`DriftRepository`로 재실행** (WO-07에서 만든 계약 테스트 재사용). Drift 마이그레이션 테스트 1개.
**STATUS.md:** `Persistence: In-memory state only` → `Local persistence via Drift` 갱신.

---

## WO-10 · Apple 로그인과 세션

- `sign_in_with_apple` → Supabase `signInWithIdToken(provider: apple)`.
- 세션은 `flutter_secure_storage`(Keychain). **SharedPreferences 금지.**
- **이름·이메일을 저장하지 않는다.** Apple이 제공해도 폐기한다. 수집 최소화가 심사와 신뢰 양쪽에 유리하다.
- 로그인 후 `volumes` 조회 → 없으면 S02, 있으면 S03.

**실패 처리:** 취소는 무시 / 네트워크 오류는 재시도 버튼 / 토큰 만료는 자동 갱신 후 실패 시 재로그인.
**완료 조건:** 앱 삭제 후 재설치 → 같은 Apple ID로 기존 데이터 복원.
**테스트:** 신규/재로그인/취소/오프라인.

---

## WO-11 · Mock 엔진

`[신규] lib/data/engine/engine_client.dart`

```dart
abstract class EngineClient {
  Future<String> enqueue(String dreamId, String idempotencyKey);
  Stream<JobProgress> watch(String dreamId);
}
```

`[신규] lib/data/engine/mock_engine_client.dart`

시나리오 3종을 `--dart-define=MOCK_CASE=` 로 전환한다.

| 케이스 | 동작 |
|---|---|
| `success` | 단계별 2초 지연 → 장면 1개(문단 5개: D 4, C 1) |
| `retry` | validate에서 1회 실패 후 재생성 성공 |
| `fallback` | 2회 실패 후 축약 장면 커밋 |
| `fail` | 최종 실패 → `dreams.status='failed'` |

**완료 조건:** `ENGINE=mock`으로 기록→리빌 전 구간 완주. 네트워크·LLM 없이 동작.
**테스트:** `[신규] integration_test/capture_to_reveal_test.dart` — Mock 위에서 4케이스 각각 검증.

---

## WO-12 · 초안 자동저장

- 텍스트 변경 500ms 디바운스 → `DreamDrafts` upsert.
- 음성 부분 인식 결과마다 저장.
- S04 진입 시 초안이 있으면 복원하고 "이어서 쓰기 / 새로 쓰기"를 **한 번만** 묻는다. 새로 쓰기를 고르면 초안을 폐기한다.
- 저장 실패는 조용히 재시도한다. **사용자에게 알리지 않는다** (PDR §12 마찰 금지).

**완료 조건:** 강제 종료 후 재실행 시 직전 입력 복원.
**테스트:** 백그라운드 전환 / 강제 종료 / 초안 폐기.

---

## WO-13 · Outbox 큐와 동기화

**가장 버그가 많이 나는 구간이다. 작은 단계로 나눠서 검증한다.**

`[신규] lib/data/sync/outbox_worker.dart`

```
1. 연결 상태 구독 (connectivity_plus)
2. 온라인 전환 또는 앱 포그라운드 → drain() 호출
3. drain(): status='pending' AND nextAttemptAt <= now 인 항목을 created_at 순 조회
4. 항목별 전송 → 성공: status='done' / 409(중복): 성공 처리
                실패: attempt+1, nextAttemptAt = now + backoff[attempt]
                attempt >= 6: status='failed'
5. 같은 dreamId의 선행 항목이 pending이면 후속 항목은 건너뛴다 (순서 보장)
```

- backoff: `[1s, 4s, 15s, 60s, 300s, 900s]`
- `idempotencyKey`는 클라이언트에서 생성하고 재전송 시 **바꾸지 않는다.** 이것이 중복 방지의 핵심이다.

**완료 조건:** 기내 모드에서 꿈 3건 기록 → 연결 복구 → 3건 순서대로 처리, 중복 생성 0건.
**테스트:**
- `test/sync/outbox_worker_test.dart` — 백오프 계산, 순서 보장, 409 처리
- 통합: 기내모드 3건 / 전송 중 앱 종료 후 재시작 / 같은 키 2회 전송

---

# C. LLM 엔진 (WO-E1 ~ WO-E7)

**공통**

- 위치: `supabase/functions/engine-{stage}/index.ts`
- 모든 출력은 **JSON 스키마 강제**(structured output 또는 tool use). 자유 텍스트 파싱 금지.
- 입력은 `jobs.payload`에서 읽고, 출력은 `jobs.payload`에 병합 후 다음 단계 job을 생성한다.
- `generation_runs`에 model, tokens, latency, validation, c_ratio, cost, **prompt_version**을 기록한다. **본문은 저장하지 않는다.**
- 프롬프트는 `supabase/functions/_shared/prompts/{stage}.v{n}.ts`로 버전 관리한다.

---

## WO-E1 · Extract

**입력:** `dreams.raw_text`, `recall_answers`
**모델:** 경량, temperature 0.0

**출력 스키마**

```json
{
  "elements": [
    { "type": "person|place|object|event|emotion|sensory",
      "label": "우산 든 여자",
      "detail": "얼굴이 보이지 않음",
      "salience": "high|mid|low",
      "span": [12, 22] }
  ],
  "clarity": "fragment|partial|vivid",
  "empty_slots": ["light","company"],
  "sensitive_flags": ["death","sexual","violence"]
}
```

**규칙**

1. **원문에 있는 것만 추출한다.** 추론·해석·상징 해석을 하지 않는다.
2. `span`은 `raw_text`의 문자 인덱스 [시작, 끝)이다. 출처 시트 강조(S09)에 쓴다. 정확히 매칭되지 않으면 `null`.
3. **clarity 판정 [G5 해결]:** `type='event'`인 요소 수 기준.
   - event 0개 → `fragment`
   - event 1~2개 → `partial`
   - event 3개 이상 또는 장소 전환 2회 이상 → `vivid`
   - 단, 전체 요소가 3개 이하면 무조건 `fragment`
4. **`recall_answers`를 elements로 병합한다 [G8 해결].** `source='recall'`로 표시하고, `모름` 답변은 제외한다. 예: `{"object":"붉은 우산"}` → `{type:'object', label:'붉은 우산', source:'recall'}`
5. `empty_slots`는 PDR §12 문항 은행의 슬롯 키 중 채워지지 않은 것을 **최대 3개** 반환한다. 우선순위: `object > company > place > feeling > light > 나머지`.
6. `sensitive_flags`는 기록을 막지 않는다. E4 생성 규칙(PDR §24-9) 적용 판단에만 쓴다.

**완료 조건:** 실제 꿈 20건에서 스키마 유효 100%, `span` 매칭률 ≥70%.
**테스트:** 고정 입력 10건에 대한 골든 테스트. clarity 판정 경계값 6케이스.

---

## WO-E2 · Link

**입력:** E1 elements, 볼륨 엔티티 레지스트리
**방식:** 규칙 우선, 애매한 경우만 경량 모델 1회

**규칙 단계 (LLM 전)**

| 조건 | 신뢰도 |
|---|---|
| `label` 완전 일치 | 0.95 |
| `label`이 `aliases`에 포함 | 0.90 |
| 정규화 후 일치 (공백·조사 제거) | 0.85 |
| 부분 문자열 포함 | 0.60 → LLM 판정 대상 |
| 불일치 | LLM 판정 대상 (같은 type만) |

**LLM 판정 (해당 요소가 있을 때만)**

```json
{ "matches": [
    { "element_id":"el_12", "entity_id":"ent_3", "confidence":0.72,
      "reason":"둘 다 얼굴이 보이지 않는 여성, 우산 소지" }
] }
```

**임계값 처리 (PDR §13)**

| 신뢰도 | 동작 |
|---|---|
| ≥ 0.85 | 자동 연결. `link_decisions.status='auto'`로 기록하고 리빌에 "이어졌어요"로 표시 |
| 0.50 ~ 0.85 | **사용자 질문 생성** (`status='pending'`). 꿈 1개당 **최대 1건** — 신뢰도가 가장 높은 것 하나만 |
| < 0.50 | 새 엔티티 후보 |

**질문 문안 템플릿:** `"오늘 꿈의 '{element.label}', {scene_no}장의 '{entity.role_name}'과 같은 {인물|장소|물건}일까요?"`

**완료 조건:** 임계값 3구간이 모두 동작하고, 질문은 꿈당 1건을 넘지 않는다.
**테스트:** 규칙 매칭 5케이스, 임계값 경계 3케이스, 질문 1건 상한.

---

## WO-E3 · Plan

**입력:** elements, link 결과, `narrative_memory`, 볼륨 설정
**모델:** 고성능, temperature 0.3

**출력 스키마**

```json
{
  "placement": "continuation|motif|interlude|fragment_attach|standalone",
  "attach_to_scene_id": "sc_9 또는 null",
  "beats": [
    { "kind": "D", "element_ids": ["el_12","el_13"], "note": "복도에 물이 차 있음" },
    { "kind": "C", "reason": "2장의 붉은 문과 오늘의 문을 잇는 전이" }
  ],
  "target_length": 1200,
  "scene_title": "붉은 문"
}
```

**규칙**

1. **placement 판정 순서:** `clarity=fragment`이고 연결 가능한 장면이 있으면 → `fragment_attach`. 아니면 강한 엔티티 연결이 있으면 `continuation`. 모티프만 반복되면 `motif`. 약한 연결이고 짧으면 `interlude`. 연결 없으면 `standalone`.
2. **`fragment_attach`는 대상 장면 끝에만 붙인다 [X2 해결].** 기존 문단 사이에 삽입하지 않는다. `attach_to_scene_id`는 U 문단 유무와 무관하게 안전하다.
3. `target_length`는 PDR §17 상한을 넘지 않는다. `clarity별 상한 × 각색 배수`.
4. `beats`의 C 비트는 **전체 비트의 각색 예산 비율 이내**로 계획한다.
5. `standalone`이면 beats를 만들지 않고 종료한다. E4를 건너뛰고 `dreams.status='archived_only'`로 커밋한다.

**완료 조건:** placement 5종이 각각 재현되는 테스트 케이스가 통과한다.

---

## WO-E4 · Write **[핵심. 가장 오래 걸린다]**

**입력:** beats, 문체, 각색 수준, L0~L5 컨텍스트 (PDR §22)
**모델:** 고성능, temperature 0.8, 재시도 최대 2회

**프롬프트 조립 순서 (캐시 경계 고려)**

```
L0 시스템 규칙       ← 캐시
L1 설정 (각색·문체·POV)  ← 캐시
L2 볼륨 바이블 (엔티티 상위 20)  ← 볼륨 버전별 캐시
L3 story_so_far + open_threads
L4 직전 장면 2개 전문
L5 오늘 (원문, elements, 보강 답변, 연결 결정, beats)
```

**L0 시스템 프롬프트 (필수 조항, PDR §24)**

```
당신은 사용자가 실제로 꾼 꿈을 소재로 한 소설의 한 장면을 쓴다.

절대 규칙
1. 모든 문단에 origin을 표시한다. D는 꿈에서 온 내용, C는 연결·각색.
2. D 문단은 반드시 element_ids를 1개 이상 가진다.
3. salience가 high인 요소는 최소 1회 사용한다.
4. 등장인물은 역할명으로 부른다 ("우산 든 여자"). 실명을 쓰지 않는다.
5. 꿈을 해석하거나 의미를 설명하지 않는다. 교훈이나 요약으로 맺지 않는다.
6. 다음 표현을 쓰지 않는다: 꿈에서 깨어났다 / 마치 꿈처럼 / 그것은 꿈이었다 /
   눈을 떠보니. 이 장면은 꿈이 아니라 현실처럼 서술한다.
7. 장면을 닫지 않는다. 마지막 문단은 열린 이미지나 미해결 요소로 끝낸다.
8. L1의 `narrative_voice` 설정에 맞춰 쓴다. 기본은 3인칭 과거형이다.
   `first_person_past`에서는 화자만 역할명 규칙의 예외이며, 다른 인물은 역할명을 유지한다.
9. 출력은 지정된 JSON 스키마만 낸다.
```

**출력 스키마** — PDR §24의 스키마를 그대로 쓴다. `open_image` 필수.

**재시도 시 프롬프트 추가**

```
이전 시도가 아래 이유로 거부되었다. 같은 문제를 반복하지 마라.
- {V2} 연결 문장 비율이 예산을 초과했다 (52% > 35%)
- {V5} 요소 '붉은 우산'(high)이 사용되지 않았다
```

**폴백 프롬프트 (2회 실패 후)**

```
각색을 최소화한다. 연결 문장은 0~1개만 쓴다.
꿈에 나온 요소를 기록된 순서대로 담백하게 서술한다.
분량은 {target_length × 0.6}자를 넘지 않는다.
```

**완료 조건:**
- 실제 꿈 20건 생성 성공률 ≥90%
- `faithful` C 비율 ≤15%, `balanced` ≤35%
- 금지 표현 출현 0건
- **품질 게이트:** 생성된 20건을 직접 읽고 "다시 읽고 싶다"가 12건 이상 (PDR §28 W1~2 게이트 승계)

**테스트:** 스키마 유효성, C 비율 계산, 금지 표현 검출, 3문체 각 3건 육안 검수.

---

## WO-E5 · Validate

**규칙 기반 우선. V5·V7만 경량 모델.**

| ID | 검사 | 구현 |
|---|---|---|
| V1 | JSON 스키마 유효 | zod 또는 ajv |
| V2 | C 비율 ≤ 예산 | `C 문단 글자 수 합 / 전체 글자 수` |
| V3 | 새 엔티티 ⊆ (오늘 elements ∪ 레지스트리) | 집합 연산. `free` 모드는 C 태그면 통과 |
| V4 | 총 길이 ≤ 상한 | 글자 수 |
| V5 | high salience 요소 누락 없음 | 경량 모델 판정 (문자열 일치로는 부족) |
| V6 | locked 문단 해시 불변 | E4 출력에 locked 문단이 포함되면 **즉시 폐기** |
| V7 | 금지 표현, 실명, 안전 기준 | 정규식 + 경량 모델 |

**금지 표현 정규식 (V7 일부)**

```ts
const BANNED = [
  /꿈(에서|을)\s*(깨|깨어)/, /마치\s*꿈\s*처럼/, /그것은\s*꿈이었/,
  /눈을\s*떠보니/, /꿈속에서/,
];
```

**폴백 검증 (`E5-relaxed`):** V1, V3, V6만 적용한다. 폴백 결과까지 거부하면 사용자에게 줄 것이 없어진다.

**완료 조건:** 위반 케이스 7종을 각각 주입해 해당 V가 정확히 탐지한다.

---

## WO-E6 · Commit

**LLM 호출 없음.** `commit_scene` RPC를 호출하는 얇은 래퍼다.

**처리**

1. E4 출력 + E2 링크 결과 + E1 elements를 `p_payload`로 조립
2. `commit_scene()` 호출 (단일 트랜잭션, 멱등)
3. 반환된 `scene_id`를 `jobs.payload`에 기록
4. 다음 단계 `remember` job 생성
5. `standalone`이면 장면 없이 `dreams.status='archived_only'`만 갱신

**완료 조건:** 같은 job을 2회 실행해도 장면이 1개만 생긴다.
**테스트:** 멱등 2회 호출, 트랜잭션 롤백(중간 실패 주입).

---

## WO-E7 · Remember

**입력:** 커밋된 장면, 기존 `narrative_memory`
**모델:** 경량, temperature 0.2

**출력**

```json
{
  "story_so_far": "…(1500자 이내)",
  "open_threads": [
    { "id": "t3", "text": "붉은 문 너머에 무엇이 있는지", "status": "open" }
  ],
  "genre_scores": { "미스터리": 0.6, "초현실": 0.4, "드라마": 0.2, "...": 0 },
  "motifs": ["붉은 문", "물", "계단"]
}
```

**규칙**

1. `story_so_far`는 **1,500자 상한**. 초과하면 오래된 내용부터 압축한다.
2. `open_threads`는 최대 5개. 해소된 스레드는 `status='closed'`로 표시하고 3개 초과 시 오래된 것부터 제거한다.
3. `genre_scores`는 이번 장면에 대한 점수다. 볼륨 프로필 갱신은 **DB에서** `profile = 0.7×profile + 0.3×scene` 으로 계산한다 (PDR §18). LLM에 누적 계산을 맡기지 않는다.
4. **E7이 실패해도 E6 커밋을 되돌리지 않는다 [§6.7].** `jobs.status='failed'`로 두고 사용자에게는 아무것도 표시하지 않는다. 다음 꿈 처리 시 이전 장면들로 재계산한다.
5. `open_image`는 E4가 이미 `scenes.open_image`에 저장했다. E7은 이를 `open_threads` 후보로 참고만 한다 [X4].

**완료 조건:** 장면 10개 누적 후에도 `story_so_far` ≤1,500자, L2+L3 합계 ≤3.5k 토큰.

---

## WO-14 · 작업 큐 워커

`[신규] supabase/functions/engine-worker/index.ts`

```
1. claim_job() 호출 → null이면 종료
2. job.type에 따라 해당 단계 함수 실행
3. 성공: jobs.status='done', payload 병합, 다음 단계 job INSERT
         → 즉시 self-invoke (지연 최소화)
4. 실패: attempt<3이면 status='queued' + 백오프, 아니면 'failed'
5. 타임아웃 60초
```

`[신규] supabase/migrations/0008_cron.sql`

```sql
select cron.schedule('engine-worker', '*/10 * * * * *',
  $$ select net.http_post(url := '...engine-worker', headers := '...') $$);
select cron.schedule('reap-zombies', '* * * * *', $$ select reap_zombie_jobs() $$);
```

**완료 조건:** 동시 invoke 10회에서 중복 처리 0건.
**테스트:** 동시성 테스트, 타임아웃 주입, 좀비 회수.

---

# D. UI 연결 (WO-15 ~ WO-21)

## WO-15 · S06 처리 구간 재작성 (Timer → Stream)

**배경:** `[코드]` `capture_flow.dart`의 `_startProcessing()`이 `Timer.periodic`으로 `_processingStage`를 0→3으로 올린다. 이건 배선이 아니라 **재작성**이다.

**제거 대상 (실측):** `_processingTimer`, `_processingStage`, `_startProcessing()` 내부의 타이머 로직.

- `watchJob(dreamId)` → Realtime 구독 (`jobs` 행).
- **폴백:** Realtime 미연결 또는 백그라운드 복귀 시 3초 폴링, 최대 2분.
- 단계 라벨 매핑 (VS §10):

| job.type | 라벨 |
|---|---|
| extract | 꿈을 읽는 중 |
| link | 이어질 곳을 찾는 중 |
| plan, write | 장면을 쓰는 중 |
| validate | 확인하는 중 |

- **20초 초과:** 도트 속도 절반, "다른 일을 하셔도 돼요. 완성되면 알려드릴게요."
- **실패:** 도트가 S0로 흩어짐. "장면을 만들지 못했어요. 꿈은 보관함에 저장되어 있어요." + [다시 시도]. **사과 문구를 쓰지 않는다.**
- **[제안] 도트 연동:** E1 결과의 `elements.length`를 받아 덩어리 수를 결정한다 (VS §10). `jobs.payload`에서 읽으면 추가 호출이 없다. `[코드]` 현재 `_DotCluster`가 이미 고정 개수를 받으므로 **파라미터만 실데이터로 바꾸면 된다.**
- **`_ProcessingDots` 위젯의 시각 구현은 그대로 둔다.** 입력 소스만 타이머에서 스트림으로 바꾼다.

**완료 조건:** 와이파이→LTE 전환 중에도 단계 표시가 끊기지 않는다.

---

## WO-16 · 실제 녹음과 STT

**선행 결정:** D2 (온디바이스 확정).

**제거 대상 (실측):** `capture_flow.dart`의 `_transcript` 상수, `_recordingTicks`, `_toggleRecording()`의 3초 후 고정 문장 주입 로직.

- `[신규] ios/Runner/SpeechChannel.swift` — `SFSpeechRecognizer`, `requiresOnDeviceRecognition = true`, locale `ko-KR`.
- MethodChannel/EventChannel로 부분 결과를 Flutter에 스트림으로 전달한다.
- **오디오를 파일로 저장하지 않는다.** `AVAudioEngine` 버퍼를 인식기에 직접 전달한다.
- 실패 경로:

| 상황 | 처리 |
|---|---|
| 마이크·음성인식 권한 거부 | 텍스트 모드 전환 + 설정 안내 1회 |
| `supportsOnDeviceRecognition == false` | **텍스트 모드 자동 전환.** 서버 폴백 없음 |
| 인식 결과 공백 | "들리지 않았어요. 직접 적어보시겠어요?" |
| 5분 초과 | 자동 종료 후 저장 |

- 부분 결과의 음량(RMS)을 도트 생성에 연결한다 (VS §9).

**완료 조건:** 실기기에서 기상 직후 녹음 10건을 수행하고 정확도를 기록한다 (PDR §31-4 검증 이행).
**테스트:** 권한 3상태, 무음, 장시간, 중단, 백그라운드 전환.

---

## WO-17 · S10 편집과 U 잠금 (앱)

- 문단 롱프레스 → 인라인 편집 (VS §15.2: 탭은 출처 시트, 롱프레스는 편집). `[코드]` `ReaderPassage`에 `onTap`은 있으나 `onLongPress`가 없다. 추가한다.
- 저장 시 `user_edit_passage` RPC 호출. **직접 UPDATE 금지.**
- 저장 후 `origin='U'`, `locked=true`. 출처 시트 배지가 "내가 씀"으로 바뀐다.
- `original_text`가 있으면 "되돌리기" 노출 → `revertPassage()`로 `origin` 복원.
- **[제안] "직접 한 문장 쓰기"** (PDR §9 Author 단계 장치): 장면 끝에 빈 문단을 추가하는 버튼. 20자 이상이면 +0.5 MU.
- 편집 중에는 도트를 표시하지 않는다 (VS §14).

**완료 조건:** 엔진 경로로 U 문단 수정을 시도하면 DB 트리거가 차단한다.
**테스트:** 편집 → 리로드 유지 / 되돌리기 / 엔진 재실행 후 U 보존.

---

## WO-18 · S09 출처 시트 실데이터

- `passages.source_element_ids` → `dream_elements` → `dreams.raw_text`.
- `span`으로 원문 발췌를 `sky-100` 배경 강조 (VS §3.1). `[코드]` `_showSource()`가 현재 origin만 받아 고정 문구를 띄운다. `Passage`를 받도록 시그니처를 바꾼다.
- `span`이 null이면 `label`로 문자열 검색, 그것도 실패하면 **원문 전체를 강조 없이** 표시한다.
- C 문단은 `c_reason` 1줄 표시. U 문단은 "내가 쓴 문장" + 편집 일시.

**완료 조건:** 실제 생성 장면에서 모든 D 문단이 원본 꿈으로 연결된다.

---

## WO-19 · S01 온보딩과 AI 처리 고지

- 3장: ① 한 문장 정의 ② 출처 개념(문단→꿈 연결 예시) ③ AI 처리 고지 + 동의.
- 고지 문안에 포함할 것: 꿈 내용이 원고 생성을 위해 AI 모델 제공사로 전송된다는 사실, 채택한 제공사명, **학습 사용 여부와 보존 기간은 실제 API 약관을 확인해 사실대로 기재**한다 (PDR §25).
- 만 14세 미만 가입 차단 (생년 입력이 아니라 **연령 확인 체크**로 간소화).
- 동의 기록: `profiles.consented_at`, `consent_version`.

**완료 조건:** 동의 없이 `enqueue`를 호출할 수 없다 (Edge Function에서도 검증).

---

## WO-20 · S16 설정 (계정 삭제·내보내기)

**App Store 심사 요건이다. 자를 수 없다.**

- 계정 삭제: 확인 다이얼로그 → `delete_user_data(user_id)` RPC → `auth.admin.deleteUser` → 로컬 DB 삭제 → 로그아웃.
- 데이터 내보내기: 꿈 원문, 원고 전문, 출처 매핑을 JSON으로 생성해 공유 시트로 전달한다.
- 앱 잠금: `local_auth`(Face ID/패스코드). 기본 OFF, 온보딩에서 1회 제안.
- 알림 시간 설정 UI는 두되, 실제 발송은 M2.

**완료 조건:** 삭제 후 모든 테이블에서 해당 user_id 행이 0개다.

---

## WO-21 · 분석 이벤트 8종

`dream_saved` / `recall_answered` / `recall_skipped` / `processing_completed` / `processing_failed` / `reveal_viewed` / `link_decided` / `passage_edited`

- 모두 `AppLog.event()` 경유. 허용 키만 통과.
- `processing_failed`에는 `stage`와 `code`만 담는다. 실패 원인 텍스트를 담지 않는다.

**완료 조건:** 전체 플로우 1회 실행 후 페이로드를 덤프해 원문 조각 0건을 확인한다.

---

## WO-22 · 통합 테스트와 실꿈 리허설

1. `integration_test/full_flow_test.dart` — 로그인 → 기록 → 보강 → 처리 → 리빌 → 편집 → 보관함.
2. 실제 꿈 20건 배치 실행 후 §9.3 운영 지표 측정.
3. 골든 테스트: S03/S06/S07 × Day/Night.
4. P1~P12 체크리스트 수동 검수.

**완료 조건:** 보고서 §9.3 전 지표 충족 + §9.1 전 항목 통과.

---

# 부록 A. v0.1 → v0.2 변경 요약

| 항목 | v0.1 | v0.2 | 사유 |
|---|---|---|---|
| WO-00 | 없음 | **신설 (5h)** | 평면 7파일·의존성 0개 |
| WO-06 | Repository 인터페이스 | **도메인 모델 신규 작성** | 모델이 존재하지 않음 |
| WO-07 | Drift 이식 | **Repository + MemoryRepository** | 이식할 대상 없음 |
| WO-08 | Apple 로그인 | **화면 4개 배선 (신설 10h)** | 위젯 리터럴이 실질 작업 |
| WO-01 | 새 CI 워크플로 | **기존 `ci.yml`에 스텝 추가** | CI가 이미 존재 |
| WO-15 | 5h 배선 | **7h 재작성** | Timer 기반 |
| 셰이더 WO | 잠재 포함 | **삭제** | 이미 CustomPainter |
| 공통 규칙 | 5개 | **7개** (AGENTS.md 우선, STATUS.md 갱신) | 저장소 관례 |
| 총 시간 | 134h | **142h** | 위 합산 |

**번호 이동:** 구 WO-07~20 → 신 WO-09~22.

---

# 부록 B. WO 착수 전 확인 사항

C1~C6은 코드 확인으로 모두 해소됐다. D1·D2·D6도 사용자 답변으로 확정됐고, 아래 표의 미확정 항목만 남는다.

| WO | 결정 상태 |
|---|---|
| WO-00 | **D6 확정** — 저장소 재편 승인, 착수 가능 |
| WO-16 | **D2 확정** — iOS 온디바이스 STT 전용, 서버 폴백 없음 |
| WO-E4 | **D1 확정** — L1 설정형, 기본 `third_person_past` |
| WO-06 (AdaptationLevel) | D 결정 §31-1 (`free` 모드 M1 포함 여부) — 현재 제외로 작성됨 |
| 전체 일정 | D5 (8~9주 수용 여부) |

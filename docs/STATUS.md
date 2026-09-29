# MUMUMONG Implementation Status

Last updated: 2026-09-29

## Summary

The repository contains a runnable Flutter implementation of the core MUMUMONG loop. Its primary screens are wired to restart-safe Drift storage, the Apple-to-Supabase authentication flow has secure session persistence and volume-aware routing, and both deterministic mock and hosted AI engines exist. The dedicated `mumumong` Supabase project (`dtdmfjovpufyyekdumga`) has migrations 0001–0014 and E1–E7 plus the queue worker deployed. The hosted app path creates its first short volume, pushes a locally captured dream through authenticated RLS, follows the Groq job, and pulls the generated elements, scene, passages, provenance and progress back into Drift before reveal. Development builds can use a device-bound anonymous trial account while Apple provisioning is pending. Dream-original edits, dream removal/deletion, passage edit/revert/read, scene placement and link decisions use the durable Outbox and authenticated cloud mutations. Client retries use an authenticated safe upsert that cannot downgrade engine-owned completion, clarity, or safety fields.

## Implemented locally

| Area | Status | Notes |
|---|---|---|
| S01 Apple Sign In | Implemented, provisioning pending | Native Apple credential exchange through Supabase, cancellation/error/retry states, automatic refresh, and Keychain-backed session storage. Development builds also offer an anonymous trial account backed by hosted Supabase; live Apple-account verification still depends on Apple and Supabase provider configuration |
| S02 Volume Setup | Implemented for M1 | Authenticated empty accounts choose adaptation, style, and first-/third-person POV. First person is the default; the dream recorder remains the protagonist in either POV |
| S03 Manuscript Home | Repository-backed prototype | Dot cover, MU percentage, event-derived delta reason, open scene |
| S04 Capture | Repository-backed prototype with autosave and native STT | Text autosaves after 500ms. iOS uses `ko-KR` `SFSpeechRecognizer` with `requiresOnDeviceRecognition=true`; audio buffers are never written to files, partial text saves immediately, RMS drives dots, and unsupported/denied/empty paths return to text. Real-device accuracy evaluation remains open |
| S05 Recall | Prototype | Three fixed-bank questions and skip action |
| S06 Processing | Hosted round-trip connected | The visual stage follows actual job types instead of a timer. The remote client pushes the owned dream, enqueues with the stable dream UUID, invokes the authenticated worker through a browser-safe CORS path, combines Realtime with a 3-second polling fallback, and pulls server results into Drift before reveal. A terminal retry creates a fresh extract job; an interrupted queued job can be resumed from Archive. Standalone results exit to explicit archive guidance instead of hanging |
| S07 Reveal | Repository-backed prototype | Generated passage marks and repository placement mutations |
| S08 Reader | Repository-backed prototype | Scene selection, vertical reading, running header, Night Paper, long-press edit to locked U, and provenance-preserving revert |
| S09 Source Sheet | Repository-backed | D/C/U source display; D resolves exact element IDs and highlights Unicode spans or safe label matches in the raw dream |
| S12 Archive | Repository-backed prototype | Typed monthly dream list and status filters |
| S13 Dream Detail | Connected | Original text is editable without changing the existing scene, clarity or MU; unfinished dreams can resume processing; deletion explicitly chooses whether to remove or detach the derived scene and syncs to the cloud |
| Brand system | Implemented | MaruBuri, Pretendard, paper/ink/sky tokens, app icon |
| Domain contract | Implemented | Nine immutable models, centralized DB enum mapping, serialization, and pure MU/clarity rules |
| Repository boundary | Implemented | Reusable repository contract runs against both memory and Drift implementations; DreamElement reference integrity and raw progress-event cache semantics are preserved |
| Local persistence | Implemented | Drift schema v1 mirrors manuscript data and adds drafts, outbox, reader positions, and sync state; mock mode seeds the prototype while hosted mode starts from the authenticated cloud volume |
| Drift prerequisites | Implemented | `drift_flutter` native bootstrap plus lock-matched `sqlite3.wasm` and `drift_worker.js` |
| Mock engine boundary | Implemented | `ENGINE=mock` and `MOCK_CASE` select deterministic success, retry, fallback, or failure; commits are idempotent and persist through both memory and Drift stores without network or LLM calls |
| E5 Validate rules | Deployed and cloud-smoked | Deterministic V1–V7 checks, including required/existing source elements. Q-07/Q-31 own further fidelity judgment; there is no separate M1 semantic V5/V7 enhancement task. Hosted secret-key and local legacy-key worker authentication are both covered; public keys are denied |
| E6 Commit assembly | Deployed and cloud-smoked | Real `commit_scene` RPC, retry deduplication, remember enqueue, rollback on invalid provenance, and worker-only access are verified locally; an authorized hosted call reaches database lookup while public callers are denied |
| E1–E4 + E7 model stages | Deployed and cloud-smoked | Groq `openai/gpt-oss-20b` handles extract/link/remember and first-opening passage expansion; `openai/gpt-oss-120b` handles plan/write and full-scene polish. First dreams keep the recorder as protagonist, preserve agent/recipient/goal/causal order, use a source-image title, and are deterministically normalized to prologue scenes. Their opening contract requires a concrete hook, immediate want, anomaly, protagonist choice, and unresolved consequence across at least seven passages and 70% of the planned length; short drafts are expanded before a whole-scene coherence pass. This abstracts public serialized-fiction pacing without copying a work's prose |
| WO-14 worker | Deployed | Atomic per-user/service job claiming, browser-safe authenticated invocation, self-invocation, bounded retry scheduling, metadata-only diagnostics, and public-key denial are implemented. A durable cron recovery schedule is still pending |
| Offline retry core | Authoring path wired | Dream creation/processing, dream-original edit/removal/deletion, passage edit/revert/read, scene placement and link-decision mutations enter the durable FIFO in the same Drift transactions and are delivered to Supabase on connectivity/foreground wakeups |
| Privacy settings | Implemented locally and partially deployed | JSON export includes dreams, drafts, manuscript and provenance but excludes credentials/job payloads; app lock uses Face ID/device passcode and Keychain with default OFF; account deletion requires typed confirmation, calls an authenticated Edge Function for server deletion, then clears local tables and signs out |

## Simulated or not connected

| Area | Current boundary |
|---|---|
| Persistence | Active-volume bootstrap, capture-to-reveal push/pull, dream edit/removal/deletion, passage edit/revert/read, placement and link decisions are connected |
| Voice and STT | Native on-device implementation builds and its Flutter callback behavior is tested; the required ten-recording quality check needs a physical iPhone and human review |
| AI pipeline | E1–E7 and the worker are deployed and a real hosted dream completed the entire pipeline. Q-series engine work takes priority; Q-07/Q-31 replace the separate semantic V5/V7 task. Durable worker recovery scheduling waits until after Q-02 |
| Backend | The dedicated cloud project has migrations 0001–0014, RLS, locked-passage trigger, authenticated dream upsert/removal/deletion and edit/revert/read/link mutations, available-at job claiming, zombie reaping, E1–E7, the worker, authenticated account deletion, and app-equivalent capture push/pull. The dream upsert preserves server-owned completion, clarity, and safety fields when stale Outbox work arrives. Durable cron recovery remains open |
| Offline | Capture autosave/restore plus durable create/process and author-interaction delivery are implemented. The next app launch imports hosted results; background completion notification remains open |
| Notifications | Morning/night and completion notifications are not present |
| Completion | S14 and PDF export are not present. State transitions and UI may proceed independently; LLM completion editing waits until after Q-32. PDF layout is independent of the engine |
| Privacy controls | App lock, JSON export, and deletion are present. Groq is selected, but the onboarding provider notice, retention-language review, and server-enforced consent gate remain open |

## Verified baseline

- `dart analyze lib test integration_test`: no issues
- `flutter test`: 120 tests passing, including S02 creation/recovery, anonymous trial routing/retry, fresh terminal engine retries, dream-original edits, stable Outbox enqueue, authenticated push/pull and author-interaction mapping, engine result import, standalone archive handling, Reader edit/revert, Unicode source highlights, export redaction, local wipe and app lock
- `flutter test integration_test`: 5 iOS integration scenarios passing: four capture-to-reveal engine cases plus native SQLite autosave/reopen/restore/discard. The restart check reopens storage and recreates the screen; it does not simulate an OS kill inside the 500ms debounce window
- `flutter build web --release`: passing
- Hosted web runtime smoke: Drift opens with the lock-matched wasm/worker assets, anonymous trial sign-in reaches S02, creates the first short volume, and opens S04 capture
- `flutter build ios --simulator --no-codesign`: passing
- Apple authentication screen runtime smoke: passing on iPhone 17 Pro Simulator
- Drift iOS runtime open/query/close smoke: passing on iPhone 17 Pro Simulator (SQLite 3.53.4)
- `supabase db reset`: migrations 0001–0013 and seed passing
- `supabase test db`: 149 database tests passing, including 0014 engine-version schema/default/candidate tagging
- `supabase db lint --local --schema public --level warning`: no schema errors
- `npx deno task verify` in `supabase/functions`: 88 tests passing, including fake-port coverage for all six Q-02 cores
- `node tool/engine_smoke.mjs` with `supabase functions serve`: real HTTP validation/audit, worker authorization, repeated commit, remember deduplication, and transaction rollback passing; disposable smoke account removed after verification
- Mobile visual QA at 390×844: capture through reveal, manuscript growth, Reader, source sheet, and Night Paper
- Cloud deployment smoke: migrations 0001–0013 match remote; every engine stage accepts only the hosted service secret; browser preflight succeeds for the worker; public manuscript reads and anonymous account deletion are denied. Hosted anonymous sign-in is enabled and disposable trial accounts are automatically removed
- Hosted safe-upsert smoke: an authenticated stale `processing` retry updates client-authored dream text while preserving the server-owned `in_manuscript` status, clarity, and safety flags
- Hosted AI pipeline smoke: disposable authenticated accounts repeatedly completed extract → link → plan → write → validate → commit → remember, including write/validate regeneration, and committed passages with real D provenance; all disposable owned data was then deleted
- Hosted app round-trip smoke: an RLS-constrained disposable user created the S02 short volume, idempotently upserted the same dream twice, processed it with the stable dream UUID, read back a prologue scene and real D provenance, edited the original, then deleted the dream while preserving and detaching the scene before automatic cleanup

## Recommended next milestone

Connect the durable local implementation to the now-live backend:

1. Follow Q-series engine work first; durable worker recovery scheduling waits until after Q-02. The server-enforced AI consent gate and provider/consent-version data can proceed independently, except during Q-02
2. Configure Apple Sign In in the Supabase project and verify a real Apple account end to end
3. Run the ten-recording Korean STT quality check on a physical iPhone

The first milestone is complete only when a dream survives an app restart, belongs to the authenticated user, cannot be read by another user, and can enter a retryable processing job without its text appearing in logs.

## Q-series quality work

- Canonical instructions: `docs/MUMUMONG_Q_WorkOrders.md` v1.1; Q-01–Q-03 and Q-05 tooling are complete. Q-04 implementation/stub verification is ready; its actual Anthropic E4 completion criterion is pending an API key. No unrelated M1 work was performed alongside Q-02.
- The `edfc13c` baseline (`write.v10`, `plan.v6`, opening expansion and polish) is frozen. No engine or prompt behavior changed in Q-01.
- Generated manuscripts may change only through the engine. The previously manually corrected hosted scene is not evidence of automatic generation quality and must not enter quality comparisons or Q-40 editing data.
- Q-01 tooling: JSON Schema, synthetic fixture (2 singles + 1 four-dream sequence), metadata-only schema/count/duplicate-ID validator, ignored private corpus/runs/judgments directories, and a CI tracked-data guard. Sentinel is separate from dev/holdout and contributes zero gate units; its human clarity judgment may remain unset.
- Q-01 verification (2026-09-29): 10 evaluation-tool tests pass, including malformed-input output redaction and forced staging in each private directory in an isolated Git repository. The local sentinel is ignored and validates with zero gate units. Log/privacy guards, Dart formatting, 120 Flutter tests, 74 existing engine tests, and a web release build to a temporary output directory pass. `flutter analyze` passes on an ASCII-path copy of the unchanged Flutter sources, avoiding the known Korean-path analyzer crash. iOS runtime and database checks were not rerun for this tooling-only change.
- Real dev/holdout collection, LLM evaluation, blind judgments, and Q-08 baseline measurement remain pending. The existing Flutter/Deno checks verify functionality, not literary quality.

### Q-02 shared stage cores

- Extract, link, plan, write, validate and remember now expose database-free `runX` cores; HTTP entrypoints load context, call the core, and persist results. The v10 write core preserves passage expansion, optional polish, request payloads, model parameters, title/provenance normalization and fallback behavior.
- `LlmPort.structured` uses roles instead of model names. Production mapping defaults remain Groq 20b for extract/link/write_aux/remember/judge and 120b for plan/write/polish. Q-02 initially implemented only the Groq adapter; Q-04 adds providers below. No model overrides are configured in the hosted project.
- `scene_loop_policy.ts` is the shared authority for regular attempts 0–2, fallback attempt 3, the existing 0.6 fallback target and strict/relaxed selection. Core results expose metadata-only per-call `modelRuns`; production preserves the legacy single aggregated write audit so the existing accounting baseline does not change.
- Migration 0014 adds `generation_runs.engine_version`, required with default `v10`. Model and deterministic-validation audit writes also use `ENGINE_VERSION` (default `v10`). The migration and the six refactored functions are deployed. Server-side bundling requires `--import-map supabase/functions/deno.json` to retain the existing pinned dependencies.
- Local verification: 88 Deno tests and 149 DB tests pass; local HTTP smoke verifies actual v10 audit persistence, validation-to-commit enqueueing, worker authorization, retry deduplication and rollback. The older local smoke attempted to create a second active commit job after validation already queued one; its fixture now consumes the real queued job. The hosted `tool/cloud_pipeline_smoke.mjs` is unchanged.
- Hosted verification: the unchanged pipeline smoke completes extract → link → plan → write → validate → write → validate → commit → remember with seven passages. `tool/cloud_engine_version_smoke.mjs` separately verifies an actual Groq extract audit with `engine_version=v10`; both tests remove their disposable accounts and owned data. No existing generated manuscript was directly corrected.
- Flutter formatting, 120 tests, web release build (temporary output), and `flutter analyze` (matching ASCII-path source copy) pass. Q-01 tooling regression tests (10) and log/privacy guards also pass. iOS runtime and real dev/holdout quality/blind evaluations were not executed in Q-02.

### Q-03 offline evaluation runner

- `tool/eval/run.ts` runs the same E1/E2/E3/E4/E5 cores and shared retry/fallback policy; sequence cases also use E7 with an in-memory commit approximation. `nextSceneOrderKey` and `buildCommitPayload` are reused. Production-shaped context projections preserve recent-scene/entity limits. No production engine, model, prompt, generated DB manuscript, or app screen was changed.
- `eval/configs/baseline_v10.json` pins role models/settings. Fixtures use a deterministic fake `LlmPort` without credentials/network. Actual dev/sentinel execution maps models explicitly from the config rather than operational `MODEL_*` overrides. Q-03 initially supported Groq; Q-04 adds registered providers below without changing the baseline config.
- Private run artifacts include config/prompt versions/git commit/source and corpus fingerprints, case outputs/final provenance/validation attempts/fallback/per-call usage, and cost/latency summaries. Optional expansion/polish usage is included; unknown failed-call usage or unpriced models mark costs incomplete, not free. All outputs stay in ignored `eval/runs/`; directories/files are created with 0700/0600 permissions.
- Resume finds the latest matching config/set/selected IDs/corpus/source/git revision, skips successful cases and restarts failed/incomplete cases. Atomic checkpoints and serialized result/summary replacement keep one line per case. PID locks prevent concurrent writers and allow dead-writer recovery on macOS/Linux. Sequence failure stops that sequence, not other cases. README documents differences from SQL commit/RLS/queue/progress/U edits.
- Sentinel is separately selected and contributes zero gate units. Fixtures also contribute zero quality gate units. Holdout execution is blocked before reading inputs until Q-32. `--lint`/`--fidelity` explicitly fail as unimplemented rather than claiming those checks ran.
- Verification (2026-09-29): 26 evaluation-tool tests (16 new runner + 10 corpus/privacy) pass, including single 2 + sequence 1 / six dreams, second-dream E2 visibility and auto-linking to the first committed entity, memory/order progression, retries/fallback, failed-case isolation, per-call cost/quantiles, resume/checkpoint deduplication, live/stale locks, partial selection, argument/log redaction and synthetic-only sentinel isolation. Existing 88 engine tests and 120 Flutter tests pass, as do Flutter formatting, matching ASCII-path `flutter analyze`, and web release build to a temporary directory (live preview not overwritten).
- Unverified in Q-03: real dev/sentinel provider runs and literary quality, holdout (intentionally unopened), blind judgments/Q-08 measurements, iOS runtime, database/cloud end-to-end checks. The runner changes tooling only; no cloud deployment is required.
- Actual root CLI smoke: `--set fixtures` reports three successful cases / six dreams; immediate `--resume` skips all three successful cases. Log/privacy guards pass, `git status` contains no private run artifacts, and all four frozen baseline files are byte-identical to `edfc13c`.

### Q-04 multi-provider LLM layer — actual-call criterion pending

- `_shared/llm/` now provides typed structured/text calls, direct Groq/Anthropic/OpenAI adapters, a verified model/capability/price registry, and role routing. Existing imports remain compatible. Provider-specific parameters stay inside adapters; stage Zod contracts remain the final gate. Frozen prompts/opening helpers and default operational Groq models are unchanged.
- Structured modes: Groq strict-schema → schema-400 JSON object fallback; Anthropic forced schema tool; OpenAI strict schema. Only 429/5xx retry twice with exponential backoff; the Groq mode fallback shares that budget. No cross-provider fallback or private generation cache. Body/parse/network/stream errors are redacted to fixed metadata codes.
- Model IDs and uncached token prices were checked against primary provider documentation on 2026-09-29. Anthropic temperature is omitted for the registered models' parameter restrictions. Registry entries are compatibility candidates, not a model-quality selection. `estimatedCostKrw` and evaluation cost-completeness both read the registry. See `docs/LLM_PROVIDERS.md` for sources and limitations.
- Verification: 120 engine tests pass (32 new adapter tests + all previous 88, including unchanged `llm_test.ts`); 31 evaluation tests pass (18 runner + 3 E4 smoke + 10 corpus/privacy). Stubs verify each provider's success, caller-Zod rejection, text, transient retries, terminal HTTP failures, credential validation, body redaction and parameter isolation. Synthetic E4 uses the real frozen write core and exactly one Anthropic stub call; it does not claim a live model result.
- Flutter format, 120 tests, web release build to `/tmp/mumumong-q04-web.IZ3wfl`, and log/privacy guards pass. Root `flutter analyze` encounters the existing Korean-path LSP crash; analyze passes on a verified identical ASCII-path source copy. Live preview `build/web` was not overwritten. No Flutter/iOS/product behavior change.
- **Unverified / completion pending:** local real `MODEL_WRITE=anthropic:claude-sonnet-5` E4. The actual smoke command fails preflight with `provider_not_configured`; local and hosted Anthropic secrets are absent, so no provider request was made. `tool/eval/smoke_write.ts` is ready to rerun after local key setup and prints metadata only, reads no private corpus, and writes no DB manuscript. OpenAI live requests, new-code remote deployment/cloud E2E, iOS runtime and literary quality/blind judgment remain unverified. Holdout remains unopened. No hosted model or secret was changed.

### Q-05 blind judging and reports

- `tool/eval/judge.ts` serves a local-only blind A/B reader at 127.0.0.1; execution/model names and left/right mapping never reach the UI. It intersects cases from matching corpus hashes, collapses raw dreams by default, hides provenance until toggled, and presents all four sequence scenes as one unit. Persisted random seed reproduces placement. Votes/reason chips/readiness save atomically; writer locks, stale PID recovery, serialized updates and revisions protect resume and concurrent windows. Missing complete manuscripts auto-lose alongside pipeline failures; both failures are separate auto-ties.
- `report.ts` emits metadata-only win/tie counts, exact one-sided sign tests, automatic failures, side-specific readiness, reason/problem chips, and clarity/kind breakdowns. G1/G2/G3 formulas follow §3.2 and fail closed on missing quality evidence, incomplete judgments/sets, fixtures/sentinel or invalid comparison settings. Final provenance/V2 use actual final passages/elements, not historical retry counts. Later hash-bound Q-07/Q-09 metric sidecars refresh on judge restart without discarding votes/seed. Real holdout reads remain locked until Q-32.
- Additional file-based fidelity-audit (15 cases), pick, paragraph annotate and professional-rewrite comparison modes are implemented; their upstream measurements/content are not. Reference/pro inputs are now ignored and covered by the tracked-data CI guard. API Host/Origin/token checks, CSP/no-store/no-referrer, plain-text DOM rendering and private file modes protect local text. No provider call, production engine/model/prompt, Flutter UI, database manuscript or remote deployment changed.
- `judge_demo.ts` creates two real Q-03 synthetic fixture runs and opens an API-key-free demo. Its fixture banner and ineligible gate flag distinguish functional tests from literary quality.
- Verification: 56 evaluation tests (25 Q-05 + previous 31), 120 engine tests, 120 Flutter tests, formatting, verified-identical ASCII-path Flutter analysis and web release build to `/tmp/mumumong-q05-web.qKXGzR` pass. Privacy/log guards and four frozen baseline diffs pass. Browser desktop/mobile flow verified rendering, source OFF/raw collapsed, no external resources or page errors, sequence four-scene reading, keyboard votes/navigation, saved-file resume and completion. Actual CLI report for the three synthetic votes shows A=1/B=1/tie=1, p=0.75 and G1 FAIL with missing fidelity correctly marked unverified; this is not a model-quality result.
- Unverified: real dev human judgments, actual literary-quality gates, Q-07/Q-09/Q-22 real data integrations, iOS runtime and cloud E2E. Q-04 live Anthropic E4 remains pending. Details and input/metric contracts: `docs/Q05_BLIND_JUDGING.md`. Next sequential task is Q-06; no Q-06 work was included here.

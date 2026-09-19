# MUMUMONG Implementation Status

Last updated: 2026-09-19

## Summary

The repository contains a runnable Flutter interaction prototype for the core MUMUMONG loop. Its primary screens are wired to restart-safe Drift storage, the Apple-to-Supabase authentication flow has secure session persistence and volume-aware routing, and a deterministic mock engine now drives capture through reveal. The validate and commit engine stages exist as deterministic, unit-tested Edge Function code. Cloud synchronization and production AI services are not yet connected.

## Implemented locally

| Area | Status | Notes |
|---|---|---|
| S01 Apple Sign In | Implemented, provisioning pending | Native Apple credential exchange through Supabase, cancellation/error/retry states, automatic refresh, and Keychain-backed session storage; live account verification still depends on Apple and Supabase provider configuration |
| S02 Volume Setup | Route boundary only | An authenticated account without a remote volume reaches the editorial setup boundary; volume creation remains a later work order |
| S03 Manuscript Home | Repository-backed prototype | Dot cover, MU percentage, event-derived delta reason, open scene |
| S04 Capture | Repository-backed prototype | Dream submission, recall answers, EngineClient enqueue/watch flow, and simulated voice transcription |
| S05 Recall | Prototype | Three fixed-bank questions and skip action |
| S06 Processing | Mock-engine backed prototype | Success, retry, fallback, and final-failure job paths; the four visual dot stages remain locally timed until WO-15 |
| S07 Reveal | Repository-backed prototype | Generated passage marks and repository placement mutations |
| S08 Reader | Repository-backed prototype | Repository scene/passages, vertical reading, running header, Night Paper |
| S09 Source Sheet | Prototype | D/C/U source display and highlighted excerpt |
| S12 Archive | Repository-backed prototype | Typed monthly dream list and status filters |
| S13 Dream Detail | Repository-backed prototype | Original text, recall metadata, derived scene |
| Brand system | Implemented | MaruBuri, Pretendard, paper/ink/sky tokens, app icon |
| Domain contract | Implemented | Nine immutable models, centralized DB enum mapping, serialization, and pure MU/clarity rules |
| Repository boundary | Implemented | Reusable repository contract runs against both memory and Drift implementations; DreamElement reference integrity and raw progress-event cache semantics are preserved |
| Local persistence | Implemented | Drift schema v1 mirrors manuscript data and adds drafts, outbox, reader positions, and sync state; Riverpod defaults to the durable repository and seeds the prototype only for an empty database |
| Drift prerequisites | Implemented | `drift_flutter` native bootstrap plus lock-matched `sqlite3.wasm` and `drift_worker.js` |
| Mock engine boundary | Implemented | `ENGINE=mock` and `MOCK_CASE` select deterministic success, retry, fallback, or failure; commits are idempotent and persist through both memory and Drift stores without network or LLM calls |
| E5 Validate rules | Implemented, not deployed | V1–V7 run as deterministic checks over an E4 draft: schema, C-ratio budget, entity resolution, length cap, high-salience provenance, locked-passage hash, and banned expressions. `E5-relaxed` restricts the fallback profile to V1/V3/V6. The audit record persisted to `generation_runs` carries codes and counts only, never a violation message |
| E6 Commit assembly | Implemented, not deployed | Assembles the `commit_scene` payload from E1 elements, E2 auto links and the E4 draft, refuses `U` passages and unprovenanced `D` passages before the RPC, records `scene_id` on the job, queues `remember`, and routes `standalone` to `archived_only` without a scene |

## Simulated or not connected

| Area | Current boundary |
|---|---|
| Persistence | Local Drift persistence is active; cloud ownership and cross-device sync are not connected |
| Voice and STT | Button drives a sample transcript; no microphone access |
| AI pipeline | A deterministic MockEngineClient exercises the full job/result contract. E5 validation and E6 commit exist as unit-tested rule code but are not deployed or invoked. E1 extraction, E2 linking, E3 planning, E4 generation, E7 memory, and the worker are not implemented: no model provider or model ID has been chosen, so every stage whose work is the model call is still open. The lightweight-model refinements inside V5 and V7 are likewise unimplemented |
| Backend | Local migrations 0001–0007, deterministic seed data, full RLS, locked-passage trigger, transactional RPCs, atomic job claiming, and zombie reaping cron are present; pipeline workers are not connected |
| Offline | Draft storage exists, but capture autosave and the retry queue are not connected |
| Notifications | Morning/night and completion notifications are not present |
| Completion | S14 and PDF export are not present |
| Privacy controls | App lock, export, deletion, and provider notice are not present |

## Verified baseline

- `dart analyze lib test integration_test`: no issues
- `flutter test`: 84 tests passing (including Apple authentication lifecycle, Keychain storage contract, authentication routing/error UI, the complete repository contract against memory and Drift, schema v1 creation, file-database restart persistence, DreamElement reference integrity, raw progress/event-sum consistency, mock-engine scenario/idempotency checks, and UI/domain/core tests)
- `flutter test integration_test/capture_to_reveal_test.dart`: 4 iOS integration scenarios passing against Drift (success, retry, fallback, fail)
- `flutter build web --release`: passing
- `flutter build ios --simulator --no-codesign`: passing
- Apple authentication screen runtime smoke: passing on iPhone 17 Pro Simulator
- Drift iOS runtime open/query/close smoke: passing on iPhone 17 Pro Simulator (SQLite 3.53.4)
- `supabase db reset`: migrations 0001–0007 and seed passing
- `supabase test db`: 108 database tests passing (4 constraints + 49 RLS + 55 trigger/RPC checks)
- `supabase db lint --local --schema public --level warning`: no schema errors
- `deno task verify` in `supabase/functions` (fmt, lint, check, test): 36 engine tests passing — 20 validate (the seven V-code injections, the E5-relaxed profile, budget boundaries, and the audit-record text-safety assertion) and 16 commit (retry idempotency, convergence when a retry follows a crash before enqueue, the deterministic `remember` idempotency key, standalone archiving, payload assembly, input guards)
- Mobile visual QA at 390×844: capture through reveal, manuscript growth, Reader, source sheet, and Night Paper

## Recommended next milestone

Connect the durable local implementation to identity, sync, and processing:

1. Draft autosave and restore/discard UX (WO-12)
2. Offline retry queue and synchronization (WO-13)
3. E1–E4 and E7 stages, which need a model provider decision, and the background worker (E5 and E6 are implemented)
4. Real recording/STT evaluation

The first milestone is complete only when a dream survives an app restart, belongs to the authenticated user, cannot be read by another user, and can enter a retryable processing job without its text appearing in logs.

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
| S04 Capture | Repository-backed prototype with autosave | Text autosaves after 500ms; voice partial callbacks save immediately (voice remains simulated); background/exit flush, one-time restore/discard prompt, silent save retry, and serialized submit/discard prevent late writes from resurrecting drafts |
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
| E5 Validate rules | Local HTTP runtime verified; cloud deployment pending | Deterministic V1–V7 checks, including required and existing source elements in both strict and fallback profiles. V5 provenance coverage and V7 banned expressions are structural checks; model-based meaning and safety checks remain open. Audit rows contain codes/counts only. Worker credentials and matching job stage are required |
| E6 Commit assembly | Local HTTP runtime verified; cloud deployment pending | Real `commit_scene` RPC, retry deduplication, remember enqueue, transaction rollback on invalid provenance, and worker-only access verified against local Supabase. Standalone archiving is also covered by unit tests |

## Simulated or not connected

| Area | Current boundary |
|---|---|
| Persistence | Local Drift persistence is active; cloud ownership and cross-device sync are not connected |
| Voice and STT | Button drives a sample transcript; no microphone access |
| AI pipeline | E5/E6 have been invoked through the local Edge runtime and real database. Cloud deployment is pending: this checkout has no linked project and the CLI has no access token. E1–E4, E7, WO-14, and the model-based parts of V5/V7 remain open; provider/model selection is still required for model calls |
| Backend | Local migrations 0001–0007, deterministic seed data, full RLS, locked-passage trigger, transactional RPCs, atomic job claiming, and zombie reaping cron are present; pipeline workers are not connected |
| Offline | Capture autosave and restore are connected to Drift; the server outbox/retry queue and synchronization remain WO-13 |
| Notifications | Morning/night and completion notifications are not present |
| Completion | S14 and PDF export are not present |
| Privacy controls | App lock, export, deletion, and provider notice are not present |

## Verified baseline

- `dart analyze lib test integration_test`: no issues
- `flutter test`: 92 tests passing, including 8 WO-12 checks for debounce, background flush, one-time restore, discard, voice partial saving, silent retries, in-flight save versus submit/discard, and file-database reopen without a dispose-time save
- `flutter test integration_test`: 5 iOS integration scenarios passing: four capture-to-reveal engine cases plus native SQLite autosave/reopen/restore/discard. The restart check reopens storage and recreates the screen; it does not simulate an OS kill inside the 500ms debounce window
- `flutter build web --release`: passing
- `flutter build ios --simulator --no-codesign`: passing
- Apple authentication screen runtime smoke: passing on iPhone 17 Pro Simulator
- Drift iOS runtime open/query/close smoke: passing on iPhone 17 Pro Simulator (SQLite 3.53.4)
- `supabase db reset`: migrations 0001–0007 and seed passing
- `supabase test db`: 108 database tests passing (4 constraints + 49 RLS + 55 trigger/RPC checks)
- `supabase db lint --local --schema public --level warning`: no schema errors
- `npx deno task verify` in `supabase/functions`: 38 tests passing (21 validation, 16 commit, 1 worker authorization)
- `node tool/engine_smoke.mjs` with `supabase functions serve`: real HTTP validation/audit, worker authorization, repeated commit, remember deduplication, and transaction rollback passing; disposable smoke account removed after verification
- Mobile visual QA at 390×844: capture through reveal, manuscript growth, Reader, source sheet, and Night Paper

## Recommended next milestone

Connect the durable local implementation to identity, sync, and processing:

1. Offline retry queue and synchronization (WO-13)
2. Connect a confirmed MUMUMONG cloud project and deploy the tested E5/E6 functions
3. E1–E4 and E7 stages, which need a model provider decision, and the background worker (E5 and E6 are implemented)
4. Real recording/STT evaluation

The first milestone is complete only when a dream survives an app restart, belongs to the authenticated user, cannot be read by another user, and can enter a retryable processing job without its text appearing in logs.

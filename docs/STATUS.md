# MUMUMONG Implementation Status

Last updated: 2026-09-17

## Summary

The repository contains a runnable Flutter interaction prototype for the core MUMUMONG loop. Its primary screens are wired to restart-safe Drift storage, and the Apple-to-Supabase authentication flow now has secure session persistence and volume-aware routing. Cloud synchronization and production AI services are not yet connected.

## Implemented locally

| Area | Status | Notes |
|---|---|---|
| S01 Apple Sign In | Implemented, provisioning pending | Native Apple credential exchange through Supabase, cancellation/error/retry states, automatic refresh, and Keychain-backed session storage; live account verification still depends on Apple and Supabase provider configuration |
| S02 Volume Setup | Route boundary only | An authenticated account without a remote volume reaches the editorial setup boundary; volume creation remains a later work order |
| S03 Manuscript Home | Repository-backed prototype | Dot cover, MU percentage, event-derived delta reason, open scene |
| S04 Capture | Repository-backed prototype | Dream submission, recall answers, mock job completion, and simulated voice transcription |
| S05 Recall | Prototype | Three fixed-bank questions and skip action |
| S06 Processing | Prototype | Four stage-driven dot states |
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

## Simulated or not connected

| Area | Current boundary |
|---|---|
| Persistence | Local Drift persistence is active; cloud ownership and cross-device sync are not connected |
| Voice and STT | Button drives a sample transcript; no microphone access |
| AI pipeline | E1–E7 screens are timed local state transitions |
| Backend | Local migrations 0001–0007, deterministic seed data, full RLS, locked-passage trigger, transactional RPCs, atomic job claiming, and zombie reaping cron are present; pipeline workers are not connected |
| Offline | Draft persistence and retry queue are not present |
| Notifications | Morning/night and completion notifications are not present |
| Completion | S14 and PDF export are not present |
| Privacy controls | App lock, export, deletion, and provider notice are not present |

## Verified baseline

- `dart analyze lib test`: no issues
- `flutter test`: 79 tests passing (including Apple authentication lifecycle, Keychain storage contract, authentication routing/error UI, the complete repository contract against memory and Drift, schema v1 creation, file-database restart persistence, DreamElement reference integrity, raw progress/event-sum consistency, and UI/domain/core tests)
- `flutter build web --release`: passing
- `flutter build ios --simulator --no-codesign`: passing
- Apple authentication screen runtime smoke: passing on iPhone 17 Pro Simulator
- Drift iOS runtime open/query/close smoke: passing on iPhone 17 Pro Simulator (SQLite 3.53.4)
- `supabase db reset`: migrations 0001–0007 and seed passing
- `supabase test db`: 108 database tests passing (4 constraints + 49 RLS + 55 trigger/RPC checks)
- `supabase db lint --local --schema public --level warning`: no schema errors
- Mobile visual QA at 390×844: capture through reveal, manuscript growth, Reader, source sheet, and Night Paper

## Recommended next milestone

Connect the durable local implementation to identity, sync, and processing:

1. Mock engine boundary and capture-to-reveal integration coverage
2. Draft autosave, offline retry queue, and synchronization
3. E1–E7 pipeline and background worker
4. Real recording/STT evaluation

The first milestone is complete only when a dream survives an app restart, belongs to the authenticated user, cannot be read by another user, and can enter a retryable processing job without its text appearing in logs.

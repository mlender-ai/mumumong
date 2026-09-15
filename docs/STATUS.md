# MUMUMONG Implementation Status

Last updated: 2026-09-15

## Summary

The repository contains a runnable Flutter interaction prototype for the core MUMUMONG loop. Its four primary screens are wired to a repository-backed memory implementation, but it is not yet connected to durable storage or production AI services.

## Implemented locally

| Area | Status | Notes |
|---|---|---|
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
| Repository boundary | Implemented | Reusable repository contract, seeded memory implementation, DreamElement reference integrity, raw progress-event cache semantics, Riverpod providers, and four-screen UI wiring |
| Drift prerequisites | Implemented | `drift_flutter` native bootstrap plus lock-matched `sqlite3.wasm` and `drift_worker.js`; durable schema/repository remain WO-09 |

## Simulated or not connected

| Area | Current boundary |
|---|---|
| Authentication | Apple Sign In not connected |
| Persistence | Repository-backed memory implementation; Drift runtime prerequisites are present, but no data survives an app restart until WO-09 |
| Voice and STT | Button drives a sample transcript; no microphone access |
| AI pipeline | E1–E7 screens are timed local state transitions |
| Backend | Local migrations 0001–0007, deterministic seed data, full RLS, locked-passage trigger, transactional RPCs, atomic job claiming, and zombie reaping cron are present; pipeline workers are not connected |
| Offline | Draft persistence and retry queue are not present |
| Notifications | Morning/night and completion notifications are not present |
| Completion | S14 and PDF export are not present |
| Privacy controls | App lock, export, deletion, and provider notice are not present |

## Verified baseline

- `dart analyze lib test`: no issues
- `flutter test`: 54 tests passing (including DreamElement reference integrity, raw progress/event-sum consistency, progress-ratio capping, repository-backed screens, and existing contract/domain/UI/core tests)
- `flutter build web --release`: passing
- `flutter build ios --simulator --no-codesign`: passing
- Drift iOS runtime open/close smoke: deferred until Simulator's required Xcode components are user-authorized
- `supabase db reset`: migrations 0001–0007 and seed passing
- `supabase test db`: 108 database tests passing (4 constraints + 49 RLS + 55 trigger/RPC checks)
- `supabase db lint --local --schema public --level warning`: no schema errors
- Mobile visual QA at 390×844: capture through reveal, manuscript growth, Reader, source sheet, and Night Paper

## Recommended next milestone

Replace the memory implementation with real, privacy-safe persistence:

1. Drift local schema and durable repository
2. Apple authentication and session lifecycle
3. Mock engine boundary and capture-to-reveal integration coverage
4. Draft autosave, offline retry queue, and synchronization
5. E1–E7 pipeline and background worker
6. Real recording/STT evaluation

The first milestone is complete only when a dream survives an app restart, belongs to the authenticated user, cannot be read by another user, and can enter a retryable processing job without its text appearing in logs.

# MUMUMONG Implementation Status

Last updated: 2026-09-13

## Summary

The repository contains a runnable Flutter interaction prototype for the core MUMUMONG loop. It is suitable for product-language and flow validation, but it is not yet connected to production data or AI services.

## Implemented locally

| Area | Status | Notes |
|---|---|---|
| S03 Manuscript Home | Prototype | Dot cover, MU percentage, delta reason, open scene |
| S04 Capture | Prototype | Text input and simulated voice transcription |
| S05 Recall | Prototype | Three fixed-bank questions and skip action |
| S06 Processing | Prototype | Four stage-driven dot states |
| S07 Reveal | Prototype | New passage marks, D1 decision, D2 placement sheet |
| S08 Reader | Prototype | Vertical reading, running header, Night Paper |
| S09 Source Sheet | Prototype | D/C/U source display and highlighted excerpt |
| S12 Archive | Prototype | Monthly list and filters |
| S13 Dream Detail | Prototype | Original text, recall metadata, derived scene |
| Brand system | Implemented | MaruBuri, Pretendard, paper/ink/sky tokens, app icon |

## Simulated or not connected

| Area | Current boundary |
|---|---|
| Authentication | Apple Sign In not connected |
| Persistence | No domain model or repository yet; screen content is hard-coded and shell counters are ephemeral |
| Voice and STT | Button drives a sample transcript; no microphone access |
| AI pipeline | E1–E7 screens are timed local state transitions |
| Backend | Local schema migrations 0001–0005, deterministic seed data, queue tables, and atomic `claim_job()` are present; RLS and pipeline functions/workers are not connected |
| Offline | Draft persistence and retry queue are not present |
| Notifications | Morning/night and completion notifications are not present |
| Completion | S14 and PDF export are not present |
| Privacy controls | App lock, export, deletion, and provider notice are not present |

## Verified baseline

- `dart analyze lib test`: no issues
- `flutter test`: 8 tests passing
- `flutter build web --release`: passing
- `flutter build ios --simulator --no-codesign`: passing
- `supabase db reset`: migrations 0001–0005 and seed passing
- `supabase test db`: 4 database constraint tests passing
- `supabase db lint --local --level warning`: no schema errors
- Mobile visual QA at 390×844: capture through reveal, manuscript growth, Reader, source sheet, and Night Paper

## Recommended next milestone

Replace the simulated capture boundary with real, privacy-safe persistence:

1. Supabase RLS and cross-user access tests
2. Apple authentication and session lifecycle
3. Repository layer and local draft persistence
4. Offline job queue and idempotency contract
5. Real recording/STT evaluation
6. E1–E7 API contracts and mock/real provider boundary

The first milestone is complete only when a dream survives an app restart, belongs to the authenticated user, cannot be read by another user, and can enter a retryable processing job without its text appearing in logs.

# MUMUMONG Implementation Status

Last updated: 2026-09-24

## Summary

The repository contains a runnable Flutter implementation of the core MUMUMONG loop. Its primary screens are wired to restart-safe Drift storage, the Apple-to-Supabase authentication flow has secure session persistence and volume-aware routing, and both deterministic mock and hosted AI engines exist. The dedicated `mumumong` Supabase project (`dtdmfjovpufyyekdumga`) has migrations 0001–0008 and E1–E7 plus the queue worker deployed. A disposable hosted smoke account completed extract → link → plan → write → validate → commit → remember with Groq structured output while retaining D-passage provenance. Cloud input/output synchronization is still the boundary preventing the installed Flutter app from using this hosted path end to end.

## Implemented locally

| Area | Status | Notes |
|---|---|---|
| S01 Apple Sign In | Implemented, provisioning pending | Native Apple credential exchange through Supabase, cancellation/error/retry states, automatic refresh, and Keychain-backed session storage; live account verification still depends on Apple and Supabase provider configuration |
| S02 Volume Setup | Route boundary only | An authenticated account without a remote volume reaches the editorial setup boundary; volume creation remains a later work order |
| S03 Manuscript Home | Repository-backed prototype | Dot cover, MU percentage, event-derived delta reason, open scene |
| S04 Capture | Repository-backed prototype with autosave and native STT | Text autosaves after 500ms. iOS uses `ko-KR` `SFSpeechRecognizer` with `requiresOnDeviceRecognition=true`; audio buffers are never written to files, partial text saves immediately, RMS drives dots, and unsupported/denied/empty paths return to text. Real-device accuracy evaluation remains open |
| S05 Recall | Prototype | Three fixed-bank questions and skip action |
| S06 Processing | Job-stream backed | The visual stage follows actual job types instead of a timer. Success/retry/fallback/failure, 20-second slow state, and explicit retry are covered. The remote client enqueues idempotently, invokes the authenticated worker, and subscribes to Supabase jobs; cloud input/output synchronization remains open |
| S07 Reveal | Repository-backed prototype | Generated passage marks and repository placement mutations |
| S08 Reader | Repository-backed prototype | Scene selection, vertical reading, running header, Night Paper, long-press edit to locked U, and provenance-preserving revert |
| S09 Source Sheet | Repository-backed | D/C/U source display; D resolves exact element IDs and highlights Unicode spans or safe label matches in the raw dream |
| S12 Archive | Repository-backed prototype | Typed monthly dream list and status filters |
| S13 Dream Detail | Repository-backed prototype | Original text, recall metadata, derived scene |
| Brand system | Implemented | MaruBuri, Pretendard, paper/ink/sky tokens, app icon |
| Domain contract | Implemented | Nine immutable models, centralized DB enum mapping, serialization, and pure MU/clarity rules |
| Repository boundary | Implemented | Reusable repository contract runs against both memory and Drift implementations; DreamElement reference integrity and raw progress-event cache semantics are preserved |
| Local persistence | Implemented | Drift schema v1 mirrors manuscript data and adds drafts, outbox, reader positions, and sync state; Riverpod defaults to the durable repository and seeds the prototype only for an empty database |
| Drift prerequisites | Implemented | `drift_flutter` native bootstrap plus lock-matched `sqlite3.wasm` and `drift_worker.js` |
| Mock engine boundary | Implemented | `ENGINE=mock` and `MOCK_CASE` select deterministic success, retry, fallback, or failure; commits are idempotent and persist through both memory and Drift stores without network or LLM calls |
| E5 Validate rules | Deployed and cloud-smoked | Deterministic V1–V7 checks, including required/existing source elements. V5/V7 model-based meaning and safety remain open. Hosted secret-key and local legacy-key worker authentication are both covered; public keys are denied |
| E6 Commit assembly | Deployed and cloud-smoked | Real `commit_scene` RPC, retry deduplication, remember enqueue, rollback on invalid provenance, and worker-only access are verified locally; an authorized hosted call reaches database lookup while public callers are denied |
| E1–E4 + E7 model stages | Deployed and cloud-smoked | Groq `openai/gpt-oss-20b` handles extract/link/remember and `openai/gpt-oss-120b` handles plan/write through strict JSON schemas. Deterministic span, clarity, link-threshold, adaptation-budget, retry/fallback, provenance, and memory caps are applied outside the model |
| WO-14 worker | Deployed | Atomic per-user/service job claiming, self-invocation, bounded retry scheduling, metadata-only diagnostics, and public-key denial are implemented. A durable cron recovery schedule is still pending |
| Offline retry core | Implemented, delivery wiring pending | Durable FIFO, stable idempotency keys, per-dream predecessor blocking, 1/4/15/60/300/900-second backoff, six-attempt terminal failure, connectivity and foreground wakeups; not yet attached to repository writes or a cloud delivery adapter |
| Privacy settings | Implemented locally and partially deployed | JSON export includes dreams, drafts, manuscript and provenance but excludes credentials/job payloads; app lock uses Face ID/device passcode and Keychain with default OFF; account deletion requires typed confirmation, calls an authenticated Edge Function for server deletion, then clears local tables and signs out |

## Simulated or not connected

| Area | Current boundary |
|---|---|
| Persistence | Local Drift persistence is active; cloud ownership and cross-device sync are not connected |
| Voice and STT | Native on-device implementation builds and its Flutter callback behavior is tested; the required ten-recording quality check needs a physical iPhone and human review |
| AI pipeline | E1–E7 and the worker are deployed and a real hosted dream completed the entire pipeline. Durable cron recovery and model-assisted semantic V5/V7 checks remain open |
| Backend | The dedicated cloud project has migrations 0001–0008, RLS, locked-passage trigger, transactional RPCs, available-at job claiming, zombie reaping, E1–E7, the worker, and authenticated account deletion. Cloud synchronization and durable cron recovery remain open |
| Offline | Capture autosave/restore and the durable retry worker are implemented; repository mutation enqueueing, ownership migration, and cloud pull/merge remain open, so cross-device sync must not be claimed |
| Notifications | Morning/night and completion notifications are not present |
| Completion | S14 and PDF export are not present |
| Privacy controls | App lock, JSON export, and deletion are present. Groq is selected, but the onboarding provider notice, retention-language review, and server-enforced consent gate remain open |

## Verified baseline

- `dart analyze lib test integration_test`: no issues
- `flutter test`: 110 tests passing, including draft persistence, engine-stream UI, Reader edit/revert, Unicode source highlights, durable outbox restart/backoff/idempotency, export redaction, local wipe, app lock, and remote engine enqueue/worker invocation/stream mapping
- `flutter test integration_test`: 5 iOS integration scenarios passing: four capture-to-reveal engine cases plus native SQLite autosave/reopen/restore/discard. The restart check reopens storage and recreates the screen; it does not simulate an OS kill inside the 500ms debounce window
- `flutter build web --release`: passing
- `flutter build ios --simulator --no-codesign`: passing
- Apple authentication screen runtime smoke: passing on iPhone 17 Pro Simulator
- Drift iOS runtime open/query/close smoke: passing on iPhone 17 Pro Simulator (SQLite 3.53.4)
- `supabase db reset`: migrations 0001–0008 and seed passing
- `supabase test db`: 111 database tests passing
- `supabase db lint --local --schema public --level warning`: no schema errors
- `npx deno task verify` in `supabase/functions`: 57 tests passing
- `node tool/engine_smoke.mjs` with `supabase functions serve`: real HTTP validation/audit, worker authorization, repeated commit, remember deduplication, and transaction rollback passing; disposable smoke account removed after verification
- Mobile visual QA at 390×844: capture through reveal, manuscript growth, Reader, source sheet, and Night Paper
- Cloud deployment smoke: migrations 0001–0008 match remote; every engine stage accepts only the hosted service secret; public manuscript reads and anonymous account deletion are denied
- Hosted AI pipeline smoke: disposable authenticated accounts repeatedly completed extract → link → plan → write → validate → commit → remember, including write/validate regeneration, and committed passages with real D provenance; all disposable owned data was then deleted

## Recommended next milestone

Connect the durable local implementation to the now-live backend:

1. Attach local repository mutations to the durable outbox, migrate local ownership after Apple sign-in, and implement authenticated push/pull conflict handling
2. Add durable worker recovery scheduling and the server-enforced AI consent gate
3. Configure Apple Sign In in the Supabase project and verify a real account end to end
4. Run the ten-recording Korean STT quality check on a physical iPhone

The first milestone is complete only when a dream survives an app restart, belongs to the authenticated user, cannot be read by another user, and can enter a retryable processing job without its text appearing in logs.

# MUMUMONG Implementation Status

Last updated: 2026-09-26

## Summary

The repository contains a runnable Flutter implementation of the core MUMUMONG loop. Its primary screens are wired to restart-safe Drift storage, the Apple-to-Supabase authentication flow has secure session persistence and volume-aware routing, and both deterministic mock and hosted AI engines exist. The dedicated `mumumong` Supabase project (`dtdmfjovpufyyekdumga`) has migrations 0001–0008 and E1–E7 plus the queue worker deployed. The hosted app path now creates its first short volume, pushes a locally captured dream through authenticated RLS, follows the Groq job, and pulls the generated elements, scene, passages, provenance and progress back into Drift before reveal. A disposable app-equivalent account completed this full round trip with stable retry identity. Remaining sync work concerns later author mutations rather than the capture-to-reveal path.

## Implemented locally

| Area | Status | Notes |
|---|---|---|
| S01 Apple Sign In | Implemented, provisioning pending | Native Apple credential exchange through Supabase, cancellation/error/retry states, automatic refresh, and Keychain-backed session storage; live account verification still depends on Apple and Supabase provider configuration |
| S02 Volume Setup | Implemented for M1 | Authenticated empty accounts choose faithful/balanced adaptation and one of three styles, see the Groq processing notice, and create a short volume with a 20 MU target in Supabase and Drift |
| S03 Manuscript Home | Repository-backed prototype | Dot cover, MU percentage, event-derived delta reason, open scene |
| S04 Capture | Repository-backed prototype with autosave and native STT | Text autosaves after 500ms. iOS uses `ko-KR` `SFSpeechRecognizer` with `requiresOnDeviceRecognition=true`; audio buffers are never written to files, partial text saves immediately, RMS drives dots, and unsupported/denied/empty paths return to text. Real-device accuracy evaluation remains open |
| S05 Recall | Prototype | Three fixed-bank questions and skip action |
| S06 Processing | Hosted round-trip connected | The visual stage follows actual job types instead of a timer. The remote client pushes the owned dream, enqueues with the stable dream UUID, invokes the authenticated worker, combines Realtime with a 3-second polling fallback, and pulls server results into Drift before reveal. Standalone results exit to explicit archive guidance instead of hanging |
| S07 Reveal | Repository-backed prototype | Generated passage marks and repository placement mutations |
| S08 Reader | Repository-backed prototype | Scene selection, vertical reading, running header, Night Paper, long-press edit to locked U, and provenance-preserving revert |
| S09 Source Sheet | Repository-backed | D/C/U source display; D resolves exact element IDs and highlights Unicode spans or safe label matches in the raw dream |
| S12 Archive | Repository-backed prototype | Typed monthly dream list and status filters |
| S13 Dream Detail | Repository-backed prototype | Original text, recall metadata, derived scene |
| Brand system | Implemented | MaruBuri, Pretendard, paper/ink/sky tokens, app icon |
| Domain contract | Implemented | Nine immutable models, centralized DB enum mapping, serialization, and pure MU/clarity rules |
| Repository boundary | Implemented | Reusable repository contract runs against both memory and Drift implementations; DreamElement reference integrity and raw progress-event cache semantics are preserved |
| Local persistence | Implemented | Drift schema v1 mirrors manuscript data and adds drafts, outbox, reader positions, and sync state; mock mode seeds the prototype while hosted mode starts from the authenticated cloud volume |
| Drift prerequisites | Implemented | `drift_flutter` native bootstrap plus lock-matched `sqlite3.wasm` and `drift_worker.js` |
| Mock engine boundary | Implemented | `ENGINE=mock` and `MOCK_CASE` select deterministic success, retry, fallback, or failure; commits are idempotent and persist through both memory and Drift stores without network or LLM calls |
| E5 Validate rules | Deployed and cloud-smoked | Deterministic V1–V7 checks, including required/existing source elements. V5/V7 model-based meaning and safety remain open. Hosted secret-key and local legacy-key worker authentication are both covered; public keys are denied |
| E6 Commit assembly | Deployed and cloud-smoked | Real `commit_scene` RPC, retry deduplication, remember enqueue, rollback on invalid provenance, and worker-only access are verified locally; an authorized hosted call reaches database lookup while public callers are denied |
| E1–E4 + E7 model stages | Deployed and cloud-smoked | Groq `openai/gpt-oss-20b` handles extract/link/remember and `openai/gpt-oss-120b` handles plan/write through strict JSON schemas. Deterministic span, clarity, link-threshold, adaptation-budget, retry/fallback, provenance, and memory caps are applied outside the model. First dreams are now deterministically kept out of `standalone` and normalized to prologue scenes |
| WO-14 worker | Deployed | Atomic per-user/service job claiming, self-invocation, bounded retry scheduling, metadata-only diagnostics, and public-key denial are implemented. A durable cron recovery schedule is still pending |
| Offline retry core | Capture path wired | Dream creation and processing mutations enter the durable FIFO in the same Drift transactions, use the dream UUID as the processing idempotency key, and are delivered to Supabase on connectivity/foreground wakeups. Later edit, placement, link-decision and deletion mutations still need adapters |
| Privacy settings | Implemented locally and partially deployed | JSON export includes dreams, drafts, manuscript and provenance but excludes credentials/job payloads; app lock uses Face ID/device passcode and Keychain with default OFF; account deletion requires typed confirmation, calls an authenticated Edge Function for server deletion, then clears local tables and signs out |

## Simulated or not connected

| Area | Current boundary |
|---|---|
| Persistence | Active-volume bootstrap and capture-to-reveal push/pull are connected. Cross-device synchronization for later edits, placement changes, link decisions and deletion is not yet complete |
| Voice and STT | Native on-device implementation builds and its Flutter callback behavior is tested; the required ten-recording quality check needs a physical iPhone and human review |
| AI pipeline | E1–E7 and the worker are deployed and a real hosted dream completed the entire pipeline. Durable cron recovery and model-assisted semantic V5/V7 checks remain open |
| Backend | The dedicated cloud project has migrations 0001–0008, RLS, locked-passage trigger, transactional RPCs, available-at job claiming, zombie reaping, E1–E7, the worker, authenticated account deletion, and app-equivalent capture push/pull. Durable cron recovery remains open |
| Offline | Capture autosave/restore plus durable create/process delivery are implemented. The next app launch imports hosted results, but a background completion notification and non-capture mutation delivery remain open |
| Notifications | Morning/night and completion notifications are not present |
| Completion | S14 and PDF export are not present |
| Privacy controls | App lock, JSON export, and deletion are present. Groq is selected, but the onboarding provider notice, retention-language review, and server-enforced consent gate remain open |

## Verified baseline

- `dart analyze lib test integration_test`: no issues
- `flutter test`: 114 tests passing, including S02 creation/recovery, stable Outbox enqueue, authenticated push/pull mapping, engine result import, standalone archive handling, Reader edit/revert, Unicode source highlights, export redaction, local wipe and app lock
- `flutter test integration_test`: 5 iOS integration scenarios passing: four capture-to-reveal engine cases plus native SQLite autosave/reopen/restore/discard. The restart check reopens storage and recreates the screen; it does not simulate an OS kill inside the 500ms debounce window
- `flutter build web --release`: passing
- `flutter build ios --simulator --no-codesign`: passing
- Apple authentication screen runtime smoke: passing on iPhone 17 Pro Simulator
- Drift iOS runtime open/query/close smoke: passing on iPhone 17 Pro Simulator (SQLite 3.53.4)
- `supabase db reset`: migrations 0001–0008 and seed passing
- `supabase test db`: 111 database tests passing
- `supabase db lint --local --schema public --level warning`: no schema errors
- `npx deno task verify` in `supabase/functions`: 59 tests passing
- `node tool/engine_smoke.mjs` with `supabase functions serve`: real HTTP validation/audit, worker authorization, repeated commit, remember deduplication, and transaction rollback passing; disposable smoke account removed after verification
- Mobile visual QA at 390×844: capture through reveal, manuscript growth, Reader, source sheet, and Night Paper
- Cloud deployment smoke: migrations 0001–0008 match remote; every engine stage accepts only the hosted service secret; public manuscript reads and anonymous account deletion are denied
- Hosted AI pipeline smoke: disposable authenticated accounts repeatedly completed extract → link → plan → write → validate → commit → remember, including write/validate regeneration, and committed passages with real D provenance; all disposable owned data was then deleted
- Hosted app round-trip smoke: an RLS-constrained disposable user created the S02 short volume, idempotently upserted the same dream twice, processed it with the stable dream UUID, and read back a prologue scene, real D provenance and an exactly matching progress cache/event before automatic cleanup

## Recommended next milestone

Connect the durable local implementation to the now-live backend:

1. Add cloud delivery for link decisions, passage edits/reverts, placement changes and dream removal/deletion
2. Add durable worker recovery scheduling and the server-enforced AI consent gate
3. Configure Apple Sign In in the Supabase project and verify a real Apple account end to end
4. Run the ten-recording Korean STT quality check on a physical iPhone

The first milestone is complete only when a dream survives an app restart, belongs to the authenticated user, cannot be read by another user, and can enter a retryable processing job without its text appearing in logs.

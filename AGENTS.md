# MUMUMONG Agent Guide

> Claude Code로 작업할 때는 `CLAUDE.md`를 함께 읽어라 (원격 환경 제약이 다르다).

## Canonical documents

Read these before changing product behavior or visual language:

0. `DESIGN.md` — **single source of truth for all UI** (tokens, surfaces, components, dot/motion system, Do/Don't, visual QA). Read it before any UI work. New styles go into `DESIGN.md` and a shared component first, never into a screen. Where it conflicts with the older design documents below, `DESIGN.md` §13 decisions (2026-10-26) win.
   - On branch `redesign/mumumong-v2` only: `DESIGN_V2.md` governs `lib/v2/` (the V2 preview, run with `lib/main_v2.dart`). V1 screens under `lib/ui` still follow `DESIGN.md`. Do not mix V2 components into V1 screens or the reverse until the user gives GO.
1. `docs/MUMUMONG_PRODUCT_PDR_v0.1.md`
2. `docs/MUMUMONG_VISUAL_SYSTEM_v0.1.md`
3. `docs/MUMUMONG_VISUAL_DIRECTION_v0.4.md` — current visual direction; supersedes v0.1/v0.3 on presentation
4. `docs/MUMUMONG_DESIGN_SYSTEM_v0.6.md` — current UI token/component/motion specification; supersedes v0.5 where different
5. `docs/MUMUMONG_M1_Report.md`
6. `docs/MUMUMONG_M1_WorkOrders.md`
7. `docs/MUMUMONG_Q_WorkOrders.md` — for Q-series work, read §0 and only the assigned Q-WO
8. `docs/STATUS.md`
9. `docs/DESIGN_DIRECTION_vNext.md` — user-approved 2026-10-14 direction; supersedes older presentation and screen-action rules where different
10. `docs/UX_REBUILD_STATUS.md` — P0–P6 execution evidence and remaining work
11. `docs/MUMUMONG_DESIGN_SYSTEM_v0.7.md` — P3 shared UI, appearance persistence and action contracts; supersedes v0.6 implementation details
12. `docs/MUMUMONG_DESIGN_SYSTEM_v0.8.md` — 2026-10-19 reference mapping, focused atmosphere/material refinement and explicit onboarding/Orb review boundaries; supersedes v0.7 visual details only
13. `docs/MUMUMONG_DESIGN_SYSTEM_v0.9.md` — shared spacing, action hierarchy and completion/export screens; retains v0.8 material/motion
13. `docs/MUMUMONG_DESIGN_SYSTEM_v0.9.md` — 2026-10-23 grouped flow spacing and shared primary/secondary action hierarchy; preserves v0.8 atmosphere/material

When documents conflict, preserve the seven-step product loop and the non-negotiable rules below, then record the unresolved conflict instead of guessing.

For M1, the user decisions recorded in `docs/MUMUMONG_M1_Report.md` v0.3 override the older pending-decision placeholders in the v0.1 PDR.

## Product north star

Dream capture → analysis → connection → fiction generation → user direction → manuscript growth → user completion.

Do not add a feature unless it makes one of these steps simpler or more compelling.

## Non-negotiable rules

- Every passage has an origin: `D` (dream), `C` (connection/adaptation), or `U` (user).
- A `D` passage references at least one source element.
- `U` passages are locked and must never be overwritten by generation or compilation.
- Generation length and `C` ratio obey the selected adaptation budget.
- Do not interpret dreams or provide fortune-telling or psychological meaning.
- Do not log dream text or generated manuscript text. Logs contain IDs and metadata only.
- 평가 데이터(`eval/corpus/`, `eval/runs/`, `eval/judgments/`, `eval/reference/`, `eval/pro/`)는 절대 커밋·출력하지 않는다. 커밋 가능한 fixture는 새로 지어낸 가짜 꿈만 사용한다.
- Generated manuscripts change only through the engine; never correct them by writing directly to the database.
- Use focused blue/lilac light that fades into a clean canvas. Keep text, input and primary actions sharp; do not fill every screen with uniform blur.
- The 2026-10-14 user direction permits a small pixel/ASCII memory object or state transition. Do not restore full-screen dot/halftone grids or overlap decoration with manuscript text.
- Use one visually primary action per screen, soft rounded controls and selective glass. Supporting navigation remains accessible. Orbs represent actual processing/network waits; typing and transcription must stay responsive and visually still. Avoid card dashboards.
- UI code uses only `DESIGN.md` tokens and `lib/core/design` components. No screen-local `Color(...)`, `Duration(...)`, `TextStyle(fontSize: ...)`, raw `TextButton`/`Switch` or hand-built button/panel widgets. Dots live only where `DESIGN.md` §8 allows and never move while the user types.

## Current implementation boundary

The repository has Drift persistence, mock and remote engines, authentication/consent gates and cloud synchronization. The public web trial uses a browser-bound anonymous Supabase account. Native voice recognition still needs physical-device validation. Non-LLM immutable completion, PDF export UI and scheduled worker wakeup are implemented; LLM ending/editing and push notifications are not. Real generation can fail validation and is not a literary-quality guarantee. Consult `docs/STATUS.md` and `docs/UX_REBUILD_STATUS.md` for current verification boundaries.

Never describe simulated behavior as production integration.

## Q-series priority and frozen baseline

- Engine work (`supabase/functions/engine-*`, `_shared/prompts`, `_shared/llm*`) follows the Q-series before remaining M1 work. Do not run unrelated work alongside Q-02.
- Freeze the `edfc13c` baseline: `write.v10` in `_shared/prompts/write.v1.ts`, `plan.v6` in `_shared/prompts/plan.v1.ts`, and `engine-write/opening_expansion.ts` / `opening_polish.ts`. Do not add or change their rules throughout the Q-series. Candidate quality changes require measurement and blind judgment and must coexist with the frozen baseline.
- Q-07/Q-31 replace the remaining M1 semantic V5/V7 enhancement. Manuscript completion may implement state transitions and UI; LLM editing waits until after Q-32.

## Development workflow

### Mandatory input/QA release gate — user requirement, 2026-10-25

- Reproduce reported failures before declaring a fix. Builds, goldens, HTTP200 and test counts alone are not evidence of usable input or successful generation.
- For capture changes, run `flutter test --no-pub --platform chrome test/ui/capture_keyboard_test.dart` as well as VM tests. Exercise focus first, then animated keyboard insets; preserve the same EditableText, Korean IME composition and reachable save control. A snapshot with the keyboard already open is insufficient.
- Run `bash tool/test_web_durability.sh`: a transaction must reach real IndexedDB before graceful close, not just appear in the current VFS. Web releases rebuild `drift_worker.js` from the pinned dependencies using `tool/build_drift_worker.sh`. Never regress below Drift2.35.2;2.35.0 lost transaction writes on reload. Check save/reload in an actual browser without clearing storage.
- For PWA startup, run `node --test tool/pwa_startup_test.mjs` and `node --check` on the **compiled** `flutter_bootstrap.js`. Inject bootstrap/main/CanvasKit download failures with the local-only `tool/serve_pwa_qa.mjs`; require explicit retry and a usable app after recovery, not a blank page. Verify local CanvasKit assets as part of the same release. Autosave failures must be visible without unmounting the editor or stealing IME focus. Never auto-reload an active editor or clear storage to make an update work.
- For installed PWA browser chrome, inspect the installed origin, manifest scope/start URL and all redirect/worker navigation paths before blaming iOS or changing CSS/fullscreen flags. Off-scope cross-origin navigation can open Safari View Controller. Retired preview HTML/workers must not automatically navigate to another origin. Run `node --test tool/pwa_install_test.mjs`; keep the stable manifest identity and never silently move anonymous auth/storage or ask users to delete their existing app/data. An installation guide/browser-mode test is not proof of physical standalone execution.
- Check draft save/re-entry, storage failure/timeout, rapid voice start/stop and denied/unavailable speech. Never present an unsupported web microphone as a recorder or a fake transcript as real speech.
- Follow `docs/QA_RELEASE_GATE.md`. Test the built release and verify the exact promoted public build. Keep simulator/browser tests, physical iPhone/Safari/PWA verification and real STT accuracy separate; mark missing evidence as unverified, not passed.
- A reproducible keyboard/data-loss/core-flow blocker stops promotion. A scoped corrective web hotfix may ship with explicit native/device limitations; it must not be called a completed native/voice release. Keep privacy-safe evidence and rollback identity. Do not log or publish real dreams/manuscripts/video frames.
- Run Flutter test/build commands sequentially; shared cross-target outputs can corrupt concurrently. Do not reset app storage or user drafts to make QA pass.

Before handing off a change, run:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

For iOS-affecting changes, also run:

```bash
flutter build ios --simulator --no-codesign
```

Keep changes scoped, update `docs/STATUS.md` when a capability crosses from simulated to implemented, and preserve user changes unrelated to the task.

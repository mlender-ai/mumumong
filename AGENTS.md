# MUMUMONG Agent Guide

## Canonical documents

Read these before changing product behavior or visual language:

1. `docs/MUMUMONG_PRODUCT_PDR_v0.1.md`
2. `docs/MUMUMONG_VISUAL_SYSTEM_v0.1.md`
3. `docs/MUMUMONG_M1_Report.md`
4. `docs/MUMUMONG_M1_WorkOrders.md`
5. `docs/STATUS.md`

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
- Sky blue always means something newly created and settles back to ink.
- Dots communicate product state. Do not use them as decorative texture.
- Cover clarity never exceeds `0.9`.
- Keep the interface editorial: paper, type, whitespace, hairlines; avoid card dashboards.

## Current implementation boundary

The repository is a local interaction prototype. Voice recognition, persistence, Supabase, AI generation, push notifications, completion, and PDF export are not implemented unless `docs/STATUS.md` says otherwise.

Never describe simulated behavior as production integration.

## Development workflow

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

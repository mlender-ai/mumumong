# MUMUMONG Design System v0.6

> Historical snapshot: `MUMUMONG_DESIGN_SYSTEM_v0.7.md` documents the 2026-10-18 P3 implementation, including persisted app theme, optional recall, modal sizing and paragraph menus. Use v0.7 with `DESIGN_DIRECTION_vNext.md` for current behavior.

> Implementation snapshot. `DESIGN_DIRECTION_vNext.md` takes precedence for the 2026-10-14 user direction and screen-action contracts. In particular, home reading entry, optional first-volume settings and limited pixel/ASCII transitions may be reintroduced under that direction. Numeric tokens below remain the starting point until the P2/P3 component review; new visual rules are not yet applied throughout the app.

> 2026-10-15: P2 has applied the four-screen composition, neutral glass actions, focused fading atmosphere and small saved-memory stamp. The **P2 실행 규격** section of `DESIGN_DIRECTION_vNext.md` supersedes the older mesh/overlay/button treatments below. Global component migration and persisted app-wide night mode still await P3.

Updated 2026-10-08. This is the current implementation specification for Flutter and the mobile web preview. It supersedes v0.5 where they differ. `lib/core/design/design_system.dart` is the executable source for tokens and shared components; this document defines how screens compose them. Product provenance, consent, privacy and the seven-step loop remain governed by the PDR and M1 report.

## 1. Product experience rule

### One screen, one primary action

- Every screen has one task and one visually primary action. Supporting information explains that task; it does not introduce a second CTA.
- Persistent bottom navigation is app chrome, not a competing screen CTA. Keep it visually quiet and do not add local “continue”, “open”, “learn more” or “start” buttons alongside the page's main task.
- The manuscript home has one content action: `꿈 기록하기`. The cover is atmospheric, not tappable. Remove scene teasers, read buttons and nonessential genre/count summaries from this screen.
- A reader is opened from a derived scene in the dream archive. Capture remains one tap from the home.
- The local-only visual walkthrough preserves the full-height gradient entry screen for design tests. The published preview URL redirects to the real-data trial; it must not expose fixed synthetic prose as if it were a generated result.

## 2. System canvas and safe areas

- The app canvas, WebView document background and iOS PWA system surround use the same white: `#FFFFFF` (`MongColor.paper`). Do not place `#FAF9F6` around a white iOS status bar; that thin tonal mismatch reads as a seam.
- `web/index.html` declares a white theme color and white `html/body` background, including while Flutter initializes. Native status/navigation bar colors use the same canvas token.
- Keep content inside platform safe areas. Web content cannot paint over an opaque browser/system status bar; do not simulate that it can.
- The home atmosphere is a 16px-inset rounded canvas (28px radius) on the same white surround. A 168px white-to-clear overlay begins fully white, then gradually reveals the flowing brand gradient. Because both sides of the inset are white, the top system region does not look like a separate band.
- Do not add a tinted page background, shadowed outer card, or second light border around this canvas.

## 3. Color roles

| Role | Token | Value | Use |
|---|---|---:|---|
| System/app canvas | `paper` | `#FFFFFF` | PWA surround, screen background, status/navigation system match |
| Modal surface | `paperPure` | `#FFFFFF` | Sheets and dialogs |
| Input/subtle surface | `paperShade` | `#F3F4F4` | Quiet fields and low-emphasis containers |
| Primary text | `ink` | `#1E1D1B` | Titles, body and primary actions |
| Secondary text | `ink2` | `#55524D` | Descriptions and supporting labels |
| Metadata | `ink3` | `#74716B` | Dates, counts and low-priority captions |
| Divider | `line` | `#E8E5DF` | Structural separation, used sparingly |
| Active sky | `sky700` | `#4D7C9B` | Focus, active capture/processing detail |
| Dream mist | `dreamMist` | `#EAF7FD` | Very light active-state surface |
| Night page | `nightPaper` | `#161513` | Optional manuscript reading mode only |

Home gradient base: `#A7C6DA → #87AFCC → #AEB2C9 → #CDC8D0`. Blue/white/lavender mesh movement may change its luminance, but not its brand family. Do not use blue-filled primary buttons.

## 4. Type

Use Pretendard for interface text and MaruBuri for manuscript/dream reading only. UI text uses `ink` or `ink2`; metadata uses `ink3`. Do not add screen-specific arbitrary font sizes.

| Role | Size / line height | Weight | Intended use |
|---|---:|---:|---|
| Display large | 36 / 1.20 | 600 | Entry headline only |
| Display medium | 28 / 1.30 | 600 | Page title / manuscript title |
| Headline small | 22 / 1.35 | 600 | Section or modal heading |
| Title medium | 18 / 1.40 | 600 | State heading |
| Body medium | 16 / 1.55 | 400 | Main UI copy |
| Body small | 14 / 1.50 | 400 | Supporting copy |
| Label large | 15 / 1.25 | 600 | Primary action |
| Label medium | 13 / 1.40 | 500 | Navigation and chips |
| Label small | 12 / 1.40 | 500 | Metadata |
| Manuscript | 18 / 1.75 | 400 | MaruBuri reading text |

## 5. Spacing and geometry

- Base rhythm: 4px. Use `4 / 8 / 12 / 16 / 24 / 32 / 48px`.
- Standard screen and modal gutter: 24px. The visual home canvas uses the explicit 16px inset needed for its rounded framing.
- Minimum interactive target: 44×44px. Primary action height: 52px. Single-line input height: at least 56px.
- Field radius: 20px. Atmospheric/panel radius: 28px. Sheet/dialog radius: 28px. Pill radius: 999px.
- A modal is at most 480px wide on large viewports; center it with 16px minimum viewport inset.
- Use open space to establish hierarchy. Do not wrap every informational block in a card.

## 6. Actions and glass

### Primary glass action

- `GlassActionButton` is the canonical renderer; `EditorialButton` and `QuietTextButton` are compatibility wrappers, not separate visual systems.
- Use a transparent neutral-white frost: 52px height, 26px radius, 22px backdrop blur, 1px white edge, translucent white diagonal fill, soft cool-light aura and quiet neutral shadow, ink label on pale surfaces. Avoid a heavy gray outline or flat gray fill.
- On white, glass should read through its translucent surface and soft light aura, not a hard gray stroke. On a moving gradient, keep the same material and a readable light label. Never use a solid blue fill to manufacture contrast.
- Press feedback compresses the button to 97.5% over 120ms, then returns without bounce, overshoot, or a color flash.
- Primary home action occupies one row and is the only content CTA on that screen. Do not put another equal-weight action beside it.
- Entry has one Apple action. Platform branding review is a release gate; do not treat a generic glass Apple button as approved Sign in with Apple artwork.
- Disabled actions reduce opacity but keep text legible. Pressed feedback is a small scale/ink response, not a new color fill.

### Glass surfaces

- Reserve `GlassSurface` for a compact overlay or navigation tray on top of imagery. Use its specular edge and blur; avoid a flat white translucent card that disappears on a white field.
- Do not apply glass behind reading paragraphs, settings groups or every list row.

## 7. Navigation

- Bottom navigation is one shared shell, 62px tall plus safe-area padding, with 3 destinations in the current app: manuscript home, dream archive and settings.
- Navigation is secondary to the page task: quiet ink labels, a subtle neutral selected state and no saturated selected pill. The navigation surround must remain exactly `MongColor.paper` white; never place the moving home gradient behind the GNB.
- Do not duplicate a navigation destination as a large CTA inside the page. Home's reading action is removed; a derived archive scene opens Reader.

## 8. Sheets and dialogs

- Bottom sheet: white surface, 28px top corners, 36×4px handle, 24px content gutter, safe-area bottom padding. Default to natural height; use a draggable/scrolling sheet only when content needs it.
- Dream detail may expand to 94% of the viewport. Keep raw dream text readable and editing/deletion explicit.
- Alert dialog: 28px radius, 16px viewport inset, 18–22px title, 16px body, 15px action labels and 44px targets. Destructive actions require explicit labels and confirmation.
- Keyboard appearance must resize/scroll the content rather than cover the field or its submit action.

## 9. Motion and state

- Home atmosphere uses the existing visibly deforming 12-second blue/lavender mesh. It is continuous, not tied to manuscript progress; content and controls stay stationary.
- Real account, policy and first-volume network waits show the 64px Thinking Orb with one stable state line on a quiet sky-white field. Do not show an orb for an instantaneous page change or invent progress. Processing retains only the 64px Thinking Orb and one stable line, “소설을 만들고 있어요”; no stage counters or beam frame.
- The capture editor stays still during typing and native voice transcription: no per-keystroke parent rebuild, orb, beam, color pulse, or volume animation. The text field updates natively and autosaves on its existing debounce; voice partials save immediately.
- The capture editor occupies the available height. When the keyboard opens, hide introductory copy and secondary recording controls so the field and save action remain visible above it. Web capture is text-only until an on-device browser STT path exists.
- No border beam appears in Capture or Processing. Reduced-motion preference freezes the gradient/orb in a stable state.
- Screen transitions are quiet (240–420ms). Growth feedback runs only after a real progress event.
- Validate rendered pixel coverage across time; unequal animation values alone do not prove visible motion.

## 10. Screen contracts

| Screen | One primary task/action | Keep off the screen |
|---|---|---|
| Signed-out entry | Start with Apple | Preview-only entry gate, multiple intro buttons |
| Manuscript home | Record a dream | Read CTA, tappable cover, open-scene link, genre/count dashboard |
| Dream capture | Save the remembered dream | Question chips before saving; competing actions |
| Recall | Answer or skip recall | More than three questions |
| Processing | Leave/understand actual pipeline state | Fake timer progression or percentage |
| Reveal | Place/accept the new scene | Multiple simultaneous decisions |
| Reader | Read and inspect provenance | Decorative cards behind prose |
| Archive | Find and inspect a dream | Duplicate capture CTAs on every row |
| Settings | Choose one settings area | Dense mixed controls on one page |

Global navigation remains available as app chrome. Every screen's content hierarchy still has one obvious next step.

## 11. Implementation and review gate

- Token/component source: `lib/core/design/design_system.dart`.
- Check the entry, consent, home, empty/active capture, processing, reveal, Reader, archive detail/edit and settings at 390×844.
- On home verify: white status/system surround and outer margin share exact `#FFFFFF`; the gradient fades from that white; there is one content CTA named `꿈 기록하기`; no tappable cover or duplicate reading/scene action exists.
- Check glass label/edge contrast over both white and the gradient, one-handed reach, 44px targets, text wrapping, bottom-sheet keyboard insets and reduced motion.
- The local design walkthrough is mock-only; the published preview URL redirects to the public real-data trial. Browser viewport and simulator checks do not replace physical-device contrast or frame-rate review.

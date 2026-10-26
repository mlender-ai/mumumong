# MUMUMONG Visual Direction v0.4

> Historical implementation direction. The user-approved 2026-10-14 rules in `DESIGN_DIRECTION_vNext.md` now take precedence for composition, primary actions and limited pixel/ASCII treatment. Existing UI is being migrated phase by phase; this file does not prove that migration is complete.

Updated 2026-10-07 after review of the signed-out entry, Metal orb source, and glass-button references. This supersedes v0.3 for presentation. The seven-step product loop, provenance, consent and privacy rules are unchanged. The older v0.1 dot/editorial treatment is retained as history, not as active UI direction.

## Entry composition

- An empty signed-out account opens on one gradient canvas. Prefer edge-to-edge behind the mobile status area when the host actually supports transparent system chrome. If an iOS PWA/browser keeps an opaque white status strip, do not force content under it: use a large, consistently rounded inset canvas on the paper surround, with a white-to-clear wash at the top so the system strip feels intentional. Safe areas inset foreground content. The first screen is not a manuscript or card dashboard.
- Header is a small translucent brand capsule and a quiet `01 / 02` counter. The emotional headline is centered in the lower half. The Apple action is a restrained glass pill, not a black platform-sized slab. No separate didactic story page interrupts entry.
- Tapping Apple moves to the age/AI-processing disclosure and consent page; it does not begin authentication until both checkboxes are selected. If the policy cannot load, show an explicit retry state, never a fabricated policy or bypass.
- The disclosure is `02 / 02` on the same gradient family with a pale wash for legibility. D/C/U provenance is introduced in one short line instead of a dedicated onboarding page.

## Color and material tokens

| Role | Value / implementation |
|---|---|
| Surround | `MongColor.paper` (`#FAF9F6`) |
| Immersive field | `#A7C6DA → #87AFCC → #AEB2C9 → #CDC8D0`, with blue, white and warm-lavender moving washes |
| Light field | white / sky / cream ramp for capture and quiet surfaces |
| Glass action | 52 px high, 26 px radius, 22 px backdrop blur, 1 px white edge, transparent white gradient fill and soft sky shadow |
| Glass surface | 24 px backdrop blur, layered low-alpha white, a specular edge; alpha chosen for contrast rather than used as a flat white card |
| Text over immersive field | white with restrained soft shadow; ink over the pale consent wash and paper |

`GlassActionButton` is the canonical CTA. `EditorialButton` and `QuietTextButton` share that renderer for older call sites; neither adds a blue or black fill. Apple carries its glyph inside the same 52 px action. Navigation selection uses translucent white, not a blue pill. Glass is reserved for controls and small overlays; manuscript text remains on paper.

App Store branding review remains open: [Apple's Sign in with Apple guidance](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple) restricts custom branded buttons to an overall black or white appearance and official Apple artwork. The current transparent Apple treatment is a visual-direction prototype, not a claim that its final branded button is approved. Keep the glass language for non-branded actions; settle the Apple-specific exception before release.

## Motion contract

- `FlowingGradient` loops every 12 seconds. A coloured mesh deforms the actual light/dark boundaries, rather than drifting near-transparent oversized overlays across an otherwise static gradient. Harmonic paths meet at the loop boundary. Perceptible pixel coverage, not merely unequal frames, is the motion gate.
- Motion communicates atmosphere, never invented percentage or AI job progress. A 64px Thinking Orb may appear during real account/policy/volume network waits and AI processing, with one stable state line; capture remains still and the border beam is not used. The supplied Metal code is an orb shader, not the home background shader; its magenta sphere and grain are not imported into the home.
- `MediaQuery.disableAnimations` freezes a stable frame. The gradient is isolated by a repaint boundary.
- Motion and glass must be checked on a 390 px mobile viewport and an iOS simulator. Physical-device frame rate remains unverified until measured.

## Review checklist

1. Compare screenshots 3 seconds apart and again beyond a full 12-second loop; the field must visibly change while headline/buttons stay stationary.
2. Verify the first action is a transparent glass pill, identical in height and material to the consent CTA. No black or solid-blue primary action.
3. Verify the consent page and network-error state do not become an empty white screen; an unavailable policy blocks auth.
4. Verify the field extends behind mobile safe areas, small-screen scroll, text contrast, reduced-motion still frame, and no dot/pixel/ASCII treatment.

The intended reference mood is a soft blue-lavender light volume with substantial breathing room, not literal reproduction of a third-party layout. Glass actions must remain legible on both the pale paper and atmospheric fields; a clear ink label and a discernible translucent edge are preferable to a white-on-white outline that technically exists but disappears on a phone.

## Local interaction walkthrough

`tool/visual_preview.dart` remains a local-only design-test entry point. Its seeded manuscript and fixed synthetic prose do not reflect the entered dream and must never be presented as real generation. The previously published preview URL now redirects to the public real-data trial instead of serving that mock. The real authentication/consent gate is unchanged.

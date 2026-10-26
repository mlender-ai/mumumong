# MUMUMONG Design System v0.5

2026-10-07. This is the active UI specification for Flutter screens. It supersedes the presentation rules in Visual Direction v0.4 where they differ, without changing product behavior, consent, provenance, or the Q-series engine freeze. `design_system.dart` is the executable token source. The v0.1 Visual System remains historical guidance for manuscript typography and Night Paper.

## Reference fit

- The [VoltAgent DESIGN.md collection](https://github.com/VoltAgent/awesome-design-md) separates color roles, typography, spacing, components and interaction rules. Use that structure; do not copy any site's brand assets.
- [ElevenLabs' analyzed system](https://github.com/VoltAgent/awesome-design-md/blob/main/design-md/elevenlabs/DESIGN.md) is the closest mood reference: quiet off-white, soft blue atmospheric fields, dark neutral type, restrained pill controls. Its desktop scale is **not** our mobile specification.
- [Clay's analyzed system](https://github.com/VoltAgent/awesome-design-md/blob/main/design-md/clay/DESIGN.md) informs the 4px spacing rhythm and softer panel geometry. The mobile manuscript remains a reading surface, not a card dashboard.
- [Thinking Orbs](https://libraries.dev/orbs) is a **small, state-specific dotted animation**, not a large luminous sphere. Its [Flutter port](https://pub.dev/packages/thinking_orbs) supplies the nine state animations. Use the 64px tuned preset with sky-700 dots only during capture and actual processing. The surrounding panel and moving beam are MUMUMONG components, not part of the orb.

## Foundations

| Role | Token | Value |
|---|---|---|
| Canvas | `paper` | `#FAF9F6` |
| Modal/sheet | `paperPure` | `#FFFFFF` |
| Subtle field | `paperShade` | `#F2F1ED` |
| Primary text | `ink` | `#1E1D1B` |
| Secondary text | `ink2` | `#55524D` |
| Metadata | `ink3` | `#74716B` |
| Separation | `line` | `#E8E5DF` |
| Active animation | `sky700` | `#4D7C9B` |
| Active surface | `dreamMist` | `#EAF7FD` |

The moving home atmosphere uses the v0.4 blue/lavender field. It is not a loading indicator. Sky fills may illuminate active input/processing, while persistent actions remain transparent glass. Never place low-contrast sky text on paper.

## Mobile type scale

| Role | Family | Size / line height | Weight | Use |
|---|---|---|---|---|
| `displayLarge` | Pretendard | 36 / 1.2 | 600 | Entry statement |
| `displayMedium` | Pretendard | 28 / 1.3 | 600 | Screen title |
| `headlineSmall` | Pretendard | 22 / 1.35 | 600 | Section, modal heading |
| `titleMedium` | Pretendard | 18 / 1.4 | 600 | Active state heading |
| `bodyMedium` | Pretendard | 16 / 1.55 | 400 | UI body, form text |
| `bodySmall` | Pretendard | 14 / 1.5 | 400 | Supporting text |
| `labelLarge` | Pretendard | 15 / 1.25 | 600 | Actions |
| `labelMedium` | Pretendard | 13 / 1.4 | 500 | Chips/navigation |
| `labelSmall` | Pretendard | 12 / 1.4 | 500 | Metadata (tabular numbers) |
| `bodyLarge` | MaruBuri | 18 / 1.75 | 400 | Dream/manuscript reading only |

Do not set ad-hoc font sizes in new UI. Manuscript and PDF typesetting are separate reading contexts and can retain their own specialized scale. UI labels are ink or ink2; metadata uses ink3. Keep minimum 44px touch targets.

## Layout and controls

- 4px base rhythm: `4 / 8 / 12 / 16 / 24 / 32 / 48`. Standard screen gutter and modal content inset: 24px; smaller screen exceptions must be explicit.
- Entry background is edge-to-edge only when the host supports transparent system chrome. If an iOS PWA/browser presents an opaque white status strip, use a large inset rounded gradient canvas and a short white-to-clear top wash so the system area blends intentionally; do not fake full-bleed. Apply safe-area padding to foreground content.
- Glass action: 52px high, 26px radius, at most 280px on the immersive entry; one shared renderer for entry, consent and in-app primary actions. The frosted fill and edge must remain visibly distinct on paper and its label must remain readable; use ink text and a quiet neutral edge on pale surfaces. Text actions use the same 44px minimum touch target. Do not introduce solid-blue CTA variants.
- Input: at least 56px high when single-line, 20px radius, paper-shade fill, line border and sky-700 focus border. Multiline dream capture keeps its enlarged reading area.
- Panel: 28px radius. The glass surface has a specular white edge and blur; put it over atmospheric backgrounds, not behind every paragraph.
- Choice chip: pill radius, 16px horizontal / 12px vertical padding; selected state uses a quiet sky border. Do not encode selection through blue fill alone.
- Bottom sheet: white, 28px top corners, 24px content gutter, 36×4px handle, safe bottom area, natural height unless the content is explicitly scrollable. Dream detail may reach 94% height. Night Reader uses its night surface with the same geometry.
- Alert dialog: white, 28px radius, 16px viewport inset; title uses 18–22px hierarchy, body 16px, actions 15px with 44px targets. Confirmation and destructive actions remain explicit text labels.

## Motion and state

- Entry gradient: continuous visible 12-second loop; `disableAnimations` freezes a stable frame.
- Capture: `listening` orb for microphone, `working` for typed memory. Processing maps extract→working, link→connecting, write→composing, validate→solving. The actual job stream owns the label and state; the orb never implies a percentage.
- Thinking Orb: 64px native preset; never stretch it to 126–184px. If motion is reduced, keep the package's static frame and the textual stage label. The beam outlines only an active input or processing surface.
- Normal page transitions remain quiet (240–420ms). No decorative dots, ASCII or pixel textures outside the explicitly requested orb.

## Review gate

At 390×844 inspect entry, consent, home, empty capture, active capture, processing, reveal, Reader, archive detail/edit and settings. Check text wrapping, tap targets, sheet keyboard insets, state labels, reduced motion and browser errors. The local walkthrough uses synthetic data and does not validate hosted generation or Apple authentication.

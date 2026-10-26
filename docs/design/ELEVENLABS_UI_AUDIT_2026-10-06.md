# ElevenLabs public UI audit — 2026-10-06

Scope: public mobile homepage, ElevenCreative landing, pricing and sign-up pages, plus ElevenLabs UI component documentation. Authenticated app screens and the entire site were not accessible; this is not a claim to reproduce an unpublished design system.

## Observed patterns

| Surface | Observation | MUMUMONG adaptation |
|---|---|---|
| Homepage and ElevenCreative hero | White or lightly warm background, very large black sans headline, generous whitespace, concise supporting copy | Warm paper base, strong Korean sans landing headline, quiet supporting copy |
| Calls to action | Black pill primary, light outlined pill secondary | Apple-branded pill on entry; deep brand-blue and translucent secondary actions inside the app |
| Product showcase | A single vivid orb becomes the focal point within a light, rounded feature panel | Keep a smooth blue orb only for active input and processing, never as passive home decoration |
| Components | Round corners, grouped controls, soft neutrals and clear type hierarchy | Rounded capture fields, navigation and sheets; selective glass over the moving blue field |
| Pricing and account | Segmented pill tabs; warm-gray pricing panels; sparse, centered sign-up form with softly rounded fields | Keep account actions simple and prominent, and show required consent explicitly before actual Apple authentication |
| ElevenLabs UI Orb docs | State-driven orb with configurable colors and audio reactivity | Flutter-painted brand-color orb driven by actual capture/job state; no Three.js/WebGL code copied |

Official references: <https://elevenlabs.io/>, <https://elevenlabs.io/creative>, <https://elevenlabs.io/pricing>, <https://elevenlabs.io/app/sign-up>, <https://ui.elevenlabs.io/docs>, <https://ui.elevenlabs.io/docs/components/orb>.

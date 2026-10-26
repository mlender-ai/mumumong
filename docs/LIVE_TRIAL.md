# MUMUMONG live trial

2026-10-26 follow-up: the user reports installation chrome is resolved. Removed
the guide from normal Introduction/Settings navigation. Previously shared
`/install.html` now opens the same-origin `/` directly; no storage, account or
manifest identity is changed. Consent disclosure is folded, not bypassed, and
production waits use the reference's one banded Thinking visual. [Current UI/QA evidence](ux-review/2026-10-26-start-flow/README.md).

Earlier 2026-10-26 installation investigation:
The retired preview previously forced cross-origin navigation in both HTML and
worker code, which can bring back Safari View Controller/toolbars. Both paths
are removed. The old origin now explains installation without creating/moving
accounts. Keep existing icons/records; export first. [Research and evidence](ux-review/2026-10-26-pwa-install/README.md).

2026-10-23 mobile follow-up: the public URL is a **web trial, not a TestFlight
app**. A normal browser tab cannot be forced into standalone by the page;
an installed same-origin standalone app can run without browser toolbars. Introduction
and Settings now include explicit Home Screen instructions and a storage
separation warning. Web microphone UI opens an honest native-only explanation;
it does not start recording or upload audio. Native app preparation/signing
boundary: [iPhone / TestFlight preparation](IOS_TESTFLIGHT_PREPARATION.md).

2026-10-23: future-generation settings, scheduled worker recovery and non-LLM
immutable completed books/PDF/next volume are implemented. Server migrations
through0020 are deployed. Latest two scheduled real-model synthetic checks
failed V2/V5 validation before commit; literary quality is not verified.
See [current release evidence](releases/2026-10-23-p4-p5-release.md).

2026-10-22: shared design v0.8 was deployed to the public real-data trial.
See [release evidence](releases/2026-10-22-design-deployment.md). The local
onboarding/Orb review tool is not the public app. Build web and iOS sequentially;
the deploy script now refuses incomplete static bundles before publishing.

The real-data trial is at https://mumumong-live-trial.vercel.app. It is a
separate Vercel project from the retired visual walkthrough. The production
address is public: visitors do not need a Vercel account. Generated deployment
URLs and preview deployments remain protected by Vercel Authentication.

The web trial creates a Supabase anonymous account after age confirmation and
AI-processing consent. It uses the hosted AI pipeline, stores the dream and
manuscript in Supabase, and keeps a local copy on the same browser. Record a
dream as text, optionally answer the three memory questions, wait for a scene,
then inspect the manuscript or archive. The browser does not provide the
project's required on-device speech recognizer. Its microphone **help** action
explains this limitation rather than pretending to record. Actual on-device
recording remains available only in the native iPhone app.

### iPhone: hide the browser bars

A normal Safari or in-app browser tab has browser-controlled chrome. For a
standalone view, open https://mumumong-live-trial.vercel.app/
in Safari, choose Share → Add to Home Screen, enable **Open as Web
App**, then launch the new MUMUMONG icon. The app already publishes a standalone
manifest and iOS web-app metadata. Install before recording a dream: iOS keeps
Home Screen web-app storage separate from Safari, and the current anonymous
account cannot be recovered or transferred automatically between them.

To bound public AI usage, an anonymous account can start up to three dreams in
any rolling 24 hours. The trial also has a shared cap of 50 new dream jobs in
any rolling 24 hours. At the cap, the dream remains saved in the archive and
the app explains that today's trial is full; it does not invite repeated
retries. The database enforces these limits before an AI job is queued.

Keep using the same browser. Clearing browser site data or using private
browsing can lose the anonymous account and access to its cloud records. This
trial does not yet provide Apple sign-in or account recovery on the web. The
former visual walkthrough URL at https://mumumong-mobile-preview.vercel.app
now shows an installation guide. Automatic cross-origin navigation can restore
browser toolbars. Do not delete old icons/data; preserve access and export
records before adding an app on another origin. Fixed mock prose is retired.

To publish changes after validation:

```sh
tool/deploy_live_trial.sh
```

The script checks for Vercel Standard Protection (public production address,
protected preview URLs), builds the real Flutter client with the Supabase
publishable key, links the separate project, and deploys the release. The
service-role key and AI provider key stay on the server. Migrations through
0020 and compatible hosted wrappers must already be deployed. The script
stages a production build without moving the public alias. Verify release.json
and static hashes, then promote exactly the tested deployment with `vercel promote`.
Do not disable preview protection. Record deployment/build/source identifiers.

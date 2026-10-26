# MUMUMONG former mobile preview

The old URL, https://mumumong-mobile-preview.vercel.app, previously hosted a
design walkthrough whose result was fixed synthetic prose unrelated to the
entered dream. It is retired. Since 2026-10-26 it serves an explicit installation
guide, **not an automatic cross-origin redirect**. That redirect and the worker's
forced client navigation can open Safari View Controller/toolbars inside an
installed app. Both are removed. See [investigation and release](ux-review/2026-10-26-pwa-install/README.md).

Install the real-data trial from https://mumumong-live-trial.vercel.app/
in Safari with Open as Web App enabled, then launch the newly added icon. The
same-origin manifest keeps start_url/scope/id at `/`. The local-only design
harness remains at `tool/visual_preview.dart` and must not be published as real
generation.

The canonical app's in-flow installation guide was removed in the10/26
simplification follow-up. Its old `/install.html` link remains only as a
same-origin compatibility entry to `/`, never as a cross-origin redirect.

Do not remove existing icons or clear browser data. Preserve access and export
records before adding an app on another origin. Sessions/records do not move
automatically between origins or Safari/Home Screen containers. See `docs/LIVE_TRIAL.md`.

The historically named `tool/mobile-preview-redirect/` now contains the guide
and worker retirement script, without forced navigation or storage deletion.
Its deploy script checks the linked project/protection, tests installation
contracts and stages production; verify both files before promoting that build.

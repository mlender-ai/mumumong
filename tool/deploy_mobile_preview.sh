#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/tool/mobile-preview-redirect"
SCOPE="mlender-ais-projects"

# The published preview used fixed prose unrelated to the user's input.
# Keep an explicit installation guide on the old origin. Automatic cross-origin
# navigation from an installed icon reopens Safari View Controller/toolbars.
cd "$ROOT_DIR"
node --test tool/pwa_install_test.mjs
vercel project inspect --non-interactive --scope "$SCOPE" --cwd "$OUTPUT_DIR"
vercel api "/v9/projects/mumumong-live-trial" --scope "$SCOPE" --raw |
  node -e '
    let body = "";
    process.stdin.on("data", chunk => body += chunk);
    process.stdin.on("end", () => {
      const project = JSON.parse(body);
      if (project.name !== "mumumong-live-trial" ||
          project.ssoProtection?.deploymentType !== "prod_deployment_urls_and_all_previews") {
        console.error("The destination trial must use Standard Protection.");
        process.exit(1);
      }
    });
  '

vercel deploy --cwd "$OUTPUT_DIR" --prod --skip-domain --yes --scope "$SCOPE"

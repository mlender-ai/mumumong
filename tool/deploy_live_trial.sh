#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/build/live-trial"
PROJECT="mumumong-live-trial"
SCOPE="mlender-ais-projects"
SUPABASE_PROJECT="dtdmfjovpufyyekdumga"

cd "$ROOT_DIR"
# A stale precompiled worker can retain persistence bugs after a client update.
# Compile it with the exact lockfile dependencies before hashing/building.
bash tool/build_drift_worker.sh
node --test tool/pwa_startup_test.mjs
node --test tool/pwa_install_test.mjs
# kIsWeb-only layout branches must be tested in a real browser, not only VM
# snapshots with a pre-set inset. A keyboard that opens then loses focus is a
# release blocker even when every golden/build/resource hash passes.
flutter test --no-pub --platform chrome test/ui/capture_keyboard_test.dart
bash tool/test_web_durability.sh
vercel project inspect --non-interactive --scope "$SCOPE" --cwd "$OUTPUT_DIR"
MM_SOURCE_HASH="$(node tool/release_manifest.mjs --hash)"
export MUMUMONG_BUILD_ID="$(date -u +%Y%m%dT%H%M%SZ)"

# Production alias is public for testers. Keep generated deployment URLs and
# previews protected so only the intended trial address is shareable.
vercel api "/v9/projects/$PROJECT" --scope "$SCOPE" --raw |
  node -e '
    let body = "";
    process.stdin.on("data", chunk => body += chunk);
    process.stdin.on("end", () => {
      const project = JSON.parse(body);
      if (project.name !== "mumumong-live-trial" ||
          project.ssoProtection?.deploymentType !== "prod_deployment_urls_and_all_previews") {
        console.error("Live trial must use Standard Protection: public production alias, protected previews.");
        process.exit(1);
      }
    });
  '

# Only the browser-safe publishable key is injected into Flutter. Neither the
# service key nor model-provider credentials enter the client bundle.
MM_PUBLISHABLE_KEY="$(node -e '
  const { execFileSync } = require("node:child_process");
  const keys = JSON.parse(execFileSync("supabase", [
    "projects", "api-keys", "--project-ref", "dtdmfjovpufyyekdumga",
    "--reveal", "-o", "json",
  ], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }));
  const key = keys.find(item => item.type === "publishable")?.api_key;
  if (!key) process.exit(1);
  process.stdout.write(key);
')"

flutter build web \
  --release \
  --output "$OUTPUT_DIR" \
  --dart-define=ENV=staging \
  --dart-define=ENGINE=remote \
  --dart-define=AUTH=apple \
  --dart-define="BUILD_ID=$MUMUMONG_BUILD_ID" \
  --dart-define="SUPABASE_URL=https://$SUPABASE_PROJECT.supabase.co" \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=$MM_PUBLISHABLE_KEY"

# Flutter's incremental cross-target cache can omit unchanged web/ resources
# even when compilation succeeds. Copy only original static inputs (not the
# transformed index/bootstrap/JS) and verify every required artifact below.
cp "$ROOT_DIR/web/manifest.json" "$ROOT_DIR/web/install.html" "$ROOT_DIR/web/sqlite3.wasm" \
  "$ROOT_DIR/web/drift_worker.js" "$ROOT_DIR/web/favicon.png" "$OUTPUT_DIR/"
mkdir -p "$OUTPUT_DIR/icons"
cp "$ROOT_DIR"/web/icons/*.png "$OUTPUT_DIR/icons/"

# Cross-target Flutter builds share intermediate outputs. A successful command
# alone does not prove the static bundle is complete; fail before publishing.
for asset in \
  index.html install.html main.dart.js flutter_bootstrap.js manifest.json \
  flutter_service_worker.js \
  canvaskit/canvaskit.js canvaskit/canvaskit.wasm \
  canvaskit/chromium/canvaskit.js canvaskit/chromium/canvaskit.wasm \
  icons/Icon-192.png icons/Icon-512.png sqlite3.wasm drift_worker.js \
  assets/FontManifest.json assets/fonts/MaterialIcons-Regular.otf \
  assets/assets/fonts/Pretendard-Regular.otf \
  assets/assets/fonts/Pretendard-Medium.otf \
  assets/assets/fonts/MaruBuri-Regular.ttf \
  assets/assets/fonts/MaruBuri-Bold.ttf; do
  if [[ ! -s "$OUTPUT_DIR/$asset" ]]; then
    printf 'Incomplete web release: missing or empty %s\n' "$asset" >&2
    exit 1
  fi
done
if [[ "$MM_SOURCE_HASH" != "$(node tool/release_manifest.mjs --hash)" ]]; then
  printf 'Source changed during build; refusing deployment.\n' >&2
  exit 1
fi
node tool/release_manifest.mjs "$OUTPUT_DIR"
node --check "$OUTPUT_DIR/flutter_bootstrap.js"

vercel link --yes --project "$PROJECT" --scope "$SCOPE" --cwd "$OUTPUT_DIR"
vercel project inspect --non-interactive --scope "$SCOPE" --cwd "$OUTPUT_DIR"
# Stage production first; promote exactly this verified bundle separately.
vercel deploy --prod --skip-domain --yes --scope "$SCOPE" --cwd "$OUTPUT_DIR"

#!/usr/bin/env bash
# Native remote-engine app. No web wrapper, audio upload or mock generation.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
MM_IOS_MODE="${1:---unsigned}"
if [[ "$MM_IOS_MODE" != '--unsigned' && "$MM_IOS_MODE" != '--signed' ]]; then
  printf 'Usage: bash tool/prepare_ios_trial.sh [--unsigned|--signed]\n' >&2
  exit 2
fi
if [[ "$MM_IOS_MODE" == '--signed' ]]; then
  if security find-identity -v -p codesigning | rg -q '0 valid identities found'; then
    printf 'No signing identity. Connect Apple Developer in Xcode and configure Runner Signing & Capabilities first.\n' >&2
    exit 1
  fi
  if ! rg -q 'DEVELOPMENT_TEAM = [A-Z0-9]+' ios/Runner.xcodeproj/project.pbxproj; then
    printf 'Runner development team is missing. Select your existing team in Xcode; do not paste credentials into chat.\n' >&2
    exit 1
  fi
fi
MM_PUBLISHABLE_KEY="$(node -e '
  const {execFileSync}=require("node:child_process");
  const keys=JSON.parse(execFileSync("supabase",["projects","api-keys","--project-ref","dtdmfjovpufyyekdumga","--reveal","-o","json"],{encoding:"utf8",stdio:["ignore","pipe","ignore"]}));
  const key=keys.find(k=>k.type==="publishable")?.api_key;if(!key)process.exit(1);process.stdout.write(key);
')"
MM_IOS_BUILD_ID="ios-$(date -u +%Y%m%dT%H%M%SZ)"
MM_SIGNING_ARGS=(--no-codesign)
if [[ "$MM_IOS_MODE" == '--signed' ]]; then MM_SIGNING_ARGS=(--export-method app-store); fi
flutter build ipa --release "${MM_SIGNING_ARGS[@]}" \
  --build-number="${MUMUMONG_IOS_BUILD_NUMBER:-2}" \
  --dart-define=ENV=staging --dart-define=ENGINE=remote --dart-define=AUTH=apple \
  --dart-define="BUILD_ID=$MM_IOS_BUILD_ID" \
  --dart-define=SUPABASE_URL=https://dtdmfjovpufyyekdumga.supabase.co \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=$MM_PUBLISHABLE_KEY"
if [[ "$MM_IOS_MODE" == '--unsigned' ]]; then
  printf 'UNSIGNED archive prepared: build/ios/archive/Runner.xcarchive\nNot installable and not uploaded to TestFlight. Build: %s\n' "$MM_IOS_BUILD_ID"
else
  printf 'Signed package prepared in build/ios/ipa. Review in Xcode Organizer before upload. Build: %s\n' "$MM_IOS_BUILD_ID"
fi

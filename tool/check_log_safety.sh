#!/usr/bin/env bash
set -euo pipefail

BAD='raw_text|passage\.text|story_so_far|transcript|rawText|passageText'

if grep -rnE --include='*.dart' --include='*.ts' \
  "(print|debugPrint|console\.log)[[:space:]]*\(.*($BAD)" \
  lib supabase/functions; then
  echo "FAIL: 본문이 로그에 노출될 수 있습니다"
  exit 1
fi

if grep -rnE --include='*.dart' \
  '(print|debugPrint|developer\.log)[[:space:]]*\(' lib \
  | grep -v 'lib/core/log/app_log.dart:'; then
  echo "FAIL: AppLog 외 직접 로그 사용"
  exit 1
fi

if grep -rnE --include='*.ts' 'console\.log[[:space:]]*\(' supabase/functions \
  | grep -v 'supabase/functions/_shared/log.ts:'; then
  echo "FAIL: 공유 로거 외 직접 console.log 사용"
  exit 1
fi

echo "OK"

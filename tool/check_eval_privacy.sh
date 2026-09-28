#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
tracked=$(git -C "$repo_root" ls-files -- eval/corpus eval/runs eval/judgments)
if [ -n "$tracked" ]; then
  echo "FAIL: 평가 데이터가 추적되고 있다. 즉시 git rm --cached 하라." >&2
  exit 1
fi
echo "OK"

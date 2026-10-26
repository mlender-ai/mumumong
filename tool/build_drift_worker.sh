#!/usr/bin/env bash
set -euo pipefail
MM_WORKER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$MM_WORKER_ROOT"
mkdir -p build/drift-worker
dart compile js -O2 --no-source-maps \
  -o build/drift-worker/drift_worker.js tool/drift_worker.dart
cp build/drift-worker/drift_worker.js web/drift_worker.js

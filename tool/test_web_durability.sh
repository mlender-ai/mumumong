#!/usr/bin/env bash
set -euo pipefail
MM_QA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$MM_QA_ROOT"
# Only the public WASM binary is served, never project files or credentials.
node --input-type=module -e '
  import http from "node:http";
  import {readFileSync} from "node:fs";
  const wasm = readFileSync("web/sqlite3.wasm");
  http.createServer((req, res) => {
    if (req.url !== "/sqlite3.wasm") { res.writeHead(404).end(); return; }
    res.writeHead(200, {"Content-Type":"application/wasm", "Access-Control-Allow-Origin":"*"});
    res.end(wasm);
  }).listen(4217, "127.0.0.1");
' &
MM_QA_SERVER_PID=$!
trap 'kill "$MM_QA_SERVER_PID" 2>/dev/null || true' EXIT
flutter test --no-pub --platform chrome test/browser/web_durability_chrome.dart --reporter expanded

// Local release only. Fault injection never modifies a compiled asset or data.
import http from 'node:http';
import {readFile} from 'node:fs/promises';
import {resolve, extname, sep} from 'node:path';

const root = resolve(process.argv[2] ?? 'build/pwa-qa');
const port = Number(process.argv[3] ?? 4219);
const fault = process.argv[4] ?? 'none';
if (!['none', 'bootstrap-once', 'main-once', 'engine-once'].includes(fault)) {
  throw Error('invalid_qa_fault');
}
let failed = false;
const mime = {'.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json',
  '.wasm': 'application/wasm', '.png': 'image/png', '.otf': 'font/otf', '.ttf': 'font/ttf'};
http.createServer(async (req, res) => {
  const pathname = new URL(req.url, 'http://localhost').pathname;
  let path;
  try { path = resolve(root, `.${decodeURIComponent(pathname === '/' ? '/index.html' : pathname)}`); }
  catch { res.writeHead(400).end(); return; }
  if (!path.startsWith(root + sep) || pathname.split('/').some(x => x.startsWith('.'))) {
    res.writeHead(403).end(); return;
  }
  const target = fault === 'bootstrap-once' ? '/flutter_bootstrap.js'
    : fault === 'main-once' ? '/main.dart.js' : '/canvaskit/canvaskit.wasm';
  const isEngine = fault === 'engine-once' && pathname.startsWith('/canvaskit/') && pathname.endsWith('.wasm');
  res.setHeader('Cache-Control', 'no-store');
  if (!failed && fault !== 'none' && (pathname === target || isEngine)) {
    failed = true;
    console.log(JSON.stringify({qa_fault: fault, status: 503}));
    res.writeHead(503).end('qa_asset_unavailable'); return;
  }
  try {
    const bytes = await readFile(path);
    res.writeHead(200, {'Content-Type': mime[extname(path)] ?? 'application/octet-stream'}).end(bytes);
  } catch { res.writeHead(404).end(); }
}).listen(port, '127.0.0.1', () => {
  console.log(JSON.stringify({qa_server: '127.0.0.1', port, fault}));
});

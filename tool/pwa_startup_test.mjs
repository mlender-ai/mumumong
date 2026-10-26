import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import test from 'node:test';
import assert from 'node:assert/strict';

const html = readFileSync(new URL('../web/index.html', import.meta.url), 'utf8');
const guard = html.match(/<script id="pwa-startup-guard">([\s\S]*?)<\/script>/u)[1];
const bootstrap = readFileSync(new URL('../web/flutter_bootstrap.js', import.meta.url), 'utf8')
  .replace('{{flutter_js}}', '').replace('{{flutter_build_config}}', '')
  .replace('{{flutter_service_worker_version}}', '"qa-version" /* Flutter\'s worker retirement */');
function harness() {
  const nodes = new Map(['pwa-startup', 'pwa-startup-title', 'pwa-startup-status', 'pwa-retry'].map(id =>
    [id, {hidden: id === 'pwa-retry', listeners: {}, addEventListener(type, fn) {this.listeners[type] = fn;},
      remove() {this.removed = true;}}]));
  const events = new Map(); let timeout; let reloads = 0;
  const window = {location: {reload() {reloads++;}},
    setTimeout(fn) {timeout = fn; return 1;}, clearTimeout() {timeout = null;},
    addEventListener(type, fn) {events.set(type, fn);}, removeEventListener(type) {events.delete(type);}};
  const document = {baseURI: 'https://example.test/app/', getElementById: id => nodes.get(id)};
  const context = vm.createContext({window, document, URL});
  vm.runInContext(guard, context);
  return {nodes, events, window, context, timeout: () => timeout?.(), reloads: () => reloads};
}
test('script failure offers explicit retry without clearing any stored data', () => {
  const h = harness();
  h.events.get('error')({target: {tagName: 'SCRIPT'}});
  assert.equal(h.nodes.get('pwa-retry').hidden, false);
  assert.match(h.nodes.get('pwa-startup-status').textContent, /기록을 지우지/u);
  assert.equal(h.reloads(), 0); // No automatic reload while a user is working.
  h.nodes.get('pwa-retry').listeners.click();
  assert.equal(h.reloads(), 1);
});
test('timeout and early rejection are recoverable, first frame removes guard', () => {
  const h = harness(); h.timeout();
  assert.equal(h.nodes.get('pwa-retry').hidden, false);
  h.events.get('flutter-first-frame')();
  assert.equal(h.nodes.get('pwa-startup').removed, true);
  assert.equal(h.events.has('unhandledrejection'), false);
  assert.equal(h.events.has('error'), false);
  h.window.mumumongStartup.fail();
  assert.equal(h.reloads(), 0);
});
test('non-script resource failure does not block startup', () => {
  const h = harness(); h.events.get('error')({target: {tagName: 'IMG'}});
  assert.equal(h.nodes.get('pwa-retry').hidden, true);
  h.events.get('unhandledrejection')();
  assert.equal(h.nodes.get('pwa-retry').hidden, false);
});
test('local CanvasKit config reaches both loader and engine; errors recover', async () => {
  const h = harness(); let options; let engineConfig;
  h.context._flutter = {loader: {load(value) {options = value; return Promise.resolve();}}};
  vm.runInContext(bootstrap, h.context);
  assert.equal(options.config.canvasKitBaseUrl, 'https://example.test/app/canvaskit/');
  await options.onEntrypointLoaded({async initializeEngine(config) {
    engineConfig = config; return {async runApp() {throw Error('qa_startup_failed');}};
  }});
  assert.equal(engineConfig, options.config);
  assert.equal(h.nodes.get('pwa-retry').hidden, false);
});
test('loader rejection is handled without leaking its message', async () => {
  const h = harness();
  h.context._flutter = {loader: {load() {return Promise.reject(Error('private_payload'));}}};
  vm.runInContext(bootstrap, h.context); await Promise.resolve();
  assert.equal(h.nodes.get('pwa-retry').hidden, false);
  assert.ok(!h.nodes.get('pwa-startup-status').textContent.includes('private_payload'));
});

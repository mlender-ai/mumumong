import {readFileSync} from 'node:fs';
import assert from 'node:assert/strict';
import test from 'node:test';
import vm from 'node:vm';

const read = file => readFileSync(new URL(`../${file}`, import.meta.url), 'utf8');
const html = read('web/install.html');
const script = html.match(/<script>([\s\S]*?)<\/script>/u)[1];
function render({standalone = false, media = false} = {}) {
  const locations = [];
  vm.runInNewContext(script, {
    navigator: {standalone},
    window: {matchMedia: () => ({matches: media}), location: {replace: path => locations.push(path)}},
  });
  return locations;
}
test('manifest start and installation page remain in one origin/scope', () => {
  const manifest = JSON.parse(read('web/manifest.json'));
  assert.equal(manifest.display, 'standalone');
  assert.equal(manifest.scope, '/');
  assert.equal(manifest.start_url, '/');
  assert.equal(manifest.id, '/'); // Do not create a new identity/store silently.
  assert.match(html, /rel="manifest" href="\/manifest.json"/u);
  assert.match(html, /apple-mobile-web-app-capable" content="yes"/u);
});
for (const options of [{}, {standalone: true}, {media: true}]) {
  test(`retired install link opens the same-origin app directly ${JSON.stringify(options)}`, () => {
    assert.deepEqual(render(options), ['/']);
  });
}
test('compatibility entry has no guide, cross-origin hop, or data reset', () => {
  assert.match(html, /href="\/">무무몽 열기/u);
  assert.doesNotMatch(html, /홈 화면에 추가|기존 기록은|launch-status|https:\/\//u);
  assert.doesNotMatch(script, /indexedDB|localStorage|sessionStorage|caches\.delete|serviceWorker/u);
});
test('retired installed origin never automatically navigates out of scope', () => {
  const retired = read('tool/mobile-preview-redirect/index.html');
  assert.doesNotMatch(retired, /http-equiv=["']refresh|location\.(?:replace|assign)|location\s*=/iu);
  assert.match(retired, /href="https:\/\/mumumong-live-trial\.vercel\.app\/install\.html"/u);
  assert.match(retired, /지우지 마세요/u);
  assert.match(retired, /자동 이전되지 않아요/u);
  const worker = read('tool/mobile-preview-redirect/flutter_service_worker.js');
  assert.doesNotMatch(worker, /\.navigate\(|location\.|clients\.openWindow/u);
  assert.doesNotMatch(worker, /indexedDB|localStorage|caches\.delete/u);
});

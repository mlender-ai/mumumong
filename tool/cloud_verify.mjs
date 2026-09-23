// Read-only deployment verification for the explicit MUMUMONG project.
// Keys remain in process memory and are never printed or written to files.
import { execFileSync } from 'node:child_process';
import assert from 'node:assert/strict';
const project = 'dtdmfjovpufyyekdumga';
const base = `https://${project}.supabase.co`;
const keys = JSON.parse(execFileSync('supabase', [
  'projects', 'api-keys', '--project-ref', project, '--reveal', '-o', 'json',
], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }));
const anon = keys.find(key => key.type === 'publishable')?.api_key
  ?? keys.find(key => key.name === 'anon').api_key;
const worker = keys.find(key => key.type === 'secret' && key.name === 'default').api_key;
for (const stage of ['extract', 'link', 'plan', 'write', 'validate', 'commit', 'remember']) {
  for (const [key, expected] of [[anon, 403], [worker, 404]]) {
    const response = await fetch(`${base}/functions/v1/engine-${stage}`, {
      method: 'POST',
      headers: { apikey: key, 'Content-Type': 'application/json' },
      body: JSON.stringify({ job_id: '00000000-0000-4000-8000-000000000000' }),
    });
    assert.equal(response.status, expected, `${stage} authorization/job lookup`);
  }
  console.log(`${stage}: non-worker denied; authorized request reached database lookup`);
}
const publicWorker = await fetch(`${base}/functions/v1/engine-worker`, {
  method: 'POST', headers: { apikey: anon, 'Content-Type': 'application/json' }, body: '{}',
});
assert.equal(publicWorker.status, 403, 'worker requires a user token or service credential');
const serviceWorker = await fetch(`${base}/functions/v1/engine-worker`, {
  method: 'POST', headers: { apikey: worker, 'Content-Type': 'application/json' }, body: '{}',
});
assert.equal(serviceWorker.status, 200, 'service worker reaches the queue');
console.log('Worker authorization enforced; service worker reached the queue.');
for (const table of ['dreams', 'passages', 'dream_elements', 'volumes']) {
  const response = await fetch(`${base}/rest/v1/${table}?select=id&limit=1`, {
    headers: { apikey: anon, Authorization: `Bearer ${anon}` },
  });
  // Depending on configured grants, anonymous access is denied or RLS-filtered.
  if (response.ok) assert.deepEqual(await response.json(), [], `${table} anonymous rows`);
  else assert.ok([401, 403].includes(response.status), `${table} access denied`);
}
console.log('Anonymous manuscript access blocked; no remote records were created or modified.');
const deletion = await fetch(`${base}/functions/v1/delete-account`, {
  method: 'POST', headers: { apikey: anon, 'Content-Type': 'application/json' }, body: '{}',
});
assert.equal(deletion.status, 401, 'anonymous account deletion must be denied');
console.log('Anonymous account deletion denied.');

// Q-02 hosted model-audit smoke. Synthetic input and credentials stay process-only.
// This runs extract only; it never writes or corrects a generated manuscript.
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';

const project = 'dtdmfjovpufyyekdumga';
const base = `https://${project}.supabase.co`;
const keys = JSON.parse(execFileSync('supabase', [
  'projects', 'api-keys', '--project-ref', project, '--reveal', '-o', 'json',
], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }));
const secret = keys.find(key => key.type === 'secret').api_key;
const headers = { apikey: secret, 'Content-Type': 'application/json', Prefer: 'return=representation' };
let userId;
async function request(path, method = 'GET', body) {
  const response = await fetch(`${base}${path}`, {
    method, headers,
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    signal: AbortSignal.timeout(65_000),
  });
  assert.ok(response.ok, `HTTP ${response.status}`);
  const text = await response.text();
  try { return text ? JSON.parse(text) : null; }
  catch { throw new Error('response_invalid_json'); }
}
async function insert(table, row) { return (await request(`/rest/v1/${table}`, 'POST', row))[0]; }

try {
  const user = await request('/auth/v1/admin/users', 'POST', {
    email: `q02-version-${randomUUID()}@example.test`, password: `${randomUUID()}Aa!`, email_confirm: true,
  });
  userId = user.id;
  const volume = await insert('volumes', {
    user_id: userId, vol_no: 1, format: 'short', adaptation: 'balanced', style: 'plain',
    narrative_voice: 'first_person_past', target_mu: 20,
  });
  const dream = await insert('dreams', {
    user_id: userId, volume_id: volume.id, input_mode: 'text', status: 'queued',
    raw_text: '동그란 돌이 빈 종이컵 안에서 굴렀다. 나는 컵을 들고 멈췄다.', recall_answers: {},
  });
  const job = await insert('jobs', {
    user_id: userId, volume_id: volume.id, dream_id: dream.id, type: 'extract',
    status: 'running', attempt: 1, idempotency_key: randomUUID(), payload: {},
  });
  const extracted = await request('/functions/v1/engine-extract', 'POST', { job_id: job.id });
  assert.equal(extracted.ok, true);
  const runs = await request(`/rest/v1/generation_runs?job_id=eq.${job.id}&select=stage,engine_version,model`);
  assert.equal(runs.length, 1);
  assert.equal(runs[0].engine_version, 'v10');
  assert.equal(runs[0].stage, 'extract');
  assert.equal(runs[0].model, 'openai/gpt-oss-20b');
  console.log('PASS: hosted model audit engine_version=v10 records=1');
} finally {
  if (userId) await request(`/auth/v1/admin/users/${userId}`, 'DELETE');
}

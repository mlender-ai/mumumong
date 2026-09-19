// Local-only integration smoke. Run after `supabase functions serve`.
// Uses a disposable account; never prints request/response bodies or keys.
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';

const config = JSON.parse(execFileSync('supabase', ['status', '-o', 'json'], {
  encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'],
}));
const base = config.API_URL;
assert.match(base, /^http:\/\/127\.0\.0\.1:/);
const key = config.SERVICE_ROLE_KEY;
async function request(path, method = 'GET', body, token = key) {
  const response = await fetch(`${base}${path}`, {
    method,
    headers: {
      apikey: key, Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json', Prefer: 'return=representation',
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
  const text = await response.text();
  return { status: response.status, data: text ? JSON.parse(text) : null };
}
async function insert(table, body) {
  const response = await request(`/rest/v1/${table}`, 'POST', body);
  assert.equal(response.status, 201, `insert ${table} failed`);
  return response.data[0];
}
const userResponse = await request('/auth/v1/admin/users', 'POST', {
  email: `engine-smoke-${randomUUID()}@example.test`,
  password: randomUUID(), email_confirm: true,
});
assert.equal(userResponse.status, 200, 'create smoke user');
const userId = userResponse.data.id;
try {
  const volume = await insert('volumes', {
    user_id: userId, vol_no: 1, format: 'novella', adaptation: 'balanced',
    style: 'plain', narrative_voice: 'third_person_past', status: 'active', target_mu: 80,
  });
  async function dream() {
    return await insert('dreams', {
      user_id: userId, volume_id: volume.id, dream_date: '2026-09-19',
      input_mode: 'text', raw_text: '테스트용 문', status: 'processing', clarity: 'fragment',
    });
  }
  const source = await dream();
  const element = await insert('dream_elements', {
    dream_id: source.id, type: 'object', label: '문', salience: 'high', source: 'raw',
  });
  const draft = {
    scene: { placement: 'continuation', kind: 'dream', title: '문' },
    passages: [{ origin: 'D', text: '문이 열려 있었다.', source_element_ids: [element.id] }],
    open_image: '문 뒤의 발소리',
  };
  async function job(type, dreamId, payload) {
    return await insert('jobs', {
      user_id: userId, volume_id: volume.id, dream_id: dreamId,
      type, status: 'running', attempt: 1, idempotency_key: randomUUID(), payload,
    });
  }
  const validation = await job('validate', source.id, { draft, clarity: 'fragment', adaptation: 'balanced' });
  const validated = await request('/functions/v1/engine-validate', 'POST', { job_id: validation.id });
  assert.equal(validated.status, 200, 'validate HTTP');
  assert.equal(validated.data.ok, true, 'valid scene accepted');
  for (const stage of ['validate', 'commit']) {
    const denied = await request(`/functions/v1/engine-${stage}`, 'POST', { job_id: validation.id }, config.ANON_KEY);
    assert.equal(denied.status, 403, 'non-worker rejected');
  }
  const audit = await request(`/rest/v1/generation_runs?job_id=eq.${validation.id}&select=validation`);
  assert.equal(audit.data.length, 1);
  assert.equal(JSON.stringify(audit.data).includes(draft.passages[0].text), false);
  const commit = await job('commit', source.id, {
    draft, clarity: 'fragment', placement: 'continuation', scene_order_key: 'a0001',
  });
  const first = await request('/functions/v1/engine-commit', 'POST', { job_id: commit.id });
  assert.equal(first.status, 200, 'commit HTTP');
  const second = await request('/functions/v1/engine-commit', 'POST', { job_id: commit.id });
  assert.equal(second.status, 200);
  assert.equal(first.data.sceneId, second.data.sceneId);
  const scenes = await request(`/rest/v1/scenes?volume_id=eq.${volume.id}&select=id`);
  assert.equal(scenes.data.length, 1, 'one scene after retry');
  const remember = await request(`/rest/v1/jobs?dream_id=eq.${source.id}&type=eq.remember&select=id`);
  assert.equal(remember.data.length, 1, 'one remember job after retry');

  const badSource = await dream();
  const badCommit = await job('commit', badSource.id, {
    draft, clarity: 'fragment', placement: 'continuation', scene_order_key: 'a0002',
  });
  const failed = await request('/functions/v1/engine-commit', 'POST', { job_id: badCommit.id });
  assert.equal(failed.status, 500, 'cross-dream element rejects transaction');
  const after = await request(`/rest/v1/scenes?volume_id=eq.${volume.id}&select=id`);
  assert.equal(after.data.length, 1, 'failed commit rolled back scene insert');
  process.stdout.write('PASS: validate, audit privacy, worker authorization, commit retry, remember deduplication, transaction rollback\n');
} finally {
  const cleanup = await request(`/auth/v1/admin/users/${userId}`, 'DELETE');
  assert.equal(cleanup.status, 200, 'remove disposable smoke account');
}

// Hosted smoke for the same RLS-constrained operations used by the Flutter
// cloud sync layer. Credentials and manuscript content remain process-only.
import { execFileSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import assert from 'node:assert/strict';

const project = 'dtdmfjovpufyyekdumga';
const base = `https://${project}.supabase.co`;
const keys = JSON.parse(execFileSync('supabase', [
  'projects', 'api-keys', '--project-ref', project, '--reveal', '-o', 'json',
], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }));
const publishable = keys.find(key => key.type === 'publishable').api_key;
const secret = keys.find(key => key.type === 'secret').api_key;
const adminHeaders = {
  apikey: secret,
  'Content-Type': 'application/json',
};
const email = `mumumong-app-${randomUUID()}@example.test`;
const password = `${randomUUID()}Aa!`;
let userId;

async function request(path, { method = 'GET', body, headers = adminHeaders } = {}) {
  const response = await fetch(`${base}${path}`, {
    method,
    headers,
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
  const text = await response.text();
  const data = text ? JSON.parse(text) : null;
  assert.ok(response.ok, `${method} ${path} failed with ${response.status}`);
  return data;
}

try {
  const created = await request('/auth/v1/admin/users', {
    method: 'POST',
    body: { email, password, email_confirm: true },
  });
  userId = created.id;
  const login = await request('/auth/v1/token?grant_type=password', {
    method: 'POST',
    headers: { apikey: publishable, 'Content-Type': 'application/json' },
    body: { email, password },
  });
  const userHeaders = {
    apikey: publishable,
    Authorization: `Bearer ${login.access_token}`,
    'Content-Type': 'application/json',
    Prefer: 'return=representation',
  };

  const [volume] = await request('/rest/v1/volumes', {
    method: 'POST',
    headers: userHeaders,
    body: {
      user_id: userId,
      vol_no: 1,
      format: 'short',
      adaptation: 'balanced',
      style: 'plain',
      narrative_voice: 'third_person_past',
      target_mu: 20,
    },
  });
  assert.equal(volume.format, 'short');
  assert.equal(Number(volume.target_mu), 20);

  const dreamId = randomUUID();
  const dreamPayload = {
    id: dreamId,
    user_id: userId,
    volume_id: volume.id,
    dream_date: '2026-09-26',
    recorded_at: new Date().toISOString(),
    input_mode: 'text',
    raw_text: '비가 오는 복도에서 붉은 문을 열자 작은 배가 떠올랐다. 배 안의 여자가 우산을 접었고, 멀리서 종소리가 세 번 들렸다.',
    recall_answers: { light: '푸른빛', feeling: '조용한 긴장' },
    status: 'processing',
    is_backfill: false,
  };
  await request('/rest/v1/dreams?on_conflict=id', {
    method: 'POST',
    headers: { ...userHeaders, Prefer: 'resolution=merge-duplicates,return=representation' },
    body: dreamPayload,
  });
  // The foreground path and an Outbox retry use the same row and must converge.
  await request('/rest/v1/dreams?on_conflict=id', {
    method: 'POST',
    headers: { ...userHeaders, Prefer: 'resolution=merge-duplicates,return=representation' },
    body: dreamPayload,
  });
  await request('/rest/v1/jobs', {
    method: 'POST',
    headers: userHeaders,
    body: {
      user_id: userId,
      volume_id: volume.id,
      dream_id: dreamId,
      type: 'extract',
      status: 'queued',
      idempotency_key: dreamId,
      payload: {},
    },
  });

  const kicked = await fetch(`${base}/functions/v1/engine-worker`, {
    method: 'POST',
    headers: userHeaders,
    body: '{}',
  });
  assert.ok([200, 202].includes(kicked.status), 'authenticated app starts own worker');

  const deadline = Date.now() + 140_000;
  let dream;
  let jobs = [];
  while (Date.now() < deadline) {
    [dream] = await request(`/rest/v1/dreams?id=eq.${dreamId}&select=status,clarity`, {
      headers: userHeaders,
    });
    jobs = await request(
      `/rest/v1/jobs?dream_id=eq.${dreamId}&select=type,status,error&order=created_at.asc`,
      { headers: userHeaders },
    );
    const failed = jobs.find(job => job.status === 'failed');
    assert.equal(failed, undefined, `pipeline failed at ${failed?.type ?? 'unknown'}`);
    const active = jobs.some(job => ['queued', 'running'].includes(job.status));
    if (!active && ['in_manuscript', 'archived_only'].includes(dream?.status)) break;
    await new Promise(resolve => setTimeout(resolve, 2_000));
  }
  assert.ok(
    ['in_manuscript', 'archived_only'].includes(dream?.status),
    'dream reaches a successful terminal state',
  );

  const [scenes, passages, elements, progress, volumes] = await Promise.all([
    request(`/rest/v1/scenes?volume_id=eq.${volume.id}&select=id,source_dream_ids`, { headers: userHeaders }),
    request(`/rest/v1/passages?source_dream_id=eq.${dreamId}&select=origin,source_element_ids`, { headers: userHeaders }),
    request(`/rest/v1/dream_elements?dream_id=eq.${dreamId}&select=id`, { headers: userHeaders }),
    request(`/rest/v1/progress_events?dream_id=eq.${dreamId}&select=delta_mu`, { headers: userHeaders }),
    request(`/rest/v1/volumes?id=eq.${volume.id}&select=progress_mu`, { headers: userHeaders }),
  ]);
  assert.ok(scenes.some(scene => scene.source_dream_ids.includes(dreamId)));
  assert.ok(elements.length > 0);
  assert.ok(passages.some(passage =>
    passage.origin === 'D'
      && passage.source_element_ids.every(id => elements.some(element => element.id === id))));
  assert.equal(progress.length, 1);
  assert.equal(Number(volumes[0].progress_mu), Number(progress[0].delta_mu));
  console.log(`App round-trip passed ${jobs.map(job => job.type).join(' -> ')}; RLS push/pull and provenance are intact.`);
} finally {
  if (userId) {
    await fetch(`${base}/auth/v1/admin/users/${userId}`, {
      method: 'DELETE',
      headers: adminHeaders,
    });
  }
}

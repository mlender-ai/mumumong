// Hosted public-trial contract smoke. Uses only invented text and prints no
// dream content, JWTs, or keys. The disposable anonymous account is removed.
import { execFileSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import assert from 'node:assert/strict';

const project = 'dtdmfjovpufyyekdumga';
const base = `https://${project}.supabase.co`;
const keys = JSON.parse(execFileSync('supabase', [
  'projects', 'api-keys', '--project-ref', project, '--reveal', '-o', 'json',
], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }));
const publishable = keys.find(key => key.type === 'publishable')?.api_key;
const secret = keys.find(key => key.type === 'secret')?.api_key;
assert.ok(publishable && secret, 'hosted project keys available');
let userId;

async function request(path, { method = 'GET', token, body, admin = false } = {}) {
  const response = await fetch(`${base}${path}`, {
    method,
    headers: {
      apikey: admin ? secret : publishable,
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
  const raw = await response.text();
  let data;
  try { data = raw ? JSON.parse(raw) : null; } catch { data = null; }
  return { status: response.status, data };
}

try {
  const signup = await request('/auth/v1/signup', {
    method: 'POST', body: { data: {}, gotrue_meta_security: {} },
  });
  assert.equal(signup.status, 200, `anonymous sign-in HTTP ${signup.status}`);
  assert.equal(signup.data?.user?.is_anonymous, true);
  userId = signup.data.user.id;
  const token = signup.data.access_token;
  assert.ok(token, 'anonymous session issued');

  const policy = await request('/rest/v1/ai_consent_policy?select=version&id=eq.1');
  assert.equal(policy.status, 200);
  const version = policy.data?.[0]?.version;
  assert.ok(Number.isInteger(version));
  const consent = await request('/rest/v1/rpc/accept_ai_consent', {
    method: 'POST', token,
    body: { p_version: version, p_age_confirmed: true },
  });
  assert.equal(consent.status, 200);
  assert.equal(consent.data, true);

  const volume = await request('/rest/v1/volumes', {
    method: 'POST', token,
    body: {
      user_id: userId, vol_no: 1, format: 'short', adaptation: 'balanced',
      style: 'plain', narrative_voice: 'first_person_past', target_mu: 20,
    },
  });
  assert.equal(volume.status, 201, `create volume HTTP ${volume.status}`);
  const volumeId = volume.data?.[0]?.id;
  assert.ok(volumeId);

  const dreamIds = [];
  for (let i = 0; i < 4; i++) {
    const dream = await request('/rest/v1/dreams', {
      method: 'POST', token,
      body: {
        user_id: userId, volume_id: volumeId, input_mode: 'text',
        status: 'queued', raw_text: `Synthetic public trial fixture ${i + 1}`,
      },
    });
    assert.equal(dream.status, 201, `create dream ${i + 1} HTTP ${dream.status}`);
    dreamIds.push(dream.data?.[0]?.id);
  }

  for (let i = 0; i < 3; i++) {
    const queued = await request('/rest/v1/jobs', {
      method: 'POST', token,
      body: {
        user_id: userId, volume_id: volumeId, dream_id: dreamIds[i],
        type: 'extract', status: 'queued', attempt: 0,
        idempotency_key: randomUUID(), payload: {},
      },
    });
    assert.equal(queued.status, 201, `enqueue ${i + 1} HTTP ${queued.status}`);
  }

  const fourth = await request('/rest/v1/jobs', {
    method: 'POST', token,
    body: {
      user_id: userId, volume_id: volumeId, dream_id: dreamIds[3],
      type: 'extract', status: 'queued', attempt: 0,
      idempotency_key: randomUUID(), payload: {},
    },
  });
  assert.equal(fourth.data?.code, 'P0001');
  assert.equal(fourth.data?.message, 'trial_user_daily_limit');
  console.log('Hosted anonymous trial: sign-in, consent, owned capture, three jobs and fourth-job denial passed.');
} finally {
  if (userId) {
    const removed = await request(`/auth/v1/admin/users/${userId}`, {
      method: 'DELETE', admin: true,
    });
    assert.ok([200, 204].includes(removed.status), `disposable account cleanup HTTP ${removed.status}`);
  }
}

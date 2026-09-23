// End-to-end hosted smoke for the real Groq pipeline. All credentials and
// manuscript text stay process-only; output contains stage metadata only.
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
const adminHeaders = { apikey: secret, 'Content-Type': 'application/json', Prefer: 'return=representation' };
const email = `mumumong-pipeline-${randomUUID()}@example.test`;
const password = `${randomUUID()}Aa!`;
let userId;

async function admin(path, method = 'GET', body) {
  const response = await fetch(`${base}${path}`, {
    method, headers: adminHeaders,
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
  const text = await response.text();
  const data = text ? JSON.parse(text) : null;
  assert.ok(response.ok, `${method} ${path} failed with ${response.status}`);
  return data;
}

async function insert(table, row) {
  return (await admin(`/rest/v1/${table}`, 'POST', row))[0];
}

try {
  const created = await admin('/auth/v1/admin/users', 'POST', {
    email, password, email_confirm: true,
  });
  userId = created.id;
  const login = await fetch(`${base}/auth/v1/token?grant_type=password`, {
    method: 'POST', headers: { apikey: publishable, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  assert.equal(login.status, 200, 'sign in disposable pipeline account');
  const accessToken = (await login.json()).access_token;

  const volume = await insert('volumes', {
    user_id: userId, vol_no: 1, format: 'short', adaptation: 'balanced',
    style: 'plain', narrative_voice: 'third_person_past', target_mu: 20,
  });
  const existingScene = await insert('scenes', {
    volume_id: volume.id, order_key: 's0001', kind: 'dream',
    placement: 'continuation', title: '복도의 문', open_image: '문 아래로 번지는 물빛',
  });
  await insert('entities', {
    volume_id: volume.id, type: 'person', role_name: '우산 든 여자',
    description: '붉은 우산을 들고 복도에 서 있던 인물', aliases: ['복도의 여자'],
    status: 'confirmed', first_scene_id: existingScene.id,
  });
  const dream = await insert('dreams', {
    user_id: userId, volume_id: volume.id, input_mode: 'text', status: 'queued',
    raw_text: '우산 든 여자가 붉은 문 앞에 서 있었다. 여자가 문을 열자 복도에 물이 차올랐고, 천장의 불빛이 차례로 꺼졌다. 나는 물속에서 작은 열쇠를 주웠다.',
    recall_answers: { feeling: '조용히 불안했다', light: '푸른빛' },
  });
  await insert('jobs', {
    user_id: userId, volume_id: volume.id, dream_id: dream.id,
    type: 'extract', status: 'queued', idempotency_key: randomUUID(), payload: {},
  });

  const kicked = await fetch(`${base}/functions/v1/engine-worker`, {
    method: 'POST',
    headers: {
      apikey: publishable,
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: '{}',
  });
  const kickedBody = await kicked.json();
  assert.ok(
    [200, 202].includes(kicked.status),
    `authenticated user starts own worker: ${JSON.stringify(kickedBody)}`,
  );

  const deadline = Date.now() + 140_000;
  let jobs = [];
  let finalDream;
  while (Date.now() < deadline) {
    jobs = await admin(`/rest/v1/jobs?dream_id=eq.${dream.id}&select=id,type,status,attempt,error&order=created_at.asc`);
    finalDream = (await admin(`/rest/v1/dreams?id=eq.${dream.id}&select=status,clarity`))[0];
    const failed = jobs.find(job => job.status === 'failed');
    if (failed) {
      const jobIds = jobs.map(job => job.id).join(',');
      const runs = await admin(
        `/rest/v1/generation_runs?job_id=in.(${jobIds})&select=stage,validation&order=created_at.asc`,
      );
      const diagnostics = runs.map(run => ({
        stage: run.stage,
        codes: Array.isArray(run.validation?.codes) ? run.validation.codes : [],
      }));
      throw new Error(
        `pipeline failed at ${failed.type}: ${failed.error ?? 'unknown'}; ${JSON.stringify(diagnostics)}`,
      );
    }
    const active = jobs.some(job => job.status === 'queued' || job.status === 'running');
    if (!active && ['in_manuscript', 'archived_only'].includes(finalDream.status)) break;
    await new Promise(resolve => setTimeout(resolve, 2_000));
  }

  assert.ok(['in_manuscript', 'archived_only'].includes(finalDream?.status), 'dream reaches terminal success');
  const stages = jobs.map(job => job.type);
  assert.deepEqual(stages.slice(0, 4), ['extract', 'link', 'plan', 'write']);
  assert.ok(stages.includes('validate') && stages.includes('commit'), 'validation and commit ran');
  const scenes = await admin(`/rest/v1/scenes?volume_id=eq.${volume.id}&select=id`);
  assert.ok(scenes.length >= 2, 'a new scene was committed');
  const passages = await admin(`/rest/v1/passages?source_dream_id=eq.${dream.id}&select=origin,source_element_ids`);
  assert.ok(passages.some(passage => passage.origin === 'D' && passage.source_element_ids.length > 0),
    'dream passages retain real provenance');
  console.log(`Hosted pipeline passed ${stages.join(' -> ')} with ${passages.length} passages.`);
} finally {
  if (userId) {
    await fetch(`${base}/auth/v1/admin/users/${userId}`, { method: 'DELETE', headers: adminHeaders });
  }
}

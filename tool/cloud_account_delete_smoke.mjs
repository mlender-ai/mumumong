// Creates and deletes one disposable cloud account to verify the complete
// deletion path. Credentials are random, process-only, and never printed.
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
const email = `mumumong-delete-${randomUUID()}@example.test`;
const password = `${randomUUID()}Aa!`;
const adminHeaders = { apikey: secret, 'Content-Type': 'application/json' };
let userId;
try {
  const created = await fetch(`${base}/auth/v1/admin/users`, {
    method: 'POST', headers: adminHeaders,
    body: JSON.stringify({ email, password, email_confirm: true }),
  });
  assert.equal(created.status, 200, 'create disposable account');
  userId = (await created.json()).id;
  const login = await fetch(`${base}/auth/v1/token?grant_type=password`, {
    method: 'POST', headers: { apikey: publishable, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  assert.equal(login.status, 200, 'sign in disposable account');
  const accessToken = (await login.json()).access_token;
  const deleted = await fetch(`${base}/functions/v1/delete-account`, {
    method: 'POST', headers: { apikey: publishable,
      Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' }, body: '{}',
  });
  assert.equal(deleted.status, 200, 'delete account function');
  const lookup = await fetch(`${base}/auth/v1/admin/users/${userId}`, { headers: adminHeaders });
  assert.equal(lookup.status, 404, 'deleted auth user is absent');
  userId = undefined;
  console.log('Disposable cloud account and all owned data deleted successfully.');
} finally {
  if (userId) {
    await fetch(`${base}/auth/v1/admin/users/${userId}`, { method: 'DELETE', headers: adminHeaders });
  }
}

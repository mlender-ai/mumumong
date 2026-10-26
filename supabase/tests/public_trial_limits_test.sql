begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select plan(6);

insert into auth.users (
  instance_id, id, aud, role, email,
  confirmation_token, recovery_token, email_change_token_new, email_change,
  raw_app_meta_data, raw_user_meta_data, is_anonymous, created_at, updated_at
)
select
  '00000000-0000-0000-0000-000000000000'::uuid,
  ('c1616161-1616-4161-8161-16161616161' || n)::uuid,
  'authenticated', 'authenticated',
  ('trial-' || n || '@example.test'),
  '', '', '', '',
  '{"provider":"anonymous","providers":[]}'::jsonb, '{}'::jsonb,
  true, now(), now()
from generate_series(1, 3) as n;

insert into public.volumes (id, user_id, vol_no, status)
select
  ('d1616161-1616-4161-8161-16161616161' || n)::uuid,
  ('c1616161-1616-4161-8161-16161616161' || n)::uuid,
  1, 'active'
from generate_series(1, 3) as n;

insert into public.dreams (id, user_id, volume_id, input_mode, raw_text, status)
select
  ('e1616161-1616-4161-8161-16161616161' || n)::uuid,
  ('c1616161-1616-4161-8161-16161616161' || n)::uuid,
  ('d1616161-1616-4161-8161-16161616161' || n)::uuid,
  'text', 'Synthetic trial fixture', 'queued'
from generate_series(1, 3) as n;

insert into public.dreams (id, user_id, volume_id, input_mode, raw_text, status)
select
  ('f1616161-1616-4161-8161-16161616161' || n)::uuid,
  'c1616161-1616-4161-8161-161616161611'::uuid,
  'd1616161-1616-4161-8161-161616161611'::uuid,
  'text', 'Synthetic trial fixture', 'queued'
from generate_series(1, 3) as n;

insert into public.profiles (user_id, consent_version, consented_at, age_confirmed)
select ('c1616161-1616-4161-8161-16161616161' || n)::uuid, 1, now(), true
from generate_series(1, 3) as n;

set local role authenticated;
select set_config('request.jwt.claim.sub',
  'c1616161-1616-4161-8161-161616161611', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claims',
  '{"sub":"c1616161-1616-4161-8161-161616161611","role":"authenticated","is_anonymous":true}', true);

select lives_ok($$
  insert into public.jobs (user_id, volume_id, dream_id, type, idempotency_key)
  select 'c1616161-1616-4161-8161-161616161611',
         'd1616161-1616-4161-8161-161616161611',
         ('f1616161-1616-4161-8161-16161616161' || n)::uuid,
         'extract', gen_random_uuid()
    from generate_series(1, 3) as n
$$, 'anonymous trial can create three first-stage jobs');

select throws_ok($$
  insert into public.jobs (user_id, volume_id, dream_id, type, idempotency_key)
  values ('c1616161-1616-4161-8161-161616161611',
          'd1616161-1616-4161-8161-161616161611',
          'e1616161-1616-4161-8161-161616161611', 'extract', gen_random_uuid())
$$, 'P0001', 'trial_user_daily_limit', 'fourth job is limited');

select is_empty($$
  update public.jobs set status = 'done'
   where user_id = 'c1616161-1616-4161-8161-161616161611'
   returning id
$$, 'client cannot alter engine-owned job state');

select is_empty($$
  delete from public.jobs
   where user_id = 'c1616161-1616-4161-8161-161616161611'
   returning id
$$, 'client cannot erase jobs to reset quota');

select throws_ok($$
  insert into public.jobs (user_id, volume_id, dream_id, type, idempotency_key)
  values ('c1616161-1616-4161-8161-161616161611',
          'd1616161-1616-4161-8161-161616161611',
          'e1616161-1616-4161-8161-161616161611', 'write', gen_random_uuid())
$$, '42501', 'new row violates row-level security policy for table "jobs"',
  'client cannot forge a downstream stage');

reset role;
select set_config('request.jwt.claim.role', 'service_role', true);
select set_config('request.jwt.claims',
  '{"role":"service_role","is_anonymous":false}', true);
insert into public.jobs (
  user_id, volume_id, dream_id, type, status, idempotency_key
)
select
  'c1616161-1616-4161-8161-161616161612',
  'd1616161-1616-4161-8161-161616161612',
  'e1616161-1616-4161-8161-161616161612',
  'extract', 'done', gen_random_uuid()
from generate_series(1, 47);

set local role authenticated;
select set_config('request.jwt.claim.sub',
  'c1616161-1616-4161-8161-161616161613', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claims',
  '{"sub":"c1616161-1616-4161-8161-161616161613","role":"authenticated","is_anonymous":true}', true);

select throws_ok($$
  insert into public.jobs (user_id, volume_id, dream_id, type, idempotency_key)
  values ('c1616161-1616-4161-8161-161616161613',
          'd1616161-1616-4161-8161-161616161613',
          'e1616161-1616-4161-8161-161616161613', 'extract', gen_random_uuid())
$$, 'P0001', 'trial_global_daily_limit', 'global trial budget is bounded');

select * from finish();
rollback;

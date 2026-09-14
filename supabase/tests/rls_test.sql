begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

-- User B owns a complete fixture graph. Tests run later as seeded user A.
insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  email_change,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values (
  '00000000-0000-0000-0000-000000000000',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'authenticated',
  'authenticated',
  'rls-b@mumumong.local',
  '',
  '',
  '',
  '',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{}'::jsonb,
  now(),
  now()
);

insert into public.volumes (id, user_id, vol_no, status)
values
  (
    'b1111111-1111-4111-8111-111111111111',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    1,
    'active'
  ),
  (
    'b2222222-2222-4222-8222-222222222222',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    2,
    'completed'
  );

insert into public.dreams (
  id,
  user_id,
  volume_id,
  input_mode,
  raw_text,
  status
)
values (
  'b3333333-3333-4333-8333-333333333333',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'b1111111-1111-4111-8111-111111111111',
  'text',
  'RLS fixture',
  'in_manuscript'
);

insert into public.dream_elements (
  id,
  dream_id,
  type,
  label,
  salience,
  source
)
values (
  'b4444444-4444-4444-8444-444444444444',
  'b3333333-3333-4333-8333-333333333333',
  'object',
  'fixture element',
  'high',
  'raw'
);

insert into public.scenes (id, volume_id, order_key, kind, placement)
values (
  'b5555555-5555-4555-8555-555555555555',
  'b1111111-1111-4111-8111-111111111111',
  'a0',
  'dream',
  'continuation'
);

insert into public.passages (
  id,
  user_id,
  scene_id,
  order_key,
  text,
  origin,
  source_dream_id,
  source_element_ids,
  locked,
  created_by
)
values (
  'b6666666-6666-4666-8666-666666666666',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'b5555555-5555-4555-8555-555555555555',
  'a0',
  'RLS fixture',
  'D',
  'b3333333-3333-4333-8333-333333333333',
  array['b4444444-4444-4444-8444-444444444444']::uuid[],
  false,
  'engine'
);

insert into public.entities (id, volume_id, type, role_name)
values (
  'b7777777-7777-4777-8777-777777777777',
  'b1111111-1111-4111-8111-111111111111',
  'person',
  'fixture role'
);

insert into public.entity_mentions (
  id,
  entity_id,
  dream_element_id,
  scene_id,
  passage_id
)
values (
  'b8888888-8888-4888-8888-888888888888',
  'b7777777-7777-4777-8777-777777777777',
  'b4444444-4444-4444-8444-444444444444',
  'b5555555-5555-4555-8555-555555555555',
  'b6666666-6666-4666-8666-666666666666'
);

insert into public.link_decisions (
  id,
  volume_id,
  dream_id,
  kind,
  payload,
  status
)
values (
  'b9999999-9999-4999-8999-999999999999',
  'b1111111-1111-4111-8111-111111111111',
  'b3333333-3333-4333-8333-333333333333',
  'entity_merge',
  '{"element_id":"fixture"}'::jsonb,
  'pending'
);

insert into public.narrative_memory (volume_id, story_so_far)
values (
  'b1111111-1111-4111-8111-111111111111',
  'RLS fixture'
);

insert into public.progress_events (
  id,
  user_id,
  volume_id,
  dream_id,
  delta_mu
)
values (
  'baaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'b1111111-1111-4111-8111-111111111111',
  'b3333333-3333-4333-8333-333333333333',
  1
);

insert into public.jobs (
  id,
  user_id,
  dream_id,
  volume_id,
  type,
  idempotency_key
)
values (
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'b3333333-3333-4333-8333-333333333333',
  'b1111111-1111-4111-8111-111111111111',
  'extract',
  'bddddddd-dddd-4ddd-8ddd-dddddddddddd'
);

insert into public.generation_runs (
  id,
  job_id,
  stage,
  model,
  prompt_version
)
values (
  'bccccccc-cccc-4ccc-8ccc-cccccccccccc',
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  'extract',
  'fixture-model',
  'fixture-v1'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select plan(49);

select is_empty(
  $$
    select tablename
      from pg_tables
     where schemaname = 'public'
       and rowsecurity = false
  $$,
  'every public table has RLS enabled'
);

-- SELECT: user A cannot see any row owned by user B.
select is((select count(*)::integer from public.volumes where id = 'b1111111-1111-4111-8111-111111111111'), 0, 'volumes blocks cross-user select');
select is((select count(*)::integer from public.dreams where id = 'b3333333-3333-4333-8333-333333333333'), 0, 'dreams blocks cross-user select');
select is((select count(*)::integer from public.dream_elements where id = 'b4444444-4444-4444-8444-444444444444'), 0, 'dream_elements blocks cross-user select');
select is((select count(*)::integer from public.entities where id = 'b7777777-7777-4777-8777-777777777777'), 0, 'entities blocks cross-user select');
select is((select count(*)::integer from public.entity_mentions where id = 'b8888888-8888-4888-8888-888888888888'), 0, 'entity_mentions blocks cross-user select');
select is((select count(*)::integer from public.scenes where id = 'b5555555-5555-4555-8555-555555555555'), 0, 'scenes blocks cross-user select');
select is((select count(*)::integer from public.passages where id = 'b6666666-6666-4666-8666-666666666666'), 0, 'passages blocks cross-user select');
select is((select count(*)::integer from public.link_decisions where id = 'b9999999-9999-4999-8999-999999999999'), 0, 'link_decisions blocks cross-user select');
select is((select count(*)::integer from public.narrative_memory where volume_id = 'b1111111-1111-4111-8111-111111111111'), 0, 'narrative_memory blocks cross-user select');
select is((select count(*)::integer from public.progress_events where id = 'baaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'), 0, 'progress_events blocks cross-user select');
select is((select count(*)::integer from public.jobs where id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'), 0, 'jobs blocks cross-user select');
select is((select count(*)::integer from public.generation_runs where id = 'bccccccc-cccc-4ccc-8ccc-cccccccccccc'), 0, 'generation_runs blocks client select');

-- INSERT: user A cannot create rows owned by, or below parents owned by, user B.
select throws_ok($$insert into public.volumes (id, user_id, vol_no, status) values ('c1111111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 3, 'completed')$$, '42501', 'new row violates row-level security policy for table "volumes"', 'volumes blocks cross-user insert');
select throws_ok($$insert into public.dreams (id, user_id, volume_id, input_mode, raw_text) values ('c2222222-2222-4222-8222-222222222222', '11111111-1111-4111-8111-111111111111', 'b1111111-1111-4111-8111-111111111111', 'text', 'RLS fixture')$$, '42501', 'new row violates row-level security policy for table "dreams"', 'dreams blocks inserts below another user volume');
select throws_ok($$insert into public.dream_elements (id, dream_id, type, label, salience, source) values ('c3333333-3333-4333-8333-333333333333', 'b3333333-3333-4333-8333-333333333333', 'object', 'fixture element', 'mid', 'raw')$$, '42501', 'new row violates row-level security policy for table "dream_elements"', 'dream_elements blocks cross-user insert');
select throws_ok($$insert into public.entities (id, volume_id, type, role_name) values ('c4444444-4444-4444-8444-444444444444', 'b1111111-1111-4111-8111-111111111111', 'person', 'insert fixture role')$$, '42501', 'new row violates row-level security policy for table "entities"', 'entities blocks cross-user insert');
select throws_ok($$insert into public.entity_mentions (id, entity_id, scene_id) values ('c7777777-7777-4777-8777-777777777777', 'b7777777-7777-4777-8777-777777777777', 'b5555555-5555-4555-8555-555555555555')$$, '42501', 'new row violates row-level security policy for table "entity_mentions"', 'entity_mentions blocks cross-user insert');
select throws_ok($$insert into public.scenes (id, volume_id, order_key, kind, placement) values ('c5555555-5555-4555-8555-555555555555', 'b1111111-1111-4111-8111-111111111111', 'a1', 'dream', 'continuation')$$, '42501', 'new row violates row-level security policy for table "scenes"', 'scenes blocks cross-user insert');
select throws_ok($$insert into public.passages (id, user_id, scene_id, order_key, text, origin, locked, created_by) values ('c6666666-6666-4666-8666-666666666666', '11111111-1111-4111-8111-111111111111', 'b5555555-5555-4555-8555-555555555555', 'a1', 'RLS fixture', 'C', false, 'engine')$$, '42501', 'new row violates row-level security policy for table "passages"', 'passages blocks inserts below another user scene');
select throws_ok($$insert into public.link_decisions (id, volume_id, dream_id, kind, payload, status) values ('c8888888-8888-4888-8888-888888888888', 'b1111111-1111-4111-8111-111111111111', 'b3333333-3333-4333-8333-333333333333', 'entity_merge', '{"element_id":"insert-fixture"}', 'pending')$$, '42501', 'new row violates row-level security policy for table "link_decisions"', 'link_decisions blocks cross-user insert');
select throws_ok($$insert into public.narrative_memory (volume_id, story_so_far) values ('b2222222-2222-4222-8222-222222222222', 'RLS fixture')$$, '42501', 'new row violates row-level security policy for table "narrative_memory"', 'narrative_memory blocks cross-user insert');
select throws_ok($$insert into public.progress_events (id, user_id, volume_id, dream_id, delta_mu) values ('c9999999-9999-4999-8999-999999999999', '11111111-1111-4111-8111-111111111111', 'b1111111-1111-4111-8111-111111111111', 'b3333333-3333-4333-8333-333333333333', 1)$$, '42501', 'new row violates row-level security policy for table "progress_events"', 'progress_events blocks inserts below another user volume');
select throws_ok($$insert into public.jobs (id, user_id, dream_id, volume_id, type, idempotency_key) values ('caaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'b3333333-3333-4333-8333-333333333333', 'b1111111-1111-4111-8111-111111111111', 'link', 'ceeeeeee-eeee-4eee-8eee-eeeeeeeeeeee')$$, '42501', 'new row violates row-level security policy for table "jobs"', 'jobs blocks inserts below another user volume');
select throws_ok($$insert into public.generation_runs (id, job_id, stage, model, prompt_version) values ('cbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'extract', 'fixture-model', 'fixture-v1')$$, '42501', 'new row violates row-level security policy for table "generation_runs"', 'generation_runs blocks client insert');

-- UPDATE: hidden rows are never affected.
select is_empty($$update public.volumes set title = 'blocked' where id = 'b1111111-1111-4111-8111-111111111111' returning 1$$, 'volumes blocks cross-user update');
select is_empty($$update public.dreams set status = 'archived_only' where id = 'b3333333-3333-4333-8333-333333333333' returning 1$$, 'dreams blocks cross-user update');
select is_empty($$update public.dream_elements set label = 'blocked' where id = 'b4444444-4444-4444-8444-444444444444' returning 1$$, 'dream_elements blocks cross-user update');
select is_empty($$update public.entities set description = 'blocked' where id = 'b7777777-7777-4777-8777-777777777777' returning 1$$, 'entities blocks cross-user update');
select is_empty($$update public.entity_mentions set created_at = now() where id = 'b8888888-8888-4888-8888-888888888888' returning 1$$, 'entity_mentions blocks cross-user update');
select is_empty($$update public.scenes set title = 'blocked' where id = 'b5555555-5555-4555-8555-555555555555' returning 1$$, 'scenes blocks cross-user update');
select is_empty($$update public.passages set text = 'blocked' where id = 'b6666666-6666-4666-8666-666666666666' returning 1$$, 'passages blocks cross-user update');
select is_empty($$update public.link_decisions set status = 'unsure' where id = 'b9999999-9999-4999-8999-999999999999' returning 1$$, 'link_decisions blocks cross-user update');
select is_empty($$update public.narrative_memory set version = version + 1 where volume_id = 'b1111111-1111-4111-8111-111111111111' returning 1$$, 'narrative_memory blocks cross-user update');
select is_empty($$update public.progress_events set delta_mu = 2 where id = 'baaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' returning 1$$, 'progress_events blocks cross-user update');
select is_empty($$update public.jobs set error = 'blocked' where id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' returning 1$$, 'jobs blocks cross-user update');
select is_empty($$update public.generation_runs set model = 'blocked' where id = 'bccccccc-cccc-4ccc-8ccc-cccccccccccc' returning 1$$, 'generation_runs blocks client update');

-- DELETE: child-first order keeps later assertions independent if a policy regresses.
select is_empty($$delete from public.generation_runs where id = 'bccccccc-cccc-4ccc-8ccc-cccccccccccc' returning 1$$, 'generation_runs blocks client delete');
select is_empty($$delete from public.entity_mentions where id = 'b8888888-8888-4888-8888-888888888888' returning 1$$, 'entity_mentions blocks cross-user delete');
select is_empty($$delete from public.link_decisions where id = 'b9999999-9999-4999-8999-999999999999' returning 1$$, 'link_decisions blocks cross-user delete');
select is_empty($$delete from public.narrative_memory where volume_id = 'b1111111-1111-4111-8111-111111111111' returning 1$$, 'narrative_memory blocks cross-user delete');
select is_empty($$delete from public.passages where id = 'b6666666-6666-4666-8666-666666666666' returning 1$$, 'passages blocks cross-user delete');
select is_empty($$delete from public.dream_elements where id = 'b4444444-4444-4444-8444-444444444444' returning 1$$, 'dream_elements blocks cross-user delete');
select is_empty($$delete from public.entities where id = 'b7777777-7777-4777-8777-777777777777' returning 1$$, 'entities blocks cross-user delete');
select is_empty($$delete from public.scenes where id = 'b5555555-5555-4555-8555-555555555555' returning 1$$, 'scenes blocks cross-user delete');
select is_empty($$delete from public.progress_events where id = 'baaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' returning 1$$, 'progress_events blocks cross-user delete');
select is_empty($$delete from public.jobs where id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' returning 1$$, 'jobs blocks cross-user delete');
select is_empty($$delete from public.dreams where id = 'b3333333-3333-4333-8333-333333333333' returning 1$$, 'dreams blocks cross-user delete');
select is_empty($$delete from public.volumes where id = 'b1111111-1111-4111-8111-111111111111' returning 1$$, 'volumes blocks cross-user delete');

select * from finish();

reset role;
rollback;

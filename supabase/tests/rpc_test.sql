begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(55);

select ok(
  has_function_privilege('authenticated', 'public.user_edit_passage(uuid,text)', 'EXECUTE')
  and not has_function_privilege('anon', 'public.user_edit_passage(uuid,text)', 'EXECUTE')
  and not has_function_privilege('service_role', 'public.user_edit_passage(uuid,text)', 'EXECUTE'),
  'only authenticated users can call user_edit_passage'
);
select ok(
  has_function_privilege('service_role', 'public.commit_scene(uuid,uuid,jsonb)', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.commit_scene(uuid,uuid,jsonb)', 'EXECUTE')
  and not has_function_privilege('anon', 'public.commit_scene(uuid,uuid,jsonb)', 'EXECUTE'),
  'commit_scene is service-role only'
);
select ok(
  has_function_privilege('service_role', 'public.recompute_progress(uuid)', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.recompute_progress(uuid)', 'EXECUTE')
  and not has_function_privilege('anon', 'public.recompute_progress(uuid)', 'EXECUTE'),
  'recompute_progress is service-role only'
);
select ok(
  has_function_privilege('service_role', 'public.claim_job()', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.claim_job()', 'EXECUTE')
  and not has_function_privilege('anon', 'public.claim_job()', 'EXECUTE'),
  'claim_job is service-role only'
);
select ok(
  has_function_privilege('service_role', 'public.reap_zombie_jobs()', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.reap_zombie_jobs()', 'EXECUTE')
  and not has_function_privilege('anon', 'public.reap_zombie_jobs()', 'EXECUTE'),
  'reap_zombie_jobs is service-role only'
);
select ok(
  has_function_privilege('service_role', 'public.delete_user_data(uuid)', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.delete_user_data(uuid)', 'EXECUTE')
  and not has_function_privilege('anon', 'public.delete_user_data(uuid)', 'EXECUTE'),
  'delete_user_data is service-role only'
);
select ok(
  not has_function_privilege('service_role', 'public.guard_locked_passage()', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.guard_locked_passage()', 'EXECUTE')
  and not has_function_privilege('anon', 'public.guard_locked_passage()', 'EXECUTE'),
  'the trigger helper is not directly callable by API roles'
);

-- commit_scene fixture: partial clarity (2 MU) + three valid recall answers (0.75 MU).
insert into public.volumes (
  id,
  user_id,
  vol_no,
  format,
  status,
  target_mu,
  progress_mu
)
values (
  'd1111111-1111-4111-8111-111111111111',
  '11111111-1111-4111-8111-111111111111',
  2,
  'short',
  'completed',
  20,
  0
);

insert into public.dreams (
  id,
  user_id,
  volume_id,
  input_mode,
  raw_text,
  recall_answers,
  status
)
values
  (
    'd2222222-2222-4222-8222-222222222222',
    '11111111-1111-4111-8111-111111111111',
    'd1111111-1111-4111-8111-111111111111',
    'text',
    'RPC fixture',
    '{"light":"dark","object":"key","sound":"wind","unknown":"모름"}'::jsonb,
    'processing'
  ),
  (
    'd6666666-6666-4666-8666-666666666666',
    '11111111-1111-4111-8111-111111111111',
    'd1111111-1111-4111-8111-111111111111',
    'text',
    'rollback fixture',
    '{}'::jsonb,
    'processing'
  );

insert into public.dream_elements (
  id,
  dream_id,
  type,
  label,
  salience,
  source
)
values
  (
    'd3333333-3333-4333-8333-333333333333',
    'd2222222-2222-4222-8222-222222222222',
    'object',
    'commit fixture',
    'high',
    'raw'
  ),
  (
    'd7777777-7777-4777-8777-777777777777',
    'd6666666-6666-4666-8666-666666666666',
    'object',
    'rollback fixture',
    'high',
    'raw'
  );

create temporary table commit_results (scene_id uuid not null);

insert into commit_results
select public.commit_scene(
  'd2222222-2222-4222-8222-222222222222',
  'd1111111-1111-4111-8111-111111111111',
  $payload$
  {
    "clarity": "partial",
    "scene": {
      "id": "d4444444-4444-4444-8444-444444444444",
      "order_key": "b0",
      "kind": "dream",
      "placement": "continuation",
      "title": "Commit fixture",
      "open_image": "Open fixture"
    },
    "passages": [
      {
        "id": "d5555555-5555-4555-8555-555555555551",
        "order_key": "a0",
        "origin": "D",
        "text": "Derived fixture",
        "source_element_ids": ["d3333333-3333-4333-8333-333333333333"]
      },
      {
        "id": "d5555555-5555-4555-8555-555555555552",
        "order_key": "a1",
        "origin": "C",
        "text": "Connection fixture",
        "c_reason": "test transition"
      }
    ],
    "new_entities": [
      {
        "type": "person",
        "role_name": "fixture role",
        "from_element": "d3333333-3333-4333-8333-333333333333"
      }
    ],
    "used_entities": []
  }
  $payload$::jsonb
);

insert into commit_results
select public.commit_scene(
  'd2222222-2222-4222-8222-222222222222',
  'd1111111-1111-4111-8111-111111111111',
  $payload$
  {
    "clarity": "partial",
    "scene": {
      "id": "d4444444-4444-4444-8444-444444444444",
      "order_key": "b0",
      "kind": "dream",
      "placement": "continuation"
    },
    "passages": [
      {
        "origin": "D",
        "text": "Retry fixture",
        "source_element_ids": ["d3333333-3333-4333-8333-333333333333"]
      }
    ]
  }
  $payload$::jsonb
);

select is((select count(distinct scene_id)::integer from commit_results), 1, 'commit_scene returns the same scene for a retry');
select is((select count(*)::integer from public.scenes where id = 'd4444444-4444-4444-8444-444444444444'), 1, 'commit_scene creates one scene');
select is((select count(*)::integer from public.passages where scene_id = 'd4444444-4444-4444-8444-444444444444'), 2, 'commit_scene creates the payload passages once');
select is((select count(*)::integer from public.progress_events where dream_id = 'd2222222-2222-4222-8222-222222222222'), 1, 'commit_scene creates one progress event');
select is((select delta_mu from public.progress_events where dream_id = 'd2222222-2222-4222-8222-222222222222'), 2.75::numeric, 'commit_scene calculates clarity and recall MU');
select is((select progress_mu from public.volumes where id = 'd1111111-1111-4111-8111-111111111111'), 2.75::numeric, 'commit_scene increments cached volume progress');
select is((select clarity::text from public.dreams where id = 'd2222222-2222-4222-8222-222222222222'), 'partial', 'commit_scene stores clarity');
select is((select status::text from public.dreams where id = 'd2222222-2222-4222-8222-222222222222'), 'in_manuscript', 'commit_scene advances dream status');
select is((select cardinality(source_element_ids) from public.passages where id = 'd5555555-5555-4555-8555-555555555551'), 1, 'commit_scene preserves D provenance');
select is((select count(*)::integer from public.entity_mentions em join public.entities e on e.id = em.entity_id where e.volume_id = 'd1111111-1111-4111-8111-111111111111'), 1, 'commit_scene records the new entity mention');

select throws_ok(
  $commit$
    select public.commit_scene(
      'd6666666-6666-4666-8666-666666666666',
      'd1111111-1111-4111-8111-111111111111',
      $json$
      {
        "clarity": "fragment",
        "scene": {
          "id": "d8888888-8888-4888-8888-888888888888",
          "order_key": "b1",
          "placement": "continuation"
        },
        "passages": [
          {
            "id": "d9999999-9999-4999-8999-999999999999",
            "origin": "D",
            "text": "Valid first fixture",
            "source_element_ids": ["d7777777-7777-4777-8777-777777777777"]
          },
          {
            "origin": "U",
            "text": "Rejected fixture"
          }
        ]
      }
      $json$::jsonb
    )
  $commit$,
  '22023',
  'commit_scene does not accept user passages',
  'commit_scene rejects U passages from the engine payload'
);

select is((select count(*)::integer from public.scenes where id = 'd8888888-8888-4888-8888-888888888888'), 0, 'failed commit rolls back its scene');
select is((select count(*)::integer from public.passages where id = 'd9999999-9999-4999-8999-999999999999'), 0, 'failed commit rolls back earlier passages');
select is((select count(*)::integer from public.progress_events where dream_id = 'd6666666-6666-4666-8666-666666666666'), 0, 'failed commit does not add progress');
select is((select status::text from public.dreams where id = 'd6666666-6666-4666-8666-666666666666'), 'processing', 'failed commit leaves dream status unchanged');

select throws_ok(
  $$update public.passages set text = 'blocked' where id = '66666666-6666-4666-8666-666666666666'$$,
  '55000',
  'locked passage cannot be modified outside user_edit_passage',
  'locked U passage blocks direct update'
);

select throws_ok(
  $$delete from public.passages where id = '66666666-6666-4666-8666-666666666666'$$,
  '55000',
  'locked passage cannot be modified outside user_edit_passage',
  'locked U passage blocks direct delete'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$select public.user_edit_passage('66666666-6666-4666-8666-666666666661', 'User revision fixture')$$,
  'user_edit_passage updates an owned passage'
);
select is((select origin::text from public.passages where id = '66666666-6666-4666-8666-666666666661'), 'U', 'user edit changes origin to U');
select ok((select locked from public.passages where id = '66666666-6666-4666-8666-666666666661'), 'user edit locks the passage');
select ok((select original_text is not null from public.passages where id = '66666666-6666-4666-8666-666666666661'), 'user edit preserves the previous text');
select is((select text from public.passages where id = '66666666-6666-4666-8666-666666666661'), 'User revision fixture', 'user edit stores the new text');
select throws_ok(
  $$update public.passages set text = 'blocked again' where id = '66666666-6666-4666-8666-666666666661'$$,
  '55000',
  'locked passage cannot be modified outside user_edit_passage',
  'user edit permission is reset immediately after the RPC'
);

reset role;

insert into public.progress_events (
  user_id,
  volume_id,
  dream_id,
  delta_mu,
  reasons
)
values (
  '11111111-1111-4111-8111-111111111111',
  'd1111111-1111-4111-8111-111111111111',
  'd2222222-2222-4222-8222-222222222222',
  1.25,
  '[]'::jsonb
);
update public.volumes
   set progress_mu = 99
 where id = 'd1111111-1111-4111-8111-111111111111';

select is(public.recompute_progress('d1111111-1111-4111-8111-111111111111'), 4.00::numeric, 'recompute_progress returns the event sum');
select is((select progress_mu from public.volumes where id = 'd1111111-1111-4111-8111-111111111111'), 4.00::numeric, 'recompute_progress repairs cached progress');

insert into public.jobs (
  id,
  user_id,
  dream_id,
  volume_id,
  type,
  idempotency_key,
  created_at
)
values
  (
    'daaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '11111111-1111-4111-8111-111111111111',
    'd2222222-2222-4222-8222-222222222222',
    'd1111111-1111-4111-8111-111111111111',
    'link',
    'dcaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    now() - interval '2 seconds'
  ),
  (
    'dbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    '11111111-1111-4111-8111-111111111111',
    'd2222222-2222-4222-8222-222222222222',
    'd1111111-1111-4111-8111-111111111111',
    'plan',
    'dcbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    now() - interval '1 second'
  );

create temporary table claimed_jobs (id uuid);
insert into claimed_jobs select (public.claim_job()).id;
insert into claimed_jobs select (public.claim_job()).id;

select is((select count(distinct id)::integer from claimed_jobs), 2, 'two claims return different jobs');
select is((select count(*)::integer from public.jobs where id in (select id from claimed_jobs) and status = 'running'), 2, 'claimed jobs move to running');
select is((select sum(attempt)::integer from public.jobs where id in (select id from claimed_jobs)), 2, 'claim_job increments each attempt once');
select is((public.claim_job()).id, null::uuid, 'claim_job returns null when the queue is empty');

update public.jobs
   set updated_at = now() - interval '6 minutes'
 where id = 'daaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

select is(public.reap_zombie_jobs(), 1, 'reap_zombie_jobs finds stale running work');
select is((select status::text from public.jobs where id = 'daaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'), 'queued', 'reap_zombie_jobs returns retryable work to the queue');
select is((select count(*)::integer from cron.job where jobname = 'reap-zombies'), 1, 'zombie reaper is scheduled once per minute');

-- Account deletion fixture includes every public ownership path and a locked U passage.
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
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
  'authenticated',
  'authenticated',
  'delete-fixture@mumumong.local',
  '',
  '',
  '',
  '',
  '{}'::jsonb,
  '{}'::jsonb,
  now(),
  now()
);

insert into public.volumes (id, user_id, vol_no, status)
values ('e1111111-1111-4111-8111-111111111111', 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 1, 'active');
insert into public.dreams (id, user_id, volume_id, input_mode, raw_text)
values ('e2222222-2222-4222-8222-222222222222', 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'e1111111-1111-4111-8111-111111111111', 'text', 'delete fixture');
insert into public.dream_elements (id, dream_id, type, label, salience, source)
values ('e3333333-3333-4333-8333-333333333333', 'e2222222-2222-4222-8222-222222222222', 'object', 'delete fixture', 'high', 'raw');
insert into public.scenes (id, volume_id, order_key, kind, placement)
values ('e4444444-4444-4444-8444-444444444444', 'e1111111-1111-4111-8111-111111111111', 'a0', 'dream', 'continuation');
insert into public.passages (id, user_id, scene_id, order_key, text, origin, locked, created_by)
values ('e5555555-5555-4555-8555-555555555555', 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'e4444444-4444-4444-8444-444444444444', 'a0', 'delete fixture', 'U', true, 'user');
insert into public.entities (id, volume_id, type, role_name)
values ('e6666666-6666-4666-8666-666666666666', 'e1111111-1111-4111-8111-111111111111', 'person', 'delete fixture');
insert into public.entity_mentions (id, entity_id, dream_element_id, scene_id, passage_id)
values ('e7777777-7777-4777-8777-777777777777', 'e6666666-6666-4666-8666-666666666666', 'e3333333-3333-4333-8333-333333333333', 'e4444444-4444-4444-8444-444444444444', 'e5555555-5555-4555-8555-555555555555');
insert into public.link_decisions (id, volume_id, dream_id, kind, payload, status)
values ('e8888888-8888-4888-8888-888888888888', 'e1111111-1111-4111-8111-111111111111', 'e2222222-2222-4222-8222-222222222222', 'entity_merge', '{"element_id":"delete-fixture"}', 'pending');
insert into public.narrative_memory (volume_id, story_so_far)
values ('e1111111-1111-4111-8111-111111111111', 'delete fixture');
insert into public.progress_events (id, user_id, volume_id, dream_id, delta_mu)
values ('e9999999-9999-4999-8999-999999999999', 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'e1111111-1111-4111-8111-111111111111', 'e2222222-2222-4222-8222-222222222222', 1);
insert into public.jobs (id, user_id, dream_id, volume_id, type, idempotency_key)
values ('eaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'e2222222-2222-4222-8222-222222222222', 'e1111111-1111-4111-8111-111111111111', 'extract', 'ecaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
insert into public.generation_runs (id, job_id, stage, model, prompt_version)
values ('ebbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'eaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'extract', 'fixture-model', 'fixture-v1');

select lives_ok(
  $$select public.delete_user_data('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee')$$,
  'delete_user_data removes a complete user graph including locked passages'
);
select is((select count(*)::integer from public.volumes where user_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'), 0, 'delete_user_data removes volumes');
select is((select count(*)::integer from public.dreams where user_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'), 0, 'delete_user_data removes dreams');
select is((select count(*)::integer from public.dream_elements where id = 'e3333333-3333-4333-8333-333333333333'), 0, 'delete_user_data removes dream elements');
select is((select count(*)::integer from public.entities where id = 'e6666666-6666-4666-8666-666666666666'), 0, 'delete_user_data removes entities');
select is((select count(*)::integer from public.entity_mentions where id = 'e7777777-7777-4777-8777-777777777777'), 0, 'delete_user_data removes entity mentions');
select is((select count(*)::integer from public.scenes where id = 'e4444444-4444-4444-8444-444444444444'), 0, 'delete_user_data removes scenes');
select is((select count(*)::integer from public.passages where user_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'), 0, 'delete_user_data removes passages');
select is((select count(*)::integer from public.link_decisions where id = 'e8888888-8888-4888-8888-888888888888'), 0, 'delete_user_data removes link decisions');
select is((select count(*)::integer from public.narrative_memory where volume_id = 'e1111111-1111-4111-8111-111111111111'), 0, 'delete_user_data removes narrative memory');
select is((select count(*)::integer from public.progress_events where user_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'), 0, 'delete_user_data removes progress events');
select is((select count(*)::integer from public.jobs where user_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'), 0, 'delete_user_data removes jobs');
select is((select count(*)::integer from public.generation_runs where id = 'ebbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'), 0, 'delete_user_data removes generation runs');
select is((select count(*)::integer from auth.users where id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'), 1, 'delete_user_data leaves Auth deletion to the admin API');

-- A short volume becomes completable only after both MU and narrative gates pass.
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
  'ffffffff-ffff-4fff-8fff-ffffffffffff',
  'authenticated',
  'authenticated',
  'completion-fixture@mumumong.local',
  '',
  '',
  '',
  '',
  '{}'::jsonb,
  '{}'::jsonb,
  now(),
  now()
);
insert into public.volumes (id, user_id, vol_no, format, status, target_mu)
values ('f1111111-1111-4111-8111-111111111111', 'ffffffff-ffff-4fff-8fff-ffffffffffff', 1, 'short', 'active', 1);
insert into public.dreams (id, user_id, volume_id, input_mode, raw_text, clarity, status)
values ('f2222222-2222-4222-8222-222222222222', 'ffffffff-ffff-4fff-8fff-ffffffffffff', 'f1111111-1111-4111-8111-111111111111', 'text', 'completion fixture', 'fragment', 'processing');
insert into public.dream_elements (id, dream_id, type, label, salience, source)
values ('f3333333-3333-4333-8333-333333333333', 'f2222222-2222-4222-8222-222222222222', 'object', 'completion fixture', 'high', 'raw');
insert into public.scenes (id, volume_id, order_key, kind, placement)
values
  ('f4444444-4444-4444-8444-444444444441', 'f1111111-1111-4111-8111-111111111111', 'c0', 'dream', 'continuation'),
  ('f4444444-4444-4444-8444-444444444442', 'f1111111-1111-4111-8111-111111111111', 'c1', 'dream', 'continuation'),
  ('f4444444-4444-4444-8444-444444444443', 'f1111111-1111-4111-8111-111111111111', 'c2', 'dream', 'continuation'),
  ('f4444444-4444-4444-8444-444444444444', 'f1111111-1111-4111-8111-111111111111', 'c3', 'dream', 'continuation');
insert into public.entities (id, volume_id, type, role_name, mention_count)
values ('f6666666-6666-4666-8666-666666666666', 'f1111111-1111-4111-8111-111111111111', 'person', 'repeated fixture', 1);

select public.commit_scene(
  'f2222222-2222-4222-8222-222222222222',
  'f1111111-1111-4111-8111-111111111111',
  $payload$
  {
    "clarity": "fragment",
    "scene": {
      "id": "f5555555-5555-4555-8555-555555555555",
      "order_key": "c4",
      "placement": "continuation"
    },
    "passages": [
      {
        "id": "f7777777-7777-4777-8777-777777777777",
        "origin": "D",
        "text": "Completion fixture",
        "source_element_ids": ["f3333333-3333-4333-8333-333333333333"]
      }
    ],
    "used_entities": ["f6666666-6666-4666-8666-666666666666"]
  }
  $payload$::jsonb
);

select is((select count(*)::integer from public.scenes where volume_id = 'f1111111-1111-4111-8111-111111111111'), 5, 'commit_scene evaluates the completed scene count');
select is((select status::text from public.volumes where id = 'f1111111-1111-4111-8111-111111111111'), 'completable', 'commit_scene advances a volume after MU and narrative gates pass');

select * from finish();

rollback;

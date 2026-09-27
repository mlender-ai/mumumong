begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(8);

select ok(
  has_function_privilege('authenticated', 'public.user_upsert_dream(jsonb)', 'EXECUTE')
  and not has_function_privilege('anon', 'public.user_upsert_dream(jsonb)', 'EXECUTE')
  and not has_function_privilege('service_role', 'public.user_upsert_dream(jsonb)', 'EXECUTE'),
  'only authenticated users can upsert their dream input'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$select public.user_upsert_dream('{
    "id":"3ddddddd-dddd-4ddd-8ddd-dddddddddddd",
    "volume_id":"22222222-2222-4222-8222-222222222222",
    "dream_date":"2026-09-27",
    "recorded_at":"2026-09-27T01:00:00Z",
    "input_mode":"text",
    "raw_text":"first client text",
    "recall_answers":{},
    "status":"processing",
    "is_backfill":false
  }'::jsonb)$$,
  'the owner can insert a new client-authored dream'
);
select is(
  (select status::text from public.dreams where id = '3ddddddd-dddd-4ddd-8ddd-dddddddddddd'),
  'processing',
  'a new processing dream keeps its initial client state'
);

reset role;
update public.dreams
   set status = 'in_manuscript',
       clarity = 'vivid',
       sensitive_flags = array['fixture']::text[]
 where id = '3ddddddd-dddd-4ddd-8ddd-dddddddddddd';

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select lives_ok(
  $$select public.user_upsert_dream('{
    "id":"3ddddddd-dddd-4ddd-8ddd-dddddddddddd",
    "volume_id":"22222222-2222-4222-8222-222222222222",
    "dream_date":"2026-09-27",
    "recorded_at":"2026-09-27T01:00:00Z",
    "input_mode":"text",
    "raw_text":"newer client text",
    "recall_answers":{"light":"dark"},
    "status":"processing",
    "is_backfill":false
  }'::jsonb)$$,
  'a stale client retry can refresh client-authored fields'
);
select is(
  (select status::text from public.dreams where id = '3ddddddd-dddd-4ddd-8ddd-dddddddddddd'),
  'in_manuscript',
  'a stale retry cannot downgrade a completed server status'
);
select is(
  (select clarity::text from public.dreams where id = '3ddddddd-dddd-4ddd-8ddd-dddddddddddd'),
  'vivid',
  'a stale retry cannot overwrite server clarity'
);
select is(
  (select sensitive_flags from public.dreams where id = '3ddddddd-dddd-4ddd-8ddd-dddddddddddd'),
  array['fixture']::text[],
  'a stale retry cannot overwrite server safety flags'
);
select is(
  (select raw_text from public.dreams where id = '3ddddddd-dddd-4ddd-8ddd-dddddddddddd'),
  'newer client text',
  'client-authored dream text still synchronizes'
);

select * from finish();
rollback;

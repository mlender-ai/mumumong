begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select plan(16);

select is((select version from public.ai_consent_policy where id = 1), 1,
  'consent policy is data-backed and versioned');
select ok(
  has_function_privilege('authenticated', 'public.accept_ai_consent(integer,boolean)', 'EXECUTE')
  and not has_function_privilege('anon', 'public.accept_ai_consent(integer,boolean)', 'EXECUTE')
  and not has_function_privilege('service_role', 'public.accept_ai_consent(integer,boolean)', 'EXECUTE'),
  'only authenticated users can record AI consent'
);
select ok(
  has_table_privilege('anon', 'public.ai_consent_policy', 'SELECT')
  and not has_table_privilege('anon', 'public.ai_consent_policy', 'UPDATE')
  and not has_table_privilege('authenticated', 'public.profiles', 'UPDATE'),
  'policy is readable but clients cannot rewrite consent records'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select is(public.user_has_current_ai_consent(), false,
  'missing consent fails closed');
select throws_ok(
  $$select public.accept_ai_consent(1, false)$$,
  '22023', 'age confirmation required',
  'under-14 or unchecked age declaration is rejected'
);
select throws_ok(
  $$select public.accept_ai_consent(99, true)$$,
  '22023', 'current consent version required',
  'stale or invented policy version cannot be accepted'
);
select throws_ok(
  $$insert into public.jobs (id, user_id, volume_id, type, idempotency_key)
    values ('a1515151-1515-4151-8151-151515151515',
      '11111111-1111-4111-8111-111111111111',
      '22222222-2222-4222-8222-222222222222', 'extract',
      'b1515151-1515-4151-8151-151515151515')$$,
  '42501', 'new row violates row-level security policy for table "jobs"',
  'client cannot enqueue without current consent'
);
select is(public.accept_ai_consent(1, true), true,
  'authenticated user records the current policy and age declaration');
select is(public.user_has_current_ai_consent(), true,
  'current consent is visible to the owner');
select is((select consent_version from public.profiles
  where user_id = '11111111-1111-4111-8111-111111111111'), 1,
  'profile stores the accepted version');
select lives_ok(
  $$insert into public.jobs (id, user_id, volume_id, type, idempotency_key)
    values ('a1515151-1515-4151-8151-151515151515',
      '11111111-1111-4111-8111-111111111111',
      '22222222-2222-4222-8222-222222222222', 'extract',
      'b1515151-1515-4151-8151-151515151515')$$,
  'current consent permits the owner to enqueue'
);

reset role;
update public.ai_consent_policy set version = 2 where id = 1;
select is((public.claim_job_for_user('11111111-1111-4111-8111-111111111111')).id,
  null::uuid, 'worker cannot claim pre-existing queued work after policy version changes');

set local role authenticated;
select is(public.user_has_current_ai_consent(), false,
  'version change revokes current status until renewed');
select throws_ok(
  $$insert into public.jobs (id, user_id, volume_id, type, idempotency_key)
    values ('a1616161-1616-4161-8161-161616161616',
      '11111111-1111-4111-8111-111111111111',
      '22222222-2222-4222-8222-222222222222', 'extract',
      'b1616161-1616-4161-8161-161616161616')$$,
  '42501', 'new row violates row-level security policy for table "jobs"',
  'old consent does not authorize new jobs'
);
select is(public.accept_ai_consent(2, true), true,
  'user can explicitly accept the new policy version');
reset role;
select is((public.claim_job_for_user('11111111-1111-4111-8111-111111111111')).id,
  'a1515151-1515-4151-8151-151515151515'::uuid,
  'worker resumes an existing job after renewed consent');

select * from finish();
rollback;

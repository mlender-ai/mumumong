begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select plan(5);

select has_column('public', 'generation_runs', 'engine_version', 'engine version column exists');
select col_not_null('public', 'generation_runs', 'engine_version', 'engine version is required');
select col_default_is('public', 'generation_runs', 'engine_version', 'v10', 'engine version defaults to v10');

insert into auth.users (id, aud, role, email)
values ('a1414141-1414-4141-8141-141414141414', 'authenticated', 'authenticated', 'engine-version@example.test');
insert into public.volumes (id, user_id, vol_no)
values ('b1414141-1414-4141-8141-141414141414', 'a1414141-1414-4141-8141-141414141414', 1);

insert into public.jobs (id, user_id, volume_id, type, idempotency_key)
values (
  'd1414141-1414-4141-8141-141414141414',
  'a1414141-1414-4141-8141-141414141414',
  'b1414141-1414-4141-8141-141414141414',
  'write',
  'd1414141-1414-4141-8141-141414141415'
);
insert into public.generation_runs (job_id, stage, model, prompt_version)
values ('d1414141-1414-4141-8141-141414141414', 'write', 'synthetic-model', 'fixture-v1');
select is(
  (select engine_version from public.generation_runs where job_id = 'd1414141-1414-4141-8141-141414141414'),
  'v10', 'omitted engine version uses the frozen baseline'
);
update public.generation_runs set engine_version = 'v11'
where job_id = 'd1414141-1414-4141-8141-141414141414';
select is(
  (select engine_version from public.generation_runs where job_id = 'd1414141-1414-4141-8141-141414141414'),
  'v11', 'future candidate runs can record a distinct engine version'
);
select * from finish();
rollback;

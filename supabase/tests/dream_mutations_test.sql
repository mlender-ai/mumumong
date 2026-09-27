begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(13);

select ok(
  has_function_privilege('authenticated', 'public.user_remove_dream_from_manuscript(uuid)', 'EXECUTE')
  and not has_function_privilege('anon', 'public.user_remove_dream_from_manuscript(uuid)', 'EXECUTE')
  and not has_function_privilege('service_role', 'public.user_remove_dream_from_manuscript(uuid)', 'EXECUTE'),
  'only authenticated users can remove a dream from the manuscript'
);
select ok(
  has_function_privilege('authenticated', 'public.user_delete_dream(uuid,boolean)', 'EXECUTE')
  and not has_function_privilege('anon', 'public.user_delete_dream(uuid,boolean)', 'EXECUTE')
  and not has_function_privilege('service_role', 'public.user_delete_dream(uuid,boolean)', 'EXECUTE'),
  'only authenticated users can delete a dream'
);

insert into public.dreams (
  id, user_id, volume_id, input_mode, raw_text, clarity, status
) values (
  '38888888-8888-4888-8888-888888888888',
  '11111111-1111-4111-8111-111111111111',
  '22222222-2222-4222-8222-222222222222',
  'text',
  'remove fixture',
  'fragment',
  'in_manuscript'
);
insert into public.dream_elements (id, dream_id, type, label, salience, source)
values (
  '48888888-8888-4888-8888-888888888888',
  '38888888-8888-4888-8888-888888888888',
  'object',
  'fixture',
  'high',
  'raw'
);
insert into public.scenes (
  id, volume_id, order_key, kind, placement, source_dream_ids
) values (
  '58888888-8888-4888-8888-888888888888',
  '22222222-2222-4222-8222-222222222222',
  'z8',
  'dream',
  'continuation',
  array['38888888-8888-4888-8888-888888888888']::uuid[]
);
insert into public.passages (
  id, user_id, scene_id, order_key, text, origin, source_dream_id,
  source_element_ids, locked, created_by
) values (
  '68888888-8888-4888-8888-888888888888',
  '11111111-1111-4111-8111-111111111111',
  '58888888-8888-4888-8888-888888888888',
  'z8',
  'remove fixture passage',
  'D',
  '38888888-8888-4888-8888-888888888888',
  array['48888888-8888-4888-8888-888888888888']::uuid[],
  false,
  'engine'
);
insert into public.progress_events (
  id, user_id, volume_id, dream_id, delta_mu, reasons
) values (
  '78888888-8888-4888-8888-888888888888',
  '11111111-1111-4111-8111-111111111111',
  '22222222-2222-4222-8222-222222222222',
  '38888888-8888-4888-8888-888888888888',
  1,
  '[]'::jsonb
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select ok(
  public.user_remove_dream_from_manuscript('38888888-8888-4888-8888-888888888888'),
  'an owner can remove a dream-derived scene'
);
select is(
  (select status::text from public.dreams where id = '38888888-8888-4888-8888-888888888888'),
  'archived_only',
  'removed dream remains archived'
);
select is(
  (select count(*)::integer from public.scenes where id = '58888888-8888-4888-8888-888888888888'),
  0,
  'removal deletes the derived scene'
);
select is(
  (select progress_mu from public.volumes where id = '22222222-2222-4222-8222-222222222222'),
  (select greatest(0, coalesce(sum(delta_mu), 0)) from public.progress_events where volume_id = '22222222-2222-4222-8222-222222222222'),
  'removal recomputes the progress cache'
);

select ok(
  public.user_delete_dream('33333333-3333-4333-8333-333333333333', true),
  'an owner can delete a dream while keeping its scene'
);
select is(
  (select count(*)::integer from public.dreams where id = '33333333-3333-4333-8333-333333333333'),
  0,
  'dream deletion removes the source dream'
);
select is(
  (select count(*)::integer from public.scenes where id = '55555555-5555-4555-8555-555555555552'),
  1,
  'keep-derived deletion preserves the scene'
);
select ok(
  not ((
    select source_dream_ids
      from public.scenes
     where id = '55555555-5555-4555-8555-555555555552'
  ) @> array['33333333-3333-4333-8333-333333333333'::uuid]),
  'preserved scene detaches the deleted dream'
);
select is(
  (select count(*)::integer from public.passages where scene_id = '55555555-5555-4555-8555-555555555552' and origin = 'D'),
  0,
  'dream passages become connection passages'
);
select is(
  (select count(*)::integer from public.passages where id = '66666666-6666-4666-8666-666666666666' and origin = 'U' and locked),
  1,
  'locked user passage remains unchanged'
);
select is(
  (select progress_mu from public.volumes where id = '22222222-2222-4222-8222-222222222222'),
  (select greatest(0, coalesce(sum(delta_mu), 0)) from public.progress_events where volume_id = '22222222-2222-4222-8222-222222222222'),
  'deletion recomputes the progress cache'
);

select * from finish();
rollback;

begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(4);

select throws_ok(
  $$
    insert into public.passages (
      user_id, scene_id, order_key, text, origin, locked, created_by
    ) values (
      '11111111-1111-4111-8111-111111111111',
      '55555555-5555-4555-8555-555555555552',
      'testD',
      'constraint fixture',
      'D',
      false,
      'engine'
    )
  $$,
  '23514',
  'new row for relation "passages" violates check constraint "chk_d_has_source"',
  'D passages require at least one source element'
);

select throws_ok(
  $$
    insert into public.passages (
      user_id, scene_id, order_key, text, origin, locked, created_by
    ) values (
      '11111111-1111-4111-8111-111111111111',
      '55555555-5555-4555-8555-555555555552',
      'testU',
      'constraint fixture',
      'U',
      false,
      'user'
    )
  $$,
  '23514',
  'new row for relation "passages" violates check constraint "chk_u_locked"',
  'U passages must be locked'
);

select throws_ok(
  $$
    insert into public.volumes (user_id, vol_no, status)
    values (
      '11111111-1111-4111-8111-111111111111',
      99,
      'active'
    )
  $$,
  '23505',
  'duplicate key value violates unique constraint "uq_volume_active"',
  'a user cannot have a second active volume'
);

select throws_ok(
  $$
    insert into public.scenes (volume_id, order_key, kind, placement)
    values (
      '22222222-2222-4222-8222-222222222222',
      'a0',
      'dream',
      'continuation'
    )
  $$,
  '23505',
  'duplicate key value violates unique constraint "uq_scene_order"',
  'scene order keys are unique inside a volume'
);

select * from finish();

rollback;

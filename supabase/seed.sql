-- Fixed local-only account. Never reuse these credentials outside local development.
insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  email_change,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  created_at,
  updated_at
)
values (
  '00000000-0000-0000-0000-000000000000',
  '11111111-1111-4111-8111-111111111111',
  'authenticated',
  'authenticated',
  'seed@mumumong.local',
  extensions.crypt('mumumong-local-only', extensions.gen_salt('bf')),
  now(),
  '',
  '',
  '',
  '',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{}'::jsonb,
  false,
  now(),
  now()
);

insert into auth.identities (
  provider_id,
  user_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
)
values (
  '11111111-1111-4111-8111-111111111111',
  '11111111-1111-4111-8111-111111111111',
  '{"sub":"11111111-1111-4111-8111-111111111111","email":"seed@mumumong.local","email_verified":true}'::jsonb,
  'email',
  now(),
  now(),
  now()
);

insert into public.volumes (
  id,
  user_id,
  vol_no,
  title,
  format,
  adaptation,
  style,
  narrative_voice,
  status,
  target_mu,
  progress_mu,
  cover_seed
)
values (
  '22222222-2222-4222-8222-222222222222',
  '11111111-1111-4111-8111-111111111111',
  1,
  '무제의 기록',
  'novella',
  'balanced',
  'plain',
  'third_person_past',
  'active',
  80,
  6,
  1031
);

insert into public.dreams (
  id,
  user_id,
  volume_id,
  dream_date,
  input_mode,
  raw_text,
  clarity,
  status
)
values (
  '33333333-3333-4333-8333-333333333333',
  '11111111-1111-4111-8111-111111111111',
  '22222222-2222-4222-8222-222222222222',
  current_date,
  'text',
  '복도 끝에 푸른 문이 있었고 바닥에는 작은 열쇠가 놓여 있었다.',
  'vivid',
  'in_manuscript'
);

insert into public.dream_elements (
  id,
  dream_id,
  type,
  label,
  detail,
  salience,
  source
)
values
  (
    '44444444-4444-4444-8444-444444444441',
    '33333333-3333-4333-8333-333333333333',
    'place',
    '긴 복도',
    '빛이 적은 복도',
    'high',
    'raw'
  ),
  (
    '44444444-4444-4444-8444-444444444442',
    '33333333-3333-4333-8333-333333333333',
    'object',
    '푸른 문',
    '복도 끝의 문',
    'high',
    'raw'
  ),
  (
    '44444444-4444-4444-8444-444444444443',
    '33333333-3333-4333-8333-333333333333',
    'object',
    '작은 열쇠',
    '바닥에 놓인 열쇠',
    'mid',
    'raw'
  ),
  (
    '44444444-4444-4444-8444-444444444444',
    '33333333-3333-4333-8333-333333333333',
    'emotion',
    '망설임',
    '문 앞에서 멈추는 감각',
    'mid',
    'recall'
  );

insert into public.scenes (
  id,
  volume_id,
  order_key,
  kind,
  placement,
  title,
  source_dream_ids,
  open_image
)
values
  (
    '55555555-5555-4555-8555-555555555551',
    '22222222-2222-4222-8222-222222222222',
    'a0',
    'prologue',
    'standalone',
    '문 앞에서',
    '{}'::uuid[],
    '닫힌 문 아래로 가느다란 빛이 번졌다.'
  ),
  (
    '55555555-5555-4555-8555-555555555552',
    '22222222-2222-4222-8222-222222222222',
    'a1',
    'dream',
    'continuation',
    '푸른 문',
    array['33333333-3333-4333-8333-333333333333']::uuid[],
    '열쇠는 손바닥 안에서 아직 차가웠다.'
  );

update public.volumes
   set prologue_scene_id = '55555555-5555-4555-8555-555555555551'
 where id = '22222222-2222-4222-8222-222222222222';

insert into public.passages (
  id,
  user_id,
  scene_id,
  order_key,
  text,
  origin,
  source_dream_id,
  source_element_ids,
  c_reason,
  locked,
  created_by
)
values
  (
    '66666666-6666-4666-8666-666666666661',
    '11111111-1111-4111-8111-111111111111',
    '55555555-5555-4555-8555-555555555552',
    'a0',
    '긴 복도는 발소리를 한 박자 늦게 돌려주었다.',
    'D',
    '33333333-3333-4333-8333-333333333333',
    array['44444444-4444-4444-8444-444444444441']::uuid[],
    null,
    false,
    'engine'
  ),
  (
    '66666666-6666-4666-8666-666666666662',
    '11111111-1111-4111-8111-111111111111',
    '55555555-5555-4555-8555-555555555552',
    'a1',
    '복도 끝에는 푸른 문이 닫혀 있었다.',
    'D',
    '33333333-3333-4333-8333-333333333333',
    array['44444444-4444-4444-8444-444444444442']::uuid[],
    null,
    false,
    'engine'
  ),
  (
    '66666666-6666-4666-8666-666666666663',
    '11111111-1111-4111-8111-111111111111',
    '55555555-5555-4555-8555-555555555552',
    'a2',
    '작은 열쇠가 바닥의 희미한 빛을 붙잡고 있었다.',
    'D',
    '33333333-3333-4333-8333-333333333333',
    array['44444444-4444-4444-8444-444444444443']::uuid[],
    null,
    false,
    'engine'
  ),
  (
    '66666666-6666-4666-8666-666666666664',
    '11111111-1111-4111-8111-111111111111',
    '55555555-5555-4555-8555-555555555552',
    'a3',
    '손을 뻗는 동안 망설임이 문턱처럼 남았다.',
    'D',
    '33333333-3333-4333-8333-333333333333',
    array['44444444-4444-4444-8444-444444444444']::uuid[],
    null,
    false,
    'engine'
  ),
  (
    '66666666-6666-4666-8666-666666666665',
    '11111111-1111-4111-8111-111111111111',
    '55555555-5555-4555-8555-555555555552',
    'a4',
    '문 너머에서 낮은 바람 소리가 이어졌다.',
    'C',
    null,
    '{}'::uuid[],
    '복도와 문 너머의 공간을 잇는 전이',
    false,
    'engine'
  ),
  (
    '66666666-6666-4666-8666-666666666666',
    '11111111-1111-4111-8111-111111111111',
    '55555555-5555-4555-8555-555555555552',
    'a5',
    '나는 열쇠를 쥔 채 문 앞에 잠시 서 있었다.',
    'U',
    null,
    '{}'::uuid[],
    null,
    true,
    'user'
  );

insert into public.narrative_memory (
  volume_id,
  story_so_far,
  open_threads,
  motifs
)
values (
  '22222222-2222-4222-8222-222222222222',
  '한 인물이 푸른 문 앞에서 작은 열쇠를 발견했다.',
  '[{"id":"thread-door","text":"푸른 문 너머","status":"open"}]'::jsonb,
  '[{"name":"푸른 문","count":1}]'::jsonb
);

insert into public.progress_events (
  id,
  user_id,
  volume_id,
  dream_id,
  delta_mu,
  reasons
)
values (
  '77777777-7777-4777-8777-777777777777',
  '11111111-1111-4111-8111-111111111111',
  '22222222-2222-4222-8222-222222222222',
  '33333333-3333-4333-8333-333333333333',
  6,
  '[{"type":"new_scene","n":1},{"type":"passage","n":6}]'::jsonb
);

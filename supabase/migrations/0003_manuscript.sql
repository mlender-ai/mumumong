create table public.entities (
  id uuid primary key default gen_random_uuid(),
  volume_id uuid not null references public.volumes (id) on delete cascade,
  type text not null,
  role_name text not null,
  description text,
  aliases text[] not null default '{}'::text[],
  status text not null default 'ambiguous'
    check (status in ('confirmed', 'ambiguous')),
  first_scene_id uuid,
  mention_count integer not null default 0 check (mention_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_entity_role unique (volume_id, role_name)
);

create table public.scenes (
  id uuid primary key default gen_random_uuid(),
  volume_id uuid not null references public.volumes (id) on delete cascade,
  order_key text not null,
  chapter_no integer check (chapter_no is null or chapter_no > 0),
  kind public.scene_kind not null,
  placement public.placement_kind not null,
  title text,
  source_dream_ids uuid[] not null default '{}'::uuid[],
  version integer not null default 1 check (version > 0),
  open_image text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_scene_order unique (volume_id, order_key),
  constraint chk_scene_order_key check (order_key ~ '^[a-zA-Z0-9]+$')
);

create index idx_scenes_volume_order
  on public.scenes (volume_id, order_key);

alter table public.volumes
  add constraint fk_volumes_prologue_scene
  foreign key (prologue_scene_id)
  references public.scenes (id)
  on delete set null;

alter table public.entities
  add constraint fk_entities_first_scene
  foreign key (first_scene_id)
  references public.scenes (id)
  on delete set null;

create table public.passages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  scene_id uuid not null references public.scenes (id) on delete cascade,
  order_key text not null,
  text text not null,
  origin public.passage_origin not null,
  source_dream_id uuid references public.dreams (id) on delete set null,
  source_element_ids uuid[] not null default '{}'::uuid[],
  c_reason text,
  original_text text,
  locked boolean not null default false,
  created_by text not null check (created_by in ('engine', 'compile', 'user')),
  first_read_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_passage_order unique (scene_id, order_key),
  constraint chk_passage_order_key check (order_key ~ '^[a-zA-Z0-9]+$'),
  constraint chk_d_has_source check (
    origin <> 'D'
    or coalesce(array_length(source_element_ids, 1), 0) >= 1
  ),
  constraint chk_u_locked check (origin <> 'U' or locked = true)
);

create table public.entity_mentions (
  id uuid primary key default gen_random_uuid(),
  entity_id uuid not null references public.entities (id) on delete cascade,
  dream_element_id uuid references public.dream_elements (id) on delete set null,
  scene_id uuid not null references public.scenes (id) on delete cascade,
  passage_id uuid references public.passages (id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint uq_entity_mention unique nulls not distinct (
    entity_id,
    scene_id,
    passage_id,
    dream_element_id
  )
);

create table public.link_decisions (
  id uuid primary key default gen_random_uuid(),
  volume_id uuid not null references public.volumes (id) on delete cascade,
  dream_id uuid not null references public.dreams (id) on delete cascade,
  kind text not null check (kind in ('entity_merge', 'placement')),
  payload jsonb not null default '{}'::jsonb,
  status text not null
    check (status in ('auto', 'pending', 'same', 'different', 'unsure', 'changed')),
  decided_at timestamptz,
  created_at timestamptz not null default now()
);

create unique index uq_link_decision_question
  on public.link_decisions (dream_id, kind, (payload ->> 'element_id'))
  nulls not distinct;

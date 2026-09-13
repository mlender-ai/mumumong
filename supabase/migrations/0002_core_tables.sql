create table public.volumes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  vol_no integer not null check (vol_no > 0),
  title text,
  format public.volume_format not null default 'novella',
  adaptation public.adaptation_level not null default 'balanced',
  style public.writing_style not null default 'plain',
  narrative_voice public.narrative_voice not null default 'third_person_past',
  status public.volume_status not null default 'active',
  target_mu numeric not null default 80 check (target_mu > 0),
  progress_mu numeric not null default 0 check (progress_mu >= 0),
  genre_profile jsonb not null default '{}'::jsonb,
  genre_directive jsonb not null default '{"mode":"keep"}'::jsonb,
  cover_motif_id text,
  cover_seed integer,
  author_note text,
  prologue_scene_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  constraint uq_volume_no unique (user_id, vol_no)
);

create unique index uq_volume_active
  on public.volumes (user_id)
  where status in ('active', 'completable', 'completing');

create table public.dreams (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  volume_id uuid references public.volumes (id) on delete set null,
  dream_date date not null default current_date,
  recorded_at timestamptz not null default now(),
  input_mode text not null check (input_mode in ('voice', 'text')),
  raw_text text not null,
  raw_text_edited_at timestamptz,
  recall_answers jsonb not null default '{}'::jsonb,
  clarity public.dream_clarity,
  status public.dream_status not null default 'queued',
  sensitive_flags text[] not null default '{}'::text[],
  is_backfill boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_dreams_user_date
  on public.dreams (user_id, dream_date desc);

create index idx_dreams_user_status
  on public.dreams (user_id, status);

create table public.dream_elements (
  id uuid primary key default gen_random_uuid(),
  dream_id uuid not null references public.dreams (id) on delete cascade,
  type public.element_type not null,
  label text not null,
  detail text,
  salience text not null check (salience in ('high', 'mid', 'low')),
  source text not null check (source in ('raw', 'recall')),
  span int4range,
  created_at timestamptz not null default now()
);

create index idx_dream_elements_dream
  on public.dream_elements (dream_id);

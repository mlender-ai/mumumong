create table public.narrative_memory (
  volume_id uuid primary key references public.volumes (id) on delete cascade,
  version integer not null default 1 check (version > 0),
  story_so_far text not null default '',
  open_threads jsonb not null default '[]'::jsonb,
  world_rules jsonb not null default '[]'::jsonb,
  motifs jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

create table public.progress_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  volume_id uuid not null references public.volumes (id) on delete cascade,
  dream_id uuid references public.dreams (id) on delete set null,
  delta_mu numeric not null,
  reasons jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create index idx_progress_events_volume_created
  on public.progress_events (volume_id, created_at);

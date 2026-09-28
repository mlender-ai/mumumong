alter table public.generation_runs
  add column engine_version text not null default 'v10';

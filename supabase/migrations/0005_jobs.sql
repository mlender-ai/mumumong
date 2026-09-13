create table public.jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  dream_id uuid references public.dreams (id) on delete cascade,
  volume_id uuid not null references public.volumes (id) on delete cascade,
  type public.job_type not null,
  status public.job_status not null default 'queued',
  attempt integer not null default 0 check (attempt >= 0),
  error text,
  idempotency_key uuid not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index uq_job_idem
  on public.jobs (user_id, idempotency_key);

create unique index uq_job_active
  on public.jobs (dream_id, type)
  where status in ('queued', 'running');

create index idx_jobs_queued
  on public.jobs (status, created_at)
  where status = 'queued';

create table public.generation_runs (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs (id) on delete cascade,
  stage public.job_type not null,
  model text not null,
  tokens_in integer not null default 0 check (tokens_in >= 0),
  tokens_out integer not null default 0 check (tokens_out >= 0),
  latency_ms integer not null default 0 check (latency_ms >= 0),
  validation jsonb not null default '{}'::jsonb,
  c_ratio numeric check (c_ratio is null or c_ratio between 0 and 1),
  cost_krw numeric not null default 0 check (cost_krw >= 0),
  prompt_version text not null,
  is_fallback boolean not null default false,
  created_at timestamptz not null default now()
);

create or replace function public.claim_job()
returns public.jobs
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  claimed public.jobs;
begin
  select *
    into claimed
    from public.jobs
   where status = 'queued'
     and attempt < 3
   order by created_at
   for update skip locked
   limit 1;

  if not found then
    return null;
  end if;

  update public.jobs
     set status = 'running',
         attempt = attempt + 1,
         updated_at = now()
   where id = claimed.id
   returning * into claimed;

  return claimed;
end;
$$;

revoke all on function public.claim_job() from public;
grant execute on function public.claim_job() to service_role;

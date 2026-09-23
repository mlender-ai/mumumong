alter table public.jobs
  add column if not exists available_at timestamptz not null default now();

drop index if exists public.idx_jobs_queued;
create index idx_jobs_queued
  on public.jobs (available_at, created_at)
  where status = 'queued';

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
     and available_at <= now()
   order by available_at, created_at
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

revoke all on function public.claim_job() from public, anon, authenticated;
grant execute on function public.claim_job() to service_role;

create or replace function public.claim_job_for_user(p_user_id uuid)
returns public.jobs
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  claimed public.jobs;
begin
  if p_user_id is null then
    return null;
  end if;
  select *
    into claimed
    from public.jobs
   where status = 'queued'
     and attempt < 3
     and available_at <= now()
     and user_id = p_user_id
   order by available_at, created_at
   for update skip locked
   limit 1;
  if not found then
    return null;
  end if;
  update public.jobs
     set status = 'running', attempt = attempt + 1, updated_at = now()
   where id = claimed.id
   returning * into claimed;
  return claimed;
end;
$$;

revoke all on function public.claim_job_for_user(uuid)
  from public, anon, authenticated;
grant execute on function public.claim_job_for_user(uuid) to service_role;

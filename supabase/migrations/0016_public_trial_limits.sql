-- Public trial users authenticate anonymously through Supabase, not Vercel.
-- Keep client access limited to creating the initial extract job; downstream
-- jobs and state transitions belong to the engine's service role.
drop policy if exists p_jobs on public.jobs;

create policy p_jobs_select on public.jobs
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy p_jobs_insert on public.jobs
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and (select public.user_has_current_ai_consent())
    and type = 'extract'
    and status = 'queued'
    and attempt = 0
    and dream_id is not null
    and payload = '{}'::jsonb
    and exists (
      select 1 from public.volumes v
       where v.id = jobs.volume_id and v.user_id = (select auth.uid())
    )
    and exists (
      select 1 from public.dreams d
       where d.id = jobs.dream_id
         and d.user_id = (select auth.uid())
         and d.volume_id = jobs.volume_id
    )
  );

create or replace function public.enforce_public_trial_job_limit()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  recent_user_jobs integer;
  recent_trial_jobs integer;
begin
  if auth.role() <> 'authenticated'
     or coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) is not true
     or new.type <> 'extract' then
    return new;
  end if;

  -- Serialize public-trial quota checks to close the concurrent-insert gap.
  perform pg_advisory_xact_lock(76112, 16);

  select count(*) into recent_user_jobs
    from public.jobs j
   where j.user_id = new.user_id
     and j.type = 'extract'
     and j.created_at >= now() - interval '24 hours';
  if recent_user_jobs >= 3 then
    raise exception using errcode = 'P0001', message = 'trial_user_daily_limit';
  end if;

  select count(*) into recent_trial_jobs
    from public.jobs j
    join auth.users u on u.id = j.user_id
   where u.is_anonymous is true
     and j.type = 'extract'
     and j.created_at >= now() - interval '24 hours';
  if recent_trial_jobs >= 50 then
    raise exception using errcode = 'P0001', message = 'trial_global_daily_limit';
  end if;

  return new;
end;
$$;

revoke all on function public.enforce_public_trial_job_limit()
  from public, anon, authenticated;

create trigger trg_public_trial_job_limit
  before insert on public.jobs
  for each row execute function public.enforce_public_trial_job_limit();

create index idx_jobs_extract_recent_user
  on public.jobs (user_id, created_at)
  where type = 'extract';

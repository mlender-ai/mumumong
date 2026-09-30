-- AI-processing consent is versioned in data, not in client copy or model routing.
-- A provider change inserts/updates a policy version before new processing can start.
create table public.ai_consent_policy (
  id integer primary key default 1 check (id = 1),
  version integer not null check (version > 0),
  providers jsonb not null check (
    jsonb_typeof(providers) = 'array' and jsonb_array_length(providers) > 0
  ),
  message text not null check (btrim(message) <> ''),
  updated_at timestamptz not null default now()
);

insert into public.ai_consent_policy (id, version, providers, message)
values (
  1,
  1,
  '[{"id":"groq","name":"Groq","terms_url":"https://console.groq.com/docs/legal/services-agreement","data_url":"https://console.groq.com/docs/your-data"}]'::jsonb,
  '꿈 내용은 원고 생성을 위해 AI 모델 제공사 Groq로 전송됩니다. Groq 약관상 별도 허락 없이는 입력과 출력을 모델 학습에 사용하지 않습니다. 추론 요청 내용은 기본적으로 보존하지 않지만, 서비스 안정성·남용 대응 시 최대 30일 동안 보존될 수 있으며 법적 의무가 있으면 더 길어질 수 있습니다.'
);

alter table public.ai_consent_policy enable row level security;
create policy p_ai_consent_policy_read on public.ai_consent_policy
  for select to anon, authenticated using (true);
revoke all on public.ai_consent_policy from public, anon, authenticated;
grant select on public.ai_consent_policy to anon, authenticated;
grant all on public.ai_consent_policy to service_role;

create table public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  consent_version integer,
  consented_at timestamptz,
  age_confirmed boolean not null default false,
  constraint consent_pair check ((consent_version is null) = (consented_at is null)),
  constraint consent_requires_age check (consented_at is null or age_confirmed)
);

alter table public.profiles enable row level security;
create policy p_profiles_owner_read on public.profiles
  for select to authenticated using (user_id = (select auth.uid()));
revoke all on public.profiles from public, anon, authenticated;
grant select on public.profiles to authenticated;
grant all on public.profiles to service_role;

create or replace function public.accept_ai_consent(
  p_version integer,
  p_age_confirmed boolean
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  actor_id uuid := (select auth.uid());
  required_version integer;
begin
  if actor_id is null then
    raise exception using errcode = '42501', message = 'authentication required';
  end if;
  if p_age_confirmed is distinct from true then
    raise exception using errcode = '22023', message = 'age confirmation required';
  end if;
  select version into required_version from public.ai_consent_policy where id = 1;
  if required_version is null or p_version is distinct from required_version then
    raise exception using errcode = '22023', message = 'current consent version required';
  end if;
  insert into public.profiles (user_id, consent_version, consented_at, age_confirmed)
  values (actor_id, required_version, now(), true)
  on conflict (user_id) do update
    set consent_version = excluded.consent_version,
        consented_at = excluded.consented_at,
        age_confirmed = true;
  return true;
end;
$$;
revoke all on function public.accept_ai_consent(integer, boolean)
  from public, anon, authenticated, service_role;
grant execute on function public.accept_ai_consent(integer, boolean) to authenticated;

create or replace function public.user_has_current_ai_consent()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.profiles p
      join public.ai_consent_policy cp on cp.id = 1
     where p.user_id = (select auth.uid())
       and p.consent_version = cp.version
       and p.consented_at is not null
       and p.age_confirmed
  );
$$;
revoke all on function public.user_has_current_ai_consent()
  from public, anon, authenticated, service_role;
grant execute on function public.user_has_current_ai_consent() to authenticated;

-- Only the initial client-authored job is inserted directly. This also gates
-- retries; service-created downstream jobs still require a valid claim below.
drop policy p_jobs on public.jobs;
create policy p_jobs on public.jobs
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and (select public.user_has_current_ai_consent())
    and exists (
      select 1 from public.volumes v
       where v.id = jobs.volume_id and v.user_id = (select auth.uid())
    )
    and (
      dream_id is null
      or exists (
        select 1 from public.dreams d
         where d.id = jobs.dream_id
           and d.user_id = (select auth.uid())
           and d.volume_id = jobs.volume_id
      )
    )
  );

-- Existing queued jobs cannot be run after consent becomes stale. The worker
-- uses these service-only RPCs, so a client-side screen cannot bypass the gate.
create or replace function public.claim_job()
returns public.jobs
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  claimed public.jobs;
begin
  select j.* into claimed
    from public.jobs j
    join public.profiles p on p.user_id = j.user_id
    join public.ai_consent_policy cp on cp.id = 1
   where j.status = 'queued'
     and j.attempt < 3
     and j.available_at <= now()
     and p.consented_at is not null
     and p.age_confirmed
     and p.consent_version = cp.version
   order by j.available_at, j.created_at
   for update of j skip locked
   limit 1;
  if not found then return null; end if;
  update public.jobs
     set status = 'running', attempt = attempt + 1, updated_at = now()
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
  if p_user_id is null then return null; end if;
  select j.* into claimed
    from public.jobs j
    join public.profiles p on p.user_id = j.user_id
    join public.ai_consent_policy cp on cp.id = 1
   where j.status = 'queued'
     and j.attempt < 3
     and j.available_at <= now()
     and j.user_id = p_user_id
     and p.consented_at is not null
     and p.age_confirmed
     and p.consent_version = cp.version
   order by j.available_at, j.created_at
   for update of j skip locked
   limit 1;
  if not found then return null; end if;
  update public.jobs
     set status = 'running', attempt = attempt + 1, updated_at = now()
   where id = claimed.id
   returning * into claimed;
  return claimed;
end;
$$;
revoke all on function public.claim_job_for_user(uuid) from public, anon, authenticated;
grant execute on function public.claim_job_for_user(uuid) to service_role;

-- Versioned author preferences. No manuscript or frozen prompt is rewritten.
alter table public.volumes add column settings_version integer not null default 1
  check (settings_version > 0);

create table public.volume_settings_versions (
  volume_id uuid not null references public.volumes(id) on delete cascade,
  version integer not null check (version > 0),
  base_version integer not null,
  mutation_id uuid,
  adaptation public.adaptation_level not null,
  style public.writing_style not null,
  narrative_voice public.narrative_voice not null,
  created_at timestamptz not null default now(),
  primary key (volume_id, version),
  unique (volume_id, mutation_id)
);
alter table public.volume_settings_versions enable row level security;
create policy p_settings_versions_read on public.volume_settings_versions
  for select to authenticated using (exists (
    select 1 from public.volumes v where v.id = volume_id and v.user_id = (select auth.uid())
  ));
revoke all on public.volume_settings_versions from public, anon, authenticated;
grant select on public.volume_settings_versions to authenticated;
grant all on public.volume_settings_versions to service_role;

insert into public.volume_settings_versions
  (volume_id, version, base_version, adaptation, style, narrative_voice)
select id, settings_version, 0, adaptation, style, narrative_voice from public.volumes;

create function public.seed_volume_settings() returns trigger language plpgsql
security definer set search_path = public, pg_temp as $$
begin
  if new.settings_version <> 1 then
    raise exception using errcode = '22023', message = 'initial settings version must be one';
  end if;
  insert into public.volume_settings_versions
    (volume_id, version, base_version, adaptation, style, narrative_voice)
  values (new.id, new.settings_version, 0, new.adaptation, new.style, new.narrative_voice);
  return new;
end $$;
create trigger trg_seed_volume_settings after insert on public.volumes
  for each row execute function public.seed_volume_settings();

create function public.guard_settings_history() returns trigger language plpgsql
set search_path = public, pg_temp as $$
begin
  raise exception using errcode = '55000', message = 'settings history is immutable';
end $$;
create trigger trg_guard_settings_history before update on public.volume_settings_versions
  for each row execute function public.guard_settings_history();

create function public.guard_volume_settings() returns trigger language plpgsql
set search_path = public, pg_temp as $$
begin
  if (new.adaptation, new.style, new.narrative_voice, new.settings_version)
      is distinct from (old.adaptation, old.style, old.narrative_voice, old.settings_version)
     and current_setting('app.settings_edit', true) is distinct from 'on' then
    raise exception using errcode = '55000', message = 'use user_update_generation_settings';
  end if;
  return new;
end $$;
create trigger trg_guard_volume_settings before update on public.volumes
  for each row execute function public.guard_volume_settings();

create function public.user_update_generation_settings(
  p_volume_id uuid, p_expected_version integer, p_mutation_id uuid,
  p_adaptation public.adaptation_level, p_style public.writing_style,
  p_narrative_voice public.narrative_voice
) returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v public.volumes;
  receipt public.volume_settings_versions;
  prior text;
begin
  if (select auth.uid()) is null then
    raise exception using errcode = '42501', message = 'authentication required';
  end if;
  if p_expected_version is null or p_expected_version < 1 or p_mutation_id is null
     or p_adaptation is null or p_style is null or p_narrative_voice is null then
    raise exception using errcode = '22023', message = 'settings request required';
  end if;
  select * into v from public.volumes where id = p_volume_id
    and user_id = (select auth.uid()) for update;
  if not found then raise exception using errcode = '42501', message = 'volume unavailable'; end if;
  select * into receipt from public.volume_settings_versions
    where volume_id = v.id and mutation_id = p_mutation_id;
  if found then
    if (receipt.base_version, receipt.adaptation, receipt.style, receipt.narrative_voice)
       is distinct from (p_expected_version, p_adaptation, p_style, p_narrative_voice) then
      raise exception using errcode = '22023', message = 'settings mutation reused';
    end if;
  else
    if v.status not in ('active', 'completable') then
      raise exception using errcode = '55000', message = 'volume settings closed';
    end if;
    if v.settings_version <> p_expected_version then
      raise exception using errcode = '40001', message = 'settings_version_conflict';
    end if;
    prior := current_setting('app.settings_edit', true);
    perform set_config('app.settings_edit', 'on', true);
    update public.volumes set adaptation = p_adaptation, style = p_style,
      narrative_voice = p_narrative_voice, settings_version = settings_version + 1,
      updated_at = now() where id = v.id returning * into v;
    perform set_config('app.settings_edit', coalesce(prior, ''), true);
    insert into public.volume_settings_versions
      (volume_id, version, base_version, mutation_id, adaptation, style, narrative_voice)
    values (v.id, v.settings_version, p_expected_version, p_mutation_id,
      p_adaptation, p_style, p_narrative_voice) returning * into receipt;
  end if;
  return jsonb_build_object('version', receipt.version, 'adaptation', receipt.adaptation,
    'style', receipt.style, 'narrative_voice', receipt.narrative_voice);
end $$;
revoke all on function public.user_update_generation_settings(uuid, integer, uuid,
  public.adaptation_level, public.writing_style, public.narrative_voice) from public, anon;
grant execute on function public.user_update_generation_settings(uuid, integer, uuid,
  public.adaptation_level, public.writing_style, public.narrative_voice) to authenticated;

-- Snapshot queued legacy jobs before preferences become editable.
update public.jobs j set payload = coalesce(j.payload, '{}'::jsonb) || jsonb_build_object(
  'generation_settings_version', v.settings_version,
  'generation_settings', jsonb_build_object('version', v.settings_version,
    'adaptation', v.adaptation, 'style', v.style, 'narrative_voice', v.narrative_voice))
from public.volumes v where v.id = j.volume_id;

create function public.pin_job_generation_settings() returns trigger language plpgsql
security definer set search_path = public, pg_temp as $$
declare
  v public.volumes;
  s public.volume_settings_versions;
  requested integer;
begin
  select * into v from public.volumes where id = new.volume_id and user_id = new.user_id for update;
  if not found then
    raise exception using errcode = '42501', message = 'new row violates row-level security policy for table "jobs"';
  end if;
  requested := coalesce((new.payload->>'generation_settings_version')::integer,
    (new.payload->'generation_settings'->>'version')::integer, v.settings_version);
  select * into s from public.volume_settings_versions where volume_id = v.id and version = requested;
  if not found then raise exception using errcode = '22023', message = 'settings version unavailable'; end if;
  new.payload := coalesce(new.payload, '{}'::jsonb) || jsonb_build_object(
    'generation_settings_version', s.version, 'generation_settings', jsonb_build_object(
      'version', s.version, 'adaptation', s.adaptation, 'style', s.style, 'narrative_voice', s.narrative_voice));
  return new;
end $$;
create trigger trg_pin_job_generation_settings before insert on public.jobs
  for each row execute function public.pin_job_generation_settings();

create function public.guard_job_generation_settings() returns trigger language plpgsql
set search_path = public, pg_temp as $$
begin
  if new.payload->'generation_settings' is distinct from old.payload->'generation_settings'
     or new.payload->'generation_settings_version' is distinct from old.payload->'generation_settings_version' then
    raise exception using errcode = '55000', message = 'job settings are immutable';
  end if;
  return new;
end $$;
create trigger trg_guard_job_generation_settings before update of payload on public.jobs
  for each row execute function public.guard_job_generation_settings();

-- BEFORE INSERT canonicalizes these two keys before RLS checks. Preserve the
-- existing first-stage/consent/ownership gate and reject every other client key.
drop policy p_jobs_insert on public.jobs;
create policy p_jobs_insert on public.jobs for insert to authenticated with check (
  user_id = (select auth.uid())
  and (select public.user_has_current_ai_consent())
  and type = 'extract' and status = 'queued' and attempt = 0
  and dream_id is not null
  and jsonb_typeof(payload) = 'object'
  and (payload - 'generation_settings' - 'generation_settings_version') = '{}'::jsonb
  and exists (select 1 from public.volumes v
    where v.id = jobs.volume_id and v.user_id = (select auth.uid()))
  and exists (select 1 from public.dreams d where d.id = jobs.dream_id
    and d.user_id = (select auth.uid()) and d.volume_id = jobs.volume_id)
);

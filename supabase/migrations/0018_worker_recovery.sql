-- Durable wakeup: background EdgeRuntime work is an optimization, not a queue.
-- A dedicated invoke-only token is used, never a service-role key in cron SQL.
create extension if not exists pg_net with schema extensions;

do $$ begin
  if not exists (select 1 from vault.secrets where name='mumumong_worker_schedule_token') then
    perform vault.create_secret(encode(extensions.gen_random_bytes(32),'hex'),
      'mumumong_worker_schedule_token','Invoke-only worker scheduler credential');
  end if;
end $$;

create function public.wake_generation_worker() returns bigint
language plpgsql security definer set search_path=public,pg_temp as $$
declare token text; endpoint text; request_id bigint;
begin
  perform public.reap_zombie_jobs();
  if not exists (select 1 from public.jobs j
    join public.profiles p on p.user_id=j.user_id
    join public.ai_consent_policy cp on cp.id=1 and cp.version=p.consent_version
    where j.status='queued' and j.attempt<3 and j.available_at<=now()
      and p.age_confirmed and p.consented_at is not null) then
    return null;
  end if;
  select decrypted_secret into token from vault.decrypted_secrets
    where name='mumumong_worker_schedule_token';
  select decrypted_secret into endpoint from vault.decrypted_secrets
    where name='mumumong_worker_url';
  if token is null or endpoint is null or endpoint !~ '^https://[a-z0-9]+\.supabase\.co/functions/v1/engine-worker$' then
    raise exception 'worker_schedule_unconfigured';
  end if;
  select net.http_post(url:=endpoint, headers:=jsonb_build_object(
    'Content-Type','application/json','x-worker-schedule-token',token),
    body:='{}'::jsonb, timeout_milliseconds:=65000) into request_id;
  return request_id;
end $$;
revoke all on function public.wake_generation_worker() from public,anon,authenticated,service_role;
-- pg_cron invokes as its privileged migration owner. Clients cannot wake a
-- global queue through this function or read its pending credential headers.
revoke all on schema net from anon,authenticated;
revoke all on all tables in schema net from anon,authenticated;
select cron.schedule('wake-generation-worker','* * * * *','select public.wake_generation_worker()');

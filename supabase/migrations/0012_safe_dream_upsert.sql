create or replace function public.user_upsert_dream(
  p_payload jsonb
)
returns public.dreams
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  actor_id uuid := (select auth.uid());
  requested_dream_id uuid;
  requested_volume_id uuid;
  saved public.dreams;
begin
  if actor_id is null then
    raise exception using errcode = '42501', message = 'authentication required';
  end if;
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception using errcode = '22023', message = 'dream payload is required';
  end if;

  requested_dream_id := nullif(p_payload ->> 'id', '')::uuid;
  requested_volume_id := nullif(p_payload ->> 'volume_id', '')::uuid;
  if requested_dream_id is null or requested_volume_id is null then
    raise exception using errcode = '22004', message = 'dream and volume ids are required';
  end if;
  if nullif(btrim(p_payload ->> 'raw_text'), '') is null then
    raise exception using errcode = '22004', message = 'dream text is required';
  end if;
  if not exists (
    select 1 from public.volumes v
     where v.id = requested_volume_id and v.user_id = actor_id
  ) then
    raise exception using errcode = '42501', message = 'volume ownership required';
  end if;

  insert into public.dreams (
    id,
    user_id,
    volume_id,
    dream_date,
    recorded_at,
    input_mode,
    raw_text,
    raw_text_edited_at,
    recall_answers,
    status,
    is_backfill
  ) values (
    requested_dream_id,
    actor_id,
    requested_volume_id,
    coalesce(nullif(p_payload ->> 'dream_date', '')::date, current_date),
    coalesce(nullif(p_payload ->> 'recorded_at', '')::timestamptz, now()),
    p_payload ->> 'input_mode',
    btrim(p_payload ->> 'raw_text'),
    nullif(p_payload ->> 'raw_text_edited_at', '')::timestamptz,
    coalesce(p_payload -> 'recall_answers', '{}'::jsonb),
    case
      when p_payload ->> 'status' = 'processing' then 'processing'::public.dream_status
      else 'queued'::public.dream_status
    end,
    coalesce((p_payload ->> 'is_backfill')::boolean, false)
  )
  on conflict (id) do update
    set dream_date = excluded.dream_date,
        recorded_at = excluded.recorded_at,
        input_mode = excluded.input_mode,
        raw_text = excluded.raw_text,
        raw_text_edited_at = excluded.raw_text_edited_at,
        recall_answers = excluded.recall_answers,
        is_backfill = excluded.is_backfill,
        updated_at = now()
  where dreams.user_id = actor_id
    and dreams.volume_id = requested_volume_id
  returning * into saved;

  if not found then
    raise exception using errcode = '42501', message = 'dream ownership required';
  end if;
  return saved;
end;
$$;

revoke all on function public.user_upsert_dream(jsonb)
  from public, anon, authenticated, service_role;
grant execute on function public.user_upsert_dream(jsonb)
  to authenticated;

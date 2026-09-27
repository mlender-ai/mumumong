create or replace function public.user_revert_passage(p_passage_id uuid)
returns public.passages
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  reverted public.passages;
  restored_origin public.passage_origin;
  previous_edit_setting text;
begin
  if (select auth.uid()) is null then
    raise exception using
      errcode = '42501',
      message = 'authentication required';
  end if;

  select *
    into reverted
    from public.passages p
   where p.id = p_passage_id
     and p.user_id = (select auth.uid())
   for update;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'passage not found';
  end if;

  if reverted.original_text is null then
    return reverted;
  end if;

  restored_origin := case
    when coalesce(array_length(reverted.source_element_ids, 1), 0) > 0
      then 'D'::public.passage_origin
    when reverted.c_reason is not null
      then 'C'::public.passage_origin
    else 'U'::public.passage_origin
  end;

  previous_edit_setting := current_setting('app.user_edit', true);
  perform set_config('app.user_edit', 'on', true);

  begin
    update public.passages p
       set text = p.original_text,
           origin = restored_origin,
           original_text = null,
           locked = restored_origin = 'U'::public.passage_origin,
           updated_at = now()
     where p.id = p_passage_id
     returning * into reverted;
  exception
    when others then
      perform set_config(
        'app.user_edit',
        coalesce(previous_edit_setting, ''),
        true
      );
      raise;
  end;

  perform set_config(
    'app.user_edit',
    coalesce(previous_edit_setting, ''),
    true
  );

  return reverted;
end;
$$;

create or replace function public.user_decide_link(
  p_decision_id uuid,
  p_status text
)
returns public.link_decisions
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  decision public.link_decisions;
  owner_user_id uuid;
  recalculated numeric;
begin
  if (select auth.uid()) is null then
    raise exception using
      errcode = '42501',
      message = 'authentication required';
  end if;

  if p_status not in ('same', 'different', 'unsure') then
    raise exception using
      errcode = '22023',
      message = 'invalid link decision status';
  end if;

  select ld.*
    into decision
    from public.link_decisions ld
   where ld.id = p_decision_id
   for update;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'link decision not found';
  end if;

  select v.user_id
    into owner_user_id
    from public.volumes v
   where v.id = decision.volume_id;

  if owner_user_id <> (select auth.uid()) then
    raise exception using
      errcode = 'P0002',
      message = 'link decision not found';
  end if;

  if decision.status = p_status then
    return decision;
  end if;

  if decision.status not in ('pending', 'auto') then
    raise exception using
      errcode = '55000',
      message = 'link decision was already answered';
  end if;

  update public.link_decisions ld
     set status = p_status,
         decided_at = now()
   where ld.id = p_decision_id
   returning * into decision;

  insert into public.progress_events (
    id,
    user_id,
    volume_id,
    dream_id,
    delta_mu,
    reasons
  ) values (
    decision.id,
    owner_user_id,
    decision.volume_id,
    decision.dream_id,
    0.5,
    '[{"type":"link_decision","n":1}]'::jsonb
  ) on conflict (id) do nothing;

  select greatest(0, coalesce(sum(pe.delta_mu), 0))
    into recalculated
    from public.progress_events pe
   where pe.volume_id = decision.volume_id;

  update public.volumes v
     set progress_mu = recalculated,
         updated_at = now()
   where v.id = decision.volume_id;

  return decision;
end;
$$;

revoke all on function public.user_revert_passage(uuid)
  from public, anon, authenticated, service_role;
revoke all on function public.user_decide_link(uuid, text)
  from public, anon, authenticated, service_role;

grant execute on function public.user_revert_passage(uuid) to authenticated;
grant execute on function public.user_decide_link(uuid, text) to authenticated;

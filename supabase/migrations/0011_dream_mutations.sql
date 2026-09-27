create or replace function public.user_remove_dream_from_manuscript(
  p_dream_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  owned_dream public.dreams;
  net_delta numeric;
  previous_edit_setting text;
begin
  if (select auth.uid()) is null then
    raise exception using errcode = '42501', message = 'authentication required';
  end if;

  select * into owned_dream
    from public.dreams d
   where d.id = p_dream_id
     and d.user_id = (select auth.uid())
   for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'dream not found';
  end if;
  if owned_dream.status = 'archived_only' then
    return true;
  end if;

  select coalesce(sum(pe.delta_mu), 0) into net_delta
    from public.progress_events pe
   where pe.dream_id = p_dream_id;

  previous_edit_setting := current_setting('app.user_edit', true);
  perform set_config('app.user_edit', 'on', true);
  begin
    delete from public.scenes s
     where p_dream_id = any(s.source_dream_ids)
       and s.volume_id = owned_dream.volume_id;
  exception when others then
    perform set_config('app.user_edit', coalesce(previous_edit_setting, ''), true);
    raise;
  end;
  perform set_config('app.user_edit', coalesce(previous_edit_setting, ''), true);

  delete from public.dream_elements de where de.dream_id = p_dream_id;
  update public.dreams d
     set status = 'archived_only', updated_at = now()
   where d.id = p_dream_id;

  if net_delta <> 0 and owned_dream.volume_id is not null then
    insert into public.progress_events (
      user_id, volume_id, dream_id, delta_mu, reasons
    ) values (
      owned_dream.user_id,
      owned_dream.volume_id,
      p_dream_id,
      -net_delta,
      '[{"type":"dream_removed","n":1}]'::jsonb
    );
    perform public.recompute_progress(owned_dream.volume_id);
  end if;
  return true;
end;
$$;

create or replace function public.user_delete_dream(
  p_dream_id uuid,
  p_keep_derived boolean default false
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  owned_dream public.dreams;
  net_delta numeric;
  previous_edit_setting text;
begin
  if (select auth.uid()) is null then
    raise exception using errcode = '42501', message = 'authentication required';
  end if;

  select * into owned_dream
    from public.dreams d
   where d.id = p_dream_id
     and d.user_id = (select auth.uid())
   for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'dream not found';
  end if;

  select coalesce(sum(pe.delta_mu), 0) into net_delta
    from public.progress_events pe
   where pe.dream_id = p_dream_id;

  previous_edit_setting := current_setting('app.user_edit', true);
  perform set_config('app.user_edit', 'on', true);
  begin
    if p_keep_derived then
      update public.scenes s
         set source_dream_ids = array_remove(s.source_dream_ids, p_dream_id),
             updated_at = now()
       where p_dream_id = any(s.source_dream_ids)
         and s.volume_id = owned_dream.volume_id;

      update public.passages p
         set origin = case when p.origin = 'D' then 'C' else p.origin end,
             source_dream_id = null,
             source_element_ids = case
               when p.origin = 'D' then '{}'::uuid[]
               else p.source_element_ids
             end,
             c_reason = case
               when p.origin = 'D' then '출처 꿈이 삭제되었습니다'
               else p.c_reason
             end,
             updated_at = now()
       where p.source_dream_id = p_dream_id;
    else
      delete from public.scenes s
       where p_dream_id = any(s.source_dream_ids)
         and s.volume_id = owned_dream.volume_id;
    end if;
  exception when others then
    perform set_config('app.user_edit', coalesce(previous_edit_setting, ''), true);
    raise;
  end;
  perform set_config('app.user_edit', coalesce(previous_edit_setting, ''), true);

  if net_delta <> 0 and owned_dream.volume_id is not null then
    insert into public.progress_events (
      user_id, volume_id, dream_id, delta_mu, reasons
    ) values (
      owned_dream.user_id,
      owned_dream.volume_id,
      p_dream_id,
      -net_delta,
      '[{"type":"dream_deleted","n":1}]'::jsonb
    );
  end if;

  delete from public.dreams d where d.id = p_dream_id;
  if owned_dream.volume_id is not null then
    perform public.recompute_progress(owned_dream.volume_id);
  end if;
  return true;
end;
$$;

revoke all on function public.user_remove_dream_from_manuscript(uuid)
  from public, anon, authenticated, service_role;
revoke all on function public.user_delete_dream(uuid, boolean)
  from public, anon, authenticated, service_role;

grant execute on function public.user_remove_dream_from_manuscript(uuid)
  to authenticated;
grant execute on function public.user_delete_dream(uuid, boolean)
  to authenticated;

create or replace function public.user_mark_passage_read(
  p_passage_id uuid,
  p_first_read_at timestamptz
)
returns public.passages
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  marked public.passages;
  previous_edit_setting text;
begin
  if (select auth.uid()) is null then
    raise exception using
      errcode = '42501',
      message = 'authentication required';
  end if;

  if p_first_read_at is null then
    raise exception using
      errcode = '22004',
      message = 'first read time is required';
  end if;

  select *
    into marked
    from public.passages p
   where p.id = p_passage_id
     and p.user_id = (select auth.uid())
   for update;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'passage not found';
  end if;

  if marked.first_read_at is not null then
    return marked;
  end if;

  previous_edit_setting := current_setting('app.user_edit', true);
  perform set_config('app.user_edit', 'on', true);

  begin
    update public.passages p
       set first_read_at = p_first_read_at,
           updated_at = now()
     where p.id = p_passage_id
     returning * into marked;
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

  return marked;
end;
$$;

revoke all on function public.user_mark_passage_read(uuid, timestamptz)
  from public, anon, authenticated, service_role;

grant execute on function public.user_mark_passage_read(uuid, timestamptz)
  to authenticated;

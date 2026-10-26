-- Non-LLM completion: freeze the current ordered text, never rewrite it.
create table public.completed_books (
  volume_id uuid primary key references public.volumes(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null,
  version integer not null default 1 check(version=1),
  snapshot jsonb not null check(jsonb_typeof(snapshot)='object'),
  completed_at timestamptz not null default now(),
  unique(user_id,request_id)
);
alter table public.completed_books enable row level security;
create policy p_books_read on public.completed_books for select to authenticated
  using(user_id=(select auth.uid()));
revoke all on public.completed_books from public,anon,authenticated;
grant select on public.completed_books to authenticated;
grant all on public.completed_books to service_role;
create function public.guard_completed_book() returns trigger language plpgsql as $$
begin raise exception using errcode='55000',message='completed book is immutable'; end $$;
create trigger trg_book_immutable before update on public.completed_books
  for each row execute function public.guard_completed_book();

create function public.book_source_document(p_volume_id uuid) returns jsonb
language sql stable security definer set search_path=public,pg_temp as $$
  select jsonb_build_object('volume_id',v.id,'volume_no',v.vol_no,'format',v.format,
    'settings_version',v.settings_version,'cover_seed',v.cover_seed,'cover_motif_id',v.cover_motif_id,
    'scenes',coalesce((select jsonb_agg(jsonb_build_object('id',s.id,'order_key',s.order_key,
      'title',s.title,'kind',s.kind,'placement',s.placement,'source_dream_ids',s.source_dream_ids,
      'passages',(select jsonb_agg(jsonb_build_object('id',p.id,'order_key',p.order_key,'text',p.text,
        'origin',p.origin,'locked',p.locked,'source_dream_id',p.source_dream_id,
        'source_element_ids',p.source_element_ids,'c_reason',p.c_reason) order by p.order_key,p.id)
        from public.passages p where p.scene_id=s.id)) order by s.order_key,s.id)
      from public.scenes s where s.volume_id=v.id and exists(select 1 from public.passages p where p.scene_id=s.id)),'[]'::jsonb),
    'dreams',coalesce((select jsonb_agg(jsonb_build_object('id',d.id,'date',d.dream_date,
      'first_line',left(split_part(btrim(d.raw_text),E'\n',1),120)) order by d.dream_date,d.id)
      from public.dreams d where d.volume_id=v.id and exists(select 1 from public.scenes s
        where s.volume_id=v.id and d.id=any(s.source_dream_ids))),'[]'::jsonb))
  from public.volumes v where v.id=p_volume_id;
$$;
revoke all on function public.book_source_document(uuid) from public,anon,authenticated,service_role;

create function public.book_completion_eligible(p_volume_id uuid) returns boolean
language sql stable security definer set search_path=public,pg_temp as $$
  select v.status in ('active','completable') and v.progress_mu>=v.target_mu*0.7
    and (select count(*) from public.scenes s where s.volume_id=v.id
      and exists(select 1 from public.passages p where p.scene_id=s.id)) >= case when v.format='short' then 5 else 12 end
    and (select count(*) from (select em.entity_id from public.entity_mentions em
      join public.entities e on e.id=em.entity_id and e.volume_id=v.id
      join public.dream_elements de on de.id=em.dream_element_id
      join public.dreams d on d.id=de.dream_id and d.volume_id=v.id
      group by em.entity_id having count(distinct d.id)>=2) repeated) >= case when v.format='short' then 1 else 3 end
    and (v.format='short' or (select count(*) from public.narrative_memory nm,
      lateral jsonb_array_elements(nm.open_threads) t(value) where nm.volume_id=v.id
        and coalesce(t.value->>'status','open')='open')>=2)
  from public.volumes v where v.id=p_volume_id;
$$;
revoke all on function public.book_completion_eligible(uuid) from public,anon,authenticated,service_role;

create function public.preview_book_completion(p_volume_id uuid) returns jsonb
language plpgsql security definer set search_path=public,pg_temp as $$
declare doc jsonb;
begin
  if not exists(select 1 from public.volumes where id=p_volume_id and user_id=(select auth.uid())) then
    raise exception using errcode='42501',message='volume unavailable';
  end if;
  doc:=public.book_source_document(p_volume_id);
  return jsonb_build_object('document',doc,'revision',md5(doc::text),
    'eligible',public.book_completion_eligible(p_volume_id),'busy',exists(select 1 from public.jobs
      where volume_id=p_volume_id and status in ('queued','running')));
end $$;
revoke all on function public.preview_book_completion(uuid) from public,anon,authenticated,service_role;
grant execute on function public.preview_book_completion(uuid) to authenticated;

create function public.complete_volume_book(p_volume_id uuid,p_request_id uuid,
  p_revision text,p_title text,p_author_note text default null) returns jsonb
language plpgsql security definer set search_path=public,pg_temp as $$
declare v public.volumes; saved public.completed_books; doc jsonb; stamp timestamptz:=now();
begin
  select * into v from public.volumes where id=p_volume_id and user_id=(select auth.uid()) for update;
  if not found then raise exception using errcode='42501',message='volume unavailable'; end if;
  if p_request_id is null or p_revision is null or p_title is null or btrim(p_title)='' or
    char_length(p_title)>120 or char_length(coalesce(p_author_note,''))>10000 then
    raise exception using errcode='22023',message='completion fields invalid';
  end if;
  select * into saved from public.completed_books where volume_id=v.id;
  if found then
    if saved.request_id<>p_request_id or saved.snapshot->>'title'<>btrim(p_title)
      or coalesce(saved.snapshot->>'author_note','')<>coalesce(p_author_note,'') then
      raise exception using errcode='40001',message='book already completed';
    end if;
    return saved.snapshot;
  end if;
  if not public.book_completion_eligible(v.id) then
    raise exception using errcode='55000',message='completion not eligible';
  end if;
  if exists(select 1 from public.jobs where volume_id=v.id and status in ('queued','running')) then
    raise exception using errcode='55000',message='generation pending';
  end if;
  -- One SQL snapshot reads every scene/passage/source consistently. Concurrent
  -- edits after this point do not mutate the frozen copy. No LLM stage runs.
  doc:=public.book_source_document(v.id);
  if md5(doc::text)<>p_revision then
    raise exception using errcode='40001',message='manuscript changed';
  end if;
  doc:=doc||jsonb_build_object('version',1,'request_id',p_request_id,'title',btrim(p_title),
    'author_note',p_author_note,'completed_at',stamp);
  insert into public.completed_books(volume_id,user_id,request_id,snapshot,completed_at)
    values(v.id,v.user_id,p_request_id,doc,stamp);
  update public.volumes set status='completed',title=btrim(p_title),author_note=p_author_note,
    completed_at=stamp,updated_at=stamp where id=v.id;
  return doc;
end $$;
revoke all on function public.complete_volume_book(uuid,uuid,text,text,text) from public,anon,authenticated,service_role;
grant execute on function public.complete_volume_book(uuid,uuid,text,text,text) to authenticated;

create function public.start_volume_after_book(p_volume_id uuid) returns public.volumes
language plpgsql security definer set search_path=public,pg_temp as $$
declare old public.volumes; next_volume public.volumes;
begin
  if (select auth.uid()) is null then raise exception using errcode='42501',message='authentication required'; end if;
  perform pg_advisory_xact_lock(hashtextextended((select auth.uid())::text,19));
  select * into old from public.volumes where id=p_volume_id and user_id=(select auth.uid()) and status='completed';
  if not found or not exists(select 1 from public.completed_books where volume_id=old.id) then
    raise exception using errcode='42501',message='completed book unavailable';
  end if;
  select * into next_volume from public.volumes where user_id=old.user_id and status in ('active','completable','completing') limit 1;
  if found then return next_volume; end if;
  insert into public.volumes(user_id,vol_no,format,target_mu,adaptation,style,narrative_voice)
    select old.user_id,coalesce(max(vol_no),0)+1,'short',20,old.adaptation,old.style,old.narrative_voice
    from public.volumes where user_id=old.user_id returning * into next_volume;
  return next_volume;
end $$;
revoke all on function public.start_volume_after_book(uuid) from public,anon,authenticated,service_role;
grant execute on function public.start_volume_after_book(uuid) to authenticated;

-- An old client must not enqueue another generation for a finished volume.
create function public.guard_completed_job() returns trigger language plpgsql
security definer set search_path=public,pg_temp as $$
begin
  perform 1 from public.volumes where id=new.volume_id and status in ('active','completable') for update;
  if not found then raise exception using errcode='55000',message='volume generation closed'; end if;
  return new;
end $$;
create trigger trg_completed_job before insert on public.jobs for each row execute function public.guard_completed_job();

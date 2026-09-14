create or replace function public.guard_locked_passage()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if old.locked
     and current_setting('app.user_edit', true) is distinct from 'on' then
    raise exception using
      errcode = '55000',
      message = 'locked passage cannot be modified outside user_edit_passage';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

create trigger trg_guard_locked_passage
before update or delete on public.passages
for each row execute function public.guard_locked_passage();

create or replace function public.user_edit_passage(
  p_passage_id uuid,
  p_text text
)
returns public.passages
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  edited public.passages;
  previous_edit_setting text;
begin
  if (select auth.uid()) is null then
    raise exception using
      errcode = '42501',
      message = 'authentication required';
  end if;

  if p_text is null then
    raise exception using
      errcode = '22004',
      message = 'passage text is required';
  end if;

  select *
    into edited
    from public.passages p
   where p.id = p_passage_id
     and p.user_id = (select auth.uid())
   for update;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'passage not found';
  end if;

  previous_edit_setting := current_setting('app.user_edit', true);
  perform set_config('app.user_edit', 'on', true);

  begin
    update public.passages p
       set original_text = case
             when p.origin <> 'U' and p.original_text is null then p.text
             else p.original_text
           end,
           text = p_text,
           origin = 'U',
           locked = true,
           created_by = 'user',
           updated_at = now()
     where p.id = p_passage_id
     returning * into edited;
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

  return edited;
end;
$$;

create or replace function public.commit_scene(
  p_dream_id uuid,
  p_volume_id uuid,
  p_payload jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  scene_payload jsonb;
  passages_payload jsonb;
  passage_payload jsonb;
  entity_payload jsonb;
  passage_index integer;
  scene_id uuid;
  passage_id uuid;
  entity_id uuid;
  element_id uuid;
  owner_user_id uuid;
  current_clarity public.dream_clarity;
  committed_clarity public.dream_clarity;
  recall_answers jsonb;
  scene_order_key text;
  scene_kind public.scene_kind;
  scene_placement public.placement_kind;
  passage_order_key text;
  passage_origin public.passage_origin;
  passage_text text;
  source_dream_id uuid;
  source_element_ids uuid[];
  entity_aliases text[];
  used_entity text;
  recall_count integer;
  delta_mu numeric;
  new_progress numeric;
  target_mu numeric;
  current_format public.volume_format;
  scene_count integer;
  repeated_entity_count integer;
  open_thread_count integer;
begin
  -- Fast idempotency path. A retry does not need to parse or validate the payload.
  select s.id
    into scene_id
    from public.scenes s
   where s.volume_id = p_volume_id
     and p_dream_id = any(s.source_dream_ids)
   order by s.created_at
   limit 1;

  if found then
    return scene_id;
  end if;

  if p_dream_id is null or p_volume_id is null then
    raise exception using
      errcode = '22004',
      message = 'dream and volume are required';
  end if;

  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception using
      errcode = '22023',
      message = 'commit payload must be an object';
  end if;

  -- The dream lock serializes concurrent commits for the same source dream.
  select d.user_id, d.clarity, d.recall_answers
    into owner_user_id, current_clarity, recall_answers
    from public.dreams d
   where d.id = p_dream_id
     and d.volume_id = p_volume_id
   for update;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'dream and volume do not match';
  end if;

  perform 1
    from public.volumes v
   where v.id = p_volume_id
     and v.user_id = owner_user_id
   for update;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'volume owner does not match dream owner';
  end if;

  -- A concurrent caller may have committed while this transaction waited.
  select s.id
    into scene_id
    from public.scenes s
   where s.volume_id = p_volume_id
     and p_dream_id = any(s.source_dream_ids)
   order by s.created_at
   limit 1;

  if found then
    return scene_id;
  end if;

  scene_payload := p_payload -> 'scene';
  passages_payload := p_payload -> 'passages';

  if scene_payload is null or jsonb_typeof(scene_payload) <> 'object' then
    raise exception using
      errcode = '22023',
      message = 'scene payload must be an object';
  end if;

  if passages_payload is null
     or jsonb_typeof(passages_payload) <> 'array'
     or jsonb_array_length(passages_payload) = 0 then
    raise exception using
      errcode = '22023',
      message = 'commit payload requires at least one passage';
  end if;

  scene_order_key := nullif(btrim(scene_payload ->> 'order_key'), '');
  if scene_order_key is null then
    raise exception using
      errcode = '22023',
      message = 'scene order_key is required';
  end if;

  scene_kind := coalesce(
    nullif(scene_payload ->> 'kind', '')::public.scene_kind,
    'dream'::public.scene_kind
  );
  scene_placement := nullif(
    scene_payload ->> 'placement',
    ''
  )::public.placement_kind;

  if scene_placement is null then
    raise exception using
      errcode = '22023',
      message = 'scene placement is required';
  end if;

  committed_clarity := coalesce(
    nullif(p_payload ->> 'clarity', '')::public.dream_clarity,
    current_clarity
  );

  if committed_clarity is null then
    raise exception using
      errcode = '22023',
      message = 'dream clarity is required';
  end if;

  scene_id := coalesce(
    nullif(scene_payload ->> 'id', '')::uuid,
    gen_random_uuid()
  );

  insert into public.scenes (
    id,
    volume_id,
    order_key,
    kind,
    placement,
    title,
    source_dream_ids,
    open_image
  )
  values (
    scene_id,
    p_volume_id,
    scene_order_key,
    scene_kind,
    scene_placement,
    nullif(scene_payload ->> 'title', ''),
    array[p_dream_id],
    coalesce(
      nullif(scene_payload ->> 'open_image', ''),
      nullif(p_payload ->> 'open_image', '')
    )
  );

  for passage_payload, passage_index in
    select value, ordinality::integer
      from jsonb_array_elements(passages_payload)
           with ordinality as item(value, ordinality)
  loop
    if jsonb_typeof(passage_payload) <> 'object' then
      raise exception using
        errcode = '22023',
        message = 'each passage must be an object';
    end if;

    passage_origin := nullif(
      passage_payload ->> 'origin',
      ''
    )::public.passage_origin;
    passage_text := nullif(passage_payload ->> 'text', '');

    if passage_origin is null or passage_text is null then
      raise exception using
        errcode = '22023',
        message = 'passage origin and text are required';
    end if;

    if passage_origin = 'U' then
      raise exception using
        errcode = '22023',
        message = 'commit_scene does not accept user passages';
    end if;

    select coalesce(array_agg(value::uuid order by ordinality), '{}'::uuid[])
      into source_element_ids
      from jsonb_array_elements_text(
        coalesce(passage_payload -> 'source_element_ids', '[]'::jsonb)
      ) with ordinality as source(value, ordinality);

    if passage_origin = 'D' and cardinality(source_element_ids) = 0 then
      raise exception using
        errcode = '23514',
        message = 'D passage requires at least one source element';
    end if;

    if exists (
      select 1
        from unnest(source_element_ids) as source_id
       where not exists (
         select 1
           from public.dream_elements de
          where de.id = source_id
            and de.dream_id = p_dream_id
       )
    ) then
      raise exception using
        errcode = '23503',
        message = 'source element does not belong to source dream';
    end if;

    passage_id := coalesce(
      nullif(passage_payload ->> 'id', '')::uuid,
      gen_random_uuid()
    );
    passage_order_key := coalesce(
      nullif(passage_payload ->> 'order_key', ''),
      'a' || lpad(passage_index::text, 4, '0')
    );
    source_dream_id := case
      when passage_origin = 'D' then p_dream_id
      else null
    end;

    insert into public.passages (
      id,
      user_id,
      scene_id,
      order_key,
      text,
      origin,
      source_dream_id,
      source_element_ids,
      c_reason,
      locked,
      created_by
    )
    values (
      passage_id,
      owner_user_id,
      scene_id,
      passage_order_key,
      passage_text,
      passage_origin,
      source_dream_id,
      source_element_ids,
      nullif(passage_payload ->> 'c_reason', ''),
      false,
      'engine'
    );
  end loop;

  if p_payload ? 'new_entities' then
    if jsonb_typeof(p_payload -> 'new_entities') <> 'array' then
      raise exception using
        errcode = '22023',
        message = 'new_entities must be an array';
    end if;

    for entity_payload in
      select value from jsonb_array_elements(p_payload -> 'new_entities')
    loop
      if nullif(btrim(entity_payload ->> 'role_name'), '') is null then
        raise exception using
          errcode = '22023',
          message = 'new entity role_name is required';
      end if;

      select coalesce(array_agg(value), '{}'::text[])
        into entity_aliases
        from jsonb_array_elements_text(
          coalesce(entity_payload -> 'aliases', '[]'::jsonb)
        ) as alias(value);

      element_id := nullif(
        coalesce(
          entity_payload ->> 'from_element',
          entity_payload ->> 'element_id'
        ),
        ''
      )::uuid;

      if element_id is not null and not exists (
        select 1
          from public.dream_elements de
         where de.id = element_id
           and de.dream_id = p_dream_id
      ) then
        raise exception using
          errcode = '23503',
          message = 'entity source element does not belong to source dream';
      end if;

      insert into public.entities (
        volume_id,
        type,
        role_name,
        description,
        aliases,
        first_scene_id,
        mention_count
      )
      values (
        p_volume_id,
        coalesce(nullif(entity_payload ->> 'type', ''), 'person'),
        btrim(entity_payload ->> 'role_name'),
        nullif(entity_payload ->> 'description', ''),
        entity_aliases,
        scene_id,
        1
      )
      on conflict (volume_id, role_name) do update
        set description = coalesce(excluded.description, entities.description),
            aliases = coalesce(
              (
                select array_agg(distinct alias_name order by alias_name)
                  from unnest(entities.aliases || excluded.aliases) as alias_name
              ),
              '{}'::text[]
            ),
            first_scene_id = coalesce(entities.first_scene_id, scene_id),
            mention_count = entities.mention_count + 1,
            updated_at = now()
      returning id into entity_id;

      insert into public.entity_mentions (
        entity_id,
        dream_element_id,
        scene_id
      )
      values (entity_id, element_id, scene_id)
      on conflict do nothing;
    end loop;
  end if;

  if p_payload ? 'used_entities' then
    if jsonb_typeof(p_payload -> 'used_entities') <> 'array' then
      raise exception using
        errcode = '22023',
        message = 'used_entities must be an array';
    end if;

    for used_entity in
      select distinct value
        from jsonb_array_elements_text(p_payload -> 'used_entities')
    loop
      update public.entities e
         set mention_count = e.mention_count + 1,
             updated_at = now()
       where e.id = used_entity::uuid
         and e.volume_id = p_volume_id
       returning e.id into entity_id;

      if not found then
        raise exception using
          errcode = '23503',
          message = 'used entity does not belong to volume';
      end if;

      insert into public.entity_mentions (entity_id, scene_id)
      values (entity_id, scene_id)
      on conflict do nothing;
    end loop;
  end if;

  update public.dreams
     set clarity = committed_clarity,
         status = 'in_manuscript',
         updated_at = now()
   where id = p_dream_id;

  select least(
           3,
           count(*) filter (
             where jsonb_typeof(value) = 'string'
               and nullif(btrim(value #>> '{}'), '') is not null
               and lower(btrim(value #>> '{}')) not in (
                 '모름',
                 '기억 안 남',
                 'unknown'
               )
           )
         )::integer
    into recall_count
    from jsonb_each(coalesce(recall_answers, '{}'::jsonb));

  delta_mu := case committed_clarity
    when 'fragment' then 1.0
    when 'partial' then 2.0
    when 'vivid' then 3.0
  end + least(0.75, recall_count * 0.25);

  insert into public.progress_events (
    user_id,
    volume_id,
    dream_id,
    delta_mu,
    reasons
  )
  values (
    owner_user_id,
    p_volume_id,
    p_dream_id,
    delta_mu,
    jsonb_build_array(
      jsonb_build_object('type', 'new_scene', 'n', 1),
      jsonb_build_object('type', 'recall', 'n', recall_count)
    )
  );

  update public.volumes v
     set progress_mu = v.progress_mu + delta_mu,
         updated_at = now()
   where v.id = p_volume_id
   returning v.progress_mu, v.target_mu, v.format
     into new_progress, target_mu, current_format;

  select count(*)::integer
    into scene_count
    from public.scenes s
   where s.volume_id = p_volume_id;

  select count(*)::integer
    into repeated_entity_count
    from public.entities e
   where e.volume_id = p_volume_id
     and e.mention_count >= 2;

  select count(*)::integer
    into open_thread_count
    from public.narrative_memory nm
    cross join lateral jsonb_array_elements(nm.open_threads) as thread(value)
   where nm.volume_id = p_volume_id
     and coalesce(thread.value ->> 'status', 'open') = 'open';

  if new_progress >= target_mu * 0.7
     and (
       (
         current_format = 'short'
         and scene_count >= 5
         and repeated_entity_count >= 1
       )
       or (
         current_format = 'novella'
         and scene_count >= 12
         and repeated_entity_count >= 3
         and open_thread_count >= 2
       )
     ) then
    update public.volumes
       set status = 'completable',
           updated_at = now()
     where id = p_volume_id
       and status = 'active';
  end if;

  return scene_id;
end;
$$;

create or replace function public.recompute_progress(p_volume_id uuid)
returns numeric
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  recalculated numeric;
begin
  select greatest(0, coalesce(sum(pe.delta_mu), 0))
    into recalculated
    from public.progress_events pe
   where pe.volume_id = p_volume_id;

  update public.volumes
     set progress_mu = recalculated,
         updated_at = now()
   where id = p_volume_id;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'volume not found';
  end if;

  return recalculated;
end;
$$;

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
   order by created_at, id
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

create or replace function public.reap_zombie_jobs()
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  affected integer;
begin
  update public.jobs
     set status = case
           when attempt < 3 then 'queued'::public.job_status
           else 'failed'::public.job_status
         end,
         error = 'worker_timeout',
         updated_at = now()
   where status = 'running'
     and updated_at < now() - interval '5 minutes';

  get diagnostics affected = row_count;
  return affected;
end;
$$;

create or replace function public.delete_user_data(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  previous_edit_setting text;
begin
  if p_user_id is null then
    raise exception using
      errcode = '22004',
      message = 'user id is required';
  end if;

  previous_edit_setting := current_setting('app.user_edit', true);
  perform set_config('app.user_edit', 'on', true);

  begin
    delete from public.jobs where user_id = p_user_id;
    delete from public.progress_events where user_id = p_user_id;
    delete from public.passages where user_id = p_user_id;

    delete from public.link_decisions ld
     where exists (
       select 1 from public.volumes v
        where v.id = ld.volume_id and v.user_id = p_user_id
     )
        or exists (
          select 1 from public.dreams d
           where d.id = ld.dream_id and d.user_id = p_user_id
        );

    delete from public.entity_mentions em
     where exists (
       select 1
         from public.entities e
         join public.volumes v on v.id = e.volume_id
        where e.id = em.entity_id
          and v.user_id = p_user_id
     )
        or exists (
          select 1
            from public.scenes s
            join public.volumes v on v.id = s.volume_id
           where s.id = em.scene_id
             and v.user_id = p_user_id
        );

    delete from public.dream_elements de
     where exists (
       select 1 from public.dreams d
        where d.id = de.dream_id and d.user_id = p_user_id
     );

    delete from public.entities e
     where exists (
       select 1 from public.volumes v
        where v.id = e.volume_id and v.user_id = p_user_id
     );

    delete from public.narrative_memory nm
     where exists (
       select 1 from public.volumes v
        where v.id = nm.volume_id and v.user_id = p_user_id
     );

    delete from public.scenes s
     where exists (
       select 1 from public.volumes v
        where v.id = s.volume_id and v.user_id = p_user_id
     );

    delete from public.dreams where user_id = p_user_id;
    delete from public.volumes where user_id = p_user_id;
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
end;
$$;

revoke all on function public.guard_locked_passage()
  from public, anon, authenticated, service_role;
revoke all on function public.user_edit_passage(uuid, text)
  from public, anon, authenticated, service_role;
revoke all on function public.commit_scene(uuid, uuid, jsonb)
  from public, anon, authenticated, service_role;
revoke all on function public.recompute_progress(uuid)
  from public, anon, authenticated, service_role;
revoke all on function public.claim_job()
  from public, anon, authenticated, service_role;
revoke all on function public.reap_zombie_jobs()
  from public, anon, authenticated, service_role;
revoke all on function public.delete_user_data(uuid)
  from public, anon, authenticated, service_role;

grant execute on function public.user_edit_passage(uuid, text) to authenticated;
grant execute on function public.commit_scene(uuid, uuid, jsonb) to service_role;
grant execute on function public.recompute_progress(uuid) to service_role;
grant execute on function public.claim_job() to service_role;
grant execute on function public.reap_zombie_jobs() to service_role;
grant execute on function public.delete_user_data(uuid) to service_role;

create extension if not exists pg_cron with schema pg_catalog;

select cron.schedule(
  'reap-zombies',
  '* * * * *',
  'select public.reap_zombie_jobs()'
);

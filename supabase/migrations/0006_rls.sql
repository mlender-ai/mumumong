-- Directly owned tables.
alter table public.volumes enable row level security;
alter table public.dreams enable row level security;
alter table public.passages enable row level security;
alter table public.jobs enable row level security;
alter table public.progress_events enable row level security;

create policy p_volumes
  on public.volumes
  for all
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy p_dreams
  on public.dreams
  for all
  to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and (
      volume_id is null
      or exists (
        select 1
          from public.volumes v
         where v.id = dreams.volume_id
           and v.user_id = (select auth.uid())
      )
    )
  );

create policy p_passages
  on public.passages
  for all
  to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1
        from public.scenes s
        join public.volumes v on v.id = s.volume_id
       where s.id = passages.scene_id
         and v.user_id = (select auth.uid())
    )
  );

create policy p_jobs
  on public.jobs
  for all
  to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1
        from public.volumes v
       where v.id = jobs.volume_id
         and v.user_id = (select auth.uid())
    )
    and (
      dream_id is null
      or exists (
        select 1
          from public.dreams d
         where d.id = jobs.dream_id
           and d.user_id = (select auth.uid())
           and d.volume_id = jobs.volume_id
      )
    )
  );

create policy p_progress_events
  on public.progress_events
  for all
  to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1
        from public.volumes v
       where v.id = progress_events.volume_id
         and v.user_id = (select auth.uid())
    )
    and (
      dream_id is null
      or exists (
        select 1
          from public.dreams d
         where d.id = progress_events.dream_id
           and d.user_id = (select auth.uid())
           and d.volume_id = progress_events.volume_id
      )
    )
  );

create index idx_passages_user_id on public.passages (user_id);
create index idx_progress_events_user_id on public.progress_events (user_id);

-- Tables whose ownership is derived through a parent row.
alter table public.dream_elements enable row level security;
alter table public.entities enable row level security;
alter table public.entity_mentions enable row level security;
alter table public.scenes enable row level security;
alter table public.narrative_memory enable row level security;
alter table public.link_decisions enable row level security;

create policy p_dream_elements
  on public.dream_elements
  for all
  to authenticated
  using (
    exists (
      select 1
        from public.dreams d
       where d.id = dream_elements.dream_id
         and d.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
        from public.dreams d
       where d.id = dream_elements.dream_id
         and d.user_id = (select auth.uid())
    )
  );

create policy p_entities
  on public.entities
  for all
  to authenticated
  using (
    exists (
      select 1
        from public.volumes v
       where v.id = entities.volume_id
         and v.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
        from public.volumes v
       where v.id = entities.volume_id
         and v.user_id = (select auth.uid())
    )
  );

create policy p_scenes
  on public.scenes
  for all
  to authenticated
  using (
    exists (
      select 1
        from public.volumes v
       where v.id = scenes.volume_id
         and v.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
        from public.volumes v
       where v.id = scenes.volume_id
         and v.user_id = (select auth.uid())
    )
  );

create policy p_entity_mentions
  on public.entity_mentions
  for all
  to authenticated
  using (
    exists (
      select 1
        from public.entities e
        join public.scenes s on s.id = entity_mentions.scene_id
        join public.volumes v on v.id = e.volume_id
       where e.id = entity_mentions.entity_id
         and s.volume_id = e.volume_id
         and v.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
        from public.entities e
        join public.scenes s on s.id = entity_mentions.scene_id
        join public.volumes v on v.id = e.volume_id
       where e.id = entity_mentions.entity_id
         and s.volume_id = e.volume_id
         and v.user_id = (select auth.uid())
    )
    and (
      dream_element_id is null
      or exists (
        select 1
          from public.dream_elements de
          join public.dreams d on d.id = de.dream_id
         where de.id = entity_mentions.dream_element_id
           and d.user_id = (select auth.uid())
           and d.volume_id = (
             select e.volume_id
               from public.entities e
              where e.id = entity_mentions.entity_id
           )
      )
    )
    and (
      passage_id is null
      or exists (
        select 1
          from public.passages p
          join public.scenes s on s.id = p.scene_id
         where p.id = entity_mentions.passage_id
           and p.user_id = (select auth.uid())
           and s.id = entity_mentions.scene_id
      )
    )
  );

create policy p_narrative_memory
  on public.narrative_memory
  for all
  to authenticated
  using (
    exists (
      select 1
        from public.volumes v
       where v.id = narrative_memory.volume_id
         and v.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
        from public.volumes v
       where v.id = narrative_memory.volume_id
         and v.user_id = (select auth.uid())
    )
  );

create policy p_link_decisions
  on public.link_decisions
  for all
  to authenticated
  using (
    exists (
      select 1
        from public.volumes v
        join public.dreams d on d.id = link_decisions.dream_id
       where v.id = link_decisions.volume_id
         and d.volume_id = v.id
         and v.user_id = (select auth.uid())
         and d.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
        from public.volumes v
        join public.dreams d on d.id = link_decisions.dream_id
       where v.id = link_decisions.volume_id
         and d.volume_id = v.id
         and v.user_id = (select auth.uid())
         and d.user_id = (select auth.uid())
    )
  );

-- Generation telemetry is service-role only. No client policy is intentional.
alter table public.generation_runs enable row level security;

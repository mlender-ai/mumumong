create type public.volume_status as enum (
  'active',
  'completable',
  'completing',
  'completed'
);

create type public.volume_format as enum ('short', 'novella');
create type public.adaptation_level as enum ('faithful', 'balanced', 'free');
create type public.writing_style as enum ('plain', 'lyrical', 'cinematic');
create type public.narrative_voice as enum (
  'third_person_past',
  'first_person_past'
);
create type public.dream_status as enum (
  'queued',
  'processing',
  'in_manuscript',
  'archived_only',
  'failed'
);
create type public.dream_clarity as enum ('fragment', 'partial', 'vivid');
create type public.element_type as enum (
  'person',
  'place',
  'object',
  'event',
  'emotion',
  'sensory'
);
create type public.passage_origin as enum ('D', 'C', 'U');
create type public.scene_kind as enum (
  'prologue',
  'dream',
  'interlude',
  'ending'
);
create type public.placement_kind as enum (
  'continuation',
  'motif',
  'interlude',
  'fragment_attach',
  'standalone'
);
create type public.job_status as enum ('queued', 'running', 'done', 'failed');
create type public.job_type as enum (
  'extract',
  'link',
  'plan',
  'write',
  'validate',
  'commit',
  'remember',
  'link_patch'
);

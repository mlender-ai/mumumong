-- Disposable database ONLY. Minimal Supabase auth contracts for local SQL tests.
-- Does not model hosted Auth, PostgREST or operational scheduling.
create schema auth;
create schema extensions;
create table auth.users (
  id uuid primary key, instance_id uuid, aud text, role text, email text,
  confirmation_token text, recovery_token text, email_change_token_new text,
  email_change text, raw_app_meta_data jsonb, raw_user_meta_data jsonb,
  is_anonymous boolean default false, created_at timestamptz, updated_at timestamptz
);
alter table auth.users add column encrypted_password text;
alter table auth.users add column email_confirmed_at timestamptz;
alter table auth.users add column is_super_admin boolean;
create table auth.identities (
  provider_id text, user_id uuid references auth.users(id), identity_data jsonb,
  provider text, last_sign_in_at timestamptz, created_at timestamptz, updated_at timestamptz
);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;
create function auth.role() returns text language sql stable as $$
  select nullif(current_setting('request.jwt.claim.role', true), '');
$$;
create function auth.jwt() returns jsonb language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claims', true), '')::jsonb, '{}'::jsonb);
$$;
grant usage on schema public, auth, extensions to anon, authenticated, service_role;
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;
create extension if not exists pgcrypto with schema extensions;
create extension if not exists pgtap with schema extensions;

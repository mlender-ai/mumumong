#!/usr/bin/env bash
# Isolated PostgreSQL contract checks; never migrate/reset the existing app DB.
set -euo pipefail
cd "$(dirname "$0")/.."
MM_TEST_CONTAINER="supabase_db_mumumong"
MM_TEST_DATABASE="mumumong_settings_fixture_$$"
docker exec "$MM_TEST_CONTAINER" createdb -U postgres "$MM_TEST_DATABASE"
trap 'docker exec "$MM_TEST_CONTAINER" dropdb -U postgres --force "$MM_TEST_DATABASE"' EXIT
sql() { docker exec -i "$MM_TEST_CONTAINER" psql -U postgres -d "$MM_TEST_DATABASE" -v ON_ERROR_STOP=1 -At; }
sql < tool/settings_test_bootstrap.sql > /dev/null
for migration_file in supabase/migrations/*.sql; do
  [[ "$migration_file" == *0017_generation_settings.sql ]] && break
  if [[ "$migration_file" == *0007_triggers_rpc.sql ]]; then
    # pg_cron is bound to the cluster's postgres DB. Do not install or schedule
    # it in this disposable DB; operational recovery belongs to P4-3.
    sed '/^create extension if not exists pg_cron/,$d' "$migration_file" | sql > /dev/null
  else
    sql < "$migration_file" > /dev/null
  fi
done
sql < supabase/seed.sql > /dev/null
sql <<'SQL' > /dev/null
insert into jobs (id,user_id,volume_id,dream_id,type,status,idempotency_key,payload)
values ('17171717-1717-4171-8171-171717171799','11111111-1111-4111-8111-111111111111',
  '22222222-2222-4222-8222-222222222222','33333333-3333-4333-8333-333333333333',
  'extract','running',gen_random_uuid(),'{"legacy_fixture":true}');
create table settings_upgrade_audit as select
  (select md5(string_agg(to_jsonb(p)::text,',' order by id)) from passages p) as manuscript_hash,
  (select md5(string_agg(to_jsonb(d)::text,',' order by id)) from dreams d) as dreams_hash;
SQL
sql < supabase/migrations/0017_generation_settings.sql > /dev/null
MM_UPGRADE_REPORT="$(sql <<'SQL'
begin;
set local search_path=public,extensions;
select plan(5);
select is((select count(*)::int from volume_settings_versions),1,'existing volume receives v1 history');
select is((select (payload->>'generation_settings_version')::int from jobs where id='17171717-1717-4171-8171-171717171799'),1,'existing running job receives v1 snapshot');
select ok((select (payload->>'legacy_fixture')::boolean from jobs where id='17171717-1717-4171-8171-171717171799'),'migration preserves existing job payload');
select is((select md5(string_agg(to_jsonb(p)::text,',' order by id)) from passages p),(select manuscript_hash from settings_upgrade_audit),'migration leaves full manuscript and U rows unchanged');
select is((select md5(string_agg(to_jsonb(d)::text,',' order by id)) from dreams d),(select dreams_hash from settings_upgrade_audit),'migration leaves full dream rows unchanged');
select * from finish();
rollback;
SQL
)"
if [[ "$MM_UPGRADE_REPORT" == *'not ok '* ]]; then
  printf '%s\n' "$MM_UPGRADE_REPORT"
  exit 1
fi
printf 'settings upgrade: 5 assertions passed\n'
sql <<'SQL' > /dev/null
delete from jobs where id='17171717-1717-4171-8171-171717171799';
drop table settings_upgrade_audit;
SQL
sql < supabase/migrations/0019_completed_books.sql > /dev/null
sql < supabase/migrations/0020_explicit_conflict_response.sql > /dev/null
for sql_test_file in supabase/tests/*_test.sql; do
  if [[ "$sql_test_file" == *rpc_test.sql ]]; then
    # Run every non-cron RPC assertion, without changing the canonical test.
    MM_SQL_REPORT="$(sed -e 's/select plan(70);/select plan(69);/' \
      -e '/select is((select count(\*)::integer from cron.job where jobname/d' "$sql_test_file" | sql)"
  else
    MM_SQL_REPORT="$(sql < "$sql_test_file")"
  fi
  if [[ "$MM_SQL_REPORT" == *'not ok '* || "$MM_SQL_REPORT" == *'# Looks like'* ]]; then
    printf '%s\n' "$MM_SQL_REPORT"
    exit 1
  fi
  MM_ASSERTIONS="$(printf '%s\n' "$MM_SQL_REPORT" | rg -c '^ok [0-9]+')"
  printf '%s: %s assertions passed\n' "$sql_test_file" "$MM_ASSERTIONS"
done
printf 'Unverified: pg_cron scheduling, hosted Auth/PostgREST and real-model execution.\n'

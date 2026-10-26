begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();

-- Invented fixtures only. No production account or manuscript is used.
insert into auth.users (id, email, is_anonymous) values
  ('17171717-1717-4171-8171-171717171711', 'settings-owner@example.test', false),
  ('17171717-1717-4171-8171-171717171712', 'settings-other@example.test', false);
insert into public.volumes (id,user_id,vol_no,narrative_voice) values
  ('17171717-1717-4171-8171-171717171721','17171717-1717-4171-8171-171717171711',1,'first_person_past');
insert into public.profiles (user_id, consent_version, consented_at, age_confirmed)
values ('17171717-1717-4171-8171-171717171711',1,now(),true);
insert into public.dreams (id,user_id,volume_id,input_mode,raw_text) values
  ('17171717-1717-4171-8171-171717171731','17171717-1717-4171-8171-171717171711','17171717-1717-4171-8171-171717171721','text','Synthetic settings dream');
insert into public.scenes (id,volume_id,order_key,kind,placement) values
  ('17171717-1717-4171-8171-171717171741','17171717-1717-4171-8171-171717171721','a0','dream','standalone');
insert into public.passages (id,user_id,scene_id,order_key,text,origin,locked,created_by) values
  ('17171717-1717-4171-8171-171717171751','17171717-1717-4171-8171-171717171711','17171717-1717-4171-8171-171717171741','a0','Synthetic user paragraph','U',true,'user');

set local role authenticated;
select set_config('request.jwt.claim.sub','17171717-1717-4171-8171-171717171711',true);
select set_config('request.jwt.claim.role','authenticated',true);
select is((select settings_version from volumes limit 1),1,'new volume starts at v1');
select is((select count(*)::int from volume_settings_versions),1,'initial immutable history is seeded');
select is((user_update_generation_settings('17171717-1717-4171-8171-171717171721',1,'17171717-1717-4171-8171-171717171761','faithful','cinematic','third_person_past')->>'version')::int,2,'owner edits preferences using CAS');
select throws_ok($$select user_update_generation_settings('17171717-1717-4171-8171-171717171721',1,'17171717-1717-4171-8171-171717171762','balanced','plain','first_person_past')$$,
  'PT409','settings_version_conflict','stale base conflicts');
select is((user_update_generation_settings('17171717-1717-4171-8171-171717171721',1,'17171717-1717-4171-8171-171717171761','faithful','cinematic','third_person_past')->>'version')::int,2,'lost ACK retry returns original receipt');
select throws_ok($$select user_update_generation_settings('17171717-1717-4171-8171-171717171721',1,'17171717-1717-4171-8171-171717171761','balanced','plain','first_person_past')$$,
  '22023','settings mutation reused','same key cannot carry different preferences');
select is((select count(*)::int from volume_settings_versions),2,'duplicate request does not add a version');
select throws_ok($$update volumes set style='lyrical'$$,'55000','use user_update_generation_settings','direct preference write is blocked');
select throws_ok($$update volumes set settings_version=9$$,'55000','use user_update_generation_settings','direct version write is blocked');
select throws_ok($$insert into volume_settings_versions(volume_id,version,base_version,adaptation,style,narrative_voice)
  values ('17171717-1717-4171-8171-171717171721',9,0,'balanced','plain','first_person_past')$$,
  '42501','permission denied for table volume_settings_versions','client cannot forge history');
select throws_ok($$select user_update_generation_settings('17171717-1717-4171-8171-171717171721',null,gen_random_uuid(),'balanced','plain','first_person_past')$$,
  '22023','settings request required','null request fails closed');
select throws_ok($$insert into volumes(user_id,vol_no,status,settings_version)
  values ('17171717-1717-4171-8171-171717171711',2,'completed',5)$$,
  '22023','initial settings version must be one','initial version cannot be forged');

insert into jobs(id,user_id,volume_id,dream_id,type,idempotency_key,payload) values
  ('17171717-1717-4171-8171-171717171771','17171717-1717-4171-8171-171717171711','17171717-1717-4171-8171-171717171721','17171717-1717-4171-8171-171717171731','extract',gen_random_uuid(),
  '{"generation_settings_version":1,"generation_settings":{"version":1,"style":"forged"}}');
select is((select payload->'generation_settings'->>'style' from jobs where id='17171717-1717-4171-8171-171717171771'),'plain','historical pinned version is canonicalized; supplied values are ignored');
reset role;
update jobs set status='done' where id='17171717-1717-4171-8171-171717171771';
set local role authenticated;
insert into jobs(id,user_id,volume_id,dream_id,type,idempotency_key) values
  ('17171717-1717-4171-8171-171717171772','17171717-1717-4171-8171-171717171711','17171717-1717-4171-8171-171717171721','17171717-1717-4171-8171-171717171731','extract',gen_random_uuid());
select is((select (payload->>'generation_settings_version')::int from jobs where id='17171717-1717-4171-8171-171717171772'),2,'old clients without version pin current confirmed settings');
select throws_ok($$insert into jobs(user_id,volume_id,dream_id,type,idempotency_key,payload) values
  ('17171717-1717-4171-8171-171717171711','17171717-1717-4171-8171-171717171721','17171717-1717-4171-8171-171717171731','extract',gen_random_uuid(),'{"generation_settings_version":999}')$$,
  '22023','settings version unavailable','missing historical version is rejected');
select is((user_update_generation_settings('17171717-1717-4171-8171-171717171721',2,'17171717-1717-4171-8171-171717171763','balanced','lyrical','first_person_past')->>'version')::int,3,'next edit increments version');
select is((select payload->'generation_settings'->>'style' from jobs where id='17171717-1717-4171-8171-171717171772'),'cinematic','running job keeps old preferences after edit');
select ok((select text='Synthetic user paragraph' and locked and origin='U' from passages limit 1),'settings changes preserve locked U manuscript');

select set_config('request.jwt.claim.sub','17171717-1717-4171-8171-171717171712',true);
select is((select count(*)::int from volume_settings_versions),0,'another owner cannot read settings history');
select throws_ok($$select user_update_generation_settings('17171717-1717-4171-8171-171717171721',3,gen_random_uuid(),'balanced','plain','first_person_past')$$,
  '42501','volume unavailable','another owner cannot change settings');
reset role;
set local role anon;
select throws_ok($$select user_update_generation_settings('17171717-1717-4171-8171-171717171721',3,gen_random_uuid(),'balanced','plain','first_person_past')$$,
  '42501','permission denied for function user_update_generation_settings','unauthenticated caller cannot update');
reset role;
select set_config('request.jwt.claim.role','service_role',true);
select set_config('request.jwt.claims','{"role":"service_role"}',true);
select throws_ok($$update jobs set payload='{}' where id='17171717-1717-4171-8171-171717171771'$$,
  '55000','job settings are immutable','worker cannot remove pinned settings');
select lives_ok($$update jobs set payload=payload||'{"stage_fixture":true}' where id='17171717-1717-4171-8171-171717171771'$$,
  'worker can append stage data without changing snapshot');
insert into jobs(id,user_id,volume_id,dream_id,type,idempotency_key,payload)
select '17171717-1717-4171-8171-171717171773',user_id,volume_id,dream_id,'write',gen_random_uuid(),payload
  from jobs where id='17171717-1717-4171-8171-171717171771';
select is((select (payload->>'generation_settings_version')::int from jobs where id='17171717-1717-4171-8171-171717171773'),1,'downstream stage inherits original job version');
select throws_ok($$update volume_settings_versions set style='plain' where version=2$$,
  '55000','settings history is immutable','even service history updates fail');
update volumes set status='completed';
set local role authenticated;
select set_config('request.jwt.claim.sub','17171717-1717-4171-8171-171717171711',true);
select throws_ok($$select user_update_generation_settings('17171717-1717-4171-8171-171717171721',3,gen_random_uuid(),'balanced','plain','first_person_past')$$,
  '55000','volume settings closed','completed volume cannot change preferences');
select is((user_update_generation_settings('17171717-1717-4171-8171-171717171721',1,'17171717-1717-4171-8171-171717171761','faithful','cinematic','third_person_past')->>'version')::int,2,'old receipt stays idempotent even after later edit and completion');
select * from finish();
rollback;

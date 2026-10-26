begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select no_plan();
insert into auth.users(id,email) values('19191919-1919-4191-8191-191919191911','book-fixture@example.test');
insert into volumes(id,user_id,vol_no,format,target_mu,progress_mu) values
  ('19191919-1919-4191-8191-191919191921','19191919-1919-4191-8191-191919191911',1,'short',20,14);
insert into dreams(id,user_id,volume_id,input_mode,raw_text)
select ('19191919-1919-4191-8191-19191919193'||n)::uuid,'19191919-1919-4191-8191-191919191911',
  '19191919-1919-4191-8191-191919191921','text',E'Synthetic first line\nPRIVATE_SECOND_LINE_FIXTURE'
from generate_series(1,2)n;
insert into dream_elements(id,dream_id,type,label,salience,source)
select ('19191919-1919-4191-8191-19191919194'||n)::uuid,('19191919-1919-4191-8191-19191919193'||n)::uuid,
  'object','Synthetic recurring object','high','raw' from generate_series(1,2)n;
insert into scenes(id,volume_id,order_key,kind,placement,title,source_dream_ids)
select ('19191919-1919-4191-8191-19191919195'||n)::uuid,'19191919-1919-4191-8191-191919191921','a'||n,
  'dream','continuation','Synthetic chapter '||n,array['19191919-1919-4191-8191-191919191931'::uuid]
from generate_series(1,5)n;
insert into passages(id,user_id,scene_id,order_key,text,origin,locked,created_by)
select ('19191919-1919-4191-8191-19191919196'||n)::uuid,'19191919-1919-4191-8191-191919191911',
  ('19191919-1919-4191-8191-19191919195'||n)::uuid,'a0','Synthetic immutable U paragraph '||n,'U',true,'user'
from generate_series(1,5)n;
insert into entities(id,volume_id,type,role_name) values
  ('19191919-1919-4191-8191-191919191971','19191919-1919-4191-8191-191919191921','object','Synthetic recurring object');
insert into entity_mentions(entity_id,dream_element_id,scene_id,passage_id)
select '19191919-1919-4191-8191-191919191971',('19191919-1919-4191-8191-19191919194'||n)::uuid,
 ('19191919-1919-4191-8191-19191919195'||n)::uuid,('19191919-1919-4191-8191-19191919196'||n)::uuid from generate_series(1,2)n;
update dream_elements set dream_id='19191919-1919-4191-8191-191919191931' where id='19191919-1919-4191-8191-191919191942';
select ok(not book_completion_eligible('19191919-1919-4191-8191-191919191921'),'two mentions in only one dream do not qualify');
update dream_elements set dream_id='19191919-1919-4191-8191-191919191932' where id='19191919-1919-4191-8191-191919191942';
update volumes set progress_mu=13.9 where id='19191919-1919-4191-8191-191919191921';
select ok(not book_completion_eligible('19191919-1919-4191-8191-191919191921'),'below 70 percent does not qualify');
update volumes set progress_mu=14 where id='19191919-1919-4191-8191-191919191921';
insert into jobs(id,user_id,volume_id,dream_id,type,status,idempotency_key) values
 ('19191919-1919-4191-8191-191919191990','19191919-1919-4191-8191-191919191911','19191919-1919-4191-8191-191919191921','19191919-1919-4191-8191-191919191931','remember','queued',gen_random_uuid());
set local role authenticated;
select set_config('request.jwt.claim.sub','19191919-1919-4191-8191-191919191911',true);
select set_config('request.jwt.claim.role','authenticated',true);
select ok((preview_book_completion('19191919-1919-4191-8191-191919191921')->>'eligible')::boolean,'cross-dream recurrence and material/scene gates are met');
select ok((preview_book_completion('19191919-1919-4191-8191-191919191921')->>'busy')::boolean,'remember also blocks completion');
select throws_ok($$select complete_volume_book('19191919-1919-4191-8191-191919191921',gen_random_uuid(),'stale','Synthetic book',null)$$,
  '55000','generation pending','cannot freeze while any stage is pending');
reset role;
delete from jobs where id='19191919-1919-4191-8191-191919191990';
set local role authenticated;
select throws_ok($$select complete_volume_book('19191919-1919-4191-8191-191919191921',gen_random_uuid(),'stale','Synthetic book',null)$$,
  'PT409','manuscript changed','stale revision cannot complete');
create temporary table book_preview as select preview_book_completion('19191919-1919-4191-8191-191919191921') as value;
select is((complete_volume_book('19191919-1919-4191-8191-191919191921','19191919-1919-4191-8191-191919191981',
  (select value->>'revision' from book_preview),'Synthetic book','Synthetic author note')->>'version')::int,1,'owner freezes ordered text');
select is((select status::text from volumes where id='19191919-1919-4191-8191-191919191921'),'completed','volume and book commit together');
select is((select count(*)::int from completed_books),1,'one immutable book is created');
select is((complete_volume_book('19191919-1919-4191-8191-191919191921','19191919-1919-4191-8191-191919191981',
  (select value->>'revision' from book_preview),'Synthetic book','Synthetic author note')->>'version')::int,1,'lost ACK replay returns same book');
select throws_ok($$select complete_volume_book('19191919-1919-4191-8191-191919191921','19191919-1919-4191-8191-191919191981','stale','Changed title',null)$$,
  'PT409','book already completed','reused request cannot silently replace book');
select ok((select bool_and(p.text=bp->>'text' and p.locked and bp->>'origin'='U') from completed_books b,
  lateral jsonb_array_elements(b.snapshot->'scenes')s,lateral jsonb_array_elements(s->'passages')bp
  join public.passages p on p.id=(bp->>'id')::uuid),'all U text and provenance are unchanged');
select ok((select snapshot::text not like '%PRIVATE_SECOND_LINE_FIXTURE%' from completed_books),'appendix excludes full dream text');
select is(jsonb_array_length((select snapshot->'scenes' from completed_books)),5,'all chapters included in order');
select throws_ok($$insert into jobs(user_id,volume_id,dream_id,type,idempotency_key) values
  ('19191919-1919-4191-8191-191919191911','19191919-1919-4191-8191-191919191921','19191919-1919-4191-8191-191919191931','extract',gen_random_uuid())$$,
  '55000','volume generation closed','old clients cannot generate into completed volume');
create temporary table next_book_volume as select (start_volume_after_book('19191919-1919-4191-8191-191919191921')).*;
select is((select vol_no from next_book_volume),2,'next volume starts at VOL02');
select is((start_volume_after_book('19191919-1919-4191-8191-191919191921')).id,(select id from next_book_volume),'double next action reuses active volume');
select is((select count(*)::int from completed_books),1,'next volume preserves completed book');
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
select is((select count(*)::int from completed_books),0,'other owners cannot read books');
select throws_ok($$select preview_book_completion('19191919-1919-4191-8191-191919191921')$$,'42501','volume unavailable','other owner cannot preview');
reset role;
select throws_ok($$update completed_books set snapshot='{}'$$,'55000','completed book is immutable','even service update cannot replace book');
select lives_ok($$select delete_user_data('19191919-1919-4191-8191-191919191911')$$,'account deletion can cascade through immutable book');
select is((select count(*)::int from completed_books),0,'deleted account leaves no frozen copy');
select * from finish();
rollback;

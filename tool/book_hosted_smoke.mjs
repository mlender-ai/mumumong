// Disposable invented fixtures only; no user manuscript correction or logging.
import {execFileSync} from 'node:child_process';
import {randomUUID} from 'node:crypto';
import assert from 'node:assert/strict';
const project='dtdmfjovpufyyekdumga', base=`https://${project}.supabase.co`;
const keys=JSON.parse(execFileSync('supabase',['projects','api-keys','--project-ref',project,'--reveal','-o','json'],{encoding:'utf8',stdio:['ignore','pipe','ignore']}));
const pub=keys.find(k=>k.type==='publishable').api_key, secret=keys.find(k=>k.type==='secret').api_key;
const users=[];
async function request(path,{key=secret,token,method='GET',body}={}) {
  const response=await fetch(`${base}${path}`,{method,signal:AbortSignal.timeout(45000),headers:{apikey:key,'Content-Type':'application/json',Prefer:'return=representation',...(token?{Authorization:`Bearer ${token}`}:{})},...(body===undefined?{}:{body:JSON.stringify(body)})});
  const data=await response.json().catch(()=>null);
  return {status:response.status,data};
}
async function insert(table,body){const r=await request(`/rest/v1/${table}`,{method:'POST',body});assert.equal(r.status,201,`synthetic ${table} insert`);return r.data;}
async function account(){
  const email=`book-${randomUUID()}@example.test`,password=`${randomUUID()}Aa!`;
  const made=await request('/auth/v1/admin/users',{method:'POST',body:{email,password,email_confirm:true}});
  assert.equal(made.status,200);users.push(made.data.id);
  const login=await request('/auth/v1/token?grant_type=password',{key:pub,method:'POST',body:{email,password}});
  assert.equal(login.status,200);return {id:made.data.id,token:login.data.access_token};
}
try {
  const owner=await account(),other=await account();
  const rpc=(name,body,token=owner.token)=>request(`/rest/v1/rpc/${name}`,{key:pub,token,method:'POST',body});
  const volume=randomUUID(),dreams=[randomUUID(),randomUUID()],elements=[randomUUID(),randomUUID()],entity=randomUUID();
  await insert('volumes',{id:volume,user_id:owner.id,vol_no:1,format:'short',target_mu:20,progress_mu:14});
  const settings={p_volume_id:volume,p_expected_version:1,p_mutation_id:randomUUID(),p_adaptation:'balanced',p_style:'plain',p_narrative_voice:'first_person_past'};
  const changed=await rpc('user_update_generation_settings',settings);assert.equal(changed.status,200);assert.equal(changed.data.version,2);
  const settingsReplay=await rpc('user_update_generation_settings',settings);assert.equal(settingsReplay.data.version,2);
  const settingsConflict=await rpc('user_update_generation_settings',{...settings,p_mutation_id:randomUUID()});assert.equal(settingsConflict.status,409);assert.equal(settingsConflict.data.code,'PT409');
  await insert('dreams',dreams.map(id=>({id,user_id:owner.id,volume_id:volume,input_mode:'text',raw_text:'Invented paper star.\nSynthetic second line excluded.'})));
  await insert('dream_elements',elements.map((id,i)=>({id,dream_id:dreams[i],type:'object',label:'Synthetic paper star',salience:'high',source:'raw'})));
  const scenes=Array.from({length:5},()=>randomUUID()),passages=Array.from({length:5},()=>randomUUID());
  await insert('scenes',scenes.map((id,i)=>({id,volume_id:volume,order_key:`s${i}`,kind:'dream',placement:'continuation',title:`Synthetic chapter ${i}`,source_dream_ids:dreams})));
  await insert('passages',passages.map((id,i)=>({id,user_id:owner.id,scene_id:scenes[i],order_key:'p0',text:`Invented locked author paragraph ${i}.`,origin:'U',locked:true,created_by:'user'})));
  await insert('entities',{id:entity,volume_id:volume,type:'object',role_name:'Synthetic paper star'});
  await insert('entity_mentions',elements.map((id,i)=>({entity_id:entity,dream_element_id:id,scene_id:scenes[i],passage_id:passages[i]})));
  const preview=await rpc('preview_book_completion',{p_volume_id:volume});
  assert.equal(preview.status,200);assert.equal(preview.data.eligible,true);assert.equal(preview.data.busy,false);
  const denied=await rpc('preview_book_completion',{p_volume_id:volume},other.token);assert.equal(denied.status,403);
  const body={p_volume_id:volume,p_request_id:randomUUID(),p_revision:preview.data.revision,p_title:'Synthetic frozen book',p_author_note:'Invented author note'};
  const stale=await rpc('complete_volume_book',{...body,p_revision:'stale'});assert.equal(stale.status,409);
  const completed=await Promise.all([rpc('complete_volume_book',body),rpc('complete_volume_book',body)]);
  for(const r of completed){assert.equal(r.status,200);assert.equal(r.data.request_id,body.p_request_id);}
  assert.deepEqual(completed[0].data,completed[1].data);
  const book=completed[0].data;
  assert.equal(book.scenes.length,5);assert.ok(book.scenes.every(s=>s.passages.every(p=>p.locked&&p.origin==='U')));
  assert.ok(!JSON.stringify(book).includes('Synthetic second line excluded.'));
  const replaced=await rpc('complete_volume_book',{...body,p_title:'Changed'});assert.equal(replaced.status,409);
  const next=await Promise.all([rpc('start_volume_after_book',{p_volume_id:volume}),rpc('start_volume_after_book',{p_volume_id:volume})]);
  assert.equal(next[0].status,200);assert.equal(next[1].status,200);assert.equal(next[0].data.id,next[1].data.id);assert.equal(next[0].data.vol_no,2);
  const foreign=await request('/rest/v1/completed_books?select=volume_id',{key:pub,token:other.token});assert.equal(foreign.status,200);assert.equal(foreign.data.length,0);
  const owned=await request('/rest/v1/completed_books?select=snapshot',{key:pub,token:owner.token});assert.equal(owned.data.length,1);assert.deepEqual(owned.data[0].snapshot,book);
  const forged=await request('/rest/v1/completed_books',{key:pub,token:owner.token,method:'POST',body:{volume_id:next[0].data.id,user_id:owner.id,request_id:randomUUID(),snapshot:{}}});assert.equal(forged.status,403);
  const unauth=await request('/functions/v1/engine-worker',{key:pub,method:'POST',body:{}});assert.equal(unauth.status,403);
  console.log(JSON.stringify({hosted_settings_cas_idempotency_conflict:true,hosted_book_rpc_rls:true,concurrent_completion_deduplicated:true,concurrent_next_deduplicated:true,source_preserved:true,anonymous_worker_rejected:true}));
} finally {
  for(const id of users){
    const cleared=await request('/rest/v1/rpc/delete_user_data',{method:'POST',body:{p_user_id:id}});
    assert.ok([200,204].includes(cleared.status),'synthetic data cleanup');
    const deleted=await request(`/auth/v1/admin/users/${id}`,{method:'DELETE'});assert.equal(deleted.status,200,'synthetic account cleanup');
  }
  console.log(JSON.stringify({disposable_accounts_removed:users.length}));
}

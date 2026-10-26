// Invoke after migration0018. No secret is printed, saved, or passed in argv.
import {execFileSync} from 'node:child_process';
const project='dtdmfjovpufyyekdumga';
const run=(args,options={})=>execFileSync('supabase',args,{encoding:'utf8',stdio:['pipe','pipe','ignore'],...options});
try{
  run(['db','query','--linked',`do $$ begin
    if not exists(select 1 from vault.secrets where name='mumumong_worker_url') then
      perform vault.create_secret('https://${project}.supabase.co/functions/v1/engine-worker','mumumong_worker_url');
    end if;
  end $$;`,'-o','json']);
  const result=JSON.parse(run(['db','query','--linked',
    "select decrypted_secret as token from vault.decrypted_secrets where name='mumumong_worker_schedule_token'",'-o','json']));
  const token=result.rows?.[0]?.token;
  if(typeof token!=='string' || !/^[a-f0-9]{64}$/u.test(token))throw new Error('scheduler_token_invalid');
  run(['secrets','set','--project-ref',project,'--env-file','/dev/stdin'],{input:`WORKER_SCHEDULE_TOKEN=${token}\n`});
  console.log(JSON.stringify({project,worker_schedule_configured:true,secret_printed:false}));
}catch{console.error('Worker schedule provisioning failed; credentials were not printed.');process.exitCode=1;}

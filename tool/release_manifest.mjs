// Build provenance only. Private evaluation data and environment files are never read.
import {createHash} from 'node:crypto';
import {readdirSync,readFileSync,writeFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {join} from 'node:path';
const inputs=['lib','supabase/functions','supabase/migrations','web','assets','pubspec.yaml','pubspec.lock'];
const hash=createHash('sha256');
function scan(path){
  if(/(?:^|\/)(?:\.env[^/]*|\.vercel|node_modules|\.dart_tool)(?:\/|$)/u.test(path))return;
  let children;
  try{children=readdirSync(path);}catch{hash.update(path+'\0');hash.update(readFileSync(path));return;}
  for(const name of children.sort())scan(join(path,name));
}
for(const path of inputs)scan(path);
const source=hash.digest('hex');
if(process.argv[2]==='--hash'){process.stdout.write(source);}
else{
  const output=process.argv[2];if(!output)throw new Error('output_directory_required');
  const manifest={build_id:process.env.MUMUMONG_BUILD_ID??'local',source_sha256:source,
    git_head:execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim(),
    working_tree_dirty:execFileSync('git',['status','--porcelain'],{encoding:'utf8'}).trim().length>0,
    local_schema:5,server_migration:'0020',engine:'v10',created_at:new Date().toISOString()};
  writeFileSync(join(output,'release.json'),JSON.stringify(manifest,null,2)+'\n');
  console.log(JSON.stringify(manifest));
}

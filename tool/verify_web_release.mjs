// Compare exact compiled bytes, not a successful build message or cached URL.
import {readFileSync} from 'node:fs';
import {execFile} from 'node:child_process';
import {promisify} from 'node:util';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const run=promisify(execFile),root='build/live-trial',url=process.argv[2];
const protectedDeployment=process.argv.includes('--protected');
if(!url?.startsWith('https://'))throw Error('https_deployment_required');
const paths=['index.html','install.html','main.dart.js','flutter_bootstrap.js','manifest.json',
 'icons/Icon-192.png','icons/Icon-512.png','sqlite3.wasm','drift_worker.js',
 'assets/FontManifest.json','assets/fonts/MaterialIcons-Regular.otf',
 'assets/assets/fonts/Pretendard-Regular.otf','assets/assets/fonts/Pretendard-Medium.otf',
 'assets/assets/fonts/MaruBuri-Regular.ttf','assets/assets/fonts/MaruBuri-Bold.ttf',
 'favicon.png','version.json','flutter.js','release.json',
 'flutter_service_worker.js','canvaskit/canvaskit.js','canvaskit/canvaskit.wasm',
 'canvaskit/chromium/canvaskit.js','canvaskit/chromium/canvaskit.wasm'];
const digest=b=>createHash('sha256').update(b).digest('hex');
const release=JSON.parse(readFileSync(`${root}/release.json`));
assert.match(readFileSync(`${root}/flutter_bootstrap.js`,'utf8'),/canvasKitBaseUrl/,
 'renderer must load from the same verified release');
assert.match(readFileSync(`${root}/index.html`,'utf8'),/pwa-startup-guard/,
 'startup failure must have a recoverable UI');
const fontManifest=JSON.parse(readFileSync(`${root}/assets/FontManifest.json`));
const startupFonts=fontManifest.flatMap(f=>f.fonts.map(x=>x.asset));
assert.ok(!startupFonts.some(p=>p.endsWith('MaruBuri-Bold.ttf')),'PDF font must not be eagerly downloaded');
const pdfBoldBytes=readFileSync(`${root}/assets/assets/fonts/MaruBuri-Bold.ttf`).length;
assert.ok(pdfBoldBytes>0,'PDF font remains bundled');
async function check(path){
 let bytes;
 if(protectedDeployment){
   try {bytes=(await run('vercel',['curl',`/${path}`,'--deployment',url,'--scope','mlender-ais-projects','--cwd',root,'--','--silent','--show-error','--fail'],{encoding:'buffer',maxBuffer:32*1024*1024})).stdout;}
   catch {throw Error(`protected_asset_fetch_failed:${path}`);}
 }else{
   const response=await fetch(`${url.replace(/\/$/u,'')}/${path}?build=${release.build_id}`,{cache:'no-store',signal:AbortSignal.timeout(30000)});
   assert.equal(response.status,200,`public ${path}`);bytes=Buffer.from(await response.arrayBuffer());
 }
 assert.equal(digest(bytes),digest(readFileSync(`${root}/${path}`)),`compiled bytes ${path}`);
}
for(let i=0;i<paths.length;i+=3)await Promise.all(paths.slice(i,i+3).map(check));
console.log(JSON.stringify({url,protected_deployment:protectedDeployment,verified_resource_count:paths.length,pdf_bold_font_deferred_bytes:pdfBoldBytes,build_id:release.build_id,source_sha256:release.source_sha256}));

'use strict';
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const origin=process.env.STAGING_BACKEND_URL;
let u;try{u=new URL(origin);}catch{throw Error('Set STAGING_BACKEND_URL to the real HTTPS staging API origin');}
if(u.origin!==origin||u.protocol!=='https:'||u.username||u.password||!u.hostname.includes('staging')||u.hostname==='semantropic-trivia.onrender.com')throw Error('Unsafe staging API origin');
const root=__dirname,source=path.join(root,'site'),output=path.join(root,'publish');
const manifest=JSON.parse(fs.readFileSync(path.join(root,'tested-site.manifest.json'),'utf8'));
for(const entry of manifest.files){const bytes=fs.readFileSync(path.join(source,entry.path));if(crypto.createHash('sha256').update(bytes).digest('hex').toUpperCase()!==entry.sha256)throw Error('Source SHA-256 mismatch: '+entry.path);}
fs.cpSync(source,output,{recursive:true});
fs.writeFileSync(path.join(output,'staging-config.js'),'window.SEMANTROPIC_STAGING_BACKEND = '+JSON.stringify(origin)+';'+String.fromCharCode(10));
const html=fs.readFileSync(path.join(source,'index.html'),'utf8');
if(!html.includes(manifest.backend))throw Error('Expected CSP backend missing');
fs.writeFileSync(path.join(output,'index.html'),html.replaceAll(manifest.backend,origin));
const files=[];
function walk(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){const file=path.join(dir,e.name);if(e.isDirectory())walk(file);else{const bytes=fs.readFileSync(file);files.push({path:path.relative(output,file).split(path.sep).join('/'),bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex').toUpperCase()});}}}
walk(output);fs.writeFileSync(path.join(output,'deployment-sha256.json'),JSON.stringify({backend:origin,files},null,2));
console.log('Staging package configured; Unity binary files preserved; SHA-256 manifest generated.');
#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import http from "node:http";
import {spawnSync} from "node:child_process";
import {fileURLToPath} from "node:url";

const FILE=path.resolve(fileURLToPath(import.meta.url));
const ROOT=path.dirname(FILE);
const AUDIT=path.join(ROOT,".cb-ai","luasmith-audit.ndjson");
const REFS=path.join(ROOT,"tools","luasmith","references.json");
const BACKUPS=path.join(ROOT,".cb-ai","v4-backups");
const MAX_OPS=8;
const MAX_FILE=60000;
const MAX_SNAPSHOT=900000;
const SENSITIVE=new Set([".env",".env.local",".env.production","secret","secrets","credential","credentials","token","tokens","password","private_key"]);
const ALLOWED_ROOTS=new Set(["README.md","default.project.json","rokit.toml",".gitignore","package.json","luasmith-v4.js","luasmith-v4-web.html"]);
const ALLOWED_PREFIXES=["src/","tools/","docs/",".github/"];
const EXT=new Set([".lua",".luau",".py",".json",".toml",".yml",".yaml",".md",".js"]);
const SEED=[
 ["core-loops","Roblox Core Loops","https://create.roblox.com/docs/production/game-design/core-loops","official"],
 ["onboarding","Roblox Onboarding","https://create.roblox.com/docs/production/game-design/onboarding","official"],
 ["discovery","Roblox Discovery","https://create.roblox.com/docs/discovery","official"],
 ["analytics","Roblox Analytics","https://create.roblox.com/docs/production/analytics","official"],
 ["custom-events","Roblox Custom Events","https://create.roblox.com/docs/production/analytics/custom-events","official"],
 ["custom-fields","Roblox Analytics Custom Fields","https://create.roblox.com/docs/production/analytics/custom-fields","official"],
 ["liveops","Roblox LiveOps","https://create.roblox.com/docs/production/game-design/liveops-essentials","official"],
 ["configs","Roblox Experience Configs","https://create.roblox.com/docs/cloud/guides/configs","official"],
 ["experiments","Roblox Experiments","https://create.roblox.com/docs/production/experiments","official"],
 ["performance","Roblox Performance","https://create.roblox.com/docs/performance-optimization","official"],
 ["luau-execution","Roblox Luau Execution","https://create.roblox.com/docs/cloud/reference/features/luau-execution","official"],
 ["players","Roblox Players","https://create.roblox.com/docs/reference/engine/classes/Players","official"],
 ["analytics-service","Roblox AnalyticsService","https://create.roblox.com/docs/reference/engine/classes/AnalyticsService","official"],
 ["engine","Roblox Engine Reference","https://create.roblox.com/docs/reference/engine","official"],
 ["datastores","Roblox Data Stores","https://create.roblox.com/docs/cloud-services/data-stores","official"],
 ["social","Roblox Social Design","https://create.roblox.com/docs/production/game-design/design-for-roblox","official"],
 ["strongest","The Strongest Battlegrounds","https://www.roblox.com/games/10449761463/The-Strongest-Battlegrounds","game"],
 ["doors","DOORS","https://www.roblox.com/games/6516141723/DOORS","game"],
 ["place-ci-cd","Roblox Place CI/CD Demo","https://github.com/Roblox/place-ci-cd-demo","official-github"]
].map(x=>({id:x[0],title:x[1],url:x[2],sourceType:x[3],retrievedAt:null,content:""}));

function dirs(){fs.mkdirSync(path.dirname(AUDIT),{recursive:true});fs.mkdirSync(BACKUPS,{recursive:true});fs.mkdirSync(path.dirname(REFS),{recursive:true});}
function read(p){try{return fs.readFileSync(p,"utf8");}catch{return null;}}
function normalize(p){return String(p||"").replaceAll("\\\\","/").replace(/^\\/+/, "");}
function sensitive(p){return normalize(p).toLowerCase().split("/").some(x=>SENSITIVE.has(x)||x.includes("password")||x.includes("credential"));}
function allowed(p){const n=normalize(p);return !!n&&!n.split("/").includes("..")&&!sensitive(n)&&(ALLOWED_ROOTS.has(n)||ALLOWED_PREFIXES.some(x=>n.startsWith(x)));}
function hash(s){let h=2166136261;for(const c of s){h^=c.charCodeAt(0);h=Math.imul(h,16777619);}return(h>>>0).toString(16);}
function audit(e){dirs();fs.appendFileSync(AUDIT,JSON.stringify({timestamp:new Date().toISOString(),...e})+"\\n");}
function walk(root,out=[]){for(const e of fs.readdirSync(root,{withFileTypes:true})){if([".git",".cb-ai","build","node_modules","__pycache__"].includes(e.name))continue;const p=path.join(root,e.name);if(e.isDirectory())walk(p,out);else if(EXT.has(path.extname(e.name).toLowerCase()))out.push(p);}return out;}
function tokenize(s){return String(s).toLowerCase().split(/[^a-z0-9_]+/).filter(Boolean);}

class RepositoryIndex{
 constructor(root){this.root=root;this.files=[];}
 build(){let total=0;for(const p of walk(this.root).sort()){const rel=normalize(path.relative(this.root,p));if(!allowed(rel))continue;const text=read(p);if(text===null)continue;const body=text.length>MAX_FILE?text.slice(0,MAX_FILE)+"\\n[truncated]":text;this.files.push({path:rel,size:text.length,hash:hash(text),text:body});total+=body.length;if(total>=MAX_SNAPSHOT)break;}return this;}
 search(q,limit=12){const terms=tokenize(q);return this.files.map(f=>{const words=tokenize(f.path+" "+f.text);let score=0;for(const t of terms)if(words.includes(t))score+=2;if(f.path.toLowerCase().includes(String(q).toLowerCase()))score+=4;return{score,f};}).filter(x=>x.score>0).sort((a,b)=>b.score-a.score).slice(0,limit).map(x=>x.f);}
 symbols(){return this.files.map(f=>({path:f.path,requires:[...f.text.matchAll(/require\\s*\\(([^)]+)\\)/g)].map(m=>m[1]),remotes:[...f.text.matchAll(/ensureRemote\\(\\s*["']([^"']+)["']/g)].map(m=>m[1]),attributes:[...f.text.matchAll(/SetAttribute\\(\\s*["']([^"']+)["']/g)].map(m=>m[1])}));}
}

class ReferenceEngine{
 constructor(file){this.file=file;this.records=[];}
 load(){dirs();let stored=[];const raw=read(this.file);if(raw)try{stored=JSON.parse(raw);}catch{}const map=new Map(stored.map(x=>[x.id,x]));for(const x of SEED)if(!map.has(x.id))map.set(x.id,x);this.records=[...map.values()];return this;}
 save(){dirs();fs.writeFileSync(this.file,JSON.stringify(this.records,null,2));}
 search(q,limit=8){const terms=tokenize(q);return this.records.map(r=>{const text=(r.title+" "+r.url+" "+r.content).toLowerCase();let score=r.sourceType==="official"?1:0;for(const t of terms)if(text.includes(t))score+=2;return{score,r};}).filter(x=>x.score>1).sort((a,b)=>b.score-a.score).slice(0,limit).map(x=>x.r);}
 async sync(limit=24){for(const r of this.records.slice(0,limit)){try{const res=await fetch(r.url,{redirect:"follow",signal:AbortSignal.timeout(12000)});if(res.ok){r.content=(await res.text()).slice(0,50000);r.retrievedAt=new Date().toISOString();}}catch{}}this.save();return this.records;}
}

class OperationPolicy{
 static validate(ops){if(!Array.isArray(ops)||ops.length>MAX_OPS)throw new Error("invalid operation list");return ops.map(op=>{if(!op||!["create_file","update_file","create_test","update_test","update_docs"].includes(op.action))throw new Error("unsupported operation");const p=normalize(op.path);if(!allowed(p))throw new Error("blocked path: "+p);if(typeof op.content!=="string"||op.content.length>300000)throw new Error("invalid content");if(/\bloadstring\s*\(/i.test(op.content))throw new Error("dynamic code loading blocked");if(/<<<<<<<|=======|>>>>>>>/.test(op.content))throw new Error("merge marker blocked");if(/(OPENAI_API_KEY|GEMINI_API_KEY|HUGGINGFACE_API_KEY|ROBLOX_API_KEY|roblosecurity|private_key)/i.test(op.content))throw new Error("secret-like content blocked");return{...op,path:p};});}
}

function apply(ops){const runId=Date.now().toString(36);const backup=path.join(BACKUPS,runId);fs.mkdirSync(backup,{recursive:true});const applied=[];for(const op of OperationPolicy.validate(ops)){const target=path.resolve(ROOT,op.path);if(target!==ROOT&&!target.startsWith(ROOT+path.sep))throw new Error("path escape");if(fs.existsSync(target)){const b=path.join(backup,op.path);fs.mkdirSync(path.dirname(b),{recursive:true});fs.copyFileSync(target,b);}fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,op.content,"utf8");applied.push(op.path);}audit({type:"mutation",runId,paths:applied});return{runId,backup,applied};}

class ProviderRouter{
 available(){return["ollama","openai","gemini","huggingface","offline"].filter(p=>p==="offline"||p==="ollama"||(p==="openai"&&process.env.OPENAI_API_KEY)||(p==="gemini"&&process.env.GEMINI_API_KEY)||(p==="huggingface"&&process.env.HUGGINGFACE_API_KEY));}
 model(p){return p==="openai"?(process.env.OPENAI_MODEL||"gpt-5"):p==="gemini"?(process.env.GEMINI_MODEL||"gemini-2.5-flash"):p==="huggingface"?(process.env.HF_MODEL||"Qwen/Qwen3-32B"):p==="ollama"?(process.env.OLLAMA_MODEL||"qwen2.5-coder:7b"):"offline";}
 async post(url,body,headers={}){const res=await fetch(url,{method:"POST",headers:{"content-type":"application/json",...headers},body:JSON.stringify(body),signal:AbortSignal.timeout(60000)});const raw=await res.text();if(!res.ok)throw new Error("HTTP "+res.status+": "+raw.slice(0,600));return JSON.parse(raw);}
 async generate(prompt,opts={}){const order=opts.provider?[opts.provider,"offline"]:this.available();const errors=[];for(const p of order){try{let text="";if(p==="ollama"){const d=await this.post((process.env.OLLAMA_URL||"http://127.0.0.1:11434")+"/api/generate",{model:opts.model||this.model(p),prompt,stream:false});text=d.response||"";}else if(p==="openai"){const d=await this.post((process.env.OPENAI_BASE_URL||"https://api.openai.com/v1")+"/responses",{model:opts.model||this.model(p),input:prompt,max_output_tokens:8000},{authorization:"Bearer "+process.env.OPENAI_API_KEY});text=d.output_text||"";}else if(p==="gemini"){const m=opts.model||this.model(p);const d=await this.post("https://generativelanguage.googleapis.com/v1beta/models/"+encodeURIComponent(m)+":generateContent?key="+encodeURIComponent(process.env.GEMINI_API_KEY),{contents:[{role:"user",parts:[{text:prompt}]}],generationConfig:{temperature:.1,maxOutputTokens:8000}});text=(d.candidates?.[0]?.content?.parts||[]).map(x=>x.text||"").join("\\n");}else if(p==="huggingface"){const d=await this.post("https://router.huggingface.co/v1/chat/completions",{model:opts.model||this.model(p),messages:[{role:"user",content:prompt}],max_tokens:8000,temperature:.1},{authorization:"Bearer "+process.env.HUGGINGFACE_API_KEY});text=d.choices?.[0]?.message?.content||"";}else{text="Offline mode: repository analysis only.";}if(text)return{provider:p,model:opts.model||this.model(p),text};}catch(e){errors.push(p+": "+e.message);}}throw new Error(errors.join(" | "));}
}

class LuaSmith{
 constructor(root=ROOT){this.root=root;this.index=new RepositoryIndex(root).build();this.refs=new ReferenceEngine(path.join(root,"tools","luasmith","references.json")).load();this.providers=new ProviderRouter();}
 context(q){return{files:this.index.search(q),references:this.refs.search(q),symbols:this.index.symbols()};}
 prompt(q,mode){const c=this.context(q);const refs=c.references.map(r=>"REF "+r.id+"\\n"+r.title+"\\n"+r.url+"\\n"+(r.content||"").slice(0,7000)).join("\\n\\n");const files=c.files.map(f=>"FILE "+f.path+"\\n"+f.text).join("\\n\\n");return"You are LuaSmith 4 for Collision Battlestar. Repository truth beats memory. Verify Roblox APIs. Server authoritative. Never invent IDs, files, remotes, attributes, prices or secrets. Never delete files. Repair mode returns JSON only. Max 8 complete-file operations. MODE="+mode+"\\nREQUEST="+q+"\\nREFERENCES="+refs+"\\nFILES="+files;}
 async ask(q,o={}){const r=await this.providers.generate(this.prompt(q,"answer"),o);audit({type:"query",request:q,provider:r.provider,model:r.model});return r;}
 async repair(q,o={}){const r=await this.providers.generate(this.prompt(q,"repair"),o);const obj=parseJson(r.text);if(!obj)throw new Error("invalid repair JSON");const ops=OperationPolicy.validate(obj.operations||[]);audit({type:"repair",request:q,provider:r.provider,model:r.model,status:obj.status||"unknown",paths:ops.map(x=>x.path)});return o.apply?Object.assign(obj,apply(ops),{provider:r.provider,model:r.model}):Object.assign(obj,{operations:ops,applied:false,provider:r.provider,model:r.model});}
 validate(){const commands=[["python-validator",["python3","tools/validate_project.py"]],["git-diff-check",["git","diff","--check"]],["luau-tests",["luau","tools/tests/run.luau"]],["rojo-build",["rojo","build","default.project.json","--output","build/LuaSmith_validation.rbxl"]]];const results=commands.map(x=>{const p=spawnSync(x[1][0],x[1].slice(1),{cwd:this.root,encoding:"utf8",timeout:120000,maxBuffer:2000000});return{name:x[0],exitCode:p.status??127,output:(p.stdout||"")+(p.stderr||"")};});const ok=results.every(x=>x.exitCode===0);audit({type:"validation",ok,results:results.map(x=>({name:x.name,exitCode:x.exitCode}))});return{ok,results};}
}

function parseJson(text){const raw=String(text||"").trim();try{return JSON.parse(raw);}catch{}const a=raw.indexOf("{"),b=raw.lastIndexOf("}");if(a>=0&&b>a)try{return JSON.parse(raw.slice(a,b+1));}catch{}return null;}
function sendJson(res,status,data){res.writeHead(status,{"content-type":"application/json; charset=utf-8"});res.end(JSON.stringify(data));}
async function startServer(port){const agent=new LuaSmith();http.createServer(async(req,res)=>{try{if(req.method==="GET"&&req.url==="/health")return sendJson(res,200,{status:"ok",version:"4.0.0",files:agent.index.files.length,references:agent.refs.records.length,providers:agent.providers.available()});if(req.method==="GET"&&req.url==="/context")return sendJson(res,200,{files:agent.index.files.map(x=>({path:x.path,size:x.size,hash:x.hash})),symbols:agent.index.symbols()});if(req.method==="GET"&&req.url==="/audit")return sendJson(res,200,{audit:read(AUDIT)||""});if(req.method==="POST"&&["/search","/generate","/repair"].includes(req.url)){const chunks=[];for await(const c of req)chunks.push(c);const body=JSON.parse(Buffer.concat(chunks).toString("utf8")||"{}");const q=String(body.query||body.description||"");if(req.url==="/search")return sendJson(res,200,agent.context(q));if(req.url==="/generate")return sendJson(res,200,await agent.ask(q,body));return sendJson(res,200,await agent.repair(q,body));}return sendJson(res,404,{error:"not found"});}catch(e){return sendJson(res,500,{error:e.message});}}).listen(port,"127.0.0.1",()=>console.log("LuaSmith 4 listening on http://127.0.0.1:"+port));}
export{LuaSmith,RepositoryIndex,ReferenceEngine,OperationPolicy,ProviderRouter,normalize,allowed,parseJson};

if(process.argv[1]&&path.resolve(process.argv[1])===FILE){dirs();const args=process.argv.slice(2);const agent=new LuaSmith();if(args[0]==="--web")await startServer(Number(args[1]||3000));else if(args[0]==="--sync-refs"){await agent.refs.sync(Number(args[1]||24));console.log("Synced "+agent.refs.records.length+" references.");}else if(args[0]==="--validate"){const r=agent.validate();for(const x of r.results)console.log(x.name+": "+x.exitCode+"\n"+x.output);process.exitCode=r.ok?0:1;}else if(args[0]==="--repair"){const q=args.slice(1).filter(x=>x!=="--apply").join(" ");console.log(JSON.stringify(await agent.repair(q,{apply:args.includes("--apply")}),null,2));}else{const q=args.join(" ");if(!q)console.log("LuaSmith 4 — --web 3000 | --sync-refs | --validate | --repair <request> [--apply]");else console.log((await agent.ask(q)).text);}}
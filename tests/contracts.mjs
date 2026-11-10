import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {pathToFileURL} from 'node:url';
const home = path.resolve(process.argv[2]);
const modules = path.join(home,'profiles','desktop','node_modules');
let checks=0;
const h=(type,props,...children)=>({type,props,children});
for (const [name,file,id,label] of [
  ['dsh-gemini-voice','client.js','gemini-voice','语音'],
  ['dsh-local-llm-controller','lib/client.js','local-llm','本地模型'],
  ['dsh-computer-use-win','mcp/client.js','computer-use','电脑操控']
]) {
  let exported;
  const entries=[];
  const icon=()=>null;
  const sandbox={console,document:{querySelector:()=>null,createElement:()=>({dataset:{},remove(){}}),head:{appendChild(){}}},
    window:{__ModuleLoader__:{load:({factory})=>{exported=factory(name=>name==='react'?{createElement:h}:name==='@deepseek-ai/dsh-client-ui-primitives'?{IconMicrophoneOutlineRegular:icon}:{})}}}};
  vm.runInNewContext(fs.readFileSync(path.join(modules,name,file),'utf8'),sandbox);
  const ctx={slots:{inject:(_,fn)=>fn(),register:(entry,component)=>{entries.push({entry,component});return()=>{}}},
    configForms:{get:()=>({mutate(){}})},locale:{register:()=>()=>{},bind:()=>key=>key==='nav'?label:key},
    effect:fn=>name==='dsh-computer-use-win'?undefined:fn()};
  ctx.inject=(names,fn)=>{if(names.length===1&&names[0]==='configForms')return fn(ctx);};
  exported.apply(ctx);
  const nav=entries.filter(x=>x.entry.name==='settings.section'&&x.entry.id===id);
  const icons=entries.filter(x=>x.entry.name==='settings.section.icon'&&x.entry.id===id);
  assert.equal(nav.length,1);assert.equal(icons.length,1);
  assert.equal(nav[0].entry.label(),label); // text label must not contain another icon
  assert.ok(icons[0].component({size:20,active:true}));
  checks+=4;
}
const notify=await import(pathToFileURL(path.join(modules,'dsh-voice-notify','index.js')));
let spoken=0;
const tracker=notify.createTracker(()=>spoken++);
const session={header:{id:'test'}};
function turn(s,reason='completed',user=true){
  tracker.event(s,{type:'turn/start',data:{turn:1}});
  if(user)tracker.event(s,{type:'user/message',data:{source:{kind:'user'}}});
  const end={type:'turn/end',data:{turn:1,reason:{kind:reason}}};
  tracker.event(s,end);tracker.event(s,end);
}
turn(session);turn(session,'cancelled');turn(session,'completed',false);
turn({header:{id:'child',origin:'subagent'}});
assert.equal(spoken,1);checks++;
const ghost=fs.readFileSync(path.join(modules,'dsh-suggest-ghost','lib','client.js'),'utf8');
assert.match(ghost,/text-shadow\s*:\s*none/);checks++;
const storage=await import(pathToFileURL(path.join(modules,'dsh-gemini-voice','storage.mjs')));
assert.equal(storage.configDirectory('win32',{DSH_HOME:home,DSH_GEMINI_VOICE_HOME:path.join(home,'gemini-voice')},'unused'),path.join(home,'gemini-voice'));checks++;
console.log(JSON.stringify({passed:true,checks,coverage:['plain navigation labels','official icon slots','completion speech de-duplication','no-glow Ghost patch']}));

import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {pathToFileURL} from 'node:url';
import {createRequire} from 'node:module';
const home = path.resolve(process.argv[2]);
const modules = path.join(home,'profiles','desktop','node_modules');
let checks=0;
const h=(type,props,...children)=>({type,props,children});
for (const [name,file,id,label] of [
  ['dsh-gemini-voice','client.js','gemini-voice','语音'],
  ['dsh-local-llm-controller','lib/client.js','local-llm','本地模型'],
  ['dsh-computer-use-win','mcp/client.js','computer-use','电脑操控'],
  ['dsh-voice-router','client.js','voice-router','语音路由'],
  ['dsh-whale-desktop-integration','client.js','whale-desktop','虚拟宠物']
]) {
  let exported;
  const entries=[];
  const icon=()=>null;
  const sandbox={console,document:{querySelector:()=>null,querySelectorAll:()=>[],documentElement:{lang:'zh'},createElement:()=>({dataset:{},remove(){}}),head:{appendChild(){},append(){}}},
    navigator:{language:'zh'},fetch:async()=>({ok:true,json:async()=>({client:{loaded:true}})}),
    setInterval:()=>0,clearInterval(){},setTimeout:()=>0,clearTimeout(){},
    window:{__ModuleLoader__:{load:({factory})=>{exported=factory(name=>name==='react'?{createElement:h}:name==='@deepseek-ai/dsh-client-ui-primitives'?{IconMicrophoneOutlineRegular:icon}:{})}}}};
  vm.runInNewContext(fs.readFileSync(path.join(modules,name,file),'utf8'),sandbox);
  const ctx={slots:{inject:(_,fn)=>fn(),register:(entry,component)=>{entries.push({entry,component});return()=>{}}},
    get:()=>null,configForms:{get:()=>({mutate(){}})},locale:{register:()=>()=>{},bind:()=>key=>key==='nav'?label:key},
    effect:fn=>name==='dsh-computer-use-win'?undefined:fn()};
  ctx.inject=(names,fn)=>{if(names.length===1&&names[0]==='configForms')return fn(ctx);};
  exported.apply(ctx);
  const nav=entries.filter(x=>x.entry.name==='settings.section'&&x.entry.id===id);
  const icons=entries.filter(x=>x.entry.name==='settings.section.icon'&&x.entry.id===id);
  assert.equal(nav.length,1,name+' section');assert.equal(icons.length,1,name+' icon slot');
  assert.equal(nav[0].entry.label(),label); // text label must not contain another icon
  assert.ok(icons[0].component({size:20,active:true}));
  checks+=4;
  if (name==='dsh-whale-desktop-integration') {
    const client=fs.readFileSync(path.join(modules,name,file),'utf8');
    assert.doesNotMatch(client,/data-whale-pet-nav|new MutationObserver/);
    const version=JSON.parse(fs.readFileSync(path.join(modules,name,'package.json'),'utf8')).version;
    assert.equal(client.match(/const VERSION='([^']+)'/)[1],version);
    const host=fs.readFileSync(path.join(modules,name,'index.mjs'),'utf8');
    assert.equal(host.match(/export const version='([^']+)'/)[1],version);
    checks+=3;
  }
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
const require=createRequire(path.join(modules,'dsh-doublecheck','package.json'));
const {parse}=require('yaml');
const config=parse(fs.readFileSync(path.join(home,'profiles','desktop','cordis.patch.yml'),'utf8'));
const profile=JSON.parse(fs.readFileSync(path.join(home,'profiles','desktop','package.json'),'utf8'));
const lock=parse(fs.readFileSync(path.join(home,'profiles','desktop','pnpm-lock.yaml'),'utf8'));
const baseline=JSON.parse(fs.readFileSync(new URL('../manifest.json',import.meta.url),'utf8')).plugins;
for (const {name} of baseline) {
  const source=profile.dependencies[name].replace('file:./','file:');
  assert.match(source,/^file:pinned-packages\/[^/]+\.tgz$/);
  const locked=lock.importers['.'].dependencies[name];
  assert.equal(locked.specifier.replace('file:./','file:'),source,name+' declared source');
  assert.equal(locked.version.replace('file:./','file:').split('(')[0],source,name+' resolved source');
  checks+=3;
}
const evidence=await import(pathToFileURL(path.join(modules,'dsh-doublecheck','lib','domain','evidence.js')));
for (const [id,prefix] of [['doublecheck-guard',''],['doublecheck-grill','report']]) {
  const entry=config.find(x=>x.id===id)?.config??{};
  const key=name=>prefix?prefix+name[0].toUpperCase()+name.slice(1):name;
  const detection=evidence.compileDetection({testToolNames:['bash','pwsh'],guardTools:['edit','write'],
    testCommandPatterns:entry[key('testCommandPatterns')]??evidence.DEFAULT_TEST_COMMAND_PATTERNS,
    testFilePatterns:entry[key('testFilePatterns')]??evidence.DEFAULT_TEST_FILE_PATTERNS});
  for (const [command,expected] of [
    ['python -m unittest',true],['python -B -m unittest discover',true],
    ['python3 -m pytest',true],['python3.12 -B -m pytest tests',true],
    ['py -3 -m unittest',true],['py -3.12 -B -m pytest',true],
    ['pnpm test',true],['npm run test',true],['node --test',true],['pytest tests',true],
    ['python --version',false],['python -m pytest --help',false],
    ['python -m unittest -h',false],['python script.py',false]
  ]) {assert.equal(evidence.isTestCommand(command,detection),expected,id+': '+command);checks++;}
  for (const [file,expected] of [['test_task.py',true],['src/task_test.py',true],['tests/check.js',true],['src/task.py',false]]) {
    assert.equal(evidence.isTestFilePath(file,detection),expected,id+': '+file);checks++;
  }
}
console.log(JSON.stringify({passed:true,checks,coverage:['plain navigation labels','official icon slots','completion speech de-duplication','no-glow Ghost patch','Python test evidence in guard and report']}));

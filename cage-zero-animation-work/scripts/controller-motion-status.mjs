import {readFile} from 'node:fs/promises';
const cfg=JSON.parse(await readFile('C:/Users/Stang/AI-Tools/motion-tools/.local/animation-rpc.json','utf8'));
const r=await fetch(`http://127.0.0.1:${cfg.port}/tool`,{
 method:'POST',headers:{Authorization:`Bearer ${cfg.token}`,'Content-Type':'application/json'},
 body:JSON.stringify({name:'motion_studio_sessions',arguments:{}}),signal:AbortSignal.timeout(10000)
});
if(!r.ok)throw new Error(`RPC HTTP ${r.status}`);
const data=await r.json();
if(data.isError)throw new Error('Motion sessions tool failed');
const block=data.content?.find(x=>x.type==='text');
const sessions=block?JSON.parse(block.text):[];
console.log(JSON.stringify({rpcPort:cfg.port,pid:cfg.pid,sessions:sessions.map(s=>({
 id:s.id,online:s.online,placeId:s.snapshot?.placeId,
 activeRig:s.snapshot?.activeRig,selection:s.snapshot?.selection
}))}));

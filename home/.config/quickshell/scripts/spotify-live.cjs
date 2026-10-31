// Update only CSS variables through Spotify's local DevTools endpoint; never reload the player.
const fs=require('fs'),path=require('path');
(async()=>{
 const file=path.join(process.env.HOME,'.config/spicetify/Themes/impasto/color.ini');
 if(!fs.existsSync(file))return;
 function readPalette(){const palette={};let active=false;
 for(const line of fs.readFileSync(file,'utf8').split(/\r?\n/)){
  if(line.trim().startsWith('[')){active=line.trim()==='[base]';continue}
  const m=active&&line.match(/^([\w-]+)\s*=\s*([\da-fA-F]{6})\s*$/);if(m)palette[m[1]]='#'+m[2];
 }
 return palette;}
 const palette=readPalette();
 // Keep the next launch on the same palette as the currently running client.
 const target='/opt/spotify/Apps/xpui/colors.css';
 if(fs.existsSync(target)){
  let css=fs.readFileSync(target,'utf8');
  for(const [k,v] of Object.entries(palette)){
   const rgb=[1,3,5].map(i=>parseInt(v.slice(i,i+2),16)).join(',');
   css=css.replace(new RegExp('(--spice-'+k+':)\\s*[^;]+;','g'),'$1 '+v+';');
   css=css.replace(new RegExp('(--spice-rgb-'+k+':)\\s*[^;]+;','g'),'$1 '+rgb+';');
  }
  const tmp=target+'.impasto-tmp';fs.writeFileSync(tmp,css);fs.renameSync(tmp,target);
 }
 const tabs=await fetch('http://127.0.0.1:9222/json/list',{signal:AbortSignal.timeout(800)}).then(r=>r.json());
 const tab=tabs.find(t=>t.type==='page'&&/spotify|xpui/i.test(t.url));if(!tab?.webSocketDebuggerUrl)return;
 const expression=()=>`(()=>{const p=${JSON.stringify(readPalette())};for(const [k,v] of Object.entries(p)){document.documentElement.style.setProperty('--spice-'+k,v);const rgb=[1,3,5].map(i=>parseInt(v.slice(i,i+2),16)).join(',');document.documentElement.style.setProperty('--spice-rgb-'+k,rgb)} window.__impastoPalette=p;return Object.keys(p).length})()`;
 await new Promise((resolve,reject)=>{const w=new WebSocket(tab.webSocketDebuggerUrl);const timer=setTimeout(()=>{w.close();reject(Error('timeout'))},1500);w.onopen=()=>w.send(JSON.stringify({id:1,method:'Runtime.evaluate',params:{expression:expression(),returnByValue:true}}));w.onmessage=e=>{const r=JSON.parse(e.data);if(r.id===1){clearTimeout(timer);w.close();if(r.error)reject(Error(r.error.message));else{if(process.argv.includes('--verbose'))console.log('Updated live Spotify CSS variables:',r.result?.result?.value);resolve()}}};w.onerror=()=>{clearTimeout(timer);reject(Error('connection'))}});
})().catch(e=>{if(process.argv.includes('--verbose'))console.error(e.message);process.exitCode=0});

const fs = require('fs');
// Exported-Web story regression. Serve build/web over HTTP first.
// NODE_PATH=/path/to/node_modules node tests/web/prologue_story_check.cjs <url> [output]
// Optional: CHROMIUM_EXECUTABLE_PATH, STORY_WAIT_MS (default 60000 for assistance),
// STORY_STORE_MS (default 15000), STORY_CPU_THROTTLE (e.g. 6: a slow machine).
const path = require('path');
const {chromium} = require('playwright');
const url = process.argv[2];
if (!url) { console.error('usage: prologue_story_check.cjs <url> [output]'); process.exit(2); }
const output = process.argv[3] || path.join('build', 'story_check');
fs.mkdirSync(output, {recursive: true});
const waitMs = Number(process.env.STORY_WAIT_MS || 60000);
// How long the browser may take to store a kept page (IndexedDB sync).
const STORE_MS = Number(process.env.STORY_STORE_MS || 15000);
async function save(page) {
 return page.evaluate(() => new Promise(resolve => {
  const req=indexedDB.open('/userfs');
  req.onsuccess=()=>{
   const db=req.result;
   if(!db.objectStoreNames.length) return resolve(null);
   const store=db.transaction(db.objectStoreNames[0],'readonly').objectStore(db.objectStoreNames[0]);
   const keys=store.getAllKeys();
   keys.onsuccess=()=>{
    const k=keys.result.find(k=>String(k).endsWith('/owner_memory.json'));
    if(!k) return resolve(null);
    const get=store.get(k);
    get.onsuccess=()=>{try {resolve(JSON.parse(new TextDecoder().decode(get.result.contents)))} catch(e){resolve(null)}};
   };
  };
  req.onerror=()=>resolve(null);
 }));
}
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROMIUM_EXECUTABLE_PATH || undefined,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 try {
 const page=await browser.newPage({viewport:{width:1280,height:720}});
 const errors=[];
 page.on('pageerror',e=>errors.push(String(e)));
 await page.goto(url);
 await page.waitForFunction(()=>window.__lsf?.scene==='title',null,{timeout:120000});
 await page.mouse.click(640,360);
 await page.waitForTimeout(300);
 await page.keyboard.press('Escape');
 await page.waitForTimeout(200);
 await page.keyboard.press('Enter');
 // The memory card first (cold_open.gd): read through it with E.
 for(let i=0;i<14;i++){const sc=await page.evaluate(()=>window.__lsf?.scene||'');if(sc==='prologue')break;await page.waitForTimeout(1500);if(sc==='cold_open')await page.keyboard.press('e');}
 await page.waitForFunction(()=>window.__lsf?.scene==='prologue',null,{timeout:60000});
 await page.waitForTimeout(waitMs);
 await page.screenshot({path:path.join(output, 'story_before_input.png')});
 const throttle=Number(process.env.STORY_CPU_THROTTLE||1);
 if(throttle>1){const cdp=await page.context().newCDPSession(page);await cdp.send('Emulation.setCPUThrottlingRate',{rate:throttle});console.log('CPU throttled '+throttle+'x');}
 // Two separate questions (RD-1, 2026-10-31): did the game keep the page
 // (window.__lsf.read, set when the reader acknowledges it), and when did
 // the browser store it? Godot syncs user:// to IndexedDB asynchronously
 // after a write: measured 2.0-2.3 s at 8 fps and 4.7-5.0 s with the CPU
 // throttled 6x, so a fixed 2 s wait failed on storage, not on reading.
 const read=()=>page.evaluate(()=>window.__lsf?.story==='first_light'?(window.__lsf.read||0):0);
 async function stored(n){
  const t0=Date.now();
  while(Date.now()-t0<STORE_MS){
   const d=await save(page);const e=d?.journal?.find(e=>e.id==='festival:first_light');
   if(e && e.lines.length>=n) return {data:d,entry:e,ms:Date.now()-t0};
   await page.waitForTimeout(100);
  }
  return {data:await save(page),entry:null,ms:Date.now()-t0};
 }
 async function acknowledged(n){
  const t0=Date.now();
  while(Date.now()-t0<1500){ if(await read()>=n) return Date.now()-t0; await page.waitForTimeout(50); }
  return -1;
 }
 const timings={};
 await page.keyboard.press('e',{delay:160});
 timings.key_ack_ms=await acknowledged(1);
 if(timings.key_ack_ms<0) throw Error('The deliberate key was not acknowledged by the reader within 1.5 s');
 let got=await stored(1);
 timings.key_store_ms=got.ms;
 if(!got.entry) throw Error(`The first page was kept by the game but not stored in IndexedDB within ${STORE_MS} ms`);
 if(await read()!==1 || got.entry.lines.length!==1) throw Error('First deliberate key must keep exactly one page: '+JSON.stringify(got.entry));
 console.log(`PASS: keyboard acknowledges exactly one story page (reader ${timings.key_ack_ms} ms, stored ${timings.key_store_ms} ms)`);
 await page.screenshot({path:path.join(output, 'story_after_keyboard.png')});
 await page.mouse.click(640,650,{delay:160});
 timings.click_ack_ms=await acknowledged(2);
 if(timings.click_ack_ms<0) throw Error('The Continue click was not acknowledged by the reader within 1.5 s');
 got=await stored(2);
 timings.click_store_ms=got.ms;
 if(!got.entry) throw Error(`The reply was kept by the game but not stored in IndexedDB within ${STORE_MS} ms`);
 if(got.entry.lines.length!==2) throw Error('Continue click must keep the reply too: '+JSON.stringify(got.entry));
 console.log(`PASS: real Continue click acknowledges the second page (reader ${timings.click_ack_ms} ms, stored ${timings.click_store_ms} ms)`);
 const data=got.data, entry=got.entry;
 if(data.sessions!==0 || data.purge!==0) throw Error('Reading armed a punitive session');
 console.log('PASS: reading and journal writes cost no session or purge');
 if(errors.length) throw Error(errors.join('\n'));
 console.log('PASS: no browser page errors');
 fs.writeFileSync(path.join(output, 'result.json'),JSON.stringify({entry,timings,sessions:data.sessions,purge:data.purge,page_errors:errors},null,2));
 } finally {await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});

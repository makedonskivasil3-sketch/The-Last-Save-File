const fs = require('fs');
// Exported-Web story regression. Serve build/web over HTTP first.
// NODE_PATH=/path/to/node_modules node tests/web/prologue_story_check.cjs <url> [output]
// Optional: CHROMIUM_EXECUTABLE_PATH, STORY_WAIT_MS (default 60000 for assistance).
const path = require('path');
const {chromium} = require('playwright');
const url = process.argv[2];
if (!url) { console.error('usage: prologue_story_check.cjs <url> [output]'); process.exit(2); }
const output = process.argv[3] || path.join('build', 'story_check');
fs.mkdirSync(output, {recursive: true});
const waitMs = Number(process.env.STORY_WAIT_MS || 60000);
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
 await page.waitForFunction(()=>window.__lsf?.scene==='prologue',null,{timeout:60000});
 await page.waitForTimeout(waitMs);
 await page.screenshot({path:path.join(output, 'story_before_input.png')});
 await page.keyboard.press('e',{delay:160});
 await page.waitForTimeout(2000);
 let data=await save(page);
 let entry=data?.journal?.find(e=>e.id==='festival:first_light');
 if(!entry || entry.lines.length!==1) throw Error('First deliberate key must keep exactly one page: '+JSON.stringify(entry));
 console.log('PASS: keyboard acknowledges exactly one story page');
 await page.screenshot({path:path.join(output, 'story_after_keyboard.png')});
 await page.mouse.click(640,650,{delay:160});
 await page.waitForTimeout(2000);
 data=await save(page);
 entry=data?.journal?.find(e=>e.id==='festival:first_light');
 if(!entry || entry.lines.length!==2) throw Error('Continue click must keep the reply too: '+JSON.stringify(entry));
 console.log('PASS: real Continue click acknowledges the second page');
 if(data.sessions!==0 || data.purge!==0) throw Error('Reading armed a punitive session');
 console.log('PASS: reading and journal writes cost no session or purge');
 if(errors.length) throw Error(errors.join('\n'));
 console.log('PASS: no browser page errors');
 fs.writeFileSync(path.join(output, 'result.json'),JSON.stringify({entry,sessions:data.sessions,purge:data.purge,page_errors:errors},null,2));
 } finally {await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});

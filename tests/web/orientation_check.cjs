// Exported-Web touch/rotation regression. Chromium emulation is not iPhone QA.
// Serve build/web; run with Playwright available through NODE_PATH.
const fs = require('fs');
const path = require('path');
const {chromium} = require('playwright');
const url = process.argv[2];
const output = process.argv[3] || 'build/orientation_check';
if (!url) throw Error('usage: orientation_check.cjs <url> [output]');
fs.mkdirSync(output, {recursive:true});
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROMIUM_EXECUTABLE_PATH || undefined,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 try {
  const context=await browser.newContext({viewport:{width:1280,height:720},hasTouch:true});
  const page=await context.newPage();
  const errors=[];
  page.on('pageerror',e=>errors.push(String(e)));
  const state=()=>page.evaluate(()=>window.__lsf || {});
  await page.goto(url);
  await page.waitForFunction(()=>window.__lsf?.scene==='title',null,{timeout:120000});
  await page.mouse.click(640,360);
  await page.waitForTimeout(300);
  await page.keyboard.press('Escape');
  await page.waitForTimeout(200);
  await page.keyboard.press('Enter');
  for(let i=0;i<14;i++){
   const s=await state();
   if(s.scene==='prologue')break;
   await page.waitForTimeout(1500);
   if(s.scene==='cold_open')await page.keyboard.press('e');
  }
  await page.waitForFunction(()=>window.__lsf?.scene==='prologue',null,{timeout:60000});
  await page.keyboard.down('Escape');
  await page.waitForTimeout(4000);
  await page.keyboard.up('Escape');
  // Read the boot safely until the actual run is ready.
  for(let i=0;i<90;i++){
   const s=await state();
   if(s.scene==='game' && s.playable && !s.reading && s.stop==='')break;
   if(s.scene==='game' && s.reading)await page.keyboard.press('e');
   await page.waitForTimeout(500);
  }
  let ready=await state();
  if(ready.scene!=='game' || !ready.playable || ready.reading)throw Error('Run not ready: '+JSON.stringify(ready));
  await page.touchscreen.tap(80,540); // activate the virtual controls
  await page.waitForTimeout(1000);
  await page.setViewportSize({width:390,height:844});
  await page.waitForTimeout(3000);
  const held=await state();
  await page.waitForTimeout(2000);
  if((await state()).game_ms!==held.game_ms)throw Error('Gameplay advances behind portrait notice');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1500);
  if((await state()).game_ms!==held.game_ms)throw Error('Escape resumes behind portrait notice');
  await page.screenshot({path:path.join(output,'portrait_hold.png')});
  console.log('PASS: portrait freezes gameplay and refuses Resume');
  await page.setViewportSize({width:1280,height:720});
  await page.waitForTimeout(2000);
  if((await state()).game_ms!==held.game_ms)throw Error('Landscape auto-resumed an existing pause');
  console.log('PASS: landscape preserves the pause');
  await page.keyboard.press('Escape');
  await page.waitForFunction(ms=>(window.__lsf?.game_ms || 0)>ms+100,held.game_ms,{timeout:20000});
  console.log('PASS: explicit Resume returns control');
  if(errors.length)throw Error(errors.join('\n'));
  fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({build:process.env.GITHUB_SHA || 'local',held,resumed:await state(),page_errors:errors},null,2));
  console.log('PASS: no page errors (Chromium touch emulation; physical iPhone unverified)');
 } finally {await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});

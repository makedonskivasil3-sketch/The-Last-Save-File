// Real exported-Web touch events after title bootstrap. Native regressions
// separately disable mouse emulation. This is not physical-device coverage.
const fs=require('fs');
const path=require('path');
const {chromium}=require('playwright');
const url=process.argv[2];
const out=process.argv[3]||'build/touch_opening_check';
if(!url)throw Error('usage: touch_opening_check.cjs <url> [output]');
fs.mkdirSync(out,{recursive:true});
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROMIUM_EXECUTABLE_PATH||undefined,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 try{
  for(const mode of ['read-card','skip-card']){
   const context=await browser.newContext({viewport:{width:1280,height:720},hasTouch:true});
   const page=await context.newPage();
   const errors=[];page.on('pageerror',e=>errors.push(String(e)));
   await page.goto(url);
   await page.waitForFunction(()=>window.__lsf?.scene==='title',null,{timeout:120000});
   // Existing title bootstrap; everything from the card onwards is touch.
   await page.mouse.click(640,360);await page.waitForTimeout(300);
   await page.keyboard.press('Escape');await page.waitForTimeout(200);
   await page.keyboard.press('Enter');
   await page.waitForFunction(()=>window.__lsf?.scene==='cold_open',null,{timeout:60000});
   await page.screenshot({path:path.join(out,mode+'_card.png')});
   const cdp=await context.newCDPSession(page);
   async function down(x,y){await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x,y,id:1}]});}
   async function up(){await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});}
   if(mode==='read-card'){
    for(let i=0;i<14;i++){
     const scene=await page.evaluate(()=>window.__lsf?.scene);
     if(scene!=='cold_open')break;
     await page.touchscreen.tap(402,584);
     await page.waitForTimeout(1000);
    }
   }else{
    await down(874,584);
    await page.waitForFunction(()=>window.__lsf?.scene==='prologue',null,{timeout:30000});
    await up();
   }
   await page.waitForFunction(()=>window.__lsf?.scene==='prologue',null,{timeout:30000});
   console.log('PASS: '+mode+' reaches the festival through touch controls');
   await page.waitForTimeout(1000);
   await page.screenshot({path:path.join(out,mode+'_festival.png')});
   await down(1196,682);
   await page.waitForFunction(()=>window.__lsf?.scene==='game',null,{timeout:60000});
   await up();
   console.log('PASS: festival hold Skip reaches the game using touch');
   await page.screenshot({path:path.join(out,mode+'_game.png')});
   if(errors.length)throw Error(errors.join('\n'));
   fs.writeFileSync(path.join(out,mode+'.json'),JSON.stringify({mode,state:await page.evaluate(()=>window.__lsf),page_errors:errors},null,2));
   await context.close();
  }
  console.log('PASS: both opening routes, no page errors; physical phones unverified');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1});

// Touch-only run of the exported Web build (docs/INPUT_POLICY.md): no
// keyboard and no mouse, only CDP touch events on a phone-shaped landscape
// viewport. Start, read the memory card, hold its Skip, hold the festival's
// skip chip while a second finger holds the stick, read the boot with the
// on-screen E, pause and resume with II, rotate mid-press.
// Chromium touch emulation is NOT iPhone or Android certification.
//
// usage: NODE_PATH=... node tests/web/touch_input_check.cjs <url> [output]
//   TOUCH_CPU_THROTTLE=4   slow the page's CPU (a phone at a few FPS)
const fs = require('fs');
const path = require('path');
const {chromium} = require('playwright');
const url = process.argv[2];
const output = process.argv[3] || 'build/touch_input_check';
if (!url) throw Error('usage: touch_input_check.cjs <url> [output]');
fs.mkdirSync(output, {recursive: true});
const throttle = Number(process.env.TOUCH_CPU_THROTTLE || 1);

(async () => {
  const browser = await chromium.launch({executablePath: process.env.CHROMIUM_EXECUTABLE_PATH || undefined,
    args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader']});
  const results = [];
  const pass = (m) => { results.push('PASS: ' + m); console.log('PASS: ' + m); };
  let page;
  try {
    const context = await browser.newContext({viewport: {width: 844, height: 390}, hasTouch: true, isMobile: true, deviceScaleFactor: 2});
    page = await context.newPage();
    const errors = [];
    page.on('pageerror', e => errors.push(String(e)));
    const cdp = await context.newCDPSession(page);
    if (throttle > 1) await cdp.send('Emulation.setCPUThrottlingRate', {rate: throttle});
    const state = () => page.evaluate(() => window.__lsf || {});
    const sep = url.includes('?') ? '&' : '?';
    await page.goto(url + sep + 'playtest=1');
    await page.waitForFunction(() => window.__lsf?.scene === 'title' && window.__lsf?.start, null, {timeout: 180000});

    // Game space (640x360) -> page pixels, from the canvas's own box.
    const box = await page.evaluate(() => { const r = document.querySelector('canvas').getBoundingClientRect(); return {x: r.x, y: r.y, w: r.width, h: r.height}; });
    const k = Math.min(box.w / 640, box.h / 360);
    const ox = box.x + (box.w - 640 * k) / 2, oy = box.y + (box.h - 360 * k) / 2;
    const P = (gx, gy) => ({x: ox + gx * k, y: oy + gy * k});
    const touch = async (type, points) => cdp.send('Input.dispatchTouchEvent', {type,
      touchPoints: points.map(([id, gx, gy]) => ({...P(gx, gy), id, radiusX: 6, radiusY: 6, force: 1}))});
    const tap = async (gx, gy, ms = 60) => { await touch('touchStart', [[1, gx, gy]]); await page.waitForTimeout(ms); await touch('touchEnd', []); };
    const hold = async (gx, gy, ms) => { await touch('touchStart', [[1, gx, gy]]); await page.waitForTimeout(ms); await touch('touchEnd', []); };
    const E = [588, 292], II = [612, 90];

    // 1. Start, by touch.
    const s0 = await state();
    await tap(s0.start[0], s0.start[1]);
    await page.waitForFunction(() => window.__lsf?.scene === 'cold_open' || window.__lsf?.scene === 'prologue', null, {timeout: 30000});
    pass('a tap on Load Slot 1 starts the run');

    // 2. The memory card: read a line with a tap, then hold Skip.
    if ((await state()).scene === 'cold_open') {
      await page.waitForTimeout(2500);
      await tap(400, 200, 40);  // a 40 ms tap anywhere reads on
      await page.waitForTimeout(800);
      await page.screenshot({path: path.join(output, '1_memory_card.png')});
      await hold(91, 331, 1600);  // the Skip chip (ColdOpen.SKIP_RECT)
      await page.waitForFunction(() => window.__lsf?.scene === 'prologue', null, {timeout: 20000});
      pass('holding Skip on the memory card goes to the festival');
    }

    // 3. The festival: thumb on the stick (finger 1), other thumb holds skip (finger 2).
    await page.waitForTimeout(1500);
    await touch('touchStart', [[1, 120, 250]]);
    await touch('touchMove', [[1, 145, 250]]);
    await page.waitForTimeout(300);
    await touch('touchStart', [[1, 145, 250], [2, 598, 341]]);  // Prologue.SKIP_CHIP centre
    await page.waitForTimeout(400);
    await page.screenshot({path: path.join(output, '2_festival_skip_hold.png')});
    await page.waitForTimeout(1600);
    await touch('touchEnd', []);
    await page.waitForFunction(() => window.__lsf?.scene === 'game', null, {timeout: 60000});
    pass('the festival skip chip works while another finger holds the stick');

    // 4. The boot: read it with the on-screen E only.
    let taps = 0;
    for (let i = 0; i < 120; i++) {
      const s = await state();
      if (s.scene === 'game' && s.playable && !s.reading) break;
      if (s.scene === 'game' && s.reading) { await tap(E[0], E[1], [30, 70, 120, 250][taps % 4]); taps++; }
      await page.waitForTimeout(400);
    }
    const ready = await state();
    if (!(ready.scene === 'game' && ready.playable && !ready.reading)) throw Error('boot not read by touch: ' + JSON.stringify(ready));
    pass(`the boot was read with ${taps} taps of the on-screen E (30-250 ms)`);
    await page.screenshot({path: path.join(output, '3_room.png')});

    // 5. Pause and resume with II (a 120 ms tap; at 3-6 FPS give it time).
    await page.waitForTimeout(3000);
    const paused = async (want) => { for (let i = 0; i < 20; i++) { if (!!(await state()).paused === want) return true; await page.waitForTimeout(300); } return false; };
    await tap(II[0], II[1], 120);
    if (!(await paused(true))) throw Error('II did not pause');
    await page.waitForTimeout(1000);
    await tap(II[0], II[1], 120);
    if (!(await paused(false))) throw Error('II did not resume');
    pass('II pauses and resumes');

    // 6. Rotate mid-press: the press is cancelled, nothing acts on its release.
    await touch('touchStart', [[3, E[0], E[1]]]);
    await page.waitForTimeout(150);
    await page.setViewportSize({width: 390, height: 844});
    await page.waitForTimeout(1500);
    await touch('touchEnd', []);
    await page.setViewportSize({width: 844, height: 390});
    await page.waitForTimeout(1500);
    const trace = (await state()).trace || [];
    if (!trace.some(l => l.includes('rotated to portrait'))) throw Error('rotation did not cancel the press:\n' + trace.join('\n'));
    pass('rotating mid-press cancels it (traced)');

    const all = (await state()).trace || [];
    fs.writeFileSync(path.join(output, 'input_trace.txt'), all.join('\n') + '\n');
    const refusedFresh = all.filter(l => l.includes('REFUSED') && l.includes('stale'));
    pass(`input trace saved (${all.length} lines, ${refusedFresh.length} stale refusals)`);
    if (errors.length) throw Error('page errors: ' + errors.join('\n'));
    console.log(`TOUCH CHECK OK (cpu x${throttle})`);
  } catch (e) {
    console.error('FAIL: ' + e.message);
    if (page) { const t = await page.evaluate(() => (window.__lsf || {}).trace || []).catch(() => []); console.error('last input trace:\n' + t.slice(-15).join('\n')); }
    if (page) await page.screenshot({path: path.join(output, 'failure.png')}).catch(() => {});
    process.exitCode = 1;
  } finally {
    fs.writeFileSync(path.join(output, 'results.txt'), results.join('\n') + '\n');
    await browser.close();
  }
})();

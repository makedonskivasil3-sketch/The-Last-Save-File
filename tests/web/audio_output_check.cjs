// Real-browser check that the web export is AUDIBLE, not just "running".
//
// An AudioContext in the "running" state, or a play() call, proves nothing
// about output: in Godot 4.3's web Sample playback, buses created at runtime
// could leave every sound routed nowhere (docs/AUDIO_DIAGNOSIS.md). This
// check taps the page's real audio graph: anything the page connects to the
// speakers (AudioContext.destination) goes through an AnalyserNode first,
// and the post-mix level is measured on the title and in the first room.
//
// Usage (Playwright + a web export served over http):
//   NODE_PATH=/opt/node-tools/node_modules node tests/web/audio_output_check.cjs http://127.0.0.1:8765/index.html
// Exits 1 if the game is silent after a user gesture, or the page errors.
// Headless Chromium mixes to a fake output device; this measures what the
// game sends to the speakers, not what a person hears.
const { chromium } = require('playwright');
const url = process.argv[2];

// Before any page script: every AudioContext gets an analyser in front of
// its destination, and connections to the destination go through it.
const tapAudio = () => {
  const Real = window.AudioContext || window.webkitAudioContext;
  window.__taps = [];
  const realConnect = AudioNode.prototype.connect;
  AudioNode.prototype.connect = function (target, ...rest) {
    if (target instanceof AudioDestinationNode && this.__isTap !== true) {
      const tap = target.context.__tap;
      if (tap) return realConnect.call(this, tap, ...rest);
    }
    return realConnect.call(this, target, ...rest);
  };
  const Spy = function (...a) {
    const ctx = new Real(...a);
    const tap = ctx.createAnalyser();
    tap.fftSize = 4096;
    tap.__isTap = true;
    realConnect.call(tap, ctx.destination);
    ctx.__tap = tap;
    window.__taps.push(ctx);
    return ctx;
  };
  Spy.prototype = Real.prototype;
  window.AudioContext = Spy;
  window.webkitAudioContext = Spy;
};

// Sample the post-mix output for `ms`: RMS and peak (dBFS), the share of
// windows above -60 dBFS, clipping, and how the energy splits between lows
// (< 200 Hz) and the mids laptop speakers can play (300 Hz - 4 kHz).
async function measure(page, ms) {
  return page.evaluate((ms) => new Promise((resolve) => {
    const ctxs = window.__taps || [];
    if (!ctxs.length) return resolve({ contexts: 0 });
    const ctx = ctxs[ctxs.length - 1];
    const tap = ctx.__tap;
    const buf = new Float32Array(tap.fftSize);
    const spec = new Float32Array(tap.frequencyBinCount);
    let windows = 0, loud = 0, sumSq = 0, n = 0, peak = 0, clipped = 0, low = 0, mid = 0;
    const avg = new Float64Array(spec.length);
    const binHz = ctx.sampleRate / tap.fftSize;
    const t = setInterval(() => {
      tap.getFloatTimeDomainData(buf);
      let s = 0;
      for (const v of buf) { s += v * v; peak = Math.max(peak, Math.abs(v)); if (Math.abs(v) >= 0.999) clipped++; }
      sumSq += s; n += buf.length; windows++;
      if (Math.sqrt(s / buf.length) > 0.001) loud++;
      tap.getFloatFrequencyData(spec);
      for (let i = 1; i < spec.length; i++) {
        const hz = i * binHz, p = Math.pow(10, spec[i] / 10);
        if (hz < 200) low += p; else if (hz >= 300 && hz <= 4000) mid += p;
        avg[i] += p;
      }
    }, 50);
    setTimeout(() => {
      clearInterval(t);
      const db = (x) => x > 0 ? Math.round(20 * Math.log10(x) * 10) / 10 : -Infinity;
      // The strongest pitches above 300 Hz (the music box lives there:
      // A4 440 Hz and E5 659 Hz are its first two notes).
      const peaks = [];
      for (let i = 2; i < avg.length - 1; i++) {
        const hz = i * binHz;
        if (hz >= 300 && hz <= 2000 && avg[i] > avg[i - 1] && avg[i] >= avg[i + 1]) peaks.push([Math.round(hz), avg[i]]);
      }
      peaks.sort((a, b) => b[1] - a[1]);
      resolve({ state: ctx.state, contexts: ctxs.length, rms_dbfs: db(Math.sqrt(sumSq / Math.max(n, 1))), peak_dbfs: db(peak),
        audible_share: Math.round(100 * loud / Math.max(windows, 1)), clipped_samples: clipped,
        mid_to_low_db: low > 0 && mid > 0 ? Math.round(10 * Math.log10(mid / low) * 10) / 10 : null,
        top_pitches_hz: peaks.slice(0, 5).map((p) => p[0]) });
    }, ms);
  }), ms);
}

async function waitForGame(page) {
  await page.waitForFunction(() => {
    const s = document.querySelector('#status');  // Godot hides it once the engine runs
    return !s || getComputedStyle(s).display === 'none';
  }, null, { timeout: 120000 });
}

(async () => {
  const browser = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--autoplay-policy=user-gesture-required'] });
  const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
  await context.addInitScript(tapAudio);
  const errors = [];
  const page = await context.newPage();
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', (e) => errors.push(String(e)));
  await page.goto(url);
  await waitForGame(page);
  await page.waitForTimeout(1500);

  const results = {};
  results.before_gesture = await measure(page, 1500);
  // The first gesture (browsers only allow sound after one): a click on the title.
  await page.mouse.click(640, 360);
  await page.waitForTimeout(500);
  results.title = await measure(page, 6000);
  // The page's own report (web/sound_unlock.js) after that click.
  // (It reports without anything on screen: no badge may cover the subtitles.)
  results.sound_state = await page.evaluate(() => document.documentElement.dataset.soundState || 'missing');
  results.visible_badge = await page.evaluate(() => !!document.getElementById('sound-state'));
  // Start: Enter on Load Slot 1, then E through the opening.
  await page.keyboard.press('Escape');
  await page.waitForTimeout(300);
  await page.keyboard.press('Enter');
  // A first launch plays the opening film first: it must not be silent
  // either. Then hold E to skip it and measure the room itself.
  await page.waitForTimeout(3000);
  const scene = await page.evaluate(() => (window.__lsf || {}).scene || '');
  if (scene === 'opening') {
    results.opening = await measure(page, 5000);
    await page.keyboard.down('e');
    await page.waitForTimeout(1200);
    await page.keyboard.up('e');
  }
  // Through the memory card (cold_open: read with E), skip the festival
  // (held Esc), then read the boot text until the room is playable, and
  // measure the room itself.
  const st = () => page.evaluate(() => window.__lsf || {});
  let skipped = false;
  for (let i = 0; i < 160; i++) {
    const s = await st();
    if (s.scene === 'game' && s.playable) break;
    if (s.scene === 'cold_open') { await page.waitForTimeout(1500); await page.keyboard.press('e'); continue; }
    // One held Esc skips the festival; after that, read on with E like a
    // player. (Holding Esc again as the room appears opens the pause menu,
    // correctly: a paused game is silent, which this check would misread.)
    if (s.scene === 'prologue') {
      if (!skipped) { skipped = true; await page.keyboard.down('Escape'); await page.waitForTimeout(3000); await page.keyboard.up('Escape'); }
      else { await page.waitForTimeout(1200); await page.keyboard.press('e'); }
      continue;
    }
    if (s.scene === 'game' && s.reading) await page.keyboard.press('e');
    await page.waitForTimeout(600);
  }
  results.first_room_scene = (await st()).scene;
  results.first_room = await measure(page, 8000);

  for (const [k, v] of Object.entries(results)) console.log(`AUDIO ${k}: ${JSON.stringify(v)}`);
  console.log('PAGE ERRORS:', JSON.stringify(errors.slice(0, 10)));
  await browser.close();

  const audible = (r) => r && r.rms_dbfs > -70 && r.audible_share > 10;
  const failures = [];
  if (!audible(results.title) && !audible(results.first_room)) failures.push('silent after the first gesture (title and first room)');
  if (!audible(results.first_room)) failures.push('the first room is silent');
  if (results.opening && !audible(results.opening)) failures.push('the opening film is silent');
  if (results.title.clipped_samples > 0 || results.first_room.clipped_samples > 0) failures.push('clipping');
  if (results.sound_state !== 'running') failures.push(`the page says sound is "${results.sound_state}" after a click`);
  if (results.visible_badge) failures.push('a sound badge is on screen');
  if (errors.length) failures.push(`${errors.length} page error(s)`);
  // The title's music box must be among what reaches the speakers.
  const near = (hz, f) => Math.abs(hz - f) <= 12;
  const tp = results.title.top_pitches_hz || [];
  if (!tp.some((hz) => near(hz, 440) || near(hz, 659))) failures.push(`the title theme isn't heard (top pitches ${JSON.stringify(tp)})`);
  if (failures.length) { console.log('FAIL: ' + failures.join('; ')); process.exit(1); }
  console.log('PASS: the web build is audible after a gesture');
})().catch((e) => { console.error('FAILED', e); process.exit(1); });

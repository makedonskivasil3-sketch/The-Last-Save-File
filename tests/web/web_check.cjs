// Real-browser check of the web export (docs/RELEASE_READINESS.md). Fails
// (exit 1) unless every step holds:
//   1. the title loads with no page errors; a first launch plays the opening
//      film, and holding E skips it
//   2. Load Slot 1 reaches actual gameplay: the game reports a playable run
//      (window.__lsf, see scripts/web_state.gd) and Rue moves on real input
//   3. the open run is saved to IndexedDB (session open, last_exit "active")
//   4. closing the tab mid-run asks first, and counts as a quit on reopening
//      (quits +1, purge +1, last_exit "crash")
// Audio output is checked separately (audio_output_check.cjs).
//
// Usage (needs Playwright + a web export served over http):
//   NODE_PATH=/opt/node-tools/node_modules node tests/web/web_check.cjs http://127.0.0.1:8765/index.html [shot_dir]
// Screenshots go to shot_dir, $SHOT_DIR, or build/web_check (in that order).
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const url = process.argv[2];
if (!url) { console.error('usage: web_check.cjs <url> [shot_dir]'); process.exit(2); }
const shotDir = process.argv[3] || process.env.SHOT_DIR || path.join(__dirname, '..', '..', 'build', 'web_check');
fs.mkdirSync(shotDir, { recursive: true });

const failures = [];
const runErrors = [];
let lastPage = null;
// What a failed run leaves behind (CI uploads it): the failed checks, the
// game's last published state, the save, page errors and the build identity.
function writeDiagnostics(extra) {
  const d = Object.assign({ build: process.env.GITHUB_SHA || 'local', failures, page_errors: runErrors.slice(0, 20) }, extra);
  fs.writeFileSync(path.join(shotDir, 'diagnostics.json'), JSON.stringify(d, null, 2));
}
function expect(ok, what, detail) {
  console.log(`${ok ? 'PASS' : 'FAIL'}: ${what}${detail === undefined ? '' : '  ' + JSON.stringify(detail)}`);
  if (!ok) failures.push(what);
}

// Everything Godot saved under user://, read from IndexedDB (IDBFS).
async function readSave(page) {
  return page.evaluate(() => new Promise((resolve) => {
    const req = indexedDB.open('/userfs');
    req.onerror = () => resolve({ error: 'no /userfs db' });
    req.onsuccess = () => {
      const db = req.result;
      if (!db.objectStoreNames.length) return resolve({ error: 'empty db' });
      const tx = db.transaction(db.objectStoreNames[0], 'readonly');
      const store = tx.objectStore(db.objectStoreNames[0]);
      const keys = store.getAllKeys();
      keys.onsuccess = () => {
        const key = keys.result.find((k) => String(k).endsWith('/owner_memory.json'));
        if (!key) return resolve({ keys: keys.result.map(String) });
        const get = store.get(key);
        get.onsuccess = () => {
          const text = new TextDecoder().decode(get.result.contents);
          try { resolve({ key: String(key), data: JSON.parse(text) }); } catch (e) { resolve({ key: String(key), raw: text.slice(0, 200) }); }
        };
      };
    };
  }));
}

const state = (page) => page.evaluate(() => window.__lsf || null);

// Bounded wait for a game state, with what it last saw if it times out.
async function waitForState(page, pred, label, timeoutMs) {
  const t0 = Date.now();
  let last = null;
  while (Date.now() - t0 < timeoutMs) {
    last = await state(page);
    if (last && pred(last)) return last;
    await page.waitForTimeout(250);
  }
  throw new Error(`timed out after ${timeoutMs} ms waiting for ${label}; last state ${JSON.stringify(last)}`);
}

// Saved state can lag IDBFS sync: poll it until it matches (bounded).
async function waitForSave(page, pred, timeoutMs) {
  const t0 = Date.now();
  let last = null;
  while (Date.now() - t0 < timeoutMs) {
    last = await readSave(page);
    if (last && last.data && pred(last.data)) return last.data;
    await page.waitForTimeout(500);
  }
  return last && last.data ? last.data : last;
}

const pick = (d) => d ? { sessions: d.sessions, deaths: d.deaths, quits: d.quits, purge: d.purge, last_exit: d.last_exit } : d;

// Startup milestones (seconds since navigation) and the game's own frame
// rate at each: the 240 s allowance below is a bound, and these say where
// the time went, so a slow runner and a slow build can be told apart.
const timing = { marks: {}, fps: {}, holds: {} };
let navStart = 0;
async function mark(page, name) {
  const s = await state(page);
  timing.marks[name] = +((Date.now() - navStart) / 1000).toFixed(1);
  if (s && typeof s.fps === 'number') timing.fps[name] = s.fps;
}

(async () => {
  const browser = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--autoplay-policy=user-gesture-required'] });
  const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
  const errors = [];
  const watch = (p) => {
    p.on('console', (m) => { if (m.type() === 'error') { errors.push(m.text()); runErrors.push(m.text()); } });
    p.on('pageerror', (e) => { errors.push(String(e)); runErrors.push(String(e)); });
  };
  let page = await context.newPage();
  lastPage = page;
  watch(page);

  // 1. The title.
  navStart = Date.now();
  await page.goto(url);
  await waitForState(page, (s) => s.scene === 'title', 'the title screen', 120000);
  await mark(page, 'title');
  await page.screenshot({ path: path.join(shotDir, 'web_1_title.png') });
  expect(true, 'the title screen loads');

  // 2. Into the game: click (the browser's first gesture), Enter on Load Slot 1,
  // then E to read through the opening until Rue is the player's.
  await page.mouse.click(640, 360);
  await page.waitForTimeout(300);
  await page.keyboard.press('Escape');
  await page.waitForTimeout(200);
  await page.keyboard.press('Enter');
  // A fresh browser is a first launch: the opening film plays first, and
  // holding E skips it (scripts/ui/opening.gd).
  const first = await waitForState(page, (s) => s.scene === 'opening' || s.scene === 'game', 'the opening or the game', 60000);
  await mark(page, 'opening');
  expect(first.scene === 'opening', 'a first launch plays the opening film', first);
  if (first.scene === 'opening') {
    await page.screenshot({ path: path.join(shotDir, 'web_1b_opening.png') });
    await page.keyboard.down('e');
    await page.waitForTimeout(1200);
    await page.keyboard.up('e');
  }
  await waitForState(page, (s) => s.scene === 'game', 'the game scene', 60000);
  await mark(page, 'game_scene');
  expect(true, 'holding E skips into the run');
  const t0 = Date.now();
  let s = await state(page);
  // E moves text on; it is pressed only while text is open (pressing it into
  // the world starts interactions, which on a slow machine can keep a poll
  // from ever seeing the run playable).
  // The boot text and the materialise run at the game's frame rate, which on
  // a software-rendered CI runner can be a few frames a second: the same
  // build has needed from about 20 s to over 90 s here. The published state
  // doesn't change while a line is read, so a stall can't be told from slow
  // progress; the budget is simply generous.
  let presses = 0;
  while (!(s && s.playable) && Date.now() - t0 < 240000) {
    if (!s || s.reading) { await page.keyboard.press('e'); presses++; }
    await page.waitForTimeout(600);
    s = await state(page);
    if (s && s.reading && !('boot_text' in timing.marks)) await mark(page, 'boot_text');
    if (s && !s.reading && 'boot_text' in timing.marks && !('boot_text_done' in timing.marks)) await mark(page, 'boot_text_done');
    if (s && !s.playable && s.hold) timing.holds[s.hold] = (timing.holds[s.hold] || 0) + 1;
    if (s && typeof s.slowest_ms === 'number') timing.slowest_ms = Math.max(timing.slowest_ms || 0, s.slowest_ms);
    if (s && s.sfx_busy) timing.sfx_busy_polls = (timing.sfx_busy_polls || 0) + 1;
  }
  await mark(page, 'playable');
  timing.presses = presses;
  // The runner's speed doesn't change how much GAME time startup takes: on
  // software rendering the engine clamps each frame's step, so game time
  // runs several times slower than the wall clock (measured ~10x locally).
  // Game time to a playable run is the bound that catches a regression.
  if (s && typeof s.game_ms === 'number') {
    timing.game_ms = s.game_ms;
    timing.wall_ms = s.wall_ms;
    timing.clock_ratio = s.game_ms > 0 ? +(s.wall_ms / s.game_ms).toFixed(1) : null;
  }
  console.log('TIMING ' + JSON.stringify(timing));
  fs.writeFileSync(path.join(shotDir, 'timing.json'), JSON.stringify(timing, null, 2));
  expect(Boolean(s && s.playable), 'the run becomes playable (Rue under the player\'s control)', s);
  expect(typeof timing.game_ms === 'number' && timing.game_ms < 30000,
    'startup takes under 30 s of game time, whatever the runner\'s speed', { game_ms: timing.game_ms, wall_ms: timing.wall_ms });
  const before = await state(page);
  // Held until she has moved (software rendering here can run few physics
  // steps per second), bounded at 6 s: a stuck character still fails.
  await page.keyboard.down('ArrowRight');
  let after = before;
  let moved = 0;
  for (let waited = 0; waited < 6000 && moved <= 10; waited += 300) {
    await page.waitForTimeout(300);
    after = await state(page);
    moved = before && after ? Math.hypot(after.x - before.x, after.y - before.y) : 0;
  }
  await page.keyboard.up('ArrowRight');
  expect(moved > 10, 'Rue moves on real keyboard input', { before, after, moved });
  await page.screenshot({ path: path.join(shotDir, 'web_2_in_game.png') });

  // 3. The open run is in the save.
  const midRun = await waitForSave(page, (d) => d.last_exit === 'active' && d.sessions >= 1, 15000);
  expect(midRun && midRun.last_exit === 'active' && midRun.sessions === 1 && midRun.quits === 0 && midRun.purge === 0,
    'the open run is saved (session 1, last_exit active, no quits)', pick(midRun));

  // 4. Closing the tab mid-run asks first, and counts on reopening.
  // The game's side first: the leave guard is armed while the run is open.
  const armed = await page.evaluate(() => Boolean(window.__tlsfGuard && window.__tlsfRunning));
  expect(armed, 'the leave guard is armed mid-run (window.__tlsfRunning)');
  let asked = false;
  page.on('dialog', async (d) => { asked = d.type() === 'beforeunload'; await d.accept(); });
  await page.close({ runBeforeUnload: true });
  // The browser's dialog can arrive late on a slow machine: wait for it (bounded).
  for (let waited = 0; !asked && waited < 5000; waited += 250) await new Promise((r) => setTimeout(r, 250));
  expect(asked, 'closing the tab mid-run asks first (beforeunload)');
  page = await context.newPage();
  lastPage = page;
  watch(page);
  await page.goto(url);
  await waitForState(page, (st) => st.scene === 'title', 'the title after reopening', 120000);
  const reopened = await waitForSave(page, (d) => d.last_exit === 'crash', 15000);
  expect(reopened && reopened.quits === 1 && reopened.purge === 1 && reopened.last_exit === 'crash',
    'a tab closed mid-run counts as a quit (quits 1, purge 1, last_exit crash)', pick(reopened));
  await page.screenshot({ path: path.join(shotDir, 'web_3_reopened.png') });

  expect(errors.length === 0, 'no page or runtime errors', errors.slice(0, 10));
  if (failures.length) {
    // Evidence while the page is still open: what it looked like and knew.
    await page.screenshot({ path: path.join(shotDir, 'web_failure.png') }).catch(() => {});
    const st = await state(page).catch(() => null);
    const sv = await readSave(page).catch(() => null);
    writeDiagnostics({ state: st, save: sv && sv.data ? pick(sv.data) : sv });
  }
  await browser.close();
  console.log(`screenshots: ${shotDir}`);
  if (failures.length) {
    console.error(`FAILED: ${failures.length} check(s): ${failures.join('; ')}`);
    process.exit(1);
  }
  console.log('ALL WEB CHECKS PASSED');
})().catch(async (e) => {
  // A crash or a timeout: leave what's needed to diagnose it.
  console.error('FAILED', e.message || e);
  try {
    if (lastPage) {
      await lastPage.screenshot({ path: path.join(shotDir, 'web_failure.png') });
      const st = await state(lastPage).catch(() => null);
      const sv = await readSave(lastPage).catch(() => null);
      writeDiagnostics({ error: String(e.message || e), state: st, save: sv && sv.data ? pick(sv.data) : sv });
    } else {
      writeDiagnostics({ error: String(e.message || e) });
    }
  } catch (_) {}
  process.exit(1);
});

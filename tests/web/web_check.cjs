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
  await page.goto(url);
  await waitForState(page, (s) => s.scene === 'title', 'the title screen', 120000);
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
  expect(first.scene === 'opening', 'a first launch plays the opening film', first);
  if (first.scene === 'opening') {
    await page.screenshot({ path: path.join(shotDir, 'web_1b_opening.png') });
    await page.keyboard.down('e');
    await page.waitForTimeout(1200);
    await page.keyboard.up('e');
  }
  await waitForState(page, (s) => s.scene === 'game', 'the game scene', 60000);
  expect(true, 'holding E skips into the run');
  const t0 = Date.now();
  let s = await state(page);
  while (!(s && s.playable) && Date.now() - t0 < 90000) {
    await page.keyboard.press('e');
    await page.waitForTimeout(600);
    s = await state(page);
  }
  expect(Boolean(s && s.playable), 'the run becomes playable (Rue under the player\'s control)', s);
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
  let asked = false;
  page.on('dialog', async (d) => { asked = d.type() === 'beforeunload'; await d.accept(); });
  await page.close({ runBeforeUnload: true });
  await new Promise((r) => setTimeout(r, 1500));
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

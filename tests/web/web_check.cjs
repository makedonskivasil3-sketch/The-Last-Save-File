// Real-browser check of the web export (docs/RELEASE_READINESS.md):
//   1. audio starts after the first user gesture (browser autoplay rules)
//   2. the owner's memory is saved to IndexedDB and survives a reload
//   3. what a tab closed mid-run does to the purge count
//
// Usage (needs Playwright + a web export served over http):
//   NODE_PATH=/opt/node-tools/node_modules node tests/web/web_check.cjs http://127.0.0.1:8765/index.html
const { chromium } = require('playwright');
const url = process.argv[2];

// Wrap AudioContext so the page's contexts can be inspected.
const audioSpy = () => {
  const Real = window.AudioContext || window.webkitAudioContext;
  window.__ctxs = [];
  const Spy = function (...a) { const c = new Real(...a); window.__ctxs.push(c); return c; };
  Spy.prototype = Real.prototype;
  window.AudioContext = Spy;
  window.webkitAudioContext = Spy;
};

// Everything Godot saved under user://, read from IndexedDB (IDBFS).
async function readSave(page) {
  return page.evaluate(() => new Promise((resolve) => {
    const req = indexedDB.open('/userfs');
    req.onerror = () => resolve({ error: 'no /userfs db' });
    req.onsuccess = () => {
      const db = req.result;
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

async function waitForGame(page) {
  await page.waitForFunction(() => {
    const s = document.querySelector('#status');  // Godot removes it once the engine runs
    return !s || getComputedStyle(s).display === 'none';
  }, null, { timeout: 120000 });
  await page.waitForTimeout(4000); // the title builds its first sounds
}

const pick = (d) => d && d.data ? { sessions: d.data.sessions, deaths: d.data.deaths, quits: d.data.quits, purge: d.data.purge, last_exit: d.data.last_exit } : d;

(async () => {
  const browser = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--autoplay-policy=user-gesture-required'] });
  const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
  await context.addInitScript(audioSpy);
  const errors = [];
  let page = await context.newPage();
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', (e) => errors.push(String(e)));

  await page.goto(url);
  await waitForGame(page);
  await page.screenshot({ path: process.env.SHOT_DIR + '/web_1_title.png' });
  const before = await page.evaluate(() => (window.__ctxs || []).map((c) => c.state));
  console.log('AUDIO before any gesture:', JSON.stringify(before));

  // The first gesture: a click on the canvas, then Enter on "Load Slot 1".
  await page.mouse.click(640, 360);
  await page.waitForTimeout(500);
  const afterClick = await page.evaluate(() => (window.__ctxs || []).map((c) => c.state));
  console.log('AUDIO after the first click:', JSON.stringify(afterClick));

  await page.keyboard.press('Escape'); // in case the click focused something else
  await page.waitForTimeout(300);
  // Focus starts on Load Slot 1; Enter starts the session (first launch: the boot log, skipped with E).
  await page.keyboard.press('Enter');
  for (let i = 0; i < 14; i++) { await page.waitForTimeout(700); await page.keyboard.press('e'); }
  await page.waitForTimeout(3000);
  await page.screenshot({ path: process.env.SHOT_DIR + '/web_2_in_game.png' });
  await page.waitForTimeout(3000); // let IDBFS sync
  const midRun = await readSave(page);
  console.log('SAVE mid-run (session open):', JSON.stringify(pick(midRun)));

  // The player closes the tab mid-run: the browser should ask first.
  let asked = false;
  page.on('dialog', async (d) => { asked = d.type() === 'beforeunload'; await d.accept(); });
  await page.close({ runBeforeUnload: true });
  await new Promise((r) => setTimeout(r, 1500));
  console.log('CLOSING MID-RUN asks first (beforeunload):', asked);
  page = await context.newPage();
  page.on('pageerror', (e) => errors.push(String(e)));
  await page.goto(url);
  await waitForGame(page);
  await page.waitForTimeout(3000);
  const afterReopen = await readSave(page);
  console.log('SAVE after closing the tab and reopening:', JSON.stringify(pick(afterReopen)));
  await page.screenshot({ path: process.env.SHOT_DIR + '/web_3_reopened.png' });

  console.log('PAGE ERRORS:', JSON.stringify(errors.slice(0, 10)));
  await browser.close();
})().catch((e) => { console.error('FAILED', e); process.exit(1); });

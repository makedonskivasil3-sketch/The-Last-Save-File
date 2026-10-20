# Release readiness

**This section is the single authoritative statement of the project's current status.** Other docs (audits, pass notes) are history; where they disagree, this wins.

## Current status (2026-10-20): `claude/last-save-file-prototype-ljwuq4` (pass 4)

**Branches:** this branch carries [PR #7](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/pull/7) (stacked on [PR #6](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/pull/6)). Nothing is merged or deployed. `main` is unchanged.

**Environment:** Linux container, Godot 4.3, Mesa llvmpipe (no GPU), headless Chromium. No Windows, phones, gamepads or speakers.

### Is this a release candidate?

**No.** No critical functional failure is known. Unmet gates:
- **Human playtest:** none has run. A five-player round is ready (`PLAYTEST_PLAN.md`, "pass 4"); results pending.
- **Listening:** no one has listened to the mix. The browser check proves audio *output*, not that it sounds good.
- **Voice:** no recorded performances ship. Spoken lines use the device's system speech or the procedural voice; the generated pilot (`narration_review/`, untracked) is unlicensed and now excluded from every export preset.
- **Real hardware:** no Windows launch, no real-GPU frame times, no physical controllers or phones.

### What the game is now

| Area | State | Evidence |
|---|---|---|
| Characters | Illustrated vector figures and matching portrait busts for the whole cast, Pip and the shed body included | Visual inspection of tour screenshots |
| Places | Shared `Decor` kit, baked backdrops; Archive floor redone as flagstones in pass 4; system spaces keep their deliberate look | Visual inspection; per-area review in `VISUAL_DIRECTION.md` |
| Type | Inter (OFL) for world and UI, DejaVu Sans Mono for the owner's system text; licences in Credits and in exports | `test_fonts`, `test_polish` |
| Screen | Clean by default; CRT optional; corruption tied to awareness and events; UI above effects | Screenshots; earlier tests |
| Threats | Line of sight blocked by solids; cone drawn from the same rays | `test_threat_fairness` |
| Onboarding | One lesson at a time; awareness before glitches; tap vs hold explicit; tips persist until read; tips yield to danger, the act card and the prompt | `test_onboarding`, `test_first_minutes` |
| Recovery | Pause says it's safe; quit says what it costs, keeps and loses; death card says what carries over and the purge count; How to Play in-run | `test_onboarding`, `test_menus` |
| Scenes and sound state | Scenes hold the owner; stop cleanly if the run ends; muffles tracked per source; reset per run | `test_moment_safety` |

### Verification (this pass)

| Check | Result |
|---|---|
| Full suite | **405 passed, 0 failed** (923 s) |
| Ending bots | **4 of 4 reached their exact endings**: escape, message, escape at purge 3, wren |
| Web export | Built; pck 2.9 MB; contains the font licences, no review audio |
| Browser checks (headless Chromium) | `audio_output_check`: audible after a gesture, no clipping, no page errors. `web_check`: closing mid-run asks first and counts as a quit |
| Visual inspection | Developer screenshots at 1280×720: title, room, square, archive, bin, house, out of bounds, Edge, tips, prompt, pause, quit, help, death card, Large text. Not inspected by anyone else |
| Listening | **Not run** |
| Human playtest | **Not run** |

### Performance (llvmpipe software rendering, 1280×720, `tests/tour_profile.gd`)

| Scene | p50 | p95 | Earlier p50 (2026-10-19, before the illustrated pass) |
|---|---|---|---|
| Room, session start | 61.5 ms | 96.5 ms | 64.1 ms |
| Square, calm, effects full | 59.9 ms | 65.6 ms | 58.6 ms |
| Square, calm, effects off | 38.2 ms | 43.1 ms | 32.9 ms |
| Square, HUNT + Wren escort | 63.9 ms | 73.7 ms | 57.2 ms |
| Edge, static spreading | 47.6 ms | 57.6 ms | 44.4 ms |
| Archive after 8 area changes | 49.1 ms | 55.3 ms | 42.3 ms |

- These numbers measure a CPU rasteriser, not a player's GPU; they show relative cost only.
- The illustrated cast and new areas cost about 5–7 ms here. Arin's line-of-sight cone costs 0.03 ms per frame (measured: 2.4 µs per ray, 14 rays).
- Node and object counts stay flat across area changes (no growth during play).
- No optimisation was made without real-device evidence. Candidates if a device shows a problem: sun shadows off on Light effects; baking figure outlines.

### Save compatibility

No saved field was added, renamed or removed in passes 3–4. Settings gain nothing new; `tips_seen` keeps its meaning (tips now enter it when read rather than when shown, so an older save simply has them marked already).

---

## Previous status (2026-10-19): `claude/cohesion-pass`

**Branches and commits:**
- `claude/cohesion-pass` is based on `claude/narrative-reliability` (`8fe3f35`, [PR #3](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/pull/3)), which is unmerged.
- `main` is still at `f2fcf32`.
- Code at `56ec8bb` (later commits on this branch are documentation only).

**Environment:** Linux container, Godot 4.3. No real GPU (Mesa llvmpipe), no Windows, no phones, no gamepads, no speakers.

### Is this a release candidate?

**Not yet.** No critical functional failure is known. These gates are still unmet:
- **Windows:** the build is exported but has never been launched on Windows.
- **Human playtest:** none has run. See the plan in `PLAYTEST_PLAN.md`.
- **Audio by ear:** nothing has been listened to.
- **Voice:** nothing ships. The generated pilot is not licensed for release (`VOICE_PILOT.md`).

### Builds

| Target | Result |
|---|---|
| Windows | Exported locally (exit 0), 84.8 MB PE32+. CI builds it as the `TheLastSaveFile-windows` artifact. **Not launched on Windows** |
| Linux | Exported (exit 0), 66.6 MB. Runs 240 frames headless with no script errors and no leak warning |
| Web | Built by CI (`TheLastSaveFile-web`). The browser check (`tests/web/web_check.cjs`) was **not re-run this pass** |

### Automated tests (this pass)

| Suite | Result |
|---|---|
| Full suite | **325 passed, 0 failed** at `8f287a7` (768 s). The suite is re-run on the final code before the PR; see the PR description |
| Character tests after Wren | 7 passed, 0 failed |
| Ending bots | **4 of 4 committed bots reached an ending:** escape (1 session), message (1), escape at purge 3 (2), wren (2, the Wren ending). An extra purge-5 bot escaped in one session in 2 of 3 runs. In the third it died once, which at purge 5 is the purge ending by design. It was not kept as a committed check |

New regression files:
- `test_verification_probes` (4)
- `test_cohesion_fairness` (5)
- `test_cohesion_story` (7)
- `test_character_presentation` (+2)

Each new fix's test was confirmed to fail without it.

### Performance (`tests/tour_profile.gd`, rendered through xvfb on llvmpipe at 1280×720)

**Software rendering:** these numbers measure this container's CPU rasteriser, not a player's GPU.

| Scene | p50 | p95 | max | Nodes | Objects |
|---|---|---|---|---|---|
| Room, session start | 64.1 ms | 101.8 ms | 129.8 ms | 269 | 2129 |
| Square, calm (effects full) | 58.6 ms | 70.6 ms | 112.8 ms | 286 | 2170 |
| Square, calm (effects off) | 32.9 ms | 38.9 ms | 42.0 ms | 287 | 2170 |
| Square, HUNT + Wren escort | 57.2 ms | 62.7 ms | 66.5 ms | 291 | 2235 |
| Edge, static spreading | 44.4 ms | 53.5 ms | 59.1 ms | 278 | 2224 |
| Out of bounds | 43.3 ms | 50.3 ms | 52.2 ms | 255 | 2188 |
| Archive after 8 area changes | 42.3 ms | 51.8 ms | 54.8 ms | 284 | 2242 |

**What this does and doesn't show:**
- **Screen effects** (CRT, lighting, shadows) are about 40% of software render time. *Settings → Screen effects* already lets low-end machines turn them off.
- **Node and object counts stay flat** across area changes, so there is no growth during play.
- **Game logic is cheap:** headless CPU time per frame stays within its budget (`test_performance`, the fully hunted square).
- **Not optimised this pass:** without real-device numbers there was no evidence to justify removing lighting or effects.

### Exit warnings

| Case | Status |
|---|---|
| Title screen | **0 leaked instances.** `Sfx` stops every audio player as it leaves the tree |
| The test harness | Still prints Godot's "ObjectDB instances leaked" once, from scenes freed mid-coroutine. **A harmless shutdown artefact**, not growth during play (see above) |

### Not verified

- Windows launch.
- Audio levels and intelligibility.
- Physical controllers.
- Phones and touch devices.
- Real-GPU frame times.
- Any human play.

---

## Historical status (2026-10-16, experience-polish milestone)


**Status on 2026-10-16:** the end of the experience-polish milestone, branch `claude/last-save-file-prototype-ljwuq4`. Everything below was run in a Linux container (Godot 4.3, headless, plus xvfb for screenshots). There was no real GPU, phone or gamepad.

## Builds

| Target | Result | How |
|---|---|---|
| Web (HTML5) | **Exported (exit 0)**: index.html, .js, .wasm (35 MB), .pck (0.4 MB). In headless Chromium (SwiftShader) it **loads and reaches the engine boot screen**; the title screen was **not confirmed** within the headless time budget | `godot --export-release "Web"`; `chrome --headless --screenshot` |
| Linux | **Exported (exit 0), 66 MB.** Ran about 240 frames headless with no script errors | `--export-release "Linux"`; `--headless --quit-after 240` |
| Windows | **Exported (exit 0), 85 MB. Not run** (no Windows here) | `--export-release "Windows Desktop"` |
| CI | The last `main` build passed (run #30, `fb1ffc9`). **This milestone isn't on `main`**, so CI hasn't built it | GitHub Actions |

Tests are excluded from exports (`exclude_filter="tests/*"`).

## Automated tests

| Suite | Baseline (`fb1ffc9`) | Now |
|---|---|---|
| Unit and scene tests | 209 passed, 0 failed | **234 passed, 0 failed** (769 s) |
| Bot playthroughs (4 endings) | 4 of 4 | **4 of 4** (escape, message, escape at purge 3, wren) |

During this milestone the choice input grace broke 9 existing tests and the Wren bot. The fix was to make the test helper `press()` wait for the grace the way a person would. **No assertion was weakened.**

## Real-browser check (Playwright, Chromium 1194 with SwiftShader)

The check is in `tests/web/web_check.cjs`; the steps to run it are in its header. Results on 2026-10-16:

| Check | Result |
|---|---|
| The engine starts and reaches the title, then a session | **Yes.** WebGL 2 (GL Compatibility), no page errors. Screenshots show the title and Arin's room mid-run |
| Audio before and after the first gesture | Before any gesture Chromium logs "AudioContext was not allowed to start"; afterwards the spied context reports `running`. **Headless autoplay rules can differ from desktop and mobile browsers. Confirm by ear on a real device** |
| The save reaches IndexedDB mid-run | **Yes:** `sessions 1, last_exit "active"` |
| Closing the tab mid-run | **Confirmed to count as a quit** on the next visit (`quits 1, purge 1, last_exit "crash"`). **The author's rule (2026-10-16): keep counting it, but warn.** The browser now asks "Leave site?" during a run (`beforeunload`, verified: `asks first: true`), and How to Play says so |

## Known defects and limits (open)

These are listed in `EXPERIENCE_POLISH_BASELINE.md` §3 and in each audit's status note:

- The console cuts off long lines with an ellipsis and has no backlog (UX C5).
- Act numbering doesn't match the guided route: Archive is ACT IV, Out of Bounds ACT III (**author decision**).
- Portrait orientation doesn't pause the game on phones (UX C9). Touch control overlaps are listed under UX C11 and C12.
- The palette contrast fixes in `CHARACTER_DIRECTION.md` need a visual review.
- **Web audio by ear:** not yet heard on a real device. Mobile Safari may not show the leave prompt, so there the tab close still counts silently.

## Platform verification

| Platform | Status |
|---|---|
| Desktop keyboard | Simulated input events in tests |
| Gamepad | Simulated joypad events in tests. **No physical controller tested** |
| Touch / phone | Simulated in tests. **No physical phone tested** |
| Browsers | Headless Chromium load only. Not tested in Firefox or Safari, not on mobile, not with audio |

## Accessibility

**Settings:**
- Master, Music, Effects and **Voices** volume.
- Fullscreen, CRT curvature, Screen effects (Off / Light / Full).
- Glitch intensity, Reduce flashing, **Screen shake**.
- Large text, Vibration, **Text speed** (Slow / Normal / Fast / Instant).
- Tutorial tips.

All settings persist (`Settings.save`/`_load`, tested). Flashing is scaled by `Settings.flash_scale()` throughout `screen_fx.gd`. **No formal WCAG flash-threshold measurement has been done.**

## Performance

Only relative frame timings are available: the visual tour under xvfb with software GL, roughly 30–45 ms per frame. These are **not** a statement about real hardware.

What still needs measuring on real devices:
- the F3 overlay in the square during HUNT;
- the Edge during the fight;
- the bin's sweep.

These should be measured on one mid-range PC and one mid-range phone, recording device, browser and resolution.

## Licensing and credits

- **Licence: all rights reserved** (author's decision, 2026-10-16). See `LICENSE`.
- **Third-party assets:** two fonts (2026-10-20): Inter (SIL OFL 1.1) and DejaVu Sans Mono (Bitstream Vera licence), subset, in `assets/fonts` with their licences; the credits screen shows both licences. All graphics and audio are generated in code. Godot itself is MIT-licensed and must be credited.
- **Credits screen:** on the title screen. It reads Godot's licence and every third-party notice from the engine at runtime (`tests/test_polish.gd` checks it).

## Release blockers

1. ~~Licence and credits~~ **Done.**
2. ~~Narrative decisions and the tab-close rule~~ **Done.**
3. ~~Save and tab-close checks in a real browser~~ **Done** (Chromium). Audio by ear and mobile browsers are still open.
4. Run at least one round of human playtests (`PLAYTEST_RESULTS.md`). The playtest log helps: open the game with `?playtest=1`.
5. ~~Merge to `main`~~ **Done** (CI builds each push).

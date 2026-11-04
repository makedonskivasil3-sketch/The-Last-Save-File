# THE LAST SAVE FILE: player-experience pass (gameplay, controls, graphics, feel, sales)

**Written 2026-11-02 for the author, and for Claude to run.**
- **Use:** paste this whole file as a session's task, or work through it yourself in order.
- **Status:** every item carries one of:
  - **APPLIED** (done in this pass, with its commit);
  - **OPEN** (the next thing to do);
  - **PEOPLE** (needs players, hardware or the author).
- **Before trusting any line:** check it against the repository. The code is the source of truth, not this text.

---

## 0. Who you are in this pass

You hold four jobs at once. Each has a veto, and a change ships only if none of the four uses it.

| Hat | You are responsible for | You veto anything that… |
|---|---|---|
| **Owner** | The game's identity and canon, money and time, risk, what ships and when. Nothing is bought, signed or published without the author | breaks canon (`docs/CANON_DECISIONS.md`, `docs/production/TRUTH_TABLE.md`), spends money, or can't be verified |
| **Designer** | Every system has a purpose a player can feel: threat, hiding, glitches, relationships, the Owner, the endings | adds content without a reason to exist, or makes the game longer without making it better |
| **Player** | What it is like, second by second, for someone who has never seen it, with keyboard, controller, mouse or touch | is confusing, unfair, slow, unreadable or ugly at the moment it happens |
| **Commercial lead** | Whether a stranger, from one screenshot and 30 seconds of video, wants to wishlist it; whether the demo makes them want the full game | can't be shown on a store page, or makes a promise the game can't keep (length, features) |

**Talk like all four.** For every change, the commit message or the report says:
- what the player feels;
- what the designer intended;
- what the owner risks;
- what the commercial lead can show.

## 1. Rules that never bend

- **Canon:**
  - Rue is the character left running; she is not the girl.
  - Arin is mute.
  - The well keeps recordings and makes no live contact.
  - Colour is choice.
  - The Owner means to clean up the save tonight.
  - Labels and festival facts follow what the prologue shows.
- **Foundations to keep:**
  - transactional saves;
  - free stopping at calm moments;
  - reader-paced story text;
  - the protection policy (story cards hold threats);
  - reduced motion and reduced flashing;
  - Owner pace;
  - the cast's visible behaviour (`docs/production/CHARACTERS.md`);
  - `main`'s doorway design.
- **Evidence:** measure before changing. A change without a before and after number, a test or a capture is a guess. **No guess ships.**
- **Tests:**
  - Never weaken, skip or disable one.
  - Never hide a warning.
  - Never call something fixed because a retry passed.
- **Money and rights:**
  - Never spend money or credits.
  - Never generate or buy assets or voices.
  - Never publish a store page.
  - Never claim human, hardware or listening verification that didn't happen.
- **Git:**
  - Work on the branch `claude/last-save-file-prototype-ljwuq4`.
  - Coherent commits, each naming what it measured.
  - Push. Update the open PR. Merge only when the author says "merge".
  - Never force-push.
- **Model IDs:** none in repository files.

## 2. Where the game is today (measured 2026-11-02, branch head `7fa700c`)

| What | Number | How it was measured |
|---|---|---|
| Strict suite | 841 cases in the inventory (`bash tests/run.sh --list-tests`). The last complete run (834 then) passed after one manifest regeneration | Four shards, an isolated `XDG_DATA_HOME` each, compared with the inventory |
| Ending bots | Every bot reached the ending asked for (escape at purge 0, 3 and 5; message; Wren) | `godot … -- --test-mode --bots --filter=<bot>` |
| Critical path (bots, no reading) | About 126–220 s of game time to an ending. The square is crossed three times (about 12% of the route) | `BOT [s…]` lines in the bot logs |
| Draw calls (software renderer) | Square about 790–1,100 a frame; Arin's room 650–750; house about 470–1,000 | `Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME`, probe and `tour_benchmark` |
| Area change | 347 ms median wall-clock on llvmpipe | `tour_benchmark`: "area change". **Not a GPU number** |
| Web startup | Playable after 1.65 s of game time (19.7 s wall on the headless runner) | `tests/web/web_check.cjs` |
| Web save delay | A save is durable 0.7–5.9 s after it is written (IndexedDB sync) | `tests/web/prologue_story_check.cjs`, `STORY_CPU_THROTTLE` |
| **Corner snag (before this pass)** | Walking straight into the workshop bench, offset by 1, 2, 3 or 5 px: **stopped dead at y 114 every time** | Probe in `LanternWorkshop` |
| **Early press (before this pass)** | [E] tapped 0.10 s before reaching the lamp: **nothing happened** | Same probe |
| Players | **Zero** unfamiliar players. No Windows, controller or phone run | — |

## 3. How to work every item

1. **Play it first, as the player.**
   - Take captures with the tour harness:
     `xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 -s res://tests/run_tests.gd -- --test-mode --tour --filter=<tour> --screenshots=<dir>`
   - Look at them at full size before reading code.
2. **Measure.**
   - Write a probe (a throwaway `tests/test_zz_*.gd`) that reproduces the problem with numbers.
   - Delete the probe afterwards. Keep the numbers.
3. **Decide with the four hats** (§0). Write one sentence per hat.
4. **Change the smallest thing** that fixes the cause.
5. **Lock it with a test** that fails without the change and passes with it. Run the neighbouring suites.
6. **Capture the after state** for anything visible.
7. **Record it:**
   - this file's status column;
   - `docs/production/ISSUE_REGISTER.md`;
   - `docs/RELEASE_READINESS.md` (top section).

## 4. The work

### C. Controls (the player's hands)

**Target:** nothing the player meant to do is lost or blocked by a pixel, on any input device.

| ID | Problem and evidence | Change | Acceptance | Status |
|---|---|---|---|---|
| C1 | Clipping a corner by 1–5 px stopped Rue dead (§2) | **Corner assist** (`Player._round_corner`): a blocked, mostly single-axis move looks up to 5 px to each side and slides round the edge through normal collision. Diagonals, squarely blocked moves and long walls are untouched | `test_controls_feel`: rounds at 1–4 px; never inside the bench; squarely blocked stays put; a long wall stays a wall; diagonals untouched | **APPLIED `7fa700c`** |
| C2 | An early [E] was dropped (§2) | **Press buffer** (`World.tap_interact`): a tap with nothing in reach is kept for 200 ms and used if something comes into reach. Dropped on area change or when Rue can't act | `test_controls_feel`: early press used; stale press expires; never carried into the next place | **APPLIED `7fa700c`** |
| C3 | Bots record "stalls" (2 in the Wren run, 9 in one purge-5 run). Some may be corner snags | Re-run the bots after C1 and compare stalls | Fewer or equal stalls, same endings | **MEASURED:** same endings. Stalls: Wren 2 → 0; purge 5: 9 → 3 and 0; others 0. Small sample: consistent with C1, not proof |
| C4 | The pointer path (click or tap to walk) uses its own route. Does it snag on corners too? | Probe a click just past a bench corner; apply C1's rule to pointer steps if it snags | Probe numbers before and after; `test_movement` unchanged | **CHECKED:** the main game has no click-to-walk. Touch drives the same move actions through its stick, so C1 covers it. Only the festival prologue walks to a pointer, and it has no furniture to snag on |
| C5 | Controller: stick deadzone 0.3 (rescaled), d-pad movement, prompts follow remapping. **Never tried with a real pad** | Run `docs/playtest/RUN_A_ROUND.md` session 1 with a pad; note overshoot at the gate and crystal | Observer sheet filled in | **PEOPLE** |
| C6 | Hold-to-glitch and tap-to-interact share [E]. A tap after a long press counts as a tap (`GlitchController`, `TAP_FRACTION`) | Measure the hold threshold against real presses (playtest log: "denied" sounds after holds) | No unintended glitch in the observer notes | **PEOPLE** |
| C7 | Movement variants A, B and C exist for playtests; C is the default | Keep C until a playtest shows 4 of 5 players prefer another | `RUN_A_ROUND.md` §7 rule | **PEOPLE** |
| C8 | Touch: the portrait pause, the E button cleared by dialogue | Unchanged; verify on a phone | One phone session | **PEOPLE** |

### G. Gameplay (the designer's systems)

**Target:** every threat is readable before it hurts; every action has a cost and a reason; failure teaches.

| ID | Problem and evidence | Change | Acceptance | Status |
|---|---|---|---|---|
| G1 | **Death to control time** is unmeasured. A slow retry makes difficulty feel worse than it is | Probe: time from a death to Rue moving again, at purge 0, 3 and 5 | A number in this table. Target ≤ 6 s unless a story card is being read | **MEASURED (this pass):** pressing as soon as allowed, control is back **2.3 s** after a first death and **1.6 s** after a repeat (0.6 s before the card, then a 1.2 s or 0.5 s retry lock, reload and wake). The card waits for the reader, by design. No change |
| G2 | Every threat's warning time (Arin's cone, the cursor, the static, eraser spots) should be ≥ 0.7 s. The death-spot warning is 3 s; the others are not listed together | One table: threat, warning, reaction time available, measured from code constants and a probe | Table in `docs/production/`; any threat under 0.7 s fixed or justified | **OPEN** |
| G3 | **The glitch economy:** each glitch costs awareness (UNLOCK +10, …). Does a careful player ever need more than they have? | Read `Glitch.DEFS` costs. Bot logs count glitches per run (2–12). Compare with the awareness thresholds | Write the budget down; change costs only with evidence | **OPEN** |
| G4 | Late purge is harsh by design: one purge-5 bot died once at the Edge (PL-4c) | Keep Normal as is; Gentle pace exists. Check that the Edge's first death at purge 5 explains itself | The death card names the cause (already tested). One human plays purge 4–5 | **PEOPLE** |
| G5 | The optional workshop now has a reason, a decision and a consequence | Watch whether players find the fifth frame (`RUN_A_ROUND.md` §8) | 3 of 5 interact with it | **APPLIED `3a5487c`** / **PEOPLE** |
| G6 | Replay value: six endings. Do players know more exist? | Title → Records shows endings found; check it says "N of 6" without spoilers | Capture plus a test that the count is shown | **HOLDS:** Records already shows "ENDINGS n/6", with a spoiler-free hint for each ending not found (`RecordsPanel`, `Story.ENDINGS_RECORD`) |
| G7 | Hiding: shelter spots and Wren's cover. Can a player tell where it is safe? | Capture every hiding spot with its "HIDDEN" status. Check that each spot has a visual cue in the art | One capture sheet; every spot readable | **OPEN** |
| G8 | No content padding. The length is reading and relationships | Add nothing longer until a playtest asks for it | Owner's veto | standing rule |

### V. Graphics (what the screenshot sells)

**Target:** one representative screen that looks like a product, then every screen to that standard. Code-drawn is fine; *inconsistent* is not.

| ID | Problem and evidence | Change | Acceptance | Status |
|---|---|---|---|---|
| V1 | **The name on the fifth frame** was three unreadable strokes | Drawn as "RUE" in her lilac, at the size of Wren's chalk name | Capture `03c_fifth_frame_named` (zoomed, readable) | **APPLIED `7fa700c`** |
| V2 | The goal bar backing (screen y 50–72) sits over the top wall row in fixed rooms. In Arin's room it covers part of the wall where the door and window are, until it fades | Measure how long it shows on first arrival. Consider anchoring it above the play area, or fading it sooner when Rue is near the top wall | Captures before and after; nothing playable hidden | **OPEN** |
| V3 | The smallest text drawn in the world (5–7 px fonts: chalk names, labels, signs) | List every `draw_string` with a size under 7. Check readability in captures at 1280×720 and 1920×1080 | Each one readable, or enlarged | **AUDITED:** six `draw_string` calls under 7 px. The smallest is 5 px (10 px on a 720p screen): Wren's and Rue's chalk names, both legible in captures. The others are 6 px decoration. No change |
| V4 | The first exit after session 1 is a faint seam (1 px line, alpha 0.18–0.30, `Seam._draw`). That is intended as a puzzle, but it may read as "no exit" | Leave it until a playtest. If 2 or more of 5 are stuck over 2 minutes, raise the hint | Playtest rule | **PEOPLE** |
| V5 | **The store page needs capsule art and key art.** The code-drawn cast is consistent but plainly programmer art | Write the art brief from `docs/ART_BIBLE.md`: capsule 920×430 plus 462×174 sizes, a key-art scene (the festival or the square at dusk). **The author commissions it** | Brief written; nothing bought | **OPEN** (brief) / **PEOPLE** (art) |
| V6 | Lighting: a warm key and a cool Owner light per map, consistent | Capture all seven maps (`tour_map_review`) side by side; correct any map that breaks the palette | One contact sheet | **OPEN** |
| V7 | Feet and animation contact (planted-foot drift 0.00 px, tested) | Unchanged | `test_world_cohesion` | holds |
| V8 | Reduced motion and reduced flashing must lose motion, not meaning | Every new visual effect has a reduced-motion path and a test | Standing rule | standing rule |

### X. Player experience (the first minute to the last)

**Target:** a stranger understands what to do within 30 s, never feels cheated, and can stop and come back without losing anything.

| ID | Problem and evidence | Change | Acceptance | Status |
|---|---|---|---|---|
| X1 | **First 60 seconds** (the memory card → the festival → the first lantern): time to first control was 0.1 s and the skip is 0.8 s, but the feel is unmeasured | Playtest session 2 (`RUN_A_ROUND.md`) | The observer sheet's first-minute notes | **PEOPLE** |
| X2 | **Web saves** become durable 0.7–5.9 s after being written (WEB-1). A tab closed at once can lose the last step | Say so on any web demo page. Keep Windows the primary platform. Re-measure on a cheap laptop | Note on the page; a measurement | **OPEN** |
| X3 | Workshop progress that fails to write says "NOT SAVED YET" and retries | Unchanged | `test_workshop_persistence` | holds |
| X4 | Chapters follow the story; places are named on arrival | Unchanged | `test_act_order` | holds |
| X5 | Report a problem, the build stamp and Previously all exist | Use them in every playtest | Reports collected | **PEOPLE** |
| X6 | Large text and every menu: does anything clip? | Run the large-text tours. Fix any clipping | Captures | **OPEN** |
| X7 | A new player's first death: does the card say why, and what to do differently? | Capture each death card (Arin, cursor, static, eraser) | Every card names the cause and a counter | **HOLDS:** every `Story.DEATHS` entry has a cause line and a counter-glitch tip (`test_fairness`, `test_narrative_reliability`) |
| X8 | Quit and resume: the free stop at a calm moment works on desktop and web (`web_check`) | Unchanged | `web_check` 12/12 | holds |

### P. Performance and code optimization (the owner's risk)

**Target:** a steady 60 fps on a five-year-old laptop and in a browser. **Optimize only what a profile shows.**

| ID | Problem and evidence | Change | Acceptance | Status |
|---|---|---|---|---|
| P1 | **Draw calls:** square about 790–1,100 a frame, Arin's room 650–750. Lights and particles are *not* the cause (turning them off changes under 2%). The area node and its children are | **First measure on a real GPU** (`tools/run_benchmark.sh` on the author's PC). Only if frame time is over 8 ms there: merge static props into the baked backdrop (`set_backdrop`), as the square's ground already is | A benchmark JSON from real hardware | **PEOPLE** (measure) → **OPEN** |
| P2 | The square redraws its `_draw` every frame until the pointer. Checked: only ten specks of the unloaded road animate; the rest is baked | Nothing to do | — | checked, fine |
| P3 | Area change: 347 ms wall-clock on llvmpipe | Profile `World._load_area` on real hardware. Cache built areas only if it is over 150 ms there | Benchmark "area change" on a GPU | **PEOPLE** (measure) |
| P4 | ObjectDB instances are reported at exit, in the test runner only (PL-3). The exported game exits clean | Fix the per-test teardown (pending timers and tweens), not the game | Warning gone from `tests/run.sh`, not suppressed | **OPEN** |
| P5 | Allocations every frame in hot paths (for example `Player._update_dust` filters an array every frame; HUD label updates) | Profile with `--verbose` and Godot's monitor. Change only a path over 0.2 ms a frame | Before and after numbers | **OPEN** |
| P6 | Web build: `index.wasm` 35 MB (engine), `index.pck` 3.3 MB | Serve with Brotli or gzip (host setting); a "loading" progress bar exists | Measured first-load time on a normal connection | **OPEN** |

### M. Commercial (what sells)

**Target:** a store page and demo that make a stranger wishlist it, without a single false promise. Plan: `docs/production/COMMERCIAL_PLAN_2026-10-31.md`.

| ID | What | Who | Status |
|---|---|---|---|
| M1 | **The playtest round** (5 people, `RUN_A_ROUND.md`). Everything else waits on it: length, price, demo endpoint | Author | **PEOPLE** (most important) |
| M2 | **Demo endpoint:** choose arch (`?demo=1`) or workshop (`?demo=workshop`) from playtest answers to "would you buy the full game?" | Author | **PEOPLE** |
| M3 | **Screenshots:** six at 1920×1080 from the tour harness:<br>• the festival;<br>• the square at dusk;<br>• Wren's chalk;<br>• the workshop light;<br>• the Edge;<br>• an ending | Claude | **OPEN** |
| M4 | **Trailer storyboard** (45–60 s), captured in game:<br>• hook: the memory card;<br>• premise: a character left running;<br>• threat: the Owner;<br>• people: Wren;<br>• stakes: Slot 2;<br>• title | Claude (storyboard), author (edit) | **OPEN** |
| M5 | **Steam dates:** Next Fest registration by **10 Jan 2027**; the event runs 22 Feb – 1 Mar 2027; the Coming Soon page must be up two weeks or more before release | Author | **PEOPLE** |
| M6 | **Price** from the measured first-ending time only (bands in `RELEASE_SPRINT_TO_CHRISTMAS_2026.md`) | Author | **PEOPLE** |
| M7 | **Store text:**<br>• a short description of 300 characters or fewer;<br>• tags;<br>• content descriptors;<br>• an honest length ("about N minutes to a first ending", once measured) | Claude drafts, author approves | **OPEN** |

## 5. Order of work (each step ends with the strict suite green)

1. **C1–C4:** controls. The hands come first; everything else is felt through them.
2. **G1, G2, X7:** failure that teaches (death-to-control time, warning times, death cards).
3. **V2, V3, V6, X6:** readability and one consistent look.
4. **G3, G6, G7:** systems the player should be able to reason about.
5. **P4, P5:** clean teardown and measured hot paths. P1 and P3 wait for real-hardware numbers.
6. **M3, M4, M7:** store material from the game itself.
7. **M1, then everything marked PEOPLE.**

## 6. Verification, every time

1. **Full suite:** four shards, each with its own `XDG_DATA_HOME`:
   `XDG_DATA_HOME=/tmp/x$i bash tests/run.sh --shard=$i/4`.
   Compare the union with `bash tests/run.sh --list-tests`: no omission, no duplicate, no script error.
2. **Bots:** each ending at least once, the escape at purges 0, 3 and 5 twice. Report deaths, reloads and **stalls**.
3. **Exports:** Windows, Linux and Web, with SHA-256 hashes. The Linux smoke run exits 0.
4. **Browser:** `web_check`, `prologue_story_check` (also with `STORY_CPU_THROTTLE=6`), `audio_output_check`.
5. **Captures** for every visible change, before and after.
6. **Documents:**
   - this file's status column;
   - `ISSUE_REGISTER.md` (top section);
   - `RELEASE_READINESS.md` (top section).

## 7. Report format (every session ends with this)

1. **What changed**, with commits, in the four hats' words.
2. **What was measured** before and after.
3. **What was verified, exactly**, and what wasn't.
4. **What needs people, hardware or the author**, with the decision asked for.
5. **The next three items** from §5.

## 8. Applied in this pass (2026-11-02)

| Item | Commit | Evidence |
|---|---|---|
| C1 corner assist | `7fa700c` | Probe before: stopped dead at 1–5 px. After: rounds at 1–4 px with no overlap; blocked squarely and long walls unchanged (`test_controls_feel`, 7 cases) |
| C2 early-press buffer | `7fa700c` | Probe before: an early tap was lost. After: used once in reach; a stale tap expires; nothing carries into the next place |
| V1 legible name on the fifth frame | `7fa700c` | Capture `03c_fifth_frame_named` |
| P2 checked | — | The square's per-frame redraw is ten specks; nothing to optimize |
| G1 measured | — | Death to control: 2.3 s first, 1.6 s repeat. Within the 6 s target |
| C4, G6, X7, V3 checked | — | No defect found. Each row says what was checked |
| Baseline numbers (§2) | — | Probes and `tour_benchmark` on this head |

Verification of this pass: `docs/RELEASE_READINESS.md`, top section.

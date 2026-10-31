# Release readiness

**This section is the single authoritative statement of the project's current status.** Other docs (audits, pass notes) are history; where they disagree, this wins.

## Current: production revision (2026-10-31)

**Branch:** `claude/last-save-file-prototype-ljwuq4`.
- `main` @ `adf2710` was merged in at `b5db36a`. Main's doorway design won.
- Code verified at `3062c7d`.
- Register: [`production/ISSUE_REGISTER.md`](production/ISSUE_REGISTER.md) (top section).
- Spec: [`production/PRODUCT_SPEC.md`](production/PRODUCT_SPEC.md) (top page).

### What changed, and why it matters to a player

| Change | Commit | Player benefit |
|---|---|---|
| Workshop steps saved in one write; a failed write says so and retries; failure injection tests | `d6fd6ed` | Nothing shown as done can vanish on relaunch without a warning |
| Chapters follow story milestones, not places. Places are named on arrival | `d6fd6ed` | No later chapter before an earlier one, in any exploration order |
| The title glitch can no longer rewrap the title and move the menu | `7f9f7e6` | A click lands on the button the player aimed at |
| RD-1: the browser story check was measuring IndexedDB sync, not reading. Root cause measured; check fixed; web save delay registered (WEB-1) | `837e798` | A verified reader. An honest statement about web saves |
| The workshop mission deepened: Rue's reason, a readable problem, a decision (her name on the fifth frame), Wren's variant | `3a5487c` | The one optional mission now has a why, a choice and a remembered consequence |
| The candidate demo endpoint (`?demo=workshop`) ends after a finished mission. Demo saves are separate | `d9beec1` | A demo that shows the game's third promise. Demo progress never leaks into the full game |

### Verified

- **Strict suite, at `d9beec1`:**
  - Four shards with isolated XDG folders.
  - **834/834 inventory cases ran**, checked against `--list-tests`: no omission, no duplicate, no script error.
  - 833 passed. One failure: the voice manifest was out of date after the new Wren line. Regenerated with the repo's tool in `3062c7d`; the voice tests then pass 12/12.
  - The ObjectDB exit warning is still printed (PL-3). It is not suppressed.
- **Earlier sharded run (`d6fd6ed` + docs):** 2 failures, both investigated and reproduced, not re-rolled.
  - UI-7: title glitch.
  - QA-2: test isolation.
  - Both fixed in `7f9f7e6`.
- **Bots** (code at `d9beec1`, game time): every bot reached the exact ending asked for.
  - escape at purge 0: 149 s, then 149 s;
  - escape at purge 3: 132 s, then 135 s;
  - escape at purge 5: 126 s; then 220 s, finished after one death at the Edge;
  - message: 151 s;
  - Wren: 178 s.
- **Exports from `3062c7d`:** Windows, Linux and Web, all exit 0.
  - SHA-256 prefixes:
    - `TheLastSaveFile.exe` `25dec7ff8106633a`;
    - `TheLastSaveFile.x86_64` `363cbae00bc059f8`;
    - `index.pck` `edaea729a6f7ca5c`;
    - `index.wasm` `fe5cebc590758c10`.
  - Linux smoke run exits 0 with no errors.
  - These are local builds in the session container, not public downloads. CI builds the public artifacts.
- **Browser checks on that web build:**
  - `web_check`: 12/12;
  - `prologue_story_check`: reader 58–102 ms, stored 0.7–1.7 s. Also 4/4 at CPU throttle ×1 and ×6 at `837e798`;
  - `audio_output_check`: pass.

### Route timing (bots, escape at purge 0, game time without reading)

| Stretch | Seconds |
|---|---|
| Arin's room | about 35. About 20 of that is the bot circling a table: bot navigation, not a player problem |
| Square → under the well | about 13 |
| Under the well | about 26 |
| Square → Archive | about 8 |
| Archive | about 9 |
| Square → Edge | about 10 |
| Edge to Slot 2 | about 31 |

**Backtracking:**
- The square is crossed three times, for about 18 s of 149 s (12%).
- Every crossing has a new reason (`production/WORLD_CONNECTIONS.md`).
- **No route change is made from this.** The bots don't read, and players do. The real length is still unmeasured.

### Not verified (needs people, hardware or the author)

- No playtest has been run.
- **Hardware never tried:**
  - Windows;
  - a physical controller;
  - a phone.
- **Web saves on real low-end hardware.** WEB-1 was measured in headless Chromium only.
- **Listening:** nobody has listened to the mix.
- **The demo endpoint:** the choice between the two is the author's, after a playtest.
- **Art:** the fifth frame's label is small at game scale. Polish it only if a playtest shows players miss it.
- **Commercial:** see [`production/COMMERCIAL_PLAN_2026-10-31.md`](production/COMMERCIAL_PLAN_2026-10-31.md). Nothing has been bought, signed or published.

## Previous: unified gameplay, traversal and lantern workshop (2026-10-30)

**Base:** main `a81baf7` (PR #12). **Final runtime:** `2f03453`.
The author requested implementation and merging into main. The previous input
fixes (`b5b0c36`) and current main's character/festival work are integrated;
historical alternative branches are not reapplied over approved canon.

The owner's friends reported gameplay, graphics and disconnected map changes.
This pass addresses that feedback with a bounded mission and traversal revision,
not a claim of final art or commercial readiness.

- Normal crossings use quieter audio and shorter fades, with threshold cues,
  inward entrance facing and protection while control is held.
- Ordinary rooms no longer trigger a corruption tear. Impossible spaces and
  Owner events keep their distinct effects.
- The lantern workshop below the Archive adds a spare wick, repair action,
  persistent light, journal/object states, Wren's acknowledgement, safe stopping
  and an earned two-way route to the well. Main progression/endings stay intact.
- Foot stance follows actual ground direction, including front/back/diagonals.
- Touch interruption and cold-open reading fixes are included. Portrait gameplay
  pauses safely; the rotation instruction sits above menus and landscape waits
  for explicit Resume.

| Verification | Result |
| --- | --- |
| Full native regression coverage | **793/793 passed**, zero failures/script errors; normal game speed, four isolated shards; inventory checked for no missing/duplicate cases. **Not a completed monolithic run.** |
| Workshop route | Rendered ordinary-input route 1/1; software llvmpipe |
| Workshop stopping | Resume before pickup, carrying wick, after repair: 1/1 route check, all stages |
| Ending bots | Five played routes reached their requested outcomes; purge-3 used two retries. The runner's sixth PASS is an inactive opt-in probe, not another played route |
| Windows / Linux / Web | Final runtime exports exit 0; Linux exported smoke 240 frames exit 0 |
| Browser | Lifecycle, audible output, manual story reader and touch-orientation checks pass; one earlier story-click attempt was timing-sensitive under concurrent software rendering, retained in the evidence |

Details, exact revisions, limitations, logs, hashes and screenshots:
[`review/oct30/IMPLEMENTATION.md`](review/oct30/IMPLEMENTATION.md) and
[`review/oct30/VERIFICATION.md`](review/oct30/VERIFICATION.md).

**Still open:** final approved artwork/acting; physical Windows, controller and
iPhone checks in this session; human listening; campaign-density/backtracking
measurements; late-purge fairness; existing ObjectDB/anchor warnings. Friends'
early feedback is valuable, but is not a recorded market-validation study.
Use [`review/oct30/PLAYTEST.md`](review/oct30/PLAYTEST.md) for the next round.
The workflow on main builds downloadable artifacts and deploys Pages; local
export success does not mean the public deployment has completed.

## Previous (parallel branch, reconciled 2026-10-31): travel between maps (`e551c6c`)

> **Reconciled with `main` @ `adf2710` on 2026-10-31.** That branch and `main` took opposite approaches to doorways. `main`'s design is kept: quick 0.12/0.16 s fades, stone thresholds, explicit arrival facing. **Removed here:** the passage card, the walk-out and walk-in, exit intent, the arrival clear-zone and the lit-threshold glow. **Kept:** dust at Rue's feet, and people noticing her arrive (`Area.on_arrival`, now called from `main`'s `change_area`). The rest of that branch's work (the open-issue sweep and next pass below) is merged unchanged. Its verification figures belong to that branch's revisions, not to the merge.

**Asked for:** update the graphics, movement and character depth, and fix "the fast meaningless jumping from map to map". The brief is [`prompts/TRAVEL_AND_DEPTH_2026-10-30.md`](prompts/TRAVEL_AND_DEPTH_2026-10-30.md), written and applied.

**The problem, measured:**
- Most maps are one screen (448×256); Rue crosses one in about 5 s.
- An exit fired on any touch, even brushing past sideways.
- The change was a 0.25 s fade, the next map, then a 0.3 s fade: **about 0.55 s, with no reason given**.

| Change | What the player gets | Evidence |
|---|---|---|
| Leaving on purpose | An exit fires only when Rue moves out through it, or stops in it. Brushing a doorway sideways doesn't change the map. After arriving, she can't bounce straight back | `test_travel` |
| Walking out and in | She walks through the doorway as the picture darkens (0.4 s), and walks in on the other side. Reduced motion: no walk | `test_travel` |
| The passage card | On black: the place's name, why she is going ("(the records. someone wrote down who lit it.)") and who is with her ("(pip at my heels.)"). 1.4 s when there's something new to say, 0.6 s (name only) otherwise; a press ends it; threats are held. A transition now takes **about 2.6 s with something to say, 1.4 s without** | `test_travel`; `tour_travel` t02 |
| Doorways you can see | Every exit draws a lit threshold that brightens within 40 px. Closed ones are cold | `test_travel`; `tour_travel` t01 |
| Dust | A puff at her feet when she sets off, stops sharply or turns round. Off with reduced motion | `test_travel` |
| People notice her | Wren waves, Tobben glances up, the Archivist keeps writing, Mira turns from the window. Only people she has met, never her escort, never while the owner hunts. Pip trots in a step behind | `test_travel`; `tour_travel` t04 |

**Test isolation, explicit:** the suite runs with travel beats off by default (`World.travel_beats_default`). `test_travel` and the bots turn them on.

**Found by the bots:** with travel on, every route stalled entering Out of Bounds. The arrival itself was fine (318 frames, Rue on her entry point); the bot only waited 240 frames. Its wait is now 8 s by the clock (`e551c6c`).

### Verification (`e551c6c`)

| Check | Result |
|---|---|
| Strict full suite | **809/809** (`407db87`; the later commit only changes the bots' wait) |
| Ending bots, with travel beats | **6/6 in two runs** (escape, message, purge-3, purge-5, the purge-5 probe, Wren) |
| Exports | Web, Windows, Linux exit 0. SHA-256: exe `29e4758894c93631`, x86_64 `0ef1fbc43b1dcd86`. Linux smoke: exit 0, no script errors |
| Browser | Lifecycle passes; audio: title −29.8 dBFS, room −31.2 dBFS. The story reader **failed once in three runs** (the "Continue click keeps the reply" step), then passed twice. It is timing-sensitive, in the festival, which this pass doesn't touch. Recorded, not hidden |
| Playable build | https://claude.ai/artifact/3G95pCn7jTAYr2DPmmWu5w **version 25** (`e551c6c`). Private until shared |

**Not verified:** whether players find the passage helpful or slow. Add it to the playtest questions: "Moving between places, did you know where you were going and why?"

## Previous: the open-issue sweep and the next pass (2026-10-30, branch at `7734ab1`)

**Base:** `main` @ `a81baf7` (PR #12). The author asked to "implement all the issues that remain unsolved", write a prompt for what the game still lacks, and implement it. The prompt is [`prompts/NEXT_PASS_2026-10-29.md`](prompts/NEXT_PASS_2026-10-29.md).

### Open issues

| Issue | Done | Evidence |
|---|---|---|
| PL-3 exit warning | Characterised. One cause fixed (Tobben's report). The rest are test teardown under pending effects. The exported game exits clean. **Still open** | Verbose suite: 25 timers, 23 tweens, 14 coroutines at exit. Linux smoke: no warning |
| PL-4b death-seeded static | A death spot glows red for 3 s before its static starts | `test_death_seeds` |
| PL-5 benchmark validity | The escort survives under `bench_immune`. The hunted scenario is valid 3/3 | `tour_benchmark` (xvfb, software renderer) |
| UI-2 phones | Portrait pauses play. A key or pad press hides the touch controls. Dialogue text clears the E button | `test_touch_fixes` 3/3. **No phone tested** |
| UI-3 gamepad remapping | Interact and Pause can be rebound. B, the d-pad and Home are refused. Start always pauses. Kept and reset | `test_pad_remapping` 4/4. **No physical controller** |
| UI-4 flashing | `tour_flash`: worst second at default is 2 (a real death with its card; was 3). Reduced flashing: 0 | An engineering measurement, not a certified PSE test |
| UI-5 silhouettes | `solid` draws a true silhouette | `test_character_pipeline` |
| UI-6 act numbers | Cards count up in the order the places are reached | `test_act_order` 2/2 |

### The next pass (the prompt's §1–4)

| Feature | What a player gets | Evidence |
|---|---|---|
| Build stamp | "build abc1234 · date" on the title and on the pause menu's History page. CI writes `build_info.json` | `test_next_pass` |
| Previously | After 20 min away: the goal, the last two things read, who is with her. Reader-paced, before anything moves | `test_next_pass` (shown, not shown, once, nothing unseen, save stamp) |
| Owner pace | Settings → Owner pace: Normal / Gentle. Gentle: Arin and the cursor at 80%, static at 60%, death-spot warning ×2. Story unchanged. Logged in the playtest log | `test_next_pass` (multipliers, Arin's real speed, kept) |
| Report a problem | Pause → History → Report a problem: build, place, goal, play settings and the last 40 lines, copied to paste to the author. Nothing is sent | `test_next_pass` |

### Verification (`7734ab1`)

| Check | Result |
|---|---|
| Strict full suite | **799/799** (1823.5 s, verbose). The exit warning is still printed (PL-3) |
| Ending bots (`7734ab1`, two runs) | Run 1: escape, message, purge-3, Wren, the purge-5 probe pass; **purge-5 failed** (two Edge static deaths after reloads, PL-4c). Run 2: **all 6 pass** |
| Exports | Web, Windows, Linux exit 0. SHA-256: exe `cd8a6f6e90713983`, x86_64 `f5ee03a69b420d6a`. Linux smoke (xvfb, 240 frames): exit 0, no script errors, no leak warning |
| Browser (headless Chromium) | Lifecycle all pass; story reader passes; audio: title −29.7 dBFS, room −32.8 dBFS |
| Playable build | https://claude.ai/artifact/3G95pCn7jTAYr2DPmmWu5w **version 24** (`7734ab1`, stamp shows the commit). Private until shared |

### Still needs people, hardware or the author

- **Playtests:** five unfamiliar players (`playtest/RUN_A_ROUND.md`). Add the new questions: did anyone use Gentle, and did "Previously" help after a break?
- **Hardware:** Windows run, a physical controller (now including remapping), a phone (portrait and touch), Mobile Safari (SV-2).
- **Assets:** final art and voices, under `production/PRODUCTION_STANDARD.md`.

## Previous: the supporting cast, canon A–E, the playtest kit (2026-10-29, branch at `40ba023`+)

**Base:** `main` @ `6e67d0a`. Branch `claude/last-save-file-prototype-ljwuq4`. **Merge:** authorised by the author ("yes merge"; decisions 1–4 delegated, 2026-10-29), after CI is green on the PR.

**Asked for:** "best work for 1 to 4" (the four decisions below) and more development, detail and graphics for the characters that weren't built enough.

### Changed, with evidence

| Area | Change | Evidence |
|---|---|---|
| Tobben | Reporting is a walk you can watch: he hesitates, walks to the board, writes "SEEN NEAR THE STALL". Rue can catch him on the way ("It's in my script. It isn't in me."). After the guest book he crosses his own name off, and it stays. Stall redrawn | `test_tobben` 3/3; `tour_characters` c01–c03 (`3ba17f5`) |
| Mira | Her corner: a table, two cups, her folded note FOR THE BOARD before she asks; the table changes with her story (carried, pinned, lost, reset); pinned, she watches from the window; restricted, the owner's selection box | `test_mira_corner` 5/5 (incl. the leak fix below); `tour_characters` m01–m04 |
| Pip | Leads once per long stop, then waits; hides behind Rue from Arin (ears back, crouched); lies down to rest | `test_pip` (`143b018`); `tour_characters` p01–p02 |
| Archivist | Names the colours once while Rue is partly coloured; after the CHARACTER FILE he starts a new file, RUE, FILED UNDER: PEOPLE (a folder drawn on his desk) | `test_archivist_file` 3/3 (`de97fdb`); `tour_characters` a01 |
| The Owner | Two notes: the house is sold and the console goes in the van; "when i play arin i'm nine again…" | story suites pass (`de97fdb`) |
| Rue (canon B) | In the `rue` ending she picks a colour nobody chose for her and wears it from then on: a lilac flower clip in her hair, in the world and on the title. The owner's flicker takes it with the rest | `test_own_colour` 4/4; `tour_characters` r01 (`984aafc`) |
| Canon A–E | Decided as recommended, on the author's delegation; each reversible (`CANON_DECISIONS.md` §7). B's playtest condition kept as a check | `TRUTH_TABLE.md` rows for the Owner and the colours |
| Cold open | Dressed: a memory card beside the first line (its access light on while reading), the television's glass and scanlines, a block cursor that blinks while it waits. Reduce motion: no blink, no breathing glow | `test_cold_open` 4/4; `tour_cold_open` |
| Playtests | `playtest/RUN_A_ROUND.md`: invitation, consent, links with parameters, variant order, schedule, log export, analysis table and decision rules written before the round | Document only; **no session run** |
| Defect found and fixed | A deleted Mira's table was created and never added: one stray node per room build (found by the suite's leak check) | Test fails before, passes after (`401ffb1`) |

### Verification

| Check | Result |
|---|---|
| Strict full suite | **777/778** on `401ffb1` (1807.5 s, no script errors). The one failure: the voice manifest lacked the new epilogue line; regenerated in `40ba023` (data only), `test_voice_manifest` 3/3. The ObjectDB exit warning (PL-3) is still printed |
| Ending bots (`40ba023`) | Run 1: escape, message, purge-5, wren pass; **purge-3 failed**. Run 2: all 5 pass. Purge-3 alone ×4: all pass. **Purge-3: 5 of 6 this round.** Investigated as PL-4b: not a threat defect |
| Exports (`40ba023`) | Web, Windows, Linux exit 0. SHA-256: exe `fbd8ed208cd09b84`, x86_64 `462b64991a902cfa`. Linux smoke (xvfb, 240 frames): exit 0, no script errors |
| Browser (headless Chromium, `40ba023` web export) | Lifecycle check all pass (memory card → festival → room; calm tab-close resumes free; no page errors). Story reader passes. Audio: room −30.8 dBFS, audible |
| Playable build | https://claude.ai/artifact/3G95pCn7jTAYr2DPmmWu5w **version 23**, game code `40ba023`. Private until shared |

### Not verified, and still open

- **No unfamiliar player has played.** The kit is ready; recruiting is the author's step.
- **Platform:** no Windows execution, no physical controller, no hardware GPU. Gamepad remapping is not built.
- **Art:** everything is code-drawn and provisional (`production/PRODUCTION_STANDARD.md`). Nothing bought, commissioned or generated.
- **Open defects:** PL-3, PL-4b (human check), UI-2, UI-4, UI-5, UI-6, SV-2.

### Decisions for the author

1. **Recruit five players** and run `playtest/RUN_A_ROUND.md`: it gates art, voice and pricing.
2. **The square's death-seeded static** (PL-4b): keep (harder late game, the owner remembers), or mark-only like the Edge.
3. Share the v23 link with anyone you want to play it (it's private).

## Previous: refining toward a vertical slice (2026-10-28, branch at `3c00c96`)

**Base:** `main` @ `6e67d0a` (PR #11). Branch `claude/last-save-file-prototype-ljwuq4`. **Not merged:** no merge authorisation for this round.

### Baseline at `6e67d0a` (re-verified this round, not carried over)

- **Strict full suite:** 747/747, 1605.2 s, no script errors. The ObjectDB exit warning (PL-3) is still printed.
- **What works:** transactional saving; free stopping at calm moments (browser-verified); keyboard remapping; pointer arrival and long-frame collision; actual-motion gait; stable facing; the festival's interruption and impossible action; Wren's chalk game.
- **Defective, found this round:**
  - Objects unidentifiable before touching them (UI-9).
  - Feet skating 20–29 px a step: the planted foot moved forward.
  - Wren's game unreachable before her escort on a natural route: the ask came first.
  - Four documents stating the **rejected** premise as current canon.
  - The audio check measuring the festival instead of the room.
- **Hypotheses:** immediate movement is right; the cold open adds the wanted dread; players care about Wren; the "2–3 hour" length.
- **Needs people or hardware:** every feel and comprehension question; Windows; a controller; listening.

### Changed this round, with evidence

| Area | Change | Evidence (revision) |
|---|---|---|
| Interaction | A name line over every prompt ("SAVE POINT", "OUT ON THE CROSSING", "WREN · WAITING FOR YOUR MARK"). Redrawn: the well (square and festival), the save crystal, the note, a memory (now a torn picture, not a second diamond) | `test_readability` 4/4; `tour_readability` captures (`3359569`) |
| Animation contact | Planted-foot drift 20–29 px → **0.00 px** (Rue at 1× and 1.35×); supporting cast 10 → 0.00 px | `tour_foot_contact`; `test_movement` 19/19 (`3359569`) |
| Movement variants | A / B / C switch for playtests, C default. A and C: 17 ms to motion, 0 px stop. B: 33 ms, 2.4 px stop. **No preference claimed** | `docs/review/movement/VARIANTS.md` |
| Game camera | Reversal moves the view 5.0 px (max 1.57 px/frame); never past the map | `tour_game_camera` |
| Wren | Game before her ask, no shelter prerequisite; "chalk out" invitation; drawings between sessions (lantern, fox or bird, hopscotch). Fresh-profile route reaches game → verdict → ask by ordinary play | `test_wren_route` 2/2, `test_wren_game` 7/7, Wren files 36/36; Wren-ending bot passes playing the game |
| Opening | A memory card before the festival (first run): last 2-player session never closed; "one more go. then i'm cleaning it up." Reader-paced, skippable, kept in the journal | `test_cold_open` 3/3; title-path tests updated; browser check sees it |
| Canon | Proposal: "colour is choice", Rue's mind, the Owner's goal and the in/out-of-machine frame. **Decisions A–E open** | `production/CANON_PROPOSAL_2026-10-28.md` |
| Threat fairness (PL-4) | The failures were the bot walking head-on into Arin's visible round after a reload, and into the square's static at purge 4–5. Bot steering fixed; **the game is unchanged** | purge-3: before 2/6 failed, after **8/8** pass |
| Narrative authority | Four banners corrected; `docs/README.md` says which documents govern; `WREN_ARC.md` intro corrected | `9b66266`, `1d4627f` |

### Verification on this branch

| Check | Result |
|---|---|
| Strict full suite | **759/760** on `b8105e7` (1704.5 s, no script errors). The one failure was `test_wren`'s helper (three talks; her game now takes the third), fixed in `3c00c96` and re-run: `test_wren` 7/7, all Wren files 36/36. **The code under test is identical** |
| Ending bots | escape, message, purge-3, purge-5 (recovers from an Edge death), wren: **all pass** |
| Exports (`b8105e7`) | Web, Windows, Linux exit 0. SHA-256: exe `ac8f57f2fdcd36ec`, x86_64 `b0c769e1470d67a8`. Linux smoke: 240 frames, exit 0, no script errors |
| Browser (headless Chromium) | Lifecycle check all pass (memory card → festival → room; calm tab-close resumes free; no page errors). Story reader passes. Audio: room −29.9 dBFS |
| Playable build | https://claude.ai/artifact/3G95pCn7jTAYr2DPmmWu5w **version 22**, game code identical to `3c00c96`. Private until shared |

### Not verified, and what's still open

- **No unfamiliar player has played any of it.** The protocol, the observer sheet and the timing for sessions A–E are ready.
- **Platform:** no Windows execution, no physical controller, no hardware GPU.
- **Gamepad remapping is not built.**
- **Length:** the bots reach an ending in about 2.5 min of travel; the product spec's 2–3 h is unmeasured. **Don't price from it.**
- **Assets:** nothing is final art. Briefs and quantities are in `production/PRODUCTION_STANDARD.md`; nothing purchased or generated.
- **Open defects:** PL-3 (ObjectDB exit warning), UI-2, UI-4, UI-5, UI-6 and SV-2 remain open.
- **Secondary characters (§10 of the brief):** not deepened this round.

### Decisions for the author

1. The canon proposal, A–E.
2. Keep the cold open?
3. Merge this branch?
4. Arrange the playtests: they gate further investment.

## Previous: trust and control, free save, and Wren's game (2026-10-28, `2ed3eb4`)

**Code revision:** `2ed3eb4`. Base `b26aba0`. Merged to `main` with the author's authorisation (PR #11).

**Since `e447ff4`, at the author's request ("free save"):**
- Stopping at a calm moment is free however you stop: Save and exit, quitting from the menu, closing the window or tab, or a crash. In danger it counts as before (SV-1).
- Keyboard remapping is in Settings → CONTROLS (UI-3). Gamepad remapping is not built.
- Smaller fixes: UI-7 (well prompt), OP-6 (ring behind nameplate), UI-8 (doubled parentheses), PL-8 (test isolation).
- Web-only fixes found by the browser check at this revision:
  - Key names no longer call a display-server function the browser lacks, which had raised a page error.
  - The check now reads open text before expecting a calm moment.

**Fixed.** Each was reproduced at `b26aba0` by a test that failed before the fix:
- **Save and exit (SV-3, S1):**
  - It reported SAVED with nothing written. Now it is one transaction: Retry / Return to game on failure, and the last save and its backup survive every injected write failure.
  - A resumed position is checked against the whole body in the rebuilt map (ST-3).
  - Escorts can be suspended: they go home and ask again (ST-5).
- **Movement (MV-1 to MV-6):**
  - pointer oscillation; walking into the fence forever;
  - crossing the closed gate on a long frame;
  - walking against walls (festival and game);
  - facing flicker; slow-movement shuffle;
  - a second stick threshold in the festival.
- **Camera:** shared framing is blended (280.7 → 67.8 px of camera travel while Arin hovers at the old switch). A plain mode exists for movement playtests (`--camera-plain` / `?camera=plain`).
- **Story:**
  - Wren's well belief is her fear, not a rule (ST-1).
  - Both chalk-mark orders are consistent (ST-2).
  - A truth / belief / observed table exists (`production/TRUTH_TABLE.md`).
- **Wren:** her chalk game is playable. She leads it, judges only what she walks over to see, refuses a bad mark, fixes the R, answers Rue hiding at her X, and the ending remembers it (`production/WREN_ARC.md`).

| Check | Result |
| --- | --- |
| Strict full suite | **747/747**, 1622.5 s, no script errors (on `f8e9313`). The `2ed3eb4` changes are re-run in focus: `test_remapping` 6/6 (twice), `test_suspend` 11/11, `test_menus` 6/6 |
| Ending bot routes | escape, message, purge-5 and wren pass. **purge-3 escape: 2 of 3 runs pass** on this revision; **1 of 2 at `b26aba0`**, the same failure (three Arin catches in the square). An existing instability (PL-4), not a regression; not fixed |
| Movement acceptance route | `docs/review/movement/ROUTE_RESULTS.md`: zero arrival error, penetration, foot slide and facing flips at 1/144 to 0.1 s frames; no walking while blocked in the game |
| Camera comparison | `docs/review/movement/camera_fixed_current_proposed.jpg` (xvfb with llvmpipe, scripted input) |
| Windows / Linux / Web exports | All exit 0 on `2ed3eb4`. SHA-256 prefixes: exe `7d98891ff7e7bbef`, x86_64 `54c053d10869fc64` (pck embedded) |
| Linux exported smoke | 240 frames, exit 0 |
| Browser lifecycle + story reader | All pass on `2ed3eb4`, no page errors (headless Chromium). Includes a tab closed at a calm moment: no leave prompt, reopened as `suspend`, 0 quits, 0 purge |
| Playable build | https://claude.ai/artifact/3G95pCn7jTAYr2DPmmWu5w, **version 21**, from this code. Private until shared |

**Not verified:**
- **No person has played any of it.** The playtest protocol is ready but not run (`PLAYTEST_PLAN.md`, "trust and one relationship").
- No Windows execution, no physical controller, no hardware GPU.
- Browser storage durability is defined but not tested in a private window.
- Nothing here shows whether players care about Wren. That is the next gate.

## Previous: Save and exit, and Wren's arc (2026-10-27, `483ac8f`)

**Author decisions:**
- **Wren** is the deep relationship.
- **Save and exit:** the choice was delegated, and option (b) was built.

**Details:** [`SAVE_AND_EXIT_PROPOSAL.md`](SAVE_AND_EXIT_PROPOSAL.md) and [`production/WREN_ARC.md`](production/WREN_ARC.md).

**Verification:** strict full suite **705/705**, 1540.2 s, no script errors, on a tree identical to `483ac8f`.

**Playable build:** https://claude.ai/artifact/3G95pCn7jTAYr2DPmmWu5w, version 19, built from code identical to `7ad88a8`. It is private to its owner until shared. Packaged build: `web_check.cjs` all pass, story reader all pass, no page errors (headless Chromium).

**Not verified:** nobody has played either change.

## Previous: the festival's break rebuilt (2026-10-27, branch `claude/last-save-file-prototype-ljwuq4`)

**Code revision:** `08ab155`, based on `main` @ `6fb8e23`. Not merged.

**What changed in the opening** ([`production/OPENING_BEATS.md`](production/OPENING_BEATS.md)):
- **The fifth lantern needs both players.** Halfway through the shared hold, Player 1's half stops. Arin freezes, the music cuts, and about 2.5 s pass before the notification.
- **Trying alone stalls.**
- **The player lights it.** After Player 2 leaves, the player lights it with no controller held: the first impossible action.

**Planning documents:** the M1 evidence pages are in `docs/production/`.

| Check (on the `08ab155` tree) | Result |
| --- | --- |
| Baseline `6fb8e23` strict suite | 691/691, 1527.3 s |
| Strict full suite | 692/693 on the first run (one intermittent failure, PL-8), then **693/693**, 1536.7 s; no script errors |
| Windows / Linux / Web exports | All exit 0. SHA-256 prefixes: exe `8ad2a49c4c7b8749`, x86_64 `9cb01522d6f79ca0`, pck `f798744185896d0e` |
| Linux exported smoke | 240 headless frames, exit 0 |
| Browser lifecycle (`web_check.cjs`) | All pass; no page errors |
| Exported story reader | All pass |
| Festival frames and timing tours | Pass. Prompt path: Player 1 stops 17.9 s, she lights the fifth 27.7 s, in the room 88.4 s (wall, llvmpipe) |

**Not verified:** Windows execution, hardware GPU, a physical controller, and unfamiliar players. This is not a release claim. The ObjectDB exit warning is still printed.

## Previous: verified integration and player-paced festival (2026-10-26)

The author requested integrating the review branch into **main**. Source
branch `claude/last-save-file-prototype-ljwuq4` at `095ab8c` is integrated
through `791d9b1`. Added runtime work is `9f1c191`; subsequent verification
and documentation changes do not alter the runtime. See
[`IMPLEMENTATION_OCT26.md`](IMPLEMENTATION_OCT26.md) for scope, screenshots,
commands, evidence and outstanding work.

- **Integrated:** the playable festival, dimensional/shadowed title, wider
  Square and camera, missions, character revision, persistent relationships,
  archive and earlier recovery anchor with Wren's checkpoint scene.
- **Added:** player-paced festival story breaks, a shared ritual, correctly
  labelled outside speakers, persistent acknowledged transcripts, safe input
  handoff and virtual-control cancellation. Loading flicker now respects
  Reduce flashing independently of Reduce motion.
- **Canon:** Rue remains the game character left running after her player
  moved away, as decided by the author; the well keeps recordings.

| Check | Result |
| --- | --- |
| Strict full suite | **691/691**, 1489.5 s, exit 0; 96 files, 691 unique cases, no script errors |
| Ending bot routes | **5/5**, 244.8 s; no deaths; three recovered steering stalls on purge-3 escape |
| Windows / Linux / Web exports | All exit 0; local hashes recorded |
| Linux exported smoke | 240 headless frames, exit 0 |
| Rendered tour | **1/1**, 12.9 s; large text, historical message, revelation, room handoff |
| Browser lifecycle | Title, festival, skip, input, save, leave guard and reopen pass; no page errors |
| Browser audio graph | Audible after gesture; no visible badge; no page errors |
| Exported story reader | Real keyboard and Continue click acknowledge separate pages; transcript saved; no session/purge charged |

Browser/rendered results use software rendering, not a hardware GPU profile.
The existing ObjectDB shutdown warning is still printed, not suppressed.
**Not verified:** Windows gameplay, iPhone, physical controller, human
listening or unfamiliar-player comprehension. Final commissioned art,
recorded acting, other map redesigns and Save and Exit remain unfinished.
This milestone is not a claim of commercial 1.0 readiness.

The Windows build is packaged locally and main's GitHub Actions workflow
rebuilds it for artifact download. An exported executable is not evidence
that a Windows PC has run it; a queued CI run is not a finished download.

## Previous: the first ten minutes rebuilt (2026-10-24, afternoon)

**Branch:** `claude/last-save-file-prototype-ljwuq4`. PR #10 is still a
**draft, not merged**; `main` is `09aeb3b`. The brief is
`docs/prompts/INTRO_HOOK_REBUILD_PROMPT.md`; everything else (audit, design,
ledger, measurements, author questions) is in `docs/INTRO_REBUILD.md`, and
the art direction in `docs/ART_BIBLE.md`.

- **The festival** (a playable prologue) replaces the opening film on a
  first run:
  - control at 0.1 s;
  - first decision at 15.6 s;
  - 3 YEARS LATER at 36.7 s on the prompt path (2:34 with no input);
  - a skip reaches the present in 0.8 s.
- **Missions:** one active mission in every first-hour map, read from the
  save, so old saves open on the mission they have reached. The
  festival's payoffs are in place: Mira, Wren, Tobben, the Archive's log,
  the lantern by the well and at Slot 2, and the message ending.
- **The cast is redrawn:** `HeroFigure`, with an artist-sheet pipeline and
  fallback. Frame time is within 10% (worst measured +8.2%, the house;
  software renderer). Procedural, not final art (Q4).
- **Story leaks:** three lines where Rue spoke as the girl are rewritten.
  Memories play in a "REPLAY · P2 · …" frame. The chronology has the
  festival.
- **Defects found and fixed (ledger D1–D4):**
  - the goal ignored the pointer;
  - a festival line dropped the reunion greeting;
  - two missing glyphs;
  - no touch controls in the festival.
- **CI:** the web check expected the old film, so CI was red on `dfdb29e`
  and `f4a0cae`. Fixed: it now expects the festival and skips it.
- **Suite:** 680 of 681 in the final full run. The one failure was the voice manifest, out of date after the message-ending line was added. It was regenerated, and that test file then passed 3/3.
- **Bots:** the same machine, baseline `0b8f0d9` against this state:
  - baseline 4/5, failing escape purge 3 (the owner wins);
  - this state 4/5 twice: escape purge 3 failed once and passed once; escape purge 5 failed once.
  - purge 5 alone then passed 2/2 on both.
  - Per route: purge 3 at 0/1 against 1/2, purge 5 at 3/3 against 3/4, every other route passing every run.
  - That is within the variance both states show; no regression is claimed or ruled out.
- **Exports:** Linux, Windows and Web all exit 0. The web check passes in headless Chromium: the festival plays and Esc skips it, the run is playable after 1.7 s of game time, and there are no page errors.
- **Not done:**
  - no unfamiliar players were available: the protocol and the
    instrumentation are ready (`PLAYTEST_PLAN.md`, the festival round);
  - no hand-drawn art;
  - no hardware GPU number;
  - nothing published or bought.
- **Open author decisions:** Q1–Q5 in `INTRO_REBUILD.md` §4.

## Previous: consistency, characters and places (2026-10-24)

**Branch:** `claude/last-save-file-prototype-ljwuq4`. PR #10 is still a
**draft, not merged**; `main` is `09aeb3b`. The review started from
`34b6823`. Everything is in `docs/REVIEW_OCT24.md`; the chronology is in
`docs/STORY_CHRONOLOGY.md`.

- **Fixed, each with a regression that failed first:**
  - facts were learned before their line was on screen;
  - off-screen NPCs were recorded as seen;
  - Tobben's reports stacked;
  - the pagination limit was ignored;
  - the message ending's wording was ambiguous;
  - the tip covered the glitch prompt at the largest text.
- **Characters:**
  - Rue's first press of her own, at Arin's save point;
  - Mira hears that her note is still up;
  - Wren waves Rue over before she explains;
  - a kept promise widens Wren's shelter;
  - the Archivist speaks four lines, with the rest as topics;
  - Pip stays at Rue's heel and greets her on return.
- **Places:** what changed stays visible; the Archive has an arrival and
  alcoves; the cast lean into their first step.
- **Measured:**
  - the opening's wall-clock times on four paths;
  - the Square with Arin active (72 runs, 0 deaths);
  - CPU frame time on a software renderer (no GPU figure claimed);
  - the exported Linux build's start and quit.
- **Suite:** 643 passed, 0 failed.
- **Bots:** 4 of 5 passed in the first run. The purge-3 bot failed once,
  passed in 2 of 3 reruns, and shows the same pattern on the baseline.
- **Exports:** Linux, Windows and Web export; the web title loads with no
  console errors.
- **Not done:** no unfamiliar players were available; there is no
  hardware GPU number; House, Out of Bounds, the Bin and the Edge were not
  recomposed.
- **Open author decisions:** listed at the end of `REVIEW_OCT24.md`
  (opening auto-play waits, Suspend, the demo endpoint, the act card, and
  the cost of Rue's press).

## Previous: opening, character and world revision (2026-10-22, evening)

**Branch:** `claude/last-save-file-prototype-ljwuq4`.
- PR #10 is a **draft, not merged**. `main` is at `09aeb3b`.
- The review started from `59d4d21`.

**Canon: decided.** The author chose `main`'s premise on 2026-10-22 (Rue
is the game character left running after her player moved away;
`CANON_DECISIONS.md` §1). The disputed text was reverted to `main`'s. The
other author decisions (§2–§6) are still open.

**What changed:** the evidence ledger, storyboard, control map and
character matrix are in `docs/OPENING_REVIEW.md`. In short:
- input: separate focus and controller holds, only the player's pad
  counts, no lost press;
- Archivist semantics;
- canon;
- opening staging;
- Rue's own gesture;
- tips moved off the scene;
- a first-session route test;
- bot replanning and an independent RNG for the static and the cursor
  (follow-up work).

**Local results:**

| Check | Head | Result |
|---|---|---|
| Strict suite | `fffaec8` | **614 passed, 0 failed** (1,448 s) |
| Suite after the last commit (`afb3bc0`: a warning gate and test messages only) | `afb3bc0` | Affected files 22/22; no new warnings |
| Ending bots (`--bots --speed=3`) | `fffaec8` | **5/5 exact endings, 0 deaths**; one stall (purge 5) |
| Web, Windows, Linux exports | `afb3bc0` | Exit 0; no errors or warnings in the export logs |
| Linux smoke (CI command) | `afb3bc0` | Exit 0 |
| `web_check.cjs` / `audio_output_check.cjs` | `afb3bc0` | All passed; audible after a gesture; no page errors |

**The purge-5 Edge has a real failure rate (bot, not players).** Across
repeated purge-5 runs on these heads, a run with one static death in the
Edge is common: 3 of 6 on the current code, 2 of 4 with the old shared RNG
on the same code, and 2 of 10 on `f18d219`. Two of 17 current runs were
purged. Code reading and the A/B both show the static's distribution is
unchanged, and the difference from the older baseline is within sampling
noise. Recorded, not tuned: tuning the Edge at purge 5 would be a balance
change for the author.

**Warnings in the suite log (`fffaec8`):**
- Expected: broken-JSON save tests (`Parse JSON failed` ×3, `SafeFile`
  ×3).
- Fixed in `afb3bc0`: `event archivist.intro_pending isn't in
  Relationships.EVENTS` (now an internal event) and `not all arguments
  converted during string formatting` (test messages).
- Still present: `ObjectDB instances leaked at exit`. The audio part was
  fixed earlier (quit now waits for the audio thread). A death
  sequence's pending `SceneTreeTimer` can still remain, which is Godot
  4.3's handling of a freed node's coroutine.

**CI:**
- Runs on `2779940`, `9c33a86`, `ebe22e3`, `1db5573`, `22ff90d` and
  `e135a27` failed one test, `test_cohesion_story.test_the_pointer_is_kept_between_runs`:
  an older save was told the Archivist's introduction again.
- Fixed in `fffaec8`. CI on the final head is linked from PR #10.

**Playable build:** https://claude.ai/artifact/3G95pCn7jTAYr2DPmmWu5w,
version 18, built from `afb3bc0`. It is private to its owner until shared.

**Not verified:**
- Windows execution
- real controllers (pad loss was injected, not unplugged)
- a real GPU
- human listening
- unfamiliar players. None were observed; the protocol and the playtest
  log are ready (`PLAYTEST_PLAN.md`).

## Previous: review milestone after the vertical slice (2026-10-22, morning)

**Branch:** `claude/last-save-file-prototype-ljwuq4`.
- PR #10 is a **draft, not merged**. `main` is at `09aeb3b`.
- Runtime code changed after `537df8c`: the vertical slice, then the
  22 October review fixes. The previous "documents only" note below is
  history, not the current state.

**Canon:** still **proposed**, and needs the author's decision
(`docs/CANON_DECISIONS.md`). Nothing on this branch is approved canon.

**Last fully green CI:** run 134 (`33145ea`),
https://github.com/makedonskivasil3-sketch/The-Last-Save-File/actions/runs/39781409580
- It covered the strict suite, five ending bots, Web, Windows and Linux
  exports, browser audio and lifecycle checks, and the Linux smoke test.
- Runs 132 (`2880d5b`) and 133 (`2785c6e`) were also green.
- **Run 131 (`2cb42dd`) failed and stays on record.** The purge-3 bot was
  left in the Edge's corner by the owner's reload, stalled, and was
  erased. That death seeded the static that caught it twice more in the
  Square. The harness now replans once per stall with the area's NavGrid
  (`33145ea`). Stalls are still counted and printed; nothing teleports.
- CI on the later heads is linked from PR #10.

**This milestone (22 October review), local results:**

| Check | Head | Result |
|---|---|---|
| Strict suite (`tests/run.sh`) | `0773f52` | **581 passed, 0 failed** (1,304 s) |
| Same, one revision earlier | `2785c6e` | 580/581. `test_cursor_drags_the_crates_across_the_road` timed out; it passed alone. The cursor now enters the wider Square from ~300 px further east, so the wait was raised from 22 s to 40 s (`0773f52`). |
| Ending bots (`--bots --speed=3`) | `0773f52` | **5/5**: escape, message, escape at purge 3, escape at purge 5, Wren. **0 deaths.** The purge-3 run logged **15 stalls** in the Edge (recovered by replanning); the others logged 0 |
| Web, Windows, Linux exports | `0773f52` | Exit 0; no errors or warnings in the export logs |
| Linux smoke (CI command) | `0773f52` | Exit 0 |
| `web_check.cjs` (Chromium) | `0773f52` | All passed, including keyboard movement, save on close and no page errors |
| `audio_output_check.cjs` | `0773f52` | Audible after a gesture; no clipping; no page errors |

**Warnings in the suite log (`0773f52`), each investigated, none
suppressed:**
- `Parse JSON failed` (×3) and `SafeFile … unreadable / recovered` (×3):
  the save-safety tests feed broken files on purpose.
- `Sfx: unknown sound 'death_arin'`: a **test bug**.
  `test_places_survive_a_retry` called `kill("arin")`; Arin's real catch
  is `kill("overwritten", "arin")`. The test is fixed and the warning has
  gone.
- `ObjectDB instances leaked at exit` and `resources still in use`: the
  known shutdown diagnostic (A14 in `CONTINUITY_MILESTONE.md`). Still
  unresolved, and not claimed fixed.

**Playable build:** https://claude.ai/artifact/3G95pCn7jTAYr2DPmmWu5w
(version 17, built from `0773f52`). Private to its owner until shared.

**Not verified:**
- Windows execution (an export is not a playtest)
- an iPhone
- a real GPU or gamepad
- human listening
- uncoached players

None of these is claimed.

## Previous: coherence milestone, review branch (2026-10-21)

Branch: `claude/last-save-file-prototype-ljwuq4` (PR #10, draft, **not
merged**). `main` = `09aeb3b`. The code head is `537df8c`; later commits
are documents only. The evidence and the remaining work are in
`docs/COHERENCE_MILESTONE.md`. The contract is
`docs/NARRATIVE_CONTRACT.md`, **proposed** (revision 2, §0).

**Behaviour changes, each documented and tested:**
- **Save v3, migrated from v2.** Ordered, counted relationship events.
  Learned facts. Archive marks by revision.
- **One selection path for conversations.** Mira and Tobben react to
  what happened between you. A consequence is said once, when it's read
  whole; it waits for the next meeting, however many runs later.
- **The archive** says only what Rue saw, was told, thinks, or doesn't
  know. It gives each object one status, marks updated entries, and keeps
  the reader's place.
- **The map** keeps every place found across runs.
- **The kept place** under the well is offered earlier (after the well's
  tune), and Rue chooses it. Answering the well no longer sets it.
  Quit and crash rules are unchanged.
- **The well's evidence** is honest: a recording, not live contact.
- **The opening's last shot** matches canon.
- **The browser check** measures startup and bounds it by game time.

**Verification on `537df8c`:**

| Check | Result |
|---|---|
| Strict full suite (one complete monolithic run) | **547/547**, 1238.3 s, exit 0; 547 unique cases across all 81 test files |
| Ending bots `--speed=3` | **5/5** exact endings. Two Edge deaths with retries (escape at purge 0 and at purge 3); 14 recovered bot stalls in total |
| Exports | Web, Windows Desktop, Linux: exit 0. SHA-256 prefixes: exe `a502defdd9b4`, linux `4636f527b6af`, pck `fc6243607296`, wasm `fe5cebc59075` |
| Linux binary | 300 frames under xvfb, exit 0 (no audio device in the container) |
| `web_check.cjs` | All passed. Playable after 6.0 s of game time (55.3 s wall on SwiftShader) |
| `audio_output_check.cjs` | Audible after a gesture, "running", **no visible badge** |
| Shutdown | ObjectDB warning still printed at the full suite's exit (A14). Owners identified; not filtered |

**Not verified:**
- Windows execution
- an iPhone
- a real GPU, a phone or a gamepad
- human listening
- uncoached players

None of these is claimed.

## Previous: continuity milestone, review branch (2026-10-21)

Branch: `claude/last-save-file-prototype-ljwuq4`, not merged. `main` (now
`09aeb3b`, with PR #9) was merged into it. Where PR #9 and this branch
built the same thing, PR #9's version was kept: the portrait resources,
caption paging and the speech-rate setting. The numbers below were
measured before that merge; see "After merging main" for the re-run.
It carries two milestones:
- **Live-art milestone** (`cc76537`…`a38049f`): portrait art route, caption
  pages, character states, console pacing, timed glitches, speech rate.
- **Continuity milestone** (`8256c29`…`3fea14f`). Contract:
  `docs/NARRATIVE_CONTRACT.md` (**proposed**). Evidence:
  `docs/CONTINUITY_MILESTONE.md`.

**New canon (proposed, needs the author's approval):** Rue is the part of
the second player that stayed in an interrupted save.

**Behaviour changes, each documented and tested:**
- Lasting encounters, conversations and relationship events (save v2,
  migrated from v1). Wren's reunions react to what she saw.
- A six-section archive.
- One checkpoint: after a death you wake under the well once the well has
  your answer. Quit and crash still start in the room; purge rules are
  unchanged.
- The well's five-step sequence.
- A 45 s opening animatic.
- The visible iPhone sound badge is removed. Audio recovery is kept.

**Verification on this branch:**

| Check | Result |
|---|---|
| Strict full suite, live-art head `a38049f` | 496/496 (1165.8 s, exit 0) |
| Strict full suite, continuity code `dc372e9` | **517/517** (1211.1 s, exit 0) |
| After `dc372e9` | One code change, the history ordering in `3fea14f`; its suites (continuity, archive) pass 13/13. The full suite was not re-run after it. |
| Ending bots, `--speed=3` | 5/5 exact endings: escape, message, escape at purge 3, escape at purge 5, Wren. One Edge death with retry; one recovered stall on the Wren route. |
| Exports at `3fea14f` | Web, Windows Desktop, Linux: exit 0. SHA-256: exe `7539e4e5…`, linux `64807693…`, web pck `fccc6a68…`, wasm `fe5cebc5…` |
| Linux binary run | 300 frames under xvfb, exit 0. No script errors; only the container's missing audio device is reported. |
| Headless Chromium `web_check.cjs` | All passed: title, opening, skip, playable, keyboard, save, leave guard, quit counted, no page errors |
| Headless Chromium `audio_output_check.cjs` | Audible after a gesture; `soundState` "running"; **no visible badge**; no clipping |
| Captures | `docs/review/continuity/` (opening before and after, the slice, the archive) |
| **After merging main** (`d527151`, with PR #9) | Strict full suite **523/523** (1215.2 s, exit 0), including PR #9's own tests. Ending bots 5/5: the escape at purge 3 took 4 sessions and 3 deaths this run; the other routes had no deaths. Web, Windows and Linux exports exit 0. Both headless-Chromium checks pass, with no visible badge. |
| PR CI | Passed on `d527151` (run 109, with downloadable Windows, Linux and Web artifacts). On `1b6f053` (a docs-only change) the export job first failed `web_check`'s "run becomes playable" step: the boot scene was still open at the 90 s limit on the slow software-rendered runner. One re-run passed. It failed the same way again on `d27d106` (also docs-only), so it was treated as real. Cause: the check's 90 s budget, not the game. At 12× CPU throttling, `main` and this branch both reach a playable run at 54.6 s, and the same code has passed and failed on CI. The budget is now 240 s (`tests/web/web_check.cjs`); the check passes locally both throttled and unthrottled. |

**Not verified:**
- Windows execution
- a real iPhone
- real GPU, phone or gamepad
- human listening
- uncoached players

The questions for players are in `CONTINUITY_MILESTONE.md`. No player
results exist, and none are claimed.

**A playable build is available through:**
- the private web artifact (owner's link);
- the PR's CI run, which uploads a Windows zip (`.github/workflows/build.yml`)
  once it completes.

A running CI job is not a finished build.

## Prompt implementation on main, PR #9 (2026-10-21)

Runtime `eec7e576` preserves combined main `1e371b1` and implements the supplied
prompts' first presentation milestone: live approved portrait resources with
palette-safe fallback, continuous recording playback across readable caption
pages, coherent world/portrait speaking and gaze, and an independent system-
speech rate preference. No new production artwork or recorded cast is claimed.

See [PROMPT_IMPLEMENTATION.md](PROMPT_IMPLEMENTATION.md) for implementation,
evidence and remaining scope, [CAPTION_VOICE_CONTRACT.md](CAPTION_VOICE_CONTRACT.md)
for route semantics, and [PORTRAIT_ASSETS.md](PORTRAIT_ASSETS.md) for the asset
contract. All **482 unique cases across 71 files** passed in isolated coverage,
including a correctly uncapped **6/6 CPU-budget rerun** after a verifier-cap
failure. This is not a completed monolithic local run. Focused actual-HUD
compatibility: **18/18**; exact-ending bots **5/5**; staged rendered checks **2/2**.
The message bot required one death/retry and 17 recovered navigation stalls;
other acceptance routes reported zero deaths/stalls. CI/export/browser status
is tracked separately in PR #9, not inferred from older builds.

The first-room/Square and wider map milestones remain open, as do authored
assets, human listening/playtests, Windows execution, real GPU/device/input
checks and shutdown diagnostics. The game remains a late prototype.

## Previous combined presentation/functionality revision (2026-10-21)

The combined branch retains main `2644629` / PR #8 (`2ffc036`): finale cursor
ownership, reading-held confrontation transitions, completed-objective clearing,
gaze hysteresis/turns and reduced-flashing brackets. It adds `e69ab5c` live
portrait clocks/system-speech mouth activity and `9117b18` cancellation of a
navigation refresh when its area leaves the tree. Test-only `3ee11fc` makes
failed screenshot saves fail visual checks. Save and balance rules are intact.

See [PRESENTATION_FUNCTIONALITY_AUDIT.md](PRESENTATION_FUNCTIONALITY_AUDIT.md)
for the combined results, evidence and remaining issues;
[PRESENTATION_GAMEPLAY_FOLLOWUP_PROMPT.md](PRESENTATION_GAMEPLAY_FOLLOWUP_PROMPT.md)
is the updated detailed assignment, incorporating the incoming revision.
Its future work is not presented as completed. Earlier verification below
belongs to its own source hash, not automatically to the combined runtime.
Combined runtime `1c21266` completed **471/471 headless tests** (1063.9 s,
exit 0), five exact-ending bots and Web/Windows/Linux exports. Current browser
lifecycle/audio and three rendered checks passed. Bots recorded four recovered
escape-route stalls and one message-route death/retry; ObjectDB/resource
shutdown warnings remain. Full logs and build checksums are in the audit.
The final evidence commit changes no gameplay code; remote CI is tracked
separately after publication.
The game remains a late prototype: human listening/playtesting, Windows
execution and real-GPU/device checks remain outstanding.

## Historical PR #8 code and experience revision (2026-10-21)

Runtime `2ffc036` completed 468 headless tests, 40 focused tests and five
exact-ending bots in its recorded environment. Purge-3 bots recorded two
recovered stalls. Its evidence remains in [REVISION_OCT21.md](REVISION_OCT21.md),
with its original next brief in [NEXT_GAMEPLAY_VISUAL_PROMPT.md](NEXT_GAMEPLAY_VISUAL_PROMPT.md).
Those earlier results do not substitute for the final combined check.

## Historical integration follow-up (2026-10-21)

The local opening/cast changes and every fetched remote branch have been
integrated on `codex/integration-follow-up`. Runtime source is `2b3e70d`.
See [INTEGRATION_FOLLOWUP_RESULTS.md](INTEGRATION_FOLLOWUP_RESULTS.md) for the
current results and limitations, and [INTEGRATION_FOLLOWUP_PROMPT.md](INTEGRATION_FOLLOWUP_PROMPT.md)
for the detailed prompt written before the new repairs and then executed.
Historical “not pushed/merged” statements below describe their original pass.
Publication status is recorded in the integration report after verification.
The game remains a late prototype pending human and hardware validation.

## Historical local follow-up: opening and cast review (2026-10-20)

Local branch `codex/opening-cast-review`, based on fetched PR #7 head
`decaf1f7`. Runtime changes: `7a5142a` and `afb44e7`. Nothing from this follow-up
has been pushed, merged or deployed. The advertised unpublished `a918b79`
work was not available; `codex/map-experience` on GitHub contains the earlier
pass-8 code, not that patch.

See [OPENING_CAST_REVIEW.md](OPENING_CAST_REVIEW.md) for the findings ledger,
preserved/missing features, scope, and uncoached playtest plan, and
[OPENING_CAST_RESULTS.md](OPENING_CAST_RESULTS.md) for current verification.
The pass-8 results below remain historical, not evidence for the new code.
Stage remains a late prototype: human playtesting, listened-to audio,
Windows execution and real hardware measurements are still pending.

## Historical status (2026-10-20, pass 8): `claude/last-save-file-prototype-ljwuq4`

**Stage:** a complete vertical slice / late prototype. **Not** a release candidate. Unmet: a human playtest (none run), listening (none), a real-GPU measurement (none), Windows, phone and gamepad runs (none), recorded voices (none ship). Not merged, nothing deployed by this pass.

**Pass 8: consistent rules, a navigation lifecycle, a deliberate finale, faster retries, a visible art pass.** Details and evidence are in `GAMEPLAY_CONSISTENCY.md` (pass 8) and `VISUAL_DIRECTION.md` (pass 8); captures are in `docs/review/pass8/`.

| Area | Implemented | Automated | Visually inspected | Human / hardware |
|---|---|---|---|---|
| One protection rule: act and NEW GLITCH cards hold the owner everywhere, small text never does; no banked click | Yes | `test_pass8` (4) | — | Pending |
| Navigation lifecycle: grid versions, partial refresh after physics, doors/wall/crates notify, walkers replan, watch ends on a new way | Yes | `test_pass8` (4) | — | — |
| Recovery by depenetration (never deepens, never crosses); body-safe path ends | Yes | `test_pass8` (3), `test_threat_navigation` | — | — |
| Finale: Slot 2 finished before the grab is a deliberate, clean outcome | Yes | `test_pass8` (2), `test_confrontation` | Edge phases sheet | Pending |
| Retry after an Edge death: the seam is already open | Yes | `test_pass8` (2), `tour_retry` (40.5 → 14.0 s at purge 1) | — | Pending |
| Edge grey-box geometry, compact banner, softer text, wall faces, motion weight | Yes | Existing suites | `before_after.jpg`, `edge_phases.jpg` | Pending |
| Title in every state; reflow then focus-following scroll | Yes | `test_the_title_menu_fits…` | `title_states.jpg` | Pending |
| Balance as a system: a closet at purge 4 against every threat; a purge-5 ending bot | Yes | `test_pass8`, `test_full_game_escape_purge_5` | — | Pending |

| Commit | Check | Result |
|---|---|---|
| `306a53f` | Full suite (local) | 453 passed, 0 failed |
| `306a53f` | Bots, speed 3 (escape, message, escape purge 3, escape purge 5, Wren) | 5/5 reached their exact ending |
| `306a53f` | `web_check` ×3 | 2 of 3 passed; 1 missed the browser's beforeunload dialog (the check then waited a fixed 1.5 s) |
| `aa45cf2` | `web_check` ×2 (now: guard armed, bounded wait for the dialog) | 2/2 all pass (and 4/4 on the same check before the final commit) |
| `aa45cf2` | `audio_output_check` | Audible |
| `aa45cf2` | Full suite (local) | 453 passed, 0 failed |
| CI | PR #7 | Earlier commits in this pass failed CI: the card hold changed timing in 13 tests (fixed in `84bdd15` and `306a53f`), and the browser check pressed E into the world (`48ffbd4`). See the PR for the run on the head commit |

**Save compatibility:** no save fields were added or changed. `slot2_beaten` is a run-only flag. Settings are unchanged.

## Status at pass 7 (2026-10-20)

**Stage:** a complete, polished **vertical slice / late prototype**. Every planned area, threat, ending and system is in and covered by automated checks. Nothing a real player experienced has been observed yet. **Not** a release candidate (same unmet items as below).

**Pass 7** (three read-only reviews, then fixes; details in `GAMEPLAY_CONSISTENCY.md`, pass 7):

| Area | Implemented | Automated | Visually inspected | Human / hardware |
|---|---|---|---|---|
| Title key art and asymmetric layout (`TitleArt`, `UiStyle.side_panel`) | Yes | Title/menu suites | `tour_visual` 00/01 | First-impression opinion pending |
| Fairness: hidden stops save-over; square cursor capped and spawned away; purge rate capped at 3; no static under Rue on arrival; room exempt from truce slowdown; seam hint; truthful death tips | Yes | `test_pass7` (5), full suite | — | Pending |
| Story: truth-aware end cards and apology; Archivist's stake; reveal no longer contradicts memories 4–5; pronoun fixes; canon header | Yes | `test_pass7`, `test_canon`, `test_voice_manifest` | — | Reading pending |
| Open for the author: Edge retry distance (checkpoint proposal); quit/purge on phones; the escape card's "doesn't know this slot survived" | — | — | — | Author's call |

| Commit | Check | Result |
|---|---|---|
| `ba3fcdd` | Full suite (local and CI) | 435 passed, 1 failed (`test_canon`: an author-decided line I had changed; restored in `12077ed`) |
| `12077ed` | `test_canon`, `test_pass7`, `test_voice_manifest`; bots (4 exact endings) | 12/12; 4/4 |
| `12077ed` | `web_check` (headless Chromium), `audio_output_check` | Lifecycle: 2 of 3 runs all-pass; one run missed the beforeunload dialog (intermittent, watch in CI). Audio: audible |

## Status at pass 6 (2026-10-20)

**Branches:** [PR #7](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/pull/7) on this branch, stacked on [PR #6](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/pull/6). Not merged; nothing deployed. The author asked for both to be merged into `main` and for GitHub Pages; the merge needs to be done on github.com (this session may not merge), and Pages needs *Settings → Pages → Source: GitHub Actions*.

**Release candidate?** No. Unmet: human playtest (none run), listening (none), real-GPU measurement (none), Windows/phone/gamepad runs (none), recorded voice (none ships).

### What changed since pass 4 (passes 5–6)

| Area | Implemented | Automated | Visually inspected | Human / hardware |
|---|---|---|---|---|
| Arin's navigation (grid paths, clearance, recovery, unreachable targets) | Yes | `test_threat_navigation` (9) | — | Pending |
| Edge: valid guard routes, safe arrival, state-tied goals, frozen writing behind text, readable floor | Yes | `test_edge_confrontation`, `test_edge`, `test_confrontation` | `docs/review/pass6/edge_confrontation_sheet.jpg` | Pending |
| Closets as open recesses, cue, status, 4 s chime | Yes | `test_house` | Pass 5 screenshots | Discoverability pending |
| Archive record stands, file emphasis at FILE stage | Yes | `test_gameplay_consistency` | Pass 5 | Discoverability pending |
| Opening film (unnamed P2, skip/replay/captions, focus and input hand-off) | Yes | `test_opening` (9) | `docs/review/pass6/opening_storyboard.jpg` | Comprehension pending (intro on/off variants ready) |
| Phone audio recovery after spoken lines; music under the opening | Yes | `audio_output_check` (headless Chromium: audible) | — | **Listening on an iPhone: pending** |
| Strict browser lifecycle in CI | Yes | `web_check` locally: all pass | — | — |
| Benchmark harness | Yes | Smoke run, 9 workloads valid | — | **Real GPU: pending** (`tools/run_benchmark.sh`) |

### Verification tied to commits

| Commit | Check | Result |
|---|---|---|
| `c7293fe` | Full suite (local) | 425 passed, 0 failed |
| `ade8215` | CI (GitHub) | Passed |
| later commits | Full suite, bots, CI | See the PR; results are not carried forward from earlier commits |

### Measuring on a real GPU

`GODOT=/path/to/Godot_v4.3-stable tools/run_benchmark.sh` on the machine to measure (windowed, nothing heavy running). It needs the Godot 4.3 editor binary and this repository (the harness lives with the tests, which exports leave out). Output: `benchmark-<commit>.json` plus a console table. Each of gameplay (room, square calm, square hunted with Wren, Archive with a portrait on screen, house visit, Edge spreading), stress (CRT and full effects while hunted), transitions and the opening is checked throughout capture; anything that stops being what its label says is listed under `invalid`, never averaged in. Software renderers (llvmpipe, SwiftShader…) are flagged as not a hardware GPU. GPU time is **not** measured separately (frame time is wall clock; CPU time is Godot's process monitor). Development-only change: `World.bench_immune` keeps Rue alive; threats run as in play.

---

## Status at pass 4 (2026-10-20): `claude/last-save-file-prototype-ljwuq4` (pass 4)

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

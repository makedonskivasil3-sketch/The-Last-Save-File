# Issue register

## Current update — 2026-11-06

See [the implementation and evidence](../review/nov6-touch/IMPLEMENTATION.md) for
baseline `8112117` and touch fixes `ac3786d` / `9c99122`.

| ID | Class | Sev | Problem | Status / evidence | Remaining verification |
|---|---|---|---|---|---|
| IN-6 | D | S2 | Fresh virtual E after dialogue could be rejected; multiple fingers could lose a hold | Implemented: gesture identity and shared ownership; `test_touch_reliability` | Physical phones |
| IN-7 | D | S2 | Opening Skip depended on mouse emulation; memory card lacked dedicated touch controls | Implemented: owned raw-touch Continue and hold Skip; native and exported-browser checks | Physical phones, device switching |
| IN-8 | D | S2 | Focus loss did not synchronously clear the reasserted interaction action | Caught by full suite; corrected in `9c99122`; all 26 touch checks pass | Final full-suite result in implementation report |
| QA-3 | R | S3 | Two headless Godot 4.3 processes crashed with thread-access errors during shared-tree verification | Preserved raw logs in the November 6 review; isolated-source full rerun recorded there. Cause not established; do not suppress the error | Reproduce independently; distinguish test/import environment from exported gameplay |
| DS-1 | H | S3 | Can unfamiliar players discover RUE naturally? | November 4 proves one continuous playthrough, 3/3 automated routes. The older two-run claim below is superseded | Human discovery, not another mechanic to force a replay |

The older register is retained as history; current readiness and the November 4
comprehension/fairness report supersede its obsolete diagnoses and baseline.

## Register of 2026-10-31 (history)

**Baseline:** `main` @ `adf2710` (runtime `2f03453`; test fixture `335a5f3`), all three verified to exist. Reconciled into `claude/last-save-file-prototype-ljwuq4` by merge `b5db36a`: where this branch and `main` disagreed on doorways, `main` won.

**How to read it:**
- **Class:**
  - **D:** reproduced defect.
  - **R:** code risk needing reproduction.
  - **W:** design weakness.
  - **P:** production gap.
  - **H:** hardware or human verification gap.
  - **X:** historical, already fixed.
- **Sev:** S1 (blocks play or loses progress) to S4 (cosmetic).

| ID | Class | Sev | Problem | Evidence/revision | Player impact | Proposed fix | Verification |
|---|---|---|---|---|---|---|---|
| WS-1 | D | S2 | Workshop steps were two separate writes: the event, then the journal note. Neither result was returned | `LanternRoute.record` @ `adf2710` | A failed second write left "repaired" saved without its note. The feedback said "kept" either way | **Done (`d6fd6ed`):** one write per step (`OwnerMemory.commit_step`); the result is returned, and "NOT SAVED YET" is shown when it fails | `test_workshop_persistence` (failure injection: no half-saved step, retry lands, relaunch restarts the step, no double reward) |
| SV-4 | D | S2 | Ordinary progress writes fail silently. Only Save and Exit was transactional | `OwnerMemory.save_memory` sets `last_save_ok`, which nothing reads | Progress shown on screen can vanish on relaunch, with no warning | **Done (`d6fd6ed`):** a failed write sets `unsaved`; the console says so once; the write is retried every 4 s; recovery is announced. The last good save is never touched | Same tests. **Not yet tested on web storage (IndexedDB)** |
| UI-6 | W | S3 | Act cards were tied to areas, so free exploration could show a later act first. This branch's interim fix (numbering by arrival order) still mixed places with story | `world._area_intro` | Contradictory chapter order | **Done (`d6fd6ed`):** places are named on arrival. Chapters follow `Quests.story_mission()` (I–IV, V at the Edge), only forward, stored as `chapter:<id>` in `acts_seen` (no new flag). An old save shows its current chapter once | `test_act_order` (Archive first, well first, workshop, old save, pointer in place) |
| RD-1 | D | S3 | The browser story check failed "Continue click keeps the reply" about 1 in 3 under load. **Cause found: not input, not reveal timing.** The reader acknowledged the page within 58–155 ms every time. The check then read IndexedDB after a fixed 2 s, and Godot syncs `user://` to IndexedDB asynchronously after a write | Probe with CDP CPU throttling and `advance()`/IndexedDB timestamps (2026-10-31). Acknowledgement to stored: 2.0–2.3 s at ×1 (the runner draws 8 fps), 4.7–5.0 s at ×6. Check runs: stored 1.4–3.4 s at ×1, 5.0–5.9 s at ×6 | In-game: none, the page is kept. The check reported a reading defect that wasn't one | **Done (this pass):** the check asserts the reader's acknowledgement (`window.__lsf.read`, within 1.5 s) separately from storage (within `STORY_STORE_MS`, default 15 s). It prints both timings; `STORY_CPU_THROTTLE` repeats it on a slow machine | `prologue_story_check.cjs`: 4/4 at ×1 and ×6 |
| WEB-1 | D | S2 | **Web save contract:** a save is durable only once the browser's IndexedDB sync lands. Measured 0.7–5.9 s at ×1–6 (RD-1) and up to 30.7 s at ×12 (CI-1). Desktop writes and renames on disk before returning | RD-1, CI-1 measurements | **Contract:** a normal tab close at a calm moment writes the suspend on close (free resume passed at every throttle level). An abrupt browser kill within the sync window can lose the latest step or calm mark | Engine-level: no completion signal reaches GDScript. Keep Windows primary; state this on any web page; the browser is a demo or playtest only | Measured in headless Chromium. **A real low-end browser session is open** |
| UI-7 | D | S3 | The title glitch could replace a space ("THE LAST#SAVE FILE"), or a narrow letter with a wider symbol. Either rewrapped the title and dropped every menu button 24 px while the glitch lasted | Shard 4 failure in `test_the_title_room_drifts…`. Reproduced: Load moves from y 149 to 173 | A click could land on the wrong button (Quit sits in the menu) | **Done (`7f9f7e6`):** the glitch never takes a space and is dropped if it would change the title's line count | `test_the_title_glitch_never_moves_the_menu` (every glitch, normal and large text) |
| QA-2 | D | S4 | Test isolation: `test_a_zero_volume_is_named_not_raised` left Music at 0. File order hid it; sharding exposed it | Shard 2 failure; reproduced with the two cases alone | None (tests only) | **Done (`7f9f7e6`):** `before_each` restores the shipped volumes | The two cases pass in order; the full shard passes |
| CI-1 | D | S1 | PR head CI red: web_check's "a calm moment is kept on disk" never saw `last_exit: safe` in IndexedDB within 15 s | Run 41537563245 (`f042ae9`), and earlier at `d9beec1`; the runner draws 1 fps. Reproduced with CDP throttling: the game marked calm at once and never flipped back (safe_marks 1, unsafe_marks 0). IndexedDB stored it 5.2 s (×1), 22.2 s (×6) and 30.7 s (×12) later | A slow runner failed a correct game. The real exposure is WEB-1 | **Fixed (`55141d6`):** the game's decision and the browser's storage are checked separately; storage is bounded at 60 s (about twice the worst measured); `WEB_CPU_THROTTLE` reproduces a slow machine | web_check at ×1, ×6 and ×12, all pass. Waiting for CI on the head |
| EN-1 | D | S2 | 9 `Lambda capture at index 0 was freed` engine errors, hidden by a passing summary | `tests/run.sh` checked only SCRIPT ERROR and Parse Error. Cause: `Area.on_arrival` scheduled each look-up with a lambda capturing the person; leaving within about 1 s freed the captures (this happens in game too) | None visible (the reaction is skipped), but it is a lifetime bug, and the gate hid it | **Fixed (`55141d6`):** a bound method of the area instead. **Gated:** every ERROR or USER ERROR not listed for its exact case in `tests/allowed_engine_errors.txt` fails the run; self-test in CI | 0 in the five affected files; the full sharded run |
| EN-2 | X | S4 | Font errors on a clean checkout's first import | `Inter-Regular.otf` is referenced before it is imported | None: the second import is clean, and the exported smoke run shows no font error. **2026-11-03:** a Linux export built from a fresh clean tree exits 0 with 0 errors, and running it shows no font error | No change: not a release defect | Clean-checkout import, run twice |
| QA-3 | D | S3 | Coverage overstated: a disabled probe counted as PASS; "six endings" claimed from five routes | `bot_playthrough` | False confidence | **Fixed:** SKIP status listed after the summary (`55141d6`). Full-route bots for all six endings: overwrite (`55141d6`), unseen and rue (2026-11-03) | Bot runs; the human round still checks rue and unseen are found |
| DS-1 | W | S3 | **RUE is in practice a second-run ending.** The truth needs all five memories (two are at the Edge). The way back from the Edge passes Arin's gap, the cursor and the square's static at peak awareness | `test_full_game_rue`: going back down died 2 of 2 times. Run 2, starting with every memory, reaches the file safely | Players may not know a second run is where the truth is | **The author decides.** If unintended: a signpost after the first escape, not a mechanic | Player round: does anyone reach the file, and in which run? |
| DM-2 | D | S2 | The workshop demo candidate ended at the Archive if Rue took the stairs before finishing the mission | Old `test_the_stairs_up_still_end_the_candidate_at_the_archive` | The demo could end without its promised finished mission | **Fixed (`55141d6`):** in the candidate the Archive, Bin and Edge ways stay shut with a line pointing to the mission; it ends after Wren notices. Quitting is always in the pause menu | `test_no_wrong_turn_ends_the_candidate_early`, `test_the_arch_demo_still_ends_at_the_arch` |
| CT-1 | D | S3 | Clipping a corner by 1–5 px stopped Rue dead; an [E] tap just before reaching something was lost | Probe in the workshop, 2026-11-02 | The controls feel sticky and unresponsive at the moments players notice most | **Done (`7fa700c`):** corner assist (up to 5 px) and a 200 ms press buffer | `test_controls_feel` (7) |
| TR-1 | X | S3 | Two branches built opposite doorway designs (fast thresholds vs a passage card) | `adf2710` vs `e551c6c` | Mixed travel feel | Reconciled: `main`'s thresholds, facing and short fades. Kept: dust, arrival reactions | `test_world_cohesion`, `test_travel` |
| PL-3 | R | S4 | ObjectDB instances leaked at exit (test runner only) | Verbose suite: timers, tweens and coroutines pending at teardown | None in the exported game (Linux smoke exits clean) | Fix the per-test teardown, not the game | Open; not suppressed |
| PL-4c | H | S3 | Late-purge Edge deaths after a reload (bot 1 in 2 at `7734ab1`) | `RELEASE_READINESS` | May read as unfair at purge 5 | Human play at purge 4–5; Owner pace Gentle exists | At `d9beec1`: 2/2 purge-5 bots reached the ending; one died once at the Edge first. Still needs people |
| DM-1 | W | S3 | The demo ends at the Archive arch, before any complete mission | `World.DEMO_END_AREAS` | The demo shows no completed action or consequence | **Candidate built (`d9beec1`):** `?demo=workshop` ends after the workshop repair and Wren's acknowledgement. The arch demo is kept for comparison. Demo saves are separate | `test_demo` (8). **The choice is the author's, after a playtest** |
| RT-1 | P | S2 | No measured campaign length or route timing with people | No playtest data exists | Price and scope can't be set | Run `playtest/RUN_A_ROUND.md` | Needs people |
| AR-1 | P | S2 | All art is code-drawn: consistent, but programmer art | `PRODUCTION_STANDARD.md` | Weak store presence; the world reads as provisional | Representative section standard; briefs for commissioned sprites (authorisation needed) | Author decision |
| AU-1 | H | S3 | No human listening of the mix; no recorded voice | — | Unknown fatigue and readability | A small pilot with rights and consent | Needs people |
| HW-1 | H | S2 | Never run on Windows, a physical controller or a phone | — | Unknown platform defects | Run on hardware | Needs hardware |
| QA-1 | P | S3 | The monolithic suite at normal game speed takes over an hour | `oct30/VERIFICATION.md` | Slow verification | Four shards with isolated XDG folders, checked against `--list-tests` | Used this pass. Sharding changed case order and exposed UI-7 and QA-2 |
| DC-1 | P | S4 | `docs/` is 56 MB and about 190k words | `du`, `wc` | Slows contributors; stale docs mislead | Archive review captures and pass notes out of the working tree | Open |

---

## History (2026-10-27 onward)


**Opened:** 2026-10-27.

**Baseline:** `main` @ `6fb8e23`. Strict suite reproduced in this session: **691/691**, 1527.3 s, no script errors. The ObjectDB exit warning is still printed.

**Rules:**
- Every row cites evidence: a file and line, a test, a capture or a measurement, tied to a revision.
- "Fixed" means fixed on `claude/last-save-file-prototype-ljwuq4` and verified as the Verification column states. "Fixed" is not a claim of human or hardware verification.

**Severity:**

| Severity | Meaning |
|---|---|
| **S1** | Blocks release |
| **S2** | Damages the experience or trust |
| **S3** | Noticeable |
| **S4** | Polish |

**Status:** open · fixed (verified) · fixed (unverified) · blocked (needs a person or hardware) · author decision.

## The opening

| ID | Sev | Issue | Evidence | Status | Verification |
|---|---|---|---|---|---|
| OP-1 | S2 | Player 1's leaving was announced, not felt: it fired when Arin reached a waypoint (`ARIN_STOPS`), and the toast appeared in the same frame. | `6fb8e23` `scripts/ui/prologue.gd`, P1_LEFT beat | fixed (verified) | Arin's half now stops mid-hold at the fifth lantern; ~2.5 s of silence follow before any text. `test_prologue.test_the_absence_is_felt_before_it_is_named`; frame `after_d0_his_half_stops` |
| OP-2 | S2 | The first impossible action wasn't the player's. "Stayed" self-lit the lantern during the time-lapse; "lit it alone" happened while Player 2 still held the controller. | `6fb8e23` prologue: time-lapse lights `lit[4]`; `choice == "lit"` | fixed (verified) | Trying alone stalls at half: it needs two. After Player 2 leaves, **the player** holds and lights it. Assistance runs only after 24 s idle. Covered by `test_alone_it_needs_two…`, `test_staying_beside_him…` and `test_doing_nothing_still_moves_on` |
| OP-3 | S3 | Player labels read as debug text: plain text floating over the sprites. | `6fb8e23` captures | fixed (verified visually) | Nameplates with plate and underline; at the load, "UNKNOWN ENTITY" / "SLOT 1 · ARIN". Frames in this session only; no human review |
| OP-4 | S3 | Arin's overshoot used the global `randf()`, so replays weren't deterministic and other RNG users were perturbed. | `6fb8e23` prologue | fixed (verified) | Uses `_fx_rng`; prologue tests pass |
| OP-5 | S3 | The "PLAYER 1 HAS LEFT THE SESSION" toast collided with Arin's nameplate. | Frame `after_d_p1_left`, this branch before the fix | fixed (verified visually) | Toast is drawn on a plate sized to its text; re-captured |
| OP-6 | S4 | The fifth lantern's hold arc passes behind Rue's nameplate at the well. | Frame `after_d_p1_left` | fixed (verified visually): a nameplate that would cover the ring steps aside |
| OP-7 | S3 | The rendered timing tour's "no input" path couldn't finish: since `9f1c191` story pages wait for the reader. The tour then read `_awake` on the Prologue, producing script errors in tour output (tours are not in the suite). | `tour_timing_intro`, this session | fixed (verified) | Path renamed "reads only": it acknowledges pages and presses nothing else. Reaches the room at 225.7 s wall |
| OP-8 | S3 | A fully idle player waits ~24 s per step: Player 1 stops at 136 s on the reads-only path. That is long, but it is the documented assistance rule. | `timing_m2` | open (design) | Needs playtest evidence before changing `AUTO_AFTER` |

## Movement

All reproduced at `b26aba0` by `tests/test_movement.gd` before the fix (11 checks failing); all pass after.

| ID | Sev | Issue | Evidence | Status |
|---|---|---|---|---|
| MV-1 | S2 | A festival tap 4.5 px away oscillated 209 → 200 → 209 and never settled: each step was a full 9 px, with a 3 px arrival radius. | `test_a_pointer_target_is_reached_and_held` | fixed (verified): step bounded by the remaining distance |
| MV-2 | S2 | A tap on the far side of the fence walked into it forever. | `test_an_unreachable_target_stops_and_says_so` | fixed (verified): stops after 0.35 s and shows "?" |
| MV-3 | S2 | The closed gate (4 px) was crossed on a 0.12 s frame: the collision test only checked the destination. | `test_the_closed_gate_holds_on_a_long_frame` | fixed (verified): swept 2 px sub-steps |
| MV-4 | S3 | Pushing into a wall showed walking, in the festival (90 px/s reported) and in the game. | `test_pushing_into_a_wall_is_not_walking`, `test_the_game_too_animates_actual_motion` | fixed (verified): resolved motion drives the gait; intent drives facing |
| MV-5 | S3 | Near-45° input flipped facing 39 times in 40 frames. | `test_near_diagonal_input_doesnt_flicker_facing` | fixed (verified): axis hysteresis 1.3× |
| MV-6 | S3 | The gait had a minimum cadence: slow movement shuffled (3 strides/s at 18 px/s). | `test_the_stride_follows_distance` | fixed (verified): one stride per 10 px |

## Story consistency

| ID | Sev | Issue | Evidence | Status |
|---|---|---|---|---|
| ST-1 | S2 | Wren's arc stated as fact that the well can't keep her ("It can't: nobody ever played her"), but the well keeps what's said near it, including Rue's answer. | `relationships.gd` at `b26aba0` vs `well_sequence.gd` | fixed (verified): now her fear ("I've never heard mine"); the journal records her question, not a law. `test_her_fear_is_hers_not_the_wells_rule` |
| ST-2 | S2 | The two chalk marks didn't agree. Writing her name never required Wren's drawing, but the journal, her line and the epilogue always described both. | `b26aba0` | fixed (verified): every text follows what is on the rim, in either order, across a save/load. `test_name_first_then_her_drawing`, `test_drawing_first_then_her_name` |
| ST-3 | S2 | A resumed position was checked only against the map's bounds and floor: she could resume inside a rebuilt crate or a closed door. | `b26aba0` `_resume_at` | fixed (verified): her whole body is checked against the rebuilt physics world, moving her to the nearest clear spot or an entry. `test_never_resumes_inside_something` |
| ST-4 | S3 | The Save and exit note promised "she'll be right here", but props and people rebuild. | pause menu | fixed: "you'll pick up here, though people and things may have moved on" |
| ST-5 | S2 | Save and exit was refused during escorts, so a player had to finish or abandon an escort to stop. | `suspend_blocker` | fixed (verified): the escort goes home and asks again; nothing is lost. `test_save_and_exit_during_an_escort` |

## Saves and persistence

| ID | Sev | Issue | Evidence | Status |
|---|---|---|---|---|
| SV-1 | S2 | Ordinary stopping cost purge. | `record_quit` | fixed (verified): Save and exit (option b). Since 2026-10-28, at the author's request, closing the window, closing the tab, quitting from the menu or a crash **at a calm moment** resumes free; in danger it counts as before. `test_suspend.gd`, `test_menus.gd`, `web_check.cjs` |
| SV-3 | **S1** | Save and exit reported success when nothing was written. With an unwritable save location, `record_suspend` returned true and closed the session. `write_atomic` also deleted the old backup before a backup rename that could fail, and could leave no file in place if the final move failed. | Reproduced at `b26aba0` by the first version of `tests/test_save_failure.gd` | fixed (verified). It is now one transaction: the run closes only if the file is on disk; otherwise everything rolls back. The pause menu shows NOT SAVED with Retry / Return to game, and no path appears in the message (paths go to `SafeFile.support_log` and the engine log). Every write step is failure-injected; crash states on disk are tested. Web: "saved" means written and `OS.is_userfs_persistent()`; IndexedDB sync completion isn't observable from the game (see `owner_memory.gd` `storage_persistent`) |
| SV-2 | S3 | Mobile Safari may not show the leave prompt, so a tab close counts silently. | `RELEASE_READINESS.md`, known defects | open; blocked on a device |

## Platform, performance and builds

| ID | Sev | Issue | Evidence | Status |
|---|---|---|---|---|
| PL-1 | **S1** | The Windows build has never been executed on Windows hardware. | `IMPLEMENTATION_OCT26.md`; `WINDOWS_PLAYTEST.txt` is instructions only | blocked (needs a person) |
| PL-2 | **S1** | No physical controller and no hardware GPU profile. All frame timings are llvmpipe under xvfb. | `RELEASE_READINESS.md` platform table | blocked |
| PL-3 | S3 | `ObjectDB instances leaked at exit` is printed at shutdown. | `suite_m0.log` tail, `6fb8e23` | **characterised, still open (2026-10-29):** a verbose full suite (799/799, `7734ab1`) leaves 25 `SceneTreeTimer`s, 23 `Tween`s and 14 suspended coroutines at exit: tests free scenes while effects and awaited delays are pending. The one traced in detail (Tobben's report, a coroutine holding a timer on a freed area) now runs from `area_process`. A frame-based replacement for awaited timers was tried and reverted: it left more suspended callers. **The exported game exits without the warning** (Linux smoke, 240 frames). Still printed by the suite, not suppressed |
| PL-4 | S3 | The purge-3 escape bot route was purged in about one run in three. | Reproduced 2026-10-28 on `1d4627f`+: 2 of 6. The failing runs share one sequence. A first death to the static at the Edge, then in each later session: a reload while crossing the square, Rue dragged back to its east end (x 877), Arin restored to the west and walking his round along the road. The bot walked west along the same road and was caught head-on. The trace: 672 px apart, then seen at 58 px, caught at 4 px 0.5 s later. Arin is on screen the whole time, walking a fixed round at 40 px/s; a catch is body contact (8 px). With the Arin fix, a second pattern showed: static deaths in the square at purge 4–5, after the owner unleashes the eraser there (cells flicker 0.8 s before they're lethal) | fixed (bot): **bot steering defects, not threat defects.** The bot reacted to Arin only inside 44 px (≈0.3 s head-on) and had no avoidance of the square's static. Now it steps off Arin's line within 130 px when he's ahead, and steps round static cells, as a player would. **The game is unchanged.** After: **8 of 8** pass, two of them recovering from an Edge death in the next session. **Human check still needed:** whether players read Arin's approach and the square's static in time (`PLAYTEST_PLAN.md` session E) |
| PL-4b | S3 | **Re-run 2026-10-29 at `40ba023`:** the purge-3 escape bot failed 1 of 6 (passed 5). The failing run: two static deaths at the Edge, then two in the square after reloads at purge 4–5; the save was lost at purge 6. | `bots_1.log` (this session). The game on that route is unchanged since PL-4's 8/8 (no threat, collision or speed change; the bot never triggers Tobben's new walk). **Investigated:** the square seeds its static where Rue died there before (`Area.start_erasure`, death spots shown as ghosts; the Edge deliberately doesn't). Probe `test_probe_purge_5_scarred_square` (opt-in, `-- --probe-scarred`) starts at purge 5 with two deaths on the square's road west: **2 of 3 reach the escape ending with no death**; the third died once in the square, and at purge 5 one death loses the save (by design) | **changed (2026-10-29):** the death-seeded static stays (the owner remembers), but each death spot now **glows red for 3 s before its static starts** (`Area.DEATH_SEED_WARNING`, `GhostMarker.warn`), so it can be read and gone round. `tests/test_death_seeds.gd`. **Human check still needed** |
| PL-4c | S3 | **2026-10-30, `7734ab1`:** the purge-5 escape bot failed 1 of 2: two deaths to the Edge's finale static, each 6–10 s after an owner reload, and the save was lost. | `botsE_1.log` (this session). The reload already lands on the oldest safe moment (never the void) with grace (`OwnerMoves`). The Edge's static is unchanged by this branch at Normal pace (no death seeds there, every pace multiplier 1.0). All other bots passed both runs; the purge-5 run passed in run 2 | **not a regression; intended finale difficulty plus bot steering.** The bot doesn't wait out the static or retreat after a reload. A player who finds this unfair now has **Owner pace: Gentle**. **Human check needed** (`playtest/RUN_A_ROUND.md`, session 5) |
| PL-5 | S3 | The benchmark scenario "square, hunted" was judged not to measure what it names in this session's run. | `tests/tour_benchmark.gd` run, this session | **fixed (2026-10-29):** reproduced: the scenario went invalid at 8.1 s every run because the owner deleted the escort. `bench_immune` now also holds that move. Re-run under xvfb: valid 3/3 (software renderer, so frame times say nothing about GPUs) |
| PL-8 | S3 | `test_cursor_drags_the_crates_across_the_road` failed once in four full-suite runs. | Its loop already handled the session being freed, which happens when Rue dies and the run restarts: she stood in the open through a HUNT for up to 40 s | fixed: the test isolates the drag (`bench_immune`, as the benchmark does) and fails loudly if the session ends under it. 3/3 passes in isolation, plus the full suite |
| PL-6 | S4 | The strict suite takes ~25 min of wall clock (1527 s), which slows every verification cycle. | `suite_m0.log` | open |
| PL-7 | S4 | `docs/` holds 55 MB, including 185 images and videos, in the repository. | `du -sh docs` | open |

## Characters, UI and accessibility

| ID | Sev | Issue | Evidence | Status |
|---|---|---|---|---|
| UI-1 | S3 | The console truncates long lines and has no backlog. | UX C5 | already fixed (stale entry): console lines wrap (`hud.gd`, "nothing is cut off"), and the pause menu's History page keeps the run's lines with replay |
| UI-8 | S4 | Rue's thoughts written with their own parentheses showed doubled: "((still up. i'll tell her.))". | `hud.gd` wrapped every "self" line | fixed (verified): a thought already in parentheses gets no second pair. `test_thoughts_have_one_pair_of_parentheses` |
| UI-2 | S3 | Portrait orientation doesn't pause on phones. Touch controls overlap. | UX C9, C11, C12 | **fixed for portrait and overlaps (2026-10-29):** portrait pauses play; a key or pad press hides the touch controls; on touch, dialogue text ends left of the E button. `tests/test_touch_fixes.gd`. **Not tested on a phone**; mobile is still not a launch target |
| UI-3 | S2 | No control remapping. | No `InputMap` editing in `scripts/` | fixed (verified) for the keyboard: Settings → CONTROLS rebinds move up/down/left/right, interact and pause. Bindings persist, a key already in use is refused with a reason, the prompts follow, and there is a reset. The arrow keys, Space and Esc stay as fallbacks. `tests/test_remapping.gd` 6/6. **Gamepad remapping built (2026-10-29):** Interact and Pause can move to another pad button; B, the d-pad and Home are refused; Start always pauses; prompts follow; kept and reset. `tests/test_pad_remapping.gd` 4/4. **Not tested on a physical controller** |
| UI-4 | S3 | No formal flash-threshold measurement (WCAG 2.3.1). | `RELEASE_READINESS.md` accessibility | **measured (2026-10-29):** `tests/tour_flash.gd` (xvfb) samples every frame at a quarter speed. Transition: ≥25% of the screen changing relative luminance by ≥0.1. Worst second: effects burst 0; deaths 0–1; a real death with its card **2** (was 3 before removing the cursor death's second invert); reduced flashing 0 everywhere. An engineering check, **not a certified PSE test** |
| UI-5 | S4 | CharacterSheet's "solid" option tints the figure rather than drawing a silhouette. | `scripts/world/character_sheet.gd:161` | **fixed (2026-10-29):** `solid` draws a white silhouette of the sheet (built once) modulated by the colour, as every caller intends. `test_character_pipeline.test_solid_is_a_silhouette` |
| UI-7 | S3 | At the well, two interaction prompts overlap: "[E] climb" over "into the well". | Capture at `6fb8e23` and on this branch | fixed (verified): the cause was the WELL wayfinding sign drawn under the prompt. Signs now fade within the prompt's range. `test_a_sign_fades_when_the_prompt_takes_over` |
| UI-9 | S2 | Objects were hard to identify before touching them. The save crystal and a memory were both spinning diamonds; the note was a yellow rectangle; the well was a box; prompts said only the verb ("[E] save"). | Captures at `6e67d0a` (the author's report) | fixed (verified in tests and captures): a name line over every prompt (`test_readability`); the well, crystal, note and memory redrawn (`tour_readability`). **Human check:** session 1, "anything you touched without knowing what it was?" |
| UI-10 | S4 | A player who skips the festival with a held Esc and presses Esc again as the room appears lands in the pause menu. That is correct (Esc pauses), but a browser check misread the paused, silent room as broken audio. | 2026-10-28 web probe; same on `6e67d0a` | accepted (correct behaviour). The audio check now skips once and reads on with E, and measures the room itself (−29.9 dBFS this branch, −29.8 `main`) |
| UI-6 | S3 | Act numbering doesn't match the guided route (the Archive is ACT IV, Out of Bounds ACT III). | `RELEASE_READINESS.md` | **fixed (2026-10-29, delegated):** act cards count up in the order this player reaches the places (`Story.act_label`). `tests/test_act_order.gd` |

## Evidence the release needs (not defects; nobody may fabricate it)

| ID | Missing | Status |
|---|---|---|
| EV-1 | Unfamiliar-player sessions per [`PLAYTEST_PLAN.md`](../PLAYTEST_PLAN.md) | blocked (needs people) |
| EV-2 | Human listening for the mix and the voices | blocked |
| EV-3 | Rights for any recorded or commissioned voice/art (none commissioned yet) | blocked on spending authorisation |
| EV-4 | Author approval | pending |

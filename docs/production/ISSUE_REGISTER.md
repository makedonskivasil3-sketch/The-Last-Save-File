# Issue register

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
| PL-3 | S3 | `ObjectDB instances leaked at exit` is printed at shutdown. | `suite_m0.log` tail, `6fb8e23` | open (not suppressed) |
| PL-4 | S3 | The purge-3 escape bot route is purged in about one run in three. | 2026-10-28: always after a first death at the Edge; on the next session's walk north the Owner reloads, and Arin catches the bot about 6 s later (the same at `b26aba0`) | open. Lead: the bot doesn't hide after "the owner reloaded". **Human check needed:** does a player get a fair warning there? Not a regression |
| PL-5 | S3 | The benchmark scenario "square, hunted" was judged not to measure what it names in this session's run. | `tests/tour_benchmark.gd` run, this session | open; re-establish before relying on it |
| PL-8 | S3 | `test_cursor_drags_the_crates_across_the_road` failed once in four full-suite runs. | Its loop already handled the session being freed, which happens when Rue dies and the run restarts: she stood in the open through a HUNT for up to 40 s | fixed: the test isolates the drag (`bench_immune`, as the benchmark does) and fails loudly if the session ends under it. 3/3 passes in isolation, plus the full suite |
| PL-6 | S4 | The strict suite takes ~25 min of wall clock (1527 s), which slows every verification cycle. | `suite_m0.log` | open |
| PL-7 | S4 | `docs/` holds 55 MB, including 185 images and videos, in the repository. | `du -sh docs` | open |

## Characters, UI and accessibility

| ID | Sev | Issue | Evidence | Status |
|---|---|---|---|---|
| UI-1 | S3 | The console truncates long lines and has no backlog. | UX C5 | already fixed (stale entry): console lines wrap (`hud.gd`, "nothing is cut off"), and the pause menu's History page keeps the run's lines with replay |
| UI-8 | S4 | Rue's thoughts written with their own parentheses showed doubled: "((still up. i'll tell her.))". | `hud.gd` wrapped every "self" line | fixed (verified): a thought already in parentheses gets no second pair. `test_thoughts_have_one_pair_of_parentheses` |
| UI-2 | S3 | Portrait orientation doesn't pause on phones. Touch controls overlap. | UX C9, C11, C12 | open (mobile not a launch target) |
| UI-3 | S2 | No control remapping. | No `InputMap` editing in `scripts/` | fixed (verified) for the keyboard: Settings → CONTROLS rebinds move up/down/left/right, interact and pause. Bindings persist, a key already in use is refused with a reason, the prompts follow, and there is a reset. The arrow keys, Space and Esc stay as fallbacks. `tests/test_remapping.gd` 6/6. **Gamepad remapping not built** |
| UI-4 | S3 | No formal flash-threshold measurement (WCAG 2.3.1). | `RELEASE_READINESS.md` accessibility | open |
| UI-5 | S4 | CharacterSheet's "solid" option tints the figure rather than drawing a silhouette. | `scripts/world/character_sheet.gd:161` | open; check every caller's intent |
| UI-7 | S3 | At the well, two interaction prompts overlap: "[E] climb" over "into the well". | Capture at `6fb8e23` and on this branch | fixed (verified): the cause was the WELL wayfinding sign drawn under the prompt. Signs now fade within the prompt's range. `test_a_sign_fades_when_the_prompt_takes_over` |
| UI-6 | S3 | Act numbering doesn't match the guided route (the Archive is ACT IV, Out of Bounds ACT III). | `RELEASE_READINESS.md` | **author decision** |

## Evidence the release needs (not defects; nobody may fabricate it)

| ID | Missing | Status |
|---|---|---|
| EV-1 | Unfamiliar-player sessions per [`PLAYTEST_PLAN.md`](../PLAYTEST_PLAN.md) | blocked (needs people) |
| EV-2 | Human listening for the mix and the voices | blocked |
| EV-3 | Rights for any recorded or commissioned voice/art (none commissioned yet) | blocked on spending authorisation |
| EV-4 | Author approval | pending |

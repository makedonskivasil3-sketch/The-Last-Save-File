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
| OP-6 | S4 | The fifth lantern's hold arc passes behind Rue's nameplate at the well. | Frame `after_d_p1_left` | open | — |
| OP-7 | S3 | The rendered timing tour's "no input" path couldn't finish: since `9f1c191` story pages wait for the reader. The tour then read `_awake` on the Prologue, producing script errors in tour output (tours are not in the suite). | `tour_timing_intro`, this session | fixed (verified) | Path renamed "reads only": it acknowledges pages and presses nothing else. Reaches the room at 225.7 s wall |
| OP-8 | S3 | A fully idle player waits ~24 s per step: Player 1 stops at 136 s on the reads-only path. That is long, but it is the documented assistance rule. | `timing_m2` | open (design) | Needs playtest evidence before changing `AUTO_AFTER` |

## Saves and persistence

| ID | Sev | Issue | Evidence | Status |
|---|---|---|---|---|
| SV-1 | S2 | Quitting during a run raised purge, with no way to stop at a safe moment for free. | `owner_memory.gd` `record_quit`; [`SAVE_AND_EXIT_PROPOSAL.md`](../SAVE_AND_EXIT_PROPOSAL.md) | fixed (verified): option (b), Save and exit at a safe moment, one resume, no cost. `tests/test_suspend.gd` 6/6; related suites pass. Not yet played by a person |
| SV-2 | S3 | Mobile Safari may not show the leave prompt, so a tab close counts silently. | `RELEASE_READINESS.md`, known defects | open; blocked on a device |

## Platform, performance and builds

| ID | Sev | Issue | Evidence | Status |
|---|---|---|---|---|
| PL-1 | **S1** | The Windows build has never been executed on Windows hardware. | `IMPLEMENTATION_OCT26.md`; `WINDOWS_PLAYTEST.txt` is instructions only | blocked (needs a person) |
| PL-2 | **S1** | No physical controller and no hardware GPU profile. All frame timings are llvmpipe under xvfb. | `RELEASE_READINESS.md` platform table | blocked |
| PL-3 | S3 | `ObjectDB instances leaked at exit` is printed at shutdown. | `suite_m0.log` tail, `6fb8e23` | open (not suppressed) |
| PL-4 | S3 | Bot ending routes vary between runs: steering stalls on the purge-3 escape, seen on both baseline and branch. | Earlier bot A/B this session; `RELEASE_READINESS` "three recovered steering stalls" | open |
| PL-5 | S3 | The benchmark scenario "square, hunted" was judged not to measure what it names in this session's run. | `tests/tour_benchmark.gd` run, this session | open; re-establish before relying on it |
| PL-8 | S3 | `test_owner_moves.test_cursor_drags_the_crates_across_the_road` failed once in four runs (the full suite on the `08ab155` tree). It passed 3/3 on its own and in a full re-run (693/693). The test waits up to 40 s of real time while Rue stands in the open during HUNT. Likely cause, not yet confirmed: she is caught before the drag lands. | `suite_m2.log` vs `suite_m2r.log`, this session | open (not hidden; root cause to establish) |
| PL-6 | S4 | The strict suite takes ~25 min of wall clock (1527 s), which slows every verification cycle. | `suite_m0.log` | open |
| PL-7 | S4 | `docs/` holds 55 MB, including 185 images and videos, in the repository. | `du -sh docs` | open |

## Characters, UI and accessibility

| ID | Sev | Issue | Evidence | Status |
|---|---|---|---|---|
| UI-1 | S3 | The console truncates long lines and has no backlog. | UX C5 | open |
| UI-2 | S3 | Portrait orientation doesn't pause on phones. Touch controls overlap. | UX C9, C11, C12 | open (mobile not a launch target) |
| UI-3 | S2 | No control remapping. | No `InputMap` editing in `scripts/` | open |
| UI-4 | S3 | No formal flash-threshold measurement (WCAG 2.3.1). | `RELEASE_READINESS.md` accessibility | open |
| UI-5 | S4 | CharacterSheet's "solid" option tints the figure rather than drawing a silhouette. | `scripts/world/character_sheet.gd:161` | open; check every caller's intent |
| UI-6 | S3 | Act numbering doesn't match the guided route (the Archive is ACT IV, Out of Bounds ACT III). | `RELEASE_READINESS.md` | **author decision** |

## Evidence the release needs (not defects; nobody may fabricate it)

| ID | Missing | Status |
|---|---|---|
| EV-1 | Unfamiliar-player sessions per [`PLAYTEST_PLAN.md`](../PLAYTEST_PLAN.md) | blocked (needs people) |
| EV-2 | Human listening for the mix and the voices | blocked |
| EV-3 | Rights for any recorded or commissioned voice/art (none commissioned yet) | blocked on spending authorisation |
| EV-4 | Author approval | pending |

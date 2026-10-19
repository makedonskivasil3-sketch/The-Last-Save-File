# Optimisation pass: baseline and issue ledger

- **Branch:** `claude/review-fixes`
- **PR:** [#6](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/pull/6) (not merged)
- **Baseline:** `main` at `3f471e6` (after PRs #3, #4 and #5)
- **Engine:** Godot 4.3-stable, GL Compatibility, threadless web export
- **Machine for every measurement:** Intel Xeon @ 2.10 GHz (cloud container), headless Godot with the dummy audio driver; headless Chromium (Playwright 1.56.1) for the web build. **No GPU, no physical audio device, no listener.**

**Labels:**
- **R** = reproduced runtime defect
- **S** = confirmed in source
- **M** = measured (on the machine above)
- **C** = creative recommendation
- **H** = playtest hypothesis
- **U** = unverified platform behaviour

**Verification:** pass / fail / blocked / not run.

## Baseline facts checked against the latest source

| Historical lead | Now |
|---|---|
| Seven areas | Yes: room, house, square, archive, bin, oob, edge |
| Nine glitches | Yes: `Glitch.DEFS`. Leaving a body is not a glitch |
| Six ending variants | Yes, six (escape, rue, wren, message, unseen, overwrite). A seventh, "out", is designed but **not built** |
| 197 unrecorded voice entries | Now **216** lines, 2,479 words; **no** `.ogg`/`.wav`/`.mp3` performances |
| Narration off by default | Yes (`Settings.narration = false`) |
| CI passing 327 tests with a misleading Wren result | Was so. The suite is now 357+, and the Wren bot asserts the exact ending (below) |

## Ledger

| # | Finding | Label | Fix | Verification |
|---|---|---|---|---|
| 1 | **Web build completely silent**: `AudioServer.add_bus()` one at a time scrambles the browser's copy of the buses (Sample playback), so nothing reaches the speakers | R, S | Buses created in one step (`bus_count`) | **pass**: browser post-mix -inf → -29 dBFS, theme pitches present (`AUDIO_DIAGNOSIS.md`) |
| 2 | Desktop music buried: 95% of the opening's energy at 55 Hz, title theme under the drone, no music in Arin's room | M | Hum harmonics; hum -18 dB; title theme -13 dB; room theme; square and archive themes up 9 dB | **pass** (measured). Listening **blocked** |
| 3 | On the web, bus effects (low-pass muffle, reverb, speech duck) don't run in Sample playback | S, U | Recorded (engine limitation). Duck by bus volume before shipping recorded speech to the web | not run |
| 4 | The old browser check accepted `AudioContext = running` as audio working | S | `tests/web/audio_output_check.cjs` measures post-mix output and theme pitches; added to CI | pass locally; CI not run yet |
| 5 | Wren bot passed on the wrong ending: any ending accepted, option index 0 when "Wren" was missing | S, R | Exact-ending assertion; a missing option is a result of its own (options, escort and Wren state logged) | **pass**: 4/4 bots exact. Wren reached in 3/3 local runs plus the full run |
| 6 | With exact assertions, the Wren bot failed when Wren had been deleted for helping (no Wren at Slot 2) | R | The bot restores Wren from the Recycle Bin, as a player can | pass |
| 7 | Archive bot stall at (518,173) → (525,170): the bot's doorway avoidance looked 30 px ahead, past a waypoint 19 px from the bin door | R | Look-ahead capped at the goal distance (bot only; no gameplay change) | pass (already in `main`) |
| 8 | Drone hum and dread synthesised on one frame each: about 80–120 ms and about 65 ms at the title and the start of a run (several times that on the web) | M | Baked to `audio/baked/*.res`, loaded in 0.3 ms; `test_baked_audio` guards drift | pass |
| 8b | Music-box themes rendered in the background (20–55 ms each here). On CI's software-rendered browser the title theme wasn't ready within the first listen (the CI check failed: no theme pitches) | R, M | All 18 themes baked (`audio/baked/theme_*.res`, about 107 KB each), loaded in under 1 ms; drift test | pass locally (theme pitches present before and after the first click). Web package 0.6 → 2.8 MB |
| 9 | Other single sounds take 30–50 ms each to build (win, memory_loop, fragment, death_*, cursor_arrive) | M | Not changed: built during the title's prewarm and held back while tense. Each still costs one long frame on the title | not run on the web; candidate for baking if a web profile shows title stalls |
| 10 | Narration cached an empty voice list for the whole session (browsers report voices late) | S | Asks again until a voice appears | pass (source test); TTS output **blocked** (no device) |
| 11 | No way for a player to check sound without starting a run | S | Settings > Sound check: effect, music box, voice (honestly labelled procedural), names a volume at 0, Master meter on desktop, restore sound defaults (sound only) | pass (`test_sound_check`, screenshot) |
| 12 | 13 AudioStreamWAV and 16 playbacks reported leaked at exit | R | Every quit path stops all sound and drops generated streams first | pass (`--verbose`: 0 audio leaks) |
| 13 | A question didn't hold the owner if it started during PAUSE | S, R | Always held | pass (`test_review_fixes`) |
| 14 | A question open at death could be answered by the retry press (and take a piece) | S, R | Cancelled with the run; returns -1 | pass |
| 15 | LEAVE THIS BODY could replace FREEZE on Arin | S, R | Not offered with Arin in reach; refuse focused first | pass |
| 16 | Every escort death seen in the bot runs is in the square while escorting Wren (cursor or Arin, about 80 s in) | M, H | Not changed. Playtest: is the escort too punishing, or is the danger unclear? | not run (human) |
| 17 | The planted memory, the early name reveal, owner notes 6–8 being hard to reach | C | Author decisions; not changed | — |

## Endings coverage

| Ending | Check |
|---|---|
| escape | bot (exact), `test_endings.test_escape_ending` |
| message | bot (exact), `test_endings.test_message_ending_reconciles` |
| wren | bot (exact), `test_endings.test_wren_ending` |
| rue | `test_dark_truth.test_rue_with_the_truth` / `test_rue_needs_the_truth` |
| unseen | `test_endings.test_the_careful_find_a_hidden_way_out` |
| overwrite | `test_endings.test_the_reckless_take_everything` |

## Not verified (this pass)

| Item | Status |
|---|---|
| Listening on headphones and laptop or phone speakers | blocked (no device) |
| Windows build launched on Windows | not run |
| Physical controller, touch, phones | not run |
| Real-GPU frame times | not run (software renderer only) |
| Any human play | not run |

## Frame-time measurements (same machine, software renderer)

Machine: Xeon 2.1 GHz, Xvfb with Mesa llvmpipe (no GPU), 1280×720, effects Full unless noted. Tour: `tests/tour_profile.gd`.

| Scene | `main` 3f471e6: p50 / p95 / max (ms) | This branch 1e6e0a6: p50 / p95 / max (ms) |
|---|---|---|
| Room, session start | 54.7 / 83.4 / 107.4 | 49.8 / 100.1 / 132.1 |
| Square, calm, effects Full | 52.1 / 60.0 / 63.4 | 49.5 / 65.5 / 69.1 |
| Square, calm, effects Off | 31.6 / 38.4 / 45.4 | 31.9 / 36.1 / 40.0 |
| Square, HUNT + Wren escort | 52.6 / 64.8 / 73.7 | 53.1 / 60.7 / 61.4 |
| Edge, static spreading | 39.2 / 45.9 / 52.4 | 41.7 / 53.6 / 77.2 |
| Out of bounds | 39.7 / 46.2 / 52.8 | 40.5 / 46.7 / 50.4 |
| Archive after 8 area changes | 42.5 / 45.9 / 48.4 | 44.2 / 50.8 / 54.2 |

**Title, first 3 s** (`tools/title_startup.gd`, two runs each), worst frames in ms:
- `main`: 89–135 and 86–111
- this branch: 95–148 and 80–98

**What this shows, honestly:**

1. **No measurable frame-time change between `main` and this branch.** Both columns and both title runs fall within run-to-run noise on this machine.
2. **The screen-effects shader dominates on a software renderer.** Effects Off cuts the square's p50 from about 50 ms to about 32 ms. A real GPU needs its own measurement (not run). Nothing was removed, because the brief rules out cutting atmosphere without evidence from target hardware.
3. **Removing synthesis spikes didn't show up in frame times here.** Baking the drone and the themes removes synthesis spikes measured in isolation: the hum went from about 95–120 ms to 0.3 ms, and a theme is now under 1 ms where rendering one took 20–55 ms. But the title still builds about 60 sound effects at roughly 30–50 ms each, one per frame (`tools/synth_timing.gd`). Those dominate its first seconds in both versions.
4. **The next step if a real device shows title stalls:** bake the deterministic sound effects the same way. Effects that use noise need a fixed seed first.
5. **Memory and objects stay flat** across 8 area changes in both versions: about 2,250 objects, about 65 MB.

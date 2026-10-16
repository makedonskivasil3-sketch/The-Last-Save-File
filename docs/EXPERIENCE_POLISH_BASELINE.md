# Experience polish: baseline and prioritized issues

The baseline was taken on 2026-10-16 at commit `fb1ffc9` (what's on `main` and the live web build), before any change in this milestone.

The audits behind it are:
- `MAP_DESIGN.md`
- `GAMEPLAY_BALANCE.md`
- `UX_AUDIT.md`
- `AUDIO_DIRECTION.md`
- `CHARACTER_DIRECTION.md`
- `NARRATIVE_DECISIONS.md`

They were written from the code and cite `file:line`. Every severity is a judgement. **No human playtest has taken place.**

## 1. Baseline (measured, not assumed)

| Check | Result | How |
|---|---|---|
| Automated tests | **209 discovered, 209 passed, 0 failed, 0 skipped** (726.9 s) | `tests/run.sh` (Godot 4.3, headless, Linux container) |
| Endings (bots) | **4 of 4 reached:** escape (purge 0), message, escape (purge 3), wren | `tests/run.sh --bots --speed=2` (594.7 s) |
| Warnings in the test log | Only expected ones: the save-safety tests feed in broken JSON on purpose (`Parse JSON failed`, `SafeFile … recovered`), plus Godot's "ObjectDB instances leaked at exit" once at shutdown | grepped `^WARNING\|^ERROR` |
| Web, Windows and Linux export | **The last CI build passed** (run #30, `fb1ffc9`, 13 min). Export templates 4.3 exist locally; local export results are in `RELEASE_READINESS.md` | GitHub Actions `Build game` |
| Performance | Only relative timings exist: the visual tour under xvfb with software GL measured about 30–45 ms per frame. **Not representative of real hardware.** No device measurements | `tests/tour_visual.gd` → `frame_times.txt` |
| Mobile, controller, browser audio | **Not verified on real hardware.** Only simulated input events have been tested | — |

## 2. Who owns critical state

```
OwnerMemory (autoload, persists to user://owner_memory.json via SafeFile)
  ├── purge / deaths / quits / last_exit ──> World._begin_session, OwnerDirector.start (start awareness)
  ├── fragments ──> Glitch unlocks (GlitchController), MusicBox level, Ambience, Rue's voice motif
  ├── npc_fates / restored / session_helpers ──> areas' NPC spawning, RecycleBin files
  ├── patched_seams / route_memory / deaths_log ──> ArinsRoom seams, OwnerAvatar routes, ghost markers
  └── side stories (mira_quest, wren_saved, guestbook…) ──> areas, Story recaps, endings
Settings (autoload, ConfigFile) ──> audio buses, ScreenFx scaling, text speed, tips, input glyphs
Sfx (autoload) ──> all sound; owner_strain (set by OwnerDirector) shapes the voices
World (per session)
  ├── area (one Area at a time) ── its threats: OwnerAvatar, OwnerCursor, Erasure
  ├── OwnerDirector: awareness, thresholds (one-shot per session), owner_paused
  ├── OwnerMoves: reload, save-over, drag, escort deletion, route notes
  ├── escort, flags (session-only), _visited, ending
  └── Hud: dialogue, choices, console, meter, overlays
```

**Rules that matter for this milestone:**
- Awareness only changes through `OwnerDirector.add_awareness`, or `notice()` for the one-off jumps a player should be able to explain.
- PAUSE and question holds go through `World.is_owner_paused()`.
- Everything persistent lives in `OwnerMemory`.

## 3. Prioritized issues

Each row gives the reproduction, expected and actual behaviour, the fix and its test. The full write-ups are in the docs named in the source column. The **Canon/Save/End** column says whether the fix touches narrative canon, save compatibility or ending conditions. "No" means none of the three.

| # | Sev | System, file | Repro → actual | Expected | Fix | Test | Canon/Save/End | Status |
|---|---|---|---|---|---|---|---|---|
| 1 | S1 | Seams, `arins_room.gd:207`, `seam.gd:38` (MAP) | Escort Mira, step into the open seam while she's more than 70 px behind → transition refused, but the seam is marked used. From session 2 the door is deleted, so the room becomes a **soft-lock** | The seam stays usable | Reset `_used` when `change_area` refuses | `test_experience_fixes.test_a_refused_seam_stays_open` | No | **Fixed** |
| 2 | S1 | Dialogue vs threats, `player.gd:138`, `owner_moves.gd:313` (UX C1, BAL 2) | Talk to someone with awareness at SUSPECT or above and read for 8 s → the save-over starts and kills you 4 s later, while its warning is hidden behind the dialogue | Reading isn't standing still | `player.reading` holds `idle_time` while dialogue or a choice is open | `test_reading_is_not_standing_still` | No | **Fixed** |
| 3 | S1 | Modal questions, `village_square.gd:255,390`, `arins_room.gd:237` (BAL 2) | Wren, Mira and Tobben's questions freeze Rue while the cursor, eraser and save ring keep running | No deaths while answering | `World.choose_safely()` holds the owner (like PAUSE) for the question | `test_a_question_holds_the_owner` | No | **Fixed** |
| 4 | S1 | Choices, `hud.gd:426,439` (UX C2) | Mashing through dialogue picks option 0, **including the Slot 2 ending** | A deliberate press only | 450 ms input grace on every choice (keys and buttons) | `test_mashing_cannot_pick_an_answer` | No | **Fixed** |
| 5 | S2 | First visits, `world.gd:310,349` (MAP T1) | `_load_area` marks the area visited before `first` is computed → every `*_first` line and the owner's arrival beats never play, including the Edge's only hint toward Slot 2 | They play once | Compute `first` before loading | `test_first_visits_are_noticed` | No (restores existing text) | **Fixed** |
| 6 | S2 | PHASE vs crates, `glitch.gd:48`, `glitch_controller.gd:186` (BAL 1) | The owner drags the crates across a road → PHASE reaches 46 px but needs about 52, so the game's promise is false | PHASE gets past the crates | 62 px reach only when the obstacle is the dragged prop. Wall reach is unchanged | `test_phase_gets_through_the_dragged_crates` (failed before the fix) | No | **Fixed** |
| 7 | S2 | Hidden awareness costs (BAL 3) | Talking (+8), the save point (+15), a memory (+6), Tobben's report (+12)… raise the meter with no explanation | Every one-off jump says why | `OwnerDirector.notice(amount, why)` shows "+N · why" | `test_hidden_costs_say_why` | No | **Fixed** |
| 8 | S2 | Reload tell, `owner_moves.gd:145` (BAL 4) | The third glitch since the last load triggers a reload with no warning | The rule is heard before it bites | The owner says "do that again and i'm loading the autosave." after the 2nd | `test_the_owner_warns_before_a_reload` | No (new owner line, no canon) | **Fixed** |
| 9 | S2 | Escorting Mira, `village_square.gd:143` (MAP) | Wren is removed for *any* escort → the square loses its only hiding spot during Mira's walk | Wren is only absent when *she* is walking with you | `escort_id() != "wren"` | `test_wren_stays_in_the_square_while_mira_walks_with_you` | No | **Fixed** |
| 10 | S3 | Pip, `world.gd:729` (MAP) | Pip leads to the owner's **planted** false memory | Pip doesn't trust the lie | Skip `planted` | `test_pip_does_not_lead_to_the_planted_memory` | No | **Fixed** |
| 11 | S2 | Music, `ambience.gd:30,40,43` (AUDIO) | With 5 memories, the house, Out of Bounds and the Edge play the resolved theme reserved for the RUE ending | The whole theme belongs to the ending | Cap in-world levels at `MAX_LEVEL-1` | `test_areas_never_play_the_rue_ending_theme` | No (restores the intended meaning) | **Fixed** |
| 12 | S2 | Sound pool, `sfx.gd:165` (AUDIO) | Typing and voice blips cycle the 14-player SFX pool and cut off stingers and death sounds | Speech never steals threat sounds | New Voice bus with its own pool | `test_voices_play_on_their_own_bus` | No | **Fixed** |
| 13 | S2 | Heartbeat on the Music bus, `drone.gd:39` (AUDIO) | Music volume set to 0 silences the heartbeat that rises with danger | Threat cues survive a music mute | Heartbeat moved to SFX | `test_muting_music_keeps_the_heartbeat` | No | **Fixed** |
| 14 | S3 | Arin's tell, `owner_avatar.gd:131`, `pixel_character.gd:197` (CHAR 1) | Arin's "seen you" pose is an 8 Hz arm wave, which reads as a friendly hello | A still point | `pointing` pose | `test_character_tells` (see below) | No | **Fixed** |
| 15 | S3 | Hostile vs friendly "!", `owner_avatar.gd:139`, `npc.gd:213` (CHAR 3) | Arin's alert is the same white bubble as Mira's and Wren's | Different shape, not just colour | Owner-coloured warning triangle | visual tour | No | **Fixed** |
| 16 | S3 | The real Arin (purge screen), `arins_room.gd:272` (CHAR 2) | Only says "…", but the mouth animates | Silent | `Npc.mute` | `test_character_tells` | No | **Fixed** |
| 17 | S3 | Rue when targeted (CHAR 5) | No reaction while the cursor settles on her or Arin points | Wide eyes while targeted | `player.set_targeted()` | `test_character_tells` | No | **Fixed** |
| 18 | S3 | Text speed (UX) | One fixed speed; no instant option | Slow / Normal / Fast / Instant | `Settings.text_speed`, applied to dialogue and console | `test_text_speed_setting`, `test_new_settings_persist` | No | **Fixed** |
| 19 | S2 | Holding F9, `world.gd:_handle_wipe` (UX C8) | Holding F9 for 1.5 s **during normal play** wipes all progress without confirmation | Only on the purge screen, or in debug | Restrict it | — | Save | **Next** |
| 20 | S2 | Tap vs hold, `glitch_controller.gd:64-79` (UX C3) | A 0.3–0.6 s press near someone neither talks nor glitches | One or the other | Short presses fall back to interacting | — | No | **Next** |
| 21 | S2 | Console, `hud.gd:722,756` (UX C5) | Long lines are cut off with an ellipsis and there's no backlog | Readable | Wrap and keep a short backlog | — | No | **Next** |
| 22 | S3 | Screen shake (UX C10) | No separate toggle; only glitch intensity | A shake toggle | `Settings.screen_shake` | — | No | **Next** |
| 23 | S3 | Choices, `hud.gd` (UX C13) | W/S don't move the choice focus | Movement keys navigate | Map `move_*` to choice focus | — | No | **Next** |
| 24 | S2 | Web tab close (BAL 5) | **Verified in Chromium:** the next launch counts it as a quit (+1 purge) | Author: count it, but warn | `beforeunload` "Leave site?" during a run; How to Play says so | `tests/web/web_check.cjs` (asks first: true) | Rules unchanged | **Fixed** |
| 25 | S3 | Act order (UX C4, MAP) | The archive is ACT IV but usually reached before OOB (ACT III) | Matches the guided order | Renumbering touches presentation | — | Canon? | **Author decision** |
| 26 | — | Three narrative questions | See `NARRATIVE_DECISIONS.md` | Author decided 2026-10-16 | Lines rewritten as decided | `tests/test_canon.gd` | Canon (approved) | **Done** |

The remaining confirmed findings and hypotheses are in each doc's issue list:
- `UX_AUDIT.md`: C6, C7, C9, C11–C16.
- `MAP_DESIGN.md` §8: wayfinding.
- `CHARACTER_DIRECTION.md`: palette contrast.
- `AUDIO_DIRECTION.md`: mix, plus the web audio unlock, which is unverified.

## 4. What was not done, and why

- **No human playtest.** `PLAYTEST_RESULTS.md` holds the plan only.
- **No balance values were changed.** The awareness rates, costs, the purge limit (6) and the ending conditions are untouched. Only explanations, tells and the crate reach (a promise the game already makes) changed.
- **No canon was decided.**

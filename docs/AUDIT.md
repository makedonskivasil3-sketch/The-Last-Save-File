# Technical audit: The Last Save File

The audit was done on 2026-10-16 against branch `claude/last-save-file-prototype-ljwuq4`.

Everything below comes from the files in the repository and from test runs in a headless Linux container. Nothing was play-tested by hand on a real screen, gamepad, or phone.

## 1. Architecture as it is

| Layer | Files | Role |
|---|---|---|
| Engine | `project.godot` | Godot **4.3**, GL Compatibility renderer, and a 640×360 pixel viewport. The game starts in `scenes/title.tscn`. |
| Autoloads | `scripts/autoload/owner_memory.gd`, `settings.gd`, `sfx.gd` | **OwnerMemory** holds everything that persists between runs, plus the input map. **Settings** holds options and tracks the current input device. **Sfx** builds every sound procedurally on a budgeted job queue. |
| Session | `scripts/world/world.gd` (about 1,130 lines) | One run of the game. It owns area loading, interaction, escorts, endings, debug tools, and the pause and death flow. |
| Owner AI | `scripts/owner/owner_director.gd` | Awareness from 0 to 100. Six thresholds (`NOTICE`…`PURGE`) each fire once per session. Hiding cools awareness, but never below the last threshold that fired. |
| | `scripts/owner/owner_moves.gd` | The owner's active moves: reload, save-over, drag, deleting an escort, and route memory. |
| | `owner_avatar.gd`, `owner_cursor.gd`, `erasure.gd` | The threats themselves: Arin, the cursor, and the static. |
| Areas | `scripts/world/areas/*.gd` | Seven areas, each a subclass of `Area` that draws itself procedurally: room, square, archive, recycle bin, out of bounds, the Edge, and Arin's house. |
| Glitches | `scripts/player/glitch.gd`, `glitch_controller.gd` | Nine glitches. The data lives in `Glitch.DEFS`. Each costs awareness, and memories unlock more of them. |
| Story | `scripts/story/story.gd`; `docs/STORY_SCRIPT.md` | All text is kept as data in one file. |
| UI | `scripts/ui/*.gd` | HUD, title, pause, settings, records, map, touch controls, how to play. |
| Tests | `tests/` | About 33 test files: 187 tests, plus 4 bot playthroughs (`tests/run.sh --bots`). |
| Build | `.github/workflows/build.yml`, `export_presets.cfg` | CI exports Windows, Linux and Web builds, and can deploy the web build to Pages. |

The project has no external assets: every graphic and sound is generated in code, so there are no third-party licences to clear. The font is Godot's built-in fallback font.

### The loop as implemented

1. You wake in Arin's room.
2. The owner watches. Awareness rises over time, when Arin sees you, and every time you glitch.
3. You escape through a seam, or by glitching the door with UNLOCK.
4. You explore the square, the Archive, the well and the house.
5. You recover memories, which unlock glitches.
6. You get the pointer and take the north road to the Edge.
7. At the Edge you lure the cursor away and write yourself into Slot 2 (the owner fights you for it).
8. You choose one of six endings.

When you die or quit, `OwnerMemory` records it. Purge rises, the people who helped you are deleted, a seam is patched, and Arin's route detours through the places where you were seen. The next run starts out harder, and the characters and the owner remember what happened.

## 2. What works

These were checked by automated tests, not by playing.

- The full loop from start to every ending, including the 4 bot playthroughs.
- The owner's thresholds and moves.
- All nine glitches and their costs.
- Persistence of deaths, helpers, seams and route memory.
- Records, settings, the pause menu and the map.
- Touch controls.

## 3. Confirmed bugs found by this audit (all fixed in this pass)

| # | Pri | Bug | Evidence | Fix |
|---|---|---|---|---|
| 1 | **P0** | **Progress could be lost.** `save_memory` wrote over the only copy of the save. If the game was killed mid-write, the file was left truncated. The next launch then said "starting fresh", and the next save made the loss permanent. | `owner_memory.gd:326` (old) | New `scripts/autoload/safe_file.gd`. Saves now go to a temp file, which is read back to check it, and the old save is rotated to `.bak`. Loading falls back from the main file to the temp file to the backup. An unreadable file is kept as `.corrupt`. |
| 2 | **P0** | **A wrong-typed value stopped the load half-way.** For example, `bool("true")` or `int([1])` raised a runtime error. Every field after it kept its default, including the crash check. | `owner_memory.gd:341-393` (old) | Typed readers `_int`, `_bool`, `_str`, `_list` and `_strings` fall back to the default value. Purge is clamped, and the death log is capped on load. |
| 3 | P1 | Save data had no version. | – | `SAVE_VERSION = 1` and `_migrate()`. Old unversioned saves still load, including the legacy `death_positions` field. |
| 4 | P1 | **Reload across a doorway could crash.** The 0.9 s rewind tween could carry Rue into an exit. The old area's snapshot was then applied to the new area, and `_history.resize()` padded the list with empty entries that crashed the next reload. | `owner_moves.gd:192-201`, `exit.gd`, `world.gd:284` | `change_area` refuses to run while the rewind is in progress. The rewind also aborts cleanly if the area changed, and the resize is clamped. |
| 5 | P1 | **The idle save-over never fired before HUNT.** `_next_save` starts at `INF`, and `INF - 17.5` is still `INF`. The behaviour described in the header comment and the README was dead code. | `owner_moves.gd:66,99` | Fixed with fairness rules: it waits for the owner's spoken idle warning (`IDLE_SAVE` 8 s > `IDLE_WARN` 6 s), and it never fires while you are hidden. |
| 6 | P1 | **The PAUSE glitch didn't carry through doorways.** In the new area the static ran while the banner still said PAUSED. | `world.gd:_load_area` | The pause state is re-applied after `catch_up()`. Arin's house honours PAUSE as well. |
| 7 | P1 | During the Edge fight, the resume at the end of PAUSE released the cursor while the scripted grab was still holding it. | `the_edge.gd:169`, `area.gd:56` | The fight now holds the cursor every frame, and freezes it during PAUSE. |
| 8 | P2 | Reloads already queued by the SILENCE threshold or by glitches still fired during PAUSE, or after you walked somewhere the owner can't see. | `owner_moves.gd:117,141` | Unless forced, `load_last_save` checks that the owner is watching. |
| 9 | P2 | **Closets in Arin's house were inconsistent.** They hid you from Arin, but there was no HIDDEN status, awareness didn't cool, and the idle warning still fired. | `world.gd:235`, `owner_director.gd:116,124` | A single side-effect-free check, `World.is_hidden_now()`, is now used everywhere. |

## 4. Known issues not fixed yet

- **Web builds may count a tab close as a crash.** `NOTIFICATION_WM_CLOSE_REQUEST` (`owner_memory.gd:110`) is most likely never sent when a browser tab closes. If so, closing the tab mid-run gets the quit penalty next launch. Also, `user://` is written to IndexedDB asynchronously, so a save made just before the tab closes could be lost. This is unverified, because it needs a real browser to test. The likely fix is a `beforeunload` hook through `JavaScriptBridge`.
- **Killing the process costs less than quitting.** The crash path adds to the quit count and to purge, but skips `_learn()`, so helpers aren't deleted and seams aren't patched (`owner_memory.gd`, crash branch). This may or may not be intended. **It's a design decision for you.**
- `mira_quest = "carried"` is never assigned anywhere, so `_lose_carried_note()` never does anything. The old flow where Mira gave you a note was replaced by her escort. The dead branch should be removed or wired back in.
- `settings.gd` uses `bool(cfg.get_value(...))`. This is safe for normal files, but a hand-edited string value would raise an error. Settings are also saved non-atomically. They are low-value data, but the same `SafeFile` approach could apply.
- The owner's tuning numbers are scattered. The thresholds are centralised, but per-event costs aren't, for example +6 for a fragment, +20 for the false memory, and Mira's 2.5/s (`world.gd`). They should move into one balance table.
- There is no debug overlay that explains the owner's decisions. Only the frame-time overlay exists (F3). An "owner brain" overlay would show awareness, rate and its sources, the next save and reload times, and cooldowns.

## 5. Performance risks (by inspection, not profiled)

- `erasure.gd` redraws every frame even when inactive. It also allocates `_young.keys()` every frame and `_frontier.keys()` on every growth step.
- Many nodes call `queue_redraw()` unconditionally every frame: owner moves, the Edge, out of bounds, cursor, avatar, player, NPCs and the glitch controller.
- The HUD and World build formatted strings every frame.

No FPS figures are claimed here. The F3 overlay should be used on target hardware before anything is optimised.

## 6. Technical debt

- `world.gd` is 1,130 lines and mixes the session, areas, escorts, endings, interaction and debug tools. The first candidates to split out are `EscortController` and `DebugTools`.
- `hud.gd` is 849 lines, `story.gd` 773 and `sfx.gd` 747. These are big, but each has a single job.
- The README has `License: TBD` and there is no credits screen. Both are needed before a public demo.

## 7. Top five next improvements

1. **Web exit handling.** A `beforeunload` hook that records the quit and flushes the save.
2. **An "owner brain" debug overlay.** It would make the AI explainable and make tuning measurable.
3. **First-30-minutes pass.** Time a fresh run through room, square, Archive, memory and the Edge. Cut dead time, and confirm the first owner reaction and the first visible consequence of a death land early. This needs human playtests, ideally 5 or more people, with notes on where they stall.
4. **Credits screen, licence, and Steam packaging.** A Windows export with an icon, a `steam_appid` placeholder documented, and no Steamworks SDK until there's an app ID.
5. **Balance table.** Move the owner's per-event costs into one constants file, and add a test that the numbers stay within fair bounds.

## 8. Roadmap

| Milestone | Exit criteria |
|---|---|
| **M1: Stable demo build** | No P0 or P1 bugs open. The full suite and the bots are green. The save survives a kill mid-write (done). Web exit handling is fixed. |
| **M2: Playtest round 1** | 5 to 10 fresh players on PC. Measure: % who escape the room within 5 minutes, % who reach the Edge, median session length, and where they quit. |
| **M3: Demo polish** | Fix the top 5 stall points from M2. Add credits, licence and a store-page capsule. Do a pass on accessibility settings. |
| **M4: Steam demo** | A Steamworks app, a depot build, and a Next Fest-ready build. Measure wishlist conversion from the demo page. |
| **M5: Full release scope** | Decided by the M2 to M4 data, not before. |

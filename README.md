# The Last Save File

> You wake up inside someone else's save file.
> You are not supposed to be here.
> The owner has noticed.

**The Last Save File** is a small, tense, systemic game about being an intruder. You're a stray process
inside another player's save slot: their character's room, their NPCs, their notes to themselves.
The owner is still playing. They see you. And every time you die or quit, they learn something and
rewrite the world to get rid of you.

Built with **Godot 4.3+** and **GDScript**.

---

## The fantasy

- **You are not the protagonist.** The world belongs to someone else. The protagonist is *Arin*,
  the owner's character. NPCs call you by that name until they realize you're wrong.
- **The world is rewritten between sessions.** Doors get deleted. Notes change. NPCs who talked to
  you get removed. Every reload of the save is a slightly more hostile version of the last one.
- **Death and quitting are permanent.** The owner's memory lives *outside* the save slot. You can
  reload the world, but you can't reload the owner. Closing the game counts as a quit, and so does
  killing the process (it's treated as a crash, and the owner goes looking for your traces).
- **Atmosphere over combat.** You can't fight the owner. You can only move, read, talk, and slip
  through gaps they haven't written yet.

## Pillars

1. **Paranoia.** Things change when you aren't looking. The room is always watching.
2. **Systemic reactions.** Everything the owner does comes from a small set of rules driven by what
   they know (awareness, deaths, quits, escapes, where you died).
3. **Permanent consequences.** There is no clean reset for the intruder. Only for the owner.
4. **Readable dread.** Simple shapes, a tight palette, and a typed console voice do the heavy lifting.

---

## The current build

Four areas, five characters, one owner who's getting impatient, and one way out.

**Controls**

| Keyboard | Gamepad | Action |
| --- | --- | --- |
| WASD / Arrows | Left stick / D-pad | Move |
| E / Space | A | Interact: read, talk, advance dialogue |
| Esc | Start | Pause menu (Resume · Settings · Quit). Quitting counts, and the menu warns you first. |
| Hold F9 | | Wipe the owner's memory (debug / "new game") |

Menus work with mouse, keyboard or gamepad. **Settings** (title screen or pause menu) has volume,
fullscreen, **glitch intensity** and **reduce flashing**, plus *Reset owner memory* on the title screen.

**The world**

| Area | What's there |
| --- | --- |
| **Arin's Room** | Where you wake up. The owner watches it closely, so awareness rises fast. The door locks; Mira is deleted for talking to you. A **seam** tears open in the wall once the owner starts rewriting the room: that's your way out. |
| **Ashvale · Village Square** | The owner's hub. **Arin** (the owner's character, driven by the owner) patrols around the well with a view cone: if Arin sees you, awareness climbs fast, and if Arin walks into you, you're overwritten. **Wren**, a child, hides you while you stand next to her. **Tobben** the shopkeeper reports anything you say to him. A notice board, Arin's locked house, and a road north that isn't loaded. |
| **The Archive · Cut Content** | East of the square. Barely watched. **The Archivist** was cut before the game shipped, so the owner can't delete them; they give you a pointer to Slot 2 that opens the north road. The books are live logs of *your* history: every death (where and when), every deleted character, every patched seam. |
| **The Edge · Not Loaded** | North of the square. Missing textures, wireframe, debug labels, an eraser already running, and the owner's **cursor** reaching in. Hold still under it and you get selected and deleted. Somewhere out here is **Slot 2**: the last save file. Reach it to win. |

**The owner's awareness** rises over time (fastest in Arin's room, slowest in the Archive), and with
what you do: being seen by Arin, Tobben's reports, touching the save crystal. At each threshold the
owner acts on whatever area you're in:

| Awareness | The owner... |
| --- | --- |
| 25 | rewrites notes and notices, but only once you've walked away from them |
| 40 | flickers the lights; Arin walks faster |
| 50 | locks the door and tears the wall; Arin looks further |
| 65 | deletes whoever has been talking to you or hiding you |
| 75 | starts the eraser where you died before, and sends in the cursor |
| 100 | "hold still." Everything speeds up. |

**How the owner adapts (persisted across sessions)**

| You... | The owner... |
| --- | --- |
| Die | Remembers where and in which area. Your ghost marker stays, and the eraser starts there. |
| Were hidden by Wren, then died or quit | Deletes Wren for good. The Archive's books record it. |
| Used a seam, then died or quit | Patches that seam. (It never finds the last one.) |
| Quit (from the pause menu, or closing the window) | Notices. *"you closed the game. i didn't."* |
| Kill the process | Treats it as running away and counts it as a quit. **This includes the Stop button in the Godot editor**: quit from the pause menu instead, or hold F9 to reset. |
| Reach Slot 2 | Shows up on the title screen as a second save slot, and the owner opens the next session with *"there's a second slot. you hid in it."* |
| Anything | Starts the next session more aware, with the door gone, Mira restricted or removed, a darker world, and a faster Arin, cursor and eraser. |

Every death or quit adds one to **purge progress**. At **6/6** the owner wins: the save is clean,
the real Arin is back in the room, and you're gone. (Reset from the title screen's Settings, or
hold F9.)

The owner's memory is stored at `user://owner_memory.json`:

- Linux: `~/.local/share/godot/app_userdata/The Last Save File/`
- Windows: `%APPDATA%\Godot\app_userdata\The Last Save File\`
- macOS: `~/Library/Application Support/Godot/app_userdata/The Last Save File/`

---

## Playing it

### Just play (no Godot needed)

Every push to `main` builds the game automatically (see `.github/workflows/build.yml`):

1. Open the repo's **Actions** tab, then the latest green **Build game** run.
2. Under **Artifacts**, download **TheLastSaveFile-windows** (or `-linux` / `-web`).
3. Unzip and run `TheLastSaveFile.exe`. Windows SmartScreen may warn because the game isn't
   signed: click **More info → Run anyway**.

Tagging a version (`git tag v0.2.0 && git push --tags`) also publishes the zips on a **Release** page.

**Optional: play in the browser.** Under *Settings → Pages* set *Source* to **GitHub Actions**, then
under *Settings → Secrets and variables → Actions → Variables* add `ENABLE_PAGES` = `true`. The
next push deploys the web build to `https://<user>.github.io/The-Last-Save-File/`.

### From the Godot editor

1. Install [Godot 4.3+](https://godotengine.org/download) (standard build, no .NET needed).
2. Open Godot, choose **Import**, and select this folder's `project.godot`.
3. Press **F5**.

Building locally: install the 4.3 export templates (*Editor → Manage Export Templates*), then
*Project → Export…* and use one of the presets (Windows Desktop, Linux, Web).

From the command line:

```bash
godot --path .            # play
godot --path . --editor   # open the editor
```

There are no external assets yet. All visuals are drawn in code, the hum is synthesized at runtime,
and the CRT/corruption look is a single screen shader.

## Project structure

```
project.godot                  Engine config (640x360 viewport, GL Compatibility renderer)
export_presets.cfg             Windows / Linux / Web export presets
.github/workflows/build.yml    CI: exports all three on every push, releases on tags
scenes/
  title.tscn                   Title screen (main scene)
  main.tscn                    The session: World, player, owner director, HUD, screen FX, drone
  player.tscn                  The intruder
scripts/
  autoload/owner_memory.gd     What the owner knows. Persists outside the save. Registers input.
  autoload/settings.gd         Player preferences (user://settings.cfg), button glyphs
  world/world.gd               Loads areas, transitions, talking, death / quit / win, purge ending
  world/areas/area.gd          Base class: walls with gaps, exits, NPCs, readables, the eraser
  world/areas/arins_room.gd    Start area: door, note, Mira, save crystal, seams
  world/areas/village_square.gd  Arin's patrol, Wren, Tobben, notice board, roads east and north
  world/areas/archive.gd       The Archivist and the live log books
  world/areas/the_edge.gd      Unloaded region, cursor, Slot 2
  world/npc.gd                 Any character: look, dialogue provider, hiding, deletion
  world/readable.gd            Books, signs, terminals
  world/exit.gd                Area-to-area exits (open or blocked with a reason)
  world/slot_two.gd            The last save file
  world/door.gd, note.gd, save_point.gd, seam.gd, ghost_marker.gd
  owner/owner_director.gd      Awareness, thresholds, the owner's voice; areas react to thresholds
  owner/owner_avatar.gd        Arin, driven by the owner: patrol route and view cone
  owner/owner_cursor.gd        The owner's mouse pointer: hunts and selects
  owner/erasure.gd             The eraser: a grid of overwritten cells that hunts you
  player/player.gd             Movement plus a body the renderer can't quite agree on
  ui/hud.gd                    Save-slot header, awareness meter, console, dialogue box, fades
  ui/title.gd, pause_menu.gd, settings_panel.gd, ui_style.gd
  fx/screen_fx.gd              Drives the corruption shader
  fx/drone.gd                  Procedural ambient hum that tightens with tension
shaders/
  save_corruption.gdshader     Scanlines, vignette, chromatic split, tearing
```

**Architecture:** `OwnerMemory` (persistent) → `World` loads one `Area` at a time and builds it from
that memory → `OwnerDirector` raises awareness and tells the current area when a threshold is
crossed → deaths, quits, helpers and wins flow back into `OwnerMemory`.

**Adding an area:** subclass `Area`, set `area_id`, `bounds`, `entries` and `awareness_rate` in
`_init()`, build the layout in `build()` with `add_boundary()`, `add_solid()`, `add_exit()`,
`add_npc()` and `add_readable()`, react in `on_owner_event()`, and register it in
`World._make_area()`.

---

## Where this could go next

- **Life after Slot 2**: playing *from* Slot 2, a save the owner is now hunting for.
- **The owner's habits**: they learn your *routes* as well as your death spots, and pre-place
  erasure, locked doors and watchers along the paths you favor.
- **More characters with loyalties**: someone who trades secrets with the owner, someone who
  forgets you every session, NPCs who remember what happened to Wren.
- **Save-file UI as terrain**: the inventory, the map screen and the load menu as spaces you can
  physically enter.
- **More owner presence**: dragging props around, dialog boxes that open on their own, a
  "Delete save?" prompt you have to stop.
- **Audio**: real sound design (room tone, rewrite stingers, the owner's typing).

## License

TBD.

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
fullscreen, **CRT curvature**, **glitch intensity** and **reduce flashing**, plus *Reset owner memory* on
the title screen. See [Visual effects](#visual-effects) for exactly what each one controls.

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

## Characters & story

**Who are you?** The game opens on the save booting: `[!] 1 UNRECOGNISED ENTITY · ENTITY SLOT: 02
· slot 02 does not exist.` Then you assemble out of pixels in Arin's room, a hooded figure with a
void for a face and two points of light, with no idea why you're here. Your own thoughts appear in
the console in cyan `(like this)`, reacting to waking up, to the town, to Arin, to the characters
the owner deletes because of you.

**Memory fragments.** Five cyan shards float where something happened: under Arin's bed, by the
well, between the Archive's shelves, and two at the Edge. Touching one stops the world for a short
letterboxed flashback, with the screen going pale and cyan like an old photo of a screen. Fragments
are *your* memories, not the owner's: they survive deaths and purges (only a full reset clears
them). Together they tell what happened: two people shared one console; one always played Arin in
slot 1, the other made their own character in slot 2. They drifted apart, and one night the owner
deleted slot 2. **You are what's left of that save.**

The world reacts to how much you remember:
- the Archivist counts the pieces of you they can see, and greets you by name once you have them all;
- Mira, Wren and Tobben each half-remember "the other one";
- the owner starts to recognise you (*"...you move like someone i used to know."*);
- the ending changes, and with all five the title screen shows `SLOT 2 · RUE`.

All narrative text lives in `scripts/story/story.gd`, with the full story in its header comment.

**Characters.** Everyone is code-drawn pixel art (`scripts/world/pixel_character.gd`): 8-pixel
templates drawn at 2x, with a 4-frame walk cycle, swinging arms, breathing, blinking, a mouth that
moves while they talk, facing in four directions, and speech-bubble emotes. Each has a personality
in motion:

| Character | Look | Moves |
| --- | --- | --- |
| You | Hood, void face, glowing eyes, cyan | Walk cycle plus trail, tearing slices, dropped frames |
| Mira | Long hair, orange dress | Sways, turns to watch you, `!` when she notices you |
| Arin | Blue tunic, red scarf | Patrols with a walk cycle, points at you when they see you |
| Wren | Child, pigtails, green dress | Hops in place, `!` |
| Tobben | Bald, moustache, apron | Waves you over, `?` |
| The Archivist | Tall, white beard, robe | Reads a book and turns the pages, `...` |

## Visual effects

Everything is still coloured rectangles; the atmosphere comes from one full-screen shader
(`shaders/save_corruption.gdshader`), one controller (`scripts/fx/screen_fx.gd`) and a handful of
effects drawn in the world. Only 3 texture reads per pixel, so it stays cheap in the browser too.

**The screen.** Curved CRT glass with a soft bezel, one scanline per game pixel row, an RGB
aperture grille, a faint refresh band rolling down, radial chromatic aberration (stronger at the
edges), and animated grain.

**Awareness drives the look.** `OwnerDirector` feeds awareness into `ScreenFx.awareness_target`,
eased so the screen *slides* into sickness rather than jumping:

| Awareness | What the screen does |
| --- | --- |
| low | Clean-ish CRT. Rare background twitches. |
| rising | Colour drains and tints red/magenta. Fringing widens. Vignette closes in. |
| 35%+ | Background tearing starts; a thin tear line sweeps down the screen. |
| high | The image breathes and wobbles row by row; the world layer jitters and skews (the HUD doesn't); brightness flickers; the player's trail and body-tearing intensify. |
| each threshold | A jolt: tearing spike, vertical-hold slip, red wash, world shake, the meter flinches. |

**Events.**

| Event | Effect |
| --- | --- |
| Character deleted | Body convulses in split colour, bursts into a spray of pixels in its own palette, leaves crawling static and a `name.npc = null` outline. Magenta wash and shake. |
| Cursor arrives | Heavy static, thin bright "whine" lines, vertical roll; the pointer materialises huge and shrinks into the world with red/cyan afterimages. While tracking it draws scan lines through itself; while selecting, marching ants close in and static builds on the whole screen. |
| Eraser | New cells: red strobing frame with a black core that grows until the cell is lethal. Settled cells: void with baked red grain, a burning dark-red bite edge, crawling static, occasional scar lines. Starting it floods the screen dark red. |
| Wall seam | Opens as a pulsing wound: red glow bleeding into the room, ragged edges, a white-hot core, leaking pixels. Patched seams from earlier sessions stay as stitched, faintly pulsing scars. |
| Entering the Edge | Big tear and roll; then a cold, colourless picture with rows of unloaded data flickering through. |
| Death: ERASED | The screen is eaten in blocks, red at the bite, while the player is eaten from the feet up. |
| Death: OVERWRITTEN | Rows smear sideways under a wash of Arin's blue as Arin's colours sweep down over the player. |
| Death: SELECTED · DELETED | Negative flashes, static, a selection box snaps shut and the player scatters into pixels. |
| Win (Slot 2) | Cyan flood, the player is pulled up into a streak, the tube collapses to a line and springs back... and a magenta flicker keeps coming back afterwards. |
| Quitting | The picture powers off like an old CRT. |

Death titles shake with colour-split ghosts and keep corrupting themselves; owner messages type
in as garbage that resolves into words, carry a cyan shadow, and corrupt themselves later (more
often the more aware the owner is). The awareness meter is segmented, beats like a pulse that
quickens as it fills, shifts orange → red → magenta, misfires, and its label changes to
`OWNER IS WATCHING` and `OWNER IS HERE`.

**Controls (Settings).** All applied in `ScreenFx`, so they cover every effect:

- **Glitch intensity** (0–1) scales all distortion: tearing, aberration, sickness, block glitches,
  world jitter and shake, player tearing and trail, text corruption. At 0 you get a calm CRT.
- **Reduce flashing** cuts colour washes, negative flashes, static bursts, brightness flicker,
  strobing and screen roll to about 30%.
- **CRT curvature** flattens the glass.
- **Screen effects** (Full / Light / Off) trades the CRT pass for speed on weak GPUs; see Performance.

**Tuning.** Every shader uniform is documented at the top of the shader; event strengths and
durations live in the event methods of `screen_fx.gd` (`threshold_pulse()`, `deletion_hit()`,
`cursor_arrives()`, `play_death()`, `play_win()`, ...).

## Performance

Measured in Godot 4.3 with the frame cap removed (headless, so this is all CPU work: scripts plus
building draw commands):

| Scene | CPU per frame |
| --- | --- |
| Arin's room | ~0.3 ms |
| Square (Arin, Wren, Tobben) | ~0.4 ms |
| Square, fully erased, cursor hunting | ~0.5 ms |
| The Edge | ~0.5 ms |
| Archive | ~0.3 ms |

The eraser draws settled cells on a layer that only redraws when a cell settles and grows from a
tracked frontier; the background hum is synthesised once at startup (~15 ms) and looped; the HUD only
re-shapes text when it changes. A soak test (40 area changes, repeated deaths) shows no node,
resource or object leaks, and the project has no GDScript warnings even with warnings-as-errors.

Most of the cost is on the **GPU**: one full-screen CRT pass at window resolution. Settings →
**Screen effects** picks how much of it runs:

| Screen effects | What you get | Relative GPU cost* |
| --- | --- | --- |
| Full (default) | Everything: 3-tap colour fringing, aperture grille, static lines | 100% |
| Light (default on phones) | Same CRT look with 1 texture read, no fringing or grille | ~70% |
| Off | No full-screen pass at all | ~30% |

*Frame time on a software GPU at 1280x720; real GPUs are far faster, the proportions are what matter.

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

## Tests

The suite lives in `tests/` and runs headless in about 1.5 minutes. CI runs it on every push and
pull request **before** building; a failing test or any Godot script error blocks the build and
the web deploy.

```bash
tests/run.sh                         # everything (uses `godot` on PATH)
GODOT=/path/to/godot tests/run.sh    # a specific Godot 4.3 binary
tests/run.sh --filter=story          # only files/methods matching "story"
# Screenshots of the effects (needs a display, so not headless):
godot --path . -s res://tests/run_tests.gd -- --test-mode --screenshots=/tmp/shots
```

Tests run with `--test-mode`, which points the owner's memory and the settings at separate
`test_*` files, so running them never touches your real progress.

| File | Covers |
| --- | --- |
| `test_memory.gd` | What the owner learns: deaths, quits, crashes, helpers, seams, fragments, purge, old-save migration |
| `test_world.gd` | The full route: seam, door, dialogue, Wren hiding (and being deleted), Tobben reporting, the pointer, the Edge, Slot 2, the hunt |
| `test_menus.gd` | Pause/resume, quitting counts, Slot 2 on the title screen, settings |
| `test_story.gd` | Boot sequence, flashbacks, fragments persisting, endings |
| `test_effects.gd` | Every death style, owner events, the win sequence, reduce flashing |
| `test_performance.gd` | Worst-case frame budget (fully hunted square) and leak checks across area changes |

Writing a test: add `tests/test_<thing>.gd` extending `res://tests/test_case.gd` and give it
`test_*` methods. They're coroutines, so you can `await start_session()`, `go_to()`, `press()`,
`interact_with()`, `wait_until()`; record problems with `check()` / `check_eq()`.

## Project structure

```
project.godot                  Engine config (640x360 viewport, GL Compatibility renderer)
export_presets.cfg             Windows / Linux / Web export presets
.github/workflows/build.yml    CI: runs the tests, exports all three on every push, releases on tags
tests/                         Automated test suite (run.sh, run_tests.gd, test_*.gd)
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
  world/npc.gd                 Any character: sprite, emotes, dialogue provider, hiding, deletion
  world/pixel_character.gd     Code-drawn pixel-art bodies and their animation
  world/memory_fragment.gd     The cyan shards of your past
  story/story.gd               Boot text, inner voice, the five fragments, endings
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
  fx/screen_fx.gd              The screen: awareness look, event effects, world shake, settings
  ui/awareness_meter.gd        The living OWNER AWARENESS bar
  fx/drone.gd                  Procedural ambient hum that tightens with tension
shaders/
  save_corruption.gdshader     CRT glass, scanlines, grille, aberration, sickness, tearing, deaths
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

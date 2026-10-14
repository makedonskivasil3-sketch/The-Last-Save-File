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

## The current prototype (vertical slice)

One room. One intruder. One owner who's getting impatient.

**Controls**

| Key | Action |
| --- | --- |
| WASD / Arrows | Move |
| E / Space | Interact (read, talk, try to save) |
| Esc | Quit (the owner counts this) |
| Hold F9 | Wipe the owner's memory (debug / "new game") |

**What happens**

- You load into **Arin's room**: a bed, a table, a rug, a save crystal, a note on the wall, and Mira.
- An **owner awareness** meter fills over time and spikes when you do things the real Arin wouldn't
  (talking to Mira, reading the note, trying to use the save crystal).
- As awareness rises, the owner acts:
  - **25**: the note on the wall is rewritten, but only once you've walked away from it.
  - **40**: the lights flicker. *"who are you?"*
  - **50**: the door locks (or locks instantly if you walk toward it). The rewrite tears the wall
    somewhere, and a **seam** starts flickering.
  - **65**: Mira is deleted for talking to you.
  - **75**: the **eraser** starts. Cells of the room are overwritten with nothing and grow toward
    you. New cells flicker for a moment as a warning. Once they settle, touching one kills you.
  - **100**: *"hold still."* The eraser doubles its speed.
- Once it appears, the **seam** is a gap the owner hasn't patched yet. Touch it
  to slip out of the room (the end of the slice).

**How the owner adapts (persisted across sessions)**

| You... | The owner... |
| --- | --- |
| Die | Remembers where. Your ghost marker stays on the floor, and the eraser seeds from there. |
| Quit (Esc or closing the window) | Notices. *"you closed the game. i didn't."* |
| Kill the process | Treats it as running away and counts it as a quit. **This includes the Stop button in the Godot editor**: quit with Esc instead, or hold F9 to reset. |
| Escape through a seam | Patches that seam. The next one is somewhere else. Five in total. |
| Anything | Starts the next session more aware, with the door deleted, Mira restricted or removed, a darker room, and a faster eraser. |

Every death or quit adds one to **purge progress**. At **6/6** the owner wins: the save is clean,
the real Arin is back in the room, and you're gone. (Hold F9 if you want to come back.)

The owner's memory is stored at `user://owner_memory.json`:

- Linux: `~/.local/share/godot/app_userdata/The Last Save File/`
- Windows: `%APPDATA%\Godot\app_userdata\The Last Save File\`
- macOS: `~/Library/Application Support/Godot/app_userdata/The Last Save File/`

---

## Running it

1. Install [Godot 4.3+](https://godotengine.org/download) (standard build, no .NET needed).
2. Open Godot, choose **Import**, and select this folder's `project.godot`.
3. Press **F5**.

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
scenes/
  main.tscn                    The room: player, owner director, HUD, screen FX, drone
  player.tscn                  The intruder
scripts/
  autoload/owner_memory.gd     What the owner knows. Persists outside the save. Registers input.
  owner/owner_director.gd      Awareness, thresholds, and the owner's voice
  owner/erasure.gd             The eraser: a grid of overwritten cells that hunts you
  world/room.gd                Builds the room from OwnerMemory, handles death/quit/escape
  world/door.gd                Open / locked / deleted
  world/note.gd                Rewritten when you're not looking
  world/npc.gd                 Mira (normal / restricted / deleted)
  world/save_point.gd          Doesn't recognize you
  world/seam.gd                An unpatched gap: the way out
  world/ghost_marker.gd        Where you died before
  player/player.gd             Movement plus a body the renderer can't quite agree on
  ui/hud.gd                    Save-slot header, awareness meter, typed console
  fx/screen_fx.gd              Drives the corruption shader
  fx/drone.gd                  Procedural ambient hum that tightens with tension
shaders/
  save_corruption.gdshader     Scanlines, vignette, chromatic split, tearing
```

**Architecture in one line:** `OwnerMemory` (persistent) → `Room` builds the world from it →
`OwnerDirector` raises awareness and calls into the room → the room reports deaths, quits and
escapes back to `OwnerMemory`.

---

## Where this could go next

- **More of the save**: a hallway, a town, a dungeon. Each area is a place the owner can
  "unload" while you're inside it.
- **The owner's habits**: they learn your *routes* as well as your death spots, and pre-place
  erasure, locked doors and watching NPCs along the paths you favor.
- **NPC loyalty**: some NPCs report you, some hide you, and some get deleted for helping.
- **Save-file UI as terrain**: the inventory, the map screen and the load menu as spaces you can
  physically enter.
- **Owner presence**: a cursor that drags things around the room, dialog boxes that open on their
  own, a "Delete save?" prompt that you have to stop.
- **Fake meta**: the title screen remembering you, the window title changing, a second save slot
  that's empty… for now.
- **Audio**: real sound design (room tone, rewrite stingers, the owner's typing).

## License

TBD.

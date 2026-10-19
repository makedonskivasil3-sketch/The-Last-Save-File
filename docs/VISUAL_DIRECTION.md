# Visual direction: illustrated, clean, corrupted only on purpose

**Target:** a contemporary illustrated psychological thriller. Expressive characters, authored places, clear cinematic UI. Digital corruption is reserved for moments when the owner is acting.

**Status labels:**
- **Implemented:** in the code.
- **Inspected:** looked at in screenshots.
- **Pending:** not done.

## Rendering strategy (implemented)

**Simulation is unchanged.**
- The world still runs in 640×360 logical coordinates.
- Collision boxes, speeds, interaction ranges, routes and every saved position are the same.
- No gameplay coordinate changed.

**Presentation draws at window resolution.**
- The project already used `canvas_items` stretch, so anything drawn as vectors renders at the window's resolution (1280×720 and up) while living in logical coordinates.
- The new characters (`IllustratedCharacter`) and environments (`Decor`) are vector-drawn.
- 2D MSAA is on (`rendering/anti_aliasing/quality/msaa_2d=2`).

**Layers, bottom to top:**

| Layer | Contents |
|---|---|
| World | Backdrop (static scenery painted once), the area's live drawing, characters, canopies |
| Screen effects | Layer 10: the corruption shader |
| HUD | Layer 15: subtitles, objective, meter, prompts, death and ending cards |
| Pause, touch | Layers 20 and 18 |
| Title menus | Layer 15 |

Text is never distorted by the effects; the world can be.

**The screen is clean by default.**
- No curvature, scanlines, grille, refresh band or bezel at rest. These are now the opt-in "CRT screen" setting.
- Colour split, scanlines and tearing appear only as the owner's awareness rises, at the Edge, and during events (cursor arrival, deletion, death). Corruption now means something.
- **Settings migration:** the old `video/crt_curvature` key was on by default for every player, so it isn't read as a choice. The new key is `video/crt_screen`, default off.

**The HUD and UI:**
- Positions are still in the 640×360 logical space, now rendered crisply.
- The interaction prompt sits above its target, clamped to the screen.
- The objective shows one line, with the truth-route hint as a quieter line under it.
- The dialogue box is rounded, with the speaker's illustrated portrait.
- **Not done:** fully converting the HUD to containers. The fixed layout already scales with the window and text size. A container rewrite is listed as remaining work rather than done partially.

## Characters (implemented, inspected)

`scripts/world/illustrated_character.gd` extends `PixelCharacter`. It uses the same palette keys and animation state, so these all keep working unchanged:
- restoration (cyan "missing" Rue regaining her colours, one memory at a time);
- borrowed pieces;
- fraying;
- startle, crouch, hug, shiver, glance, wave, point;
- reading;
- the glitch slices.

**What changed:**
- Soft shapes with one dark outline around the whole figure.
- Big readable heads with painted shading.
- Eyes with highlights, brows and a mouth that respond to mood (`MOODS`: neutral, concerned, afraid, relieved, determined, remembering, and the characters' own eager, proud, reset, brave, awed).
- **Silhouettes:**
  - Rue: cowlick, red scarf with a trailing end, raincoat with pockets;
  - Mira: long hair, dress;
  - Wren: child, pigtails with ribbons (gone when frayed);
  - Tobben: bald crown, moustache, apron;
  - Archivist: tall, white beard, robe and sash;
  - Arin: plain tunic and belt;
  - deleted Rue: a void face with two points of light.

**Portraits:** `PortraitView` draws the same figure as a bust, in the speaker's current palette and mood. The face in the box is always the face on screen. Every person has their own portrait; Pip, a creature, has none. The old 32×32 pixel grids remain in `CharacterArt` (with their tests) but are no longer shown.

## Environments (implemented, inspected)

The `scripts/art/decor.gd` kit:
- planks;
- cobbles and flagstones;
- grass;
- paths;
- wall shadow;
- walls with face and cap;
- three-quarter furniture with a lit top and shaded front;
- bed;
- rug;
- lamp;
- plant;
- tree canopy;
- house.

**Rules:**
- Only solid things have a front face. Decoration that isn't solid stays flat.
- Tree canopies are drawn above the cast but turn see-through over anyone beneath them (`Area.add_canopies`), so they never hide Rue or a threat.
- Static scenery goes on a backdrop drawn once (`Area.set_backdrop`), not every frame.

**Per area:**

| Area | State |
|---|---|
| Arin's room | Illustrated (slice): boards, rug, quilted bed in the nook, desk with the console's green light and a lamp, things flat on the floor |
| Village square | Illustrated (slice): grass, dirt path, cobbled roads, Arin's house with roof and door, the well, Tobben's striped stall with produce, overhead canopies, flower beds, fence |
| Archive | Illustrated: flagstones, shelves of varied spines, desk on a runner, lamp |
| Arin's house | Illustrated: warm living room; Player 2's room as the same boards gone cold, with outlines of missing furniture; wardrobes to hide in |
| Recycle Bin, Out of Bounds, the Edge | The owner's system spaces. They keep their deliberate digital look (grids, missing textures, sweeps) for contrast with the familiar world; they pick up the new walls |
| Crate stack (prop) | Illustrated |

## Performance (measured, software renderer only)

**Setup:**
- **Machine:** Intel Xeon 2.1 GHz cloud container, Xvfb with Mesa llvmpipe (no GPU), 1280×720, effects Full.
- **Method:** average frame time over 90 frames (`tests/tour_slice.gd`, `tests/tour_visual.gd`).
- **Caveat:** the software renderer exaggerates per-light and per-shape costs. Real-GPU numbers: **not run**.

| Scene | Before (old pixel art) | Illustrated, first version | After baking backdrops and lean discs |
|---|---|---|---|
| Arin's room | ~45 ms | ~74 ms | ~53–56 ms |
| Village square | ~53 ms | ~86 ms | ~64–68 ms |
| Bin, Out of Bounds, Edge | ~38–44 ms | ~43–45 ms | unchanged (not redrawn) |

**What the cost is** (square, measured by switching layers off):

| Layer | Cost |
|---|---|
| The area's four 2D lights, including the shadow-casting sun (present before this pass) | ~13.5 ms |
| The illustrated cast | ~7 ms |
| Tree canopies | ~0 ms |
| The calm screen shader | ~0 ms (it no longer does scanlines or colour split at rest) |
| 2D MSAA | ~3 ms |

**What was done:**
- Static scenery is painted once into a 2× texture (`Area.set_backdrop`) instead of every frame.
- Figures use 8–12-sided discs instead of `draw_circle`.

**Still a regression here:** about +9 ms in the room and +11 ms in the square on this machine. Next steps if a real device shows it matters:
- turn off the sun's shadows on low effects;
- bake each figure's outline into one polygon;
- drop 2D MSAA on the web.

## Not done (pending)

- **Production art:** no external artist assets. Everything is drawn in code and needs nothing to be licensed. A finished pass would replace `Decor` and `IllustratedCharacter` drawing with authored art at the same anchor points:
  - feet at `FEET_Y`;
  - furniture footprints equal to their solid rects;
  - portrait busts from the same palettes.
- **Turning and stop animations** beyond the existing four facings, and a hand-made walk cycle.
- **A full container-based HUD.**
- **A taller wall face** along interior top walls (it would sit in the margin above the play area).
- **A typography pass:** the engine's built-in default font is still used, and no font file was added.
- **Visual evaluation by a person** on a real display: not run.

## Screenshots

Before and after captures for this pass were taken with `tests/tour_visual.gd` and `tests/tour_slice.gd` (the cast lineup, the room, a conversation, the square calm and hunting). They are attached to the PR, not committed.

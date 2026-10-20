# Visual direction: illustrated, clean, corrupted only on purpose

**Target:** a contemporary illustrated psychological thriller. Expressive characters, authored places, clear cinematic UI. Digital corruption is reserved for moments when the owner is acting.

**Status labels:**
- **Implemented:** in the code.
- **Inspected:** looked at in screenshots.
- **Pending:** not done.

## Art specification (the rules every new drawing follows)

| Topic | Rule | Why / trade-off |
|---|---|---|
| Perspective | Top-down three-quarter: floors seen from above, solid things show a lit top and a shaded front face toward the camera | Readable footprints: what you see as a front face is exactly what blocks you (collision = footprint) |
| Proportions | About 3 heads tall for adults, 2.5 for Wren; heads large for faces at 640×360 | Faces must read at gameplay scale; realistic proportions would make expressions vanish |
| Outline | One dark ink outline around the whole figure or object, none inside except features | Separates characters from busy floors without the noise of per-part outlines |
| Light | Two tones per material (lit/shade) plus the area's 2D lights. Light comes from a named source in each place (lamp, sun, console, TV) | Pools of light give each room a focal point; flat colour alone looked unfinished |
| Shadow | Soft ground ellipse under every figure; walls cast a short band | Grounds characters; shadows never imply cover that isn't there |
| Materials | Wood: planks with grain; stone: cobbles/flags; cloth: soft folds; system spaces: grids, wire, flat fills | Inhabited places are textured; the owner's spaces are not, so the contrast is the story |
| Detail density | Dense at the focal point and along walls, sparse in movement space | The open floor is where the player plays: keep it legible |
| Colour hierarchy | 1. Rue's cyan (and her restored colours), 2. danger (owner orange/red, Arin's cone), 3. interactables (pink brackets, prompts), 4. people, 5. scenery in muted, warm mid-tones | The player finds themselves and the threat first, then what they can use |
| Character animation | Same rig for all, different body language: Mira sways and watches, Wren hops, Tobben waves, the Archivist reads, Arin patrols and points | One system, distinct people; visual easing never delays control (movement is immediate) |
| Portraits | A bust of the same figure, same palette and current state (missing, restored, borrowed, frayed) and mood | The face in the box is always the face on screen |
| Typography | Inter (Regular for text, SemiBold for headings) for the world and interface; DejaVu Sans Mono only for the owner's system (file names, slot labels, system-space signage, redactions) | A neutral, highly legible face keeps text calm; the mono face marks what belongs to the owner |
| Corruption | Off at rest. Rises with awareness (colour split, tearing), spikes on events (thresholds, deletion, cursor, death). Never touches the HUD text layer. Scaled by Glitch intensity and Reduce flashing | Corruption is the owner acting; constant noise would make it meaningless |

### Interface type and spacing

- **Sizes (logical px at 640×360, ×1.25 with Large text):** 9 secondary HUD (objective, status, hints), 10–11 body and prompts, 12–14 section headings, 16 page headings, 28 death titles.
- **Spacing:** multiples of 2 logical px; panels have 16 px content margins, 6 px between stacked items; the HUD keeps a 14×10 px safe margin.
- **States:** hover = owner orange border; keyboard/gamepad focus = Rue's cyan border and text; pressed = orange fill. Back from any page returns focus to the button that opened it.
- **Motion:** fades of 0.3 s for tips and prompts; 0.6–1.2 s holds before a death card accepts input, so a held key doesn't skip it.

### HUD priority (what wins when things compete)

1. **Immediate danger:** warnings (on their own dark strip), the awareness meter, the status line (HIDDEN, SEEN). A tip waits while a warning is up.
2. **Current interaction:** the prompt above its target. A tip that covers the prompt fades back to 20%.
3. **Immediate intention:** the objective line.
4. **Secondary:** the objective hint, tips (one at a time, never during the act card, dialogue, choices, scenes or warnings), the console.

Right-aligned HUD lines grow to the left, so Large text never pushes them off screen.

## Rendering strategy (implemented)

**Simulation is unchanged.**
- The world still runs in 640×360 logical coordinates.
- Collision boxes, speeds, interaction ranges, routes and every saved position are the same.
- No gameplay coordinate changed.

**Presentation draws at window resolution.**
- The project already used `canvas_items` stretch, so anything drawn as vectors renders at the window's resolution (1280×720 and up) while living in logical coordinates.
- The new characters (`IllustratedCharacter`) and environments (`Decor`) are vector-drawn.
- 2D MSAA isn't available: Godot 4.3's Compatibility renderer doesn't support it (it warns and does nothing). Edges are smoothed by drawing at 2× (backdrops) and at window resolution (figures).

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

## Area composition (review, pass 4)

Inspected from `tests/tour_visual.gd` screenshots at 1280×720 (visual inspection by the developer, not by players).

| Area | Emotional purpose | Focal point | Routes | Danger / shelter | Evidence of history | State and next step |
|---|---|---|---|---|---|---|
| Arin's room | Familiar, watched, trapped | The lamp-lit desk and the console's green light; Mira by the bed | Door (locked by the owner), the thin wall to the nook (PHASE) | The owner's attention; no patrol here | Personal objects flat on the floor, the bed nook, a note | Good. The open floor reads as movement space. The rug draws the eye to the centre, where nothing is: acceptable, it frames the act card |
| Village square | Open, public, exposed | The well at the crossroads | Cobbled road east (Archive), north road, Arin's house door; the dirt path ties them | Arin's patrol and cone; shelter beside Wren, behind the stall | The notice board ("MISSING: ONE (1) INTRUDER"), Tobben's stall | Good. Canopies turn see-through over anyone beneath them. The well's label sits under the act card on arrival (minor) |
| Archive | Relief and curiosity | The Archivist at the desk on the runner | West back to Ashvale, east to the Recycle Bin | A quiet place: the owner can't see in | Shelves of unfinished books | **Improved in pass 4:** the floor was drawn with the cobble brush at a large size and read as "bubble wrap"; it is now laid flagstones (`Decor.flagstones`). Shelves are still thin bands: next step is taller shelf fronts |
| Arin's house | Domestic warmth beside absence | The TV-lit living room | Front door back to Ashvale | Arin comes home (door chime); closets hide you | Player 2's room: the same boards gone cold and blue, outlines where furniture was | Good contrast. Closets are small for their importance: next step is a lit edge on closet doors |
| Recycle Bin | Clinical, emptied | The system files' cyan shadows | Back to the Archive | The sweep line; shelter in a system file's shadow | Deleted files with names | Readable but sparse: it reads as a void with icons. Next step: a floor grid with hierarchy (a lit lane between files) |
| Out of Bounds | Vertigo, unfinished | The far ledge where Pip sleeps | Anchors joined by streaming floor chunks | Floor that flickers red before it goes | Debug labels left in the void ("TODO: nobody should ever see this") | Good hierarchy: solid = outlined anchors, unsafe = red grid |
| The Edge | Collapse, the end of the map | Slot 2 (top right) | Open field toward the slot | The cursor and the spreading static | Fragments of unloaded data | **Weakest:** the magenta checker blocks are as loud as the hazard, and Rue is hard to find at the bottom. Next step: dim the static that isn't dangerous yet, keep full saturation for cells that kill |

Collision check: solid furniture is drawn with `Decor.furniture`, which returns its top face from the same rect the area registers as solid, so what looks solid is solid. Flat decoration (rugs, papers) has no front face and doesn't block, and doesn't look like cover.

## Level design record (pass 5)

Evidence column: **R** = reproduced defect or measured geometry; **I** = developer inspection of screenshots; **O** = player observation (none yet).

| Area | Main intention | Essential route | Optional | Landmark | Safe space | Threat | Key interaction | Likely confusion | Change made | Evidence |
|---|---|---|---|---|---|---|---|---|---|---|
| Arin's room | Get out | Door (locked) or the thin wall (PHASE) | Note, Mira, the save crystal | Lamp-lit desk | None (watched) | The owner's attention | First glitch at the crack | Tap vs hold (pass 4 tips) | None this pass | I |
| Village square | Find the way on | Cobbled road east; north road (later) | Tobben, notice board, the well, Arin's house | The well | Beside Wren; behind the stall | Arin's patrol and cone | Hiding beside Wren | Whether the stall hides you | Arin no longer walks through the stall, house or well | R |
| Archive | Learn where Slot 2 went | West to east, past the desk | The four records; the CHARACTER FILE (truth route) | The Archivist's lamp | The whole room (owner can't see in) | None | Reading records | Records vs decorative books | Record stands; file pulses at FILE stage; hint says desk | I, R (hint text) |
| Arin's house | Find what's under the couch; survive a visit | Front door to couch and back | Player 2's room, photo, TV | The TV glow | Closets | Arin's visits | Hiding in a closet | Closets looked solid; chime too late | Open recesses, cue, status, 4 s chime; Arin's loop uses the doorway | R (route, timing), I |
| Recycle Bin | Restore deleted people | Along the files | Each file | The system files' cyan shadows | The shadows during the sweep | The sweep line | Standing beside a file | Sparse; reads as a void | None this pass (pending observation) | I |
| Out of Bounds | Cross to Pip | Anchor to anchor | The labels in the void | The far ledge | Anchors | Floor that flickers red | Timing crossings | None found | None | I |
| The Edge | Write into Slot 2 | South gap to Slot 2 | Two memories by the sides | Slot 2's glow | None (grace, then static) | Static, cursor, Arin | Luring the cursor, writing | Everything at once on arrival; generic goal | Countdown after the act card; state-tied goal; frozen writing behind text; valid guard routes; Arin goes around blocks | R |

Backtracking after all memories: Pip and the goal hint already point at the next person or the file (Progression); not changed.

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

**Portraits:** `PortraitView` draws the same figure as a bust, in the speaker's current palette and mood. The face in the box is always the face on screen. Every person has their own portrait; Pip, a creature, has none. During a scene, the portrait dims while the owner's line is shown, so the face never claims a line it isn't saying. The old 32×32 pixel grids remain in `CharacterArt` (with their tests) but are no longer shown.

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
| Pip | Illustrated in pass 3 (was the last pixel creature): soft body, ears, muzzle, curled asleep while waiting |
| Rue's shed body | Pass 3: Rue's own illustrated figure, grey, lying on its side and breathing faintly (was a pixel sprite) |

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

**What was done:**
- Static scenery is painted once into a 2× texture (`Area.set_backdrop`) instead of every frame.
- Figures use 8–12-sided discs instead of `draw_circle`.

**Still a regression here:** about +9 ms in the room and +11 ms in the square on this machine. Next steps if a real device shows it matters:
- turn off the sun's shadows on low effects;
- bake each figure's outline into one polygon;

## Title screen (pass 7)

The title is the first image anyone sees, so it now carries key art instead of a generic skyline behind a centred box.

- **Layout:** asymmetric. Large title type, flush left, over a menu column with no heavy box: a faint wash and one accent rule in the owner's colour (`UiStyle.side_panel`). The small print is two short lines, not a paragraph. The full controls stay in How to Play.
- **Key art (`scripts/fx/title_art.gd`):** Rue, drawn large, alone in a dark room facing the television the save runs on. The screen is the only light. It rims her on the side facing it, throws a cone across the floor and catches dust. The screen shows SLOT 1 full and SLOT 2 part-written with a waiting cursor (the save that never finished).
- **It changes with the save:** her colours come from `Player.palette_for` (the same rule as the sprite), so a first launch shows the missing version with two points of light for eyes. The Slot 2 bar fills a little with each memory. Past purge 1, the screen occasionally slips (scaled by the flash setting).
- **Status:** Implemented; Visually inspected (`tour_visual` 00/01). The look and feel of the first impression is still pending a human opinion.

## Pass 8: finishing the established direction (no new style)

Each change answers a capture, and each applies a rule from the art specification above rather than inventing a new one.

| Area | Before (capture) | Change | Status |
|---|---|---|---|
| The Edge's walls | Full magenta/black checkerboards, the loudest thing on screen after the cursor | **Grey-box blocks** (`Decor.greybox`): the untextured stand-ins of an unfinished level. A lit top face, a front face for depth, one crisp edge (the collision boundary) and a 6 px missing-texture tag in a corner. Unfinished world, not unfinished production | Implemented; Visually inspected (`tour_visual` 15) |
| The Edge's exit sign | "ASHVALE" drawn on Rue's arrival spot | Beside the gap | Implemented |
| Warning banner | 16 px headline across the top of the play area (y 70) | A compact plate (13 px) at y 50, shown only with text; warnings just under it | Implemented; inspection pending on every area |
| Text over the world | 2–4 px black rims (terminal look) | A thin outline plus a soft drop shadow (`UiStyle.outline`) | Implemented; Visually inspected |
| Interior walls | The top wall a flat band | A built-up face in `Decor.walls`: light falling off towards the ceiling, a faint wallpaper stripe, a wainscot with panels and a rail, the skirting. Shading, not height: collision unchanged | Implemented; subtle at 640×360, visible at 1280×720 |
| Character motion | Instant flips; dead stops | A 0.12 s squeeze through a turn and a 0.18 s settle on stopping, scaled about the feet | Implemented; Human observed: pending |
| Title in every state | One state checked | `tour_title`: clean, partial, full + frayed, after an ending with every button, large text, controller focus, touch, small window. With large text and every button the menu was 403 px on a 360 px screen: now the controls line gives way first, then the column scrolls and follows focus (the flashing warning always stays) | Implemented; Automated (`test_the_title_menu_fits…`); Visually inspected |

Not done in this pass: portrait expression work, furniture perspective beyond the shared `furniture()` helper, and a lighting hierarchy pass per area. All are listed under "Not done".

## Not done (pending)

- **Production art:** no external artist assets. Everything is drawn in code and needs nothing to be licensed. A finished pass would replace `Decor` and `IllustratedCharacter` drawing with authored art at the same anchor points:
  - feet at `FEET_Y`;
  - furniture footprints equal to their solid rects;
  - portrait busts from the same palettes.
- **Turning and stop animations** beyond the existing four facings, and a hand-made walk cycle.
- **A full container-based HUD.**
- **A taller wall face** along interior top walls (it would sit in the margin above the play area).
- **Typography:** done in pass 4 (Inter and DejaVu Sans Mono, see above). Still pending: a dedicated display face for titles, if the author wants one.
- **Visual evaluation by a person** on a real display: not run.

## Screenshots

Before and after captures for this pass were taken with `tests/tour_visual.gd` and `tests/tour_slice.gd` (the cast lineup, the room, a conversation, the square calm and hunting). They are attached to the PR, not committed.

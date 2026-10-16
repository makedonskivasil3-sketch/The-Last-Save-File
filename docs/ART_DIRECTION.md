# Art direction: The Last Save File

This is a living document. Each rule is marked **[in game]** if it already holds in the code, or **[target]** if it's a direction not yet implemented. The evidence is the visual tour (`docs/CREATIVE_AUDIT.md` §F).

## The idea

> The world is not simply corrupted. It is trying to remain the version of itself that someone remembers.

So every place shows two things at once:
1. **The remembered version.** Warm, specific, slightly too perfect, held at 14:22 in the afternoon.
2. **What's underneath it.** Unloaded data, cut content, the deleted.

The owner works to keep the first over the second. Rue sees through it.

## Colour language (semantic: a colour *means* something)

| Colour | Meaning | Where | Status |
|---|---|---|---|
| **Cyan** `#8cf2ff` | Rue's: memories, a glitch that worked, Slot 2, protected shelter in the bin | memory fragments, glitch success flicker, Slot 2, the bin's shelters | [in game] |
| **Magenta / red** `#e0704f`, `(0.9,0.1,0.6)` | The owner exerting control: the cursor, deletion, locks, the awareness tint | `screen_fx.gd` (`deletion_hit`, awareness colour), `Door.LOCK`, HUD owner lines | [in game] |
| **Cold blue-grey** | Unloaded, outside memory: the Edge, out of bounds, Player 2's emptied room | `edge_mode` in the shader, `arins_house.gd` Player 2 room | [in game] |
| **Warm amber** `(1.0,0.86,0.58)` | The remembered afternoon: what the owner is preserving | `SunBeam` (Arin's room) | **[in game: room]**, [target: square, house] |
| **Arin's blue** `(0.32,0.48,0.75)` | Being overwritten (Arin's colours replacing yours) | `play_death("overwritten")` | [in game] |

Rules:
- Never use cyan for an owner action, or magenta for something that helps Rue.
- Warmth is not safety. It is the *owner's* memory, and it drains when they look at you.

## Lighting

- **[in game]** One `CanvasModulate` per area (`Area.tint`), darkened by purge. The full-screen CRT shader (`shaders/save_corruption.gdshader`) adds vignette, grain, scanlines, and colour drain toward red as awareness rises.
- **[in game] The frozen afternoon** (`scripts/fx/sun_beam.gd`). A window in the wall throws a warm shaft across the floor, with dust hanging in it.
  - It never moves, because the save is always 14:22.
  - Its warmth is driven by the owner's awareness. It is full while calm, starts draining at about 15, and is down to a cold sliver by about 80.
  - On a reload it stutters, toned down by Reduce flashing.
  - It is draw-only (polygons plus 16 one-pixel motes), compatible with the GL Compatibility renderer, and has no lights or shaders.
- **[target]** The same beam in the square (a low sun over the rooftops) and the house living room, but *not* in Player 2's emptied room. Cold light there tells that story without a word.
- **[target]** The first time the owner notices you in the room (NOTICE), the beam should visibly shift. That would show the owner reacting on screen within the first minute.

## Surfaces and shapes

- **[in game]** Hard-edged pixel geometry is drawn in code. Areas are rectangles floating in black, like a screen inside a screen.
- **[in game, room]** Floors have plank seams with staggered joints, and props cast contact shadows (offset by (2,3), 28% black) so they sit on the floor.
- **[target]** Every remembered place gets one *specific* detail at floor level that someone would remember: the room's worn rug pattern (done), the square's chalk marks, the house's couch dent. Keep these generic or confirmed by canon (`docs/NARRATIVE_BIBLE.md`). Don't invent story objects.

## Corruption rules (what an anomaly means)

| Event | Signature | Status |
|---|---|---|
| The owner exerting control | magenta wash, a red lock, the cursor | [in game] |
| A reload | the whole picture rolls and slips, Rue is dragged back along her path, the sun stutters | [in game] |
| Rue finds something hidden | cyan glint, a soft pale "memory" tint | [in game] |
| A glitch opening a way | pink focus brackets beforehand, a cyan flicker on success | [in game] |
| Persistent change from a past run | **a scar:** sealed seams stay visible, glitch scars stay, the note changes | [in game] |
| Unloaded or out of memory | cold colour, missing-texture checkerboards, wireframe | [in game] |

- Effects must never hide a threat's tell (Arin's cone, the cursor, cracks before the static, the save ring). Checked in the tour shots `19`, `20b` and `21`.
- Text in the Edge gets the ghosting aberration. It is legible, but the death cards there are tiring (`25`). **[target]** Exempt the death-card layer from `edge_mode`.

## Camera and transitions

- **[in game]** A fixed camera per area. Shake only moves the world layer, never the HUD. Every distortion scales with *Glitch intensity*, and every flash with *Reduce flashing* (`screen_fx.gd` header).
- Rules: no camera motion that hides a threat, and shake decays within 0.5 s.

## Typography and UI

- **[in game]** The fallback font. Owner lines are red-orange and start with `>`. Rue's thoughts are pale blue in parentheses. System lines are grey capitals. Large text is available in Settings.

## Per area (identity in one screenshot)

| Area | Remembered or underneath | Key visual | Status |
|---|---|---|---|
| Arin's room | remembered | the afternoon beam over the rug, the bed in the nook | **beam done** |
| Ashvale square | remembered | [target] low sun and long shadows; Arin's cone is the only cool light | brown, flat |
| The Archive | between | shelves of cut content, a pool of lamp light on the desk | lamp done |
| Recycle Bin | underneath | an empty folder grid, cyan shelters | distinctive |
| Arin's house | remembered / emptied | [target] warm living room vs a cold Player 2 room | split done, beam to do |
| Out of bounds | underneath | blueprint grid, glowing anchors | distinctive |
| The Edge | underneath | missing textures, wireframe, debug labels | distinctive |

# World connections: audit (2026-10-31)

**What this is:** every way between two places, as the code builds it on `claude/last-save-file-prototype-ljwuq4` at `d9beec1`. It answers the revision brief's §5 questions for each one.

**Read from:**
- `scripts/world/areas/*.gd`:
  - `add_exit` (walk-through gaps);
  - `Passage` (an interaction);
  - `entries` and `entry_facings`.
- `World.change_area()`.

**Common to every connection** (`World.change_area`, `main`'s doorway design @ `adf2710`):
- **The walk-in:** the exit fires when Rue walks into its gap.
- **Fades:**
  - doorways: out 0.12 s, in 0.16 s;
  - into or out of Out of Bounds: 0.25 s and 0.3 s.
- **Sound:**
  - doorways: `ui_back`;
  - Out of Bounds: `transition`.
- **Facing:** Rue arrives facing into the room (`Exit.inward`, or the area's `entry_facings`).
- **Camera:** it follows Rue only where the place is wider than the screen (the square, 880 px). Every other place is one fixed screen.
- **People:** once Rue is inside, people she has met look up (`Area.on_arrival`).
- **First visits:** a new place says its name. A chapter card shows instead when the story has reached a new chapter (`World._chapter_check`).

| Connection | Physical relationship | Exit cue | Trigger | Arrival position / facing | Camera | Audio | Revisit purpose |
|---|---|---|---|---|---|---|---|
| Arin's room → square | Arin's front door opens onto the square's west houses | The door; Mira's and the room's prompts | Interaction at the door (`ArinsRoom`: `change_area("square","house")`) | `house` (111, 118), facing into the square | Follows (wide) | `ui_back` | Mira's errand. Her note on the board |
| Square → Arin's house | The same row of houses, its front door | House door, prompt | Interaction (`VillageSquare`: `change_area("house","front")`) | `front` (320, 270), facing up into the hall | Fixed | `ui_back` | The controller under the stairs. The closets as hiding places |
| Arin's house → square | Front door, south wall gap | Sign "ASHVALE" ↓ | Walk-through gap (south) | `house` (111, 118) | Follows | `ui_back` | — |
| Square → Archive | East road through the gatehouse | Sign "ARCHIVE" →, the gatehouse lamp | Walk-through gap (east) | `west` (118, 180), facing east | Fixed | `ui_back` | The Archivist, files, Leads |
| Archive → square | West gap | Sign "ASHVALE" ← | Walk-through gap (west) | `east` (898, 180), facing west | Follows | `ui_back` | Wren, Tobben, the well |
| Archive → Recycle Bin | East gap | Sign "RECYCLE BIN" → | Walk-through gap (east) | `west` (118, 180) | Fixed | `ui_back` | Restoring deleted people |
| Recycle Bin → Archive | West gap | Sign "ARCHIVE" ← | Walk-through gap (west) | `east` (522, 180) | Fixed | `ui_back` | — |
| Archive → lantern workshop | The stair down in the Archive's south wall (gap 430–470) | Sign "LANTERN WORKSHOP" ↓, the same stair stones | Walk-through gap (south) | `stairs` (450, 64), facing down | Fixed | `ui_back` | The service light; the fifth frame (this pass) |
| Workshop → Archive | The same stair, north gap | Sign "ARCHIVE UPSTAIRS" ↑ | Walk-through gap (north) | `workshop` (450, 266), facing up | Fixed | `ui_back` | — |
| Workshop → under the well | Service hatch in the west floor, brass rungs | Sign "WELL SERVICE HATCH" (lit only once repaired); the light's line from the lamp to the hatch | Interaction (`Passage`), **earned**: no target until the repair | Out of Bounds `workshop` entry, facing down onto the solid landing | Fixed | `transition` | A way to the well that doesn't cross Arin's road |
| Under the well → workshop | The same hatch from below | "LIT SERVICE HATCH" and sign "WORKSHOP / ARCHIVE" (after the repair). In the workshop demo candidate only: "DARK SERVICE LADDER" before it | Interaction (`Passage`) | `well` (152, 250), facing right | Fixed | `transition` | Back up without the square |
| Square → under the well | The well in the square's centre | Sign "WELL" ↓ | Interaction (`Passage` at the well) | Out of Bounds `well` entry | Fixed | `transition` | Pip; the anchor; the recordings |
| Under the well → square | The pillar of light upward | Sign "UP TO ASHVALE" ↑; lit once an anchor is kept | Interaction (`Passage`, "climb up") | `well` (320, 214) | Follows | `transition` | — |
| Square → the Edge | North road, beyond the last houses | Sign "NORTH ROAD" ↑, crossed out until the pointer | Walk-through gap (north); closed with a message until open | `south` (320, 274), facing north | Fixed | `ui_back` | Slot 2 and the endings |
| Edge → square | South gap | Sign "ASHVALE" ↓ | Walk-through gap (south) | `north` (320, 54), facing south | Follows | `ui_back` | — |

## What the audit shows

- **Every connection has a physical reason** (a door, a road, a stair, a hatch, the well) and a cue on the near side (a sign or a lit object).
  - Two are earned: the north road (the pointer) and the service hatch (the repair).
  - Each says why when touched closed.
- **Weakest cue:** Arin's room → square. The door is a prompt, not a sign. It is the first exit a player ever takes, and the opening's staging covers it (`test_first_session_route`), but there is no signpost. Leave it until a playtest shows a problem.
- **Fixed-screen places and the camera:** they match the logical screen. Only the square scrolls. Nothing jumps the camera on arrival.
- **Revisit purpose:** every place but the Recycle Bin and the house has a reason to return in the current story.
  - The house's reason ends once the controller is found.
  - The Bin's reason is only for players who lost someone.
  - Both are optional by design.
- **Measured route timing** (§6): `RELEASE_READINESS.md`, section of 2026-10-31.

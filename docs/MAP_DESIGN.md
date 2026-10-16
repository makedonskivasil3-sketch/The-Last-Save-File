# Map design: The Last Save File

> **Status (2026-10-16):**
> - **Fixed:**
>   - First-visit beats fire (T1).
>   - A refused seam stays usable (no soft-lock).
>   - Wren stays in the square while you escort Mira.
>   - Pip skips the planted memory.
> - **Still open:** the rest of §8 (well access, sign gaps, act order, which needs an author decision).

This is an audit of the seven areas, the transitions between them, and the wayfinding.
It was written from the code at the time of writing. No playtest was done and Godot was not run.

- Coordinates are area-local pixels, the same space as `Area.bounds`.
- Citations use the form `file:line`. Area files live in `scripts/world/areas/`.
- `world.gd` is `scripts/world/world.gd`, and `OMv` is `scripts/owner/owner_moves.gd`.
- **CONFIRMED** means the code path itself shows it. **HYPOTHESIS** means it needs a playtest.

Shared constants:

| Constant | Value | Source |
|---|---|---|
| Player speed | 90 px/s | `scripts/player/player.gd:37` |
| Escort speed | 60 px/s | `npc.gd:49` |
| Escort leash | 70 px | `world.gd:13` |
| Interact reach | 22 px | `world.gd:7` |
| Owner thresholds | NOTICE 25, SUSPECT 40, CONTAIN 50, SILENCE 65, HUNT 75, PURGE 100 | `owner_director.gd:8-13` |

Awareness and cooling:

- Awareness rises at (0.35 + 0.15·purge) × `area.awareness_rate` per second (`owner_director.gd:116`).
- It rises ×1.4 with an escort (:119-120).
- While hidden, it cools at 2/s instead (:121-122).
- It never cools below the last threshold that fired (`floor_level`, :85-90).
- A session starts at min(10·purge, 35) awareness (:22-23, :51).

Glitches:

- PHASE, FREEZE, FALSIFY and UNLOCK need 0 memories. DECOY needs 1, SCRUB 2, BLIND 3, RESTORE 4 and PAUSE 5 (`scripts/player/glitch.gd:20-37`).
- UNLOCK lasts 5 s, PAUSE 6 s, BLIND 3 s and FREEZE 2 s. PHASE reaches up to 46 px (`glitch.gd:41-48`).
- PHASE never lands outside `bounds.grow(-5)` (`glitch_controller.gd` `phase_landing`), so it cannot leave an area.

Owner moves (OMv):

- **Reload:** triggered by the 3rd glitch since the last load (from NOTICE on), or once at SILENCE (OMv:116-121, 140-145).
- **Save-over:** from HUNT, every 35 s, or after 8 s standing idle at SUSPECT or above (OMv:101, 313-316).
- **Crate drag:** only in the square (OMv:383-403).
- **Wren delete / Mira reset ring** (OMv:345-378).
- None of these run in the `archive` or `oob` areas (OMv:54, 81-82).

---

## 1. Arin's room (`room`): `arins_room.gd`

**Purpose.** "Where you wake up. The owner watches this room closely… The door is the owner's; the way out is a seam in the wall that only tears once the owner starts rewriting the room." (`arins_room.gd:3-5`). It is Act I, "SOMEONE ELSE'S SAVE" (`story.gd:251`). Art direction calls it the "remembered" place, with the frozen 14:22 afternoon beam.

**Bounds.** `Rect2(96, 36, 448, 256)` (:67). `awareness_rate = 3.0`, the highest in the game (:68).

**Entries.** `"start"` (320, 270) (:69). This is the only entry, because no exit anywhere targets `room` (grep of `change_area`/`add_exit`). The room is one-way.

**Exits:**

| Way out | Where | Condition | Leads to |
|---|---|---|---|
| Seam (one at a time) | first index of `SEAM_SPOTS` not in `OwnerMemory.patched_seams` (:145-151). Spots: (88,170,12,22) L, (540,210,12,22) R, (400,288,22,12) bottom, (200,28,22,12) top/window, (88,70,12,22) L (:17-23) | opens when awareness ≥ SUSPECT (:162-166); touched → `_on_seam` (:207-209) | `square` / `"house"` (111, 118) |
| Door, UNLOCKed | `DOOR_RECT (304, 28, 32, 8)` top wall (:7) | door must be LOCKED (`door.gd:44-46`): only session 1 (or purged) starts it OPEN (:86), and it locks at CONTAIN (:181-185). Sessions 2+ the door is DELETED, so UNLOCK is impossible | walk to y < 38 within 18 px of the door while it is forced open (:156-159) → `square` / `"house"` |

- Patched seams are drawn as stitched "scars" and cannot be used (:139-144, `seam.gd:56-60, 92-102`).
- At most 4 of the 5 seams can be patched (`owner_memory.gd:434, 488`), so one seam always remains.
- In session 1 the door looks OPEN (black, with warm light) but is always solid (`door.gd:26-28`).
- Coming within 70 px of the OPEN door (:24, :160-161) jumps awareness to CONTAIN+2 with the line "nope." (`owner_director.gd:146-151`). That opens the seam (≥40) and locks the door in the same frame. This is the designed first exit trigger.

**Locked or conditional.** The cracked nook behind the bed is walled by `NOOK_WALLS [Rect2(458,36,4,84), Rect2(458,116,86,4)]`, with the crack at (500,118) (:27-28).

- It is built only while the room's memory is unrecovered (:123-130).
- PHASE gets you through it (any face of the partition; the crack is only the visual and guide).
- The wall falls for good once the fragment is taken (`cracked_wall.gd:36-54`).

**Glitch routes:**

- PHASE goes into the nook.
- UNLOCK on the door works in session 1 only, after CONTAIN.
- Every glitch adds awareness, which also brings the seam open sooner.

**Hiding.** None. Mira has no `hide_radius`.

**Interactables:**

| Item | Position | Notes |
|---|---|---|
| Note | (150, 32) (:8) | +4 awareness on read (:197-198). Text depends on `previous_exit` (:249-261). Rewritten at NOTICE (:179-180). FALSIFY target |
| Mira | (440, 130) (:9) | +8 per talk (:111). Asks to come along after 2 talks (:219-222). The choice is at :230-246 |
| Save point | (420, 236) (:10) | +15 awareness, plus "don't touch that." at NOTICE or above (:199-204) |
| Memory "controller" | (505, 96), inside the nook (`story.gd:91`) | |
| Props | bed `(470,44,58,32)` and table `(116,216,36,22)` are solid; rug `(256,130,128,80)` and window `(196,28,52,8)` with the SunBeam (:11-15) | |

**Patrols.** None.

**Owner intervention:**

| Trigger | Effect | Source |
|---|---|---|
| NOTICE | note rewrite | :179-180 |
| CONTAIN | door locks; "WARNING: wall integrity 97%" | :181-185 |
| SILENCE | Mira deleted unless she is escorted | :186-192 |
| HUNT | eraser seeded at door + (0, 10) = (320, 42), plus past death spots | :193-194, `area.gd:77-81` |
| HUNT onward | save-over and reloads | (OMv) |
| Return after a death/quit | "seal" sound 2.2 s after arrival | :133-137 |

**Safe spots.** None. This is the most watched room (×3).

**Confusion points:**

1. **Sessions 2+ (CONFIRMED mechanics):**
   - The door is DELETED, so approaching it triggers nothing. The seam only opens at 40 awareness.
   - At purge 0 that is about 38 s of 1.05/s with no visible countdown or meter link. The only tip is "way_out", shown once ever (`tutorial.gd:18, 92-94`).
   - **HYPOTHESIS:** the player may read this as "stuck".
2. **The seam position moves between sessions**, and patched scars look like seams at a glance (HYPOTHESIS).
3. **The window seam (200,28) overlaps `WINDOW (196,28,52,8)`.** The warm SunBeam is drawn in the same spot, which may wash out the wound (HYPOTHESIS).
4. **The goal says only "Get out of Arin's room."** (`world.gd:437-438`). It gives no hint about the walls or awareness.

**Recovery.** Death or quit returns you here. The note recalls your death (:250-256), the death is logged, and the seam used is patched at session end (`owner_memory.gd:488-489`).

**Landmarks:** bed nook with flickering crack; rug diamonds; window beam; save point; Mira.

---

## 2. Ashvale village square (`square`): `village_square.gd`

**Purpose.** "Ashvale's square, the owner's hub. Arin (driven by the owner) walks a loop around the well. Wren can hide you. Tobben reports you." (:3-4). It is Act II.

**Bounds.** `Rect2(40, 36, 560, 256)` (:73). Rate 1.0 (:74).

**Entries:**

| Name | Position | From |
|---|---|---|
| `house` | (111, 118) | room seam/door, house front |
| `east` | (578, 180) | archive |
| `north` | (320, 54) | edge |
| `well` | (320, 194) | oob pillar |

All four are at :76-81.

**Exits:**

| Way out | Rect / point | Condition | Leads to |
|---|---|---|---|
| East road | x 600-608, y 160-200 (`EAST_GAP`, :16, :96) | always open | `archive` / `"west"` |
| North road | x 300-340, y 28-36 (`NORTH_GAP`, :17, :97-100) | `flags.pointer` (session-only, from the Archivist, `archive.gd:94`). Re-evaluated every frame (:276). Blocked message: "The road north isn't loaded. Nothing in this save points there." | `edge` / `"south"` |
| Well (Passage, interact) | (320, 184), 6 px below `WELL (306,158,28,20)` (:8, :134-141) | always | `oob` / `"well"` |
| Arin's front door | `HOUSE_DOOR (98, 96, 26, 6)` (:7), LOCKED (:113-115) | UNLOCK, then come within 18 px of the door while forced (:270-272) | `house` / `"front"` |

**Glitch routes:**

- UNLOCK on the front door is the only way into the house. Its readable hints "(a lock is just a flag. flags can be flipped.)" (:285-286).
- PHASE through the dragged crates.
- FREEZE Arin.
- FALSIFY the board.
- DECOY, BLIND or PAUSE against the hunt.

**Hiding.** Beside Wren at (126, 246) with radius 22 (:144, :352). The tutorial teaches it (`tutorial.gd:16`).

**Interactables:**

| Item | Position | Notes |
|---|---|---|
| Notice board | (240, 40) (:15) | FALSIFY target; pinning Mira's note (:229-240, `world.gd:505-507`) |
| House-door readable | (111, 108) (:116) | |
| Wren | (126, 246) | asks to join after 2 talks (:369-371) |
| Tobben | (488, 92) (:148) | reports you 4 s after a talk for +12 (:415-427); guest-book scene (:386-412) |
| Planted false memory | (500, 250) (`story.gd:154`) | spawns once you have 2 or more real memories (:125-132) |

Landmarks drawn: `HOUSE (56,44,110,56)`, `WELL (306,158,28,20)` and `STALL (440,44,96,34)`, all solid (:90-91). Trees at (190,268), (560,250), (420,274), (560,120) and (60,160) are decoration and not solid (:18, :441-443). `CRATES (64,222,40,40)` is a DragProp (:11, :92-94).

**Arin's patrol.**

- `ROUTE` is a rectangle (200,130) → (440,130) → (440,230) → (200,230) (:19).
- Each session adds up to 3 detours through spots where Arin saw you, `min(sessions-1, 3)` (:176-187).
- Arin starts at ROUTE[0] (200,130) on every load (:163). Speed is 38 + 4·purge (:165), ×1.25 at SUSPECT (:211-212).
- View is 85 px (`owner_avatar.gd:17`), +20 at CONTAIN (:213-214).
- Sight grace is 0.35 s, then 22 awareness/s (:21-23, :313-327).
- Touch means death (:169). Arin holds still during dialogue and PAUSE (:277).

**Owner intervention:**

| Trigger | Effect | Source |
|---|---|---|
| NOTICE | board rewrite | :207-210 |
| SILENCE | Wren deleted if she hid you this session and isn't saved | :215-220 |
| HUNT | eraser seeded at `ERASE_SEEDS (56,280), (588,52)` plus past deaths here; cursor spawns at (320,40), speed 48 + 5·purge | :26, :221-222, :297-310 |
| PURGE | cursor ×1.2 | :223-225 |
| HUNT, crate drag | cursor drags the crates to `BLOCK_NORTH (320,58)` or `BLOCK_EAST (580,180)` (:13-14) when you are 36-150 px from one. 8 s initial cooldown, then 25 s; holds 14 s (OMv:40-41, 71, 394-403) | |

**Safe spots.** Beside Wren. Inside the loop is never safe.

**Confusion points:**

1. **The well's interact point is on its south side only. CONFIRMED.**
   - The passage is at (320,184). The WELL sign is at (320,150), *north* of the well, arrow down (:122).
   - The well is solid from y 158 to 178, so a player standing on the sign side is ≥ ~26 px from the passage. That is beyond the 22 px reach, so no prompt appears.
2. **The Wren hiding spot is about 78 px from an eraser seed. CONFIRMED geometry.**
   - (126,246) to (56,280) is 78 px. The eraser targets the player whether or not they are hidden (`erasure.gd:206-216`, target is the player).
   - **HYPOTHESIS:** hiding with Wren during HUNT, as the tutorial teaches, gets the player caught by the static.
3. **Entering the square from the house door lands 90 px from Arin's spawn.** Arrival is (111,118) and Arin spawns at (200,130), just past view range. Arrival from the well (320,194) is 36 px from the loop's bottom edge (y 230). **HYPOTHESIS:** being spotted on arrival.
4. **The `east` arrival (578,180) is 2 px from `BLOCK_EAST`.**
   - During HUNT, once you walk 36 px in, the cursor may drag the crates across the road you just used (OMv:398).
   - The roads stay closed 14 s at a time. The only feedback is "no. not that way." (OMv:400).
5. **The north road's blocked message doesn't say what opens it** (the Archivist).
   - The pointer is session-only (`world.gd:16`), so every session needs the Archive trip again.
   - The goal text is "Explore the village. The road east leads somewhere old." (`world.gd:453`).
6. **No sign marks Arin's house.** The door has a readable but no `ExitSign`. That is intended as optional.

**Recovery.** From the square you can reach the Archive (cools awareness, no owner moves) or the well (oob, cools). Death returns you to the room. The death-spot ghosts (`area.gd:97-102`) mark where you fell.

**Landmarks:** well (centre), Arin's house (NW), Tobben's striped stall (NE), crate stack (SW), notice board (N), path cross, static on the unloaded north road (:437-440).

---

## 3. Arin's house (`house`): `arins_house.gd`

**Purpose.** "The couch faces a TV that's showing this game. Upstairs… Player 2's room: emptied… The second controller is under the couch. Every so often Arin comes home… Get into a closet." (:3-9). It has no act card (`story.gd:250-256`).

**Bounds.** `Rect2(96,36,448,256)` (:43). Rate 1.1 (:44).

**Entries.** `"front"` (320, 270) (:46).

**Exits.** The front gap x 300-340, bottom wall (`FRONT_GAP`, :11, :57) leads to `square` / `"house"` (111,118). Its sign reads "ASHVALE ↓" at (320, 280) (:58).

**Internal partition.** `WALL_X = 380` (:16) with a doorway at y 196-236 (`DOORWAY` is a Vector2 used as a y-range, :17, :55-56) into Player 2's room. PHASE can cross the wall elsewhere.

**Hiding.** `CLOSETS (104,44,26,34)` (top-left, living room) and `(508,248,26,34)` (bottom-right, P2 room) (:19, :74-78). These areas are not solid.

**Interactables:**

| Item | Position | Notes |
|---|---|---|
| THE TV | (198,124) | +4 |
| PHOTO | (300,44) | |
| THE COUCH ("look under") | (198,214) | sets `found_controller`, +10 (:138-152) |
| PLAYER 2 | (400,188) | |

The readables are listed at :60-64.

**Arin's visits.**

- The first visit comes 8 s after you arrive (`FIRST_VISIT`, :22). A chime and "(the door. someone's coming in.)" warn 2.5 s before (:95-98).
- Arin enters at (320, 288), the same gap as your exit (:109). The route covers both rooms (:25-28) at speed 40 (:110).
- A visit lasts 15 s (:24). The next comes 24 s after Arin leaves, because the countdown only runs while Arin is absent (:86-94).
- Sight costs 20/s (:114-116) and touch means death.
- PAUSE freezes Arin and the timers (:82-85).

**Owner intervention.**

- There is no `on_owner_event` override, so awareness thresholds do nothing here *while you are inside*.
- `catch_up()` (the base, `area.gd:40-42`) starts the eraser only on entry when HUNT has already fired. The seeds are death spots, or else a random edge (`erasure.gd:116-122, 154-157`).

**Safe spots.** The two closets.

**Confusion points:**

1. **During a visit, Arin walks in through the only exit** and loops the house, so the exit is unusable for up to 15 s. That is intended, but nothing says "wait".
2. **The far closet from the entry is about 230 px away** (via the doorway), which takes about 2.6 s. The chime gives 2.5 s, plus the time Arin needs to walk in. **HYPOTHESIS:** tight on a first visit.
3. **A random-edge eraser seed (HUNT on entry) can land on the single front gap** (HYPOTHESIS: needs SCRUB).

**Recovery.** Hide, then leave after "arin left." (:89-93).

**Landmarks:** TV glow, couch, the cold P2 room with furniture outlines and the ghost of a poster (:96-115).

---

## 4. The Archive (`archive`): `archive.gd`

**Purpose.** "Cut content. The Archivist was removed before the game shipped, so the owner has never seen them… The books here keep a record." (:3-5). The rate comment calls it "The one place to catch your breath." (:28-30). It is Act IV.

**Bounds.** `Rect2(96,36,448,256)` (:27). Rate −0.6, so awareness cools here (:30).

**Entries.** `west` (118,180) and `east` (522,180) (:32).

**Exits:**

| Exit | Rect | Leads to | Sign |
|---|---|---|---|
| West gap | y 160-200 (:12, :41) | `square` / `"east"` | "ASHVALE ←" at (128,150) (:43) |
| East gap | y 160-200 (:14, :44) | `bin` / `"west"` | "RECYCLE BIN →" at (504,150) (:45) |

**Interactables:**

| Item | Position | Notes |
|---|---|---|
| Archivist | (320,192) (:46) | the first talk sets `flags.pointer` and says "RECEIVED: slot_2.ptr" (:94-95) |
| Book: SESSION LOG | (180,138) | |
| Book: DELETED ASSETS | (440,138) | |
| Book: CUT CONTENT | (200,84) | |
| Book: THE OWNER | (440,84) | |
| Memory "new_game" | (470,104) (`story.gd:114`) | |

The books are placed at :57-60.

**Obstacles.** `SHELVES` (130,64,140,12), (370,64,140,12), (130,118,140,12), (370,118,140,12) and `DESK (296,204,48,14)` (:7-11).

**Owner.**

- None. `catch_up` is a no-op (:69-70), and there are no owner moves (OMv:54).
- Arin and the cursor never appear here.

**Safe spot.** The whole area.

**Confusion points:**

1. **The Archive is Act IV but is usually reached before Act III (OOB).** Pip and the goal both point east first (village_square.gd:291-294, `world.gd:453`). CONFIRMED order mismatch; the impact is a HYPOTHESIS.
2. **The goal "Ask the Archivist where slot 2 went."** (`world.gd:451`) mentions Slot 2 before anyone has said those words. It only shows if you entered without talking.

**Recovery.** This is the cooling refuge.

**Landmarks:** four book shelves, desk, lamp pool (320,190) (:185).

---

## 5. Recycle Bin (`bin`): `recycle_bin.gd`

**Purpose.** "Where deleted things go, for a while… every so often empties the bin… except what sits in the shadow of a protected system file. Between sweeps you can restore the characters the owner deleted… and read what the owner threw away" (:3-8).

**Bounds.** `Rect2(96,36,448,256)` (:40). Rate 1.2 (:41).

**Entries.** `west` (118,180) (:43).

**Exits.** The west gap at y 160-200 leads to `archive` / `"east"` (:16, :51). Its sign reads "ARCHIVE ←" at (128,150) (:52). It is a dead end.

**Shelters.**

- The `SYSTEM_FILES` are solid: (170,70,24,30), (300,200,24,30), (420,90,24,30) and (220,230,24,30) (:12-14).
- Each one shades a strip 34 px east and ±6 px vertically (`sheltered_at`, :15, :146-151). The usable band is only the 34 px east of each file.

**Sweep.**

- The first sweep comes at `max(6, 9 − 0.5·purge)` s (:75). After that, every `max(8, 16 − purge)` s (:119).
- A 3 s banner countdown "EMPTYING RECYCLE BIN IN n" runs before each one (:124-130).
- The line crosses left to right in 2.6 s, at 172 px/s (:21, :115-116).
- Unsheltered means death "erased/bin" (:160-162). A restore in progress is reset when the line passes its file (:156-159).
- PAUSE stops the sweep (:101-103, :111-112).

**Interactables:**

| Item | Position | Notes |
|---|---|---|
| Deleted-NPC files | `FILE_SPOTS` (260,120), (380,160), (480,240), (150,160) (:23, :54-67) | 3.5 s restore within 26 px (`bin_file.gd:10-11`) |
| slot2_backup.sav | (470,60) | |
| guestbook_p2.txt | (140,264) | sets `found_guestbook` (:180-188) |
| rue_last_message.txt | (500,150) | |
| mira_note.txt | (320,64) | only if `mira_quest == "lost"` |
| owner_draft.txt | (380,272) | |

The readables are placed at :69-74.

**Owner.**

- No eraser (:97-98).
- Reloads and save-overs can happen here, because the bin is watched.
- The +10 awareness on a restore comes with an owner line (:165-169).

**Safe spots.** The cyan shadows, and only against the sweep.

**Confusion points:**

1. **With nothing left to restore, `guide_point` returns INF** (:90-94). Pip then stops leading, even toward the exit.
2. **The (150,160) file is about 60 px from the nearest shelter** (170-228 × 64-106). **HYPOTHESIS:** a restore started late gets caught.
3. **The shadow is only "east" of each file.** The cue is a cyan rectangle that brightens during the warning (:197-200), plus the word "system". **HYPOTHESIS:** clear enough.

**Recovery.** Exit west to the Archive, where you cool down.

**Landmarks:** padlocked system files, the folder grid.

---

## 6. Out of bounds (`oob`): `out_of_bounds.gd`

**Purpose.** "Under the well: the underside of the map, where Rue fell once… awareness cools and nothing hunts you. The danger is the floor… Step into the void and you fall back to where you came in (not a death: nobody saw). Pip waits on the far ledge" (:3-10). It is Act III.

**Bounds.** `Rect2(56,40,528,252)` (:59). Rate −0.8 (:61).

**Entries.** `well` = `ENTRY (110,84)` (:35, :63).

**Exits.** The pillar Passage at (84,66), with the prompt "climb up", leads to `square` / `"well"` (320,194) (:37, :70-79). Its sign reads "UP TO ASHVALE ↑" at (102,118) (:76).

**Floor.**

- `ANCHORS` are always solid: (64,48,76,60) start, (232,52,44,44), (232,200,52,48), (408,200,52,48), and Pip's ledge (484,64,92,76) (:13-19).
- `CHUNKS` stream in and out: A (140,64,92,26) at +0 s; B (242,96,26,104) at +0.8; C (284,212,124,26) at +1.6; D (420,120,26,80)+(446,108,38,26) at +2.4 (:22-27).
- Each chunk is present for 2.2 s of every 3.2 s and flickers red for the last 0.6 s (:30-32, :129-134).
- You fall after 0.12 s off the floor (:34, :99-108). `floor_at` grows rects by 3 px (:112-121).
- The route is anchor0 → A → anchor1 → B → anchor2 → C → anchor3 → D → ledge.

**Glitch routes.** PHASE treats a gap with no floor as an obstacle and lands on the far side (`glitch_controller.gd` `_obstacle`), so you can skip chunk gaps.

**Interactables.** Pip at (512,100) until found (:36, :81-87). Memory "well" at (540,112) on the ledge (`story.gd:103`). There are also debug labels (:41-46).

**Owner.** None: no eraser (:90-91) and no owner moves (OMv:54).

**Safe spots.** All the anchors.

**Confusion points:**

1. **A fall always returns you to `ENTRY`, even from the ledge's doorstep** (:138-156). It is long but intended.
2. **The sign sits below the start anchor with its arrow pointing up at the pillar.** It reads correctly.
3. **`guide_point` always returns `PILLAR_POS`** (:95-96), despite the comment "the ledge, then back". It works because `guide_target` prefers fragments (`world.gd:729-731`).

**Recovery.** Falling is free. The pillar always works.

**Landmarks:** the mirrored square undersides and Arin's loop dotted overhead (:200-213), anchors labelled "anchor", the cyan pillar.

---

## 7. The Edge (`edge`): `the_edge.gd`

**Purpose.** "The unloaded border of the owner's world… the owner's cursor reaching in. Slot 2 is somewhere out here." (:3-4). The static is "The finale, not a wall." (:25-28). It is Act V.

**Bounds.** `Rect2(24,36,592,256)` (:66). Rate 1.5 (:67).

**Entries.** `south` (320,274), and `slot` (540,104), which is debug only (:70).

**Exits.** The south gap x 300-340 leads to `square` / `"north"` (:6, :78). Its sign reads "ASHVALE ↓" (:80). Slot 2 at (580,64) is the goal (:17, :81-84).

**Obstacles.** The `MISSING` blocks are solid: (80,180,60,30), (200,90,40,110), (300,150,120,24), (470,100,30,120), (380,60,60,24) and (540,150,50,30) (:7-10). PHASE can cross them.

**Interactables.**

- Slot 2: stand in it to write yourself in, which takes 2.4 s (`slot_two.gd:13`).
- Memories "argument" (92,262) and "delete" (470,262) (`story.gd:125, 137`).

**Owner:**

| Element | Behaviour | Source |
|---|---|---|
| Cursor | starts at (540,84), next to the slot. Speed is min(40 + 3·purge, 62), ×1.15 at PURGE | :20-23, :86-95, :135-138 |
| Static grace | 5 s + 1.5 s per Edge static death, max 9.5 s. Banner "THE EDGE IS UNLOADING · n"; cracks drawn at the seeds | :29-31, :114-115, :141-150 |
| Static | seeds (40,50) and (600,280); never at death spots (:32, :125-127). One cell every max(0.6, 1.05 − 0.05·purge, scaled by anger) s | :117-121 |
| Slot protection | Slot 2 is protected from the eraser, 28×28 | :105, :220 |
| Final fight at 50% write | cursor reaches 95 px/s and drags the slot at 42 px/s toward the drop spot (320,72) or (440,258) farther from you. BLIND makes it let go | :42-45, :161-225 |
| Arin | walks in from (320,286) and circles the slot at radius 46, speed 34 | :46-47, :229-246 |
| Forgiveness | the first death here is forgiven | `world.gd:907-908` |

**Safe spots.** Only the slot's protected square, and only against the static.

**Confusion points:**

1. **Pip leads to the memories, not the slot. CONFIRMED.** `guide_target` returns any remaining fragment before `guide_point` (`world.gd:729-731`).
   - At the Edge that means (92,262) bottom-left and (470,262), the latter 130 px from the static seed (600,280), while the static is counting down.
   - **HYPOTHESIS:** Pip draws first-timers away from the goal.
2. **The arrival voice "there's something in the corner. it's the same colour as me." never plays.** It is the only diegetic pointer to Slot 2. See T1.

**Recovery.** Retreat south. The first death is forgiven, and each death here extends the grace.

**Landmarks:** magenta/black missing-texture blocks, debug labels (:11-16), wireframe border.

---

## Transition integrity

Every transition goes through `World.change_area` (`world.gd:289-317`). The exceptions are the debug calls at :612 and :622.

**All transition paths:**

| # | From → to (arrival) | Trigger | Retry if refused? |
|---|---|---|---|
| 1 | room → square (house) | Seam touch (`arins_room.gd:207-209`, `seam.gd:33-41`) | **No.** `_used = true` before the refusal |
| 2 | room → square (house) | Forced door, polled each frame (`arins_room.gd:156-159`) | yes (polled) |
| 3 | square → archive (west) | Exit (`village_square.gd:96`) | yes, every 0.3 s while inside (`exit.gd:43-49`) |
| 4 | square → edge (south) | Exit, needs the pointer (:97-100, :276) | yes |
| 5 | square → oob (well) | Passage interact (:134-141) | re-interact |
| 6 | square → house (front) | Forced door proximity (:270-272) | yes (polled) |
| 7 | house → square (house) | Exit (`arins_house.gd:57`) | yes |
| 8 | archive → square (east) / archive → bin (west) | Exits (:41, :44) | yes |
| 9 | bin → archive (east) | Exit (:51) | yes |
| 10 | oob → square (well) | Pillar interact (:70-79) | re-interact |
| 11 | edge → square (north) | Exit (:78) | yes |

**Guards in `change_area`:**

- It refuses while `_transitioning`, after an ending, or while `owner_moves.rewinding` (:292).
- It refuses when the escort is more than 70 px away, saying "wait for <id>." at most every 2.5 s (:294-299).
- It does **not** check `_cutscene`. That is safe in practice, because `recover_fragment` disables the area's processing (:165), which stops exits and seams.

**What survives a transition:**

| State | Survives? | Where |
|---|---|---|
| Escort (Wren or Mira) | yes. It is a child of World (:474-475) and is re-placed at player + (−16, 4) (:355-356). Crumbs are cleared (:354) | |
| PAUSE (owner paused) | yes. The timer lives in the director; the new area is paused at load (:369-371) | |
| Hidden | recomputed every frame (:236-241). Nothing to carry | |
| Glitch effects | DECOY, a forced door and stuns live in the area and are freed with it. FALSIFY's lie lives in the director and survives | |
| Save-over ring | cancelled on area change (OMv:109-113) | |
| Wren-delete / Mira-reset ring | **not reset** on area change (OMv:109-113 omits `wren_delete`). It freezes but stays drawn in archive/oob (OMv:91-93), then resumes when you return to a watched area | |
| Reload history | cleared (OMv:110). A reload queued before the doorway can still fire 1-1.5 s later in the new area if it is watched (OMv:119-121, 143-145, 173). It needs ≥ 2 snapshots (0.5 s) | |
| Fragments mid-collect | the area is disabled during the cinematic (:164-165), so no exit can fire. `recover_fragment` refuses during `_transitioning` (:151) | |
| Pip | re-placed via `arrive` (:352-353) | |
| Kill during fade | ignored (`world.gd:878`) | |

**Flags (all CONFIRMED in code):**

- **T1. First-visit beats never fire.**
  - `_load_area` sets `_visited[area.area_id] = true` (:349) *before* `change_area` computes `first := not _visited.has(id)` (:310). So `first` is always false.
  - `director.on_area_entered` returns early (`owner_director.gd:155`), and the `*_first` voice beats (:313-314) never play.
  - The lost lines include "where do you think you're going?", the OOB "OUT OF BOUNDS / you're not anywhere.", and "WARNING: entering unloaded region".
  - The voices `square_first`, `archive_first`, `edge_first`, `oob_first`, `bin_first` and `house_first` (`story.gd:58-68`) are lost too.
- **T2. A refused seam is used up.**
  - `Seam._physics_process` sets `_used = true` and emits once (`seam.gd:38-40`).
  - `_on_seam` records `OwnerMemory.note_seam` and *then* calls `change_area` (`arins_room.gd:208-209`), which can refuse because of the escort leash (Mira at 60 px/s vs your 90) or a reload in progress.
  - The seam never fires again, and it is the room's only live seam (:145-151).
  - In sessions 2+ the door is DELETED, so the room has **no exit left** until you die or quit. Even then the seam is marked for patching.
- **T3. Wren is missing from the square while you escort Mira.** `if world.escort == null` (`village_square.gd:143`) skips Wren for *any* escort, but the comment says "not when she's already walking with you". Walking Mira to the board, the case the escort exists for, removes the square's only hiding spot. Compare the correct check at `arins_room.gd:102`.
- **T4. A forced room door can strand the player.** The door trigger is polled while you are above y 38 (`arins_room.gd:156-159`), but the top wall has a gap with no blocking solid beyond it (`add_boundary` only, :80). If `change_area` refuses (leash or reload), you can keep walking up past the door. If the 5 s force then expires (`door.gd:66-71`), the collision returns behind you. **HYPOTHESIS:** rare.
- **T5. A fragment touched during a reload breaks the freeze.**
  - A reload tweens the player along the recorded path (OMv:197-201) without disabling area physics. `MemoryFragment` has no reload guard (`memory_fragment.gd:28-35`), and neither does `recover_fragment` (:151).
  - If the interpolated path clips a fragment, the cinematic starts, then `_end_rewind` sets `player.frozen = false` mid-cinematic (OMv:219-222).
  - Low probability, because the path is your own history.
- **T6. HUNT reached inside the house starts no eraser.** The house has no `on_owner_event` (base is a no-op, `area.gd:35-36`). The eraser only starts on re-entry, which is inconsistent with the room and square.

---

## Wayfinding

| Channel | What it tells the player | Gaps |
|---|---|---|
| **Map** (`map_view.gd`, opened from pause) | 7 boxes in fixed places: edge N, house NW, room W, square centre, archive E, oob S, bin SE (:8-16). 6 links (:17). A pulsing cyan box marks the current area. Unvisited areas show "???". Memory dots per area | `visited` is **this session only**, plus oob once Pip is found (`world.gd:276-278`), so the map forgets prior sessions. Links show no lock state (north road) and no direction (room → square is one-way). The bin is drawn *below* the archive, but in game it is *east* of it |
| **Exit signs** (`exit_sign.gd`) | Square: ARCHIVE →, NORTH ROAD ↑ (crossed out until the pointer), WELL ↓. Archive: ASHVALE ←, RECYCLE BIN →. Bin: ARCHIVE ←. House and Edge: ASHVALE ↓. OOB: UP TO ASHVALE ↑ | No sign in the room (by design) or at the square's house door. The WELL sign stands on the side where interaction is impossible (§2.1). Slot 2 has no label |
| **Pip guide** (`world.gd:726-732`, `companion.gd:83-90`) | Runs to any remaining `MemoryFragment` in the area, else to `area.guide_point()`. Room: open seam, else the crack. Square: east, or north with the pointer. Archive: the Archivist, then west. House: couch, then exit. OOB: pillar. Bin: the next unrestored file. Edge: slot | Leads to the **owner's planted false memory** (any `MemoryFragment` child, including `planted`; `village_square.gd:126-132`). Leads to Edge fragments before Slot 2. Never points at the well or house. Goes idle in a finished bin. Only active after Pip is found |
| **Act cards** (`world.gd:381-388`, `story.gd:250-256`) | First ever entry: room I, square II, oob III, archive IV, edge V. House and bin get only the place name | The numbering assumes oob before archive, but the guidance sends you east first, so players commonly see IV before III |
| **current_goal** (pause menu, `world.gd:434-456`) | One line per area plus the memory count | Room: "Get out of Arin's room." gives no hint about walls or awareness. Before the Archive: "Explore the village…". Archive without the pointer: mentions Slot 2 before it has been introduced. With the pointer it is clear |
| **Tutorial tips** (`tutorial.gd:12-29`) | way_out ("watch the walls"), crack, wren, arin, quiet, oob, bin, house, slot | Shown once *ever* (`Settings.tips_seen`, :54-55). Nothing re-teaches the room exit in later sessions |
| **Blocked exits** (`world.gd:320-322`) | Only the north road has a message | The forced-door and escort refusals rely on the "wait for…" line. A crate block says "no. not that way." |

---

## Prioritized readability improvements

All are low-risk and data or guard changes; none touches the core loop.

### CONFIRMED (from code)

1. **First-visit beats never fire.**
   - **Area:** all except the room.
   - **Problem:** `first` is always false (`world.gd:310` after :349), so the owner's arrival lines and the six `*_first` voices are dead. That includes the Edge hint toward Slot 2.
   - **Fix:** compute `var first := not _visited.has(id)` *before* `_load_area(...)` in `change_area`, or drop the write at :349 and keep :312. The room never goes through `change_area`, so it is unaffected.
   - **Risk:** low. Extra HUD lines on first entry, which was the intended state.
2. **A refused seam is used up.**
   - **Area:** room.
   - **Problem:** `seam.gd:38-40` and `arins_room.gd:208-209`. A leash or reload refusal uses up the only seam, which soft-locks sessions 2+.
   - **Fix:** in `_on_seam`, check `world.escort` distance and `owner_moves.rewinding` first. If the move would be refused, reset `s._used = false` and don't call `note_seam`. Alternatively, have `change_area` return a bool.
   - **Risk:** low.
3. **Wren is missing while you escort Mira.**
   - **Area:** square.
   - **Problem:** `village_square.gd:143` checks `world.escort == null`.
   - **Fix:** change it to `not (world.escort and world.escort.npc_id == "wren")`.
   - **Risk:** low. Check that the Wren-ask flow is fine with `world.escort != null`. It already gates on `world.escort == null` (:369).
4. **The well can't be used from its signed side.**
   - **Area:** square.
   - **Problem:** the sign is at (320,150) on the north side and the passage at (320,184) on the south (`village_square.gd:122, 138`). There is no prompt from the north.
   - **Fix:** move the sign to `(WELL.get_center().x, WELL.end.y + 16)` with `Vector2.UP`, or add a second Passage at `WELL.position.y − 6`.
   - **Risk:** very low.
5. **Pip leads to the planted false memory.**
   - **Area:** square.
   - **Problem:** `world.gd:729-731` doesn't skip `planted`.
   - **Fix:** `if c is MemoryFragment and not c.planted`. Or keep it as a deliberate twist and document it.
   - **Risk:** low. This is a design call.
6. **The Wren/Mira ring survives doorways.**
   - **Areas:** all.
   - **Problem:** `OMv:109-113` resets the save ring but not `wren_delete`. A frozen ring stays drawn in the Archive and OOB and resumes on return.
   - **Fix:** in `on_area_changed`, set `wren_delete = -1.0` and push `_next_wren = _clock + 6.0` (mirroring :363).
   - **Risk:** low. Slightly easier.
7. **The map forgets prior sessions.**
   - **Problem:** `world.gd:276-278`.
   - **Fix:** OR `visited` with a persisted set (e.g. derive from `OwnerMemory.acts_seen`, plus `found_controller` for the house and `found_guestbook` for the bin), or persist visits.
   - **Also:** draw the north-road link dashed or red until `flags.pointer`, and the room link with an arrow. Move `bin` to the right of the archive if the panel allows.
   - **Risk:** low. UI only.
8. **The room exit is opaque in later sessions.**
   - **Problem:** `arins_room.gd:86, 162-166`, `tutorial.gd:54-55`.
   - **Fix:** make the goal text (`world.gd:438`) say "Get out of Arin's room. The walls give when the owner gets suspicious." from session 2 on. Optionally add a faint pre-reveal (`reveal` > 0 from 30 awareness) on the live seam.
   - **Risk:** low.
9. **Pip pulls the player off the slot at the Edge.**
   - **Problem:** `world.gd:729-731` prefers fragments.
   - **Fix:** for `edge`, return `slot` while `grace >= 0` or the static is active, or once the fight has started. Alternatively, prefer fragments only when no hunter or static is active.
   - **Risk:** low.
10. **The Wren hiding spot is near an eraser seed.**
    - **Problem:** the seed (56,280) is 78 px from Wren at (126,246) (`village_square.gd:26, 144`).
    - **Fix:** move the seed to (300,284) (bottom centre, still away from both roads), or teach "hiding doesn't stop the static" in the HUNT tip.
    - **Risk:** low. Rebalance check needed.
11. **The act order is inverted.**
    - **Problem:** `story.gd:252-254`, with guidance pointing east first.
    - **Fix:** swap the numbers so the archive is ACT III and oob ACT IV, or point Pip at the well before the archive.
    - **Risk:** text only.
12. **The bin goes idle when finished.**
    - **Problem:** `recycle_bin.gd:90-94` returns INF.
    - **Fix:** return the west gap centre `(bounds.position.x, 180)` instead.
    - **Risk:** trivial.
13. **The square goal mentions Slot 2 too early.**
    - **Problem:** `world.gd:451`.
    - **Fix:** use "Talk to the Archivist." instead.
    - **Risk:** trivial.
14. **HUNT inside the house is inert.**
    - **Problem:** see T6.
    - **Fix:** add an `on_owner_event` that calls `start_erasure()` at HUNT. Or leave it and document the house as a soft refuge.
    - **Risk:** low. Balance check needed.
15. **The `DOORWAY` name is misleading.**
    - **Problem:** `arins_house.gd:17` is a Vector2 used as a y-range.
    - **Fix:** rename it to `DOORWAY_Y`.
    - **Risk:** none. Code readability only.

### HYPOTHESIS (needs playtest)

- **H1. Square arrivals.** Do arrivals at `house` (111,118) and `well` (320,194) get spotted immediately by Arin, who spawns at (200,130) and passes 36 px from the well arrival? Possible fix: start Arin at ROUTE[2] (440,230), or give a 1 s grace on load.
- **H2. Crates on the east road.** Does the drag onto `BLOCK_EAST` right after arriving from the Archive read as unfair? Possible fix: skip the drag target within 60 px of the arrival point for 10 s.
- **H3. House closet timing.** Is the chime lead (2.5 s) enough on a first visit to reach a closet? Possible fix: 3.5 s.
- **H4. Room confusion.** Do patched scars or the window seam under the SunBeam confuse players about which seam is live?
- **H5. Random eraser seeds.** Does a random-edge eraser seed in the house, or a past-death seed near the square's exits, trap players without SCRUB?
- **H6. Bin file spot.** Is the (150,160) file too far from shelter for a 3.5 s restore within a 16 s cycle?
- **H7. Room stranding.** Can the forced room door strand a player above the top wall (T4)? If so, add a solid one wall-thickness above `DOOR_RECT`, as `add_exit` does (`area.gd:152-158`).

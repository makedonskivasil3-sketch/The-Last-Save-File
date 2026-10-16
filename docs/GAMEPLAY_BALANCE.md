# Gameplay Balance & Fairness Audit

> **Status (2026-10-16):**
> - **Fixed:**
>   - PHASE now clears the dragged crates (62 px reach for the prop only).
>   - Reading and modal questions are safe.
>   - One-off awareness jumps show "+N · why" (`OwnerDirector.notice`).
>   - The owner warns one glitch before a reload.
> - **Unchanged on purpose:** every balance value, the purge limit (6), and the ending conditions.
> - **Still an author decision:** whether closing a browser tab counts as a quit (unverified behaviour).

Static read of the GDScript only. Godot was not run, so every number below comes from the source and
every timing is derived from constants. All `file:line` references use bare filenames, which are unique
in `scripts/` (for example `owner_director.gd` is `scripts/owner/owner_director.gd`).
Player speed is 90 px/s (`player.gd:37`). Collider is 8x8 at offset (0,2) (`scenes/player.tscn`).

Status tags used below:
- **CONFIRMED**: follows directly from the code.
- **ARITH**: follows from the constants by arithmetic. Should still be checked in the engine.
- **HYPOTHESIS**: needs a playtest.
- **UNVERIFIED**: depends on engine or browser behaviour that the code does not settle.

---

## 1. Awareness

### 1.1 Thresholds (`owner_director.gd:8-14`)

| Value | Name | What happens (`_check_thresholds`, `owner_director.gd:173-193`) |
|---|---|---|
| 25 | NOTICE | Owner line. Room note rewritten (`arins_room.gd:179-180`). Square board becomes "MISSING" (`village_square.gd:208-210`). From here, the 3rd glitch can trigger a reload (`owner_moves.gd:141-142`) |
| 40 | SUSPECT | Lights flicker (`owner_director.gd:184-185`). Room seam opens (`arins_room.gd:165`). Square Arin speed x1.25 (`village_square.gd:211-212`). Idle save-over is armed (`owner_moves.gd:314`). Wren delete becomes possible (`owner_moves.gd:360`) |
| 50 | CONTAIN | Room door locks (`arins_room.gd:181-185`). Square Arin view +20 px (`village_square.gd:213-214`) |
| 65 | SILENCE | Mira deleted (`arins_room.gd:186-192`). Wren deleted if she hid you (`village_square.gd:215-220`). One reload 1.5 s later (`owner_moves.gd:117-121`) |
| 75 | HUNT | "RUNNING: erase_unknown_entity()" (`owner_director.gd:186-187`). Eraser starts. Square cursor spawns (`village_square.gd:297-310`). First save-over 3 s later, then every 35 s (`owner_moves.gd:122-123`, `:35`) |
| 100 | PURGE | Base glitch FX. Eraser interval halved (`owner_director.gd:188-191`). Square cursor x1.2 (`village_square.gd:223-225`). Edge cursor x1.15, capped at 62 (`the_edge.gd:135-138`) |

Every crossing plays a stinger, jolts the meter, startles Rue and shows an owner line (`owner_director.gd:178-183`).

Full awareness (100) has no kill attached to it.

**CONFIRMED readability gap.** The meter draws tick marks at only 3 of the 6 thresholds: NOTICE, CONTAIN and HUNT (`awareness_meter.gd:17`, `:104-106`). SUSPECT (the seam opens, idle save-over is armed) and SILENCE (Mira or Wren is deleted, a reload happens) have no tick.

The stage *label* under the bar does name all six (`awareness_meter.gd:19-22`). The tutorial says "Each tick is a new reaction" (`tutorial.gd:14`), which is not accurate.

### 1.2 Passive rate

`rate = (BASE_RATE 0.35 + RATE_PER_PURGE 0.15 x purge) x area.awareness_rate` (`owner_director.gd:17,19,116`)

Modifiers, applied in this order:
1. FALSIFY lie: x0.35 (`:117-118`).
2. Escort: x1.4 (`:119-120`).
3. Hidden: the rate is replaced by -2.0/s (`:121-122`).

Negative rates cool awareness down to `floor_level()` (`:123-124`, `:135-142`). The rate is frozen while the director is paused for story beats (`:108`) or while the owner is PAUSEd (`:110-114`).

| Area | Multiplier | Rate at purge 0 | Rate at purge 5 | Source |
|---|---|---|---|---|
| Arin's room | 3.0 | 1.05/s | 3.30/s | `arins_room.gd:68` |
| Village square | 1.0 | 0.35/s | 1.10/s | `village_square.gd:74` |
| Arin's house | 1.1 | 0.385/s | 1.21/s | `arins_house.gd:44` |
| Recycle bin | 1.2 | 0.42/s | 1.32/s | `recycle_bin.gd:41` |
| The Edge | 1.5 | 0.525/s | 1.65/s | `the_edge.gd:67` |
| Archive | -0.6 | -0.21/s (cools) | -0.66/s | `archive.gd:30` |
| Out of bounds | -0.8 | -0.28/s (cools) | -0.88/s | `out_of_bounds.gd:61` |

### 1.3 Every gain source

The "+N" fly-up is `hud.glitch_cost()` (`hud.gd:567-575`). Only `glitch_controller.gd:262` calls it.

| Source | Amount | file:line | Feedback? | What feedback |
|---|---|---|---|---|
| Passive, per area | table above | `owner_director.gd:116-126` | Partial | Meter fills. Tutorial "watched" tip, first session only (`tutorial.gd:14`). No area tells you its multiplier |
| Glitch fired | 4 to 20 (see section 2) | `glitch_controller.gd:259-261` | **Yes** | Price shown before charging ("PHASE +8", `:301`). Ghost preview on the meter (`hud.gd:559`). "+N" fly-up, shake, buzz |
| Idle 6 s in the open, once per session | +5 | `owner_director.gd:128-131` (IDLE_WARN `:30-31`) | Yes | "you stopped moving. i noticed that too." |
| Approaching the open room door (session 1 only) | Jumps to 52 (fires NOTICE, SUSPECT and CONTAIN) | `owner_director.gd:146-151`, trigger `arins_room.gd:160-161` (70 px) | Weak | "nope." No tell beforehand: the door is the obvious exit |
| Arin sees you (square) | 22/s, after 0.35 s of continuous sight | `village_square.gd:21-23,313-321` | Yes | Bright cone, "!" bubble (`owner_avatar.gd` `_draw`), "spotted" sfx and a landmark line the first time |
| Arin sees you (house) | 20/s, no grace | `arins_house.gd:114-116` | Yes | Cone and "!". No "spotted" line. Grace is inconsistent with the square |
| Arin sees you (Edge) | 12/s, no grace | `the_edge.gd:241-243` | Yes | Cone and "!" |
| Arin sees your escort (square) | 8/s | `village_square.gd:274-275` | **No** | Nothing specific |
| Escort following you | Passive x1.4 | `owner_director.gd:119-120` | **No** | Not explained |
| Mira out of her room | +2.5/s | `world.gd:502-504` | Weak | "mira? what is mira doing out of her room." when she joins (`world.gd:486`) |
| Memory recovered | +6 | `world.gd:206` | No | The meter only moves |
| False memory taken | +20, then a save-over starts | `world.gd:222-223` | Yes | "MEMORY REJECTED", owner line, save ring |
| Talking to Mira | **+8 every talk** | `arins_room.gd:112`, applied `world.gd:866-868` | **No** | The prompt just says "talk" (`npc.gd:138-139`). Asking her to come along costs 3 or more talks, so 24+ |
| Room note read | +4 | `arins_room.gd:198-199` | No | |
| Room save point used | +15 | `arins_room.gd:200-204` | Partial | "don't touch that." only if awareness is already >= 25. The prompt says "save" (`save_point.gd:26-27`) |
| House TV | +4 | `arins_house.gd:123` | No | |
| House couch (controller) | +10 | `arins_house.gd:143-146` | Yes | "...don't touch that." 1 s later |
| Tobben talk reports you | +12, 4 s later | `village_square.gd:415-427` | Late | "tobben says you were asking questions." Skipped if a lie is believed (`:422-425`) |
| Mira's note pinned (carried) | +5 | `village_square.gd:237` | Yes | Owner line |
| Mira pins her note (escort) | +5 | `world.gd:535` | Yes | Owner line |
| Bin restore completes | +10 | `recycle_bin.gd:165-168` | Yes | Owner line |
| Debug drag (F8) | Jumps to 76 | `world.gd:614-615` | n/a | Debug only |

### 1.4 Every reduction

**Hiding.** The rate becomes -2.0/s (`owner_director.gd:27,121-122`).

Hiding sources:
- **Wren**, `hide_radius` 22 (`village_square.gd:352`, `npc.gd:130-131`). Set to 0 while she escorts you (`world.gd:479`).
- **The house closets** (`arins_house.gd:19,74-78`).

Nothing else hides you. The Edge, the room and the bin have no hiding spot. The HUD shows "HIDDEN · WREN covers you" (`world.gd:236-241`).

**Quiet areas.** Archive -0.6x and out of bounds -0.8x (table above). Cooling is purge-scaled, so it gets *faster* at high purge.

**The FALSIFY lie.** Not a reduction: it slows gain to x0.35 for 15 s (`owner_director.gd:40,117-118`, `glitch.gd:46`).

**The floor rule.** `floor_level()` is the highest threshold already fired (`owner_director.gd:85-90`). `_cool` never goes below it (`:135-139`). Thresholds already passed at session start count as fired (`:51-56`).

**CONFIRMED consequence.** You leave Arin's room in one of two ways:
- Through the seam, which only opens at >= 40 (`arins_room.gd:165`).
- In session 1, through the door, which jumps you to 52.

From session 2 on the door is DELETED (`arins_room.gd:86`), so the seam is the only way out. Every run therefore leaves the room with a floor of at least 40.

For the rest of the run, hiding and the Archive can only shave off the gap above the last threshold: 10 to 25 points. The tutorial "quiet" tip says this honestly (`tutorial.gd:21`).

### 1.5 Session start awareness (purge)

`awareness = min(purge x 10, 35)` (`owner_director.gd:22-23,51`):
- purge 0: 0
- purge 1: 10
- purge 2: 20
- purge 3: 30 (NOTICE already fired, so the floor is 25)
- purge 4 and 5: 35

**ARITH: the room timer.** At purge 5 the room rate is 3.3/s:
- SUSPECT in 1.5 s.
- SILENCE (Mira deleted, reload) in about 9 s.
- HUNT in about 12 s. The +8 PHASE needed for the room memory makes it sooner.

At purge 0, HUNT in the room is about 71 s away. **HYPOTHESIS:** at purge 4-5 the room becomes a ~10 s sprint.

---

## 2. The nine glitches (`glitch.gd:19-38`)

**Input** (`glitch_controller.gd:17-18,64-99`):
- Holding [E] starts charging after `HOLD_START` 0.22 s.
- Charging takes `hold` seconds.
- So time-to-fire = 0.22 + hold.
- Cooldown is 0.6 s after a fire or a fizzle.
- Releasing before any charge counts as a tap (interact).
- Releasing mid-charge cancels **silently**: the loop sound stops, with no "cancelled" cue (`:76-79`, `:102-107`).

**Targeting** (`find_target`, `:118-164`):
1. The best `distance / range` score among Arin, NPCs, deleted NPCs, notes, a locked door, the cursor and the nearest erased cell.
2. Otherwise PHASE, if a wall is within 9 px in front of you.
3. Otherwise DECOY, if you are moving.
4. Otherwise PAUSE, if you are still.

There is no input to cycle targets. **HYPOTHESIS:** under pressure the wrong glitch can be chosen. For example, a note at 15 px (15/34 = 0.44) beats the cursor at 45 px (45/90 = 0.5), so you get FALSIFY instead of BLIND. The prompt does show the chosen glitch before you hold (`:297-301`).

**Generic failures:**
- `can_act()` false (dialogue, cutscene, frozen, menu) cancels the charge (`:57-62`, `world.gd:656-658`).
- The target leaves 1.4 x range (minimum 56 px) or is freed mid-charge: fizzle with a "denied" sfx and the cooldown (`:89-91,110-113,167-174`).

**Generic costs:**
- Awareness.
- The 1st use of each glitch per session gets an owner line 0.7 s later (`:273-275`, lines at `glitch.gd:51-61`).
- Escalation lines on the 3rd, 6th, 10th and 15th glitch (`story.gd:717-722`).
- Each glitch counts toward a reload (`owner_moves.gd:140-145`).

**Reload undo** (`owner_moves.gd:283-301`) clears:
- Arin stun, cursor blind, a forced-open door, falsified notes, NPC freeze, the decoy, the lie.

It does **not** undo:
- PHASE (position is rewound anyway), SCRUB (erased cells stay gone), RESTORE (persisted), PAUSE (a reload cannot fire while paused, `owner_moves.gd:173-174`).

Awareness is never refunded.

**Unlock order.** Unlock needs N recovered fragments (`glitch.gd:64-65`). There are 5 fragments:
- room, oob, archive (`story.gd:89-125`)
- two at the Edge (`story.gd:125,137`)

So BLIND is usually unlocked only after the Archive, RESTORE at the Edge, and PAUSE only once you hold all five.

| id | Purpose | Time to fire | Target, range | Cost | Duration | Failure, feedback | Owner counterplay | Temp/perm | Unlock | Interactions | Tests |
|---|---|---|---|---|---|---|---|---|---|---|---|
| PHASE | Pass through a thin wall | 0.67 s | Wall within 9 px ahead (`glitch_controller.gd:22,183`). Lands 12-46 px away, inside bounds-5, on floor (`:179-193`, `glitch.gd:48`) | 8 | Instant | No landing at fire time: fizzle (`:217-220`). Not offered if no landing exists | Reload rewinds position | Perm (position) | 0 | Only way into the room memory nook (`arins_room.gd:25-27`). **Cannot cross the dragged crates** (section 3) | `test_glitch.gd:52`, `test_fairness.gd:71` |
| FREEZE | Stop Arin or an NPC | 0.62 s | Arin 70 px (`glitch.gd:22`). Other NPCs **40 px**, hard-coded (`glitch_controller.gd:132`), not the 70 in DEFS | 6 | 2 s (`glitch.gd:41`) | Range fizzle | Undone by reload (`owner_moves.gd:287,297-298`) | Temp | 0 | A stunned Arin cannot see or touch (`owner_avatar.gd:56-59,90-91`). Freezing a plain NPC (e.g. Tobben) does nothing useful | `test_glitch.gd:11` |
| FALSIFY | Make a note lie, so the owner relaxes | 0.62 s | Unfalsified note, 34 px | 4 | Lie 15 s at x0.35 rate (`glitch.gd:46`, `owner_director.gd:40`). The note text stays false until reload | Range fizzle | Undone by reload (`owner_moves.gd:295-296,301`). Blocks owner rewrites (`note.gd:61-63`) | Temp | 0 | Cancels Tobben's +12 report (`village_square.gd:422-425`). Cheapest save-breaker (if a note is in range) | `test_glitch.gd:28` |
| UNLOCK | Open a locked door | 0.77 s | LOCKED door, 44 px | 10 | 5 s (`glitch.gd:42`) | Range fizzle | Undone by reload (`owner_moves.gd:291-293`) | Temp | 0 | Session-1 room door (only after CONTAIN) and the square's front door to the house. From session 2 the room door is DELETED, so it cannot be targeted (`arins_room.gd:86`, `glitch_controller.gd:138`). **As the 3rd glitch, the reload 1 s later relocks the door** | `test_glitch.gd:39`, `test_house.gd:19` |
| DECOY | Leave a frame to lure Arin and the cursor | 0.57 s | Self, moving > 10 px/s (`glitch_controller.gd:159-161`) | 7 | 4 s (`glitch.gd:43`) | Only offered when nothing else is targetable | Popped when a hunter gets within 9 px (`world.gd:695-701`). Arin follows it only within 200 px (`owner_avatar.gd:63`) | Temp | 1 | Cursor ignores you while it exists (`owner_cursor.gd:116-119`). Undone by reload | `test_glitch.gd:73` |
| SCRUB | Erase void back to floor | 0.72 s | Nearest erased cell within 40 px | 9 | Permanent, radius 28 (`glitch_controller.gd:240`) | Range fizzle | Eraser regrows | Perm (until regrowth) | 2 | Wins targeting near the void (it may pre-empt BLIND) | `test_glitch.gd:117` |
| BLIND | Cursor can't see you | 0.67 s | Unblinded cursor, 90 px | 10 | 3 s (`glitch.gd:44`) | Range fizzle | Undone by reload (`owner_moves.gd:290`) | Temp | 3 | Edge fight: the cursor can't reach the slot and drops it if dragging (`the_edge.gd:178-180,195-196`). Resets selection (`owner_cursor.gd:98-100`) | `test_glitch.gd:117`, `test_confrontation.gd:25` |
| RESTORE | Undelete a person | 1.42 s | DELETED NPC, 34 px | 20 | Permanent (`world.gd:798-804`, `owner_memory.gd:173-176`) | Range fizzle | Owner can delete again (Wren at SILENCE if she hid you) | Perm | 4 | Removes them from `npc_fates`. Mira also clears the purge>=3 auto-delete (`world.gd:794`) | `test_glitch.gd:102`, `test_bin.gd:22` |
| PAUSE | Freeze the owner's world | 1.02 s | Self, standing still, owner not already paused (`glitch_controller.gd:162-163`) | 15 | 6 s (`glitch.gd:45`) | Facing a wall offers PHASE instead (PHASE is checked first) | None while it lasts. Awareness from glitches still applies (`owner_director.gd:97-100` has no pause check) | Temp | 5 | Stops Arin, cursor, eraser (`area.gd:51-56`), bin (`recycle_bin.gd:101-111`), house visits (`arins_house.gd:82-85`), all owner moves (`owner_moves.gd:81-82`). Carries through doorways (`world.gd:369-371`). Banner "‖ OWNER PAUSED" | `test_glitch.gd:87`, `test_bin.gd:80`, `test_owner_fixes.gd:59` |

Shared tests: unlock order `test_glitch.gd:63`; price preview `test_fairness.gd:89`; reload `test_owner_moves.gd:24`; save interrupt `test_owner_moves.gd:45`.

**Glitches inside quiet areas.** Glitches in the Archive or out of bounds still cost awareness and still increment the reload counter. The reload itself waits until the owner can see you again (`owner_moves.gd:140-145,173-174`).

---

## 3. Owner attacks

Every row is described in the same order:
- **a. Tell:** the warning before the attack.
- **b. Target:** how readable the target is.
- **c. Window:** the reaction window.
- **d. Attack:** what happens.
- **e. Feedback:** how the result is shown.
- **f. Recovery:** what you can do afterwards.

Flag: ⚠ = no tell, or a tell shorter than ~0.5 s.

### Cursor click / select (`owner_cursor.gd`)
- **a. Tell.** It arrives as a giant shrinking pointer, about 0.67 s (`:31,150`), with an arrive sfx and a positional hum (`:46-55`). Scan lines while tracking you (`:168-173`).
- **b. Target.** It homes on you when you are visible (`:116-121`). Speed:
  - Square: 48 + 5 x purge (`village_square.gd:303`).
  - Edge: 40 + 3 x purge, capped at 62 (`the_edge.gd:89`).
  - x0.6 when it can't see you (`:125`).
- **c. Window.** **1.1 s** of continuous hover within 12 px (`:9,129-130`). It decays at 2x off target.
- **d. Attack.** Instant kill: "selected", reason "cursor" (`village_square.gd:306`, `the_edge.gd:92`).
- **e. Feedback.**
  - While it builds: a selection box with marching ants that shrinks onto you, a rising whine, screen static (`:131-137,175-179`).
  - On death: card "SELECTED · DELETED" with a tip (`story.gd:777-779`).
- **f. Recovery.** Move away, hide (Wren or a closet), BLIND, or DECOY.
- **ARITH.** In the square at purge 5 and awareness 100, speed is 73 x 1.2 = **87.6 px/s against your 90**. The square has no cap, unlike the Edge (`the_edge.gd:21-23`). You can barely outrun it.
- **CONFIRMED.** The cursor ignores `player.frozen`, dialogue and choice menus. See problem P2.

### Eraser / static (`erasure.gd`, `area.gd:70-83`)
- **a. Tell.**
  - HUNT line, stinger and "RUNNING: erase_unknown_entity()".
  - New cells flicker red with a growing black core for `mature_time` 0.8 s (Edge 1.1 s) before they become lethal (`erasure.gd:13,141-151,221-230`).
  - At the Edge: a 5 s countdown banner (+1.5 s per consecutive Edge static death, maximum 9.5 s) plus pulsing cracks at the seed points (`the_edge.gd:29-31,141-151,276-282`).
- **b. Target.** It grows from the frontier cell nearest you with 70% chance (Edge 45%) (`erasure.gd:14,163-170`; `the_edge.gd:35`).
  - Seeds: room door (`arins_room.gd:194`), far square corners (`village_square.gd:26`), Edge corners (`the_edge.gd:32`).
  - **Also every remembered death spot in that area** (`area.gd:77-79`). The Edge is the exception (`the_edge.gd:127-128`).
- **c. Window.** 0.8 s per cell. Growth interval:
  - `max(0.2, 0.45 - 0.04 x purge)` (`area.gd:75`).
  - Cells per tick: `1 + purge/3` (`area.gd:76`).
  - Halved at PURGE.
  - ARITH: purge 5 at PURGE gives 0.125 s x 2 = 16 cells/s.
- **d. Attack.** Touching a settled cell kills: "erased", reason "eraser" (`area.gd:93`, `erasure.gd:206-216`). The check uses the collider shrunk by 1 px.
- **e. Feedback.** Black void with a red bite edge. Death card "ERASED".
- **f. Recovery.** Outrun it, SCRUB, leave the area (a re-entered area starts with fresh erasure, `world.gd:338-348`). Slot 2 is protected (`the_edge.gd:105,220`).

### Prop drag (`owner_moves.gd:383-403`, `owner_cursor.gd:58-94`)
- **a. Tell.** "no. not that way." when it starts (`owner_moves.gd:400`). The cursor visibly fetches the crates (speed x1.6), then carries them (x0.9) with a "held" ants highlight (`drag_prop.gd:45-47`).
- **b. Target.** The road you are 36-150 px from: north (320,58) or east (580,180) (`owner_moves.gd:397-399`, `village_square.gd:13-14`).
- **c. Window.** About 5-7 s of carry, from home (84,242) at 0.9 x 48 = 43 px/s. The prop is never dropped onto Rue (`owner_cursor.gd:85-88`).
- **d. Attack.** Not lethal. Blocks the road for 14 s after placement (`owner_moves.gd:41,389-393`, which counts down only once the drag ends). Cooldown 25 s from the start (`:40`).
- **e. Feedback.** A lock sfx on placement (`owner_cursor.gd:94`).
- **f. Recovery.** The docstrings say "Phase through it" (`owner_moves.gd:17`, `drag_prop.gd:4`).
  - **ARITH: you can't.** The prop is 40 px deep. Your center is at least 4 px from it and the landing probe is 7x7, so you need d >= 4 + 40 + 3.5 = 47.5 px. But `PHASE_RANGE` = 46 (`glitch.gd:48`, `glitch_controller.gd:185-193`), so `phase_landing()` returns INF.
  - At both block points the far side is also the area boundary or the exit, which fails the `bounds.grow(-5)` test anyway.
  - In practice you must wait it out under HUNT, with the eraser growing. The cursor does not select you while it drags (`owner_cursor.gd:109-114`), which is a small mercy.
  - Test `test_owner_moves.gd:62` covers the drag only, not crossing.

### Load-last-save reload (`owner_moves.gd:150-262`) ⚠
- **a. Tell.**
  - **None** for the glitch trigger. It fires 1.0 s after your 3rd glitch "since the last load" (`:32,140-145`).
  - That counter spans the whole session until a reload and appears nowhere in the HUD. Grep: no `_glitches_since_load` outside `owner_moves.gd`.
  - The SILENCE trigger at least has the threshold stinger and owner line, 1.5 s ahead (`:117-121`).
- **b. Target.** You. Arin and the cursor snap back too (`:271-279`).
- **c. Window.** None. It is not avoidable once queued except by entering a blind area or PAUSEing (`:173-174`). Cooldown 40 s (`:31`).
- **d. Attack.** You are dragged along your path back to the oldest safe snapshot within 10 s:
  - The drag takes 0.9 s (`:29-30,197-201`).
  - Snapshots are taken every 0.25 s and kept for 12 s (`:27-28`).
  - It never lands you in void, within 64 px of the cursor, or within 44 px of Arin (`:50-51,228-250`).
  - Then glitch effects are undone (`:283-301`).
- **e. Feedback.** Owner line, banner "◀◀ LOADING AUTOSAVE · 00:NN AGO" (`:186-187`), screen spike and roll.
- **f. Recovery.** 0.8 s grace: the cursor is blinded and Rue flickers (`:52,255-262`). Exits are blocked while rewinding (`world.gd:292`).
- **CONFIRMED.** The glitch that triggers the reload is the one it undoes. An UNLOCK fired as the 3rd glitch costs 10 awareness, and the door relocks 1 s later.

### Save-over ring (`owner_moves.gd:311-341,416-436`)
- **a. Tell.**
  - Owner line ("saving over you.") plus "SAVING SLOT 1 . . ." in the console (`:324-325`).
  - Ring over Rue from 0%, with key ticks that speed up and a haptic buzz above 50% (`:331-336`).
  - Triggers: at HUNT 3 s after the threshold, then every 35 s. Or idle > 8 s at awareness >= 40, not hidden (`:33-39,101-102,313-316`). Or the false memory (`world.gd:223`).
- **b. Target.** Always you. The ring sits above your head.
- **c. Window.** **4.0 s** standing still. **13.3 s** while moving (x0.3) (`:33-34,329-330`).
- **d. Attack.** Kill: "overwritten", reason "save" (`:337-340`).
- **e. Feedback.**
  - Interrupted: "SAVE FAILED: SLOT 1 IN USE" plus an owner line (`:133-138`).
  - Complete: "SAVE COMPLETE: 0 UNKNOWN ENTITIES" and the death card.
- **f. Recovery.**
  - Any glitch cancels it. The interrupting glitch does **not** count toward a reload (`:133-139`).
  - Leaving the area cancels it (`:109-112`).
  - No save-over while writing Slot 2 (`:97-98`) or where the owner can't see (`:91-93`).
  - **Hiding does not stop a running ring**: `_update_save` has no hidden check.
- **Ring vs. progress.** The drawn arc and the % label read `save_progress` directly (`:422,428,431,435`), the same variable that `_update_save` advances (`:330`). **CONFIRMED identical**, with no separate display value.
- **Frame rate.** **CONFIRMED** frame-rate independent: `save_progress += delta / SAVE_TIME * k`, driven from `world.gd:251` with process delta. The only frame-sampled input is the `still` test (`velocity.length() < 10`, `:329`). The white blink above 75% uses wall-clock time (`:429`), which is cosmetic.
- **Freezes and pauses.** The ring freezes (it is not cancelled) during cutscenes (`world.gd:228`) and owner PAUSE.
- **CONFIRMED: it does not pause for dialogue or choice menus.** See P2.

### Door lock (`arins_room.gd:156-161,181-185`; `owner_director.gd:146-151`) ⚠
- **a. Tell.** **None.** In session 1 the door is OPEN (`arins_room.gd:86`). Walking within 70 px fires "nope.", awareness jumps to 52 and the door locks in the same frame.
- **b. Target.** The door.
- **c. Window.** **0 s.** You cannot reach a 70 px trigger before it fires.
- **d. Attack.** The door locks. Not lethal, but **floor 50 for the session**. ARITH: SILENCE in about 12 s and HUNT in about 22 s at room rate 1.05/s.
- **e. Feedback.** Spike, "WARNING: wall integrity 97%". The "LOCKED OUT" tip (`tutorial.gd:18`) points at the walls. The seam is open from here because awareness >= 40.
- **f. Recovery.** The seam, or UNLOCK (5 s). The square front door is always LOCKED (`village_square.gd:115`), with UNLOCK as the counter. A reload relocks forced doors.
- **Note.** This is clearly an authored teaching beat, but it is the single largest awareness hit in the game, and it lands on the most natural first action.

### Arin touch (`owner_avatar.gd:86-87`)
- **a. Tell.**
  - Arin is always drawn, with a view cone (85 px, 70°; `:17-18`) and positional footsteps (`:101-120`).
  - In the house: a door chime and "(the door. someone's coming in.)" 2.5 s before arrival (`arins_house.gd:95-98`). First visit 8 s after entering, then every 24 s, staying 15 s (`:22-24`).
  - At the Edge: a line when he is sent (`the_edge.gd:246`).
- **b. Target.** Patrol route. In the square it detours through learned spots (`village_square.gd:176-187`).
- **c. Window.** Continuous. Speed is always below yours:
  - Square: 38 + 4 x purge, x1.25 at SUSPECT, so 72.5 at most (`village_square.gd:165,212`).
  - House: 40 (`arins_house.gd:110`).
  - Edge: 34 (`the_edge.gd:46`).
- **d. Attack.** Contact within **8 px** kills instantly ("overwritten", reason "arin").
- **e. Feedback.** Death card "OVERWRITTEN".
- **f. Recovery.** n/a.
- **CONFIRMED.** The touch check ignores `is_hidden` (`owner_avatar.gd:86` is outside the sight test). Hiding does not protect from being walked into. The death tip says "hide beside Wren" (`story.gd:772`). Low practical risk, since Wren stands away from the loop.

### Recycle-bin sweep (`recycle_bin.gd`)
- **a. Tell.** Banner "EMPTYING RECYCLE BIN IN 3..2..1" with rising beeps, an owner line at 3 (`:20,123-130`), and the shadows brighten (`:222-227`).
  - The first sweep comes `max(6, 9 - 0.5 x purge)` s after entry (`:75`).
  - Later sweeps every `max(8, 16 - purge)` s (`:19,119`).
- **b. Target.** A full-height vertical line moving west to east.
- **c. Window.** 3 s of warning, plus 2.6 s to cross 448 px, about 172 px/s (`:21,115`). From the west entry (118,180) the nearest shadow is about 112 px away, roughly 1.25 s on foot.
- **d. Attack.** Instant kill unless you stand in a system-file shadow (`:146-151,154-162`). **Hiding does not apply.**
- **e. Feedback.** "RECYCLE BIN EMPTIED". Death card "EMPTIED", with tip.
- **f. Recovery.** Half-done restores reset (`:156-159`). PAUSE stops the bin (`:101-111`).
- **HYPOTHESIS.** The countdown keeps running while a terminal is open, because dialogue does not pause `area_process`. The banner is still visible.

### Edge static
See the eraser entry above. Gentler at the Edge:
- `GRACE` 5 s with a countdown (`the_edge.gd:29-31`).
- mature 1.1 s (`:36`).
- interval `max(0.6, (1.05 - 0.05p) x lerp(1.1, 0.9, aw) x 0.85 at PURGE)` (`:118-122`).
- burst 1 (`:129`).
- Never seeded on death spots (`:127-128`).
- The first Edge death of any kind is forgiven (section 4).

Tests: `test_edge.gd:12,26,42,53,64,79`.

### Slot 2 grab (`the_edge.gd:161-246`)
- **a. Tell.** At 50% written, if the cursor is more than 40 px from you: owner line, banner "THE OWNER HAS SEEN SLOT 2" and a stinger (`:170-176`).
- **b. Target.** The slot. The cursor reaches it at 95 px/s (`:44,177-184`).
- **c. Window.** Distance / 95 s to BLIND it before the grab. BLIND during "reach" stalls it (`:178-180`).
- **d. Attack.** Not lethal.
  - The slot is dragged at 42 px/s to whichever drop spot is farther from you (`:43-45,186-203`).
  - Writing pauses but progress is kept (`slot_two.gd:19-21,43-44`).
  - Then Arin walks up from the south road and circles the slot at radius 46 (`:228-246`).
- **e. Feedback.** Owner lines from `Story.FINAL_FIGHT`.
- **f. Recovery.** BLIND drops it early. On drop the cursor is blinded 0.6 s (`:217`).
  - Slot progress drains at 0.5x while you're out (`slot_two.gd:15,53`).
  - Write time 2.4 s is longer than the 1.1 s select, so the lure has to come first (`slot_two.gd:13`).
  - Test: `test_confrontation.gd:25`.

### Escort rings (for completeness; `owner_moves.gd:345-378`)
- Wren delete: a 5 s ring every 30 s, from SUSPECT.
- Mira reset: a 6 s ring every 25 s whenever she is out of her room.
- Tell: an owner line, a stinger, a labelled red ring.
- Counter: any glitch.

---

## 4. Persistence

All of it lives in `user://owner_memory.json`, written atomically (`owner_memory.gd:8,294-330`). Except where noted, it is learned only in `_learn()` (`:468-489`). `_learn()` runs on **death and on menu or window quit only**, never on a crash and never on a win.

**Patched seams**
- Trigger: you used seam N this session (`arins_room.gd:207-209`), then the session ended in death or quit (`owner_memory.gd:488-489`).
- Where saved: `patched_seams`. Capped at SEAM_COUNT-1 = 4, both on learn and on load (`:16,434,488`).
- How you learn: a "seal" sound 2.2 s into the next run (`arins_room.gd:133-137`). Patched seams stay drawn as scars (`:138-144`).
- Can it block progression? **No.** The room opens the first unpatched of 5 spots (`:145-151`), so one always stays open. Tested: `test_memory.gd:55`.

**Helper deletion**
- Trigger: anyone who hid you while the cursor or Arin queried you (`world.gd:402-408`), or anyone who escorted you (`world.gd:483`), when you die or quit. Wren is exempt once saved (`owner_memory.gd:469-470`).
- Where saved: `npc_fates[npc] = "deleted"` (`:486-487`).
- How you learn: death card "the owner saw who helped you." (`world.gd:900-901`), and next run "and i know who helped you." (`owner_director.gd:229-230`).
- Can it block progression? Not the escape ending. It **removes the square's only hiding spot** (Wren). It blocks the Wren ending until you restore her in the bin (`recycle_bin.gd:79-87`) or with RESTORE (4 memories).

**In-session deletions**
- Trigger: Mira at SILENCE (`arins_room.gd:186-192`). Wren at SILENCE if she hid you (`village_square.gd:215-220`).
- Where saved: session flag only (`world.gd:794`).
- How you learn: owner line plus "x.npc deleted".
- Can it block progression? No.

**Mira restricted / deleted by purge**
- Trigger: purge >= 1 makes her RESTRICTED. Purge >= 3 deletes her unless restored (`arins_room.gd:97-101`, `world.gd:794`).
- Where saved: derived from purge.
- How you learn: her dialogue changes.
- Can it block progression? Blocks Mira's side quest until she is restored.

**Note recall**
- Trigger: the previous exit or last death picks the room note text (`arins_room.gd:249-261`). There is also one owner note per run (`owner_director.gd:245-249`) and a death recall line (`:217-218`).
- Where saved: `last_exit`, `last_death`, `owner_notes_seen`.
- How you learn: reading the note, and the intro lines.
- Can it block progression? No.

**Route memory**
- Trigger: every 1.5 s that Arin can see you (`owner_moves.gd:42,406-414`).
- Where saved: `route_memory`, 40-px clusters, top 16 kept (`owner_memory.gd:471-485`).
- How you learn: in the square, Arin detours through the top `min(sessions-1, 3)` spots (`village_square.gd:176-187`), with "i know where you like to walk." (`owner_director.gd:160-161`).
- Can it block progression? No, but it makes the square denser each run. Tested: `test_owner_moves.gd:85`.

**Death sites**
- Trigger: every death (`owner_memory.gd:209-211`), last 12 kept.
- Where saved: `deaths_log`.
- How you learn: ghost markers (`area.gd:97-102`). These spots also seed the eraser at HUNT (`area.gd:77-79`).
- Can it block progression? **HYPOTHESIS:** players die near exits, so death seeds can grow void near roads, which the square comment explicitly tried to avoid (`village_square.gd:24-26`).

**Purge darkening**
- Trigger: purge.
- Where saved: `purge`.
- How you learn:
  - The light tint lerps toward (0.55, 0.5, 0.6) by purge/6 (`world.gd:395`).
  - "OWNER PURGE PROGRESS n/6" plus a bell at session start (`owner_director.gd:238-241`).
  - An extra unknown process at purge >= 2 (`world.gd:103`).
- Can it block progression? Indirectly, through faster everything.

**Edge mercy**
- Trigger: the first Edge death of *any* cause doesn't add purge (`owner_memory.gd:203-208`). It is re-armed when you reach Slot 2 (`:236`).
- Where saved: `edge_mercy_used`.
- How you learn: death card "(it didn't count.)" (`world.gd:907-908`). This text is **hidden when purge is already 5**, because the PURGE_WARNING branch wins (`world.gd:902-906`).
- Can it block progression? No.

**Edge static grace**
- Trigger: consecutive Edge static deaths add 1.5 s each, up to 9.5 s (`owner_memory.gd:198-201`, `the_edge.gd:114-115`).
- Where saved: `edge_static_deaths`.
- How you learn: the death tip states the new grace (`world.gd:910-911`).
- Can it block progression? No.

**Fragments and glitches**
- Survive death and purge. Only a wipe clears them (`owner_memory.gd:77-80`).
- Can it block progression? No.

---

## 5. Purge

`MAX_PURGE` = 6 (`owner_memory.gd:13`). `is_purged()` means purge >= 6 (`:122-123`), which loads the purged room (`world.gd:83-85,1105-1118`).

| Event | Purge +1? | Where |
|---|---|---|
| Death (not forgiven) | Yes | `owner_memory.gd:206-208` via `world.gd:894` |
| Forgiven Edge death | No (deaths +1) | `owner_memory.gd:203-208` |
| Quit to title or Quit game (menu) | Yes | `pause_menu.gd:55-56,141-156` → `world.gd:1084-1092` → `owner_memory.gd:217-224` |
| Window close (desktop X, Alt+F4) | **Yes, no confirmation** | `owner_memory.gd:109,112-115` |
| Crash, killed process, power loss | Yes, on next launch | `begin_session` writes `last_exit = "active"` (`owner_memory.gd:145,151`). `load_memory` sees "active" and does quits+1, purge+1, last_exit = "crash" (`:444-448`). Tested: `test_memory.gd:74` |
| Win "message" ending | Resets to 0 | `owner_memory.gd:243-246` |

**What crash and quit do differently.**
- A crash does **not** run `_learn()`: no seam patch, no helper deletion, no route learning (`:444-448`).
- A crash therefore punishes less than a menu quit on persistence, but the same on purge.
- The crash branch can push purge to 7: the load clamps to 6 (`:389`), then adds 1. This is harmless, because the check is `>=`.

**Web tab close (UNVERIFIED).**
- The only close hook is `NOTIFICATION_WM_CLOSE_REQUEST` (`owner_memory.gd:112-115`).
- There is **no `JavaScriptBridge` `beforeunload` handler** anywhere. `JavaScriptBridge` is used only for `?debug` (`world.gd:590-591`). `progressive_web_app/enabled=false` (`export_presets.cfg:91`).
- Godot's web platform is not expected to deliver WM_CLOSE_REQUEST on tab close, refresh or mobile tab discard. In that case `last_exit` stays "active" and the next visit counts it as a **crash: purge +1** ("you vanished without quitting.", `owner_director.gd:223-225`).
- Also UNVERIFIED: whether the "active" write had been flushed to IndexedDB before the tab died. If not, the previous closed state is what loads.

**Warnings.**
- Pause quit confirm: "Quitting counts. The owner will remember. Purge progress will rise to n/6", with extra text at 5 and 6, and "Stay" focused by default (`pause_menu.gd:141-152`). Good.
- Death card adds `PURGE_WARNING` ("one more death or quit...") when purge == 5 after this death (`world.gd:904-906`, `story.gd:692`). Tested: `test_purge.gd:65`.
- Session start shows "OWNER PURGE PROGRESS n/6" (`owner_director.gd:238-241`).
- Tutorial "QUITTING COUNTS" tip (`tutorial.gd:15`), shown in the first session only.
- No warning anywhere for window close, crash or tab close.

**Accidental-trigger risks.**
1. Desktop window X or Alt+F4 mid-run gives an immediate +1 with no confirm (CONFIRMED).
2. A web refresh or tab close, likely +1 via the crash path (UNVERIFIED).
3. A game bug or engine crash gives +1. The game's own defects are charged to the player (CONFIRMED by design).
4. "Quit to title" counts the same as quitting the game (CONFIRMED, but warned).
5. **Reverse risk:** holding F9 for 1.5 s anywhere in a run wipes *all* memory, including fragments (`world.gd:9,227,1146-1156`, `owner_memory.gd:251-291`).
   - It is not gated by `debug_enabled()`.
   - The only feedback is a hint line ("restoring intruder… N%").
   - Compare the purged-screen restore, which needs two confirmations (`world.gd:1123-1135`), and Settings reset, which is armed twice (`settings_panel.gd:80-82`).
6. Safe cases (CONFIRMED): closing during the death card or on the title screen doesn't double-count, because `_session_closed` is checked (`owner_memory.gd:192,218`). Tested: `test_memory.gd:36`.

---

## 6. Findings

### Confirmed problems (evidence)

**P1. Dragged crates cannot be PHASEd, despite the docs (ARITH).**
- The docs claim it in `owner_moves.gd:17` and `drag_prop.gd:4`.
- 40 px prop + 4 px collider half + 3.5 px probe half = 47.5 px > `PHASE_RANGE` 46 (`glitch.gd:48`, `glitch_controller.gd:179-193`). Both block points also back onto the area edge.
- Result: under HUNT the only answer is waiting about 14 s while the eraser grows.
- Fix options: raise PHASE_RANGE to about 56, shrink the prop, or correct the docs.

**P2. Dialogue and choice menus leave owner attacks running while disabling your answers (CONFIRMED path).**
- `idle_time` grows while you read, because the player isn't frozen by dialogue (`player.gd:138`, `hud.gd:378-390`).
- `_idle_save_due` has no `is_talking()` check (`owner_moves.gd:313-316`). The director's idle warn does have one (`owner_director.gd:128`), so the save can start without the promised warning.
- Glitches are disabled while dialogue is open (`world.gd:656-658`), so the counter to the ring is unavailable.
- `hud.choose()` sets `player.frozen` (`village_square.gd:254`, `:389`; `arins_room.gd:236`). The cursor (`owner_cursor.gd:103-142`), the eraser and the save ring keep running, and you can neither move nor glitch.
- Only the square's Arin pauses for talking (`village_square.gd:277`).

**P3. Hidden awareness costs.**
- Costs with no "+N" feedback:
  - Mira talk +8 *per talk*: `arins_room.gd:112`, `world.gd:866-868`.
  - Save point +15: `arins_room.gd:204`.
  - Room note +4.
  - TV +4.
  - Memory +6.
  - Escort x1.4 and +8/s.
  - Mira +2.5/s.
- The glitch UI shows prices clearly; these sources look free. Only `glitch_controller.gd:262` calls `hud.glitch_cost`.

**P4. The reload trigger is invisible and punishes the glitch you just paid for.**
- The session-long 3-glitch counter appears nowhere and survives blind areas (`owner_moves.gd:140-145`).
- It fires 1 s later with no tell.
- `_undo_glitches` reverts that glitch (`:283-301`). Awareness is kept.

**P5. Purge charged for non-choices.**
- Window close: +1 with no confirm (`owner_memory.gd:112-115`).
- Crash or killed process: +1 (`:444-448`).
- Web tab close: almost certainly +1 (UNVERIFIED; there is no beforeunload).
- At purge 5, one Alt+F4 or browser refresh ends the save permanently.

**P6. The room forces floor >= 40 every run.**
- The seam needs SUSPECT (`arins_room.gd:165`). From session 2 the door is DELETED (`:86`). In session 1 the door jumps you to 52 with no tell (`owner_director.gd:146-151`).
- Hiding, the Archive and FALSIFY can only recover the 10-25-point gaps above the floor, so the "slowly loses track" promise (`tutorial.gd:19`) is small in practice.

**P7. The meter shows ticks for only 3 of 6 thresholds** (`awareness_meter.gd:17`). SUSPECT and SILENCE are the two with the biggest consequences.

**P8. The idle warn fires in "blind" areas.**
- `owner_director.gd:128-131` doesn't check the area, so standing still 6 s in the Archive or out of bounds costs +5 with "i noticed that too".
- This contradicts "The owner can't see in here" (`tutorial.gd:21`, `archive.gd:28-30`).

**P9. Inconsistent sight rules.**
- Square: 0.35 s grace and 22/s.
- House: 20/s, no grace.
- Edge: 12/s, no grace.
- Arin's touch ignores hiding, while the death tip suggests hiding beside Wren.

**P10. The F9 wipe has no confirmation and is not debug-gated** (`world.gd:1146-1156`).

**P11. The PURGE-threshold speedups are not reapplied by `catch_up`.**
- The square cursor x1.2 and the eraser x0.5 interval are set only in `on_owner_event`.
- Leaving and re-entering an area at awareness 100 quietly removes them (`village_square.gd:195-203`, `area.gd:40-42`).
- Minor, and in the player's favour.

### Hypotheses needing playtest

- **H1.** Purge 4-5 room timer: HUNT about 12 s after waking, before the PHASE cost. Is the room memory plus the seam still reachable?
- **H2.** Square cursor at purge 5 and awareness 100 runs at 87.6 px/s against 90. Is it effectively unshakeable without BLIND or Wren?
- **H3.** Eraser at purge 5 and PURGE (16 cells/s, hunting 70%). Does the square become unwinnable after HUNT plus PURGE?
- **H4.** Death-spot eraser seeds near exits wall off roads over many runs.
- **H5.** Wrong-target glitches under pressure (no cycling, nearest-by-normalised-range).
- **H6.** Entering a watched area from the Archive after 35+ s at HUNT starts a save-over on the first frame (`owner_moves.gd:101-102`). Combined with a fresh cursor and eraser, is the arrival readable?
- **H7.** Reading bin terminals during the sweep countdown. Is the banner enough?
- **H8.** The session-1 door beat (+52, then about 12 s to Mira's deletion and a reload). Do first-time players understand the seam in time?
- **H9.** The DECOY, PAUSE and PHASE priority. Standing still facing a wall gives PHASE, never PAUSE.
- **H10.** Web: verify tab close and refresh in a real browser export (does `last_exit` = "active" persist, and does purge increment on return?).

### Tests that exist for these systems
- Glitches: see the table in section 2.
- Owner moves: `test_owner_moves.gd:6,24,34,45,55,62,85`.
- Fairness: `test_fairness.gd:7,22,35,51,63,71,89`.
- Idle save: `test_owner_fixes.gd:12,22,32,36`.
- Purge: `test_purge.gd:19-65`.
- Memory: `test_memory.gd:25-102`.

None cover:
- PHASE across a dragged crate (P1)
- save or cursor during dialogue or choice (P2)
- idle warn in the Archive (P8)
- window-close purge

# UX audit: The Last Save File

> **Historical record.** This audit describes an earlier build. For the current state, see `RELEASE_READINESS.md` (status and validation) and `COHESION_PASS.md` (what was verified, fixed and deferred most recently). Findings marked fixed there supersede the ones here.

> **Status (2026-10-16, experience-polish milestone):**
> - **Fixed:**
>   - C1: reading no longer counts as standing still, and modal questions hold the owner.
>   - C2: a 450 ms input grace on choices.
>   - C3: a press released in the first half of a charge still talks; later releases give a "cancelled" sound.
>   - C8: holding F9 only works on the purge screen or in debug builds.
>   - C10: a Screen shake toggle.
>   - C13: W/S move the focus in choices.
>   - Text speed setting (Slow / Normal / Fast / Instant).
> - **Still open:** C4–C7, C9, C11, C12, C14–C16.
> - See `EXPERIENCE_POLISH_BASELINE.md` §3.

Written 2026-10-16 at commit `fb1ffc9`. Everything here comes from **reading the code**. The game was not run, and no human session was observed. Line numbers point at that commit.

Each finding is labelled with one of two tags:

- **PRODUCTIVE UNCERTAINTY**: the player is unsure on purpose. The game is horror about an unreliable save, and the confusion serves it.
- **ACCIDENTAL CONFUSION**: the player is unsure because of an implementation detail, a timing collision or a missing affordance.

Section 7 lists the confirmed issues in priority order and, separately, the hypotheses that need a playtest. Where this doc overlaps `docs/CREATIVE_AUDIT.md` §A, it adds timings and code paths and doesn't repeat that section's verdicts.

---

## 1. First session, beat by beat

The numbers assume the first launch (`OwnerMemory.sessions == 0 → 1`, `purge == 0`), tips on, and no input during cinematics unless stated.

### 1.1 Title (`scripts/ui/title.gd`)
- **What it shows.** A load menu: a slot card, "Load Slot 1", Records (hidden until a session exists, `:200`), Settings, How to Play and Quit. It carries a flashing warning (`:209`) and a one-line control hint chosen once in `_ready` (`:210-214`).
- **Timing.** From 4 s, the Load button briefly reads "(it isn't yours)" in the last 0.4 s of every 7 s cycle (`:259`). From 8 s, the owner types "> is someone there?" at 12 cps (`:261-268`). The title also glitches at random (`:245-250`, scaled by `flash_scale`).
- **Verdict.** PRODUCTIVE UNCERTAINTY. The whispers are short and never block anything.
- **Issue.** The control hint is chosen once. If a gamepad is plugged in after the title loads, it still lists keyboard keys. The same applies to How to Play's `controls()`, which `_ready` builds once (`how_to_play_panel.gd:37,45-50`). This is ACCIDENTAL CONFUSION and low severity.

### 1.2 Boot (`world.gd:109-115`, `Story.BOOT`, `hud.gd:304-370`)
- **What it shows.** 8 letterboxed lines in system grey on full black (`dim = 1.0`).
- **Timing.** Each line types at 40 cps (`hud.gd:353`) and then waits `2.4 + 0.045 × len` s (`:360`). The lines total about 274 characters, so typing takes about 6.9 s and the waits about 31.5 s. With the 0.4 s bars in and 0.5 s out, the boot lasts **about 39 s untouched**. The CREATIVE_AUDIT figure of "about 15 s" assumes the player presses through.
- **Skipping.** Interact or confirm completes a line, and a second press advances it. Skipping the whole boot takes about 16 presses. There is no skip-all.
- **Verdict.** PRODUCTIVE as content.
- **Issue.** The last line, "> ...who's in my save?", is the owner speaking, but it renders in system grey and gets the system key sound (`hud.gd:356` only tells SELF apart from everything else). The game's own colour language (owner = orange-red, `hud.gd:10`) is broken on its first owner line. ACCIDENTAL CONFUSION, low.
- **Mitigation.** The boot only plays when `sessions == 1 and previous == "none"` (`world.gd:112`), so it plays once ever, or again after a memory wipe.

### 1.3 Wake (`world.gd:116-134`)
- Rue is frozen for 1.4 s while materialising. The act card "ACT I · SOMEONE ELSE'S SAVE" is non-blocking: 0.4 s fade in, 2.8 s hold, 0.8 s fade out (`hud.gd:460-479`).
- Three `wake_first` thoughts type into the console at 36 cps with a 0.5 s gap (`hud.gd:22-23`). The tips start after a 1 s gap. At 7 s comes "something cyan…" (`world.gd:131-134`).
- **Simultaneous channels in the first ~10 s:** the act card in the centre, console typing at bottom left, a tip card at top centre, the slot bar and the awareness meter. The cyan memory hint also lands while the MOVE tip is up.
- **Timing pressure.** Arin's room has `awareness_rate = 3.0` (`arins_room.gd:68`), which works out to about 1.05 awareness/s at purge 0 (`owner_director.gd:115`). NOTICE (25) arrives at about 24 s and SUSPECT (40) at about 38 s, even if the player does nothing.
- **Verdict.** PRODUCTIVE: the meter fills while you read, which teaches "don't stand still". But see §2.3: reading itself counts as standing still.

### 1.4 Tutorial tip sequence (`tutorial.gd`)
- **Room sequence.** `move → watched → quit → wren` (`:31`). Each tip stays up for at least 3.5 s and at most 8 s (`:33-34`), with 1.2 s between tips (`:38`).
- **Which tips end early.** Only `move` (48 px walked), `interact` (focus lost), `hidden` and `crack` (entered the nook) finish early (`:147-157`). `watched`, `quit` and `wren` always stay the full 8 s. So the sequence occupies the top-centre card for **about 28-30 s** of the first 40 s.
- **Priorities.** Contextual tips win only *between* tips (`_next_tip`, `:89-118`): `interact`, then `way_out`, `hidden`, `price`, `crack` and `glitch`. A door lock that happens during the 8 s `quit` tip waits up to 8 s for its "LOCKED OUT" explanation.
- **Issue.** The `wren` tip ("In the village square, stand right beside Wren…") is shown in Arin's room before the square or Wren exist for the player. It is front-loaded advice with nothing to attach to. ACCIDENTAL CONFUSION, low.
- **Issue.** The tip card (y ≈ 44-96) and the banner (`hud.gd:174`, y 70-94) overlap. A reload ("◀◀ LOADING AUTOSAVE") during a tip draws both on top of each other: the tutorial hides tips only for dialogue, cinematics and `_cutscene` (`tutorial.gd:64`), and a reload is none of those. Geometric, confirmed. Low.
- **Persistence.** `tips_seen` lives in `settings.cfg` (`settings.gd:68-71`), so wiping the owner's memory does not replay the tips. That is intended.

### 1.5 First interaction
- **Mechanics.** `INTERACT_DISTANCE` is 22 px (`world.gd:7`). The focus marker brackets the target, and the prompt reads "[E] talk" or "[E] read note" at bottom right (`hud.gd:539-540`). The `interact` tip pre-empts the sequence the moment anything is focusable (`tutorial.gd:90`).
- **Issue: talking costs awareness without saying so.** Mira has `awareness_cost = 8.0` (arins_room.gd, `mira.awareness_cost`), charged on *every* interaction (`world.gd:866-868`). The note costs +4 (`arins_room.gd` `interact_extra`), and the save point +15. Getting to Mira's request takes 3 talks (`_mira_line >= 2`), which costs 24 awareness, about 23 s of room time. The only feedback is the meter, and the owner's "don't touch that" appears only for the save point at NOTICE or above.
  - PRODUCTIVE UNCERTAINTY if the designer wants "everything you touch is noticed".
  - ACCIDENTAL if the player reads How to Play's "Talk to everyone more than once" (`how_to_play_panel.gd:16`) as safe advice.
  - Flagged as hypothesis H4.
- **Issue: tap and hold collide on people, notes and doors.** FREEZE targets any present NPC within 40 px, FALSIFY any note within 34 px, and UNLOCK a locked door within 44 px (`glitch_controller.gd:127-139`). All three are unlocked from the start (`glitch.gd:20-27`, `needs: 0`). So the prompt "[E] talk" sits directly under a pink "hold [E] FREEZE +6".
  - A press longer than `HOLD_START = 0.22 s` starts a charge (`glitch_controller.gd:17,73`). Releasing during the charge does **neither**: no tap is sent because `_charge > 0` (`:76-79`), and no glitch fires.
  - A press of 0.62 s or more fires FREEZE on the person you wanted to talk to, at +6 awareness.
  - Confirmed mechanics. ACCIDENTAL CONFUSION. See C3.

### 1.6 First glitch: the cracked wall (PHASE)
- **When the tip appears.** The `crack` tip needs `move` seen and Rue within 90 px of `CRACK (500,118)` (`tutorial.gd:102-104`). It says "Face the wall and hold {interact}". Showing it also marks `glitch` as seen (`:127-128`) and schedules "...is something in the walls?" 2.5 s later (`:130-132`).
- **Targeting.** PHASE needs Rue's *facing* toward a wall within 9 px (`glitch_controller.gd:22,179-193`). Facing is the last movement direction. A player who walks up to the crack and stops is facing it, so the prompt "hold [E] PHASE +8" appears.
- **After it fires.** The `price` tip ("THE PRICE") arrives after the next tip gap (`tutorial.gd:98-99`).
- **Verdict.** PRODUCTIVE. It is well staged. The owner's line after the tip turns the tutorial into a diegetic beat.
- **Edge case.** Near the nook's left wall (x 458), Mira (440,130) is within FREEZE's 40 px, and NPC targets beat PHASE (`glitch_controller.gd:154-158`). Holding E there freezes Mira instead of phasing. Hypothesis H6.

### 1.7 First owner encounter: the door
- **Trigger.** While the door is OPEN, getting within 70 px of it (`arins_room.gd:160-161`) calls `on_door_approached`. That adds `CONTAIN − awareness + 2` (`owner_director.gd:143-149`), so awareness jumps to 52.
- **What fires in one frame:**
  - NOTICE: the note is rewritten.
  - SUSPECT: lights flicker and **the seam opens**.
  - CONTAIN: the door locks, the screen spikes, and the console prints "WARNING: wall integrity 97%".
  - The awareness meter jolts three times, and three stingers play.
- **Verdict.** PRODUCTIVE. It is the best moment of the opening, and the attempt itself reveals the way out.
- **Timing hazard.** The player is now at 52 while the room adds 1.05/s:
  - SILENCE (65) comes about 12 s later. Mira is deleted, and an autosave reload drags Rue back about 10 s, 1.5 s after the threshold (`owner_moves.gd:113-117`).
  - HUNT (75) comes about 22 s later. Erasure spreads from the door, and a save-over starts 3 s after that (`owner_moves.gd:118-119`).
  - The window to find the seam is about 20 s, and it is broken up by the reload. Hypothesis H2: likely the intended first death, but a hard one.
- **Door on later sessions.** From session 2 the door spawns already DELETED (`arins_room.gd:86`), so this beat happens once.

### 1.8 First death
- **What happens.** `kill()` (`world.gd:877-920`) runs the death effect, waits 0.6 s, then shows the death card. The card has a title, a body, an optional owner-saw-helpers line, and a tip resolved to the current device glyph (`:924-929`). After **3.6 s** with a tip (2.8 s without, `:918`), the scene reloads.
- **No input is read**, so the card is neither skippable nor holdable. A 3-line body plus a tip is a lot to read in 3.6 s, especially with Large text on. Hypothesis H3.
- **Reload cost.** Another 1.4 s frozen while materialising (`world.gd:116-119`). Each death is about **5.6 s of dead time**.
- **Glitch tip on the card.** The "save" death's glitch tip is gated on PHASE, which is always unlocked, so the plain "keep moving" tip never shows (`Story.DEATHS.save`). Fine.

### 1.9 Return to a changed world
- The note recalls the death (`Story.NOTE_RECALL`). The used seam is stitched shut with an audible seal 2.2 s in (`arins_room.gd` build). The door is DELETED, and Mira is RESTRICTED once `purge ≥ 1`. One `wake_again` line plays.
- **Verdict.** PRODUCTIVE. This is the signature, as CREATIVE_AUDIT notes.
- **Gap.** Nothing on screen says that awareness now *starts* higher: `START_PER_PURGE` = 10 per purge (`owner_director.gd:22-23`), so 10 on session 2. The meter just starts partly filled. PRODUCTIVE UNCERTAINTY, acceptable.
- **Repetition.** Per-area line counters such as `_mira_line` and `_tobben_line` are area-instance variables, so they reset every session. Mira restarts at RESTRICTED line 0 after every death. See §6.

### 1.10 First memory (`world.gd:150-206`)
- **How the world stops.** The area is set to `PROCESS_MODE_DISABLED`, the director pauses and the player freezes. This is the **only** dialogue-like state that truly stops threats (§2.3).
- **The cinematic.** 3-4 lines. Each takes about `2.4 + 0.045 × len + len/40` s, so a flashback runs **about 15-20 s untouched**.
- **Afterwards.** The console queues "MEMORY RECOVERED n / 5", the `after` line, the `RESTORED` body line and "NEW GLITCH: X", and a centred NEW GLITCH card shows for 4 s. The owner then gets +6.
- **Issue.** Four console lines at 36 cps plus 0.5 s gaps take about 6-7 s to drain. Anything the owner says in the meantime waits in the FIFO queue (§2.4). Low.

### 1.11 First route decision: the square
- **On arrival.** The act card reads "ACT II · ASHVALE", the owner says "where do you think you're going?", and the `arin` tip appears.
- **The pause-menu goal** reads: "Explore the village. The road east leads somewhere old. The well looks deeper than it should." (`world.gd:447-455`).
- **Routes:**
  - East to the Archive.
  - The well, to Out of Bounds.
  - The house, with the door locked (UNLOCK).
  - The north road, struck through until the Archivist gives the pointer (`village_square.gd:276`).
- **Issue: act numbers follow areas, not the order you reach them.** The goal text and Pip's `guide_point` (`village_square.gd:291-294`) both steer the player **east to the Archive first**. But `Story.ACTS` numbers OOB as ACT III and the Archive as ACT IV, and `_area_intro` shows an area's card the first time you enter *that area* (`world.gd:381-388`). The recommended route therefore shows "ACT IV" before "ACT III". Confirmed. ACCIDENTAL CONFUSION, medium for a story-led game. It touches presentation only, not canon.
- **Verdict on the struck-through NORTH ROAD.** PRODUCTIVE: it signals a goal.
- **Verdict on the house.** PRODUCTIVE: it is optional, and its locked door teaches UNLOCK.

### 1.12 Final confrontation: the Edge and Slot 2
- **On arrival.** The act card reads "ACT V", and the `slot` tip explains that the cursor selects still things, so you should lead it away. The cursor's select timer is 1.1 s (`owner_cursor.gd:9`).
- **`reach_slot2`** (`world.gd:944-983`):
  - The world is frozen properly (director paused, owner paused).
  - The recap cinematic plays: 3-10 lines in OWNER colour (`Story.slot2_recap`), about 25-45 s untouched.
  - `choose()` opens with **option 0 focused by default** (`hud.gd:426`).
  - For the message ending, a second `choose()` follows.
- **Then `win()`:**
  - A 1.5 s pause, then the FINAL_EXCHANGE cinematic (3-4 lines, about 12-15 s), all in OWNER colour, including Rue's "(…)" lines and Wren's line (`world.gd:1011`).
  - The EPILOGUE cinematic (5-7 lines, about 25-35 s).
  - The end card, "[ENTER] title screen" (`:1035`).
- **Issues:**
  - Mashing through the recap selects option 0 (C2).
  - On touch, the end card names the wrong button (C7).
  - Replaying for other endings means about 60-90 s of per-line cinematics with no skip-all (§6).

---

## 2. Dialogue

### 2.1 Reveal speed, per channel
| Channel | Speed | Code | Voice |
|---|---|---|---|
| Dialogue box (NPCs, notes, readables) | 55 cps, **the same for every speaker** | `hud.gd:503` | per-speaker blip if the name is in `Sfx.VOICES`, else a system key (`:506-510`) |
| Console (`say()`) | 36 cps plus a 0.5 s gap between lines | `hud.gd:22-23,690,711` | owner: `owner_blip`; others: `type_key(kind)` (`:695-698`) |
| Cinematic | 40 cps, then auto-advance after `2.4 + 0.045 × len` s | `hud.gd:353,360` | SELF colour → "self", otherwise "system" (`:356`) |
| Title owner line | 12 cps | `title.gd:265` | owner blip |

- **No speed setting.** There is no text-speed setting, and none of the four speeds is configurable or tied to Large text.
- **Typing speed doesn't vary by character.** The only per-character difference is the sound. Owner console lines also "arrive wrong": garbage characters run ahead of the cursor (`hud.gd:699-703`, off at `glitch_intensity == 0`).

### 2.2 Skip and instant reveal
- **Dialogue box.** The first interact or confirm reveals the whole line, and the next advances. The press that opened the box is ignored (`hud.gd:511-522`). Walking more than 40 px away closes it (`world.gd:246-247`). Gamepad B and Esc cannot close it: Esc opens the pause menu instead.
- **Cinematic.** Same two-press pattern per line (`hud.gd:357,369`). There is **no skip-all and no hold-to-fast-forward**.
- **Console.** It cannot be skipped or scrolled, and there is no backlog. Lines over 420 px are **truncated with "…"** (`hud.gd:722-723`). One known casualty is `Story.WREN_EDGE[2]`, "WREN: I always thought the world ended at the wall… It just stops being drawn.", at about 106 characters, which cannot fit 420 px at 10 px or larger. Lines beyond 4 (3 with Large text) are dropped (`:756-766`). Confirmed. See C5.
- **Death card.** It cannot be skipped and cannot be held (§1.8).

### 2.3 Is gameplay paused during dialogue? Only partly.
`World._process` keeps running while the box is open (`world.gd:226-252`). The only gates in that function are `ending`, `_transitioning` and `_cutscene`, and an open dialogue box sets none of them. The player isn't frozen either (`player.gd:130-136`), which is how "walk away to close" works.

| System | During the dialogue box | During `choose()` (Wren, Mira, guest book) | Evidence |
|---|---|---|---|
| Awareness rise | **keeps rising** | keeps rising | `owner_director.gd:107-125` has no `is_talking` check. Only the idle *warning* checks it (`:128`). |
| Arin (square, house) | paused | **not paused**: `is_talking()` checks only the dialogue box | `village_square.gd:277`, `arins_house.gd:87`, `world.gd:816-817` |
| Arin's sight and touch | none while paused | **active**: touch kills within 8 px even when hidden (`owner_avatar.gd:86-87`), and the player is frozen | `village_square.gd:254` (frozen) |
| Cursor (square at HUNT, Edge) | **active**: it selects a player who stands still for 1.1 s | active | `cursor.paused` is set only by owner-pause (`area.gd:51-56`, `village_square.gd:308`) |
| Erasure (static) | **spreads** | spreads | `erasure.gd:128-136`, stopped only by `set_owner_paused` |
| Save-over | **starts and progresses**. Reading is "standing still", so `idle_time` grows and `_idle_save_due` fires after 8 s at SUSPECT or above (`owner_moves.gd:313-316`). It fills in 4 s while still (`:328-330`). | progresses at full speed (frozen → `velocity == 0`) | `owner_moves.gd:88-105` has no talking check |
| Recycle bin sweep | runs | runs | `recycle_bin.gd:101-111` pauses only on owner-pause |
| Out of Bounds fall | paused | not paused | `out_of_bounds.gd:101` |
| Glitch input | blocked (`can_act`) | blocked | `world.gd:656-658` |
| Console visibility | **hidden**. Lines keep typing invisibly and can scroll out unseen. | hidden | `hud.gd:388,424,747-749` |
| Tutorial tips | hidden | shown | `tutorial.gd:64` |

**So yes: the cursor, the eraser, a save-over and the bin can kill Rue while a dialogue box is open.**
- The warning for a save-over, "SAVING SLOT 1 . . ." plus the owner's line, goes to the console, and **the console is hidden while dialogue is open**. The save ring over Rue (`owner_moves.gd`, `_draw`) is the only remaining signal.
- The design is internally inconsistent:
  - Arin pauses for dialogue, but the cursor doesn't.
  - The idle *warning* skips dialogue, but the idle *save-over* doesn't.
  - Memories freeze the area, but conversations don't.
- A player who learns "Arin waits while I talk" will reasonably assume the rest of the world waits too. ACCIDENTAL CONFUSION, high severity (C1).

### 2.4 Narration, self, owner and system lines
| Kind | Where | Look | Sound |
|---|---|---|---|
| owner | console | `> ` prefix, orange-red `#e0704f`, cyan chromatic shadow, self-corrupting (`hud.gd:725-733,774-797`) | owner blip |
| self (Rue) | console, memory cinematics | `( )` wrap, cyan `#8cf2ff` | "self" key |
| npc | dialogue box (speaker label in NPC colour) or console `NAME: text` in amber | | per-speaker blip |
| system | console | grey `#8a8f98`, no prefix | "system" key |

- **Strong in the console.** Prefix and colour each carry the speaker, so the distinction doesn't rely on colour alone. Good for colour-blind players.
- **Weak in cinematics.** One colour covers the whole block:
  - The BOOT block is grey, including the owner's "> …who's in my save?".
  - The recap and FINAL_EXCHANGE use OWNER colour for Rue's "(…)" and for "WREN: …".
  - Only the prefixes still separate the speakers.
- **Console ordering.** The console is a single FIFO queue with no priority (`hud.gd:527-529,716-718`). An urgent line like "SAVING SLOT 1 . . ." or "RUNNING: erase_unknown_entity()" can sit behind 3-4 flavour lines, about 1.5-2 s each. Confirmed mechanism. Medium (C6).

---

## 3. Input matrix

Bindings come from `owner_memory.gd:498-515`. Glyphs come from `settings.gd:85-97`. Touch buttons come from `touch_controls.gd:17-20`.

| Action | Keyboard | Gamepad | Touch | Prompt glyph correct? |
|---|---|---|---|---|
| Move | WASD + arrows (physical keys) | d-pad + left stick | drag in the left `Rect2(0,60,300,300)` | Yes on all three. Touch reads "Drag on the left side of the screen". |
| Interact (tap) | E, Space | A | E button (r 30) | Yes. Touch shows "E", which matches the button label. |
| Glitch (hold ≥0.22 s plus the glitch's hold time) | hold E/Space | hold A | hold E: a pink dashed ring with "HOLD · NAME" | Yes ("hold [E] PHASE +8"). There's no toggle or one-press alternative (§5). |
| Dialogue advance | E, Space, Enter | A | E | Yes, but the hint text is set per line, so it's stale if the device changes mid-line (`hud.gd:494`). |
| Dialogue close early | walk away | walk away | walk away | Not prompted anywhere. |
| Choice navigate | **arrows only**: `ui_up/down` defaults don't include W/S | d-pad, stick | tap an option | No prompt. A WASD player gets no response from W/S. |
| Choice select | E, Space, Enter (+ mouse) | A | E (picks the *focused* option) or tap an option | No glyph shown. |
| Pause | Esc | Start | II button (r 15) at (612,90) | "ESC", "START" or "II": yes. |
| Menu navigate | arrows, Tab | d-pad, stick | tap | Yes. Focus is grabbed on every panel switch (`pause_menu.gd:121,133,138`, `title.gd:358`). |
| Back | Esc (`pause`, `ui_cancel`) | B (`ui_cancel`), Start | tap Back or II | How to Play lists "Back: B" for gamepad only. |
| Map | pause → Map | pause → Map | pause → Map | There's no direct binding. How to Play says "Pause / map". |
| Win card → title | Enter, Esc | A, Start | E (sends `confirm`) | **No on touch**: it says "[ENTER]" (C7). |
| Wipe memory | hold F9 for 1.5 s, **in every build** | none | none | Only a small hint, shown once you're already holding (`world.gd:1147-1156`) (C8). |
| Debug | F3, F5-F8, F10, F11 (debug builds, or `?debug` on web) | pause → Debug | pause → Debug | n/a |

**Device switching** (`settings.gd:53-64`):
- A key press clears both the touch and gamepad flags. A joypad button, or an axis past 0.5, sets gamepad. A screen touch sets touch. An emulated mouse button is ignored.
- Prompts re-read the glyph every frame (`world.gd:855`), so they update immediately.
- Tip bodies, death tips and NEW GLITCH cards resolve the glyph once, when shown.
- `TouchControls.active` becomes true on the first touch and **is never reset** (`touch_controls.gd:51,56`). On a touch laptop, after one touch the on-screen E and II stay drawn while the player uses the keyboard. Meanwhile `Settings.using_touch` goes false, so the HUD moves the prompt back under the drawn E button (`hud.gd:661` vs `touch_controls.gd:18`). Confirmed. Low.

**Focus handling:**
- `choose()` grabs focus on option 0 once (`hud.gd:426`).
- Opening pause moves focus to Resume (`pause_menu.gd:121`). `close()` doesn't restore the previous focus (`:96-99`).
- After pausing during a choice and resuming, no option has focus. E, Enter and A then do nothing, because `_update_choice` needs a focused Button (`hud.gd:443-446`). Whether arrows re-acquire focus depends on Godot 4.3's handling of navigation with no focus owner (H1).

---

## 4. Touch

The viewport is 640×360, stretch `canvas_items`, aspect `keep` (`project.godot`).

| Control | Game-px geometry | On a 2400×1080 phone (×3) | Overlaps |
|---|---|---|---|
| E button | centre (588,292), r 30, hit r 36 | 180 px wide, about 11 mm | **The dialogue box** spans x 10-630, y 282-350 (`hud.gd:255-256`). Its text area, x 18-578 and y 300-334, runs under the button (x 558-618, y 262-322). The last ~20 px of each dialogue line sit under the button and the thumb. Confirmed geometry. |
| II (pause) | centre (612,90), r 15, hit r 21 | 90 px drawn, about 6 mm; 126 px hit, about 8 mm | Clear of the meter (y 8-44) and the status line (y 46-58). Slightly small next to the 44 pt guideline. Hit area OK. |
| Stick zone | x 0-300, y 60-360 | | The console (bottom left, y ≈ 294-350) sits under the left thumb. Owner lines, the main narrative channel, are covered while moving (H5). |
| Prompt | shifted 72 px left on touch (`hud.gd:661`) → x 378-554, y 288-304 | | It can overlap the right end of a 4-line console (x ≤ 442, top ≈ 294). Unverified (H5). |
| Hold ring and label | 180 px label above E | | Can cover the glitch prompt. Redundant, so fine. |

- **Landscape.** It's assumed. In portrait the game draws a "turn your phone sideways" overlay (`touch_controls.gd:148-153`) but **doesn't pause**. The owner's awareness keeps rising and threats keep moving while the player rotates the phone. Confirmed. Medium (C9).
- **Safe areas.** There's no notch or safe-area handling (no `get_display_safe_area`). The `SAFE` 14×10 margin in `hud.gd:20` is for the CRT bezel, not device cutouts. On ×3 phones with the `keep` letterbox, side bars usually absorb the notch. H5.
- **E sends two actions.** It sends both `interact` and `confirm` (`touch_controls.gd:18`). In a `choose()`, tapping E picks the focused option, option 0 by default (C2).

---

## 5. Settings

Defined in `settings.gd`, saved to `user://settings.cfg` on every change (`set_value`, `:116-122`), loaded at boot (`:165-184`). Slider drags save on every 0.05 step.

| Setting | Default | Persisted | Applied where |
|---|---|---|---|
| Master, Music, Effects volume | 0.8, 0.8, 0.9 | yes | audio buses (`apply`) |
| Fullscreen | off | yes | `DisplayServer` |
| CRT curvature | on | yes | shader `curvature` |
| Screen effects (Full, Light, Off) | Full; Light on first mobile launch | yes | shader quality / visibility (`screen_fx.gd:228-229`) |
| Glitch (intensity 0-1) | 1.0 | yes | shader distortion, **world shake** (`screen_fx.gd:280`), player jitter and tearing, owner-line shadow and corruption, death-title shake and ghosts, charge-ring wobble |
| Reduce flashing | off | yes | `flash_scale()` = 0.3. Shader wash, invert, noise and roll; meter strobe; light flicker (`world.gd:824`); title, sun beam, scars, bursts, player blink; Sfx harshness |
| Large text (×1.25) | off | yes | every `UiStyle.sized` label and theme: dialogue, console, cinematic, tip, choice, menus |
| Vibration | on | yes | `buzz()` on touch and gamepad |
| Tutorial tips | on | yes, plus `tips_seen` | `tutorial.gd`. Turning it back on clears `tips_seen`. |
| `using_touch`, `using_gamepad` | — | no (runtime) | glyphs |

- **Screen shake has no separate toggle.** `shake()` is scaled only by `glitch_intensity` (`screen_fx.gd:280`). A player who wants the glitch look but no camera shake, or the reverse, can't have it. Setting "Glitch" to 0 also removes the owner's text corruption, which is narrative signal. Medium (C10).
- **Reduce flashing scales flashes down, it doesn't remove them.** At 0.3, the "selected" death still double-inverts the screen at 30% (`screen_fx.gd:148-155` → shader `:157`). Only "Screen: Off" removes all full-screen flashes. The title's warning says flashes "can be reduced", which is accurate. Some world-side spikes pass raw values, such as `world.gd:566` and `arins_room.gd` `door.lock` → `spike(0.6)`. That's acceptable because the shader multiplies tear by intensity, not by `flash`, so these count as distortion rather than flashes.
- **Large text coverage.** Complete by construction, but the layout is fixed:
  - The dialogue text box is 560×34 px inside a 68 px panel (`hud.gd:266`). Two lines at 14 px fit, three overflow onto the hint row and past the panel bottom.
  - The console drops to 3 lines (`hud.gd:757`), and its 420 px truncation gets worse (about 60 characters at 13 px).
  - The choice min width is 420/400 with autowrap. OK.
  - The death body is 560×140. OK.
  - H7: overflow on long lines.
- **Missing options:** text speed, cinematic auto-advance off, hold-time or toggle for glitches (motor accessibility), rebinding, a separate shake toggle, a colour-blind palette. Awareness and the threat colours rely on red, magenta and cyan, though the console prefixes help.

---

## 6. Friction

| Item | Duration | Skippable? | Repeats | Note |
|---|---|---|---|---|
| Boot | ≈39 s untouched | per line (≈16 presses) | once ever (and after a wipe) | Fine. |
| Wake materialise | 1.4 s frozen | no | every session | Fine. |
| Act card | 4.0 s, non-blocking | n/a | once per area ever (`acts_seen`) | The order issue is in §1.11. |
| Area title | 2.8 s, non-blocking | n/a | every area entry | Fine. |
| Death → reload | 0.6 + 3.6 (2.8) s, plus 1.4 s wake | **no** | every death | ≈5.6 s dead time per death, in a game built on dying. A "press to continue after 1.5 s" would respect both readers and retriers. |
| Memory cinematic | ≈15-20 s | per line | once per fragment | Fine. |
| Recap before the Slot 2 choice | ≈25-45 s | per line, no skip-all | every Slot 2 visit | Plays in full on every replay of an ending. |
| FINAL_EXCHANGE + epilogue | ≈40-50 s | per line | every ending | No skip-all on replays. |
| Mira, Tobben and other NPC lines | — | — | counters reset per session | Every death restarts their dialogue at line 0, or 2 for Tobben (`village_square.gd:377-382`). Clamping at the last line means extra talks repeat that line. |
| Wren and Mira ask → choose | — | — | if declined, asks again later | OK. |
| Tutorial | ≈30 s of tips in the room | no dismiss button | once ever | Fixed 8 s tips can't be closed early. They're non-blocking, so this is low severity. |
| Quit confirm | 1 extra press | — | every quit | Good: it states the purge cost (`pause_menu.gd:141-151`). |

---

## 7. Findings

### 7.1 Confirmed issues, prioritised

Severity: **S1** can cause an unfair death or a wrong irreversible choice. **S2** causes frequent confusion. **S3** is polish.

**C1. Threats keep running while dialogue is open, and their warning is hidden. S1.**
- **System.** Dialogue / world update.
- **Where.** `world.gd:226-252`; `owner_moves.gd:88-105,313-316`; `owner_director.gd:107-125`; `village_square.gd:277`; `area.gd:51-56`; `hud.gd:388,747`.
- **Repro.**
  1. Arin's room. Reach SUSPECT (≥40, about 38 s, or approach the door).
  2. Talk to Mira and keep reading, without moving, for more than 12 s. Alternatively, at HUNT in the square, open the notice board while the cursor is near.
- **Expected.** Talking is safe, as it is for Arin (which pauses), or else the danger stays visible.
- **Actual.** The idle save-over starts after 8 s and kills in 4 s while you read. Its "SAVING SLOT 1" line goes to the hidden console. The cursor selects a still Rue. The eraser spreads.
- **Fix.** Make `World.is_talking()` return true for `hud.is_dialogue_open() or hud.is_choosing()`, then use it to:
  - pause `owner_moves.update`, the director's rate, `cursor.paused` and `erasure.set_process`;
  - zero `player.idle_time` while talking.

  Or keep the danger as a feature, but keep the console visible (shrink it above the box) and stop the idle save-over from counting reading as idle.
- **Regression test.** In `tests/`: open a dialogue at awareness 45 with `idle_time` 0, step 20 s, and assert `owner_moves.save_progress < 0` and `ending == ""`. Do the same for `choose()`.
- **Canon, save or endings.** No canon change. It prevents unearned deaths, which feed purge and deaths (save data).

**C2. A mashed or default input picks option 0 in irreversible choices. S1.**
- **System.** `choose()`.
- **Where.** `hud.gd:426,439-446`; `world.gd:971-974`; `village_square.gd:250-255`; `arins_room.gd:230-237`.
- **Repro.** Mash E through the Slot 2 recap, or through Wren's or Mira's ask dialogue.
- **Expected.** The choice needs a deliberate input after it appears.
- **Actual.** Two frames after opening, any interact or confirm (including touch E) selects the focused option 0. For Slot 2 that's ESCAPE or RUE, which ends the run. For Wren and Mira it's "join".
- **Fix.** Ignore input for about 0.6 s after `choose()` opens, require a release then a fresh press, or start with no option highlighted until a direction is pressed.
- **Regression test.** Call `choose()`, then simulate `interact` on frames +2…+20, and assert it's still pending.
- **Canon, save or endings.** **Yes, endings:** `record_win`, `endings_seen`, `escort`, `npc_fates`.

**C3. Tap and hold collide on people, notes and doors, and swallow medium-length presses. S2.**
- **System.** GlitchController.
- **Where.** `glitch_controller.gd:17,64-79,127-139`.
- **Repro.** Stand by Mira and press E for about 0.3-0.5 s.
- **Expected.** Talk.
- **Actual.** Nothing happens, because a charge started and was cancelled. At 0.62 s or more, Mira is frozen and awareness goes up by 6.
- **Fix.** If a hold is released before the glitch fires *and* the focused node is interactable, call `tap_interact()`. Consider raising `HOLD_START` on touch to about 0.3 s, or charging only after a separate "glitch armed" cue.
- **Regression test.** Hold for 0.4 s near an NPC, release, and assert the dialogue is open.
- **Canon, save or endings.** `session_glitches` and `total_glitches` feed the "unseen" and "reckless" endings, so accidental glitches change which endings are offered.

**C4. Act cards follow the area, not the story order. S2.**
- **Where.** `world.gd:381-388`; `Story.ACTS`; `village_square.gd:291-294`; `world.gd:447-453`.
- **Repro.** Follow the goal text or Pip east from the square.
- **Expected.** ACT III next.
- **Actual.** ACT IV (Archive) appears, then ACT III later at the well.
- **Fix.** Either number the acts by the guided route (Archive III, OOB IV), or drop numbers for the optional areas.
- **Regression test.** Assert that the order of `Story.ACTS` numbers matches the `guide_point` route.
- **Canon, save or endings.** Presentation only. `acts_seen` is saved by area id, so there's no migration.

**C5. The console truncates and drops lines, with no backlog. S2.**
- **Where.** `hud.gd:17,722-723,756-766`.
- **Repro.** Reach the Edge with Wren.
- **Expected.** Her full line.
- **Actual.** "WREN: I always thought the world ended at the wall behind…" is cut. With Large text, lines over about 60 characters are cut, and only 3 lines are kept.
- **Fix.** Autowrap with a max width and a line budget measured in rendered lines. Long NPC speeches should go to the dialogue box. Optionally add a backlog to the pause menu.
- **Regression test.** For every string routed through `say()` in `Story`, assert that its rendered width at Large text is under the console width, or that it wraps.
- **Canon, save or endings.** Canon lines are lost to the player, but the text isn't changed.

**C6. The console is a FIFO with no priority, and it types while hidden. S2.**
- **Where.** `hud.gd:527-529,716-751`.
- **Repro.** Recover a memory (4 queued lines), then trigger a save-over.
- **Actual.** "SAVING SLOT 1 . . ." appears about 6 s later. Lines said during dialogue or a cinematic type invisibly and may scroll out.
- **Fix.** Add a `priority` flag for system and owner warnings that jumps the queue (or flushes it). Pause typing while the console is hidden.
- **Regression test.** Queue 4 self lines plus 1 priority line, and assert the priority line is visible within 1 s.
- **Canon, save or endings.** No.

**C7. The touch end card says "[ENTER]". S3.**
- **Where.** `world.gd:1035`; `settings.gd:88-90`.
- **Fix.** Make `glyph("confirm")` return "E" when `using_touch`.
- **Regression test.** With `using_touch = true`, assert `glyph("confirm") == "E"`.
- **Canon, save or endings.** No.

**C8. Holding F9 wipes the save in every build, with no confirmation. S2.**
- **Where.** `world.gd:1147-1156`; `owner_memory.gd:507`.
- **Repro.** Hold F9 for 1.5 s during play.
- **Actual.** `OwnerMemory.wipe()` erases all progress and the records. The Settings route needs two presses and is title-only.
- **Fix.** Gate the shortcut behind `debug_enabled()`, or add a confirm dialog. The purge card already offers buttons.
- **Regression test.** In a non-debug build, pressing F9 doesn't call `wipe`.
- **Canon, save or endings.** **Yes, save:** it's destructive.

**C9. Portrait orientation doesn't pause the game. S2 on phones.**
- **Where.** `touch_controls.gd:148-153`.
- **Fix.** While `win.y > win.x` during play, open the pause menu, or set `get_tree().paused`.
- **Regression test.** Simulate a portrait window size and assert the tree is paused.
- **Canon, save or endings.** Unfair awareness and deaths, which feed purge.

**C10. There's no separate screen-shake toggle. S3.**
- **Where.** `screen_fx.gd:83-85,280`; `settings_panel.gd:42`.
- **Fix.** Add `Settings.screen_shake` (bool, or 0-1) applied at `:280`, saved in `[accessibility]`.
- **Regression test.** With shake at 0 and glitch at 1, `canvas_transform.origin == 0` after `shake(6)`.
- **Canon, save or endings.** No.

**C11. The dialogue box text runs under the touch E button. S3.**
- **Where.** `hud.gd:255-266`; `touch_controls.gd:18`.
- **Fix.** On touch, shrink `_dialogue_text` to about 520 px wide, or raise the box by 40 px.
- **Regression test.** Assert that the `_dialogue_text` rect doesn't intersect the E-button circle when `using_touch`.
- **Canon, save or endings.** No.

**C12. Touch controls stay drawn after switching to the keyboard, and the prompt moves under them. S3.**
- **Where.** `touch_controls.gd:51,56,136`; `hud.gd:661`.
- **Fix.** Derive `active` from `Settings.using_touch`, or clear it on key or pad input.
- **Canon, save or endings.** No.

**C13. W/S don't navigate choices. S3.**
- **Where.** `owner_memory.gd:510-515` adds pad events to `ui_up` and `ui_down` but not W and S.
- **Fix.** Add KEY_W and KEY_S to `ui_up` and `ui_down`. Check that it doesn't break text entry, which the game doesn't have.
- **Canon, save or endings.** No.

**C14. Cinematic colour flattens the speakers. S3.**
- **Where.** `world.gd:113,971,1011`; `hud.gd:304-356`.
- **Fix.** Colour and voice each line by prefix (`>` owner, `(` self, `NAME:` npc). The prefixes are already present.
- **Canon, save or endings.** No.

**C15. Title and How to Play control hints are fixed at load. S3.**
- **Where.** `title.gd:210-214`; `how_to_play_panel.gd:37`.
- **Fix.** Rebuild them on `Settings` device change.
- **Canon, save or endings.** No.

**C16. The tip card and the banner overlap. S3.**
- **Where.** `hud.gd:174,181-183`; `tutorial.gd:64`.
- **Fix.** Hide the tip while `banner_text() != ""`.
- **Canon, save or endings.** No.

### 7.2 Hypotheses that need a playtest

- **H1. A choice may soft-lock after pausing.** Resuming leaves no focused option (`pause_menu.gd:96-99`, `hud.gd:426`). Verify in Godot 4.3 whether arrows or the d-pad re-focus a control when nothing has focus. If they don't, a keyboard or gamepad player is stuck at Slot 2 until they use the mouse. Fix either way: re-grab focus on `PauseMenu.close()` when `hud.is_choosing()`.
- **H2. The room window after the door attempt may be too short.** It's about 20 s to SILENCE and HUNT, with a reload in between. Measure how long first-time players take to find the seam, and whether they understand that the reload was the owner and not a bug.
- **H3. The death card may be too short to read.** 3.6 s for a title, a body of up to 3 lines and a tip, at default and Large text. Check whether players read the tip.
- **H4. Per-interaction awareness costs may feel arbitrary.** Mira +8, the note +4, the save point +15. Check whether players connect the meter jump to the talk, or read it as random.
- **H5. Touch occlusion.** The thumb over the console, prompt and console overlap, the hold label, notch handling. Test with a real phone at 19.5:9 and 4:3.
- **H6. Targets can steal the hold.** An NPC within 40 px overrides PHASE, for example Mira by the nook's left wall. Check whether this ever blocks the teaching beat.
- **H7. Large text may overflow the dialogue box** on the longest NPC lines. Render every dialogue line at 14 px against 560×34.
- **H8. Arin may touch-kill during Wren's choice.** Rue is frozen and hidden beside Wren, but `is_talking()` is false during `choose()`, so Arin patrols. Check whether Arin's route ever passes within 8 px of Wren's corner.
- **H9. Replay friction.** Do players replaying for other endings abandon during the 60-90 s of per-line cinematics? Consider skip-all once an ending has been seen (`endings_seen`).
- **H10. The pace of the opening 10 s.** Four simultaneous text channels (§1.3). Is the cyan memory hint at 7 s noticed while the MOVE tip and the act card are up?
- **H11. The tutorial `wren` tip in the room.** Is it remembered by the time the player reaches the square, or is it noise?
- **H12. Repeated dialogue across deaths.** Mira and other NPC counters reset each session. Does repetition after 3 or more deaths read as "the save reset them", which is productive, or as stale content?

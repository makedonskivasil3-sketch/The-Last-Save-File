# Rebuilding the first ten minutes: audit, design, ledger (2026-10-24)

The brief is `docs/prompts/INTRO_HOOK_REBUILD_PROMPT.md`. This file holds:
- the audit of the current opening;
- the design of the new one, with the mission map;
- the five-part ledger;
- the author questions.

The art direction is in `docs/ART_BIBLE.md`.

## 0. Baseline

- **Code:**
  - Head `0b8f0d9`, on `claude/last-save-file-prototype-ljwuq4`, the same as its origin.
  - The code is that of `757f172`; `0b8f0d9` adds only the brief.
  - `main` is `09aeb3b`.
  - The worktree was clean.
  - PR #10 is an open draft. It is not merged and won't be.
- **CI:** green on `44a0866`, `6cdf09b`, `fa0798b` and `757f172`.
- **Suite and bots:** re-run at the start of this pass; see §6.

**Before** evidence (`docs/review/intro/`):
- `before_first_90s.mp4`: a fresh profile, the watched (no-input) path, 90 s of real time.
- `before_stills_every_2s.jpg`: a still every 2 s. For about 80 of those 90 s the screen shows the same dim brown TV frame with two 26-px figures. The "months later" card arrives at about 82 s.

**Measured times** (`tests/tour_timing_oct24.gd`), counted from pressing Start:

| Path | First agency | Film over | In the room | First decision |
|---|---|---|---|---|
| Prompt | 5.0 s (the film's first gate) | 53.5 s | 57.5 s | 59.6 s |
| Hesitant | 11.0 s | 71.5 s | 75.5 s | 77.6 s |
| No input | — | 93.6 s | 97.7 s | 99.8 s |
| Skip | — | 1.1 s | 5.1 s | 7.2 s |

## 1. The diagnosis, verified

| # | Claim in the brief | Evidence | Verdict |
|---|---|---|---|
| 1 | The connection is told, not felt | `opening.gd` lines 1–30: three gates (save together, press at 87%, walk under PAUSE). The only shared act is one hop at a save point (`_together_t`). The contact sheet: the two figures stand still for most of 90 s | **Confirmed** |
| 2 | No mission frames the opening | `world.gd` `current_goal()`: "Get out of Arin's room."; "Explore the village: the road east leads somewhere old." Places, not purposes | **Confirmed** |
| 3 | The film-to-game seam drops the thread | `world.gd` line 148: the 8-line boot (33.1 s at the reading allowance), then a dark room. Nothing from the film continues in it | **Confirmed** |
| 4 | The characters look dated | `illustrated_character.gd` `BODIES`: 21–33 logical px tall. `project.godot`: a 640×360 viewport, stretched 2× | **Confirmed** |
| 5 | Story leaks | §5 below lists each one with file and line | **Confirmed** (8 lines) |
| 6 | The hook is weak | The first 60 s pose no question that needs answering, and teach no verb that is fun to use (all the verbs come later, in the room) | **Confirmed** |

## 2. The new introduction

### What the player learns, and when (one question at a time)

| Time (prompt path) | Question opened | Answered by |
|---|---|---|
| 0:02 | "Who am I?" | The HUD tag over the figure the stick moves: **P2 · RUE (you)** |
| 0:05 | "Who's the other one?" | **P1 · ARIN**, a second player, waiting for her, then waving |
| 0:20 | "What are we doing?" | The quest banner: THE LANTERN FESTIVAL, light five lanterns before sundown |
| 2:20 | "Where did P1 go?" | "PLAYER 1 HAS LEFT THE SESSION" |
| 2:40 | "Why can I still move?" | "PLAYER 2 HAS LEFT THE SESSION", and she still moves. The answer is held back: the CHARACTER FILE, much later |
| 3:00 | "How long?" | The time-lapse: months, the message, SLOT 2 · DELETED, 3 YEARS LATER |
| 3:30 | "Who's in my save?" | The owner, who asks it, and the game that follows |
| 4:00 | "Who kept the fifth lantern burning?" | The first mission. It answers itself only at the Archive |

### Beats

**A. Player 2 has joined.**
- A festival afternoon in the village square, years ago: warm, full, alive. Mira is at her window, Wren hops by the crates, Tobben is at his stall.
- The stick moves Rue at once.
- Arin is driven by a scripted "Player 1" that feels human: he overshoots, waits, waves her over, spins when they succeed.

**B. The mission together.** Four lanterns, each teaching a verb the present-day game uses.

| Lantern | Co-op trick | Verb taught | Used later in |
|---|---|---|---|
| 1 | Arin stands on the plate; the gate opens while he stays | move, interact | everywhere |
| 2 | Tobben watches the fireworks; Rue hides beside Arin as his look sweeps | hide beside someone | Wren's shelter; Arin's look |
| 3 | Both hold [E] together: the "co-op special" | hold to charge | glitches (hold [E]) |
| 4 | The festival spotlight sweeps the plank by the well; cross when it turns | time a crossing | the lamp, the static |

- Each lantern lit fills a festival meter (five pips) and moves the sun toward sundown. It is the first loop: light, sound, a burst, a step closer.
- Rue celebrates with **the girl's habit**: two light taps, then the press, as a hop-hop-flourish. It is seen four times, so that it reads later (the save point in the room; the well; Slot 2).

**C. The break.**
- With four lit, they run for the fifth, by the well. Mid-run Arin stops: **PLAYER 1 HAS LEFT THE SESSION**. His tag greys out, and he idles.
- **First decision:** light the fifth lantern alone, or stay beside Arin.
- Then **PLAYER 2 HAS LEFT THE SESSION**. The controller glyph fades from her tag, and the stick still moves her.
- If the player chose to stay, Rue lights the fifth lantern **by herself** during the time-lapse. That is the impossible act, kept from the old opening.

**D. Time passes** (about 20 s; hold to skip; a static version under reduced motion).
1. Sundown, then night.
2. The decorations fade, and the board's notice changes: FESTIVAL TODAY → FESTIVAL CANCELLED → blank.
3. Seasons turn, and the townsfolk loop their idles, thinner each time.
4. A message slides in on the "screen" layer: **"still have my save?"** A typing indicator answers, and stops.
5. **SLOT 2 · DELETED** stamps across the sky.
6. **3 YEARS LATER**.

Four lanterns are dark. The fifth still burns, the only light that never went out.

**E. The load.**
- The square snaps cold and half-unloaded. A short diegetic HUD types: LOADING SLOT 1 · ARIN / PLAYER 2 · DELETED 3 YEARS AGO / 1 UNRECOGNISED ENTITY.
- Arin turns, owner-driven now, and sees her: **> ...who's in my save?**
- The picture tears, and Rue wakes in Arin's room. The 8-line boot log is not shown again.

**F. The first mission.** "Find who kept the fifth lantern burning: get out of Arin's room." Mira, the first person she meets, remembers the festival.

### Canon notes (see the questions)

The brief's version has Player 1 leave first: the night of the move, the owner walks away, and the girl is still holding the controller. Then the girl stops. This keeps the decided canon:
- The owner never answered.
- She moved away.
- Rue is what she left running.

Nothing here says the owner left the household, or that Rue is the girl. **The order of the two leaves is author question Q1.**

## 3. Missions: a reason for every map

One mission is active at a time. It is shown on the HUD as one line (reason + destination) and listed in the journal. Survival instructions for dangerous places (the Bin, the house, the Edge) follow the mission's own sentence.

| # | Mission | Where | Why the player goes | Verb tested | Ends on |
|---|---|---|---|---|---|
| 1 | THE FIFTH LANTERN | Arin's room | "Find who kept the fifth lantern burning: get out of Arin's room." | the seam, hiding from the owner | Mira remembers the festival |
| 2 | THE LIGHT BY THE WELL | The square | "Reach the fifth lantern by the well; Wren can hide you from Arin." | hiding beside someone | The light falls into the well; the well clicks with her habit |
| 3 | UNDER THE WELL | Out of bounds | "Follow the lantern's light down the well." | timing the floor | Pip, who knows her; a memory |
| 4 | WHO KEPT IT BURNING | The Archive | "Ask the Archive who lit the fifth lantern." | reading records | The festival log: LANTERN 5 · lit by P2 · never saved off. The pointer |
| 5 | WHAT SHE LEFT | Arin's house (optional) | "Find what Player 2 left at Arin's house." | hiding on the chime | The controller |
| 6 | BRING THEM BACK | The Recycle Bin (when someone was deleted) | "Restore who the owner deleted." | sheltering in shadows | A restoration |
| 7 | WHAT'S LEFT OF SLOT 2 | The Edge | "Take the north road to what's left of Slot 2." | leading the cursor away | The fifth lantern, burning at Slot 2; the choice |

The five memories, the truth gates (two truth pieces, then the CHARACTER FILE) and all six endings are unchanged. Missions frame them; they don't gate them.

## 4. Ledger

### Confirmed defects
Found while building. Each was caught by an existing test, which failed first and passes now.
- **D1** (introduced by F2, fixed before commit). The mission line ignored the run's `pointer` flag and read only the save's `met_archivist`. A run holding the pointer still read "Reach the fifth lantern…" instead of the north road (`test_gameplay_consistency.test_goal_keeps_the_way_out_and_adds_the_hint`). `Quests` now takes the flag.
- **D2** (introduced by F2, fixed before commit). A line carrying a festival memory came back as a conversation, so `Npc.interact` dropped the familiar greeting on a reunion (`test_relationships.test_several_sessions_later`, `test_tobben_remembers_without_reintroducing`). Such lines are now marked as usual lines, and the greeting opens them.
- **D4** (in F1, committed, found in verification). The festival never created `TouchControls`. On a phone there was no stick and no E button, so Rue couldn't be moved: only the autopilot after 24 s, or the skip chip. Fixed by adding them; `test_prologue.test_a_phone_can_play_it` fails on the committed prologue. Its drawn tags and emotes now also grow with Large text, as its Labels already did.
- **D3** (introduced by F1, fixed before commit). The prologue used ⏭ and ♪, which the bundled fonts don't have (`test_fonts`).

### Source-backed risks
- **R1.** The new prologue makes the first session longer: the prompt path is about 4 minutes before the room, against 57.5 s now. That is mitigated by playable time from 0:02 instead of 5 s; a hold-skip after the first lantern; and the present reached in ≤ 15 s by skipping.
- **R2.** Replacing the old opening on the title path. `test_first_session` and the replay button point at `Opening`. The old film stays in the code (with its own tests) as the "night she moved" film, but is not on the first-run path. Deleting it is an author decision (Q3).

### Design weaknesses (to fix in this pass)
- **W1–W6:** the diagnosis table above.
- **W7.** Rue's "after" lines and colour lines speak as the girl (§5).

### Completed improvements
- *(Filled in per commit: §6.)*

### Questions for the author
- **Q1.** Who leaves first in the festival: Player 1 (the brief's version, used here) or Player 2?
- **Q2.** The first mission's framing. "Find who kept the fifth lantern burning" (used here), or "Find your way back to Slot 2"?
- **Q3.** Retire the old TV-and-hands film? It is kept, but off the first-run path.
- **Q4.** Final character art: commission an artist from `ART_BIBLE.md`, or approve generated art? Nothing is final until one of these is approved; see the art status in `ART_BIBLE.md`.
- **Q5.** The new first session is about 4 minutes of prologue on the prompt path. Keep it, or trim lantern 4?

## 5. Story leaks (first hour), before fixing

| # | File:line | Text | Problem |
|---|---|---|---|
| L1 | `story.gd:112` | "i was here before. not in this room. in front of it." | Rue claims she sat in front of the screen: that's the girl |
| L2 | `story.gd:146` | "i moved away. i said i'd come back. i came back twice." | Rue says *she* moved away |
| L3 | `story.gd:92` | "a scarf. red. i picked that colour myself." | The girl picked the colour |
| L4 | `story.gd:109,131,…` | The memories speak as "i" with no frame | They read as Rue's own past until the file. **Fix:** a "REPLAY · P2 · 41:07:12" frame on each memory |
| L5 | `story.gd:28` | BOOT "PLAYER 2 . . . [DELETED 3 YEARS AGO]" | Fine, but shown 3 minutes after the prologue said it. **Fix:** the prologue's diagnostic HUD replaces the boot after the prologue |
| L6 | `opening.gd` (old film) | A save at 87% at night | Contradicts the festival as "the last session" if both play. **Fix:** off the first-run path (Q3) |
| L7 | `world.gd` `current_goal()` | "Get out of Arin's room." | No reason (W2) |
| L8 | `STORY_CHRONOLOGY.md` | No festival, no lanterns | **Fix:** add the festival as the last shared session |

## 6. Progress and evidence

### F1. The festival, playable (`scripts/ui/prologue.gd`)

- Beats A–E are built as the state machine `Prologue.Beat` (L1–L4, P1_LEFT, P2_LEFT, TIMELAPSE, LOAD).
- First launch: Start → the festival → Arin's room. The room's 8-line boot log isn't shown again; the festival's LOAD beat is where that information now appears.
- Profiles that have already started never get it. The title's replay button is now **The Festival**, and a replay changes nothing in the save.
- `OwnerMemory` saves two new fields, `festival_seen` and `festival_choice` (lit / stayed / idle / skipped). Saves written before them load with both empty (`test_prologue`).
- Skipping: hold Esc / pause / the touch chip, from any beat, to go straight to the present. The years are always skippable.
- Reduced motion: the time-lapse plays without particles or flicker.
- Every step has its instruction written on screen.
- The P1/P2 tags carry a shape (P1 a triangle, P2 a circle) as well as a colour.
- A player who does nothing is never stuck. An autopilot takes over after 24 s idle, everywhere except the decision. The decision times out after 20 s as "idle", and Rue then lights the fifth lantern herself during the years.

**After evidence** (`docs/review/intro/`):
- `after_*.jpg`: key frames, by `tests/tour_prologue_frames.gd`.
- `after_prompt_first_90s.mp4` and `after_prompt_stills_every_2s.jpg`: the first 90 s on the prompt path, by `tests/tour_intro_capture.gd`. Compare `before_*`.

**Measured times** (`tests/tour_timing_intro.gd`), real time from pressing Start. *Prompt* is autoplay, which is faster than any human; *hesitant* waits 6 s before each act; *no input* touches nothing.

| Path | Control | 1st lantern | P1 leaves | Decision | P2 leaves | 3 YEARS LATER | Present | In the room |
|---|---|---|---|---|---|---|---|---|
| Prompt | 0.1 s | 1.1 s | 15.5 s | 15.6 s (lit) | 17.2 s | 36.7 s | 41.7 s | 47.8 s |
| Hesitant | 7.0 s | 8.1 s | 42.6 s | 49.9 s | 51.5 s | 71.0 s | 76.0 s | 83.0 s |
| No input | — | 25.1 s | 110.5 s | 132.8 s (idle) | 134.4 s | 153.9 s | 158.9 s | 165.0 s |
| Skip | — | — | — | — | — | — | 0.8 s | 6.9 s |

Against §9 of the brief:
- control ≤ 10 s: **met** (0.1 s; 7.0 s hesitant).
- festival + leaves + 3 YEARS LATER ≤ 4 min: **met** (36.7 s prompt; 2:34 with no input).
- skip to the present ≤ 15 s: **met** (0.8 s).
- first choice ≤ 3 min: **met** (15.6 s prompt; 2:13 with no input).
- Co-op success < 45 s: met on the prompt path (the maypole special). A first-time human is not measured: no playtest has been run (§7).

The prompt path is much shorter than §2's estimate of about 4 minutes, because autoplay never hesitates. R1 is smaller than feared.

### F2. Missions (`scripts/story/quests.gd`)

- **One active mission**, shown on the HUD as "TITLE · what to do", in every first-hour map (`test_quests`).
- **Missions are read from the save**, like `Progression`, never from flags of their own. A save written before missions existed opens on the mission its progress has reached, with what it has done marked done. There is nothing new in the save to migrate.
- **Where a place can kill her**, the survival instruction comes first on screen (the Bin's shadow, the house's closets, the Edge's cursor). The mission follows it in the pause menu and the journal. This keeps `test_review_oct22`'s "the survival part comes first", and corrects §3's "survival follows the mission".
- **The quest log** is the journal's LEADS:
  - "Mission: …": now, why, what to do;
  - then the missions done, each with ✓;
  - an optional mission not started isn't listed.
- **The festival, remembered.** Each line is said once ever and recorded as an event on the People page:
  - **Mira**, straight after "You're not Arin. Who are you?": "Wait. I know you. From the festival…" The middle line depends on how the festival ended (lit / stayed / anything else). She ends on "You lit the last one. Nobody else came."
  - **Wren**, after her shelter line: the lantern by the well, still lit.
  - **Tobben**, after his first lines: the fireworks still under his counter.
  - These ride on the speaker's own next line, so no conversation is added and every sequence the tests count is the same. A greeting still opens them on a reunion. That ordering was a regression in `test_relationships`, caught and fixed (see Confirmed defects).
- **The Archive's SESSION LOG** has the festival record:
  - "LANTERN 5 · lit by P2 · never saved off.";
  - when she stayed or nobody chose: "lit by SLOT 2 · controller: none". The record says what it saw, and leaves it unexplained.
- **The fifth lantern** is drawn by the well in the present square: a post, a paper lantern, a faded ribbon, lit.

### F3. The cast, redrawn (`HeroFigure`, `CharacterSheet`, `CharacterArt.figure`)

- **In the world now:** Rue, Arin, Mira, Wren, Tobben, the Archivist, the husk and the title's Rue are `HeroFigure`s:
  - 28–42 px tall instead of 21–33;
  - adult proportions;
  - two-segment rigged limbs and a real walk;
  - faces with whites and highlights;
  - painted light and secondary motion on the scarf and hair.
- **Gameplay is unchanged:** collision boxes, speeds and sight lines are untouched. The title's Rue is drawn at her old size so the title's composition holds.
- **Pip** is scaled to the taller cast (1.3×), with painted shading and inner ears.
- **Pipeline:** `CharacterArt.figure()` picks a valid artist sheet (`assets/characters/<who>/`), else `HeroFigure`, else `IllustratedCharacter`. A broken sheet logs a warning and falls back (`tests/test_character_pipeline.gd`).
- **No sheet exists**, so everything on screen is the procedural figure. `ART_BIBLE.md` says plainly that this is not commercially illustrated final art (Q4).
- **Performance:** the brief allows at most a 10% frame-time regression.
  - **First draft too slow.** As first wired, a `HeroFigure` cost about 940 µs a frame to draw, against about 400 µs for the old figure (six figures, xvfb + llvmpipe). Most of it was GDScript building circle points with cos/sin for every shape, twice (outline and fill).
  - **Now:**
    - circles and ellipses are precomputed unit shapes, transformed natively;
    - a limb is one tapered polygon instead of a quad and two discs;
    - the face and hair know their own outline;
    - Npcs and Arin skip redrawing while well out of view (the margin covers Arin's view cone and a shelter ring).
  - **Result:** drawing six new figures went from 5.65 ms to 3.21 ms a frame. The old figures share the helpers, so they also got cheaper (2.42 → 2.21 ms).
  - **Whole-frame benchmark** (`tests/tour_benchmark.gd`; the old figures from the F2 state against this one; same machine, software renderer, so CPU-bound and pessimistic). Median frame:
    - the square, calm: +4.3% (70.2 → 73.3 ms; three interleaved runs each; p95 +4.6%);
    - room: +5.0%;
    - house: +8.2%;
    - Archive: +3.2%;
    - Edge: +6.1% (two runs each).
  - **All within 10%.** No hardware-GPU number is claimed.
  - **Not measured:** the benchmark's "square, hunted" workload reports itself invalid ("the escort is gone") on the old state and the new alike. That is a pre-existing harness issue, recorded, not fixed here.
- **Before/after**, the same states (`tests/tour_world_cast.gd`):
  - `docs/review/intro/cast_world_room_before_after.jpg`;
  - `cast_world_square_before_after.jpg`;
  - and the style sheets `style_cast_before_after.jpg` and `style_rue_walk_moods.jpg`.

### F4. Story leaks fixed (§5)

| # | Before | After |
|---|---|---|
| L1 | "i was here before. not in this room. in front of it." | "i know this evening. not from this room. from the other side of the glass." |
| L2 | "i moved away. i said i'd come back. i came back twice." | "she moved away. she said she'd come back. ...why do i remember the boxes?" |
| L3 | "a scarf. red. i picked that colour myself." | "a scarf. red. somebody picked that colour for me, carefully." |
| L4 | Memories in "i", with no frame | Each plays in a frame: "REPLAY · P2 · 00:00:41" (the first evening) … "REPLAY · P2 · 41:07:12" (the last time); the deletion "LOG · SLOT 02 · AFTER THE LAST SESSION"; the planted one "REPLAY · NO SIGNATURE". It shows with speaker labels off, and opens the memory's journal page |
| L5 | The boot repeated after the festival | Not shown after the festival (F1) |
| L6 | The old film contradicts the festival | Off the first-run path (Q3) |
| L7 | "Get out of Arin's room." | "THE FIFTH LANTERN · Find who kept the fifth lantern burning: get out of Arin's room." (F2) |
| L8 | No festival in the chronology | Rows added: the festival on moving day, the lantern through the years, the load. The argument in memory 4 is the moment Player 1 left (41:07:12) |

**Payoffs:**
- The fifth lantern is drawn beside Slot 2 at the Edge ("lantern_05 · lit"). It holds steady under reduced flashing.
- In the message ending, with every memory, the owner says: "> the festival. i walked off before the last lantern. i never saw who lit it."

`tests/test_story_leaks.gd` fails on the lines and frames as they were. It checks:
- no line of Rue's before the file claims the girl's life;
- every memory has its frame;
- the frame shows with speaker labels off;
- the journal page keeps it.

## 7. Against the brief's acceptance criteria (§9)

| Criterion | Result | Evidence |
|---|---|---|
| Control ≤ 10 s | **Met:** 0.1 s (hesitant 7.0 s) | `tour_timing_intro.gd`, §6 F1 |
| Festival + leaves + 3 YEARS LATER ≤ 4 min (prompt) | **Met:** 36.7 s (no input 2:34) | same |
| Skip reaches the present ≤ 15 s | **Met:** 0.8 s | `test_prologue`, the timing tour |
| First choice ≤ 3 min | **Met:** 15.6 s (no input 2:13) | same |
| Every first-hour map transition has a mission | **Met** for all 7 maps | `test_quests` |
| No chronology contradictions | **Met** for the pairs checked | `STORY_CHRONOLOGY.md`, "Contradictions checked" |
| Rue and Arin redrawn, with fallback | **Met** for the whole cast. Procedural, not final art | `test_character_pipeline`, `cast_world_*` |
| ≤ 10% frame-time regression | **Met** on the software renderer: worst +8.2% (house); square +4.3% | §6 F3 |
| Suite green | **Met:** 680/681, then the stale manifest regenerated and passing | `RELEASE_READINESS.md` |
| Bots no worse (A/B) | **Inconclusive:** baseline 4/5, this 4/5 twice, the failing route differs by run | same |
| Exports and web green | **Met:** 3 exports exit 0; the web check passes | same |
| Old saves load | **Met** | `test_prologue`, `test_quests` |
| Hook targets, measured on people | **Not met:** no unfamiliar players were available. Protocol ready | `PLAYTEST_PLAN.md` |

**Asset status:**
- No art was bought, generated or commissioned. No voices were generated or cloned. Nothing was published.
- The new lines (festival callbacks, the owner's line in the message ending) are text-only in the voice manifest.

**Author decisions, with recommendations:**
- **Q1** (who leaves first): keep Player 1 leaving first. It matches memory 4's argument and the owner's notes.
- **Q2** (mission framing): keep "Find who kept the fifth lantern burning". The answer, a Slot-2 record with no controller held, is a truth clue that doesn't spoil the file.
- **Q3** (the old film): retire it after a playtest round confirms the festival works. It is kept but unreachable on a first run, with only a replay path.
- **Q4** (final art): commission a test character (Rue) from `ART_BIBLE.md`'s brief before deciding. The procedural cast is a clear step up, but not the bar the author described.
- **Q5** (trim lantern 4): keep it until playtests show the length (~37 s autoplayed, likely 1.5–3 min for a person) is a problem. That length is an estimate, not a measurement.

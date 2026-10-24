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
- *(See §6 for anything found while building.)*

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

*(Filled in as each commit group lands.)*

# Comprehension, identity payoff, visual credibility and fairness (2026-11-04)

**Brief:** "Comprehension, Emotional Payoff, Visual Credibility, and Fairness" (4 November 2026).
**Starting point:** branch `claude/last-save-file-prototype-ljwuq4` at `a3c9c28`. `main` is still `adf2710`, and no newer branch exists.

**Evidence classes used:**
- **source:** reading the code;
- **automated:** a test or bot;
- **visual:** a capture looked at;
- **human:** a playtest;
- **hardware:** a real device.

No human or hardware evidence exists yet for anything here.

## 1. The four risks, assessed

| Risk | What the evidence says | Class | Status after this pass |
|---|---|---|---|
| **1. The premise and its systems are hard to follow** | Many concepts, each introduced by action, none tested on a person. Two were shown before they were useful (see the table below) | source | **Unverified.** The protocol is in §6 |
| **2. Players may finish without the identity payoff** | **Corrected claim:** RUE does *not* need two runs. `test_full_game_rue_one_playthrough` reached it in one session, 277 s, with no ending in between and no death, at awareness 100 with two reloads. The real problem was guidance: the hint said only "someone who has watched you", nothing pointed to where to go when the fifth memory landed, and Slot 2 gave no warning that a lead was still open | automated | **Guidance fixed** (§3). Discovery by humans is unverified |
| **3. Provisional graphics read as unfinished** | Developer-looking labels at the Edge ("TODO: art", "tree_04.png (missing)") looked like leftovers. The other areas are coherent, but most are "functional", not finished (§5) | visual | **The Edge labels and seam are fixed.** Art across the campaign is still functional |
| **4. Late-game escalation undermines trust** | **Two verified defects:**<br>• a reload could kill Rue while she had no control;<br>• the Edge's extra patience reset after a death elsewhere.<br>Permanent save loss at purge 6 is a design question for the author | automated plus source | **Both defects fixed with tests.** The loss policy goes to the author (§4.3) |

### Claims checked rather than repeated

| Earlier claim | Verdict |
|---|---|
| "RUE requires two runs" | **Wrong.** It was a limit of the bot. One continuous playthrough works (above) |
| "Only two areas are finished" | **Imprecise.** Two areas had a calibration art pass. "Finished" is defined per category in §5, and no area is "approved final" |
| "Yesterday's CI proved unfairness" | **Partly.** The purge-5 failure in CI run 41721851052 had two parts. The Edge eraser death was ordinary risk. The Square death, 0.4 s after "the owner reloaded", was a real defect: Arin could touch Rue during the reload drag. Reproduced in `test_fairness`, then fixed |
| "Act numbers appear out of sequence" | **Already fixed** (UI-6): chapters follow story milestones. The unused location-numbered `Story.ACTS` table is removed |
| "The lantern objective asks who lit it" | **Fixed** in `61b4ce6` |

## 2. When each concept is introduced (source inspection)

| Concept | First appearance | Why it's needed then | How it's shown | What the player must understand | Later reinforcement |
|---|---|---|---|---|---|
| **Rue versus the girl** | The festival: two players, two figures | The fifth lantern is Rue's first impossible act | The second player leaves; Rue moves on her own | "The figure I control kept going after its player left." **Not** that she isn't the girl: that is the late truth | Mira's and Wren's truth lines; the CHARACTER FILE |
| **The Owner versus Arin** | The present room: the owner's notes in the console; Arin in the Square | The first threat | Arin walks a route; the owner's words appear as `>` lines | Someone outside moves Arin | The cursor at the Edge; the Owner's reload banner |
| **Then versus now** | Memory card, then festival, then the cut to the present | The handoff | A time card, colour drained, the room changed | The festival is past; this is three years later | Mira's room changes; the well |
| **Recordings versus live speech** | The well, typed and not spoken | The first answer to "who kept it burning" | The same framing each time; the journal says "played back" | The well keeps recordings and is not contact | Wren at the well; the Archive's festival log |
| **Slots** | **The HUD save header "SLOT 1 · ARIN · LV 7" from the first second** | It isn't needed until the Edge | Text only | Nothing at first. Shown **before it is useful** | The Archive's pointer to Slot 2; the Edge |
| **Awareness and purge** | The meter in the room; purge on the death card | The first death | The meter rises when seen. The death card names the cause and counts toward the limit | "Being seen is bad. Deaths add up." | Warnings, and the purge warning at 5 |
| **Glitches** | The cracked wall in Arin's room | The first exit | Phase through it; the price is shown while charging (`test_charging_shows_the_price`) | Tap to act; hold to glitch; it costs attention | A new glitch with each memory |
| **Memories** | The room's crack | The first payoff | A cinematic, then "MEMORY RECOVERED 1 / 5" | They survive death and endings | Journal; title screen |
| **Truth pieces** | After all five memories | The identity route | A character says what they noticed | "Someone noticed something about me." **Now named in the hint** | The journal's leads |
| **Escorts** | Wren's ask in the Square | Her ending | A choice; she follows | She can come, and can be lost | Mira's escort |
| **The Bin** | East of the Archive, once someone is deleted | Restoring someone | A sweep warning; system files give shelter | Collect between sweeps; hide during them | Restored people's lines |
| **Safe stopping** | The pause menu, "Save and exit" | Whenever the player stops | The menu says when and why it is allowed (`test_the_pause_menu_says_when_and_why`) | Calm means free; danger costs | The title screen resumes |

**Introduced before they are useful:**
- **The slot header:** "SLOT 1 · ARIN" reads as UI from the first second, and uses a term the story only explains at the Edge.
- **The awareness meter in a room with no threat yet.**

Both are deliberate framing: you're in someone else's save. Whether they confuse people is question 1 of the protocol. **Not changed** without that evidence.

**Terms that overlap:**
- "save", "slot" and "session" all mean "the file";
- "memories", "pieces", "fragments" and "truth pieces".

In player-facing text, "memories" and "what they noticed" are kept apart. "Fragments" appears only in code.

## 3. The RUE route: dependencies and discovery (verified)

```
fresh profile
  ├─ 5 memories   room (crack) · out of bounds (well ledge) · Archive · Edge ×2
  │                  └─ the last two are at the Edge, past the cursor
  ├─ 2 truth pieces, from any of:
  │     Wren    (Square)            needs all 5 memories; her conversation priority:
  │                                 escort > restore > well mark > death
  │                                 > ending recall > service light > open promise
  │                                 > TRUTH
  │     Mira    (Arin's room)       needs all 5 memories
  │     Tobben  (stall)             needs the guestbook restored (the Bin);
  │                                 no memory requirement
  │     Pip     (FIRST HITBOX,      needs Pip found and all 5 memories
  │              out of bounds)
  ├─ the CHARACTER FILE (Archive desk), read to its last line → knows_truth
  └─ Slot 2: written with all 5 memories and the truth → RUE (otherwise escape)
```

- **Mandatory:**
  - all five memories;
  - two pieces;
  - the file read whole;
  - Slot 2.
- **Alternatives:** any two of the four witnesses. Tobben is the only one available before the Edge.
- **Hidden conditions:**
  - pieces need all five memories, except Tobben's;
  - Wren says other things first, by her priority order;
  - Tobben needs the Bin and his guestbook;
  - Pip's hitbox appears only after all five memories.
- **Missable:**
  - nothing permanently;
  - pieces, memories and the truth are saved, and survive death and endings.
- **Recovery:**
  - after a death, everything above is kept;
  - the first Edge death doesn't count toward the purge;
  - a deleted Wren is restored from the Bin.
- **Learned only after an ending:** nothing is required. Since `61b4ce6`, an ordinary escape adds a lead line.
- **One continuous playthrough:** **proven possible** (automated). Human discoverability is unverified.

**The layered guidance, now implemented:**
1. **An early question:** the fifth lantern; "who kept it burning" (`61b4ce6`).
2. **A reframing observation:** Mira, Wren, Tobben and Pip each notice something that doesn't fit.
3. **The invitation, when the requirements become real:** the fifth memory now says *(all five. it still doesn't say what i am. the archive keeps a file on me, and the people back in the square have been watching.)*
4. **A practical destination:**
   - the goal hint and journal now **name** who and where, for example "Ask those who watched you: Mira, in Arin's room, Wren, in the square";
   - then "Something on the Archivist's desk has your name on it now".
5. **An understandable commitment point:** when Rue starts writing into Slot 2 with the file unread, she says once that finishing ends the run, that she can step out and go back, and that memories are kept.

None of these says what she is (`test_gameplay_consistency`).

## 4. Late-game fairness

### 4.1 How the spiral works (source plus automated)

These factors feed each other:
- purge (deaths and quits, 6 = save lost);
- awareness (sight, glitches);
- previous deaths (the static seeds where Rue died, `Area.start_erasure`);
- reload position (`OwnerMoves._pick_snapshot`);
- Arin's patrol (including Arin guarding a husk);
- Edge mercy (the first Edge death is free);
- Edge grace (`grace_time`, growing with Edge eraser deaths);
- anchors (well checkpoints);
- helpers (Wren, Pip) and available glitches.

### 4.2 Findings

| Investigated | Result | Class | Action |
|---|---|---|---|
| A reload landing Rue next to a threat, or killing her during the drag | **Defect.** Arin kept patrolling during the 0.9 s drag, with Rue frozen. His touch check still ran. The fallback, used when no moment was safe, picked the oldest moment even if it was beside Arin | Unavoidable failure | **Fixed:**<br>• Arin is held, and the cursor blind, for the drag and the grace beat (`OwnerAvatar.held`; reloads never undo it);<br>• the fallback picks the moment furthest from any threat.<br>Reproduced first in `test_fairness` |
| The Edge grace resetting after a death outside the Edge | **Defect.** A struggling player got the harshest Edge back | Unclear, and punishes struggle twice | **Fixed:** kept until an ending, capped. `test_edge` updated as a documented change |
| Static repeated near earlier death positions | Intended. It is the Owner learning, and the seeds are visible as cracks before they spread | Intended challenge | None. The human round should check it is noticed |
| Returning to the Edge after dying elsewhere | Fine now that the grace persists. The cursor and Arin are rebuilt | Intended | — |
| Losing a helper while recovering | Wren can be deleted and restored from the Bin, and the save says so | Intended, recoverable | — |
| Failure before the warning can be read | Reading holds the Owner (`World._update_reading_hold`). Cards hold threats (P8-1) | Already fixed | — |
| CI purge-5 eraser death at the Edge | The bot sprinted into spreading static | Bot limitation | — |

### 4.3 The trust contract, and the loss policy

1. **Every lethal event has a recognisable cause.** The death card names it (`test_deaths_explain_themselves`). Kept.
2. **A warning gives time to act:**
   - the Edge countdown, the cracks, the save ring, the sweep warning;
   - the timings live per encounter in the area scripts.
3. **Loading, reading and lost control never cause damage:**
   - reading holds the Owner;
   - **a reload now holds Arin and the cursor** (this pass).
4. **Recovery never lands in an immediate trap:** the reload fallback is fixed, and resume never lands inside geometry (`test_never_resumes_inside_something`).
5. **An earlier mistake never creates an unexplained loop:** the Edge grace now persists. The static seeds are visible.
6. **Safe stopping stays safe:** `test_save_contract`, `test_suspend`.
7. **Permanent loss is announced before it happens:**
   - the death card at purge 5 says "one more death or quit, and the owner won't let you back in. ever.";
   - the purge screen asks twice before wiping.
8. **Emotional investment is treated in proportion:** this one is **open** (below).

**Permanent loss today:** at purge 6 the save is gone; restoring means every memory, ending and Records entry is forgotten.

**Recommendation for the author** (not implemented, since it is a creative decision):

| | Today | Option A (recommended): **the save remembers the player** | Option B: keep as is, add an opt-in |
|---|---|---|---|
| At purge 6 | Everything wiped | The run is lost and the Owner "wins" that run. **The Records (endings seen) and the journal survive**, and the next new game is told what the Owner learned | Unchanged by default. "Owner pace: Gentle" also stops at purge 5 |
| Tension kept by | Fear of total loss | The world changes: the Owner starts stronger, routes are patched, a relationship is damaged | The same as today |
| Risk | A late, total, unrecoverable loss of hours, which is a refund and review risk | Less dread at the very end | Gentle players never see the ending they fear |

**Not changed this pass.** Decision owner: the author, before the second player round.

## 5. The eight areas, by category (visual inspection)

Scale: **P** placeholder, **F** functional, **C** consistent with the target, **A** approved final.

Captures: `docs/review/calibration_2026-11-03/area_*.jpg`, 1280×720, software renderer.

| Area | Composition | Materials | Lighting | Character scale | Interactables | Hazards | Entrances | Storytelling | A11y |
|---|---|---|---|---|---|---|---|---|---|
| Arin's room | C | F | C | F | C | — | C | C | C |
| Square | C | F | C | F | C | C | C | C | C |
| Arin's house | F | F | F | F | F | C | F | C | C |
| Archive | C | F | C | F | C | — | C | C | C |
| Workshop | C | F | C | F | C | — | C | C | C |
| Out of Bounds | F | F | F | F | C | C | F | F | C |
| Recycle Bin | F | F | F | F | C | C | F | F | C |
| The Edge | **C (this pass)** | F | F | F | C | C | **C** | **C** | C |

- **No area is A.** "Approved final" needs the author's approval.
- **Animation, performance, and hardware/GPU frame times** are not graded from captures: that needs motion review and a real GPU.
- **Character scale is F everywhere:** figures are about 26 px tall at 640×360, readable but small. A scale change touches collision, camera, interaction distances and sightlines together. It **needs a controlled comparison first**: proposed as two builds side by side in the next round, not done here.

**Edge before and after:** `docs/review/calibration_2026-11-03/edge_before_after.jpg`.

**The production slice proposed to finish first:** the Archive, then the workshop, then the service hatch, then the well. It has exploration, a relationship (the Archivist, then Wren's service-light reaction), a useful action (the repair), a readable threat (the hatch's out-of-bounds floor), a consequence (the shortcut) and a quiet payoff (the named fifth frame).

**Asset briefs, before any commission** (authorisation needed):
- Rue's turnaround and walk cycle, 4 directions, at 32 px;
- portrait variants for 6 characters;
- an Edge tileset (drawn, outline and void tiers);
- a workshop props sheet.

## 6. The comprehension protocol (5–8 unfamiliar players)

Use the playtest kit (`docs/playtest/RUN_A_ROUND.md`) for setup. Use regular, disposable profiles, and never touch a tester's real save.

Observe silently. Ask **open questions first**, at natural stops (after the festival, at the first escape, at the well, at the Archive, after an ending). Never offer choices until the open answer is recorded.

1. Who are you controlling?
2. Who is controlling Arin?
3. Who was the other person at the festival?
4. What do you think the well is doing?
5. What are you trying to do now?
6. What happens if you stop playing safely?
7. What do you think the Owner remembers?
8. (After an ending) Is there anything you didn't get to find out?

**Record for each answer:**
- their words;
- their confidence (sure, guessing, no idea);
- the moment that produced a misunderstanding;
- any help given.

**Report denominators** ("3 of 5"), never percentages from five people.

**Status:** prepared. **Comprehension is unverified**: no participants yet.

## 7. Other endings: keeping them valid

| Ending | Preparation | Consequence | Meaning | Closure |
|---|---|---|---|---|
| Escape | Slot 2's whole route | Slot 2 is hers | Survival | Complete, plus one quiet lead (not "you missed it") |
| Wren | Her game, promise and escort | Wren gets a game of her own | Generosity | Complete |
| Message | Slot 2's question | The Owner reads it; the purge stops | Reconciliation | Complete. Restores people |
| Unseen | Never seen, ≤1 glitch | She walks off the map | Being free by being unnoticed | Complete |
| Overwrite | Reckless play | Slot 1 is hers | Revenge, and its cost | Complete, deliberately bleak |
| RUE | The truth | Her own name and colour | Identity | Complete |

The return invitation after an escape now suggests a perspective ("the ones who watched me might know the rest"), not a failure.

## 8. The demo endpoint

| Candidate | Identities clear | Meaningful action | A character worth caring about | Readable danger | Lasting consequence | Unresolved question |
|---|---|---|---|---|---|---|
| The Archive entrance (`?demo=1`) | Partly | Getting in | Wren, briefly | The Square | — | Strong |
| **The workshop, ending after Wren notices the light (`?demo=workshop`)** | Yes | **Repairing the lamp** | **Wren's reaction** | The Square, the hatch floor | **The shortcut stays open** | "Who kept it burning?" |

**Recommendation:** the workshop endpoint. It is already bounded and keeps its own save (DM-2). The final choice belongs to the author, after the player round.

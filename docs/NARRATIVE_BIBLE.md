# THE LAST SAVE FILE — Narrative Bible

*Canon reference derived only from the shipped game text and logic. Every claim marked
**CONFIRMED** is backed by a `file:line` reference. **INTERPRETATION** is a reading the text
supports but does not state outright. **PROPOSAL** is a suggestion that needs author approval. Nothing
here is canon until it is confirmed in code.*

Sources: `scripts/story/story.gd` (abbreviated **S**), `scripts/world/areas/*.gd`,
`scripts/world/world.gd` (**W**), `scripts/autoload/owner_memory.gd` (**OM**),
`scripts/owner/owner_director.gd` (**OD**), `scripts/owner/owner_moves.gd` (**OMv**),
`scripts/world/tutorial.gd`, `scripts/player/glitch.gd`, `docs/STORY_SCRIPT.md` (**SS**), `README.md`.

Where `docs/STORY_SCRIPT.md` and code disagree, **code wins** (SS calls itself the "readable version"
of story.gd, SS:3-5, but it has drifted; see §10).

---

## 1. Established facts

### 1.1 CONFIRMED

| Fact | Evidence |
| --- | --- |
| Two people shared one console and one couch, with two controllers. | "two people on one couch. one screen. one save." S:94; "we used to play this on the couch at mum's. two controllers." S:178 |
| One played **Arin** in slot 1; the other made their own character in slot 2. | "\"you be arin,\" they said. \"i'll make my own.\"" S:95; "NEW GAME. SLOT 02. ENTER NAME: _" S:116 |
| The slot-2 character's name is three letters: **RUE**. | "three letters." S:117; `SECOND_PLAYER_NAME := "RUE"` S:20; "my name was RUE. slot 2 was mine." S:144 |
| Rue's look: red scarf, cowlick hair, yellow raincoat, shoes, face. Picked by the player; it was raining the day they made her. | S:78-82 ("i picked that colour myself", "it was raining the day we made me") |
| Rue walked into the village well by accident, clipped out of the map; a fox fell after her. They laughed, and saved. | S:105-107 |
| The fox is **Pip**, Rue's fox. It was never saved back in, so the deletion never reached it. | S:14-16 (header); "nobody saves out here. so nobody could delete out here." S:263; "PIP · RUE'S · LV 31. it was always your fox." S:330 |
| ARIN & RUE beat the forest boss together and signed Tobben's guest book. | recycle_bin.gd:186 |
| Slot 2's last record: RUE, LV 31, 41:07:12 played, last played the night before the move. | recycle_bin.gd:174-176 |
| The second player **moved away** in the summer, promised to visit every weekend, came twice. | S:127-132, S:179 |
| Parting words: "you'll visit." "every weekend." "you won't." / "it's my console anyway." | S:128-129 |
| The second controller stayed on the floor; in-game it is still under the couch in Arin's house. | S:130; arins_house.gd:149-151; "i never moved it. i couldn't." S:235 |
| Rue's last message (in the bin): "i'm not gone, i'm just moving. keep my slot. we'll finish it when i visit. promise?" | recycle_bin.gd:206 (full text only with 5 memories, :205) |
| Months later the second player asked: "still have my save?" There was no answer. | S:139-140; S:182 |
| The owner drafted a reply, never sent it: "hey. i know it's been ages. yes i still have your sa" — deleted the same night as slot 2. | recycle_bin.gd:194-196 |
| The owner deleted slot 2 at night, telling themself it was for space; the card wasn't half full. | S:141, S:181 |
| The owner's stated reason: "the empty slot was easier than the waiting." | S:183 |
| The owner kept "her save for two years" and walked Arin past where her character used to stand. | S:180 |
| slot2_backup.sav and rue_last_message.txt were "deleted 3 years ago". | recycle_bin.gd:174, :204 |
| The player character is what's left of the deleted slot-2 save, waking in slot 1. | S:10-12; BOOT "ENTITY SLOT: 02 / slot 02 does not exist." S:29-30 |
| The owner is never seen; they type into the console and drive Arin. | tutorial.gd:20 ("ARIN IS THE OWNER — The owner plays as Arin."); OD:93-94 |
| Arin's save: LV 7, 14:22:00; the owner has 14 hours in it and won't start a new one. | S:24; archive.gd:165; "that's fourteen hours" S:443 |
| The town is **Ashvale**. | S:252; village_square.gd:72 |
| The **Archivist** was cut before the game shipped; the owner has never seen them and can't delete them. | archive.gd:101-102 |
| Cut content also includes save slot 2 and the north road. | archive.gd:153-156 |
| **Mira** lives in Arin's room, has never left it, and first notices you. | arins_room.gd:34-41; S:280 |
| **Wren** is a child in the square who hides you and wants to see the Edge before she is deleted. | village_square.gd:32-38; S:339 |
| **Tobben** is the shopkeeper, must report you ("It's in my script"), and has lost the second name in his guest book. | village_square.gd:39-45 |
| The owner's notes (8, one per run from run 2) tell the owner's side. | S:176-185, S:190-198 |
| The owner planted a false memory, "YOU LEFT FIRST". | S:151-162; village_square.gd:125-132 |

### 1.2 INTERPRETATION

- The second player is a girl/woman. The owner refers to her as "she/her" throughout (S:179-183, 205,
  233, 235); the unseen epilogue calls the intruder "a girl in a yellow raincoat" (S:492); README:226
  says "herself". SS:36 says *they* (see §10).
- "at mum's" (S:178) plus "my half of the room already empty" (S:127) suggests the two shared a room,
  possibly siblings. The game never says friend or sibling; SS:11 says "Two friends".
- The in-game Arin's house is a mirror of the real house: a couch, two controllers, a photo of two kids
  with one face pixelated out (arins_house.gd:132-135), an emptied "PLAYER 2. KNOCK FIRST." room
  (arins_house.gd:156-159).

---

## 2. Deliberate mysteries

| Mystery | Withheld by | Where it is (eventually) revealed |
| --- | --- | --- |
| Who/what the intruder is | BOOT "ENTITY NAME: none" S:29; "this body isn't mine" S:51 | Fragment 3 "slot 02. that's what the save said about me" S:120; Fragment 5 S:144 |
| The intruder's name | "[the name has been scratched out of this memory]" S:118; "a name they can no longer remember" S:8 | Fragment 5 "my name was RUE" S:144. **Leaks earlier**: Pip S:260, slot2_backup recycle_bin.gd:175, guest book page :186, Tobben recall S:608 (§10.6) |
| Why the owner hates/fears the intruder | "the one they wanted instead of me... why did i think that?" S:59 | Owner notes 5-8 S:181-184; Fragment 5 S:139-143 |
| What happened between the two players | False fragment tells the owner's version S:156-158 | Fragments 4-5 S:127-143; notes 3, 6, 7 |
| Whether the owner ever answered "still have my save?" | Fragment 5 "no answer." S:140 | owner_draft.txt recycle_bin.gd:194-199 (the unsent reply) |
| Rue's last message | Redacted with █ until all 5 memories, recycle_bin.gd:209-210 | recycle_bin.gd:206-207 |
| What Slot 2 is | Archivist: "a slot the owner never used" archive.gd:104 | Fragments 3 and 5: it was Rue's |
| The owner's identity | Never named; only ">" lines | **Never revealed.** The epilogues stay off-screen ("somewhere outside the screen" S:367, 475) |
| Whether the owner will reconcile | — | Only the message ending with 5 memories: "i'm going to call you. the real you." S:480 |

---

## 3. Characters

### 3.0 Avatar vs person (how the game distinguishes them) — CONFIRMED

| Layer | Name in game | Evidence |
| --- | --- | --- |
| Real person 1 (slot 1) | "the owner" — never named | OD:93-94 ("owner" voice); epilogues "outside the screen" S:367 |
| Avatar 1 | **Arin**, the owner's character | tutorial.gd:20; "the character in the bed isn't the one they made" S:499 |
| Real person 2 (slot 2) | "she", "the second player", "the real you" | S:179-183; S:480 |
| Avatar 2 / the intruder | **Rue** — the deleted save carrying the player's memories | S:10-13; memories are told from the player's seat: "my character walked into the well" S:105, "i typed it" S:117 |

The owner speaks of the person and her character separately ("where her character used to stand",
S:180). Rue's memories, however, are first-person *player* memories ("i was here before. not in this
room. in front of it." S:98). INTERPRETATION: the intruder is save data that remembers being played.

### 3.1 Rue (the intruder, you)

- **Role (CONFIRMED):** player character; slot 2's deleted character; restored one body part per memory (S:77-83).
- **Motivation:** get out ("You want out... you're the only one who can actually leave" archive.gd:103);
  then, through the fragments, remember who she was.
- **Knows:** almost nothing at start ("i remember dying. i don't remember living." S:55). Gains the backstory only through optional fragments.
- **Misunderstands:** thinks she is unwanted ("the one they wanted instead of me" S:59) before knowing why;
  nearly accepts the false memory ("it felt like mine. it was so close." S:161).
- **Relationship to others:** Pip's owner; Wren's protector; Mira's first visitor; the owner's deleted friend.
- **Voice:** lowercase, in parentheses on the console, short, honest, scared, dry. Samples:
  "it hurts less every time. that's worse." S:54 · "can data smell like dust?" S:60 ·
  "(you had two slots. now you have one. now you know.)" S:444 · "(hi.)" S:424.
- **Strongest scene:** the RUE final exchange, S:420-425, followed by EPILOGUE_TRUE S:365-372.
- **Endings role:** chooses all six endings (W:939-979).
- **Contradictions:** pronoun (code "she", SS "they"); name known before "remembered" (§10.6).

### 3.2 The owner

- **Role (CONFIRMED):** antagonist; the real person who plays Arin; types on the console; deletes, reloads,
  saves over, drags props, empties the bin (OMv:3-24; recycle_bin.gd:130).
- **Motivation (text-supported):** keep the one save they have left ("it's all i have left of it." S:203);
  avoid the pain of waiting ("the empty slot was easier than the waiting." S:183); ambivalence ("i want you gone. i want you to stay." S:184).
- **Knows:** everything in OwnerMemory (survives deaths/quits/crashes, OM:1-6). Learns your routes, seams, helpers (OM:468-489).
- **Misunderstands:** thinks you are a bug/intruder; recognises you gradually: 3 memories "...you move like someone i used to know." / 5 memories "no. you can't be. i deleted you." (S:243-246, OD:231-237).
  The planted memory shows how they misremember the parting ("you wanted to be forgotten. so i forgot you." S:158).
- **Relationship to Rue:** her former couch partner; deleted her save.
- **Voice:** lowercase, `>`-prefixed, curt; bored → irritated → cruel → cracking (SS:28). Samples:
  "nope." OD:149 · "huh. arin doesn't walk like that." OD:200 · "i count them too." S:719 ·
  "> STOP. that's fourteen hours. that's all i have left of" S:443 · "> stop. stop. please." S:171.
- **Strongest scene:** the slot-2 recap (S:214-239), every run summarized in their voice, then "> ...go on, then. whose name goes in it."
- **Endings role:** reacts in every final exchange (S:414-446) and in ENDING_RETURN next run (S:549-556).
- **Contradictions:** whether they know Slot 2 exists (§10.1); order of deletion vs message (§10.3).

### 3.3 Arin (avatar)

- **Role (CONFIRMED):** the owner's character in slot 1; patrols the square with a light cone (village_square.gd:161-171), comes home to Arin's house (arins_house.gd:103-119), guards Slot 2 in the final fight (the_edge.gd:229-244). Touch = death "overwritten" (W:875; S:739).
- **Motivation:** none of its own; silent; "the owner plays as Arin" (tutorial.gd:20). Purged room: "The real Arin", lines `"..."` (arins_room.gd:256-264).
- **Voice:** silent. Only the owner speaks about Arin: "arin. go and get it." S:170; "arin's home." arins_house.gd:119.
- **Endings:** overwrite ending replaces Arin in slot 1 with Rue (S:496-502).
- **Contradictions:** pronoun "him" (S:552, the_edge.gd:40) vs "them/they" (S:740-741; tutorial.gd:27).

### 3.4 Mira

- **Role (CONFIRMED):** NPC in Arin's room; greets you as Arin, then realises you're not (arins_room.gd:34-41).
- **Motivation:** to be remembered as more than a line: "MIRA WAS HERE. I TALK. I REMEMBER." S:310; "I've never been outside this room." S:280.
- **Knows:** "Arin never talks about the other one. The one who used to sit next to them." arins_room.gd:40. Remembers your past runs (S:586-603).
- **Misunderstands:** nothing the text marks as wrong; her belief that "The owner reads the board" (S:282) is borne out by "...mira wrote this?" (W:534). After a reset she mistakes you for Arin again (S:295-299).
- **Relationship to Rue:** first witness; directs her to Wren (arins_room.gd:39).
- **Voice:** warm, worried, full sentences, capitalised. "They're going to notice you. They notice everything." · "There. MIRA WAS HERE. Now it's true." S:292.
- **Strongest scene:** MIRA_PIN_SCENE S:289-294.
- **Fates:** deleted at SILENCE if in the room (arins_room.gd:178-184); restricted from purge ≥1 (arins_room.gd:92-93); deleted from purge ≥3 (W:792); reset permanently if the ring fills (W:544-552); "lost" if you die escorting her (W:890-891).
- **Endings role:** epilogue lines (S:519-522) and recap (S:226-231).
- **Contradictions:** "Arin walks past my window every morning" (S:281) though she lives *in* Arin's room; dead "carried" note branch (§10.2).

### 3.5 Wren

- **Role (CONFIRMED):** child in the square; hides you (`hide_radius`, village_square.gd:352); asks to be taken to the Edge (S:339).
- **Motivation:** "I want to see the Edge. Before they delete me." S:339.
- **Knows:** that Rue's player once fell in the well ("They fell in the well once. It was funny." village_square.gd:37); that the owner can't see what she stands beside, but not why (village_square.gd:34).
- **Misunderstands:** says "The Archivist says I'm cut content now" (S:357) — the Archivist never says so on screen (§10.9).
- **Voice:** plain, brave, short. "It's okay. Go." · "Thank you for not leaving me there." S:350 · last words "you said you'd—" S:353.
- **Strongest scene:** WREN_EDGE S:346-351.
- **Endings role:** Wren ending requires her present at Slot 2 (W:953). Epilogue lines S:515-518; recap S:222-225.
- **Contradictions:** the owner says "i didn't make her" (S:427, S:572) though they delete her by name earlier (village_square.gd:218, OMv:377).

### 3.6 Tobben

- **Role (CONFIRMED):** shopkeeper; tells the owner 4 s after you talk (village_square.gd:415-427).
- **Motivation:** bound by script, sorry about it: "I have to tell them, you know. It's in my script." / "I told them. I'm sorry."
- **Knows:** there used to be two names in the guest book (village_square.gd:44). After you read the torn page he remembers "RUE" (S:608).
- **Voice:** cheerful shop patter that breaks: "Welcome to Tobben's! Finest... you don't have any gold. You don't have an inventory." · "I'd forgotten I forgot." S:324.
- **Strongest scene:** GUESTBOOK_SCENE S:320-325.
- **Endings role:** epilogue "tobben's guest book lies open: two names, two handwritings." S:524.
- **Contradictions:** remembers "RUE" as soon as you *read* the page in the bin, before you tell him (S:607-608; recycle_bin.gd:181-183).

### 3.7 Pip

- **Role (CONFIRMED):** Rue's fox, out of bounds; follows you every session once found (W:734-745), invisible to the owner (S:268).
- **Motivation:** loyalty: "i waited by the wall. i'm good at waiting." S:261.
- **Knows:** Rue's name immediately ("...rue?" S:260); how many pieces you have (S:270).
- **Voice:** lowercase, quick bursts. "you're the wrong colour. that's okay. i'm the wrong place." S:262 · "don't stand still near the hand. i don't like the hand." S:271.
- **Strongest scene:** PIP_MEETING S:259-265; with 5 memories, the name tag S:330.
- **Endings role:** last line of every ending except overwrite (S:506-507).

### 3.8 The Archivist

- **Role (CONFIRMED):** cut NPC in the Archive; gives `slot_2.ptr`, which opens the north road (archive.gd:94-106).
- **Motivation:** kindness, keeping records: "I keep the logs." archive.gd:110.
- **Knows:** deaths, sessions, deleted assets, the owner's pages (archive.gd:115-169); counts your pieces and greets you as Rue with all 5 (archive.gd:78-84).
- **Misunderstands:** "There's a slot the owner never used. Slot 2." archive.gd:104 (contradicted by fragments, §10.1).
- **Voice:** dry, kind librarian. "Oh. A visitor. Nobody visits." · "Lucky me. Lucky you, maybe." · "I wasn't finished either." archive.gd:92.
- **Endings role:** none directly.

### 3.9 Minor voices

- **SYSTEM** console: "SLOT 1 LOADED" OD:213, "RUNNING: erase_unknown_entity()" OD:187, "SCAN COMPLETE: 0 UNKNOWN PROCESSES" W:1108.
- **Notes/boards** that rewrite themselves (arins_room.gd:172, 241-253; village_square.gd:106-110).

---

## 4. Timeline

### 4.1 Backstory (CONFIRMED order where stated; relative times flagged)

1. Two people play on one couch "at mum's", two controllers (S:94, 178).
2. "you be arin... i'll make my own" — slot 2, NEW GAME, three letters, a rainy day (S:95, 116-117, 80).
3. Rue and Pip fall through the well; they save anyway (S:105-107).
4. ARIN & RUE beat the forest boss and sign the guest book (recycle_bin.gd:186).
5. Rue's slot reaches LV 31 / 41 h (recycle_bin.gd:175).
6. The move, in summer; boxes; "you'll visit"; last played the night before the move (S:127-129, 179; recycle_bin.gd:175). Rue's last message "keep my slot" (recycle_bin.gd:206).
7. She came back twice (S:132, 179).
8. The owner keeps the save "for two years" (S:180).
9. "months later": "still have my save?" (S:139). The owner drafts "yes i still have your sa" (recycle_bin.gd:195).
10. Same night: DELETE SLOT 02? YES (S:141; recycle_bin.gd:194). "for space" (S:181). The draft goes in the bin.
11. ~3 years pass (recycle_bin.gd:174, 204).
12. Present: the owner still plays Arin at night (archive.gd:167); "there's something in arin's room again" (S:177).

Steps 8-10 conflict on timing (§10.3).

### 4.2 In-game run structure (CONFIRMED)

- **Session start:** OwnerMemory.begin_session() increments `sessions` (OM:139-152). First launch only: BOOT (W:110-111).
- **Owner intro** per previous exit (OD:211-249): death recall, quit, crash, ending return; "and i know who helped you"; recognition line; purge counter; one owner note from session 2 (S:190-198).
- **Act cards** first time each area is entered (W:379-384; S:250-256): room I, square II, oob III, archive IV, edge V. (House and bin have none.)
- **Awareness thresholds** 25/40/50/65/75/100 (OD:8-13) drive each area's reactions.
- **Session end:** death (OM:191-214), quit (OM:217-224), crash (OM:444-448), or Slot 2 (OM:229-247).
- **Purge:** +1 per non-forgiven death or quit (OM:207-208, 222); at 6 the run is "purged" (OM:13, 122-123; W:1100-1110). F9 wipes everything (W:1116-1127).

---

## 5. Rules of the world

| Rule | Evidence |
| --- | --- |
| **Save vs owner memory.** The world reloads; the owner's memory lives outside the slot. | OM:1-6 |
| **Fragments are Rue's**, not the owner's: they survive deaths and purges. | OM:77-80 |
| **What the owner can see:** Arin's cone (village_square.gd:313-327), the room (rate ×3, arins_room.gd:66), the bin (rate 1.2, recycle_bin.gd:41), the house, the Edge. | area `awareness_rate` values |
| **What the owner can't see:** the Archive (−0.6, archive.gd:28-30), out of bounds (−0.8, out_of_bounds.gd:60-61), what Wren stands beside (village_square.gd:34), closets (arins_house.gd:74-78), Pip (S:268). No owner moves in archive/oob (OMv:54). | — |
| **Cut content can't be deleted:** "They can't delete what was never in the game." | S:357; archive.gd:101-103, 151 |
| **Out of bounds:** nobody saves there, so nothing there could be deleted; falling isn't death ("nobody saw"). | S:263; out_of_bounds.gd:7-8, 138-156 |
| **Recycle bin:** deleted things go there "for a while"; the owner empties it periodically; system files' shadows protect; deleted NPCs can be restored. | archive.gd:144; recycle_bin.gd:1-8, 136-169 |
| **Restore** (glitch, 4 memories) or bin file: permanent undeletion. | glitch.gd:34; W:796-802 |
| **Slot 2 is protected from the eraser** "The owner doesn't know Slot 2 exists". | the_edge.gd:104-105 |
| **The Edge forgives one death** (not loaded, owner didn't see). Resets on reaching Slot 2. | OM:188-214, 236 |
| **Helpers pay:** whoever hid/escorted you is deleted if the session ends badly (unless Wren is cut content). | OM:468-470, 486-487; W:400-406 |
| **Glitches cost awareness** and are learned one per memory. | glitch.gd:20-36; S:682 |
| **Quitting counts as dying; crashing counts as quitting.** | OM:112-115, 217-224, 444-448 |

---

## 6. The six endings

All choices are built in `reach_slot2` (W:939-979). Writing into Slot 2 requires the pointer (`flags.pointer`, archive.gd:94) to open the north road (village_square.gd:97-100).

| Id | Condition (code) | Option text | Final exchange | Epilogue | End card | Title after |
| --- | --- | --- | --- | --- | --- | --- |
| **escape** | Always offered; picked with <5 memories (W:950-952) | "Write yourself in" S:379 | S:415-419 | default S:504 + people S:512-527 + Pip S:506 | win_text S:768-773 (by memories ≥3 or less) | S:37 |
| **rue** | Same option with 5 memories ("Write RUE", S:380); escape is promoted to rue (W:987-988). Also counts "escape" as seen (OM:239-242) | "Write RUE" | S:420-425 | EPILOGUE_TRUE S:365-372 | S:770 | S:38 |
| **wren** | Wren escorting and present (W:953-955) | "Give Slot 2 to Wren" S:381 | S:426-430 | S:461-470 | S:534 | S:39 |
| **message** | Always offered (W:956-957); then pick 1 of 3 messages (W:973-974; S:384-388) | S:382 | S:431-435 | S:471-485 (5 memories: "...rue?" and "i'm going to call you. the real you.") | S:535-538 | S:40 |
| **unseen** | `is_unseen_run()`: `not flags.seen_by_arin and session_glitches <= 1` (W:928-929) | S:392 | S:436-440 | S:488-494 | S:541-542 | S:41 |
| **overwrite** | `is_reckless_run()`: awareness ≥ 100 and `session_glitches >= 10` (W:933-934) | S:394 | S:441-445 | S:495-502 | S:543-544 | S:42 |

Side effects: message resets purge to 0 and clears `npc_fates` (OM:243-246). Only "rue" plays the full music box (S:448-452). Next run the owner says ENDING_RETURN (S:549-556).

**What each means (INTERPRETATION):**
- *escape* — survival without identity; the owner finds the slot next run (S:553).
- *rue* — the owner chooses LOAD instead of DELETE: forgiveness on both sides.
- *wren* — Rue gives the slot away; identity without a body ("i don't need a slot to keep it." S:469).
- *message* — the slot returns to its owner; the only ending with real-world contact (S:480 "the real you", S:537 "a phone is ringing").
- *unseen* — escape by never being noticed; the owner feels only lightness (S:439).
- *overwrite* — revenge: the owner learns what deletion feels like (S:444, 500-501). Slot 1 later "restored from a backup. most of it." (S:42).

---

## 7. Narrative flags

### 7.1 OwnerMemory (persistent)

| Field | Meaning | Set | Read |
| --- | --- | --- | --- |
| `sessions` | runs started | OM:144 | S:191, 215; OD:159, 197, 236; arins_room.gd:78, 251; village_square.gd:106, 178, 379; archive.gd:126 |
| `deaths` / `quits` / `wins` | counters | OM:206, 221, 232 | S:216-219, 616, 716-719; OD:219; archive.gd:109, 116 |
| `purge` | owner progress 0-6 | OM:208, 222, 245, 446 | OD:51, 116, 238-241; W:792; S:208, 730; many speed values |
| `deaths_log` | where you died | OM:209 | area.gd:78-102 (ghosts, erasure seeds); archive.gd:117-120 |
| `patched_seams` | room seams closed | OM:488-489 | arins_room.gd:125-143; archive.gd:140-141 |
| `npc_fates` | npc → "deleted" | OM:486-487; W:558 | OM:126-127; S:224, 483, 517, 581; archive.gd:130; recycle_bin.gd:81; OD:229 |
| `met_archivist` | met once | archive.gd:96-98 | archive.gd:96; S:642 |
| `found_pip` | Pip follows forever | W:744 | W:95, 444, 452, 1000; out_of_bounds.gd:81; S:641 |
| `wren_saved` | Wren saw the Edge (cut content) | W:572 | S:204, 515, 611, 643; village_square.gd:216, 360; archive.gd:150; OMv:349; OM:469 |
| `owner_notes_seen` | notes shown | S:194 | S:191-193; archive.gd:162; recycle_bin.gd:198 |
| `session_glitches` / `last_run_glitches` / `total_glitches` | glitch counts | glitch_controller.gd:270-271; OM:142-143 | W:929, 934; S:202, 236 |
| `total_reloads` | owner reloads | OMv:176 | S:220-221 |
| `false_memory_taken` | took "YOU LEFT FIRST" | W:209 | village_square.gd:125 |
| `mira_quest` | "", "pinned", "reset", "lost" (**"carried" never set**) | W:515, 545, 891; village_square.gd:231 (dead) | S:226-231, 519-522, 586-591, 646; arins_room.gd:206, 211; village_square.gd:108, 196, 209, 230; archive.gd:132-137; recycle_bin.gd:72; OM:168 |
| `found_guestbook` | read torn page | recycle_bin.gd:181-183 | S:607, 645, 710; village_square.gd:387 |
| `guestbook_restored` | wrote RUE back | village_square.gd:396 | S:232, 523, 605; archive.gd:138 |
| `found_controller` | found it under the couch | arins_house.gd:141 | S:234, 525, 647; village_square.gd:283; arins_house.gd:68, 139 |
| `last_ending` / `endings_seen` | last and all endings | OM:233-242 | OD:227; S:582, 696, 728; title.gd:139-171 |
| `last_death` / `death_causes` | death reasons | OM:194-196 | OD:217; S:583; arins_room.gd:246; W:896 |
| `edge_static_deaths` / `edge_mercy_used` | Edge balance | OM:198-205, 236-237 | the_edge.gd:114-115 |
| `restored` | NPCs brought back | OM:173-176 | S:204, 592, 644, 712; W:792 |
| `fragments` | memory ids | OM:159-162 | everywhere (S:206, 707; W:950, 987; archive.gd:79; recycle_bin.gd:205; OD:234) |
| `acts_seen` | act cards shown | W:382 | W:381 |
| `route_memory` / `session_spots` | Arin's learned route | OM:453-489 | village_square.gd:176-187; OD:160 |
| `last_exit` / `previous_exit` | how the last run ended | OM:140-141, 493 | OD:214; S:582-583; arins_room.gd:244 |
| `session_helpers` | who helped this run | OM:179-181 (from W:405, 481) | OM:486; village_square.gd:216; W:898 |
| `session_recalled` | recall lines used | npc.gd:146-147 | npc.gd:146 |
| `session_seam` | seam used this run | OM:184-185 | OM:488; arins_room.gd:125 |

### 7.2 `world.flags` (session only, W:14-15)

| Flag | Meaning | Set | Read |
| --- | --- | --- | --- |
| `pointer` | have slot_2.ptr | archive.gd:94; W:619 (debug) | village_square.gd:99, 121, 276, 292, 438, 462; archive.gd:64, 88; W:446 |
| `mira_deleted` | Mira deleted this run | arins_room.gd:180; cleared W:800 | W:792; archive.gd:128 |
| `seen_by_arin` | Arin saw you this run | village_square.gd:322; arins_house.gd:116 (**not** the_edge.gd:241) | W:929 |
| `<id>_restored` | restored this run | W:801 | **never read** (§10.10) |

---

## 8. Narrative dependency map

### 8.1 Rue's identity (intruder = deleted slot 2)
- **Clues:** BOOT "PLAYER 2 . . . [deleted]" / "ENTITY SLOT: 02" S:27-29 · "the one they wanted instead of me" S:59 · Mira "the other one. The one who used to sit next to them." arins_room.gd:40 · Wren "You look like someone who used to play here." village_square.gd:37 · Tobben's missing name village_square.gd:44 · "edge_first": "it's the same colour as me" S:61.
- **Revealed:** Fragment 3 (archive) S:120; fully at Fragment 5 S:144; owner at 5 memories "i deleted you." S:245.
- **Gains meaning:** the cyan colour = missing-texture slot data; Pip's "you fell back in!" S:261; the Records margin "i know whose they are." S:707.

### 8.2 Arin is the owner's avatar
- **Clues:** "ARIN IS THE OWNER — The owner plays as Arin." tutorial.gd:20 (stated as a mechanic, on entering the square); Mira greets you as Arin arins_room.gd:35; "huh. arin doesn't walk like that." OD:200.
- **Revealed:** Fragment 1 "\"you be arin,\"" S:95.
- **Gains meaning:** the house couch/TV ("a little someone standing in front of a TV" arins_house.gd:126); overwrite "the character in the bed isn't the one they made." S:499.

### 8.3 Slot 2 was Rue's
- **Clues:** Archivist "a slot the owner never used" archive.gd:104 (misdirection); CUT CONTENT "save slot 2" archive.gd:154; Edge card "SLOT 2 · EMPTY" S:378; owner note-line "you're looking for slot 2. it isn't there. i made sure." S:207.
- **Revealed:** Fragment 3 "NEW GAME. SLOT 02." S:116; Fragment 5 S:144; slot2_backup.sav recycle_bin.gd:174-176.
- **Gains meaning:** BOOT line S:29; Final fight "what is SLOT 2. that's not yours." S:166 (ironic: it is).

### 8.4 Why Rue was deleted
- **Clues:** false memory S:156-158 (the owner's self-justification); owner notes 3-5 S:179-181; the empty PLAYER 2 room arins_house.gd:156-159; the photo with one face pixelated arins_house.gd:132-135.
- **Revealed:** note 7 "the empty slot was easier than the waiting." S:183 (needs session 8); Fragment 5 S:139-143.
- **Gains meaning:** Fragment 4 "i came back twice"; "you keep putting people back. she used to do that. bring back the ones i got bored of." S:205.

### 8.5 The unsent message(s)
- **Two documents:** Rue's "keep my slot... promise?" (recycle_bin.gd:206) and the owner's draft "yes i still have your sa" (recycle_bin.gd:195).
- **Clues:** Fragment 5 "no answer." S:140; note 6 S:182; the controller "i never moved it. i couldn't." S:235.
- **Revealed:** owner_draft.txt (any time in the bin); the closing line "they couldn't send it. it wasn't true anymore." only after 6 notes (recycle_bin.gd:198-199). Rue's message only with 5 memories (recycle_bin.gd:205).
- **Gains meaning:** message ending — Rue finally sends something the owner reads (S:473-475); EPILOGUE_TRUE "i kept your controller." S:370.

---

## 9. Optional vs mandatory story content

**Critical path to *escape*** (CONFIRMED by gating): wake in the room → leave via a seam (opens at awareness ≥ 40, arins_room.gd:157-158; approaching the door forces it, OD:146-151) or UNLOCK the door → square → east → Archive → talk to the Archivist (pointer, archive.gd:94) → back to the square → north road → Edge → lure the cursor → write into Slot 2 → "Write yourself in".

**Seen on that path:** BOOT (first run only), wake voice, room note, owner threshold lines, Act cards I, II, IV, V, the Archivist's intro (archive.gd:100-106), Edge lines, final fight (S:165-172), slot-2 recap, escape exchange/epilogue/end card. Wren's and Tobben's lines only if you choose to talk.

**Missed on that path:** every memory fragment (none is required — the room's is behind a cracked wall, two sit at the Edge off the slot), so the player can win without learning Rue's name, the couch, the move or the deletion; Pip and Act III; the Recycle Bin (backup, guest book, Rue's message, owner's draft); Arin's house and the controller; Mira's walk; Wren's escort; the guest book; all owner notes (only from run 2, S:191); the false memory (needs 2 fragments, village_square.gd:125). **The entire backstory is optional.**

**Mandatory-ish exposition:** the Archivist is the only required speaker, and his key line ("a slot the owner never used") is the one most at odds with the backstory (§10.1).

**Permanently missable without an F9 wipe:** Mira's walk/"Mira saw the square" once `mira_quest` is "reset" or "lost" (arins_room.gd:211 requires "" or "carried"; message ending does not clear it, OM:243-246).

---

## 10. Contradictions, dead branches, repetition (each verified by grep)

### 10.1 Does the owner know Slot 2 exists? (major) — RESOLVED 2026-10-16: the cut-content ghost (NARRATIVE_DECISIONS.md)
- Says **no**: Archivist "a slot the owner never used" archive.gd:104; THE OWNER book "They don't know there's a second slot. If they find out, they'll delete that too." archive.gd:168; final fight "what is SLOT 2" S:166; escape win text "the owner doesn't know this slot exists. not yet." S:773; code comment the_edge.gd:104.
- Says **yes**: owner deleted slot 2 themself S:141, S:181; BOOT shows "PLAYER 2 . . . [deleted]" S:27; "you're looking for slot 2. it isn't there. i made sure." S:207.
- CUT CONTENT says slot 2 was cut before ship ("players never use the second one") archive.gd:154, yet Rue made a character there (S:116).

### 10.2 `mira_quest = "carried"` is never assigned (dead branch)
- Only reads: arins_room.gd:211, village_square.gd:230, OM:168. No assignment anywhere (grep `"carried"`).
- Therefore dead: `VillageSquare.interact_extra` pin path (village_square.gd:229-240); `OwnerMemory._lose_carried_note()` (OM:167-169) is a permanent no-op although called at OM:202, 220; `Story.MIRA_NOTE_GIVE` (S:305-309) is never referenced.
- Stale docs: S:302-304 ("Die (or quit) while carrying it"), OM:47 (lists "carried", omits "reset").
- Side effect: **quitting** while escorting Mira does not set "lost" (only `kill` does, W:890-891), contrary to S:303. (She is still deleted via `session_helpers`, OM:486-487.)
- MIRA_NOTE_LOST says "the owner found it on you" (S:314) and Mira says "they found it on you" (S:591), but in the live flow Mira carries the note herself (S:289-292).

### 10.3 Backstory timing — RESOLVED 2026-10-16 for the message/deletion order (message months later, deleted that same night); the hours/levels question (§11.9) stays open
- "i kept her save for two years" S:180 vs Fragment 5 "a message, months later" followed by deletion (S:139-141) and the draft deleted "the same night as slot2.sav" (recycle_bin.gd:194).
- Note 6 "i didn't answer. i'd already deleted it." S:182 vs the draft "yes i still have your sa" (recycle_bin.gd:195) and Fragment 5's order (message, then delete).
- Rue LV 31 / 41 h (recycle_bin.gd:175) vs Arin LV 7 / 14 h, "fourteen hours... all i have left" (S:24, 443; archive.gd:165) although the owner kept playing for years (S:180).
- LAST PLAYED "the night before the move" (recycle_bin.gd:175) vs "i came back twice" (S:132) — possible, but the visits never played.

### 10.4 Fragment 1 speaker — RESOLVED 2026-10-16: Rue says both lines
"\"you be arin,\" they said. \"i'll make my own.\"" (S:95) attributes both clauses to "they" — that would make *the other person* the slot-2 maker, inverting roles. Same in SS:90.

### 10.5 Pronouns
- Rue/second player: code "she/her" (S:179-183, 233, 235, 492; README:226; OMv:6 "her path") vs SS:36 "*they*" and README:288 "them".
- Arin: "him" (S:552; the_edge.gd:40; README:210) vs "them/they" (S:740-741; tutorial.gd:27).

### 10.6 The name leaks before it is "remembered"
Fragment 5's after-line "my name was RUE" (S:144) plays whenever that fragment is taken, even as the 1st memory; fragments have no order gate (area.gd:187-197). Pip says "rue" on meeting (S:260), slot2_backup shows RUE (recycle_bin.gd:175), the guest-book choice says "Write RUE" (S:318). Yet the Slot 2 option stays "Write yourself in" (W:951) and the end card says "you almost remember whose it was" (S:771-772).

### 10.7 Room note after endings — RESOLVED 2026-10-16 for *unseen* (the note now reads like nothing happened: `Story.NOTE_RECALL.unseen`); escape/rue/overwrite still use "I KNOW ABOUT SLOT 2", which fits them
NOTE_RECALL has keys only for wren/message (S:572-573) among endings; after escape/rue/unseen/overwrite the note reads "I KNOW ABOUT\nSLOT 2." (arins_room.gd:250). After *unseen* this contradicts "the owner never knew you were there" (S:542) and "probably nothing." (S:551).

### 10.8 Unseen condition ignores Arin at the Edge — RESOLVED 2026-10-16 (the Edge Arin sets `seen_by_arin`; `test_endings.test_arin_at_the_edge_counts_as_being_seen`)
`seen_by_arin` is set in the square (village_square.gd:322) and house (arins_house.gd:116) but not by the Edge Arin (the_edge.gd:241), so being seen by Arin during the final fight still allows "Arin never saw you this run" (W:927-929).

### 10.9 Dialogue claims with no on-screen source
- Wren: "The Archivist says I'm cut content now." (S:357) — no Archivist line says it; only the CUT CONTENT book (archive.gd:151).
- Archivist: "I remember you. I'm the only one here who does" (archive.gd:108) vs Mira/Tobben/Wren recall lines (S:580-624).
- SS:259 Archivist line about Pip ("I logged a fox once") is not in code.

### 10.10 Other dead/unused data
- `flags["<id>_restored"]` set at W:801, never read (grep `_restored"`).
- No recall lines for rue/unseen/overwrite endings (S:596-623 check only message/wren/escape).
- OM:55-56 comment lists only three endings; there are six.
- Overwrite: `_epilogue_people` excludes pinned-board and guest-book lines from overwrite (S:519, 523) but not the Mira-reset line (S:521-522).
- Overwrite title shows "SLOT 2 · ARIN · (corrupted)" (S:42) while the epilogue says "SLOT 1 · RUE" (S:497) and title.gd:170-171 shows "ARIN?" in slot 1.
- Deleted Assets lists "door_01... Reason: used by intruder." from session 2 regardless of use (archive.gd:126-127; door deleted at arins_room.gd:78).

### 10.11 STORY_SCRIPT.md drift (doc vs code)
SS:47-48 (BOOT: "ENTITY OWNER" line; code S:24-31 differs) · SS:88 ("plugged in next to the first" vs "the cable taped where the dog chewed it" S:93) · SS:223 ("laughed until we cried" vs "couldn't breathe" S:107) · SS:268-269 (vs S:117-118) · SS:349-353 (vs S:127-132) · SS:358 (not in S:139-143) · SS:342 (missing "Thank you for not leaving me there." S:350). README:249 says 6 secrets; `Story.secrets()` has 7 (S:640-648). README:247 and records_panel.gd:117 show "/4" in examples; code uses 6 endings and 7 secrets (records_panel.gd:127).

### 10.12 Repetitive exposition
- "still have my save?" twice (S:139, 182); "she came twice" twice (S:132, 179).
- "i kept your controller. it's still under the couch." in two endings (S:370, 479), plus the recap controller line (S:235).
- "...where did you go?" for both Archive and OOB (OD:163, 166).
- "for both of us" twice in epilogue people (S:518, 522).
- "The owner can't see..." stated by Wren, Archivist, Pip, Rue, tutorial (village_square.gd:34; archive.gd:92; S:268, 66; tutorial.gd:21).

### 10.13 Owner "didn't make" Wren
"who is that. i didn't make her." (S:427), "WHO IS WREN? I DIDN'T MAKE HER." (S:572) vs the owner deleting her by name (village_square.gd:218; OMv:377; recycle_bin.gd:168 "wren? i deleted you.").

### 10.14 Mira's window
"Arin walks past my window every morning" (S:281, 290) while Mira lives in Arin's room (arins_room.gd:4-6, 97).

---

## 11. Open questions (need author approval)

1. **Slot 2 knowledge (§10.1):** Is Slot 2 at the Edge the *same* slot the owner deleted (resurrected as cut content), or a cut, never-shipped slot? Should the Archivist's line become "a slot the owner thinks is gone"? PROPOSAL: reword archive.gd:104, 168 and S:773.
2. **Timeline (§10.3):** two years or months? Did the owner delete before or after the message? PROPOSAL: pick one; edit S:139 or S:180, and S:182.
3. **Fragment 1 speaker (§10.4):** PROPOSAL: "\"you be arin,\" i said. \"i'll make my own.\"" or split speakers.
4. **Pronouns (§10.5):** Rue "she" (code) or "they" (SS)? Arin "he" or "they"?
5. **Relationship:** friends (SS:11) or siblings ("at mum's", "my half of the room")? The game currently does not say.
6. **Name gating (§10.6):** should Fragment 5's after-line depend on memory count, or the RUE option unlock when the name is learned?
7. **Mira's note (§10.2):** delete the "carried" branch and MIRA_NOTE_GIVE, or restore the carry flow? Should quitting during her walk also set "lost"? Should the message ending undo "reset"/"lost"?
8. **Unseen (§10.7, §10.8):** add NOTE_RECALL keys for the four missing endings; should Edge Arin set `seen_by_arin`?
9. **Hours/levels (§10.3):** why does Arin have 14 h / LV 7 and Rue 41 h / LV 31?
10. **Overwrite aftermath:** what does "SLOT 2 · ARIN · (corrupted)" mean (S:42)?
11. **Wren's origin:** is "i didn't make her" meant to hint that Wren is not the owner's (unfinished/cut) character? Should the Archivist actually tell her she's cut content?
12. **The owner's name and the real-world call** (S:480, 537): ever shown, or kept off-screen permanently?

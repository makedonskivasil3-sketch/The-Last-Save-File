# Narrative and persistence contract (continuity milestone)

**Status: PROPOSED, applied on the review branch only.** It replaces the
"dark truth" of 2026-10-19 (Rue is a character grown from someone's play,
`docs/DARK_TRUTH_DESIGN.md`). Nothing here is merged into `main` until the
author approves it. Each section is marked **implemented**, **proposed**,
**deferred** or **blocked**.

**Revision 2 (coherence milestone, 2026-10-21).** §0 below was added before
any further story text changed. It tightens the rules where the first
revision let the text claim more than the evidence in the game supports.
The rest of the document is updated to match, and each changed rule says
"(rev 2)".

---

## 0. Rev 2: the rules in one place

### 0.1 Internal truth (one paragraph, for writers)

Two real people played one save. The second player, a girl, fell asleep
holding her controller the night before she moved away; the save hung at
87%, and the part of her that was playing stayed inside. That part is Rue:
a real person, wearing her character like a costume. Everyone else in
Ashvale is native to the game (Mira, Tobben, Wren, the Archivist), plus
Pip, whom she drew. The natives have started to keep things between resets
since a person began living among them, which is why they remember Rue.
The owner (player 1) deleted slot 2 months after she left, the same night
her message came. The owner refuses to believe a person can be in there.
The well is the seam between saved and unsaved space. It **keeps** what
the saves lose, including sounds from the real room. It does not
transmit live, and nothing in the game proves that anyone outside hears
Rue. The only way to reach the girl is through someone who can read: the
owner.

### 0.2 What each character believes (and is it true?)

| Who | Believes | True? |
|---|---|---|
| Rue (start) | She is a glitch in someone else's save; the people are "just the game". | No, and no. |
| Rue (after the file) | She is the part of the girl that stayed. | Yes. |
| Mira | Rue is "the other one, who used to sit next to them". | Yes, though she can't know why. |
| Wren | Rue is a kind of ghost; nobody plays either of them. | Half: nobody plays them, but Rue is not a ghost. |
| Tobben | Reporting Rue keeps the village safe; it's in his script. | He does report. Whether it keeps anyone safe: no. |
| The Archivist | Rue's file was closed long ago; he files what's left. | Her file is still open (in session). |
| The owner | "You're not her." Something wearing her walk. | Denial. The game never confirms it. |
| The girl | She doesn't know what she lost ("I'd forgotten I forgot"). | Off-screen; only the message ending reaches her. |

### 0.3 What the player knows at each stage

| Stage (`Progression`) | The player has seen | The player can suspect | Not yet knowable |
|---|---|---|---|
| Opening | Two people, one save; her hands stay; the save hangs at 87%; months later, her message and the owner's reply stopping mid-word. | Rue is connected to the second player. | That Rue *is* her. |
| MEMORIES | The couch, the well, the name, the move, DELETE. | Rue remembers being the second player. | Whether the memories are hers or copied. |
| INVESTIGATE | Others noticed she isn't Arin's kind of character (hands, movement, handwriting). | She was played by someone. | That the player is still in session. |
| FILE / KNOWN | "player: still in session. save: interrupted at 87%." | — | Whether the girl will ever know. |
| Endings | What each ending saves (§0.6). | — | What the girl does next (deliberately off-screen). |

### 0.4 Contradictions audited (rev 2) and how each is resolved

| # | Topic | Contradiction found in the branch | Resolution |
|---|---|---|---|
| C1 | The girl outside | The opening's last shot typed "still have my sa" as **her** unfinished sentence (`opening.gd`, `UNFINISHED`). Canon (owner note 6, the Bin's draft): her message was complete; the **owner's reply** stopped mid-word. | The shot shows her complete message arriving, then the owner's reply "yes i still have your sa" stopping. |
| C2 | What the well transmits | `COMPARED` ends "it's her. outside. she's still asking." and `ANSWER_HOPE` "she's still out there asking". The only evidence is one sentence from months after the move. | The well keeps a recording. Rue says what it proves (the room heard it once) and what it doesn't (that she is asking now). |
| C3 | Who held Mira's note | Archive, `RECALL.mira_lost` and the Bin's `mira_note.txt` say "the owner found it **on you**". In play Mira carries her own note on the walk; Rue never holds it (`mira_quest = "carried"` is never written). | It was found on Mira. The lines say so. The archive shows "carried by Mira" during the walk. |
| C4 | Rue's identity | `CHARACTER_FILE`: "rebuilt from: slot2_backup.sav…". This can read as "Rue is a rebuild". | "costume rebuilt from…": the costume is rebuilt; the player is not. |
| C5 | How natives know things | Mira's recall "They took Wren" breaks the witnessing rule: Mira never leaves her room. | Natives feel the save's **lists** (who is in the save, which slots exist) but witness only events where they are. The line becomes "Wren's name went out of the list". |
| C6 | What a checkpoint preserves | The anchor needed DELETE (at the Edge) or the Bin's draft, so recovery arrived near the end of the game. | An earlier, earned, opt-in anchor at the pillar (§5, rev 2). The well's later steps stay as revelations. |
| C7 | What deletion destroys | "nothing is ever really deleted. not while someone still remembers" (DELETE memory) vs. the Bin being emptied ("EMPTIED"). | Kept as Rue's hope, not a rule. Deletion moves a native to the Bin; emptying it destroys only what nobody restored. A restored native keeps relationship history (§3). |
| C8 | What restoration returns | Mira: "I remember the dark in between". The archive said "She remembers…" for every restored person, Tobben included. | Per character: only lines that character actually says. |
| C9 | What each ending saves | Consistent with §1; restated in §0.6 so writers have one list. | No text change. |
| C10 | The owner's knowledge | Consistent: the owner knows they deleted slot 2 (2026-10-16 decision) and doesn't know its ghost survived. | No change. |

### 0.5 What the well can carry (limits)

- **What crosses:** sounds and typed text from the real room where the
  console is. A button click, the music box, the message as it appeared
  there, the owner typing.
- **When:** whenever it happened in the room. The well keeps it and plays
  it back the same way each time: the same pause, the same missing key.
  That repetition is the evidence that it is a recording.
- **Why:** it is where the saves lose things (Rue's character fell through
  it once). Lost things settle there.
- **Cost:** answering is done in the open Square (+20 awareness, unchanged).
- **What cannot cross:** nothing goes **up**, as far as the game shows.
  After Rue answers, listening plays back **her own** answer. That is
  observable proof that the well keeps what is said now. It is not proof
  that anyone outside hears it.
- **What cannot be recovered through it:** people. It returns no one. The
  Bin and RESTORE do that.

### 0.6 What each ending saves

| Ending | Saves | Costs |
|---|---|---|
| escape | Rue, as a finished save in slot 2: she stops eroding. | The natives stay in the owner's hands. |
| rue | The same, knowing who she is. | As above. |
| wren | Wren, given the slot. | Rue stays erodable, in someone else's save. |
| message | Everyone: purge cleared, fates cleared, pieces returned. The owner calls the girl. | Rue stays inside, unfinished, but heard. |
| unseen / overwrite | Hidden endings: unchanged. | — |

### 0.7 Author-level choices still open

1. **Approve the canon** (Rue is the part of the girl that stayed). Until
   approved, everything here is a proposal.
2. **Live contact or trace only?** Rev 2 implements *trace only*: the
   well keeps, it doesn't send. If the author wants live contact, the
   plot needs a response to something Rue does now that a recording could
   not produce. Nothing in the game currently provides one, and none is
   faked.
3. **The earlier anchor** (§5) changes where a run starts after a death,
   once it is set. It is opt-in in play; the author decides whether it
   stays.
4. **The opening's length** stays about 45 s (shorter than the 60–90 s
   budget, on purpose).

Baseline: `main` = `1e371b1`. The review branch
`claude/last-save-file-prototype-ljwuq4` was at `a38049f` when this
milestone began: the live-art milestone, ten commits ahead of `main`, with
no other open branch ahead of `main`. No local modifications were present.

---

## 1. The truth (internal; the player discovers it in pieces)

**Who entered the game, and how.**
- Two real people shared one console "at mum's": the **owner** (player 1,
  never named, always played Arin) and a **girl** (player 2, never named
  outside the game; she typed her character's name, RUE, with her tongue
  between her teeth).
- On the night before she moved away, she played slot 2 one last time,
  alone. She fell asleep with the controller in her hands while it saved.
  The save hung at 87% (the opening's frozen bar).
- The part of her that was playing did not come back out. She woke up the
  next morning, moved, and went on living, slightly less than whole. She
  says "I'd forgotten I forgot"; she doesn't know what she lost.

**Rue is a literal trapped person.** She is the part of that girl that
stayed in the save: real memories, a real will, and no body of her own.
The character model is a costume she is wearing. Her five memories are her
own memories, told from her own seat.
- This is why she can't simply be "loaded". The save she is in never
  finished.
- This is why she erodes. Every time the owner overwrites her, she reloads
  from what is left of an interrupted save, and a little less comes back
  (the purge counter).

**What remains outside.**
- The girl: alive, three years older, somewhere else.
- The owner: still in the house.
- The couch, the console, and her controller under the couch.
- Months after the move she sent "still have my save?". She half-knew
  something was in there. The owner started to answer, then deleted slot 2
  that same night "for space" (canon of 2026-10-16, kept).

**What the owner knows and wants.**
- The owner knows they deleted slot 2. They do not believe a person can be
  inside a game. They think something is wearing her character: a glitch
  with her walk.
- They want the empty slot to stay empty, because the empty slot is easier
  than the waiting. They are afraid that it is her.
- Every "you're not her" from the owner is denial, not truth. The player
  may believe it for a while; the implementation never does.

**The people of Ashvale.**
- **Mira, Tobben and Wren are native inhabitants.** They are game people.
  Since a person has lived among them, they have started to keep things
  between resets. That is why they remember Rue across runs. They are
  people to Rue, and they can be lost.
- **Wren** is unfinished cut content who was left in the village. Her
  "nobody finished me" is literally true.
- **The Archivist** is a remnant: cut before release, keeping the records
  nobody reads.
- **Pip** is the fox the girl drew. It is the one native thing that was
  hers.
- **Arin** is the owner's avatar and has no will of his own; the owner
  drives him. "The real Arin" in the purged room is the owner, standing in
  Arin and saying nothing.

**Death, deletion, restoration and checkpoints.**
- **Death:** the owner overwrites Rue's current copy. She reloads from the
  interrupted save, which loses a little each time (the purge counter,
  unchanged).
- **Deletion of a native:** the native is moved to the Recycle Bin.
- **Restoration:** the native is brought back with what the Bin kept.
  Relationship history survives. Natives remember "the dark in between".
- **Fraying:** when Rue leaves her costume, she borrows a piece of someone.
  It is a real harm to them, and it is reversible only by returning the
  piece.
- **The well anchor** (§5) is the one thing the owner cannot overwrite. It
  is kept out of bounds, where nothing is ever saved.

**What the well stores and connects.**
- The well is where her character once fell out of the world. That day the
  two of them laughed until they couldn't breathe, and saved anyway.
- It is the seam between saved and unsaved space. Things the saves lost
  settle under it (Pip, the anchor).
- Sound from the real room carries down it: a controller's click, the
  music box with its missing note, and once, words the girl typed outside.
- It does not answer questions. It does not foretell anything. It cannot
  bring anyone back by itself. It keeps traces, and it carries sound, at a
  cost.

**What escape saves, and what it cannot.**
- **Writing herself into slot 2:** the trapped part of her becomes a save
  that finished. She is no longer erodable.
- **What escape cannot save:** her three years outside, or the people she
  leaves behind, unless she gives the slot to one of them (the Wren ending).
- **The message ending** sends the owner to the real girl. The owner will
  tell her where the rest of her is. This is the most hopeful ending: the
  two halves may meet.

---

## 2. People: desire, fear, habit, misunderstanding, action

Each character keeps their established voice. Nobody is "help, I'm trapped".

| | Desire | Fear | Habit that survives erosion | Misunderstands | Can do for someone else | Responds to the player's history |
|---|---|---|---|---|---|---|
| **Rue** | Her own name; to get home | That she is only a copy | Holds her hands as if they hold a controller; puts things back where they were | Thinks the people here are "just the game" | Restores, returns pieces, takes the risk | Remembers everything the save keeps |
| **Mira** | To be more than a line; to leave the room | The blank smile (being reset) | Sets out a second cup | Thinks Rue is "the other one who used to sit next to them" (true, though she can't know why) | Writes and pins a warning note | "I remember the dark in between" |
| **Wren** | To see the Edge | Being left behind, or cut again | Tugs her ribbon when she's thinking | Thinks Rue is a ghost of someone who used to play here | Hides Rue; shows her the way; hears the well too | Promise, witnessed death, restoration (§4) |
| **Tobben** | Order: stock counted, guests signed in | That the script makes him report you | Counts under his breath | Thinks reporting keeps the village safe | Offers the guest book | Reports less once you return his voice |
| **Archivist** | Correct records | Being unread | Refiles things you just put back | Thinks Rue's file was closed long ago | Hands her the file | "Hello, Rue" |
| **Owner** | The slot to stay empty | That it's her | "you move like someone i used to know" | That a person can't be in there | Can call the real girl (the message ending) | Notes, recall, recognition |

Rhythm for every arc: connection → disturbance → loss → practical hope →
chosen risk. Erosion shows through small controlled changes: a shortened
answer, a missing word, recognition that arrives a moment late.

---

## 3. Persistence contract (rev 2)

All three layers use stable ids, never node paths. Transient presentation
(timers, animation phase, positions) is rebuilt from state, never saved.
Save version 3 (`OwnerMemory.SAVE_VERSION`). v0, v1 and v2 saves migrate:
`_from_v1` and `_from_v2` run in order. `SafeFile` writes atomically and
recovers `.tmp`/`.bak`. Every number read back must be finite and whole
where it is used as one (`_whole`).

**Field by field.** Layer **A** is lasting narrative knowledge. Layer **B**
is a persistent world consequence. Layer **C** is the checkpoint. **T** is
transient: this attempt only.

| Field (`OwnerMemory`, unless noted) | Layer | Written when | Notes |
|---|---|---|---|
| `encounters` {first, last, prev, count, area, look, seen} | A | a conversation **opens** (meeting counts even if you walk away); `seen` whenever Rue sees their state | `seen` is what the journal calls their condition |
| `conversations` | A | the box is read to its last line | a consequence walked away from is said again |
| `rel_events` {first, last, count, seq, first_seq} | A | the authored moment (registry: `Relationships.EVENTS`) | one record per id; `seq` keeps order |
| `event_seq` | A | each event or fact | order counter; repaired to the highest stored order on load |
| `facts` | A | the line that teaches it is shown (`ArchivePages.FACTS`) | never on meeting alone |
| `journal` | A | a readable is read | every version of a rewritten note is kept |
| `fragments`, `truth_pieces`, `knows_truth` | A | memory lived / line shown / file read | unchanged |
| `places` | A | an area loads | the map's "found" (rev 2: the map uses it) |
| `well_events` | A | each step's own moment; `words` only when read whole (rev 2) | ordered |
| `archive_seen` {key: revision} | A | an entry is read (1.5 s on the page, or picked) | v2 keys migrate as "*" (read, revision unknown) |
| `acts_seen`, `owner_notes_seen`, `endings_seen`, `restored`, `found_*`, `met_archivist`, `guestbook_restored` | A | their moments | unchanged |
| `npc_fates`, `frayed`, `returned_pending`, `mira_quest`, `wren_saved`, `patched_seams`, husk fields | B | their moments | consequences in the world, unchanged rules |
| `purge`, `deaths`, `quits`, `wins`, `deaths_log`, `death_causes`, `route_memory` | B | session end | the owner's learning; unchanged |
| `anchor` {id, version, session} | C | Rue keeps her place (rev 2: the mark by the pillar) | a place by id; no items, choices or coordinates |
| `World.flags`: `pointer` | B (mirrored) | read from `met_archivist` at session start | the only flag that outlives a session |
| `World.flags`: `mira_deleted`, `seen_by_arin`, `slot2_beaten`, `*_restored` | T | this attempt | the lasting parts are already in `npc_fates`/`rel_events` |
| `World._visited`, doors, crates, awareness, escort, owner moves, `session_*` | T | this attempt | the map shows `_visited` as "this run" |
| `ArchivePages.escort_now`, `JournalPanel` reading place | T | this process | per-viewer conveniences, reset each session / new game |

**Commit points tested** (interruption, scene exit, death, restart):
- **A reunion or consequence cut off halfway** is said again. It is
  committed only when read whole (`test_relationships`,
  `test_continuity`).
- **The well's words cut off** are not heard (`test_well_anchor`).
- **A witnessed death** waits for the next meeting, however many runs
  later. This session's own opening of the box doesn't count as "met
  since" (`Relationships.unacknowledged`).

## 4. Conversations and relationships (rev 2)

**One selection path** (`Npc.interact`; first match wins, one topic per
conversation):
1. **Urgent:** a piece Rue took or gave back (`Relationships.urgent`),
   said once a session and alone; escorting. Reset (Mira) and restriction
   shape delivery. Reset Mira knows nothing; restricted Mira whispers
   (`MIRA_HUSHED`) and still says it.
2. **Consequence:** what they witnessed or what happened to them, each
   said once and committed when read whole.
3. **Continuation:** an open promise; a second, shorter ask.
4. **New topic:** what they noticed about Rue (the truth lines); the well.
5. **Familiar greeting:** once a session, before their usual lines, for
   someone met in an earlier session.
6. **Repeat:** the area's own line counters. Introductions are skipped
   once met.

The fray, truth and recall lines that `Npc.interact` used to stack in
front of the selected conversation now live at their precedence slots.

**Implemented** for Wren, Mira and Tobben. The Archivist keeps his own
first meeting, return greeting, pointer and file lines (his events are
registered).

| | First meeting | Greeting | Shared event | Consequence / changed attitude | Continuation | Repeat |
|---|---|---|---|---|---|---|
| Wren | "You're the one Mira talks about." | "You still look like someone." | sheltered, promised, ribbon | after a death she saw; restored; ending | the promise, kept or broken | her lines |
| Mira | "Arin! You're up early." | two cups (one forgotten); hushed when restricted | asked, walked, pinned, note lost, reset, saw a death, deleted | after a death in her room; restored (each time); pinned; note lost from her hands; Wren leaving the list | the shorter ask | her lines |
| Tobben | "Welcome to Tobben's!" | "a face with no inventory"; "two names, still" | the guest book | the name back; Wren; the tab | (what he noticed) | his lines |
| Archivist | his first lines (the pointer) | "Back again. I remember you." | pointer, file | erasure count, shed lines | the file | the pointer |

**Witnessing rule (rev 2).** A native acknowledges what they saw where
they were, and what the save's **lists** show (who is in the save, which
slots exist). Mira can't leave her room. She knows Wren's name left the
list, but not how.

**Erosion differs by character.**
- Mira still sets out two cups, and forgets why (purge ≥ 3).
- Wren half-remembers the promise ("You said you'd—").
- Tobben, frayed, can only write.

## 5. The checkpoint: a kept place under the well (rev 2)

**What it is.** Death recovery, not a save-and-resume system. It keeps a
**place** (by id). It keeps no items, no choices and no coordinates. A
quit or a crash still starts in Arin's room. The pause menu has no "Save
and Exit"; its quit button says that quitting counts, like dying.

**When it is offered (rev 2, changed).** The first revision set it only
when Rue answered the well. That needs DELETE (at the Edge) or the
owner's draft (in the Bin), so recovery arrived near the end of the game.
Now it is offered as soon as the well's tune has played under the well
(the memory THE WELL, out of bounds; an optional route the Square points
to). That place is where Rue climbed back in the first time she fell out
of the world. Rue **chooses** it: "keep my place here", on a mark beside
the pillar. Answering the well no longer sets it.

| Situation | Behaviour |
|---|---|
| Activation | The mark by the pillar, after the tune. Explicit. A light at the pillar; "PLACE KEPT · under the well"; Rue says what it means. Saved at once. |
| Activating again | "it's still here. it'll keep." Nothing changes. |
| Death | Purge +1 (unchanged). The next session starts at the kept place, on the landing (solid, never streams), after the wake-up. The death card says where you'll wake. Lasting and world state are untouched. |
| Save and Exit | Doesn't exist. The pause menu's quit warns that it counts. |
| Ordinary quit | Counts (purge +1, unchanged). Next start: Arin's room. The anchor stays for the next death. |
| Abrupt closure / crash / tab closed | Counts as a quit (unchanged). Next start: Arin's room. |
| Phone suspension / focus loss | Pausing is free (unchanged); resuming continues where you were. |
| Restart after an update | A `version` mismatch: the room, and the anchor is dropped. |
| Invalid or malformed anchor | Unknown id, missing or non-whole version, unreadable value: the room, and the anchor is dropped (`test_malformed_anchor_data_falls_back_to_the_room`). |
| Companion | Pip (never in the save) arrives beside Rue. An escort is never stored; death already ends one; the place can't be kept while escorting. |
| Endings | Any ending clears it (a new start). |
| Purge | At the purge ending nothing resumes. A full reset clears it. |
| Never mid-anything | Refused during a conversation, a scene, a move between areas, an escort or an ending. |
| No death loop | Out of bounds has no killers; falling is not a death. The tests wait 2 s at the wake point. |
| No duplicates, no reversals | Memories, promises and the owner's learning (routes, deaths, notes) are kept, never duplicated (tested). |

**Consequences of the change, for the author to judge:**
- A run after a death can skip Arin's room. Mira's reaction to a death
  she saw waits for the next time you see her, so it isn't lost.
- The room's per-run owner note is skipped on such a run.

## 6. The well's sequence (rev 2)

The explanation (§0.5): the well **keeps** what the saves lose. That
includes sounds from the real room, and it plays them back identically.
It sends nothing up. Every step needs the previous one, commits once
(`well_events`), survives restart, and gives observable feedback.

| # | Event | Eligible when | What happens | Evidence, and what it proves |
|---|---|---|---|---|
| 1 | `click` | first time near the well | a real controller click | a sound from outside the game |
| 2 | `tune` | `click` + the memory THE WELL, at the pillar | the music box, one note missing; the place can be kept | the well holds the room's sounds; recovery becomes possible |
| 3 | `words` | `tune`; listen at the rim; **read to the end** | "still have my save?", typed | someone typed in the real room |
| — | (replay) | after `words` | exactly the same, the same pause | it's a recording, not someone speaking now |
| 4 | `compared` | `words` + DELETE or the owner's draft, then listen | her message, months after she left | it was her, then. It is **not** proof that she is asking now |
| 5 | `answered` | `compared`; answer at the rim for 2 s, in the open, no escort | +20 awareness; "i'm here." | — |
| — | (replay) | after `answered` | the well plays **Rue's** answer back | it keeps what is said here; it carries nothing up |

Every step's prerequisites lie on routes the player already takes:
- the well is in the Square;
- THE WELL memory is out of bounds, which the goal line points to;
- DELETE is at the Edge, and the draft is in the Bin, both on the way to
  endings.

No trip exists only to trigger a line. The journal's leads say what is
known and what isn't (`WellSequence.leads`).

**Characters' readings.**
- **Wren** (after `words`): "It hums like the people who used to play."
- **Tobben:** "Things come back up wrong."

---

## 7. Affected-content ledger

**C** = conflicts with the new truth. Resolution: **Rewritten** (applied),
**Kept as misunderstanding** (a character is wrong), or **Kept**.

| Where | Old | Resolution |
|---|---|---|
| `story.gd` header | "not the girl, but what she left behind" | **Rewritten:** the part of her that stayed |
| `TRUTH_LINES.mira` | "So who's holding you?" | **Rewritten:** her hands hold a controller that isn't there (the habit) |
| `TRUTH_LINES.wren` | "anybody plays you either" | **Kept:** now literally true |
| `TRUTH_LINES.tobben` | "a different hand… pressed harder" | **Kept:** the same hand, three years older; compatible |
| `FIRST_SHAPE` | "the shape she gave me. what have i been wearing since?" | **Rewritten:** the costume never fit; the shape is her character's, not hers |
| `CHARACTER_FILE` | "behaviour: learned from player input… character: still running" | **Rewritten:** "player: still in session. save: interrupted at 87%." |
| `TRUTH_REVEAL` | "(i'm not her.) (i'm what she left running.)" | **Rewritten:** "(i'm not what she left running.) (i'm what she left.)" |
| `TRUTH_AFTER` | "so this body is a file. files can be left." | **Rewritten:** "so this body is a costume. costumes can be left." (fraying still works) |
| `MESSAGE_TRUTH`, `MESSAGE_SORRY_TRUTH` | "tell her what she left running", "i'm sorry she stopped coming" | **Rewritten:** "tell her where the rest of her is" |
| `EPILOGUE_TRUE` | "> you're not her. i know you're not." | **Kept as misunderstanding**, plus Rue's reply: "(i am. the part that stayed.)" |
| `ending_text` message / rue | "a part of her stayed behind", "you know what you are" | Message **kept** (now literal). Rue **rewritten:** "you know who you are" |
| `win_text` | "you don't know yet what you are" | **Kept:** still true until the file |
| `ENDINGS_RECORD.rue` | "knowing what you are" | **Rewritten:** "knowing who you are" |
| Wren epilogue | "two things nobody plays" | **Kept:** literally true for both |
| `ARCHIVIST_SHED_FIRST` | "whose pieces they were" | **Kept:** she rebuilt from what was around her |
| `ARCHIVIST_NOTHING_TO_TAKE`, archive "cut before it shipped" | — | **Kept:** the Archivist is a remnant |
| Wren "Nobody finished me", "cut content" | — | **Kept:** Wren is cut content |
| Tobben "It's in my script" | — | **Kept:** he is native |
| "data" lines (`VOICE.archive_first`, `HUSK_LINES`, couch) | "can data smell like dust?" | **Kept:** Rue doesn't know yet; she is wrong |
| `recycle_bin._last_message` | truth branch "you remember her writing it" | **Rewritten:** "you remember writing it. you were still in here." |
| Opening film comments | "shows a situation, not the truth" | **Kept;** the shots are rebuilt (§8) |
| `test_canon`, `test_dark_truth`, `test_pass7` | dark-truth phrases | **Updated deliberately** to the new lines |
| `docs/DARK_TRUTH_DESIGN.md`, `NARRATIVE_BIBLE.md` §3.0 | the old truth | **Marked superseded** at the top (history kept) |

The voice manifest is regenerated after text changes. No recordings exist,
so none are lost.

---

## 8. Opening animatic (shot list)

The target is **about 45 s**, inside the 60–90 s prototype budget, and
shorter on purpose. Skip (hold), replay, focus pause, captions and the
"release before play" handoff are all kept.

| # | Time | Framing | Action | Sound | Caption | Purpose |
|---|---|---|---|---|---|---|
| 1 | 0–5 s | Dark room, a TV glow; two pairs of hands on controllers at the bottom of the frame | Both play | Theme, quiet | [a television, late at night] | Two real people |
| 2 | 5–11 s | The TV: Arin and Rue walk together | The girl's hand taps the controller twice before pressing (her gesture) | Two soft clicks | — | The personal gesture (Rue's habit later) |
| 3 | 11–16 s | Hands | Player 1's hands leave; the girl's hands stay, then slacken (asleep) | Theme thins | [she falls asleep holding it] | — |
| 4 | 16–22 s | The TV | "SAVING SLOT 2…" freezes at 87%. Arin stops. Rue keeps walking | Key click; the save tone stops | — | A character moves after its controller is put down |
| 5 | 22–28 s | The TV | PAUSE appears; the screen dims; everything stops except Rue | Silence | [PAUSE] | Pause stops everything except her |
| 6 | 28–33 s | The TV, the well in the room picture | A drip, then the music-box note with the missing one | Wrong-context well sound | [one note, from a music box, in the wrong place] | The well |
| 7 | 33–39 s | Push in | Rue turns and looks out of the screen at the hands | — | — | A character looks out |
| 8 | 38.5–45 s (rev 2) | Cut: no push. The TV; below it, the owner's hands alone; her controller on the floor, its cable taped | Her message arrives whole: "still have my save?". Under it the owner types "yes i still have your sa" and stops. Rue, fainter, still in the picture. Fade; the first move in Arin's room is hers | A key tone; the owner's single click (hers was always two taps, then a press) | [months later. her message. the owner starts to answer.] | The unfinished sentence is the **owner's** (rev 2, §0.4 C1); the handoff |

**Rev 2, carried into play.** The well's first click (step 1) is her
gesture from shot 2: two light taps, then a press (`CLICK_PATTERN`). It is
the sound that crosses the screen. The taped cable in shots 1–3 is the
controller of the memory THE SECOND CONTROLLER.

Hands and silhouettes are drawn in-engine, the same pixel style as the
game. No filmed or photoreal people are needed, so no rights questions
arise.

---

## 9. Status (rev 2)

- **Implemented on the branch, for review:**
  - §0 (rev 2), and the text rewrites in §7 plus C1–C5;
  - save v3, with lasting encounters, conversations, ordered relationship
    events and facts;
  - the single selection path, with Wren, Mira and Tobben arcs;
  - the archive (SEEN / SAID / RUE / UNKNOWN, observed conditions, object
    statuses, "updated" marks, the reader's place);
  - the map's four states;
  - the earned, opt-in kept place;
  - the well's honest evidence;
  - opening shot 8 to canon;
  - the iPhone badge removed;
  - the tests named in `docs/COHERENCE_MILESTONE.md` §4.
- **Proposed:** a larger Square, behind a camera
  (`docs/COHERENCE_MILESTONE.md` §3b); the Archivist on the same selector.
- **Deferred:**
  - other areas' expansion;
  - live animation contact sheets;
  - humour and irritation passes;
  - a relationship-dependent sacrifice (no new endings this milestone).
- **Blocked:**
  - observing unfamiliar players (none available to this session);
  - human voice recording and listening (no one can listen here);
  - hardware (Windows execution, phones, real GPUs, gamepads).
- **Needs the author:** §0.7: the canon, trace-only versus live contact,
  the earlier kept place, and the opening's length.

## 10. Map continuity (audit and proposal)

From the route audit:
- **All walk-off exits arrive on the opposite side.** Two intentional
  exceptions:
  - The room's top door leads out of Arin's front door: south of the house.
  - The well's pillar leads up beside the well.
- **Fixed:** arriving from the well put you on the well's own prompt
  (10 px away). The arrival point is moved clear of it.
- **Implemented:** returning to a discovered place shows the place name and
  a short "back" line, not its act card or first-arrival line again.
  (Act cards were already once per save; first-arrival lines were once per
  session and are now once per save.)
- **Proposed, not built:** a 1.4× Square with a conversation recess by the
  stall, a sheltered lane behind the houses, a viewpoint toward the north
  road, and an opened shortcut to the Archive.
  - It needs a scrolling camera, which the game does not have yet: every
    area is one fixed 640×360 screen.
  - It is deferred until the slice above has been seen by players.
  - The layout notes are in `docs/CONTINUITY_MILESTONE.md`.

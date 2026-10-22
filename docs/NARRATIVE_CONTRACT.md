# Narrative and persistence contract (continuity milestone)

**Status (2026-10-22): the premise is decided.** The author chose
`main`'s premise (`CANON_DECISIONS.md` §1): Rue is the character the girl
played, left running after her player moved away. The draft's "part of the
girl that stayed" text has been reverted to `main`'s. §0.1, §0.2, §0.3,
§0.8 and §1 below are written to the decided premise. The rest of this
document (persistence, conversations, the anchor, the well, the opening's
shots) never depended on the premise and is unchanged. It is still on the
review branch, not merged. Each section is marked **implemented**,
**proposed**, **deferred** or **blocked**.

**Revision 2 (coherence milestone, 2026-10-21).** §0 below was added before
any further story text changed. It tightens the rules where the first
revision let the text claim more than the evidence in the game supports.
The rest of the document is updated to match, and each changed rule says
"(rev 2)".

---

## 0. Rev 2: the rules in one place

### 0.1 Internal truth (one paragraph, for writers)

Two real people played one save. The second player, a girl, made a
character in slot 2 and played her for 41 hours: Rue. Then the girl moved
away. Rue kept running: a character made of someone else's attention,
moving now with no one holding the controller. Everyone else in Ashvale is
native to the game (Mira, Tobben, Wren, the Archivist), plus Pip, whom the
girl drew. The natives have started to keep things between resets since
something in the save began moving with no one playing it, which is why
they remember Rue. The owner (player 1) deleted slot 2 months after the
girl left, the night her message came. The owner says "you're not her",
and that is true; what the owner misses is that Rue is someone anyway. The
well is the seam between saved and unsaved space. It **keeps** what the
saves lose, including sounds from the real room. It does not transmit
live, and nothing in the game proves that anyone outside hears Rue. The
emotional question: can something made through someone else's attention
become a person with a life of her own? She begins as what someone left
behind and becomes someone who decides what happens next.

### 0.2 What each character believes (and is it true?)

| Who | Believes | True? |
|---|---|---|
| Rue (start) | She is a glitch in someone else's save; the people are "just the game". | No, and no. |
| Rue (after the file) | She is the character the girl played, still running without her. | Yes. And she is someone anyway: the endings are her choices. |
| Mira | Rue moves when nobody is holding anything ("so who's holding you?"). | Yes: nobody is. |
| Wren | Rue is a kind of ghost; nobody plays either of them. | Half: nobody plays them, but Rue is not a ghost. |
| Tobben | Reporting Rue keeps the village safe; it's in his script. | He does report. Whether it keeps anyone safe: no. |
| The Archivist | Rue's file says what she is; he files what's left. | Yes: "player: moved away. character: still running." |
| The owner | "You're not her." A bug that moves like her. | "Not her" is true. "Only a bug" is the denial: the game shows otherwise through what Rue chooses. |
| The girl | She doesn't know what she lost ("I'd forgotten I forgot"). | Off-screen; only the message ending reaches her. |

### 0.3 What the player knows at each stage

| Stage (`Progression`) | The player has seen | The player can suspect | Not yet knowable |
|---|---|---|---|
| Opening | Two people, one save; the second figure answers the player; the save hangs at 87%; her hands go still and the figure goes on moving; months later, her message and the owner's reply stopping mid-word. | The figure is connected to the second player, and moves without her. | What the figure is. |
| MEMORIES | The couch, the well, the name, the move, DELETE. | Rue remembers the second player. | Whether she was the girl or the girl's character. |
| INVESTIGATE | Others noticed she isn't Arin's kind of character (she moves when nobody holds her; her handwriting). | She was played by someone, and isn't now. | What the file says. |
| FILE / KNOWN | "behaviour: learned from player input. player: moved away. character: still running." | — | Whether the girl will ever know. |
| Endings | What each ending saves (§0.6). | — | What the girl does next (deliberately off-screen). |

### 0.4 Contradictions audited (rev 2) and how each is resolved

| # | Topic | Contradiction found in the branch | Resolution |
|---|---|---|---|
| C1 | The girl outside | The opening's last shot typed "still have my sa" as **her** unfinished sentence (`opening.gd`, `UNFINISHED`). Canon (owner note 6, the Bin's draft): her message was complete; the **owner's reply** stopped mid-word. | The shot shows her complete message arriving, then the owner's reply "yes i still have your sa" stopping. |
| C2 | What the well transmits | `COMPARED` ends "it's her. outside. she's still asking." and `ANSWER_HOPE` "she's still out there asking". The only evidence is one sentence from months after the move. | The well keeps a recording. Rue says what it proves (the room heard it once) and what it doesn't (that she is asking now). |
| C3 | Who held Mira's note | Archive, `RECALL.mira_lost` and the Bin's `mira_note.txt` say "the owner found it **on you**". In play Mira carries her own note on the walk; Rue never holds it (`mira_quest = "carried"` is never written). | It was found on Mira. The lines say so. The archive shows "carried by Mira" during the walk. |
| C4 | Rue's identity | `CHARACTER_FILE`: "rebuilt from: slot2_backup.sav…". This can read as "Rue is a rebuild". | Kept (decided premise): the body is rebuilt from what was thrown away; the behaviour is the 41 hours, learned. Both are true of a character. |
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
| rue | The same, knowing what she is, and writing her name anyway. | As above. |
| wren | Wren, given the slot. | Rue stays erodable, in someone else's save. |
| message | Everyone: purge cleared, fates cleared, pieces returned. The owner calls the girl, to tell her what she left running. | Rue stays inside, unfinished, but heard. |
| unseen / overwrite | Hidden endings: unchanged. | — |

### 0.7 Author-level choices

1. **The canon: decided 2026-10-22.** `main`'s premise (Rue is the
   character left running). See `CANON_DECISIONS.md` §1.
2. **Live contact or trace only?** Rev 2 implements *trace only*: the
   well keeps, it doesn't send. If the author wants live contact, the
   plot needs a response to something Rue does now that a recording could
   not produce. Nothing in the game currently provides one, and none is
   faked. (Open.)
3. **The earlier anchor** (§5) changes where a run starts after a death,
   once it is set. It is opt-in in play; the author decides whether it
   stays. (Open.)
4. **The opening's length** stays about 45 s (shorter than the 60–90 s
   budget, on purpose).

### 0.8 Revelation matrix (decided premise)

Evidence is what the game shows or a record states. Belief is what a
character says. They are kept apart: a claim is never filed as a fact
(`ArchivePages` SAID versus SEEN).

| What happened | Evidence in the game | Rue knows | Mira | Wren | Tobben | Archivist | Owner | The player can infer | Unknown |
|---|---|---|---|---|---|---|---|---|---|
| Two people played one save; the girl played slot 2 for 41 h | Opening (two controllers, two figures); the couch memory; the file's 41:07:12 | From MEMORIES on | "The other one, who used to sit next to them" (SAID) | — | — | Files it | Yes | From the opening | The girl's name |
| The figure answered the girl's input, with her two-tap habit | Opening RITUAL; the well clicks with the same gesture | Feels it as her own habit (inherited) | — | — | — | — | Recognises the walk | That Rue carries the girl's gesture | — |
| The save hung at 87% on the last night | Opening INTERRUPT | Remembers the bar | — | — | — | — | Yes | Something was left unfinished | Why it hung (never said) |
| Her hands went still and the figure kept moving | Opening IMPOSSIBLE; Mira's "you move when nobody is" | Not until the file | Noticed (SAID) | "Nobody plays either of us" (SAID) | His "different hand" (SAID) | — | Denies it | Something moves with no one holding it | — |
| She moved away; the owner deleted slot 2 months later | MOVE and DELETE memories; owner notes; the Bin's draft | From MEMORIES | — | — | — | Logs | Yes | Yes | — |
| Rue is the character, still running | CHARACTER FILE, read whole | After the file | — | — | — | Yes (filed) | "You're not her" (true) | After the file | — |
| The girl sent "still have my save?" | Opening's last shot; the Bin; the well's recording | From the well | — | — | — | — | Yes; reply never sent | She remembered the save | Whether she still asks (trace only) |
| Rue is someone anyway | Her choices: Slot 2, Wren, the message; her own gesture (§ opening review) | What she decides | Treats her as a person | Treats her as a friend | Writes her name back | Calls her by name | Doesn't see it, until "...rue?" | What the endings mean | — |

Checked against: the opening (`opening.gd`), the five memories, the well
(`WellSequence`), the Archive's records and CHARACTER FILE, and all six
endings (`Story.ending_text`, `FINAL_EXCHANGE`, `EPILOGUE_TRUE`).

Baseline: `main` = `1e371b1`. The review branch
`claude/last-save-file-prototype-ljwuq4` was at `a38049f` when this
milestone began: the live-art milestone, ten commits ahead of `main`, with
no other open branch ahead of `main`. No local modifications were present.

---

## 1. The truth (internal; the player discovers it in pieces)

**Decided 2026-10-22 (`CANON_DECISIONS.md` §1): `main`'s premise.** The
draft's "literal trapped person" version is superseded; it remains in git
history (`2cb42dd` and earlier) for reference.

**Who played, and what was left.**
- Two real people shared one console "at mum's": the **owner** (player 1,
  never named, always played Arin) and a **girl** (player 2, never named
  outside the game; she typed her character's name, RUE, with her tongue
  between her teeth).
- The girl made Rue and played her for 41 hours. Rue's way of moving, the
  two light taps before a press, the walk to the well: all learned from
  her input.
- The girl moved away. Nobody asked the character. Rue kept running.

**Rue is the character.** Not the girl, and not a copy of her mind: a
character made of someone else's attention who now moves with no one
holding the controller.
- Her memories are bittersweet: she remembers their time together, from
  the character's side of the screen. Those memories don't make her the
  girl.
- She erodes because she is a ghost of a deleted slot, reloaded from what
  is left each time the owner overwrites her (the purge counter).
- She begins with an inherited gesture (the girl's two-tap habit) and, by
  the end, makes choices that are only hers. That is her arc.

**What remains outside.**
- The girl: alive, older, somewhere else.
- The owner: still in the house. The couch, the console, her controller
  under the couch.
- Months after the move she sent "still have my save?". The owner started
  to answer, then deleted slot 2 that same night "for space" (canon of
  2026-10-16, kept).

**What the owner knows and wants.**
- The owner knows they deleted slot 2. "You're not her" is factually true.
  What it misses is Rue's worth: the owner wants the empty slot to stay
  empty, because a thing that moves like her is harder than an absence.

**The people of Ashvale.**
- **Mira, Tobben and Wren are native inhabitants.** They have started to
  keep things between resets since something in the save began moving
  with no one playing it. They are Rue's equals: their lives matter for
  the same reason hers does.
- **Wren** is unfinished cut content left in the village ("nobody
  finished me").
- **The Archivist** is a remnant: cut before release, keeping the records
  nobody reads.
- **Pip** is the fox the girl drew.
- **Arin** is the owner's avatar and has no will of his own.

**Death, deletion, restoration and checkpoints.**
- **Death:** the owner overwrites Rue's current copy (the purge counter).
- **Deletion of a native:** moved to the Recycle Bin.
- **Restoration:** brought back with what the Bin kept; relationship
  history survives.
- **Fraying:** "this body is a file. files can be left." When Rue leaves
  hers, she borrows a piece of someone. A real harm, reversible only by
  returning the piece.
- **The well anchor** (§5) is the one thing the owner cannot overwrite.

**What the well stores.** Unchanged (§0.5): it keeps traces of the real
room, including her message, and plays them back the same way each time.
It does not answer or transmit.

**What each ending is.** Each is a choice about who Rue becomes:
- **Writing herself into slot 2** (escape / RUE): a finished save of her
  own. With the truth, she knows what she is and writes her name anyway.
- **Giving the slot to Wren:** someone else's life matters as much as
  hers.
- **The message:** the owner will tell the girl what she left running.

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

**Superseded 2026-10-22.** The author chose `main`'s premise, so every
"Rewritten" row below has been reverted to its "Old" text, which is now
the current text. The Mira journal entry follows her line ("so who's
holding you?"), and the Bin's truth branch is `main`'s again ("you remember
her writing it."). The table is kept as the record of what the draft
changed.

**C** = conflicts with the (draft's) new truth. Resolution: **Rewritten** (applied),
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

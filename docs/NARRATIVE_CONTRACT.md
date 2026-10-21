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

## 3. Persistence contract

All three layers use stable ids, never node paths. Transient presentation
(timers, animation phase) is rebuilt from state, never saved.

**A. Lasting narrative state** (`OwnerMemory`; survives death, quit and
purge, and is cleared only by a full reset). **Implemented** for:
- `encounters`: id → `{first_session, last_session, count}`. Written when a
  conversation **opens**: meeting someone counts even if you walk away.
- `conversations`: completed conversation ids. Written only when the box
  was read to its last line (`Hud.dialogue_finished`).
- `rel_events`: relationship event id → session it happened in. Written at
  the authored completion point. Examples: `wren.met`, `wren.sheltered`,
  `wren.promised`, `wren.saw_death`, `wren.promise_kept`,
  `wren.promise_broken`, `wren.restored`, `wren.ribbon_returned`.
- `places`: discovered area ids (separate from this session's visits).
- `well_events`: the well's sequence (§6).
- Existing fields, kept: fragments, journal, truth pieces, `mira_quest`,
  `restored`, `npc_fates`, frayed.

**B. Current-world state.**
- Already persistent: `npc_fates`, `frayed`, `restored`, `patched_seams`,
  purge, the husk.
- Session only, unchanged: doors, crates, the owner's awareness, escort
  position, owner moves.

**C. Checkpoint state.** **Implemented**, one anchor (§5):
`anchor = {id, version, session}`. The resume place is found from the
anchor id (`"oob:pillar"`), never from raw coordinates.

**Intentional loss stays explicit.** The death card already lists what is
kept and lost. It now also says where you will wake.

---

## 4. Conversations and relationships

**Selector precedence** (`Relationships.choose`, **implemented for Wren**,
first match wins):
1. **Urgent current condition:** deleted, restricted, frayed, or escorting.
2. **Consequence of a recent event:** she watched you die last run; she was
   restored; a returned piece.
3. **Relationship continuation:** an open promise, or a kept or broken one.
4. **New story topic:** the ask, a truth line, the well.
5. **Brief familiar greeting:** met before, nothing new.
6. **Optional repeat conversation:** the old idle lines.

Recall lines no longer sit in front of a first-meeting introduction. Once
someone has been met in any session, their introduction is skipped.
- **Mira:** met-before skips "Arin! You're up early."
- **Tobben:** already skipped introductions on later sessions; unchanged.

**Witnessing rule.** A character acknowledges only what they saw, or what
the story explains they learned:
- Wren saw a death only if she was escorting you or in the same area.
- Mira hears only what happens in her room, or what the board says.

**Proposed / deferred:** the same selector for Mira, Tobben and the
Archivist; authored expressions for them.

---

## 5. The well anchor (one checkpoint)

**Where.** Under the well, at the pillar out of bounds (`oob:pillar`).
Awareness cools there, there are no threats, and nothing is saved there,
so the owner cannot overwrite it.

**How it is set.** It is set by the well's answer (§6, step 5), never by a
menu.

| Situation | Behaviour |
|---|---|
| First activation | Set by answering at the well. A light appears at the pillar, and Rue says it out loud. Saved at once. |
| Replacing the anchor | There is only one anchor; answering again re-confirms it. |
| Death | Purge +1, as before (unchanged). The next session starts at the anchor instead of Arin's room, after the wake-up. Lasting state is untouched. |
| Save and Exit / Quit | Unchanged: it counts a quit (purge +1); the next session starts in Arin's room. The anchor is for failure, not for leaving. The pause warning says so. |
| Abrupt closure / crash | Counts as a quit (unchanged). Next start is in Arin's room. |
| Phone suspension | Pausing is free (unchanged). Resuming continues where you were. |
| Corrupt save | `SafeFile` recovers `.tmp`/`.bak`. A bad anchor value falls back to Arin's room. |
| Restart after an update | Anchor `version` mismatch: fall back to the room and clear the anchor. |
| Resume place deleted or blocked | Unknown id, or no open floor at the place: fall back to the room. |
| Active escort | An escort is never stored. Death already ends an escort (unchanged rules). The anchor cannot be set while escorting. |
| Major story transition | An ending, a purge or a full reset clears the anchor. |
| Never inside a hazard / dialogue / transition | Activation is refused during a conversation, a scene, a transition or an escort. The resume point is the pillar's landing, which is solid floor that never streams. |
| No death loop | OOB has no killers. Falling into the void is not a death. |
| No duplicated items or reversed choices | The anchor stores a place only: no items, no choices. |

**What this changes from current behaviour (documented):**
- After a death with an anchor, a run no longer always begins in Arin's
  room.
- The room's per-run owner note is skipped on such a run. The owner's
  wake-up line still plays.

---

## 6. The well's sequence

All five steps share one explanation: sound from the real room carries
down the well, and the unsaved space under it keeps what saves lose.
Every step needs the previous one and is stored in `well_events`.
**Implemented.**

| # | Event | Prerequisite | What happens | Evidence |
|---|---|---|---|---|
| 1 | `click`, the oddity | First time near the well | A single real-sounding controller click. "(that was a button. a real one.)" | Sound + line |
| 2 | `tune`, a personal detail | `click`, plus the memory THE WELL recovered | At the pillar below: the music-box tune with one note missing. "(the same note's missing. it was always missing.)" | Sound + line |
| 3 | `words`, not an echo | `tune`; listen at the well (new LISTEN prompt) | Up from below, as typed text: "still have my save?". No one in Ashvale has said it. | Line + journal "lead" |
| 4 | `compared`, a testable clue | `words`, plus the memory DELETE (which holds the same words) or the owner's half-written reply in the Recycle Bin | Rue connects them: the girl's own words, from outside. Journal links the document, the place and the person. | Journal link |
| 5 | `answered`, a costly contact | `compared`; answer at the rim and stay there 2 s, in the open Square (holding [E] is for glitches) | Costs +20 awareness (Arin can see you). Rue answers ("i'm here.") and the anchor is set. | The pillar lights; the next death wakes you under the well |

**How characters change the interpretation.**
- **Wren** (met, after `words`): "You heard it too? It hums sometimes. I
  thought it was just me."
- **Tobben:** "Don't lean over that. Things come back up wrong."

**The first hopeful response has an observable result.** After step 5, a
death no longer sends you to the start: you wake where the well keeps you.

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
| 8 | 39–45 s | Black, then the room | Typed letters cross from the room into the game: "still have my sa" (unfinished). Fade into Arin's room; Rue at the same angle; the first move is hers | A click that matches shot 2 | — | The unfinished sentence; the handoff |

Hands and silhouettes are drawn in-engine, the same pixel style as the
game. No filmed or photoreal people are needed, so no rights questions
arise.

---

## 9. Status

- **Implemented on the branch:**
  - this contract
  - the text rewrites in §7
  - encounters, conversations and relationship events, with the Wren slice
  - People and archive sections
  - the anchor checkpoint
  - the well sequence
  - removal of the iPhone badge
  - the opening animatic
  - the tests named in `docs/CONTINUITY_MILESTONE.md`
- **Proposed:** the selector for Mira, Tobben and the Archivist; a larger
  Square (§10).
- **Deferred:**
  - other areas' expansion
  - a local map for every area
  - full relationship arcs for every character
- **Blocked:** observing unfamiliar players (none available to this
  session); human voice recording.

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

# The dark truth: design proposal

> **Status.** The author chose the direction on 2026-10-19: all three layers (A: the truth, B: shedding,
> C: the virus route), and **Rue stays "she"**. The author then answered the open questions (§6):
> - shedding costs **a piece of someone** only;
> - the virus route is a **seventh ending**;
> - the **RUE ending needs the truth**;
> - the **real girl learns that Rue exists**.
>
> **Layer A is implemented** (§7). Layers B and C are still design only.
>
> Sources are the same as `NARRATIVE_BIBLE.md`: `S:` is `scripts/story/story.gd`, `OM:` is `owner_memory.gd`.
> The line numbers are approximate; the bible's own numbers are from an older commit.

## 0. The idea in one paragraph

Rue believes she is the girl who moved away. She isn't. She is the character that girl played. Forty-one hours of someone else's hands taught a save file how to move, what to fear and who to miss. That save was left behind on another person's console. When it was deleted, what survived didn't survive whole: it rebuilt itself out of whatever the save still held. The other characters each hold one piece of that truth and help her find it. Once she knows she is only an intelligence, she learns she can leave a body behind and take another to shake off the owner. Every new body is borrowed from someone. A player who keeps borrowing, and keeps breaking things, becomes what the owner always said she was: something that spreads, and that wants out of the console and into the owner's computer.

The three layers:

| Layer | What it is | Kind of work |
|---|---|---|
| **A. The truth** | Rue is the character, not the person; she survived by patching herself from the save | Writing, plus one new late reveal |
| **B. Shedding** | Leave the current body to wipe what the owner has learned, at a cost the player picks | A new mechanic |
| **C. The virus route** | Choosing to consume and corrupt leads to an infection ending: revenge, out of the game | A new ending branch that builds on `overwrite` |

Revenge stays a **temptation the player chooses**, never the game's only answer. The gentle endings (rue, message, wren, unseen) remain and stay reachable.

---

## 1. Layer A: the truth

### 1.1 What is already true, and what changes

The game already half-says this. The bible's INTERPRETATION (§3.0): *"the intruder is save data that remembers being played."* Rue's memories are told from the player's seat ("my character walked into the well", "i typed it"). The owner already separates the person ("the real you", S:480) from her character ("where her character used to stand", S:180).

**Proposed canon:**
1. **Rue is the slot-2 character, not the second player.** She is an intelligence that grew out of a save: 41:07:12 of inputs, habits and choices. The memories she recovers are the player's, recorded in the way she was played. She remembers them as her own because she has nothing else.
2. **"Saved on someone else's computer."** The save lived on the owner's console, at the owner's house. The girl moved away; her character stayed in someone else's machine. Nobody asked the character.
3. **She did not survive deletion whole.** The cut-content ghost (author decision 1) is only a seed. To come back she patched herself from what was nearby:
   - the `slot2_backup.sav` in the bin;
   - cut content;
   - **pieces of other characters**, small things she doesn't know she took.

   The body parts she "regains" one per memory (S:77–83) are partly borrowed.
4. **The owner stays human.** They never find out what she is before the player does. Their recognition lines already fit: 3 memories, "...you move like someone i used to know"; 5 memories, "no. you can't be. i deleted you." (S:246–247). They recognise the *movement*, the thing that was learned from the girl.

### 1.2 Who helps her find it

Each character holds one piece. Each piece appears through action, never as exposition, and each one has to be earned. **As built:** Mira, Wren and Tobben say theirs once ever; Pip's is a debug outline on its ledge. The Archivist's file needs every memory and **any two** of those four pieces, so no single deleted character can lock the truth away.

| Character | Their piece | How it surfaces (proposal) |
|---|---|---|
| **Mira** | "You're not Arin. Who are you?" is a real question: Mira has watched Arin's body all game and knows what a played character looks like when nobody is playing it | Once you have 5 memories: Mira notices Rue moves on her own, with nobody's hands behind her. "*Arin only moves when they're here. You move when no one is.*" |
| **Wren** | Wren is cut or unfinished content, so she has never been played; she is the only one like Rue (bible open question 11) | On the escort, Wren asks who made Rue. Wren's ending gains a line: two things nobody is playing |
| **Tobben** | The guest book's second name. He remembers the girl's *handwriting*, which isn't Rue's | Once the guest book is restored, his recall line notes that Rue writes her own name differently |
| **Pip** | Pip fell after the character, not after the girl. Pip knows Rue's first shape | Out of bounds, Pip leads Rue to a place where the floor shows her original silhouette, and parts of it don't match her |
| **The Archivist** | Keeps the record | A new book, **CHARACTER FILE · RUE**, readable once all five memories are found. It reads as a data sheet: *"behaviour: learned from player input, 41:07:12. player: [moved]. character: still running."* |

### 1.3 The reveal

A sixth beat after the five memories, in a later run. It is not a sixth fragment: fragments are memories, and this is a fact.

- **Trigger:** reading the Archivist's CHARACTER FILE with all five memories and two of the four pieces (Mira, Wren, Tobben, Pip). In practice a run-2+ moment.
- **Rue's line:** *"those were her hands. i'm what she left running."*
- **What it opens:** shedding (layer B). Once she knows the body is a file, she knows a file can be left.

### 1.4 Endings under A

The text changes; the conditions don't.

| Ending | Reading under A |
|---|---|
| **rue** | **Now requires the truth** (author, 2026-10-19). The owner chooses LOAD for a character they know isn't her, and keeps it anyway. It becomes more generous, not less |
| **message** | The slot returns to the *real* girl: "the real you" (S:480) now says what it always meant. **Knowing the truth, Rue asks the owner to tell her about Rue, and the owner promises to** (author: she learns that Rue exists) |
| **wren** | Two unplayed things; Rue gives the slot to the only one like her |
| **escape** | Survival without knowing what she is (unchanged) |
| **unseen** | Unchanged |
| **overwrite** | Becomes the first step of layer C |

---

## 2. Layer B: shedding

### 2.1 The verb

Rue leaves her current body behind, as an empty husk the owner can see, and steps into a new one.

**What it wipes:** the owner's learned traces of *this* Rue.
- `route_memory` and `session_spots`: Arin stops anticipating her route.
- `session_helpers` for the run: the helpers are no longer tied to her, so they aren't punished if the run ends badly.
- The current awareness drops a tier.

**What it never wipes** (pillar 1, the owner is a person):
- `deaths_log`, `patched_seams` and owner notes. The owner remembers what *they* did.
- **How she moves.** The owner recognises gait, not clothes. After a shed, the console shows a fair, specific tell: "*> new face. same walk.*" The recognition lines (S:246–247) still escalate.

### 2.2 The cost, which the player picks (pillar 2: previewed, never revealed afterwards)

The new body has to come from somewhere. **The cost is always a piece of someone** (author, 2026-10-19). Who it's taken from, and what they lose, is shown in full before committing:

| Cost | What happens | Persistent? |
|---|---|---|
| **A piece of someone** | The new body borrows from a character nearby: Wren's pigtail ribbon, Mira's colour, Tobben's voice. That character is **frayed**: they lose that piece and a line of their own, and they remember | Yes. A new `npc_fates` value, `"frayed"`; the Recycle Bin can return the piece |

This ties B back to A: it is how she survived the first time, now done on purpose and in the open. Memories are never the price, so "fragments survive everything" (bible §5) stays true.

### 2.3 Limits

- **Where:** only where the owner can't see: the archive, out of bounds, the bin's shadows. That makes it a decision about where to stand, not a panic button.
- **How often:** at most once per run at first, possibly twice later. It needs a playtest; no number is promised.
- **Reading is safe** (pillar 3): the cost choice is a held moment, and nothing advances while it's open.
- **It is not a glitch.** It doesn't use the glitch meter and doesn't count toward `session_glitches`. The cohesion pass rejected new glitches; this is a separate, rare act. **Author note:** it is still a new verb, against that pass's "no new glitches" rule, and it is in by the author's choice on 2026-10-19.

### 2.4 The owner adapts (rules, not machine learning)

| What the owner notices | What they do | Fair because |
|---|---|---|
| A husk left behind | Arin stands guard over it next run. The note: "*> you left something in my room.*" | Seen, said, answerable: shed somewhere else |
| Two sheds in one run | The owner watches the hiding places: awareness decays more slowly in the bin's shadows | Shown on the goal line |
| A frayed character | The owner notices the damage before Rue does: "*> wren's ribbon is gone. did you do that.*" | The owner reacts to cruelty, not to a timer |

---

## 3. Layer C: the virus route

### 3.1 How you get there

C is the dark mirror of the reconciliation endings: an accumulation of choices, never one switch.

**A new persistent counter, `consumed`, goes up for:**
- each **piece of someone** taken while shedding;
- each run that ends in `overwrite`;
- each restore *refused* when it was offered.

**It goes down for:**
- returning a piece from the bin;
- restoring a character;
- the message ending, which already clears `npc_fates` (OM:243–246).

**Thresholds** (to be tuned):
1. First, the tone shifts. Characters flinch from Rue, the music box detunes, and Pip keeps its distance.
2. Then the Slot 2 choice gains an option: **"Don't take the slot. Take the console."**

### 3.2 The ending: "out"

- Rue spreads through the save: Mira's room, the square, the bin. Each frayed character becomes a part of her.
- The final exchange: the owner, no longer cruel, only scared: "*> what are you. you were HER.*" Rue: "*(no. i was what she left here. you left me here too.)*"
- **The epilogue happens on the owner's side of the screen, staged entirely inside the game.** A drawn, obviously in-game "desktop" with files being renamed and the cursor not theirs. A last line from outside: the owner unplugging the console, and Rue's line from somewhere that is not the console.
- **Title after:** the overwrite title (S:42, "SLOT 2 · ARIN · (corrupted)") gets its meaning: bible open question 10 is answered by this route.

### 3.3 Hard limits for this route

- **Everything stays inside the game window.** It never reads, writes, renames or lists real files. It never opens other windows or changes system settings. It never imitates the real operating system's dialogs closely enough to be mistaken for them. The "desktop" is plainly drawn in the game's own pixel style.
- **No real-world technique.** Spreading is shown as story (rooms recolouring, characters merging), never as anything resembling real malware.
- **No achievement-style reward** for cruelty beyond the ending itself. The route is a tragedy, and the title screen after it should feel like one.

---

## 4. Canon changes this requires

Each item needs the author's sign-off.

| # | Change | Lines touched (approximate) |
|---|---|---|
| 1 | Rue is the character, not the person (promotes the bible's §3.0 INTERPRETATION to CONFIRMED) | Bible §3.0–3.1; no shipped line contradicts it. Check S:144 ("my name was RUE. slot 2 was mine.") still reads right; it does: the name and the slot were the character's |
| 2 | She patched herself from other data, including other characters | New lines: the Archivist (`archive.gd`), the Recycle Bin's `slot2_backup` text |
| 3 | ~~Fragments can be lost~~ Dropped: shedding costs only a piece of someone | — |
| 4 | A new NPC fate, `"frayed"` | `OM.npc_fates`, the bin restore logic, each character's recall lines |
| 5 | `overwrite` becomes the gate to the virus route | `is_reckless_run()`, `ENDING_RETURN`, title S:42 |
| 6 | A seventh ending, `out` (author: yes) | `reach_slot2`, endings tables, title screen, `endings_seen` |
| 7 | The cohesion pass's "no new glitches" rule gains an exception for shedding | `COHESION_PASS.md` pillars note |
| 8 | Mira, Wren, Tobben, Pip and the Archivist each gain one truth line | Their area scripts and `Story.recall` |

**Unchanged:** Rue stays "she". The owner stays unnamed and human. The author decisions of 2026-10-16 stand (cut-content ghost; message, then delete; Rue says both lines). Multiplayer stays out of this milestone.

---

## 5. Implementation plan (after approval)

Each phase ships with tests that fail without it, and a bot run per ending. Persistent consequences are not weakened to make tests pass.

1. **Phase A (writing first).** The truth lines for five characters, the CHARACTER FILE book, the reveal beat, and the ending text revisions. Canon tests (`test_canon.gd`) pin the new lines. Smallest risk; it can ship alone.
2. **Phase B (shedding).**
   - The verb and the cost choice: a held moment, with a full preview.
   - The husk, the `frayed` fate and the gait tell.
   - The owner's adaptation rules.
   - Tests: the wipe list, the keep list, and costs that persist across a quit.
   - A playtest question in `PLAYTEST_PLAN.md`: do players understand what they'll lose before they choose?
3. **Phase C (virus route).**
   - The `consumed` counter and the tone thresholds.
   - The new Slot 2 option, the `out` ending and its in-window epilogue.
   - A bot that takes the cruel route end to end.
   - An art and audio pass for the detuned states.

**Prerequisite:** [PR #3](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/pull/3) and [PR #4](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/pull/4) merged (or this work stacks on them).

## 6. Questions for the author (answered 2026-10-19)

1. **The cost menu:** only the piece-of-someone cost.
2. **The `out` ending:** a seventh ending; `overwrite` stays as the step before it.
3. **Is the reveal optional?** No: the RUE ending requires it.
4. **Does the real girl learn about Rue?** Yes, in the message ending, when Rue knows the truth.

## 7. Layer A as built

| Piece | Where | Test |
|---|---|---|
| `truth_pieces`, `knows_truth` (persistent, like memories; cleared only by a new game) | `owner_memory.gd` | `test_dark_truth.test_mira_tells_rue_once_she_remembers_everything` (survives a reload) |
| Mira and Wren: once every memory is back; Tobben: once the guest book has RUE again. Said once ever, before their usual lines | `Story.TRUTH_LINES`, `Story.truth_line`, `npc.gd` | `test_mira_…`, `test_tobben_notices_the_handwriting` |
| Pip: FIRST HITBOX on Pip's ledge, with Pip found and every memory | `out_of_bounds.gd` | `test_pip_shows_the_first_shape` |
| CHARACTER FILE beside the Archivist's desk: locked (memories), unreadable (fewer than two pieces), whole; then the reveal scene "WHAT I AM", which holds the owner | `archive.gd`, `world.reveal_truth` | `test_the_character_file_opens_in_three_steps` |
| The Archivist points to the file once every memory is back | `archive.gd` | (text) |
| RUE needs every memory **and** the truth; otherwise the slot is the plain escape. Records and title follow | `world.gd`, `owner_memory.record_win`, `title.gd`, `Story.ENDINGS_RECORD` | `test_rue_needs_the_truth`, `test_rue_with_the_truth`, `test_records` |
| Endings: RUE's epilogue ("you're not her… it presses LOAD anyway"), Wren's ("two things nobody plays"), the message ending tells the real girl | `story.gd` | `test_the_message_tells_the_real_girl`, `test_canon.test_rue_is_what_she_left_running` |

**Not done yet:** a portrait or art pass for the reveal (it reuses Rue's *remembering* face); recorded voice for the new lines (they are in the voice manifest's lists, text only); any human playtest of whether the pieces are findable without a guide.

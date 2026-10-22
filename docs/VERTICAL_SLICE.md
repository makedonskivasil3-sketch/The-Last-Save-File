# Vertical slice: the first route, made playable and testable

Branch: `claude/last-save-file-prototype-ljwuq4` (PR #10, draft). It is the
designated branch for this work and is separate from `main`; nothing is
merged. The canon here is the **proposed** contract
(`docs/NARRATIVE_CONTRACT.md` §0).

The experience this slice must deliver:
> "I entered someone else's saved world. The people inside are slowly
> losing themselves. They remember what I do. I may be able to escape, but
> leaving them behind now means something."

## 1. Starting point (verified 2026-10-22)

- **Hashes.** `origin/main` = `09aeb3b`. The review branch is `d8e868b`,
  36 commits ahead of `main`, with `main` as its ancestor. No other branch
  is ahead of `main`.
- **CI.** Green on `537df8c` (the code head) and `d8e868b` (documents).
- **Last local verification.** 547/547 strict suite on `537df8c`; 5/5
  ending bots; three exports; both browser checks.
- **Read for this audit:**
  - the release readiness, coherence, continuity and narrative contract
    documents;
  - the narrative bible (superseded in part), story script, caption and
    voice contract, art direction and map design.
- **Code inspected:** `opening.gd`, `title.gd`/`title_art.gd`,
  `world.gd` (transitions, sessions, anchor), `npc.gd`/`relationships.gd`,
  `archive_pages.gd`/`journal_panel.gd`, `owner_memory.gd`, `sfx.gd`,
  `village_square.gd`, `area.gd`, `hud.gd` (prompt placement), and the
  endings in `story.gd`.

## 2. Audit

### 2.1 Confirmed defects (each checked in the code or reproduced)

| # | Defect | Evidence |
|---|---|---|
| D1 | **Closing the game during the boot text counts as quitting** (purge +1), before the player has controlled anything. | `OwnerMemory.begin_session()` sets `last_exit = "active"` and opens the session at `World._ready`. The boot text plays after that, so `record_quit()` (window close) and crash detection apply from the first frame. Reproduced by `test_vertical_slice` (first version, failing). **Fixed:** the World's session is deferred (`begin_session(true)`) and armed when Rue is first controllable; an unarmed quit or crash is undone. |
| D2 | **A controller disconnecting mid-opening or mid-run is not handled.** No pause, and no message. | No `joy_connection_changed` handler anywhere in `scripts/`. **Fixed:** losing the pad in use opens the pause menu (`World.controller_lost`); the opening already holds on focus loss. Untested on real hardware. |
| D3 | **The pause map, the HUD clamp and the Owner's nav fallback assume one 640×360 screen.** | `hud.gd:1185,1198`; `owner_avatar.gd:333`; `area.gd:205` (`BACKDROP_SIZE`). |
| D4 | **The Archivist chooses his lines outside the shared selector.** He has no familiar greeting route and no witnessing rule. | `archive.gd` `_archivist_lines` (documented in `COHERENCE_MILESTONE.md` §5). |

### 2.2 Design weaknesses supported by observable behaviour

| # | Weakness | What is observable |
|---|---|---|
| W1 | **The opening is watched, not played.** For 45 s the only input is "hold to skip". The habit (two taps) is shown, not performed. | `opening.gd`: all events are on a timer. |
| W2 | **The title is one flat plane** at a fixed distance, with nothing in front of or behind the figure. | `title_art.gd` draws wall, floor, TV and Rue on one plane. |
| W3 | **The Square is a single screen.** Its exits are a few steps from the centre, so there is no route choice: the Archive is always the same 30-step walk past Arin. | `VillageSquare.bounds = Rect2(40,36,560,256)`. |
| W4 | **Nobody notices that Rue came back.** Waking at the kept place gives one line of Rue's own; the first person she meets after a death reacts only if they saw it. | `world.gd` `ANCHOR_NOTE`; `Relationships.wren`. |
| W5 | **A boot text of seven system lines** is the first thing after the opening: consecutive explanation panels. | `Story.BOOT`, `world.gd` `_begin_session`. |
| W6 | **There are no Save and Exit or Continue semantics.** Quitting is always punished, and the menu says so. This is honest, but it is a commercial risk: a player who stops for dinner pays purge. | `pause_menu.gd` `_ask_quit`. |

### 2.3 Proposed improvements (this slice implements the first five)

1. **An interactive opening** (§4): the player performs the ritual, sees
   it fail, and makes the impossible move.
2. **A layered, dimensional title** with bounded parallax and a
   reduced-motion mode.
3. **A bounded camera, and a Square half again as wide**, with purposeful
   subspaces and a shortcut that is earned.
4. **A character-focused checkpoint scene:** someone notices that Rue
   came back.
5. **Sessions start counting when play starts**, not at the boot text
   (D1); a controller disconnect holds the game (D2).
6. Proposed only: Save and Exit / Continue (§6).
7. Proposed only: a shorter boot text (W5). It is kept for now; its lines
   are canon the author approved.

### 2.4 Already implemented (kept, not redone)

- Persistent encounters and ordered relationship events (v3).
- One selection path, with Wren, Mira and Tobben arcs.
- The six-section archive with SEEN / SAID / RUE / UNKNOWN.
- The map's four states.
- The kept place under the well (opt-in, earned by the tune).
- The well's honest evidence.
- Caption pages over a single take; manual advance; text speed, including
  instant; subtitle size and background; history replay; the speech-rate
  setting.
- Audio unlock and recovery, without a visible badge.
- Exact-ending bots and the browser checks.

### 2.5 Claims that need human playtesting

None of the following is claimed. Each needs unfamiliar players (§7):
- whether the first objective is understood;
- whether the opening's anomaly reads without narration;
- whether players care about Mira, Wren or Tobben;
- whether the kept place is understood;
- whether players want to continue after the demo;
- what value they perceive.

## 3. The milestone route and its experience specification

Title → interactive opening → first relationship (Mira) → first threat
(the owner's attention in the room, then Arin's cone in the Square) →
Square exploration → first recovery anchor (the place under the well) →
meaningful discovery (the well's words; a memory) → continuation hook.

Timings are provisional targets. They are measured in play only where
noted.

| Stage | Knows | Wants | Fears | Can do | What changes | Why continue |
|---|---|---|---|---|---|---|
| Title (any) | A girl, a TV, a save that never finished | To see what this is | — | Load Slot 1 | — | The figure's eyes are two points of light |
| Opening A, the ritual (~15 s) | Two people play together | To finish the evening together | — | Walk Rue beside Arin; press to save (her two taps happen) | The save starts | It feels like a memory |
| Opening B, the interruption (~10 s) | Player 1 left; the save stuck at 87% | For it to finish | That it won't | Press again: the familiar action fails | The sound thins; her hands go slack | She can still move. Why? |
| Opening C, the impossible action (~10–25 s) | Everything is paused except her | To follow the sound | Being alone in a paused game | Walk to the well at the picture's edge; look out | She turns to the real room | Something outside can see her |
| Opening D, the handoff (~6 s) | Months later her message came; the reply stopped | — | — | (skippable) | The room fades in, at the same angle | Her first move in the room is the player's |
| Room (1–4 min) | Someone else's save; a note; Mira | To get out | The owner's attention (the bar) | Read, talk, find a memory, glitch | Mira is met; a memory is recovered; the wall tears | "Find Wren in the square." |
| Square (3–6 min) | A village; Arin's cone; a well that clicks | To find a way on | Arin seeing her | Hide by Wren, cross or take the lane, listen at the well | Wren is met; the well clicks with **her** gesture | The well is deeper than it should be |
| Under the well (2–4 min) | The tune, one note short | To understand | Falling | Cross the floor; take THE WELL; keep her place | The anchor is set; Pip | If taken, she wakes here |
| A death, then the return (≤1 min) | She came back | To know what's left | Losing people | Climb up | **Wren noticed** (§5); her place by the crates | Someone is waiting for her |
| Hook | The Archive is east; "still have my save?" | To find out who asked | The owner learning her | Go east, or to the Edge with Wren | — | Who is she? |

## 4. Revelation table (the primary reveal: the proposed canon)

| | |
|---|---|
| **Underlying truth** | Rue is the part of the second player that stayed in the interrupted save (contract §0.1). |
| **Mira believes** | Rue is "the other one, who used to sit next to them". True, though she can't know why. |
| **Wren believes** | Rue is a ghost of someone who played; nobody plays either of them. Half true. |
| **Tobben believes** | The name RUE is just a name that went out of his book. |
| **The owner believes** | "You're not her": something is wearing her walk. Denial. |
| **The player has observed** | The two taps before a press, which they performed in the opening; the save stuck at 87%; Rue moving with nobody's hands on her; the well's click with the same two taps. |
| **Early clues (three channels)** | (1) **A bodily habit:** her two taps, performed in the opening, heard again at the well, and noticed by Mira ("your hands hold something that isn't there"). (2) **A character remembering outside their script:** Tobben's guest book had two names; Mira "remembers the dark in between". (3) **A document separating the costume from the occupant:** the CHARACTER FILE, "costume rebuilt from…; player: still in session". |
| **Plausible first readings** | She is a glitch; a copy of the player; a ghost of a deleted character. |
| **Resolving evidence** | The file read whole; her memories are told from the second player's seat; the habit the player performed is hers. |
| **The playable recognition** | Proposed, implemented in part: at the well, the click repeats the two taps the player made in the opening. The full reveal needs the player to perform the gesture in front of the file. This is listed as the next milestone, not claimed. |
| **The decision it unlocks** | RUE at Slot 2 (write herself in, knowing who she is). The message ending tells the girl where the rest of her is. Leaving now means leaving people who remember her. |

The rules are unchanged:
- **The well keeps recordings; it is not live contact.** Live contact
  would need a present-time response that a recording could not produce.
- **No extra twist** may undo relationships.

## 5. Characters: distinct emotional functions

| | Desire | Ordinary habit | Limitation / fear | Imperfect trait | Offers Rue | Needs from Rue | Trust action | Changed interaction |
|---|---|---|---|---|---|---|---|---|
| **Mira** | To be more than a line; to leave the room | Sets out two cups (one forgotten) | Locked in the room; the blank smile (reset) | Talks too much when nervous; a little bossy | The first welcome; warnings; "find Wren" | To be taken outside; to be believed | Walking her to the board | Whispers past the owner's lock; remembers the death she saw |
| **Wren** | To see the Edge | Tugs her ribbon; stands by the crates | Being cut again; being left | Blunt; teases ("you smell like the bin") | Shelter from Arin's eyes; the way | A promise kept | Standing beside her while Arin passes | **Notices that Rue came back** (§5a); half-remembers a broken promise |
| **Tobben** | Order; his guest book whole | Counts under his breath; shop patter | His script makes him report her | Cheerful to the point of being annoying; guilty | A name; the guest book | Her name written back | Writing RUE back | Reports less; jokes about her "tab" |

### 5a. The checkpoint scene implemented in this slice

- **When it plays:** after Rue wakes at her kept place and climbs back
  into the Square, if Wren has been met, wasn't deleted, and isn't
  escorting.
- **What happens:** Wren has moved to the well rim and has tied her spare
  ribbon to it as a marker, "so you'd find your way up". It is a short
  exchange, read at the player's pace.
- **How it commits:** `wren.marked_well` is written only when the
  exchange is read whole. Interrupted, it plays again the next time.
- **After that:** the ribbon stays on the rim in later runs, as a quiet
  sign that someone waited. The archive lists it.
- **Owner pressure:** the owner is held while the conversation is open
  (existing reading hold).

## 6. Save behaviour: what survives, and a proposal

**What survives today:**

| Event | What survives | What is lost | Where the next run starts |
|---|---|---|---|
| Death | everything lasting (A), world consequences (B), the kept place (C) | the attempt (T); purge +1 | the kept place if set, else Arin's room |
| Retry (after the death card) | same as death | same | same |
| Quit (pause menu) | A, B, C | the attempt; purge +1 (the menu warns) | Arin's room |
| Application closed mid-run | A, B, C | the attempt; purge +1, counted on the next launch | Arin's room |
| Crash | same as closed | same | Arin's room |
| Before play starts (opening, boot text) | everything (**fixed in this slice**, D1) | nothing | as before |
| Ending | A; some B (a message ending clears purge and fates) | the kept place (an ending is a new start) | Arin's room |

The kept place is a **place**, not a snapshot. Position, items, an escort
and the owner's awareness are not saved.

**Commercial proposal (not implemented; the author decides):**
- **Save and Exit** (the pause menu): end the session without purge.
  Resuming continues where the player was (the kept place, else the room),
  with a short "you were away" line from the owner.
- **The story action stays separate.** A deliberate in-world "leave the
  save" (glitching out of the game) keeps today's purge. It is the
  diegetic quit, and it is clearly labelled as one.
- **Closing the window** counts as Save and Exit, not as running away.
- Purge from deaths is unchanged.

# Decisions only the author can make

**Integration update (26 October 2026):** the author requested merging the
review branch into `main`. The integration/pacing milestone is recorded in
`IMPLEMENTATION_OCT26.md`; the status below is the historical decision record.
The decided character-left-running premise is preserved. No new live-contact,
Save and Exit, production-art or commercial-publishing decision is implied.

**Status (2026-10-22, later the same day):**
- **§1 is decided.** The author chose `main`'s premise, and the branch now
  carries it (below).
- **§2–§6 are still open.** The review branch implements proposals for
  them, and approval to improve gameplay does not decide them.
- Nothing here is merged to `main`, and the game has no player-facing
  canon toggle.

## 1. Who Rue is (the central reveal): DECIDED, `main`'s premise

**The author's decision (2026-10-22), in their words:**

> I prefer Rue being the game character left running after her player
> moved away. It gives the game a more distinctive emotional question: can
> something created through someone else's attention become a person with
> a life of her own? [...] Her memories become bittersweet: she remembers
> their time together, but those memories don't make her the girl. Mira,
> Wren and Tobben become her equals [...]. The endings become harder
> choices [...]. The owner's denial becomes more interesting: "you're not
> her" can be factually true while completely missing Rue's worth. [...]
> I would keep the two-controller opening, but frame its impossible moment
> as a character beginning to act after her player stops. Introduce her
> through a familiar gesture she inherited; later, let her make a gesture
> or choice entirely her own.

**What was done:**
- The constants listed below were reverted to `main`'s text, as this
  section said would happen.
- Also reverted: Mira's journal entry (which followed her line), the Bin's
  truth branch, and the RUE hints ("what you are").
- `NARRATIVE_CONTRACT.md` §0 and §1 were rewritten to the decided premise,
  with a revelation matrix (§0.8).
- The opening and Rue's own gesture follow the author's direction
  (`docs/OPENING_REVIEW.md`).

The comparison is kept for the record.

| | `main` (`09aeb3b`) | Draft branch (proposal) |
|---|---|---|
| **Premise** | Rue is the *character* the girl played: 41 hours of someone else's hands, left running in the save after she moved away. "Not the girl, but what she left behind." | Rue is the *part of the girl* that was playing when the save hung at 87% the night before the move. A real person wearing her character, still in the save. |
| **CHARACTER FILE** | "behaviour: learned from player input", "player: moved away", "character: still running", "rebuilt from: …" | "save: interrupted at 87%", "player: still in session", "character: worn by the player", "costume rebuilt from: …" |
| **Rue's last lines in the file** | "(i'm not her.)" / "(i'm what she left running.)" | "(i'm not what she left running.)" / "(i'm what she left.)" |
| **After reading** | "so this body is a file. files can be left." | "so this body is a costume. costumes can be left." |
| **Mira's clue** | "Arin only moves when the owner's there. You move when nobody is. So who's holding you?" | "When you stand still, your hands hold something that isn't there. Like a controller." |
| **Message ending** | "tell her what she left running." | "tell her where the rest of her is." |
| **Rue ending card** | "slot 2 was hers once. now it's yours." | "slot 2 was yours once. now it's yours again." |
| **Opening** | (Film) | The interactive opening has the player's press become her habit, and her hands lie still under PAUSE while the figure still answers the player. This **supports either premise**: it shows *someone* still playing. It names neither. |

**Where the disputed text lives (for review):**
- `scripts/story/story.gd`: the header comment; `CHARACTER_FILE_*`;
  `TRUTH_LINES.mira`; `TRUTH_AFTER`; the message-ending lines;
  `MESSAGE_SORRY_TRUTH`; the ending text for `rue`.
- `docs/NARRATIVE_CONTRACT.md`: §0 and §1.

The rest of the branch's work does not depend on which premise is chosen:
- relationships and the journal;
- the wider Square, the lamp and the gate;
- the checkpoint scene;
- the opening's interaction;
- the integrity fixes.

**Consequences:**
- **Main's premise** keeps the story about a made thing outliving its
  maker. It is easier to explain, and the endings already fit it.
- **The draft's premise** makes the stakes literal. A person is trapped,
  so the message ending becomes a rescue cue. That raises expectations of
  an outside-world payoff the game does not provide: the well only keeps
  recordings (§3).

**Decision:** `main`'s premise (above).

## 2. The kept place under the well (the earlier anchor)

- The draft offers "keep my place here" once the well's tune has played.
  A death then wakes Rue under the well instead of in Arin's room.
- **Consequence:** retries are shorter, and the first route is less
  punishing. It also changes the rhythm of returns that the original
  design intended. The quit and crash rules are unchanged.
- **Recommendation:** keep it, because it is opt-in and teaches the
  well. Revisit it after the unfamiliar-player round.

## 3. Live contact or trace only

- The well keeps recordings; it doesn't carry messages. Nothing in the
  game produces a present-time response.
- **Recommendation:** stay with trace only unless a real
  present-time-response mechanic is designed.

## 4. Save and Exit / Continue: DECIDED, option (b), built 2026-10-27

**Decision:** Save and exit at a safe moment costs nothing and resumes once.
Quitting still raises purge, and so does closing a web tab. See
`SAVE_AND_EXIT_PROPOSAL.md`. The original notes follow.

### Original notes

- Today, quitting mid-run raises purge. That is the owner's rule, and the
  pause menu warns about it.
- **The proposal** (`VERTICAL_SLICE.md` §6): a Save and Exit that does
  not cost purge, with the story's "leave the save" kept as the costly
  quit.
- **Consequence:** friendlier for commercial play, but it weakens "the
  owner remembers that you ran".
- **Recommendation:** decide before the demo. It changes what closing the
  window means.

## 5. The demo endpoint (built behind a flag, off by default)

- **The proposal:** the demo ends under the Archive's arch, before the
  CHARACTER FILE, the Edge or any ending
  (`COMMERCIAL_DIRECTION.md` §4).
- **Built, not shipped:** it is on only in a build with the `demo`
  export feature, or with `-- --demo` / `?demo=1`.
  - The arch shows "still have my save?" and closes the session cleanly:
    no purge, no quit, no ending seen.
  - The Archive, the Bin and the Edge are never loaded.
  - `tests/test_demo.gd` checks that every exit from the kept areas leads
    to a kept area or to the end card.
  - **No demo export preset exists, and nothing has been published.**
- **Recommendation:** approve. It stops before the reveal.

## 6. The opening's implication

- **The draft's interactive opening:** the player's press becomes her
  two-tap habit, and under PAUSE her hands lie still while the figure
  still answers the player.
- With the decided premise, the impossible moment is a character
  beginning to act after her player stops (the author's direction).
- **Done:** the opening is reframed that way (`docs/OPENING_REVIEW.md`).
  The author should confirm it in play.

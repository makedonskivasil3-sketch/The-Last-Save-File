# Decisions only the author can make

**Status (2026-10-22): none of these has been approved.** The review
branch implements proposals. Approval to improve gameplay does not decide
any of them. Nothing here is merged as canon, and the game has no
player-facing canon toggle.

## 1. Who Rue is (the central reveal)

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

**Recommendation:** decide this before any public demo. The demo endpoint
(§5) stops before the reveal, so the demo can ship with either.

**If main's premise is chosen:** revert the listed constants to main's
text, and nothing else.

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

## 4. Save and Exit / Continue (not implemented)

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
- **Recommendation:** approve. It is spoiler-safe for either premise.

## 6. The opening's implication

- **The draft's interactive opening:** the player's press becomes her
  two-tap habit, and under PAUSE her hands lie still while the figure
  still answers the player.
- With main's premise, this reads as "the player is her hands now".
- With the draft's premise, it reads as "she is still in there".
- **Recommendation:** keep the opening as built, and confirm it once §1 is
  decided.

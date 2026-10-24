# Review of `34b6823` (24 October 2026)

**Baseline (checked before editing):** head `34b6823`, the same as
`origin/claude/last-save-file-prototype-ljwuq4`. `main` is `09aeb3b`. The
worktree was clean. There is no `AGENTS.md` or `CLAUDE.md`. PR #10 is an
open draft and is not merged. The brief's CI claim (run 39850118655 green,
614 passed) was not re-fetched. The local suite was re-run instead (below).

Earlier documents (`OPENING_REVIEW.md`, `REVIEW_OCT22.md` and the rest)
describe their own heads. They are history, not the current state.

**Not redone, as instructed:** input ownership, caption continuity, the
gate and lamp response, the floor warning, the Bin shelter, guidance, and
the independent RNG.

## Ledger

| Kind | Item | Evidence | Status |
|---|---|---|---|
| Confirmed defect A | `Hud._show_dialogue_line()` emitted `line_shown` as the last page opened, with `visible_characters` still 0. Journal facts and truth pieces were learned from text not yet on screen. Walking away mid-reveal still taught them | `test_a_fact_is_not_learned_when_its_page_opens` and `test_a_truth_piece_waits_for_its_line` failed | **Fixed** (see "Line milestones" below) |
| Confirmed defect B | `World._load_area()` called `OwnerMemory.observe()` for every NPC in the area, on screen or not. Back from the Archive at the Square's east end, a Wren deleted meanwhile was recorded as seen deleted ("Deleted: you saw them gone"), though her corner was off-screen | `test_coming_back_from_the_archive_does_not_see_someone_off_screen` failed (`{state: deleted}`) | **Fixed**: Rue observes only people inside the framed screen. This is checked on arrival and every 0.25 s; talking to someone also counts. There is no line-of-sight test. Old saves keep their sightings, and "Since then: unknown" still shows for an earlier run's sighting |
| Confirmed defect C | Each conversation with Tobben scheduled its own report, with no pending guard. Three quick talks meant three "+12 · tobben told on you". A report could land during another conversation or a scene, and written Tobben (voice taken) still "said" things to the owner | Four regressions failed (3 reports; landing during dialogue; written Tobben reporting; no guest-book difference) | **Fixed** (see "Tobben's report" below) |
| Confirmed defect D | `StoryPacing.pages(text, page_chars)` cut unbroken text at `PAGE_CHARS` (180), not `page_chars`. A long identifier at a small limit (large subtitles) made pages longer than the box allows | `test_unbroken_text_pages_at_the_given_limit` failed at limits 40 and 90 | **Fixed**. History keeps the whole source line once (tested) |
| Confirmed wording defect | The message ending said the girl would "hear that a part of her stayed behind". That reads as the girl herself, against the canon (Rue is the character) | `test_the_message_ending_says_it_is_the_character` failed | **Reworded**: "she's about to hear about the character she left running". The owner says "she should know her character is still running" |
| Design weakness | The present day was undated in the first minute. "Months later" (the opening) and "deleted years ago" (the endings and the Bin) were both true, with nothing tying them together | `STORY_CHRONOLOGY.md` | **Addressed**: the boot reads `PLAYER 2 . . . . . . [DELETED 3 YEARS AGO]` |
| Source-supported risk | Docs claimed Tobben "reports less once you return his voice". The code did no such thing | `village_square.gd` before this pass | **Made true**, in a narrower form, and the contract was corrected |

## Line milestones (A)

A *line* is one entry given to `show_dialogue`, however many caption pages
it takes.

| Milestone | Signal | Meaning | Used for |
|---|---|---|---|
| Page presented | `line_presented` | The line's first page opened. Nothing is read yet | History (once per line, as before) |
| Text fully revealed | `line_revealed` | The line's last page is wholly visible: by the typewriter finishing, by the reveal press, at once (Instant), or on moving past it | **Journal facts and truth pieces** (`World._on_line_revealed`), once per line per conversation |
| Line acknowledged | `line_acknowledged` | The player moved on from it | (Available. Nothing uses it yet) |
| Conversation completed | `dialogue_closed` with `dialogue_finished` | Read to the end | `commit` events and `after` callables (unchanged) |

Instant text, reveal-on-press, auto advance, caption pages, history and
audio are unchanged. The existing caption and journal suites pass.

## Tobben's report (C)

- One report at a time. Talking again while one is pending adds nothing.
- After a report lands he doesn't tell again for 60 s (`REPORT_COOLDOWN`).
- The report waits for any open conversation, scene or question, both
  before and after its 4 s delay.
- While Rue has his voice (written Tobben) he can't tell anyone. Giving the
  voice back restores the ordinary report.
- After the guest book he still reports, because it is his script. The
  report is smaller (+6, not +12): "tobben says you came by. he didn't say
  what for."
- Leaving the Square while a report is pending drops it. Coming back and
  talking again makes at most one report (tested).
- A believed lie still turns it into "tobben says you're gone. good."

The audit of the "helping him changes him" claims is in
`STORY_CHRONOLOGY.md` (contradictions).

## Characters (second commit)

Each change is something the player sees happen. No new monologue.

| Character | Before | Now | Test |
|---|---|---|---|
| **Rue** | Her only gesture of her own was at Slot 2, and needed the truth | At Arin's save point, the first two presses are the inherited habit (two light taps, then the press, now audible), and both are refused. The third press is one press: no refusal, and the crystal glows her cyan. The first time ever, she says "(once. no taps first. i like it better.)". It needs no truth and claims nothing about whose habit it was | `test_rue_presses_the_save_point_once_her_own_way` |
| **Mira** | After pinning her note she asks Rue to check that it's still up ("Tell me if it is?"). Nothing answered that | Reading the board after she asked records `mira.board_checked` ("(still up. i'll tell her.)"). Her next talk is the answer: "It's still up? ...It's still up. / Thank you for looking. Nobody's ever gone and looked for me before." Her introduction and reset are unchanged | `test_mira_hears_her_note_is_still_up`, `…_before_she_asked` |
| **Wren** | Her generosity was explained (line 2) before it was ever shown | When Arin comes and Rue is in the open near her, before Rue has ever sheltered, Wren waves her over ("here!") and her shelter ring shows. The explanation comes after. A kept promise is now material: safe for good, she can cover Rue from further out (30 px, not 22) | `test_wren_waves_rue_over_before_she_explains`, `test_a_kept_promise_makes_her_shelter_wider` |
| **Tobben** | Reported after every conversation; the book changed only his greeting | See defect C: one report, a cooldown, none while written, and a smaller report after the book that leaves out what she asked. | `test_after_the_guest_book_he_tells_less`, `test_written_tobben_cannot_tell` |
| **Archivist** | A seven-line first speech | Four lines (who he is, the pointer, what it's for). The rest comes one piece per later talk: Slot 2's remains, the unloaded road, "why you", why he can't be deleted. Each is kept until heard to the end, then the usual directions. The pointer is still immediate, and the introduction still counts only once heard. Old saves are greeted as before | `test_the_archivist_s_first_exchange…`, `test_the_rest_is_there_if_she_asks_again`, `test_walking_off_a_topic_keeps_it`, the existing `test_narrative_semantics` |
| **Pip** | Always nosed ahead toward the next goal, like a route arrow | At her heel by default. Pip leads only for 3 s after arriving somewhere, or once Rue has stood still for 2.5 s. Back with her after a run, Pip runs one quick circle round her feet | `test_pip_greets_her_when_she_comes_back`, `test_pip_leads_only_when_she_hesitates` |
| **Arin, the owner, the girl** | — | Unchanged: Arin stays mute. The owner's only new line is Tobben's report, which now follows what Tobben actually saw. The girl is given no new scenes. Her timeline is dated (`STORY_CHRONOLOGY.md`) | — |

## Maps and presentation (third commit)

Bounded: what changed stays visible, and three small composition fixes.
Collision sizes, speeds and routes are unchanged.

- **Square:** Mira's pinned note and Tobben's open guest book are drawn
  where they happened.
- **Archive:** an arrival space inside the Square's door (a worn mat, a
  RETURNS cart), and each of the four records in its own alcove with a
  brass plate. The four records already carry what the Archivist no
  longer lectures.
- **Cast:** a start to go with the stop. The first step leans in (the head
  and shoulders sideways, a dip toward or away from the viewer) for
  0.14 s. Drawing only.
- **UI at the largest text (found by the captures):** the tip card sat on
  the "hold [E]" glitch prompt in the same corner. The tip now stands
  above it. Regression: `test_a_tip_never_covers_the_glitch_prompt`
  (failed first: the two rectangles overlapped).
- Also now drawn: Mira's note pinned on the board (her "M", two pins) and
  Tobben's open guest book (two names, the second in Rue's colour).

**Evidence** (`docs/review/oct24/`, left `34b6823`, right this head;
Compatibility renderer under xvfb, 1280×720):
`compare_square_board_and_stall.jpg`, `compare_archive_arrival.jpg`,
`compare_wren_waves.jpg`, `compare_room_own_press.jpg`,
`compare_ui_max_text_card_and_tip.jpg`,
`compare_ui_max_text_dialogue_and_tip.jpg`. Motion at 30 frames a second
of game time: `motion_start_stop.mp4` (start, stop, turn) and
`motion_wave.mp4` (Wren waving Rue over as Arin comes). Captures:
`tests/tour_oct24.gd`.

**Reviewed at the largest text and with touch on, not changed:** the act
card still sits centred over the Square (it holds the owner until read;
moving it is a design decision, `OPENING_REVIEW.md`). At the largest
subtitle size, a one-line dialogue leaves the box mostly empty, because
its minimum height is sized for two lines plus the portrait. Readable, not
fixed.

**Not done in this pass (proposals):** House (shared versus emptied
rooms), Out of Bounds (authored unfinished look, Pip's stable ground), the
Bin (discarded-data landscape, restore silhouettes) and the Edge (a final
composition around Slot 2) were not recomposed. Hand and arm poses and
gaze were not redrawn. There are no new portraits; no approved assets
exist.

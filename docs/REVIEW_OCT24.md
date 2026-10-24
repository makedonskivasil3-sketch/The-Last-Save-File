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

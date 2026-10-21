# Coherence milestone: places, discoveries and relationships that survive failure

Branch: `claude/last-save-file-prototype-ljwuq4` (PR #10, draft, not merged).
Contract: `docs/NARRATIVE_CONTRACT.md` (**proposed**, revision 2, §0).

## 1. Baseline (2026-10-21)

**Hashes.**
- `origin/main` = `09aeb3b` (PR #9 merged).
- The review branch = `90f26d4`: 25 commits ahead of `main`, with `main`
  as an ancestor.
- Working tree clean.
- Every other remote branch is fully merged into `main` (0 commits
  ahead), including the newly fetched `codex/prompt-implementation`.

**Baseline verification used.** CI run 39646071947 on `90f26d4`: the full
suite, the ending bots, the exports and both browser checks passed. Earlier
local results (523/523 and so on) belong to older heads, and are not
counted as verification for anything changed here. No AGENTS.md exists.

**Documents read as claims, then checked against the code.**
- `RELEASE_READINESS.md`, `PROMPT_IMPLEMENTATION.md`,
  `CAPTION_VOICE_CONTRACT.md`, `PORTRAIT_ASSETS.md`.
- `LIVE_ART_MILESTONE.md`, `CONTINUITY_MILESTONE.md`,
  `NARRATIVE_CONTRACT.md`, `NARRATIVE_DECISIONS.md`.
- The tests, export presets and `.github/workflows`.

## 2. Findings (each checked in the source or reproduced)

| # | Finding | How it was confirmed |
|---|---|---|
| F1 | Relationship events for Mira and Tobben (`mira.piece_taken`, `tobben.piece_taken`, `*.piece_returned`, `mira.restored`, `tobben.restored`) are written but are not in `Relationships.EVENTS`. `history()` filters by `EVENTS`, so they never reach the archive. | `owner_memory.gd` `fray`/`return_piece`, `world.gd` `note_restored`, `relationships.gd` `history` |
| F2 | `rel_events` maps id → session. A repeat (Wren's ribbon taken again after it was returned) overwrites the session. "Taken" can then sort after "returned", and the archive can show the wrong current state. Occurrence counts are lost. | `fray` writes `rel_events[...] = sessions` |
| F3 | Three systems prepend lines in `Npc.interact`: fray, truth and recall/greeting. A conversation can open with three unrelated remarks before the selected one. | `npc.gd` `interact` |
| F4 | Mira has no event-driven selector. After a death she watched, a restoration or a pinned note, she shows a generic recall line, then repeats her counters. | `arins_room.gd` `_mira_lines` |
| F5 | Archive facts leak. Tobben's "has to report you: it's in his script", the Archivist's "cut before the game shipped" and Wren's "Arin can't see what she stands beside" all appear on first meeting, before (or without) the line that tells Rue. | `archive_pages.gd` `facts` |
| F6 | Archive conditions are read from omniscient state. "Restricted" comes from `purge >= 1`, and "Deleted" from `npc_fates`, even when Rue has seen neither. | `archive_pages.gd` `condition` |
| F7 | Mira's note is never "carried" by Rue (`mira_quest = "carried"` is never written). Mira carries it on the walk. Yet the archive, Mira's recall and the Bin's file say "the owner found it on you". | `grep mira_quest` |
| F8 | Archive "new" marks are per key (`archive_seen`). An entry whose content later changes (a new event, a changed condition) is never marked again. | `owner_memory.gd`, `journal_panel.gd` |
| F9 | Opening the journal always jumps to the newest journal section and its last entry. That auto-selection, and mouse hover, mark entries as read. | `journal_panel.gd` `refresh`/`_show_entry` |
| F10 | The pause map shows only this attempt's visits (`World._visited`, plus OOB once Pip is found). After a death every other discovered place is "???" again. | `world.gd` `open_pause`, `map_view.gd` |
| F11 | The well's `words` step is recorded before its box opens. Walking away mid-line marks it heard, and the well "was only ever going to say it once". | `village_square.gd` `_on_listen` |
| F12 | The well's text claims live contact from a repeated historical sentence ("it's her. outside. she's still asking."). | `well_sequence.gd` |
| F13 | The anchor needs DELETE (at the Edge) or the Bin's draft. The first death recovery arrives near the end of the game. | `well_sequence.gd` `can_compare` |
| F14 | The opening's final typed line contradicts canon (§0.4 C1). | `opening.gd` `UNFINISHED` |
| F15 | The 240 s browser allowance hides how long startup takes: the check logs no timings. | `tests/web/web_check.cjs` |

## 3. Implemented

(Filled in as each slice lands; see §5 for commits.)

## 4. Verification

(Filled in from runs on this branch's final head.)

## 5. Commits

| Commit | What |
|---|---|

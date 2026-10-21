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

| Commit | What | Findings closed |
|---|---|---|
| `ed91f5a` | Contract rev 2, §0: internal truth, beliefs, player knowledge per stage, contradiction audit (C1–C10), the well's limits, open author choices. Written before any story text changed. | — |
| `0352f68` | Save v3: event occurrence records (first, last, count, sequence) with a v2→v3 migration and finite whole-number checks. Every written event has a journal label. One selection path in `Npc.interact`. Mira and Tobben selectors. Mira's note taken from her, not Rue. | F1–F4, C3, C5 |
| `35d30fb` | The archive: SEEN / SAID / RUE / UNKNOWN facts learned from shown lines; observed conditions; object statuses; semantic revisions and an "updated" mark; the reader's place kept; reading by dwell or deliberate pick. The well: words committed when read whole; replays prove a recording; honest comparison; the answer played back; the earned, opt-in place under the well. | F5–F9, F11–F13, C2, C6 |
| `d083178` | The map: found in any run / this run / closed (and why) / here. | F10 |
| `d4c0df5` | Consequences wait for the next meeting, however many runs later. Malformed-anchor and owner-learning tests. Contract §3–§6 rev 2 (field-by-field layers, checkpoint table, well evidence). | — |
| `881375f` | Opening shot 8 matches canon: her message whole, the owner's reply unfinished, her taped controller on the floor. The well's click is her gesture from the opening. | F14, C1 |
| `9257311` | The browser check logs startup milestones, what holds play, frame rate and game time against wall time, and bounds startup by game time. | F15 |
| `9d691a4` | Sounds released when the engine shuts down without `quit_game()`. | A14 (partly) |

### What a player now sees (to be confirmed by the players in §6, none yet)

- **"They remember what happened between us."**
  - Mira, Wren and Tobben react to what they saw: a death in Mira's room
    (the next time she sees you, however many runs later), a restoration
    (each one), her note pinned or taken from her hands, Wren's name
    leaving the save's list, the guest book.
  - One thing per conversation; walked away from, it is said again.
  - Reset Mira knows nothing. Restricted Mira whispers.
- **"I lost ground, but our story continued."**
  - The map keeps every place found.
  - The journal keeps people, facts, objects and places; it marks what is
    new or changed and reopens where you were.
  - Once the well has played its tune below, you can keep your place
    there, and a death wakes you under the well.
- **"I understand what this evidence proves, and what it does not."**
  - The well's words replay identically: a recording.
  - Matched with DELETE, Rue says it was her message, then. She also says
    that this doesn't mean the girl is asking now.
  - After she answers, the well plays her own answer back: it keeps, it
    doesn't send.
  - The lead keeps "UNKNOWN: whether she's still asking."

## 3a. Route graph (every transition) and repeated journeys

| From → to | Exit | Arrival | Direction | Prerequisite | Purpose | Return path |
|---|---|---|---|---|---|---|
| Room → Square | top door (UNLOCK) or a seam | outside Arin's front door | intentional flip: out of the front door | escape the room (each run) | out of the owner's sight | none: the front door locks behind you (the map says "no way back in") |
| Square → Archive | east gap | Archive west | ✓ | — | the Archivist; the pointer; memories | west gap |
| Archive → Bin | east | Bin west | ✓ | — | restore the deleted; return pieces; the owner's draft | west |
| Square → Out of bounds | climb into the well | landing | intentional: down | — (the goal line points to it) | Pip; THE WELL; the tune; your place | the pillar |
| Out of bounds → Square | the pillar | beside the well, off its prompt | ✓ up | — | back to the village | the well |
| Square → Edge | north gap | Edge south | ✓ | the pointer (kept across runs) | Slot 2; two memories | south gap |
| Square → House | front door | house bottom | ✓ in | UNLOCK (needs no memories) | the controller | bottom gap |

**Why each repeated journey exists.**

| Journey | Repeats because | Kept, shortened or removed |
|---|---|---|
| Room → Square every run | the room is where a run starts, and escaping it is the owner's containment | **Shortened after a death** once your place is kept: you wake under the well (rev 2: earned earlier, at the tune) |
| Square → Archive → Bin | restoring, returning pieces, the draft | **Kept**: each trip changes someone's state |
| Square ↔ Out of bounds | the well's steps | **Kept, with purpose**: the tune (once), your place (once), then only to climb back after waking |
| Square → Edge | endings | **Kept**: the pointer is never re-earned (it stays in the save) |
| Back to Mira after a death | her reaction to what she saw | **Not forced**: it waits for the next time you meet her, so skipping her room for a run loses nothing |

## 3b. The larger Square: camera first, then layout (deferred, specified)

Every area is one fixed 640×360 screen, with no camera.

**Prerequisites before any area grows:**
- **Camera:** a `Camera2D` per area with `limit_*` set to the area's
  `bounds`. It follows Rue with a dead zone of about 120×60, smoothing
  near 6, and no rotation.
- **Reduced motion:** the camera snaps instead of smoothing.
- **HUD:** already screen-space (CanvasLayer). Its prompt anchoring
  (`set_prompt(..., world position)`) must convert through the camera
  transform.
- **Navigation:** the bot nav grids are sized to `bounds`, so they grow
  with it. Re-check `docs/MAP_DESIGN.md` nav versioning.
- **Entries and exits:** `entry_point()` and exit rects are in area
  coordinates and keep working. Signs must stay inside the camera's view
  at arrival.
- **Audio:** positional sounds (Arin's steps, the well) need their
  `max_distance` re-tuned for the larger space.
- **Lighting and backdrop:** baked per 640×360. A larger Square needs
  tiles or a repainted backdrop. Stretching it is ruled out.
- **Touch controls:** screen-space, unaffected.
- **Performance:** measure in a rendered export before and after (§4).

**Square subspaces**, from `docs/CONTINUITY_MILESTONE.md`, still proposed:
- a recess for Wren;
- a sheltered lane;
- the north viewpoint;
- the Archive shortcut gate (opens with the pointer);
- the chalk drawing.

**Not built, and why.** Section 16 asks for the Square–well sequence and
continuity first, and warns against doing every enlargement at once. A
camera touches every area, the HUD prompts, the bots and the captures.
That is a milestone of its own, best started after players have seen this
one.

## 3c. Emotional arc: what changed (and what didn't)

- **Mira:**
  - warmth (the two cups);
  - initiative (she whispers past the owner's lock);
  - erosion (the cups outlast the reason, purge ≥ 3);
  - an action for someone else (her note, carried by her);
  - a change caused by the player's history (every consequence in §4).
- **Wren and Tobben:** consequences and greetings as listed in the
  contract §4.
- **Not done:**
  - authored humour and irritation lines beyond the existing ones;
  - a sacrifice choice built on an established relationship. The endings
    are unchanged; no new endings were allowed.

## 3d. Animation (section 13): not changed in this milestone

- The speaking, writing, mute and restricted states, the single mouth
  clock and the timed glitches are kept as `main`'s PR #9 and the
  live-art milestone left them. Their tests pass in the full run (§4).
- No locomotion, gaze or escort catch-up changes were made, so no
  before/after contact sheets are claimed.
- The opening's shot 8 frames are the only before/after pair:
  `docs/review/continuity/opening_shot8_before.png` (`d4c0df5`) and the
  new capture (§4).

## 4. Verification

(Filled in from runs on this branch's final head.)

## 5. Commits

| Commit | What |
|---|---|

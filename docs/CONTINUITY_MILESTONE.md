# Continuity milestone: what was built, how it was checked, what's left

The contract is `docs/NARRATIVE_CONTRACT.md` (**proposed**). This file is the
evidence for it. Branch: `claude/last-save-file-prototype-ljwuq4`.

## Baseline

- **Source hashes at the start:**
  - `main` = `1e371b1`.
  - The branch was at `a38049f`, ten commits ahead with the live-art
    milestone. No other branch was ahead of `main`. There were no local
    modifications.
- **Strict full suite on `a38049f`:** 496 passed, 0 failed (1165.8 s,
  exit 0). The ObjectDB warning at exit remains (A14).

**Defects reproduced on the baseline before fixing:**

| Defect | Probe | Baseline | Now |
|---|---|---|---|
| Reunion opens with a first-meeting line | Talk to Wren, die in the Square, talk again | "You're the one Mira talks about." | "You came back. I saw them take you…" |
| The journal refused entries and cut lines silently | `record_read` past 80 entries / 16 lines | Entry refused with no warning; lines cut | Generous limits, with a warning |
| The well's arrival lands on its own prompt | Arrive from Out of Bounds | 10 px from "climb into the well" | 30 px away |
| First-arrival lines repeat every run | Enter the Square in a later session | "a whole town…" again | A short "back" line |

## Implemented, with commits

| Commit | What |
|---|---|
| `8256c29` | `NARRATIVE_CONTRACT.md` (proposed) |
| `83dfcf2` | Save v2: encounters, conversations, relationship events, places, well events, anchor. v1 migration. Wren's selector. Reunions without introductions. |
| `8b7c938` | The new truth applied to the conflicting lines (ledger §7). Tests updated deliberately. |
| `555e050` | The archive: people, memories, documents, objects, places, leads. No silent limits. |
| `978d98c` | The well's five steps; the well anchor checkpoint; transition fixes; "back" lines |
| `8c5529c` | The visible iPhone sound badge removed; audio recovery kept |
| `dc372e9` | The opening animatic |
| `3fea14f` | People page history in story order; captures |

## Route audit (every transition)

The direction column says whether the arrival side matches the exit side.

| From → to | Physical exit | Arrival | Direction | Why travel | Return route | Why return |
|---|---|---|---|---|---|---|
| Room → Square | top door (UNLOCK) or the seam | outside Arin's front door | **Intentional flip:** out of the front door | Out of the owner's sight; find the exit | Front door (locked) | No reason yet. Proposed: Mira's note on the board |
| Square → Archive | east wall gap | archive west | ✓ | The Archivist, memories | West wall | The CHARACTER FILE, once ready |
| Archive → Bin | east wall | bin west | ✓ | Restore the deleted | West wall | Restoring someone, returning a piece |
| Square → Out of Bounds | the well (climb in) | top-left landing | **Intentional:** down | Pip, a memory; the tune | The pillar | The tune (well step 2); waking at the anchor |
| OOB → Square | the pillar | beside the well (**fixed**: off its prompt) | ✓ up | Back to the village | The well | The well's steps |
| Square → Edge | north gap (once you have the pointer) | edge south | ✓ | Slot 2 | South gap | — |
| Square → House | front door (UNLOCK) | house bottom | ✓ in | The couch, the controller | Bottom gap | — |

**Backtracking classes:**
- **Required and meaningful:** Square ↔ Archive (the file), Archive ↔ Bin
  (restoring).
- **Optional discovery:** House, Out of Bounds (Pip).
- **Relationship revisit:** Square for Wren after any event (her selector
  now has something to say).
- **Unnecessary traversal:** after a death you walk the room → Square →
  well again every run. Once the well's anchor is set, a death wakes you
  under the well instead (`978d98c`). Nothing teleports without an
  explanation: the well kept her answer.

## Square expansion: proposal, not built

The game has no scrolling camera: every area is one fixed 640×360 screen.
Scaling the Square to 1.3–1.5× would need a `Camera2D` with limits, plus
these, and none of them exist:
- a HUD layout check against a moving view;
- navigation grids larger than the screen;
- spawn points and audio falloff re-tuned;
- lights placed outside today's baked backdrop.

That is deferred until players have seen this slice.

Proposed subspaces, for when it is built:

| Space | Purpose | Interaction | Collision | Narrative state | Repeat |
|---|---|---|---|---|---|
| Recess behind Tobben's stall | Quiet conversation with Wren away from Arin's loop | Wren moves there after `wren.reunited` | Solid stall back wall | `wren.reunited` | Her place from then on |
| Lane behind the houses | A sheltered route east, out of Arin's cone | Walk | Narrow, with walls both sides | Opens after `wren.sheltered` (she shows it to you) | Always open |
| Viewpoint at the north fence | See the Edge's grey before you can go | Look | Fence | Pointer flag | Says something new after each ending |
| The well's far side | The rim (built now) | Listen | Well | Well events | Quiet after `answered` |
| A shortcut gate to the Archive | Saves the loop after the file is ready | Gate opens | Gate | `knows_truth` or Stage FILE | Open for good |
| Someone's former life | A child's chalk drawing of two figures and a well | Read | Flat (never solid, never looks like cover) | — | Changes after `answered` (a third figure) |

## Verification

See `RELEASE_READINESS.md`, the current section. In short:
- full suite 517/517 on `dc372e9`;
- 5/5 ending bots;
- three exports;
- both browser checks pass, with no visible badge;
- captures in `docs/review/continuity/`.

## Tests added (all in the strict suite)

- **`test_continuity.gd`:**
  - first meeting versus reunion;
  - an interrupted reunion is not committed;
  - history survives death and restart;
  - characters acknowledge only what they saw;
  - a promise and a restoration are remembered;
  - v1 save migration.
- **`test_archive.gd`:**
  - people only once met, without spoilers;
  - objects say where they are now;
  - places survive a retry;
  - nothing dropped silently;
  - the panel's sections and new-entry marks.
- **`test_well_anchor.gd`:**
  - the well's steps happen in order and need their prerequisites;
  - stepping away cuts the answer off;
  - after a death you wake under the well, with purge counted and nothing
    duplicated or undone;
  - after a quit or crash you start in the room;
  - an invalid or outdated anchor falls back to the room;
  - no anchor mid-story;
  - an ending clears the anchor;
  - transition directions;
  - no repeated first arrival.
- **`test_opening.gd`:**
  - length bound 40–60 s (changed deliberately);
  - the impossible event: she walks under PAUSE while Arin doesn't.
  - The existing skip, replay, focus and hand-off tests still pass.
- **`test_audio_routing.gd` / `audio_output_check.cjs`:** audio recovery is
  kept, and nothing is drawn.
- **Updated deliberately to the new canon:** `test_canon`, `test_pass7`,
  `test_records`, `test_dark_truth`, `test_story_pacing`.

## Known remaining inconsistencies

- Mira, Tobben and the Archivist still use their old line counters.
  - Only the introduction is skipped on a reunion.
  - They don't yet react to specific shared events the way Wren does.
- The well's step 2 tune uses the theme with one level missing. On a save
  with the "rue" ending already heard, the title plays the full theme while
  the well still plays it one note short. That is intended (the well
  remembers how it was), but untested by ear.
- `DARK_TRUTH_DESIGN.md` and the narrative bible are bannered as
  superseded, not rewritten.
- The opening is an animatic: drawn hands and silhouettes. Its pacing has
  not been tried on players.
- The People page shows a portrait in the colours last seen. Someone frayed
  since then shows their old colours until met again. This is intended
  ("as you last saw them") but could confuse.

## Not done (blocked or unavailable)

- **Unfamiliar players:** none were observed. When some are available,
  ask after 15 minutes, without hints:
  1. Where are you going, and why?
  2. When you were taken, what did you keep?
  3. Who remembers you?
  4. Why does the well matter?
  5. What gives you hope?

  There are no results yet, and none are invented here.
- **Hardware:** no Windows execution, phone, real GPU or gamepad session.
  Exports are built on Linux; the Web build is checked in headless
  Chromium.
- **Listening:** no human listened to anything.

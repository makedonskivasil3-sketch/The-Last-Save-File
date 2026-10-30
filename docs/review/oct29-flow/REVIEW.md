# Gameplay flow review — 29 October 2026

Base: main a81baf7 (PR #12 merged). Work branch: codex/gameplay-flow-oct29.

## Implemented scope

- ColdOpen respects Settings.text_rate including Instant. First press reveals;
  another press after release advances. Focus loss freezes typing and resets
  the skip hold and input arming.
- TouchControls cancels virtual actions on application focus loss and OS touch
  cancellation. Portrait rotation releases the stick and buttons and refuses
  new virtual controls behind the sideways notice. This does not pause hazards:
  a complete orientation pause remains open, and mobile is not certified.
- Regression coverage extends test_cold_open and test_touch.

## Route diagnosis

The Square is the hub for the house, Archive, well/Out of Bounds and Edge.
The Archive leads to the Bin; both the house and Edge return to the Square,
while the Out of Bounds pillar also returns there. Quests derives its mission
from area and remembered progress; this is useful for old saves, but cannot
make repeated hub travel feel like a new action. More floor space alone would
increase the cost of repetition.

Recommended design (proposal, not built): three authored mission loops, each
with a discovery, usable artefact, destination, consequential action and calm
checkpoint. Open shortcuts after their first traversal. Revisit the Square
only with a changed character, environmental consequence or new route.
Keep optional relationship branches optional and preserve all six endings.

Keep the festival playable inside the first-run experience, with replay in the
menu and skip available. Reuse its learned two-person lantern interaction
later; avoid adding mandatory flashbacks before player testing. It is the
emotional baseline against which the present deteriorates.

## Release limits

Native Godot regression checks cannot certify iPhone Safari, interrupted audio,
browser save durability, physical touch targets, Windows play, controller feel
or commercial enjoyment. No new rooms, artefacts, recordings, ending rewrite,
exports or release publication are part of this bounded fix.

## Proposed mission loops

1. The Unfinished Delivery: the Archive reveals an undelivered message;
   a sorting annex lets Rue repair its address by inspecting objects, not
   guessing a code. Deliver it to Mira; her reply and altered corner persist.
   Unlock an Archive-to-Square shortcut and a calm save scene.
2. The Last Light: Wren's chalk establishes a refuge; a maintenance room
   contains a lantern wick whose recorded rhythm recalls the festival.
   Redirect light around one readable patrol, then choose which shelter it
   protects. Wren's drawing records the decision; do not invent permanent
   relationship flags until the save schema and old-save migration are tested.
3. A Place for Someone: the Archivist's PEOPLE folder motivates a recovered
   identity record from the Bin. A restoration desk turns that record into
   a concrete way to preserve someone. An interrupted action reveals that
   the Owner is preparing the console for removal. Preserve Rue's established
   identity: she is the game character, not the girl; well sounds are recordings.

These are design candidates, not claims that these items or rooms already exist.
Before adding them, map every current required leg and remove redundant errands.
New rooms should begin with greyboxes and existing interaction vocabulary.

## Commercial planning assumption

One experienced full-time developer with part-time paid art/audio/QA support,
using the current codebase: roughly 4–6 months to a demo with evidence of player
comprehension and interest; 9–15 months to a modest polished PC release. This is
an estimate, not an audit-derived schedule or sales forecast. Solo part-time
work takes materially longer. Cost and staffing need an actual budget.

First two weeks: touch interruption, movement/reading regressions, route map,
5–8 unfamiliar players. Weeks 3–6: one complete mission loop and one new room.
Weeks 7–12: representative art, sound, accessibility and Windows verification.
Weeks 13–20: public-demo preparation, store assets and external testing, with
extra time if the revised loop still needs explanation. Expand the campaign
only after that gate; cut optional scope before cutting save reliability.

## Verification results

Godot 4.3 stable, isolated XDG directories, native headless execution:
- `tests/run.sh --filter=cold_open,touch,movement,quests`: 46 passed,
  0 failed, 61.7 seconds. Existing ObjectDB exit warning remains.
- Final touch-only rerun includes portrait rotation and the final portrait
  input guard; see the committed test cases. No physical phone test or full
  suite rerun was performed for this bounded change.
- `git diff --check`: passed.

Anchor/size warnings from the cold-open layout remain; no claim of a visual
layout correction. Portrait releases input but does not stop the simulation.

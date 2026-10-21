# Code and game-experience revision — October 21, 2026

## Baseline and integration

Reviewed `main` at `da83f01aeaab6015914a7d7d028783e9c84b9558` in a separate
`codex/revision-oct21` worktree. That main already includes the integration
follow-up, opening/cast repairs and all available remote branch heads.
PR #6 is merged. PR #7's `decaf1f7` head is an ancestor of main, although the
old PR remains open against `claude/review-fixes`; it needs administrative
reconciliation, not an older code tree merged over current work.

The two old local `codex/player-experience` commits are not ancestry-merged,
but their console-history, compact-pause and repeat-session improvements have
evolved in the current source. Blindly cherry-picking them would conflict with
newer pacing, history, journal, voice replay and menu work. They were preserved.
The previously reported `a918b79` object/combined patch is not available here.
In particular, no `MapSurvey` local floor plan has been recovered or delivered.

## Assessment

This is a substantial playable late prototype. Its distinctive value is Rue's
recovered identity, the Owner reacting through the game's systems, and the
choices about other characters. Its presentation now has coherent lighting,
shared illustrated characters, functional onboarding and an extensive automated
test harness. Existing integration evidence is materially stronger than the
earliest audit: audio routing, real first-run coverage and exact-ending bots
are already present. Those old problems must not be reported as wholly unfixed.

The next quality jump is interaction clarity and authored staging. Characters
retain small, fairly generic poses; Square landmarks compete; closets and Bin
shadows need clearer actionable boundaries; temporary floor needs a reliable
non-flickering timing cue; and the overview cannot answer room-level navigation
questions. These are visual observations and design hypotheses, not evidence
from unfamiliar human players. No market-success or release-quality claim is
justified by the current automated evidence.

## Reproduced and repaired in this revision

| Finding | Trigger and impact | Repair | Regression |
|---|---|---|---|
| Generic resume overwrites finale cursor ownership | `set_owner_paused(false)` restarts cursor in reach/drag/beaten or after a completed slot | Edge pause override reapplies confrontation/terminal ownership after the common pause logic | `test_terminal_slot_keeps_cursor_stopped_after_generic_resume` |
| Confrontation advances behind reading protection | Pending `fight == "arin"`, then an act/NEW GLITCH card; the old order spawns Arin while the Owner is held | Check the common owner hold before any fight transition or grace countdown; remove the redundant arrival-only hold implementation | `test_reading_holds_the_pending_arin_spawn_and_grace` |
| Completed writing retains obsolete guidance | Slot 2 completes with a previous writing objective | Completed slot returns no goal; `World.reach_slot2` explicitly clears the objective and its tween | Terminal-slot and completed-objective cases |
| Stationary gaze snaps and chatters around the diagonal | Repeated NPC gaze updates near the facing threshold | Direction-dependent hysteresis and one turn-animation trigger per actual gaze change | `test_gaze_turn_animates_once_and_does_not_chatter_near_diagonal` |
| Reduced flashing leaves charging brackets oscillating rapidly | Hold targets with Reduce flashing enabled | Keep brackets stable while retaining progress-driven contraction and the steady charge ring | Source inspection; current rendered verification pending |

All four new regression methods failed against the unmodified baseline
(`0 passed, 4 failed`, 4.2 s). After repair the isolated wrapper run completed
with **4 passed, 0 failed**, 4.1 s and exit 0 on official Godot 4.3.
No purge, memory, ending, cost, movement, save-schema or checkpoint rule changed.
The existing whole-card reading-protection duration is preserved.

## Source and visual review scope

Reviewed the shared animation/rendering model, interaction charging/commitment,
HUD priority and objective lifecycle, pause/history/map composition, navigation
occupancy/recovery, finale state transitions, retry metadata, area rules,
audio-production status and test/build pipeline. This is a targeted expert
revision, not a claim that every line or every possible state has been proven.

Visually inspected the existing baseline room, Square, Archive, House, Bin,
Out of Bounds and Edge captures in `review/opening-cast/`, and the clean
directional cast sheet in `review/integration-followup/`. Those images precede
this revision. They support composition observations, not current animation,
pursuit, audio, hardware or human-playtest claims. No new rendered capture was
produced during this revision.

| Area | Strength | Next specific concern |
|---|---|---|
| Room | Cyan Rue contrasts with warm interior; partition provides an initial mechanic | Competing note/crystal/Mira/partition cues and possible Slot 1 identity confusion |
| Square | Crossroads and exits establish the hub | Route hierarchy, crowding of information and shelter understood under HUNT |
| Archive | Quiet desk focal point and record stands | Readables versus shelf decoration, optional-record discovery and truth-stage emphasis |
| House | Empty Player 2 room supports the story | Closet entrances and real shelter boundaries before the timed visit |
| Bin | System-file motif clearly differs from village space | Protected footprint is faint; draw/safety rectangle construction is duplicated |
| Out of Bounds | Permanent anchors and wireframe floor fit the fiction | Temporary-floor warning depends on subtle effects; guide fallback needs progression-aware review |
| Edge | Blocks and Slot 2 are spatially legible | Deliberate unloaded fiction still resembles a greybox; clarity across every confrontation phase |

Additional unresolved technical concerns: avatar recovery still gates on a
nearby grid-cell centre, which deserves an exact-position recovery regression;
avatar body queries still allocate per call, which deserves measurement before
an optimisation claim; local geometric maps remain absent; and ObjectDB/audio
teardown warnings persist. These were not fixed or presented as measured frame
rate defects in this revision.

## Validation and evidence boundaries

The final PR's checks and validation section record the completed broad-suite
and bot results for this revision. At the time this report was prepared, those
runs were ongoing; the four-case red/green result above is complete. This avoids
substituting the inherited 464-test / five-bot results for current verification.

Commands, from the repository with a writable temporary directory and isolated
test user data:

```sh
GODOT=/path/to/Godot_v4.3-stable_linux.x86_64 bash tests/run.sh --filter=revision_oct21
GODOT=/path/to/Godot_v4.3-stable_linux.x86_64 bash tests/run.sh --filter=revision_oct21,confrontation,pass8,opening_slice,integration_followup
GODOT=/path/to/Godot_v4.3-stable_linux.x86_64 bash tests/run.sh
GODOT=/path/to/Godot_v4.3-stable_linux.x86_64 bash tests/run.sh --bots --speed=3
```

The isolated new regression run reports ObjectDB leakage and three resources
still in use during teardown. These diagnostics are retained, not suppressed.
Passing gameplay assertions do not establish leak-free shutdown. No new
browser lifecycle, export, listening, Windows execution, real-GPU, physical
controller, phone or human-playtest result is claimed here. CI checks on the
new commit must be distinguished from older archived integration evidence.

## Detailed next assignment

[NEXT_GAMEPLAY_VISUAL_PROMPT.md](NEXT_GAMEPLAY_VISUAL_PROMPT.md) is the complete
implementation prompt: preserved canon, reliable controls, cast animation,
all seven maps, an honest local survey, modern visual/HUD rules, audio and voice
production, performance methodology, real-player testing and acceptance criteria.
It specifies future work; its presence does not mean that work is implemented.

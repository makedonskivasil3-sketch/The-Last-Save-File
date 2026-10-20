# Opening and cast consolidation — 2026-10-20

## Version and scope

Baseline: `decaf1f7f1851358bf0b357f15509d654066d20a`, the fetched head of
`claude/last-save-file-prototype-ljwuq4` supplied as the PR #7 baseline.
The local working tree was initially clean on `playtest/first-minutes-fairness`
(`6eafb64`). It was preserved. Work uses a separate worktree and the local
branch `codex/opening-cast-review`.

Remote `main` was `3f471e6a1781ca3f82b2cac80f20bbf95f6ec958`.
Remote `codex/map-experience` was `da2a99b5d9b619d7cf662db519ffc027144996d1`.
That branch is available, but PR #7 contains the same gameplay code and two
additional prompt documents. The advertised `a918b79` object is absent from
the accessible repository; no combined patch was found. Neither historical
commit messages nor old screenshots are used as current validation.

This pass fixes a complete opening/control/presentation slice. It does not
pretend to reconstruct all of the unavailable work. No changes were pushed,
published or merged. No campaign rule, ending, price, prerequisite, purge
consequence, movement speed, or save field was changed.

## Assessment

The strongest aspect is the connection between identity, recovered colour,
glitches and the Owner's reactions. Seven areas and the existing endings
already form a playable campaign; there is a shared illustrated renderer,
story pacing, threat protection, and useful automated coverage.

The weakest aspects are integration details and unvalidated comprehension:
the overview map is still a topology diagram, some controls and character
views contradict their presentation, and no unfamiliar player has yet
established that the opening or shelter cues are understandable. Recorded
voice performances and real-device validation remain production gaps.

## Availability of the reported unpublished work

| Reported feature | Accessible baseline |
|---|---|
| `MapSurvey`, actual-geometry local floor plan and discovery landmarks | Absent; `map_survey.gd` does not exist |
| Live floor-plan crates/exits, closet/Bin cover markers | Absent; `MapView` remains an area-link diagram |
| Archive → Bin drawn eastward on the overview | Not present: linked correctly, but Bin is drawn below Archive |
| Discovery-aware Pip route selection | Partial: existing `Progression.local_target` selects memories/witnesses/files, then area guidance; not a recovered survey system |
| Occupancy-only grid versioning | Absent: `NavGrid.refresh` increments its version unconditionally |
| Shared `Area.nav_grid()` and cached avatar queries | Absent; existing meta-based grid and per-query objects remain |
| Final sub-threshold crate notification | Not established; existing distance-triggered notification remains |
| Separately timed card protection and terminal cursor refinements | Existing pass-8 protection/finale code is retained, not claimed equivalent to missing follow-ups |
| One-time retry metadata and legacy conversion refinements | Not recovered; existing retry logic retained and covered by the integrated suite |
| Eligible charge time, stable charge feedback and cached PHASE queries | Missing at baseline; implemented here |
| Rear cowlick, bald scalp, Arin scarf and travel-facing companions | Missing at baseline; targeted corrections implemented here |
| Gaze turn hysteresis, title callback and other unpublished visual refinements | Not recovered; no claim they were restored |

## Findings ledger

| Finding / classification | Location | Evidence | Player impact | Correction / status | Verification |
|---|---|---|---|---|---|
| Confirmed defect: crossing a charge gate counts the entire frame | `GlitchController._process` | Regression failed at simulated 30/60/120 FPS, both hold and cooldown gates | Low FPS permits earlier commitment | Count only time after both gates | `test_charge_counts_only_time_after_hold_and_cooldown` |
| Confirmed defect: PHASE can replace its shown landing | `GlitchController._fire` | Moving 4 px during a hold changed the landing and charged the player | Preview and executed action disagree | Revalidate and cancel if destination moved by more than 2 px; no payment | `test_phase_never_commits_to_a_changed_destination` |
| Confirmed defect: walking escort faces Rue behind her | `Npc._process` | Walking right, Rue left: sprite faced left | Companion appears to walk backward | Travel-facing while moving; dialogue and stopped proximity still face Rue | `test_companion_faces_travel_then_the_speaker` |
| Confirmed defect: objective competes with dialogue/danger and spends hidden reading time | `Hud.show_objective` | New regression failed for visibility, timing and empty clearing | Simultaneous reading and missed goals | Priority hiding, paused reading tween, backed goal, empty clear | `test_objective_yields_without_spending_its_reading_time` |
| Confirmed regression found during this pass: a finished objective tween can be replayed | Objective priority handling | Intermediate bot run reported `Can't play finished Tween` | Runtime errors on later interruptions | Release finished tween explicitly; regression includes completion then interruption | Focused regression and restarted final integrated checks |
| Visual inconsistency: Arin's promised red scarf is a belt only | Shared illustrated adult body | New directional sheet and actual avatar palette | Identity differs from brief | Shared scarf rendering in world, opening and portraits | Matching directional captures; gameplay tour |
| Visual inconsistency: Rue loses cowlick from rear | `IllustratedCharacter._head` | Rear branch returns before cowlick draw | Silhouette changes with direction | Draw rear cowlick in current palette | Matching directional captures |
| Visual inconsistency: Tobben's bald scalp becomes all hair from rear | Same renderer | Rear head filled with hair colour | Rear view resembles a different character | Retain scalp with side hair rim | Matching directional captures |
| Visual inconsistency: apron still uses front panel from behind | Shared illustrated torso | Directional sheet and shared torso branch | Clothing layering still needs refinement | Pending next cast pass; not claimed fixed here | Visual/source inspection |
| Usability hypothesis: Slot 1 header may be mistaken for the controlled character | Fresh room | Current fresh captures; no human observations | Identity confusion | Pending uncoached playtest; do not reveal Rue's name early | Plan below |
| Usability hypothesis: topology map implies a southward Bin route | `MapView.NODES` | Bin below Archive; actual exit goes east | Navigation confusion | Pending next map-focused slice; not rewritten here | Source review, existing Bin route regression |
| Performance hypothesis: unchanged grid refreshes cause avoidable replanning | `NavGrid.refresh` | Unconditional version increment | Possible wasted navigation work | Pending profiling/occupancy-based regression | No FPS improvement claimed |
| Confirmed unsafe input path; runtime failure not reproduced: arbitrary death-session metadata reaches `int()` | `OwnerMemory.load_memory`, `ArinsRoom.back_from_the_edge` | Loader validates position/area but retains the session value; retry converts it directly | Malformed records need stronger rejection; ordinary numeric/missing legacy records are a different case | Deferred save-input hardening; not claimed fixed by this slice | Source inspection; no crash claim |
| Confirmed validation weakness: successful process without summary could pass | `tests/run.sh` | Mock engine exits 0 without running tests | False green checks | Require completed non-empty zero-failure summary and successful import | Negative harness check |
| Observed teardown warning: active WAV playback retained at shutdown | Existing audio/test shutdown | Isolated verbose run lists WAV streams/playbacks; title probe with stop + 0.3 s mixer drain exits cleanly | Unresolved teardown reliability; not a reproduced gameplay crash | Investigated, not suppressed or claimed universally fixed | Logs; final-suite warning accounting |

## Opening evidence and limits

`test_a_genuinely_fresh_title_reaches_a_clean_room` starts at the real title
with zero sessions/deaths/quits and `last_exit == "none"`, starts the first
film, skips by held input, releases before hand-off, reads the boot and checks
arrival. It does not use the helper that fabricates a preceding death.

`tour_opening_review` repeats that route with reduced flashing and zero glitch
intensity. It captures the title, film, actual initial room, charge at 55%,
large text, and the first exit via the room's real door/seam triggers. Positioning
for the charge and seam is staged automation, not a claim of discoverability.
The directional sheet is a controlled enlarged reference; gameplay captures
show the figures at the native game scale. No human playtest is claimed.

Before/after captures use the same harness, logical 640×360 canvas, 1280×720
window and settings. Animation/typing timing can differ; they are not pixel
benchmarks. Renderer: Compatibility, Mesa llvmpipe software GL under Xvfb.
Full-tour frame times under concurrent verification are diagnostic only,
not hardware measurements or before/after performance claims.
The historical multi-area tour exceeded its 90 s method watchdog while
accumulating 90 software-rendered frames per shot (roughly 79–137 ms/frame
in that workload). That run did not complete and is not a passing tour.
`tour_map_review` separates static composition from benchmarking: effects
off, threats held directly without PAUSE's cyan wash, valid named arrivals,
and a wait for the area's objective to settle. It does not measure pursuit
or prove threat readability under full effects.

## Seven-area source/composition review

| Area | Entry → critical exit | Optional / character | Threat and real shelter | Focal point / remaining question |
|---|---|---|---|---|
| Arin's room | South arrival → exposed wall seam | Mira, note, partition memory | Door response, awareness, later erasure; Mira's state matters | Arrival and crack; does an uninstructed player find the seam? |
| Square | House side → north road after pointer | Wren, well, Archive, house, Tobben | Arin LOS, crates, hunt; Wren shelter follows actual state | Crossroads; several destinations compete |
| Archive | West → east Bin passage / return west | Archivist, records, memory, character file | Quiet space with solid shelves | Desk/readables; discovery remains a human question |
| House | Front → square | Controller, Player 2 room | Visitor and actual closet recesses | TV/empty room; which furniture falsely looks like shelter? |
| Bin | Archive passage → return | Deleted files/restoration | Lethal sweep, system-file shadows | File silhouettes; boundaries need human readability check |
| Out of Bounds | Well → far ledge / climb out | Pip, memory, first shape when eligible | Temporary floor; permanent anchors | Far ledge; muted/reduced-flash comprehension remains unobserved |
| Edge | South road → Slot 2 | Final memories and ending choice | Static, cursor, confrontation; protected Slot 2 | Floor versus void; no checkpoint or new bypass added |

## Uncoached playtest: 3–5 new players

Use the reviewed build hash, a separate clean profile for each participant,
and their preferred supported input. Obtain consent before recording.
Do not explain the solution. Keep a second session for returning-run checks.

Observe and timestamp:
1. What they think their first useful action should be.
2. Which figure they believe they control; how they interpret Slot 1.
3. Their expectation before tapping versus holding; whether the charge agrees.
4. First interaction, first deliberate hold, first shelter and first exit.
5. Which note, record, closet, cover edge or exit they overlook.
6. What they believe caused failure, and what persisted into the next run.

Neutral follow-ups: “What do you think happened?”, “What would you try next?”,
“What made you expect that?”, “Was anything difficult to read?”
Record build, device, settings, input, timestamps, observed actions and exact
answers in `PLAYTEST_RESULTS.md`. Results remain empty until actual sessions.

## Next three steps

1. Harden optional death-session metadata with a malformed-record regression,
   preserving valid legacy numeric data and the retry rule. Recover the missing
   patch if it exists elsewhere before duplicating its work.
2. Complete a separate map/navigation slice: geometry-derived room survey,
   discovery, eastward Bin layout, real cover, occupancy/version/recovery,
   final crate movement and pending-area-refresh regression. A freed-area crash
   is not reproduced here and must not be called fixed.
3. Run the uncoached playtest and real-device listening/GPU/Windows/controller
   checks; use observed confusion to choose the next visual/layout changes.

Final commands, counts, hashes and remaining limits are recorded alongside
the evidence in `OPENING_CAST_RESULTS.md` when verification completes.

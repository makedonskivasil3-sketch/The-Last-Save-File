# Gameplay consistency: the rules the player can trust

- **Branch:** `claude/last-save-file-prototype-ljwuq4`, stacked on PR #6 (`claude/review-fixes`, 701af0e)
- **Baseline at 701af0e:** 376 tests passed, 0 failed (`tests/run.sh`, Godot 4.3, headless).

**Verification labels:**
- **pass:** an automated test covers it and passes.
- **not run:** no automated or human check has been done.

## Findings

| # | Finding (state at 701af0e) | Fixed by | Test |
|---|---|---|---|
| A | Guidance ignored the truth route. With all five memories, the goal and Pip still pointed only at the ordinary exit; the CHARACTER FILE and the people with something to say went unmentioned | `Progression` (one read of the save, no new flags); a hint line under the goal; Pip leads to a witness or the file; the journal shows a summary | `test_progression_stages_follow_the_save`, `test_goal_keeps_the_way_out_and_adds_the_hint`, `test_pip_leads_*`: pass |
| B | Mira's escort exposure (+2.5 awareness a second) kept counting during dialogue, choices, scenes and PAUSE | `World.escort_exposed()`: passive exposure follows the modal hold, like every other passive source | `test_mira_escort_exposure_respects_reading_choices_and_pause`: pass |
| C | Leaving a body cleared the saved route memory, but the Arin already walking kept the old learned round until the next run | `Area.relearn_owner_routes()` → `OwnerAvatar.set_route()`: no jump, a valid next point, guard stop kept | `test_shedding_rebuilds_the_live_patrol`: pass |
| D | The hold prompt could say RELOADS for LEAVE THIS BODY, which never reloads; the prompt didn't say what it takes | `ActionPreview`: one description used by the prompt, the touch button, the charge and the commit; the commit re-checks and says why if it's no longer possible | `test_prompts_match_what_happens`: pass |
| E | The title read a recorded escape as RUE once the truth was learned later | `Title._after()` uses `last_ending` as recorded. Only saves with wins but no ending name read as an escape | `test_an_old_escape_stays_an_escape`: pass |
| F | The CHARACTER FILE gave the truth on any later `dialogue_closed`: walking away from it, or another conversation closing. Truth pieces counted when a conversation opened, before their line was shown | Truth: only the file, read to its last line (`World.conversation_completed`). Pieces: counted when their line is shown whole (`Hud.line_shown`); Pip's ledge on its last line | `test_the_truth_needs_the_whole_file`, `test_a_truth_piece_counts_when_its_line_is_shown`: pass |
| G | The body was placed 16 px from the helper without checking walls, furniture, gaps or bounds | `World.husk_spot()`: tries eight directions at two distances on open floor inside the area; else where she stood | `test_a_body_is_never_left_in_a_wall_or_off_the_edge`: pass |

## The rules

**Awareness, by source:**

| Source | Kind | While reading, answering, a scene or PAUSE |
|---|---|---|
| Time passing (area rate), an escort in view, being seen by Arin | Passive | Held |
| A glitch, a forced door, touching the owner's things | Direct action | Can't happen: input is held |
| Story consequences (a note on the board, a file restored) | Scripted | Applied when the script runs, at a point it chooses |

**When progress counts:**

| Progress | Counted when |
|---|---|
| A memory | Its cinematic has played (unchanged) |
| A truth piece (Mira, Wren, Tobben) | Its line has been shown whole. Walk away before it and it's said next time |
| Pip's first-hitbox piece | The ledge text's last line is shown |
| The truth | The CHARACTER FILE, shown whole, read to its last line |
| An ending | `last_ending` at the moment it happens; nothing later rewrites it |

**Guidance (Progression stages):**

| Stage | HUD goal | Pip | Journal |
|---|---|---|---|
| MEMORIES | Area goal | Memory here, else area way on | Memories n/5 |
| INVESTIGATE | Area goal + "someone who has watched you may have noticed something" | A person here with something to say | How many noticed, of how many needed |
| FILE | Area goal + "something on the Archivist's shelf has your name" | The CHARACTER FILE, in the Archive | "The file will read whole now" |
| KNOWN | Area goal + "Slot 2 is still north" (until RUE is done) | Area way on | "You read your CHARACTER FILE" |

The ordinary escape is open in every stage.

## Save compatibility

No saved field was added or renamed, so no migration is needed. Truth pieces already counted under the old rule stay counted. A save made between opening the file and finishing it (the old leak) keeps whatever it recorded.

## The player's journey, phase by phase (what this pass changed)

| Phase | What the player wants | What told them before | What tells them now |
|---|---|---|---|
| First launch, the room | Get out; understand who they are | Goal line, owner's note, act card | Same. The screen is clean, so the owner's first distortion is noticed; the prompt sits on the thing itself |
| Interaction and hiding | Know what [E] does here | A corner prompt, a generic hold label | The prompt above the target; the hold names its price, what it takes and whether it reloads (`ActionPreview`) |
| First escalation and failure | Know why it happened, and what persists | Death card with a tip (unchanged) | Unchanged. The card sits above the effects, so the tip is never distorted |
| Escorts | Not to be punished for reading | Exposure accrued while reading or answering | Exposure waits while reading, answering, in scenes and during PAUSE |
| All memories, the truth | Learn there's more without being told what | The goal pointed only at the exit | A quiet hint line; Pip noses toward whoever has something to say, then the file; the journal says how many have noticed |
| Shedding | See the cost and its consequences | Prompt could say RELOADS; Arin kept the old patrol; the body could sit in a wall | The prompt says what's taken; Arin forgets at once; the body lies on open floor |
| Endings and the title | The ending they got is the one remembered | Title could rewrite an escape as RUE | The ending as recorded; the slot shows her name once she remembers it |

**Bot coverage vs human play:**
- The four bots reach exact endings (escape, message, escape with purge, Wren), and focused tests cover RUE, unseen and overwrite.
- A human-equivalent playthrough of each ending: **not run**.

## Pass 3: moment-to-moment rules

**Threat line of sight (`OwnerAvatar.can_see`, `_blocked`).**
- Arin sees Rue only if a ray from Arin to Rue reaches her without crossing a wall, stall, furniture or any other solid on Rue's collision mask. People don't block sight.
- The drawn cone is the same rays (13 of them), clipped where they hit something. What the cone covers is what Arin can see; standing behind the stall is safe and looks safe.
- Covered by `tests/test_threat_fairness.gd`.

**Interaction targeting (`GlitchController._retarget`).**
- When two things in the world are both in reach, the target changes only after the new one has stayed best for 0.15 s, so the prompt and brackets don't flicker between them.
- Rue's own actions (PAUSE standing still, DECOY, PHASE at a wall) and losing the old target switch at once.
- A hold keeps the thing it started on. If that thing stops being valid mid-hold, the glitch fizzles instead of landing on something else.

**Escorts (`World._update_escort`, `Npc.follow`).**
- Steps taken within 16 px of her are forgotten, so fidgeting beside her isn't replayed.
- She takes the shortest way along the trail (skips ahead to the nearest of the next crumbs) and hurries, up to 96 px/s, when more than 24 px behind.
- If Rue PHASEs through a wall, the trail is cut; Rue says once that the companion can't follow. The companion waits until Rue is back beside her, within 40 px with nothing between them.
- After a door, she arrives just behind Rue on open floor, never inside a wall.

**Scenes always end cleanly.**
- Any scene (memory, the truth, Mira pinning her note) holds the owner exactly like reading does. Nobody dies, and awareness doesn't grow, while the player can't act.
- If the run ends during a scene's waits, the scene stops; nothing from it is recorded.
- Sound: each muffle has a source (pause menu, memory). The music opens only when every source has let go, so closing the pause menu during a memory no longer un-muffles it. A new run or the title screen clears every muffle and duck (`Sfx.reset_scene_state`).
- Covered by `tests/test_moment_safety.gd`.

**Noted, not changed:** a companion being escorted can't be talked to; tap focus ignores facing (it's sticky, so it doesn't flicker).

## Pass 5 (2026-10-20): ledger

| Item | Category | State |
|---|---|---|
| Arin walked through walls, furniture and missing-texture blocks (patrol, learned spots, decoy, husk guard, house, Edge) | Confirmed defect | **Fixed.** Reproduced first (146 frames inside a solid chasing a decoy; 93 on a patrol with learned spots) |
| Arin's house loop crossed the wall to Player 2's room | Confirmed defect | **Fixed:** the loop uses the doorway |
| Edge guard corners outside the area (3 of 4 at the slot's start; the drop spots too) | Confirmed defect | **Fixed:** `TheEdge.guard_route` |
| Edge countdown ran under the act card | Confirmed defect | **Fixed:** countdown and cursor wait for the card |
| Slot 2 filled and drained behind dialogue and scenes | Confirmed defect | **Fixed:** frozen while Rue can't act; PAUSE (Rue acting) still writes |
| Edge goal line didn't follow the confrontation | Design weakness | **Fixed:** goal from live state |
| FILE hint and the Archivist said "shelf"; the file is on the desk | Confirmed defect | **Fixed** |
| Archive records looked like 8 px floor scraps among decorative spines | Design weakness | **Changed:** record stands; see below |
| Closets drawn as closed wardrobes but entered by walking in | Design weakness | **Changed:** open recesses; see below |
| Door chime gave 2.5 s for a ~2.1 s walk | Design weakness | **Changed:** 4 s |
| Browser check printed results without asserting; screenshots in `undefined/` | Confirmed defect | **Fixed** |
| Do players find the shelves, closets, Edge objective? | Hypothesis | **Needs player observation** (pending) |
| Does the opening help? | Hypothesis | **Needs player observation** (intro on/off variants ready) |
| Real-GPU performance, phones, gamepads, Windows | Unverified platform | **Pending** (no hardware here) |

## Pass 5: decisions (problem → evidence → decision → intended effect → validation)

**Threat navigation.**
- **Problem:** Arin's movement set `position` directly. Line of sight used physics; movement didn't.
- **Evidence:** `tests/test_threat_navigation.gd` failed on the previous code (decoy behind a solid; learned spots inside furniture).
- **Decision:** a circle shape cast per axis (slides along the rectangular solids). Destinations inside a solid move to the nearest clear floor within 40 px, or are dropped. Blocked for 0.75 s: a waypoint is skipped, a decoy is stared at for 1.5 s, then decoys are ignored for 4 s. Speeds, FREEZE, tells and sight are unchanged.
- **Intended effect:** what blocks Rue blocks Arin; a decoy behind a wall buys time without Arin ghosting through.
- **Validation:** the navigation tests pass; owner, house, shedding and Edge suites pass; the four ending bots still reach their endings.

**Edge guard route.**
- **Problem:** fixed ±46 px corners around Slot 2.
- **Evidence:** at the slot's start (580, 64), x 626 and y 18 are outside the 24–616 × 36–292 area; each drop spot also loses corners.
- **Decision:** keep only corners inside the area (12 px margin), clear of solids (5-point check) and walkable from the previous corner; try a smaller ring; else one post beside the slot.
- **Validation:** `test_every_edge_guard_route_is_walkable` for the start and both drop spots.

**Edge arrival and confrontation.**
- **Problem:** the act card covered the arena while the 5 s countdown ran; the goal said "lead the cursor away" in every state.
- **Decision:** the countdown and cursor wait until the card has gone. The goal line follows the state: cursor by the slot; stand in it; writing (stepping out drains it); the owner is dragging it; it's yours again, Arin is coming. Slot 2 neither fills nor drains during dialogue, choices or scenes; the menu pause stops physics; PAUSE is Rue's own action, so writing continues.
- **Validation:** `tests/test_edge_confrontation.gd`; `test_edge` updated for the card.
- **Not changed:** the final memory's position (no spatial or observed evidence that it is unfair; reading it already holds the owner).

**Archive records.**
- **Problem:** the four records were 8×6 px rectangles on the floor under shelves of decorative spines.
- **Evidence:** inspection of the pass 4 screenshots; no player data.
- **Decision:** `Readable.Look.RECORD`, an open book on a stand with a pool of light, dimmer once read. The CHARACTER FILE pulses only at the FILE stage, and says nothing about its contents.
- **Intended effect:** records read as things to pick up; decoration stays decoration.
- **Validation:** `test_archive_records_look_like_records_and_the_file_pulses_when_relevant`; screenshot. Whether players find them: **pending observation**.

**Closets.**
- **Problem:** the art showed closed wardrobes (solid-looking furniture); hiding happened by walking into a rectangle; nothing said so.
- **Decision:** one interaction, walk in.
  - **Art:** a dark recess with doors swung open and a lit threshold on the side facing the room.
  - **Cue:** "step in to hide" nearby.
  - **Inside:** the doors close around Rue, she crouches, and the status reads "HIDDEN · the closet hides you".
  - **Leaving:** walk out.
  - **Rules:** a closet stops sight, not touch: Arin walking into you still overwrites you.
  - **Warning:** the chime moves from 2.5 s to 4 s ahead.
- **Validation:** both closets entered and left with real movement input; chime timing test; the house loop's segments cross no wall. Whether players notice them: **pending observation**.

**Map.** Not changed. It shows area connections and memory counts. The shelf and closet problems were world-readability problems, fixed in the world; a local floor plan would compensate for them, not fix them. Revisit if observation shows players lost *between* areas.

## Pass 6 (2026-10-20): ledger (finding → evidence → player impact → correction → validation)

| Finding | Kind | Evidence | Player impact | Correction | Validation |
|---|---|---|---|---|---|
| A fully rejected route kept its invalid points | Confirmed (source) | `_sanitize_route` assigned only a non-empty result | Arin could walk at points inside furniture | Rejected points are dropped; an empty route means "keep watch"; sight and touch still run | `test_a_route_with_nowhere_valid_is_dropped_and_arin_still_watches` |
| Destinations checked as points, not bodies | Confirmed (source) | `free_point` used a point query | Arin could stop half inside a wall | One clearance rule: a circle of Arin's radius + 1 px, inside the bounds by that much (`NavGrid.clear`) | Every frame of every navigation test checks the body |
| Inside a solid, movement ignored collision | Confirmed (source) | `_travel` moved freely when overlapping | Arin could cross a whole obstacle | Bounded recovery: step to open floor within 16 px; hold still if none | `test_arin_steps_out_of_a_solid_without_crossing_it`, `test_stuck_fast_it_holds_still_rather_than_walk_through` |
| Skipping blocked waypoints looked broken; no way round obstacles | Design weakness | Sliding can't find a way round a solid | Arin got stuck on corners and skipped points | `NavGrid` (AStarGrid2D at Arin's clearance): paths round solids and through doorways; partial paths to unreachable targets | Decoy reached around a solid; house loop through the doorway; patrol with points in furniture; Edge guard walked |
| The opening's skip and focus | Confirmed (source) | Skip input read before the focus check | A key held across alt-tab could skip; a held Load could skip; a held skip could reach the room | Focus pauses film, music and skip; skip needs a fresh press; the scene changes only once input is released | `test_opening` (9 tests) |
| "P2 RUE" on the television | Spoiler | The late truth: Rue is the character P2 played | Told in the first seconds | Player 2 unnamed | `test_the_opening_names_no_one`; storyboard |
| The Edge's safe floor as dark as the lethal void | Readability | Screenshot inspection | Couldn't tell ground from death at a glance | Slate floor; quieter grid and labels; Slot 2 pulses | `docs/review/pass6/edge_confrontation_sheet.jpg` |
| Benchmark samples could be anything (a death card as "pursuit"; a null portrait) | Confirmed | Harness review | Untrustworthy numbers | Workloads asserted before and during capture; invalid samples recorded separately; environment and software renderer recorded | Smoke run: 9 workloads valid |
| Strict browser lifecycle check not in CI | Confirmed | Workflow review | A broken run lifecycle could ship | Own blocking step; failure evidence uploaded | CI on the next push |
| **Standing in Slot 2 can finish before the owner's grab** | **Design question (open)** | Tour: from 50% the slot fills in 1.2 s; the cursor needs longer when lured away | The confrontation is skipped by a player who lures the cursor far enough | **Not changed:** freezing writing during the reach would make the confrontation unavoidable but changes the finale's balance and the bots' routes. Author's call | — |
| Do players find records, closets, the Edge objective? | Hypothesis | No observations | — | — | Pending human play |

## Pass 7 (2026-10-20): ledger (three read-only reviews, then fixes)

Sources: a player-experience review, a story-consistency review and an engineering review, each reading the code without running it. "Confirmed" means the code path is unambiguous; nothing here was observed with a human player.

| Finding | Kind | Player impact | Correction | Validation |
|---|---|---|---|---|
| Hiding didn't stop "saving over you" at HUNT | Confirmed (source) | The tutorial says hide; a hidden, still Rue was overwritten in 4 s | The HUNT save doesn't start while hidden, and an open save waits while she is hidden | `test_a_save_over_waits_while_you_are_hidden` |
| Square cursor reached 82–88 px/s at high purge (Rue walks 90) and spawned 14 px from the north arrival | Confirmed | Unavoidable deaths, some during the fade-in | Capped at 70 (the Edge caps at 62); comes in from the square's corner furthest from Rue | `test_the_square_cursor_never_outruns_rue_and_comes_in_far_away` |
| Each purge step sped awareness without limit | Confirmed | After a few deaths, HUNT within ~30 s and no way back | The rate stops growing after purge 3 (start awareness was already capped) | Full suite, bots |
| Static seeded where you died could start under you on arrival | Suspected | ~0.5 s to step off unseen static | Death seeds within 40 px of Rue are skipped | `test_the_static_does_not_start_under_your_feet` |
| Truce runs slowed the room too | Confirmed | ~2 minutes of waiting for the seam after a RUE or message ending | The truce slowdown doesn't apply in the room | Full suite |
| No seam hint in session 1 (door locked, not deleted) | Confirmed | A new player searched ~25 s with the clock running | The hint shows whenever the door isn't open | `test_cohesion_story` |
| Death tips promised things the game doesn't do ("break its line of sight", "any glitch breaks a save") | Confirmed | Players act on wrong advice | Reworded to what works (hide; face a wall or get near someone) | Text |
| **A finale retry walks room → square → north road again** | **Open (design)** | About two minutes per Edge retry; only the first Edge death is forgiven | **Not changed:** a checkpoint at the Edge needs the run's flags (the pointer) restored and skips the room's per-run notes. Proposal: after an Edge death, the next session starts on the north road with the pointer kept. Author's call | — |
| Quits add purge; a phone killing a background tab counts as a crash | Design (kept) | Six quiet evenings can purge the save | Kept: the quit/purge rule is the author's. Worth revisiting after playtests | — |
| Act cards and NEW GLITCH hold threats only at the Edge | Confirmed | A 4 s card in the square while Arin moves | Not changed this pass (moving the Edge's hold into World touches every area) | — |

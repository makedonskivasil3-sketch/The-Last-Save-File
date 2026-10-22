# 22 October review: audit and status

**Baseline:** `7710f10`, on `claude/last-save-file-prototype-ljwuq4`.
- Main is at `09aeb3b` and is an ancestor of the baseline.
- PR #10 is a draft and unmerged.
- CI run 129 was green.

The reviewer's local probes (`docs/review/oct22/`) were not committed. Each
finding below was reproduced again here, with a test that runs the
player's flow.

## Starting table

| Kind | Item | Evidence | Status |
|---|---|---|---|
| Confirmed defect | **A.** The journal said "Arin looked straight past you" whenever Rue stood in Wren's hiding radius, even with Arin about 700 px away | `test_standing_by_wren_with_arin_far_away_witnesses_nothing` failed on `7710f10` | **Fixed** (below) |
| Confirmed defect | **B.** The lamp widened onto the opened gate only after leaving and re-entering the Square | `test_the_lamp_turns_to_the_gate_when_it_opens_not_later` failed (`arc_from` stayed at 0.40) | **Fixed** |
| Confirmed defect | **C.** Out of Bounds' floor warnings blinked at 0.16 s and ignored Reduce flashing | Source; `test_floor_warnings_hold_still_with_reduce_flashing` | **Fixed** |
| Confirmed defect | **D.** `RELEASE_READINESS.md` named `537df8c` as the current code head | Source | **Fixed** (current section rewritten) |
| Confirmed defect | Pip ignored the FIRST HITBOX readable when it was the remaining discovery, and pointed at the pillar | `test_pip_leads_to_the_first_hitbox…` failed: the target was (84, 66) | **Fixed** |
| Confirmed defect | The House's door chime went through the console queue, so a backlog could hold it past Arin's arrival | `test_the_chime_shows_at_once…` failed: no line was on screen | **Fixed** |
| Design weakness | The Bin built its shelter rectangle separately for the sweep and for the drawing. They matched, but could drift apart | Source | **Fixed**: one helper, with a steady edge |
| Design weakness | The crossing is one large, uniform cobble rectangle; the Archive's door sits above a route that exits east | Captures | Addressed in the route pass (below) |
| Design weakness | The HUD competes with itself: header, wrapped goal, meter, prompt and console | Captures | Addressed in the HUD pass (below) |
| Hypothesis, then **confirmed defect** | `Hud.cinematic()` resume reset the caption's reveal while the take resumed mid-way, and waited on the global `voice_busy` | `test_a_scene_over_an_early_page…` failed: the caption went back to 4 of 37 characters, and the first page waited for the whole take | **Fixed** (below) |
| Hypothesis | Lamp beam raycasts in `_draw()`, and cosmetic randomness shared with gameplay | Source | Profiling candidate only; not measured as a defect |
| Completed | Bounded camera, relationship persistence, caption paging, speech rate, browser audio unlock, interactive opening | Earlier milestones and their tests | Kept; not reimplemented |

## A. Journal evidence

- `wren.sheltered` now says only what it records: "You hid beside Wren."
  - Its SEEN line is "You stood beside her and the owner's marks didn't
    settle on you."
- A new event, `wren.concealed`, is written only by
  `World.is_player_hidden(pos, "arin")`. Arin calls it after his own
  range, angle and wall checks have reached Rue, and Wren's cover turned
  the look aside.
  - Only then does the journal say "Arin looked straight past you…"
- **Old saves:** they keep `wren.sheltered` with the corrected wording,
  and are never upgraded to a concealment nobody saw.
- **Other SEEN lines checked against their sources:**
  - Mira's "Lives in Arin's room": from meeting her.
  - "She walked out of the room with you": `mira.walked`.
  - Tobben's stall: from meeting him.
  - Wren's CUT CONTENT: `promise_kept`.
  - Pip under the well: always.
  - The Archivist's "where the owner rarely looks" is his own claim,
    recorded at meeting him. It stays, but it is the softest of these.
- Hearing a line and completing a conversation stay separate contracts.
  `World._on_dialogue_closed` still commits only when a conversation is
  read whole.

## B. The lamp and the gate

**Rule:** the owner reacts as the latch lifts.
- `LaneGate.opened` triggers `OwnerLamp.widen_to(LAMP_GATE_ARC)`.
- The lamp ticks, turns onto the gate over 1.5 s, and the owner says
  "the gate behind the stall. i'll keep the lamp on it."
- A restored save, or a later visit, starts already widened.
- The shortcut keeps its benefit: the lane itself stays out of the beam,
  and only the gate's mouth is covered.
- The nav grid is still refreshed by the gate's collision change.

## C. Out of Bounds floor warnings

- Each chunk shows a timer bar along its edge. Present, it drains;
  missing, it fills back up. The bar runs on the same clock as
  `floor_at()`.
- In its last 0.6 s a chunk is hatched diagonally. In normal mode it also
  shifts towards red with a slow 2.5 Hz pulse. Under Reduce flashing
  there is no pulse.
- The three states (there, about to go, gone) differ by pattern: grid,
  grid with hatching, and dotted outline. They don't depend on colour or
  sound.
- The fall grace (0.12 s) and floor tolerance (3 px) are unchanged.

## House

- The chime now shows on the warning strip at once, in Rue's colour,
  through the new `Hud.alert()`.
- Until Arin is in, light spills from the front door, and each closet's
  open side is marked with a bright threshold line.
- The four-second lead is unchanged.

## Captions: a scene over a conversation

**Reproduction:** a 12 s recorded take, paginated across several pages,
with a scene opening over its first page, in Auto advance. After the
scene:
- the caption restarted from 4 characters (it had been at 37) while the
  audio resumed mid-take;
- the page waited for the whole take, because the pacer was rebuilt with
  the global `voice_busy`.

**Fixed:** a held page now comes back on the same page.
- **With a recording:** the take resumes from where it was held, the
  caption from where it was, and the page waits only for its own share of
  the take (`_caption_voice_busy`, the predicate the page had before the
  scene).
- **Without a recording:** the page is typed again from its start, and
  with spoken narration it is said again.
- **In both cases:**
  - the page is still typing when it returns, so a press carried over
    from the scene can't skip it unread;
  - the history is logged once.

**Tests:**
- `test_a_scene_over_an_early_page_resumes_that_page_not_the_whole_take`
  (Auto advance, recorded);
- `test_a_scene_over_a_later_page_comes_back_to_that_page_once` (Manual
  advance, recorded, second page);
- `test_without_a_recording_the_page_is_typed_again_from_its_start`.

**Known limit:** the page cues are character-count fractions of the take,
a fallback rather than word alignment. No recordings exist to author real
cues from. The tests use silent fixtures, which are not voice acting.

## Seven areas: what each is for

| Area | Entry view | Landmark | First useful action | Route choice | Cover | Threat | Optional find | Exit | On return |
|---|---|---|---|---|---|---|---|---|---|
| Arin's room | The act card over the rug, Rue at the bottom | The TV and Mira's corner | Talk to Mira, or read the note | Door (locks) or the seam | — | The owner's attention bar | The second controller memory | The seam, once suspicion opens it | "Welcome home" notes change by run |
| Square | West framing: Arin's door, the well, Wren | The well; now also the **Archive's gatehouse** east | Meet Wren | Road across the crossing, the bench detour, or the **lane** (once its gate is lifted) | Wren, the bench, the lane | Arin's cone; the lamp on the crossing | The well's words; the false memory | Gatehouse (Archive), north road, well, Arin's door | Gate open, lamp turned onto it, chalk on the rim, board text |
| Archive | West door, aisle runner ahead | **Tall cases and the high window**, the desk under its lamp | Talk to the Archivist | Records (lit stands) either side of the aisle | The whole room (cools awareness) | — | Four records; the CHARACTER FILE at the FILE stage | West to the Square, east to the Bin (a bin over the door) | **North-road map pinned to the desk** after the pointer; read records dimmed |
| House | Front door, bottom centre | The couch and TV | Look under the couch | — | Walk-in closets | Arin's visit; the chime warns 4 s before | The controller | Front door | — |
| Out of Bounds | The pillar landing | The far ledge (Pip) | Cross the streaming floor | Chunk timing | Anchors | Falling (grace 0.12 s) | Pip; the FIRST HITBOX (later) | The pillar, back up | The kept place mark |
| Bin | West door | System files with their shadows | Stand by a deleted file | Restore order between sweeps | System-file shadows (one definition) | The sweep | Restorations | West door | Restored people return elsewhere |
| Edge | South entry | Slot 2, top right | Reach the slot | Lure the cursor away | Guards' blind sides | Cursor, static | Two memories | Slot 2 | (Phases already readable; unchanged) |

**What changed in this pass:** the Square's entrance and crossing; the
Archive's layout and its change on return; the House's chime cue; the
floor warnings in Out of Bounds; the Bin's shelter edge.

**Unchanged on purpose:**
- **Arin's room and the Edge.** Their entry views already show one first
  action. The Edge's phases and holds were fixed earlier, and nothing
  here justified moving them without an observation from a player.
- **The pause map.** It is a **topology diagram** (places and
  connections), labelled as a map of places. It is not a floorplan, and
  this pass did not build one.

## Square routes, measured

`tests/tour_route_measure.gd` steers Rue with real input from (560, 182)
to the Archive. Arin is held at the far west, so only the crossing is
measured. Each route runs at **8 phases of the lamp's cycle**, at purge
0, 3 and 5. The raw figures are in `docs/review/oct22/route_measure.txt`.

| Route | Reached | Time | Awareness gained (mean, worst) | Time in the beam (mean, worst) |
|---|---|---|---|---|
| Direct, purge 0 | 8/8 | 4.3–4.4 s | +1.5, +1.5 | 0.33 s, 0.93 s |
| Bench, purge 0 | 8/8 | 5.3–13.3 s | +0.8, +0.9 | 0.07 s, 0.35 s |
| Lane (gate open), purge 0 | 8/8 | 6.4–6.6 s | +2.3, +2.3 | 0.09 s, 0.41 s |
| Direct, purge 5 | 8/8 | 4.3–4.4 s | +3.4, +3.5 | 0.30 s, 0.85 s |
| Bench, purge 5 | 8/8 | 5.3–13.4 s | +3.9, +3.9 | 0.08 s, 0.35 s |
| Lane, purge 5 | 8/8 | 6.4–6.5 s | +5.2, +5.2 | 0.10 s, 0.43 s |

**Reading:**
- The lamp's 0.6 s grace means a straight crossing almost never costs
  attention. The gains above are the owner's background drift over time,
  which is why the slower routes gain slightly more.
- After the purge-5 regression, raising the lamp's cost was the wrong
  lever. Instead, **being held in the beam past its grace teaches the
  owner the spot** (`OwnerMemory.note_spot`). Arin's learned patrol then
  walks the crossing in later runs. Crossing openly is cheap now and
  costly later, and the bench and lane are how to avoid that.
- There is room to retreat on every route: the road is 24 px of setts
  inside a 124 px-deep plaza, and the bench sits 30 px off the road.

## Visual language

**Rules applied in this pass:**
- **Accents mean something.** Rue's cyan and the owner's warm red are
  kept for information: the lamp, warnings, shelter edges. The crossing's
  paving was toned down after a first pass made it the brightest surface.
- **Landmarks are architecture.** The Archive is entered through its
  gatehouse; the facade has no door. In the Archive, the tall cases and
  the high window give the room its silhouette.
- **Light leads:**
  - the gatehouse's lamp spills onto the road;
  - each record has its own reading lamp;
  - in the House, the door's light spills in when the chime sounds.
- **Collision matches what you see.** The gatehouse piers are solid. The
  Archive's taller cases are drawn above the solid shelf, so the
  footprint is unchanged.
- **HUD hierarchy:**
  - one actionable sentence for the goal;
  - the save header dimmed to 60%;
  - the owner's colour-split shadow halved, so essential owner lines stay
    readable under the screen's own colour split.

**The "SLOT 1 · ARIN" header:** kept. It is the save's label, and it
becomes RUE as she recovers her name. Dimming it makes it read as
"whose save" rather than "who you are". Whether new players still read
it as their own name is a question for the playtest.

## Characters and motion

- **Tobben** has an occupational idle ("tend"): both hands at counter
  height, turning things over. He still waves when Rue comes close.
- **The Archivist** already reads.
- **Rue, Mira and Wren:** their weight, settle, turn squeeze, blink and
  contact shadow were already in place. They are not rewritten, because
  without an observed problem a rewrite would only change, not improve.
- **Clips** (in `docs/review/oct22/`, 10 frames a second of game time,
  in-engine): `motion_walk.mp4` (walk and stop),
  `motion_tobben.mp4` (tending, then waving as Rue comes near),
  `motion_dialogue.mp4` (a line typing out, then waiting),
  `motion_escort.mp4` (Wren following) and `motion_death_return.mp4`
  (Arin's touch, the OVERWRITTEN card, retry after 3.5 s, and Rue waking
  in the room while the owner's lines type in).

**No new portraits or recorded performances exist.** The procedural
fallback is kept.

## Audio and voice (status, not new work)

The game's audio is of five kinds, kept apart:
- procedural music;
- sound effects;
- per-speaker syllable blips;
- optional device text-to-speech (off by default; not acting);
- silent test fixtures (used in tests only).

**No approved acting exists.** `audio/voice/manifest.csv` is an inventory,
not shipped audio. `VOICE_AUDITION.md` holds the pilot script. Human
listening has not happened, and the mix against music is not judged here.

## Performance and determinism (measured, then decided)

`tests/tour_measure_candidates.gd`, run under llvmpipe at 1280×720:

| Candidate | Measured | Decision |
|---|---|---|
| The lamp casts rays twice: once for its look, and 11 more in `_draw()` for the beam | Look 0.2–0.3 µs, beam 28–35 µs per frame, against a 64 ms median frame: **0.05%** | **Not refactored.** It costs nothing worth the code |
| The static's spread and the cursor's wandering shared the global RNG with the cosmetic static drawn every frame | Same seed, 60 growth steps, drawn between steps versus not: **only 36 of 60 cells in common**. So frame rate steered the static, and a failing bot run could not be replayed | **Fixed** (`3312f9c`). `Erasure.rng` and `OwnerCursor.rng` are their own generators: random as before, but seedable. The regression failed on the old code |

The cosmetic effects (the HUD glitch, blinks, flicker, the static's
pixels) still use the global generator. That is harmless now that
nothing in gameplay does.

## Evidence

- **Stills:** `docs/review/oct22/before_*.jpg` were captured at
  `7710f10` in a worktree; `after_*.jpg` at this pass's head. Both use
  the same tour (`tests/tour_review.gd`) and the same states:
  - the title;
  - a true first launch (opening skipped, boot read, first frame);
  - the Square, west and east;
  - the Archive;
  - the House at the chime;
  - Out of Bounds, normal and with Reduce flashing;
  - the Bin at a sweep;
  - the Edge.
- **Motion:** as listed above. Stills alone do not show animation.
- **Verification:** the head, commands, counts, warnings and CI runs
  are in `RELEASE_READINESS.md` (current section). Local results and CI
  are kept apart there. Summary at `0773f52`:
  - suite 581/581;
  - bots 5/5 with 0 deaths, and 15 stalls in one run, reported;
  - three exports, the smoke test and both browser checks pass.

## After the milestone (follow-up work)

- **Bot stalls at the Edge** (15 in one purge-3 run): every one was
  against the missing tile at (380–440, 60–84), on the straight line to
  Slot 2.
  - The replan never ran, because the Edge builds its walking grid only
    when Arin needs one.
  - The bot now builds a grid for its replan, and refuses a route that
    crosses the static, which the grid can't see.
  - Three purge-3 runs after the fix: stalls 0, 8, 0; deaths 1, 0, 0 (the
    death had no stall); all reached the escape ending.
  - A player sees the tile, so this is not a player-facing snag.
- **Playtest log:** now covers the session plan's watch list
  (`PLAYTEST_PLAN.md`).
- **Demo endpoint:** built behind a flag, off by default
  (`CANON_DECISIONS.md` §5).
- **Shutdown leak:** every leaked object was a sound still playing as
  the process quit.
  - `OwnerMemory.prepare_quit` already stopped them, but the audio
    thread needs wall-clock time to let go.
  - It now waits 0.25 s of real time before quitting, and the sounds no
    longer leak.
  - **One `SceneTreeTimer` can still leak:** a death or card sequence
    waiting on its timer when the process quits. That is Godot 4.3's
    handling of a freed node's pending coroutine. It is documented, not
    suppressed.

## Unfamiliar-player round (prepared, not run)

**Who:** five to eight people, the same build, no coaching for the first
10–15 minutes.

**Observe:**
- the first meaningful action;
- wrong-door approaches (the Archive's facade);
- crossing choices (road, bench, lane);
- whether closets and shelves are found;
- unnecessary deaths;
- whether a restart is understood.

**Ask afterwards, without leading:**
1. Who are you?
2. Where are you going?
3. What does hiding protect you from?
4. What survived?
5. What does the well prove?

Write observations and interpretations in separate columns
(`COMMERCIAL_DIRECTION.md` §8). **No participants were available, and no
results are claimed.**

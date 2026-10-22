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
| Hypothesis | `Hud.cinematic()` resume resets the caption reveal and waits on global `voice_busy` | Source | Checked in the caption pass (below) |
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

# Movement specification

**Scope:** the festival (`scripts/ui/prologue.gd`) and the game (`scripts/player/player.gd`). Shared rules live in `PixelCharacter` (gait, facing) and are tested in `tests/test_movement.gd`.

**Revision:** 2026-10-28.

## The four quantities

| Quantity | Festival | Game | Used for |
|---|---|---|---|
| **Intent** (direction, 0..1) | `_rue_intent` | `Player._intent` | **Facing** (she turns toward a wall she pushes into) |
| **Desired step** | `want`: intent × speed × Δt, or the remaining distance to a tap target | `velocity = intent × speed` | Collision |
| **Resolved motion** | `_slide()` result | `move_and_slide()` | Position |
| **Presentation velocity** | `_rue_vel` = resolved ÷ Δt | `get_real_velocity()` | **Gait, footsteps, dust, camera look-ahead, "still" mood** |

Blocked intent is never treated as travel. Pushing into a wall shows no walk cycle and no dust, and the camera doesn't lean through the obstacle.

## Rules

| Item | Rule | Notes |
|---|---|---|
| **Input sampling** | `Input.get_vector` on the four move actions, read every frame (festival) or physics tick (game). The actions' deadzone is 0.3, radially rescaled; there is no second threshold | The festival used to add a 0.2 threshold after rescaling, so a stick below about 0.44 did nothing there but walked in the game. Removed. Diagonals are normalised (tested). A light stick moves slowly in both (tested) |
| **Speed** | 90 logical px/s for Rue in both | Arin 78. Assisted walking in the festival 54 |
| **Acceleration** | **None: immediate start and stop.** | A hypothesis kept until players say otherwise. Threat timings were tuned against immediate motion. The figure's start lean, turn squeeze and stop settle are presentation only and never delay the body |
| **Footprint** | 8 × 6 at the feet in the festival. The game body is an 8 × 8 rectangle offset 2 px down | Visual animation never changes collision |
| **Collision** | Festival: swept in sub-steps of at most `SUBSTEP` = 2 px, with up to two halvings to reach contact. At a corner the axis carrying more of the motion slides, whichever it is. Game: Godot physics `move_and_slide` at the physics rate | A 0.5 s frame can't cross the 4 px gate (tested at 0.12, 0.25 and 0.5 s). Mirrored corner approaches slide alike (tested) |
| **Pointer (festival only)** | The step is bounded by the remaining distance, so no overshoot at any frame length (tested from 1/144 s to 0.25 s). Arrival within 0.05 px. A queued lantern action fires once, on arrival. No path-finding: after `STUCK_TIME` (0.35 s) without real progress she stops and shows "?". Keys or a stick cancel a tap target at once | The game has no tap-to-walk. On touch it uses a virtual stick (`touch_controls.gd`), so the two parts of the game differ by design. The festival is a small open square with one fence |
| **Facing** | Reversal on the same axis is immediate. Changing axis needs the new axis to lead by `FACING_BIAS` (1.3×) | Near-45° wobble keeps one facing (tested). Idle glances and emotional looks set `facing` separately and are unaffected |
| **Gait** | Phase advances by distance: one stride per `STRIDE` (10 px). There is no minimum cadence | At 18, 45 and 90 px/s the strides match distance (tested). This replaces `clamp(v/9, 3, 9)`, which made slow movement shuffle |
| **Interaction while moving** | The festival's interact acts where she stands; a tap on a lantern acts on arrival. In the game, interact as before | — |
| **Modal ownership** | Story pages, choices and the pause menu stop movement input (`reading`, `frozen`, `story.visible`). A virtual stick or held E is cancelled when a panel opens | Existing tests: `test_prologue_story`, `test_onboarding` |
| **Focus / controller loss** | Unchanged: focus loss opens the pause menu; a lost pad holds the festival (`_pad_lost`) | Existing tests in `test_opening`, `test_prologue` |

## Camera (festival)

The game's camera is unchanged.

**Measurements:** `tests/tour_camera_metrics.gd` measures the festival camera on any revision. It runs headless with scripted input at 60 Hz. The captures use xvfb with llvmpipe, not a GPU.

| Measure | Fixed (centred on Rue) | Current (`b26aba0`) | Proposed (now) |
|---|---|---|---|
| Camera minus Rue x during a 0.6 s reversal and back | 0 px | 6.5 px swing | 6.0 px swing |
| Largest single-frame move while Arin walks 130 → 190 px away | 0 | 3.89 px | 3.52 px |
| Camera travel while Arin hovers 142–158 px away for 4 s, Rue still | 0 | **280.7 px** (the framing switched at 150 px) | **67.8 px** (blended 110–190 px) |
| View centre at a lantern 1 s after stopping | (−2, −2) | (−4, −2) | (−4, −1) |

**What changed:**
- **Shared framing** with Arin is blended by distance (`smoothstep` from 190 to 110 px), not switched.
- **Look-ahead** reads actual travel, so there is none against a wall, and fades beside an unlit lantern.
- **The idle drift** is halved (±2 px).

**What was kept, and why:**
- **Look-ahead size: 0.35 s of travel.** It cancels the follow's own lag of about speed ÷ 2.5. Shrinking it made the reversal swing 41.6 px; measured, not assumed.
- **The fixed camera is steadiest but shows the least ahead of her.** It is a comparison only (`camera_fixed`).

**Reduced motion:** there is no look-ahead, drift, shake or zoom punch. The view follows closely (rate 6 instead of 2.5). Zoom changes between beats remain, eased, because they mark the story's beats: the time-lapse widens and the load narrows.

**Captures:** `docs/review/movement/camera_fixed_current_proposed.jpg`. Each row is one camera; the columns are running right, 0.25 s after reversing, and 0.75 s after.

## Acceptance route

`tests/tour_movement_route.gd` measures, at 1/144, 1/60, 1/30 and 0.1 s frames:
- stop distance after release;
- pointer arrival error;
- penetration at the thin gate, an outside corner and an inside corner;
- foot slide at half stick;
- facing flips under ±4° wobble;
- view bounds.

In the game it measures penetration into the movable crates, walking frames while blocked, and facing.

Results before and after are in `docs/review/movement/ROUTE_RESULTS.md`. At `b26aba0`:
- pointer arrival was up to 2.96 px off;
- facing flipped on every frame of the wobble;
- the feet slid about 4.3 px per second at half stick;
- the game showed 29 walking frames while blocked.

After the fix all of these are 0. Neither revision penetrated a solid at these frame lengths: the gate tunnelled at 0.12 s and longer (see `test_movement`).

## Not yet measured

- How these feel to people, and on real controller hardware.
- Whether acceleration would read better. That needs a side-by-side test with players (see `PLAYTEST_PLAN.md`).
- The movement acceptance route (`tests/tour_movement_route.gd`) records arrival error, penetration and facing flips under software rendering only.

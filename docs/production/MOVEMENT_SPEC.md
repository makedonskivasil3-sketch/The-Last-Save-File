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
| **Input sampling** | `Input.get_vector` on the four move actions, read every frame (festival) or physics tick (game) | Godot's radial deadzone and rescaling. Diagonals are normalised (tested). A light stick moves slowly (tested) |
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

## Not yet measured

- How these feel to people, and on real controller hardware.
- Whether acceleration would read better. That needs a side-by-side test with players (see `PLAYTEST_PLAN.md`).
- The movement acceptance route (`tests/tour_movement_route.gd`) records arrival error, penetration and facing flips under software rendering only.

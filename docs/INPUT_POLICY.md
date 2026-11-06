# Input policy: who owns a press (2026-11-06)

This is the contract behind `PressGate` (`scripts/input/press_gate.gd`), `TouchControls`, the HUD, the glitch controller and both openings. It exists because phone players reported that E "often seems not to work" and that skipping the beginning was unreliable. Every rule below has a test in `tests/test_phone_input.gd` or `tests/test_touch.gd`.

## One logical E button

`interact` and `confirm` count as **one button**. That button is pressed by:
- E or Space (`interact`), and Enter (`confirm`), on a keyboard;
- A on a pad, which is bound to both actions;
- the on-screen E.

The on-screen E sends **`interact` only**. It used to send `interact` and then `confirm`. In Godot 4.3 the second parsed action event releases the first, so `interact` was never held by touch and no glitch could be charged from a phone. Every reader of E already accepts `interact`; nothing reads `confirm` alone.

## One owner per press

Each time the button goes down it is a **new press**, with its own id. The first owner to `take()` the press acts on it. Everyone else asking about that press is refused, and the input trace records why.

| Context | Owner | What one press does |
|---|---|---|
| Talk / use / read / take / repair / name / enter a hatch or the well | `world` (glitch controller, on release) | One interaction. A release before a glitch fires interacts |
| Charge a glitch | `world` (same press, held) | The charge starts after `HOLD_START` (0.35 s) of game time. It needs the glitch's hold, or 1 s for a friendly person |
| Dialogue reveal, then advance | `hud` | One press reveals the whole line, and only that. A later press advances. `LinePacer.shown_frame` stops the revealing press from also advancing |
| Cinematic lines and skip arming | `hud` (cached once per frame) | The same answer for skip arming and the line in one frame |
| Choice confirmation | `hud` | **One answer per question.** `Hud._pick` ignores the second activation (Enter is both `ui_accept` and `confirm`; a tap can also arrive as an emulated click) |
| Retry card | `retry` | One retry |
| Memory card | `cold_open` | One reveal or one read-on |
| Pause, menus | the menu | A held E is **cancelled** when the pause menu opens; nothing acts on its release |

## Rules

1. **A press is consumed by one owner.** Closing a dialogue never also interacts with the world: that press belongs to `hud`.
2. **A new press is never mistaken for the old one.** Presses have ids, not frame distances. The old guard (`Engine.get_process_frames() - hud.interact_used_frame > 1`) discarded a genuine new tap that arrived one frame after a close: two taps 130 ms apart at 8 FPS.
3. **Nothing is buffered.** An untaken press can be taken while it is held, and for one process frame after its release (`STALE_FRAMES`). One frame is enough for a press and release that land in the same rendered frame. A press is never taken after that, and never across a scene or a modal. The world's existing 200 ms tap buffer (walking up to something) is unchanged: it lives inside one scene and is dropped on any transition.
4. **A held input cannot leak into a new modal.** Opening a dialogue, cinematic, choice, retry card or passage calls `PressGate.claim()`, which takes whatever press is live. A press held from play therefore never advances a new line.
5. **Cancelled touches never act.** These cancel the press:
   - an OS `canceled` touch;
   - a finger sliding more than `SLIDE_CANCEL` (56 px) from E's centre;
   - focus loss;
   - rotation to portrait;
   - the pause menu opening.

   The owner sees `was_canceled()` and does nothing on release. The button shows "cancelled".
6. **Multi-touch: a button is held until its last finger lifts.** The action is pressed when the first finger lands and released when the last one lifts, in any order. A second finger is traced as "already held".
7. **Slide policy.** A thumb that rolls a little past the rim (up to 56 px from the centre) keeps E, because that is how thumbs move. Sliding further cancels, as in rule 5.
8. **A tap is never a glitch.** Taps of 30–250 ms read or talk; a deliberate hold glitches. A glitch on someone friendly needs a 1 s hold.

## Feedback on the on-screen E

- **A press flashes the button** for 0.14 s. A tap can go down and up inside one frame, which is too short to see as "held".
- **The button names the action:** TALK, READ, USE, NEXT or OK. A small E above the word keeps teaching the key. While a glitch hold is offered, the pink HOLD ring says so instead.
- **A tap that finds nothing says so** ("nothing in reach"), instead of looking broken.
- **Layout:** the tip card moves left of E on touch screens, and the side checklist moves below II.

## The openings

The memory card and the festival are separate scenes, and each has a complete touch interface.

**Memory card** (`cold_open.gd`):
- A **Continue** chip sits bottom right. Tapping anywhere also reads on.
- A **hold: skip to festival** chip sits bottom left, with a fill.
- Fingers are handled one by one. A finger on Skip is never also a reading press.
- A quick tap is latched, so a down and up inside one frame still counts once.
- Mouse clicks count only when no touch has been seen.
- Text speed still follows Settings, and reveal and advance stay separate.

**Festival** (`prologue.gd`):
- The skip chip (**hold: skip ▸▸**, with a fill) is a `TouchControls` zone owned by the finger that lands on it. It never depends on the emulated mouse position, so it works:
  - without touch-to-mouse emulation;
  - while finger 0 holds the stick;
  - while a story panel is open (the chip draws on layer 21, above the panel, and opening a panel keeps a finger already on the chip).
- The zone is checked before E and the stick. Its rect does not overlap E's hit circle or the stick zone.

**Both skips:**
- Each frame adds at most 0.1 s to the hold, so one long frame or time in the background can't complete a skip.
- Focus loss resets the hold.
- After the skip, the zone disappears, so a finger still down doesn't act in the next scene.
- Skipping the memory card goes to the festival. Skipping the festival goes to the present.
- Skipped material is still kept in the journal, per OPENING_BEATS.md ("kept in the journal even if skipped"). The skip itself is logged, and `festival_choice` records "skipped".

## Which clock governs what

| Interaction | Clock |
|---|---|
| Press identity, ownership, the stale window | **Process frames** (`Input.is_action_just_pressed`, synced lazily on the first question each frame, so call order doesn't matter) |
| Glitch charge (`HOLD_START`, hold times) | **Game time** (process delta). Only the part of a frame after the gates counts, so low FPS doesn't charge faster |
| Skip holds (memory card, festival) | **Game time**, capped at 0.1 s per frame and reset on focus loss |
| Cinematic hold-to-skip | Game time, paused with the game |
| Reading allowance before auto-advance | Game time, paused with the game |
| World tap buffer (200 ms); choice grace (450 ms) | **Wall clock** (`Time.get_ticks_msec`) |
| Movement | Physics frames |

## Diagnostics: the input trace

`InputTrace` (`scripts/input/input_trace.gd`) is on only with the playtest flag: `?playtest=1` on the web, or `-- --playtest` on desktop.
- It keeps the last 300 lines in memory and sends nothing anywhere.
- It shows on the pause menu's **Playtest log** page, after the log, and "Copy to clipboard" copies both.
- Browser checks read the last 40 lines from `window.__lsf.trace`.

Each line has the time, the FPS, the kind of event, the control, the owner, the scene and modal, ACCEPTED or REFUSED, and the detail.

| Seen in the trace | Meaning |
|---|---|
| No `touch-down` line at all | The tap never reached the game |
| `touch-down ... missed: no control at (x, y)` | The hit test missed |
| `touch-down ... buttons off (story panel or menu)` | Consumed by UI |
| `refused E ... already used by hud` | The dialogue box had that press |
| `refused E ... stale` | It came too long after its release |
| `hold E world charging falsify after 352 ms` | A glitch hold started |
| `blocked E world tap during a scene or passage` | A transition had the input |
| `cancelled E ... slid off E` / `rotated to portrait` / `focus lost` | Cancelled, nothing acted |

# Phone input reliability pass (2026-11-06)

**Reports:**
- E on the on-screen button often seems unresponsive on phones;
- skipping the beginning is unreliable.

**Scope:** input repair only. No new rooms, characters, endings or systems. Story work from 4–5 November is preserved (§7). Mobile is still not a declared launch platform; Windows PC is. A public browser build with visible touch controls must still work by touch.

## 1. Which build players had

| Distribution | Revision | Built | Input code it carries |
|---|---|---|---|
| GitHub Pages (`makedonskivasil3-sketch.github.io/The-Last-Save-File/`) | **`adf2710`**: the last `main` build that succeeded ([run 41143395809](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/actions/runs/41143395809), 30 Oct). The 4 Nov merge `8112117` failed CI and was **never deployed** | 2026-10-30 | All four defects below |
| Claude artifact "The Last Save File" (`claude.ai/artifact/3G95pCn7jTAYr2DPmmWu5w`), hosted separately | **`e551c6c`** (`build_info.json` inside its `game.pck.wasm`: `{"commit": "e551c6c", "date": "2026-10-30"}`) | 2026-10-30 | All four defects below. Updating GitHub does **not** update it |
| `main` | `8112117` (reviewed release work through 4 Nov) | — | All four defects below |
| Windows | CI artifact of each run | — | Same code; touch is not used on Windows |

Missing player details: device, OS, browser, orientation, and whether they used the Pages link or the artifact link. These are being collected separately (see §6). The reproduction did not wait for them.

## 2. Reproduction (before any edit)

`tests/test_phone_input.gd` drives real `InputEventScreenTouch` and `InputEventScreenDrag` events, with presses and releases landing in the same or adjacent frames. Run against `main` `8112117`: **5 passed, 12 failed**. The 5 that pass there are the protections the fix had to keep:
- closing a line never also talks;
- one press answers one question;
- a held press never advances a new line;
- a tap never becomes a glitch;
- taps land at every frame rate.

| # | Finding | Exactly what was rejected, and why | Test (fails on `8112117`) |
|---|---|---|---|
| A | **A fresh tap right after a line closes is thrown away** | `GlitchController` started a press only if `Engine.get_process_frames() - hud.interact_used_frame > 1`. The HUD stamps that frame when it closes the line. A **new, distinct** tap whose `just_pressed` lands on the next process frame has a difference of 1 and is dropped. At 8 FPS that is two taps 130 ms apart. The guard was there to stop the *closing* press from also talking, and frame distance can't tell the two presses apart | `test_a_new_tap_on_the_next_frame_after_closing_a_line_is_handled` |
| A2 | **Holding the on-screen E never held `interact`** (found while reproducing) | The button parsed `interact` then `confirm`. In Godot 4.3 the second parsed action event releases the first: `interact` is `just_pressed` but **not** pressed in the same frame, while `confirm` stays pressed. The glitch controller reads `interact`, so every touch press counted as an instant release. **No glitch could ever be charged from a phone**, and any "hold" was a tap | `test_holding_the_on_screen_e_charges_a_glitch` |
| B | **Two fingers on E: lifting one released it** | `_touch_up` sent releases for every action of that button, whoever else still held it | `test_e_stays_held_until_the_last_finger_lets_go`, `test_release_order_does_not_matter` |
| B2 | **Cancelled touches acted** | `cancel_touches()` (focus loss, rotation, story panels) and OS `canceled` touches called `_touch_up`, which sent an ordinary release. The glitch controller treats a release as a **tap**, so a cancelled press interacted. Sliding off E did nothing special, and the release still tapped | `test_an_os_cancelled_touch_on_e_does_nothing`, `test_losing_focus_mid_press_does_nothing_on_return`, `test_sliding_off_e_cancels_without_acting`, `test_a_small_roll_off_e_keeps_it` |
| C | **The festival skip chip was unreliable** | `_skip_held()` checked keys, then `Input.is_mouse_button_pressed(LEFT)` plus `get_mouse_position()` in the chip. It fails in three cases (*with* emulation is the Godot default): **(1)** with touch-to-mouse emulation off; **(2)** while another finger is touch 0, because emulation follows finger 0 only, so with a thumb on the stick the "mouse" is on the stick; **(3)** after rotation or focus loss, when the emulated button state can be stale | `test_festival_skip_chip_without_mouse_emulation`, `test_festival_skip_chip_while_another_finger_steers` |
| D | **The memory card had no touch interface** | Hint: "[E] continue · hold Esc to skip". No skip control at all for touch. Reading on worked only through an emulated mouse click. With emulation off, taps did nothing | `test_memory_card_reads_on_with_taps_alone`, `test_memory_card_has_a_touch_skip` |

**Historical findings already fixed, kept separate:**
- the portrait notice and overlaps (UI-2, 29 Oct);
- focus loss releasing the stick (O1);
- the tap buffer when walking up to things (C2, 2 Nov);
- `HOLD_START` 0.35 s and friendly 1 s holds (5 Nov).

None of them covered A–D.

## 3. The repair

The policy is in [`docs/INPUT_POLICY.md`](../INPUT_POLICY.md). In short:

- **`PressGate`** gives each press of E (`interact` and `confirm` as one logical button) an id and **one owner**:
  - the HUD (dialogue, cinematic, choice), the world (talk, use, glitch), retry, or the openings;
  - modals **claim** a held press as they open;
  - an untaken press expires one process frame after its release;
  - nothing is buffered across scenes;
  - it is synced lazily, so call order within a frame can't matter.

  The frame-count guard is gone. Its protection (the closing press never talks) is kept by ownership, and tested.
- **The on-screen E sends `interact` only.** Holding works by touch.
- **TouchControls ownership:**
  - a button is held while any finger on it stays down;
  - sliding more than 56 px off E, an OS cancel, focus loss, rotation, or the pause menu **cancels** the press, so nothing happens on its release;
  - a release also clears the action immediately.
- **Feedback on E:**
  - a tap flash;
  - a contextual label (TALK / READ / USE / NEXT / OK, with a small E above it);
  - "nothing in reach" when a tap finds nothing;
  - "cancelled" after a slide-off.
- **Layout:** on touch, the tip card moves left of E (E covered its text), and the side checklist moves below II (it overlapped II).
- **Festival skip chip:**
  - a touch zone owned by its finger, checked before E and the stick;
  - drawn above the story panel, with a fill;
  - kept through a story panel opening;
  - a long frame can't complete it, and focus loss resets it.
- **Memory card:**
  - Continue and **hold: skip to festival** chips;
  - per-finger touch, so a finger on Skip never reads on;
  - quick taps latched; real mouse support kept;
  - keyboard and pad unchanged.
- **One answer per question** (`Hud._pick`).
- **End cards** (demo, win) accept the on-screen E, and the touch prompt says E.
- **Diagnostics:**
  - a bounded **input trace**, playtest flag only, local only, shown and copied with the Playtest log;
  - `window.__lsf.trace` for browser checks.

## 4. Tests and timing

**Native** (`tests/test_phone_input.gd`, 19 cases, all passing on the branch). The cases are listed in §2, plus:
- **Durations and frame rates:** taps of 30, 70, 120 and 250 ms, at `Engine.max_fps` 8, 15, 30 and 60. All 16 combinations talk exactly once, and none glitches.
- **Story panel:** the festival skip chip works while a story page is open.
- **Long frame:** a single 5 s frame cannot complete a skip.
- **Held press:** a press held from play never advances a newly opened line.
- **One answer:** one Enter press answers exactly one of two queued questions.

Taps are delivered both as press and release inside one frame (`_quick_tap`) and across frames. Which clock governs each interaction is in INPUT_POLICY.md, "Which clock governs what". No gameplay assertion was weakened.

**Exported Web** (`tests/web/touch_input_check.cjs`): a phone-shaped landscape viewport (844×390, `isMobile`, `hasTouch`, DPR 2), driven by CDP touch events only (no keyboard, no mouse), on a local export of this branch:

| Step | Result |
|---|---|
| A tap on Load Slot 1 starts the run | PASS |
| A 40 ms tap reads on the memory card; holding Skip goes to the festival | PASS |
| The festival chip, held by finger 2 while finger 1 holds the stick, skips | PASS |
| The boot reads by the on-screen E | PASS |
| II pauses and resumes | PASS |
| Rotating to portrait mid-press cancels it (traced) | PASS |
| Holding E to charge a glitch in the browser | Not shown: the scripted walk did not reach a glitch target at the 3–6 FPS this machine renders. Proven natively (`test_holding_the_on_screen_e_charges_a_glitch`) |

The run renders at 3–8 FPS (SwiftShader), which is the slow-phone condition. There were 0 stale refusals in its trace.

## 5. Video

Two clips, attached in the session:
- `phone_input_browser_2x.mp4`: the touch-only browser run at 2× speed;
- `phone_input_native.mp4`: the native touch tests, including E held to charge the note's glitch, the dialogue handoff, and both skips.

The clips are not in the repository (size).

## 6. Physical devices: not done; the gate stays open

No physical device was available to this session. **Chromium emulation is not iPhone or Android certification.**

**Before a phone link goes to anyone, check on each real device:**

| Check | iPhone Safari | Android Chrome | The friends' browser |
|---|---|---|---|
| Build stamp on the title (bottom right) matches the PR head |  |  |  |
| Tap Load Slot 1; memory card: tap reads on; hold Skip (bottom left) goes to the festival |  |  |  |
| Festival: thumb on the stick + other thumb holds "hold: skip ▸▸" → the present |  |  |  |
| Talk to Mira with E (button says TALK); close the line; tap E again at once → talks again |  |  |  |
| Hold E at the note ~1 s → it glitches (pink ring fills); a quick tap only reads it |  |  |  |
| Two thumbs on E, lift one → still held; slide a thumb far off E → "cancelled", nothing happens |  |  |  |
| II pauses / resumes; rotate to portrait mid-press → notice, nothing acts; back to landscape |  |  |  |
| Switch apps mid-hold and return → nothing acted; skip holds restart |  |  |  |
| Safe areas and browser chrome don't cover E, II or the chips; pinch-zoom is off; resize keeps hit areas |  |  |  |
| Audio returns after switching back; save, close the tab, reopen → progress kept |  |  |  |
| Esc → Playtest log → Copy: the input trace is there (`?playtest=1`) |  |  |  |

**For each device, record:** device, OS version, browser and version, orientation, the build stamp, and pass/fail per row with the trace copied for any failure.

## 7. Preserved (checked against the suite)

These all remain covered by their existing tests:
- the fifth-memory and identity leads, and the specific journal guidance;
- the Slot 2 "this ends the run" warning;
- RUE on a first playthrough;
- reload protection while Rue cannot act, and persistent Edge grace;
- story-based chapters, the corrected lantern objective, and the transactional workshop mission;
- the naming choice, and all six ending identities.

Canon is untouched (no story text changed): Rue is the character left running, the Owner, Arin, Player 2 and Rue stay distinct, Arin is mute, and the well keeps recordings.

## 8. Story experience: an observed playtest once controls are trusted

This pass changed no story text. Words get added only where an observed misunderstanding demands them.

**The session:** the opening, plus the first substantial mission (the workshop lantern), on a phone and on a PC. Silent observation; questions only afterwards.

**Ask, without explaining first:**
1. Who are you controlling?
2. Who is controlling Arin?
3. What happened at the festival?
4. What do you think the well is doing?
5. What does Rue want now?
6. What action changed the world?
7. Which character matters to you?
8. Where did you feel sent back without purpose?

**Observe (tick or note):**
- Does the cold open help or delay engagement (time on the card, skipped or read)?
- Is the festival's impossible act understood?
- Is the first present-day goal clear without the checklist?
- Does the naming choice feel personal?
- Are the identity leads found naturally?
- Does the return from the Edge feel motivated and fair?

**Pre-assessment (hypotheses, not findings):**
- Q1 and Q2 are the most likely to be confused: Rue, the Owner and Arin are distinct in canon, but all three are on screen in the first minute.
- Q8 is the most likely complaint, about the Edge return.

Both stay hypotheses until a player shows them. Then the fix is staging first: an action, a reaction, a placement. Not more words.

## 9. Honest status

- **Done:** reproduced, repaired and tested natively and in the exported Web build, with emulated touch.
- **Not done:**
  - physical-device verification;
  - a human comprehension playtest;
  - campaign pacing and visual quality gates;
  - Windows hardware.

The automated test count is not a release claim, and any release date stays conditional on those gates.

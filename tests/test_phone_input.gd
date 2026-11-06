extends "res://tests/test_case.gd"
## Phone input reliability (2026-11-06 review: "E often seems not to work on
## phones; skipping the beginning is unreliable"). Driven by real touch
## events, with presses and releases landing in the same or adjacent frames
## the way they do on a phone browser running at 8-15 FPS.

var _emulate := true


func before_each() -> void:
	await super.before_each()
	_emulate = Input.emulate_mouse_from_touch


func after_each() -> void:
	Input.emulate_mouse_from_touch = _emulate
	settings().using_touch = false
	for i in 4:
		_send_touch(i, Vector2(-50, -50), false)
	await frames(2)
	await super.after_each()


# --- helpers ---------------------------------------------------------------------

func _window_pos(game_pos: Vector2) -> Vector2:
	return tree.root.get_final_transform() * game_pos


## One touch event, no waiting: several can land in one frame.
func _send_touch(finger: int, game_pos: Vector2, pressed: bool, canceled := false) -> void:
	var e := InputEventScreenTouch.new()
	e.index = finger
	e.position = _window_pos(game_pos)
	e.pressed = pressed
	e.canceled = canceled
	Input.parse_input_event(e)


func _send_drag(finger: int, game_pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = finger
	e.position = _window_pos(game_pos)
	Input.parse_input_event(e)


func _e() -> Vector2:
	return TouchControls.BUTTONS["interact"].center


## A tap whose press and release arrive within one rendered frame.
func _quick_tap(finger: int, at: Vector2) -> void:
	_send_touch(finger, at, true)
	_send_touch(finger, at, false)


func _by_mira(w: World) -> void:
	w.player.global_position = w.area.mira.global_position + Vector2(0, 14)
	w.player._sprite.facing = Vector2.UP
	await frames(3)


# --- A: a fresh tap right after a dialogue closes --------------------------------

## The review's case: one fully revealed line, closed with the on-screen E,
## then a new, separate tap on the very next frame (two taps 130 ms apart at
## 8 FPS). The second tap was thrown away as "the press the HUD just used".
func test_a_new_tap_on_the_next_frame_after_closing_a_line_is_handled() -> void:
	var w := await start_session(true, true)
	await _by_mira(w)
	w.hud.show_dialogue("Mira", Color.WHITE, ["(one line)"])
	await wait_until(func() -> bool: return w.hud._pacer != null and w.hud._pacer.is_shown(), 3.0, "the line shown whole")
	await wait(0.1)
	_quick_tap(1, _e())  # closes the line (handled on the next frame)
	await frames(1)
	_quick_tap(2, _e())  # a new tap, one frame later: talk to Mira again
	await frames(1)
	check(w.hud.history.size() > 0 or not w.hud.is_dialogue_open(), "the first tap closed the line")
	await frames(4)
	check(w.hud.is_dialogue_open(), "the next tap talks to Mira again (it was discarded as the old press)")


## And the protection the old guard gave stays: the tap that closes a line
## never also talks to the person standing there.
func test_closing_a_line_never_also_starts_a_conversation() -> void:
	var w := await start_session(true, true)
	await _by_mira(w)
	w.hud.show_dialogue("Mira", Color.WHITE, ["(one line)"])
	await wait_until(func() -> bool: return w.hud._pacer != null and w.hud._pacer.is_shown(), 3.0, "the line shown whole")
	await wait(0.1)
	_send_touch(1, _e(), true)
	await frames(3)
	_send_touch(1, _e(), false)
	await frames(6)
	check(not w.hud.is_dialogue_open(), "closed, and the same tap didn't open a new conversation")


# --- B: two fingers on E ---------------------------------------------------------

func test_e_stays_held_until_the_last_finger_lets_go() -> void:
	var w := await start_session()
	_send_touch(1, _e(), true)
	await frames(2)
	_send_touch(2, _e() + Vector2(8, 4), true)
	await frames(2)
	_send_touch(1, _e(), false)
	await frames(2)
	check(Input.is_action_pressed("interact"), "the second finger still holds E")
	_send_touch(2, _e() + Vector2(8, 4), false)
	await frames(2)
	check(not Input.is_action_pressed("interact"), "released with the last finger")
	check(w.touch._held.is_empty(), "no finger left owning E")


# --- C: the festival's skip chip -------------------------------------------------

func _festival() -> Prologue:
	settings().opening_seen = false
	var p := Prologue.new()
	var old := tree.current_scene
	tree.root.add_child(p)
	tree.current_scene = p
	if old:
		old.queue_free()
	await frames(3)
	return p


func _chip() -> Vector2:
	return Prologue.SKIP_CHIP.get_center()


func test_festival_skip_chip_without_mouse_emulation() -> void:
	Input.emulate_mouse_from_touch = false
	var p := await _festival()
	settings().using_touch = true
	_send_touch(0, _chip(), true)
	await wait(Prologue.SKIP_HOLD + 0.6)
	check(p.acted.has("skipped") or p.beat >= Prologue.Beat.LOAD, "holding the chip skips (browser without touch-to-mouse)")
	_send_touch(0, _chip(), false)
	await frames(2)
	p._done = true
	p._handed_off = true


func test_festival_skip_chip_while_another_finger_steers() -> void:
	var p := await _festival()
	settings().using_touch = true
	_send_touch(0, Vector2(120, 250), true)  # the joystick thumb: finger 0
	await frames(2)
	_send_drag(0, Vector2(140, 250))
	await frames(2)
	_send_touch(1, _chip(), true)  # the other thumb holds the chip
	await wait(Prologue.SKIP_HOLD + 0.6)
	check(p.acted.has("skipped") or p.beat >= Prologue.Beat.LOAD, "the chip skips while the stick is held")
	_send_touch(1, _chip(), false)
	_send_touch(0, Vector2(140, 250), false)
	await frames(2)
	p._done = true
	p._handed_off = true


# --- D: the memory card ----------------------------------------------------------

func _cold_open() -> ColdOpen:
	var c := ColdOpen.new()
	var old := tree.current_scene
	tree.root.add_child(c)
	tree.current_scene = c
	if old:
		old.queue_free()
	await frames(3)
	return c


func test_memory_card_reads_on_with_taps_alone() -> void:
	Input.emulate_mouse_from_touch = false
	var c := await _cold_open()
	await wait(2.0)  # the first line types out
	var line := c._line
	_send_touch(0, Vector2(320, 200), true)
	await frames(3)
	_send_touch(0, Vector2(320, 200), false)
	await frames(3)
	check(c._line > line, "a tap reads on (no keyboard, no touch-to-mouse)")
	c._done = true


func test_memory_card_has_a_touch_skip() -> void:
	Input.emulate_mouse_from_touch = false
	var c := await _cold_open()
	var skip: Control = c.get("skip_button") if "skip_button" in c else null
	check(skip != null and skip.visible, "a visible Skip control")
	if skip == null:
		c._done = true
		return
	var at := skip.get_global_rect().get_center()
	_send_touch(0, at, true)
	await wait(ColdOpen.SKIP_HOLD + 0.5)
	_send_touch(0, at, false)
	await frames(2)
	check(c._done, "holding Skip leaves the memory card")


# --- holding E by touch -------------------------------------------------------------

func _by_note(w: World) -> void:
	w.player.global_position = w.area.note.global_position + Vector2(0, 20)
	await frames(3)


## The on-screen E sent interact AND confirm; in Godot 4.3 the second parsed
## action event releases the first, so "interact" was never held by touch
## and no glitch could be charged from a phone.
func test_holding_the_on_screen_e_charges_a_glitch() -> void:
	var w := await start_session(true, true)
	await _by_note(w)
	check_eq(w.glitch.target.get("id", ""), "falsify", "the note can be falsified")
	_send_touch(1, _e(), true)
	await wait(0.25)
	check(Input.is_action_pressed("interact"), "E is held while the finger stays on it")
	await wait(GlitchController.HOLD_START + Glitch.hold_time("falsify") + 0.4)
	_send_touch(1, _e(), false)
	await frames(3)
	check(w.area.note.falsified, "holding the on-screen E glitched the note")


func test_a_tap_never_becomes_a_glitch() -> void:
	var w := await start_session(true, true)
	await _by_note(w)
	var glitches: int = memory().session_glitches
	for ms in [30, 70, 120, 250]:
		_send_touch(1, _e(), true)
		await wait(ms / 1000.0)
		_send_touch(1, _e(), false)
		await frames(3)
		if w.hud.is_dialogue_open() or w.hud.is_cinematic():
			await finish_dialogue(w)
	check_eq(memory().session_glitches, glitches, "taps of 30-250 ms read the note, never glitch it")


# --- cancelling ------------------------------------------------------------------

func test_sliding_off_e_cancels_without_acting() -> void:
	var w := await start_session(true, true)
	await _by_mira(w)
	_send_touch(1, _e(), true)
	await frames(3)
	_send_drag(1, _e() + Vector2(-90, -40))  # well off the button
	await frames(3)
	check(not Input.is_action_pressed("interact"), "E lets go when the finger slides off")
	_send_touch(1, _e() + Vector2(-90, -40), false)
	await frames(6)
	check(not w.hud.is_dialogue_open(), "and nothing happens: no conversation")


func test_a_small_roll_off_e_keeps_it() -> void:
	var w := await start_session(true, true)
	await _by_mira(w)
	_send_touch(1, _e(), true)
	await frames(3)
	_send_drag(1, _e() + Vector2(-34, 0))  # a thumb rolling past the rim
	await frames(3)
	check(Input.is_action_pressed("interact"), "still held")
	_send_touch(1, _e() + Vector2(-34, 0), false)
	await frames(6)
	check(w.hud.is_dialogue_open(), "and the tap still talks")


func test_an_os_cancelled_touch_on_e_does_nothing() -> void:
	var w := await start_session(true, true)
	await _by_mira(w)
	_send_touch(1, _e(), true)
	await frames(3)
	_send_touch(1, _e(), true, true)  # cancelled (the platform keeps "pressed")
	await frames(6)
	check(not w.hud.is_dialogue_open(), "a cancelled touch never talks")
	check(not Input.is_action_pressed("interact"), "and E is released")


func test_losing_focus_mid_press_does_nothing_on_return() -> void:
	var w := await start_session(true, true)
	await _by_mira(w)
	_send_touch(1, _e(), true)
	await frames(3)
	w.touch.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await frames(6)
	check(not w.hud.is_dialogue_open(), "switching apps mid-press doesn't talk")
	_send_touch(1, _e(), false)
	await frames(4)
	check(not w.hud.is_dialogue_open(), "nor does the late release")


# --- one owner per press ---------------------------------------------------------

func test_a_press_held_from_play_never_advances_a_new_line() -> void:
	var w := await start_session(true, true)
	w.player.global_position = Vector2(300, 300)
	await frames(2)
	_send_touch(1, _e(), true)
	await frames(3)
	w.hud.show_dialogue("SYSTEM", Color.WHITE, ["(first)", "(second)"])
	await wait(1.2)
	_send_touch(1, _e(), false)
	await frames(4)
	check(w.hud.is_dialogue_open() and w.hud._dialogue_index == 0, "still the first line: the old press is not this box's")


func test_one_press_answers_one_question() -> void:
	var w := await start_session(true, true)
	var picks := []
	var ask := func() -> void:
		picks.append(await w.hud.choose("?", ["one", "two"]))
		picks.append(await w.hud.choose("again?", ["three", "four"]))
	ask.call()
	await wait(float(Hud.CHOICE_GRACE_MS) / 1000.0 + 0.2)
	# Enter is ui_accept (the focused button presses) AND confirm.
	var k := InputEventKey.new()
	k.keycode = KEY_ENTER
	k.physical_keycode = KEY_ENTER
	k.pressed = true
	Input.parse_input_event(k)
	await frames(2)
	var up := k.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await frames(6)
	check_eq(picks.size(), 1, "one press, one answer (the second question still waits)")
	w.hud.cancel_choice()
	await frames(2)


# --- several fingers ---------------------------------------------------------------

func test_release_order_does_not_matter() -> void:
	var w := await start_session()
	for order in [[1, 2], [2, 1]]:
		_send_touch(1, _e(), true)
		_send_touch(2, _e() + Vector2(6, 6), true)
		await frames(2)
		_send_touch(order[0], _e(), false)
		await frames(2)
		check(Input.is_action_pressed("interact"), "held after finger %d lifts" % order[0])
		_send_touch(order[1], _e(), false)
		await frames(2)
		check(not Input.is_action_pressed("interact"), "released after finger %d lifts" % order[1])
	check(w.touch._held.is_empty(), "nobody left holding")


# --- frame rates -----------------------------------------------------------------

## A tap to talk and a tap to close, at 8-60 FPS with taps of 30-250 ms:
## every tap is handled once (talk opens; the next tap closes it).
func test_taps_land_at_every_frame_rate() -> void:
	var w := await start_session(true, true)
	await _by_mira(w)
	var before := Engine.max_fps
	var missed := []
	for fps in [8, 15, 30, 60]:
		Engine.max_fps = fps
		for ms in [30, 70, 120, 250]:
			_send_touch(1, _e(), true)
			await wait(ms / 1000.0)
			_send_touch(1, _e(), false)
			var opened := await wait_until(func() -> bool: return w.hud.is_dialogue_open(), 1.5, "")
			if not opened:
				missed.append("%dfps %dms talk" % [fps, ms])
				continue
			await finish_dialogue(w)
			await wait(0.3)
	Engine.max_fps = before
	check(missed.is_empty(), "every tap talked (missed: %s)" % str(missed))


func test_festival_skip_chip_while_a_story_panel_is_open() -> void:
	Input.emulate_mouse_from_touch = false
	var p := await _festival()
	settings().using_touch = true
	p._story_break("phone_test", [["SYSTEM", "a page"], ["SYSTEM", "another page"]])
	await frames(2)
	check(p.story.visible, "a story page is up (the stick and E are off)")
	_send_touch(0, _chip(), true)
	await wait(Prologue.SKIP_HOLD + 0.6)
	_send_touch(0, _chip(), false)
	await frames(2)
	check(p.acted.has("skipped"), "the chip still skips during a story page")
	p._done = true
	p._handed_off = true


## Time away (backgrounded, or one huge frame) never completes a skip hold.
func test_a_long_frame_cannot_finish_the_skip_by_itself() -> void:
	var p := await _festival()
	settings().using_touch = true
	p._update_skip(0.01)  # arm (nothing held)
	p._touch._zone_fingers[0] = "skip"
	p._update_skip(0.05)
	check(p._skip_t > 0.0, "the hold is counting")
	p._update_skip(5.0)   # one 5 s frame (the tab was in the background)
	check(not p.acted.has("skipped"), "a single long frame doesn't skip")
	p._touch._zone_fingers.clear()
	p._done = true
	p._handed_off = true

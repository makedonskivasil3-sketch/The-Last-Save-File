extends "res://tests/test_case.gd"
## One player, one controller (2026-10-22 opening review, items 1 and 2):
## why the film or the game is held is kept apart (the window's focus, the
## player's controller), only the controller in use counts, and no ordinary
## press is lost between a tap and a skip.


func _film() -> Opening:
	settings().opening_seen = false
	var film := Opening.new()
	var old := tree.current_scene
	tree.root.add_child(film)
	tree.current_scene = film
	if old:
		old.queue_free()
	await frames(2)
	return film


func _step(film: Opening, seconds: float) -> void:
	for i in int(seconds / 0.05):
		if film._done:
			return
		film._process(0.05)


## Is the film running? (Held: nothing advances.)
func _runs(film: Opening) -> bool:
	var e := film.elapsed
	_step(film, 0.3)
	return film.elapsed > e


## The player's controller: a press on pad `device` (an unmapped button, so
## it does nothing in the film but say which pad is in use).
func _use_pad(device: int) -> void:
	for pressed in [true, false]:
		var ev := InputEventJoypadButton.new()
		ev.device = device
		ev.button_index = JOY_BUTTON_RIGHT_STICK
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await frames(1)


## Done with this film: gone, without a scene change (which would land in
## the next test and free its film).
func _end(film: Opening) -> void:
	film._done = true
	film._handed_off = true
	film.queue_free()
	await frames(2)


func after_each() -> void:
	settings().using_gamepad = false
	super()


func test_a_reconnected_controller_does_not_bring_back_the_window() -> void:
	var film := await _film()
	_step(film, 1.0)
	await _use_pad(0)
	film._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	film._on_joy_connection_changed(0, false)
	film._on_joy_connection_changed(0, true)
	check(not await _runs(film), "the window is still elsewhere: still held")
	film._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(await _runs(film), "both back: it runs")
	await _end(film)


func test_the_window_coming_back_does_not_bring_back_the_controller() -> void:
	var film := await _film()
	_step(film, 1.0)
	await _use_pad(0)
	film._on_joy_connection_changed(0, false)
	film._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	film._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(not await _runs(film), "the controller is still gone: still held")
	film._on_joy_connection_changed(0, true)
	check(await _runs(film), "back")
	await _end(film)


func test_unplugging_a_controller_nobody_is_using_changes_nothing() -> void:
	var film := await _film()
	_step(film, 1.0)
	await _use_pad(0)
	film._on_joy_connection_changed(1, false)
	check(await _runs(film), "pad 1 was never used: the film goes on")
	await _end(film)


func test_another_controller_arriving_does_not_stand_in_for_the_lost_one() -> void:
	var film := await _film()
	_step(film, 1.0)
	await _use_pad(0)
	film._on_joy_connection_changed(0, false)
	film._on_joy_connection_changed(1, true)
	check(not await _runs(film), "an unrelated pad plugged in: still waiting for the player's")
	await _use_pad(1)
	check(await _runs(film), "a press on it is the player taking over")
	await _end(film)


func test_a_key_takes_over_and_that_press_does_nothing_else() -> void:
	var film := await _film()
	_step(film, 6.0)  # at the ritual
	film._rue_x = Opening.SAVE_X
	await _use_pad(0)
	film._on_joy_connection_changed(0, false)
	var ev := InputEventKey.new()
	ev.keycode = KEY_E
	ev.physical_keycode = KEY_E
	ev.pressed = true
	Input.parse_input_event(ev)
	await frames(1)
	Input.action_press("interact")  # (the same key, still down)
	_step(film, 0.2)
	Input.action_release("interact")
	_step(film, 0.2)
	check(await _runs(film), "the keyboard took over")
	check(not film.acted.has("ritual"), "the key that took over didn't also press (%s)" % film.acted)
	await _end(film)


# --- no lost press ------------------------------------------------------------

func _press_for(film: Opening, seconds: float) -> void:
	Input.action_press("interact")
	_step(film, seconds)
	Input.action_release("interact")
	_step(film, 0.1)


func test_a_slow_press_still_presses() -> void:
	for held in [0.1, Opening.TAP - 0.05, Opening.TAP + 0.05, 0.5, Opening.SKIP_HOLD - 0.1]:
		var film := await _film()
		_step(film, 0.5)  # armed: nothing was held
		_step(film, 5.0)
		film._rue_x = Opening.SAVE_X
		_press_for(film, held)
		_step(film, 1.2)
		check(film.acted.has("ritual") and not film._done, "held %.2f s and let go: pressed, not skipped (%s)" % [held, film.acted])
		await _end(film)
		await frames(2)


func test_a_press_held_to_the_end_skips_and_only_skips() -> void:
	for held in [Opening.SKIP_HOLD + 0.05, 1.2]:
		var film := await _film()
		_step(film, 5.5)
		film._rue_x = Opening.SAVE_X
		_press_for(film, held)
		check(film._done, "held %.2f s: skipped" % held)
		check(film.acted.is_empty() and film._habit_t < 0.0, "and didn't also press (%s)" % film.acted)
		await _end(film)


# --- the game ------------------------------------------------------------------

func test_in_the_game_only_the_players_controller_pauses_it() -> void:
	var w := await start_session()
	await _use_pad(0)
	w._on_joy_connection_changed(1, false)
	await frames(2)
	check(not tree.paused, "an unused pad unplugged: play goes on")
	w._on_joy_connection_changed(0, false)
	await frames(2)
	check(tree.paused, "the player's pad unplugged: paused")
	tree.paused = false


func test_an_end_card_held_for_the_controller_is_not_released_by_focus() -> void:
	var w := await start_session()
	await _use_pad(0)
	w.ending = "win"  # an end card: no pause menu, the tree is held instead
	w.controller_lost()
	w.focus_returned()
	check(tree.paused, "focus came back, the controller didn't: still held")
	w._on_joy_connection_changed(0, true)
	check(not tree.paused, "the controller back: released")
	tree.paused = false


func test_rumble_goes_to_the_players_controller_only() -> void:
	await _use_pad(0)
	check_eq(settings().rumble_pads([0, 1, 2]), [0], "one player: only the pad in use")
	settings().using_gamepad = false
	check_eq(settings().rumble_pads([0, 1]), [], "not using a pad: none")


func test_an_end_card_held_for_the_controller_can_be_taken_over_by_a_key() -> void:
	var w := await start_session()
	await _use_pad(0)
	w.ending = "win"
	w.controller_lost()
	var ev := InputEventKey.new()
	ev.keycode = KEY_SPACE
	ev.pressed = true
	Input.parse_input_event(ev)
	await frames(2)
	check(not tree.paused, "a key took over")
	ev = ev.duplicate()
	ev.pressed = false
	Input.parse_input_event(ev)
	tree.paused = false


func _click(film: Opening, at: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = film.get_viewport().get_final_transform() * at  # (window coordinates)
	ev.global_position = ev.position
	Input.parse_input_event(ev)


func test_a_slow_click_on_the_save_point_still_presses() -> void:
	var film := await _film()
	await wait(0.4)  # armed
	film._t = Opening.GATE_AT[Opening.Gate.RITUAL]
	film._rue_x = Opening.SAVE_X
	_click(film, Vector2(Opening.SAVE_X, 200), true)
	await wait(0.5)  # past the old 0.3 s tap, short of the skip
	_click(film, Vector2(Opening.SAVE_X, 200), false)
	await wait_until(func() -> bool: return film.acted.has("ritual"), 3.0, "the press")
	check(not film._done, "not skipped")
	await _end(film)

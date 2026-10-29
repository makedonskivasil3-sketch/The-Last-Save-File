extends "res://tests/test_case.gd"
## Phone controls: the drag joystick, the E button and the pause button,
## driven by real touch events.


func after_each() -> void:
	settings().using_touch = false
	await super.after_each()


func test_dragging_moves_rue() -> void:
	var w := await start_session()
	var start: Vector2 = w.player.global_position
	await _touch(0, Vector2(120, 250), true)
	await _drag(0, Vector2(150, 250))  # thumb pushed to the right
	await wait(0.6)
	check(w.player.global_position.x > start.x + 20.0, "dragging right walks Rue right")
	await _touch(0, Vector2(150, 250), false)
	var stopped: Vector2 = w.player.global_position
	await wait(0.3)
	check(w.player.global_position.distance_to(stopped) < 1.0, "letting go stops")
	check(settings().using_touch, "prompts switch to the on-screen buttons")
	check_eq(settings().glyph("pause"), "II", "the pause prompt names the touch button")


func test_pressing_e_while_running_keeps_you_running() -> void:
	var w := await start_session()
	await _touch(0, Vector2(120, 250), true)
	await _drag(0, Vector2(150, 250))
	await wait(0.2)
	var e: Vector2 = TouchControls.BUTTONS["interact"].center
	await _touch(1, e, true)  # the E button, while the thumb holds the stick
	var x0: float = w.player.global_position.x
	await wait(0.4)
	check(w.player.global_position.x > x0 + 15.0, "still running while E is held")
	await _touch(1, e, false)
	await _touch(0, Vector2(150, 250), false)


func test_e_button_talks() -> void:
	var w := await start_session(true, true)
	w.player.global_position = w.area.mira.global_position + Vector2(0, 14)
	await frames(3)
	var e: Vector2 = TouchControls.BUTTONS["interact"].center
	await _touch(1, e, true)
	await _touch(1, e, false)
	await frames(2)
	check(w.hud.is_dialogue_open(), "the E button talks to Mira")


func test_pause_button() -> void:
	var w := await start_session()
	var p: Vector2 = TouchControls.BUTTONS["pause"].center
	await _touch(2, p, true)
	await _touch(2, p, false)
	await frames(2)
	check(w._pause_menu.visible, "the II button pauses")
	await _touch(2, p, true)
	await _touch(2, p, false)
	await frames(2)
	check(not w._pause_menu.visible, "and resumes")


## Touches are given in game space (640x360); the window may be bigger.
func _window_pos(game_pos: Vector2) -> Vector2:
	return tree.root.get_final_transform() * game_pos


func _touch(finger: int, game_pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = finger
	e.position = _window_pos(game_pos)
	e.pressed = pressed
	Input.parse_input_event(e)
	await frames(2)


func _drag(finger: int, game_pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = finger
	e.position = _window_pos(game_pos)
	Input.parse_input_event(e)
	await frames(2)


func test_focus_loss_releases_virtual_stick_and_buttons() -> void:
	var w := await start_session()
	await _touch(0, Vector2(120, 250), true)
	await _drag(0, Vector2(150, 250))
	await _touch(1, TouchControls.BUTTONS["interact"].center, true)
	var controls: TouchControls = w.touch
	check(controls != null, "touch controls exist")
	if controls == null:
		return
	controls.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check_eq(controls._stick_finger, -1, "focus loss forgets the thumb")
	check(controls._held.is_empty(), "focus loss releases buttons")
	check(not Input.is_action_pressed("move_right"), "movement released")
	check(not Input.is_action_pressed("interact"), "interaction released")
	var stopped: Vector2 = w.player.global_position
	await wait(0.3)
	check(w.player.global_position.distance_to(stopped) < 1.0, "no walking while away")


func test_canceled_touch_releases_the_stick() -> void:
	var w := await start_session()
	await _touch(0, Vector2(120, 250), true)
	await _drag(0, Vector2(150, 250))
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = _window_pos(Vector2(150, 250))
	e.canceled = true
	e.pressed = true  # cancellation wins even if the platform retains pressed
	Input.parse_input_event(e)
	await frames(2)
	check_eq(w.touch._stick_finger, -1, "OS cancellation releases the thumb")
	check(not Input.is_action_pressed("move_right"), "no stuck movement")


func test_rotating_to_portrait_cancels_and_blocks_virtual_movement() -> void:
	var w := await start_session()
	var win := tree.root
	var original: Vector2i = win.size
	w.touch.active = true
	w.touch._touch_down(0, Vector2(120, 250))
	w.touch._move_stick(Vector2(150, 250))
	win.size = Vector2i(360, 640)
	w.touch._process(0.01)
	check_eq(w.touch._stick_finger, -1, "rotation cancels the existing drag")
	w.touch._touch_down(0, Vector2(120, 250))
	check_eq(w.touch._stick_finger, -1, "the portrait notice blocks new virtual movement")
	win.size = original

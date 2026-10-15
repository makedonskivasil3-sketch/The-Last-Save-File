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

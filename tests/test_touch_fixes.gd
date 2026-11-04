extends "res://tests/test_case.gd"
## UI-2 on phones: portrait pauses; switching to keys hides the touch
## controls; dialogue text stops short of the touch E button.


func after_each() -> void:
	settings().using_touch = false
	super()


func test_portrait_pauses_play() -> void:
	var w := await start_session()
	w.touch.active = true
	var before := w.get_window().size
	w.get_window().size = Vector2i(360, 640)
	await frames(3)
	var portrait := Vector2(w.get_window().size).y > Vector2(w.get_window().size).x
	if not portrait:
		check(TouchControls.is_portrait(Vector2(360, 640)) and not TouchControls.is_portrait(Vector2(640, 360)), "this display can't resize: the rule itself")
		return
	check(tree.paused, "turned to portrait mid-play: paused")
	w.get_window().size = before
	await frames(2)


func test_a_key_hides_the_touch_controls() -> void:
	var w := await start_session()
	w.touch.active = true
	var e := InputEventKey.new()
	e.physical_keycode = KEY_W
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await frames(1)
	e.pressed = false
	Input.parse_input_event(e)
	check(not w.touch.active, "the keyboard took over: no stick or E drawn over the game")


func test_dialogue_clears_the_e_button() -> void:
	var w := await start_session()
	settings().using_touch = true
	w.hud._layout_dialogue_face()
	var right: float = w.hud._dialogue_text.position.x + w.hud._dialogue_text.size.x
	var e_left: float = TouchControls.BUTTONS["interact"].center.x - TouchControls.BUTTONS["interact"].radius
	check(right + w.hud._dialogue.position.x <= e_left, "text ends (%.0f) left of the E button (%.0f)" % [right + w.hud._dialogue.position.x, e_left])

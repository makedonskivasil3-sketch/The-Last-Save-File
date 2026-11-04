extends "res://tests/test_case.gd"
## Gamepad remapping (UI-3, the part that was missing): Interact and Pause
## can move to another pad button; B, the d-pad and the home button are
## refused; Start always pauses; prompts follow; it's kept and reset.


func after_each() -> void:
	settings().reset_binds()
	settings().using_gamepad = false
	super()


func _pad(button: int, pressed: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = button as JoyButton
	e.pressed = pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func test_interact_moves_to_x() -> void:
	check_eq(settings().bind_pad("interact", JOY_BUTTON_X), "", "interact -> X")
	_pad(JOY_BUTTON_X, true)
	await frames(1)
	check(Input.is_action_pressed("interact"), "X interacts")
	_pad(JOY_BUTTON_X, false)
	_pad(JOY_BUTTON_A, true)
	await frames(1)
	check(not Input.is_action_pressed("interact"), "A no longer interacts")
	check(Input.is_action_pressed("confirm"), "but A still confirms in menus")
	_pad(JOY_BUTTON_A, false)
	settings().using_gamepad = true
	check_eq(settings().glyph("interact"), "X", "prompts say X")


func test_refusals() -> void:
	check(settings().bind_pad("interact", JOY_BUTTON_B) != "", "B is kept for going back")
	check(settings().bind_pad("interact", JOY_BUTTON_DPAD_UP) != "", "the d-pad moves Rue")
	check(settings().bind_pad("interact", JOY_BUTTON_START) != "", "Start is pause's")
	check(settings().bind_pad("move_up", JOY_BUTTON_X) != "", "movement isn't on this list")
	check_eq(settings().bind_pad("pause", JOY_BUTTON_Y), "", "pause can add Y")
	check(settings().bind_pad("interact", JOY_BUTTON_Y) != "", "and then interact can't take Y")


func test_start_always_pauses() -> void:
	settings().bind_pad("pause", JOY_BUTTON_BACK)
	_pad(JOY_BUTTON_START, true)
	await frames(1)
	check(Input.is_action_pressed("pause"), "Start still pauses")
	_pad(JOY_BUTTON_START, false)
	_pad(JOY_BUTTON_BACK, true)
	await frames(1)
	check(Input.is_action_pressed("pause"), "and so does Back now")
	_pad(JOY_BUTTON_BACK, false)


func test_kept_and_reset() -> void:
	settings().bind_pad("interact", JOY_BUTTON_RIGHT_SHOULDER)
	settings().save()
	settings()._load()
	check_eq(settings().pad_for("interact"), JOY_BUTTON_RIGHT_SHOULDER, "kept across a restart")
	settings().reset_binds()
	check_eq(settings().pad_for("interact"), JOY_BUTTON_A, "reset: A again")

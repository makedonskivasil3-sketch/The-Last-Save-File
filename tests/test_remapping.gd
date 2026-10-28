extends "res://tests/test_case.gd"
## Control remapping (backlog B7): keyboard keys for moving, interacting and
## pausing can be changed; conflicts are refused; prompts follow; it's kept;
## the arrow keys and Esc always still work.


func after_each() -> void:
	settings().reset_binds()
	super()


func _press(code: int, pressed: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = pressed
	Input.parse_input_event(e)
	# Delivered now, not at the next frame's flush (which a test run first
	# in a fresh engine can miss).
	Input.flush_buffered_events()


func test_rebinding_interact_moves_the_key_and_the_prompt() -> void:
	check_eq(settings().bind_key("interact", KEY_F), "", "interact -> F")
	_press(KEY_F, true)
	await frames(1)
	check(Input.is_action_pressed("interact"), "F interacts")
	_press(KEY_F, false)
	_press(KEY_E, true)
	await frames(1)
	check(not Input.is_action_pressed("interact"), "E no longer does")
	_press(KEY_E, false)
	_press(KEY_SPACE, true)
	await frames(1)
	check(Input.is_action_pressed("interact"), "Space still does (a fixed fallback)")
	_press(KEY_SPACE, false)
	check_eq(settings().glyph("interact"), "F", "prompts say F")


func test_a_key_in_use_is_refused() -> void:
	var why: String = settings().bind_key("move_up", KEY_D)
	check(why.contains("Move right"), "D is moving right: refused (%s)" % why)
	why = settings().bind_key("interact", KEY_UP)
	check(why.contains("Move up"), "the arrow keys are kept for moving (%s)" % why)
	why = settings().bind_key("interact", KEY_ESCAPE)
	check(why != "", "Esc is kept for pausing")
	check_eq(settings().key_for("move_up"), KEY_W, "nothing changed")


func test_movement_keys_and_arrows() -> void:
	check_eq(settings().bind_key("move_up", KEY_I), "", "up -> I")
	_press(KEY_I, true)
	await frames(1)
	check(Input.is_action_pressed("move_up"), "I moves up")
	_press(KEY_I, false)
	_press(KEY_UP, true)
	await frames(1)
	check(Input.is_action_pressed("move_up"), "the up arrow still does")
	_press(KEY_UP, false)
	check(settings().glyph("move").begins_with("IASD"), "the move prompt names the keys (%s)" % settings().glyph("move"))


func test_pause_rebound_keeps_escape() -> void:
	check_eq(settings().bind_key("pause", KEY_P), "", "pause -> P")
	_press(KEY_ESCAPE, true)
	await frames(1)
	check(Input.is_action_pressed("pause"), "Esc still pauses")
	_press(KEY_ESCAPE, false)
	check_eq(settings().glyph("pause"), "P / ESC", "and the prompt says both")


func test_kept_across_launches_and_reset() -> void:
	settings().bind_key("interact", KEY_G)
	settings().key_binds.clear()
	settings()._load()
	settings().apply_binds()
	check_eq(settings().key_for("interact"), KEY_G, "read back from the settings file")
	settings().reset_binds()
	check_eq(settings().key_for("interact"), KEY_E, "reset: E again")
	check_eq(settings().glyph("move"), "WASD / ARROWS", "and the move prompt as before")


func test_the_settings_panel_rebinds() -> void:
	var panel := SettingsPanel.new()
	tree.root.add_child(panel)
	await frames(2)
	panel._start_binding("interact")
	check(panel._bind_buttons.interact.text.contains("press a key"), "it waits for a key")
	var e := InputEventKey.new()
	e.physical_keycode = KEY_R
	e.pressed = true
	panel._input(e)
	check_eq(settings().key_for("interact"), KEY_R, "the key pressed is the binding")
	check(panel._bind_buttons.interact.text.ends_with("R"), "and the button says so (%s)" % panel._bind_buttons.interact.text)
	panel._start_binding("interact")
	e = InputEventKey.new()
	e.physical_keycode = KEY_D
	e.pressed = true
	panel._input(e)
	check(panel._bind_note.text.contains("not changed"), "a conflict is explained (%s)" % panel._bind_note.text)
	panel.queue_free()
	await frames(1)

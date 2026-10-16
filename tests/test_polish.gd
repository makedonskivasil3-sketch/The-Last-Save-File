extends "res://tests/test_case.gd"
## Polish for real players: the How to Play screen, gamepad menus, rumble.


func _pad_button(button: JoyButton) -> void:
	for pressed in [true, false]:
		var e := InputEventJoypadButton.new()
		e.button_index = button
		e.pressed = pressed
		Input.parse_input_event(e)
		await frames(2)


func test_how_to_play_from_the_title() -> void:
	tree.change_scene_to_file("res://scenes/title.tscn")
	await frames(5)
	var title := scene()
	title._show_help()
	await frames(2)
	var text := ""
	for l in title.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			text += (l as Label).text + "\n"
	check(text.contains("HOW TO PLAY"), "the page opens")
	check(text.contains("GLITCHES") and text.contains("HIDING"), "the rules are explained")
	await press("ui_cancel")
	check(title._panel_of(title._menu).visible, "back to the menu")


func test_gamepad_drives_the_title_menu() -> void:
	tree.change_scene_to_file("res://scenes/title.tscn")
	await frames(5)
	var title := scene()
	check(title._load.has_focus(), "Load has focus first")
	await _pad_button(JOY_BUTTON_DPAD_DOWN)
	check(not title._load.has_focus(), "the d-pad moves focus")
	check(InputMap.action_has_event("ui_cancel", _b()), "B is back")
	title._show_help()
	await frames(2)
	await _pad_button(JOY_BUTTON_B)
	check(title._panel_of(title._menu).visible, "B closes How to Play")


func test_rumble_on_a_gamepad() -> void:
	var s := settings()
	s.vibration = true
	s.using_touch = false
	s.using_gamepad = true
	s.last_buzz = 0
	s.buzz(160)
	check_eq(s.last_buzz, 160, "a gamepad rumbles too")
	s.using_gamepad = false
	s.last_buzz = 0
	s.buzz(160)
	check_eq(s.last_buzz, 0, "keyboard and mouse: nothing")
	s.using_gamepad = true
	s.vibration = false
	s.buzz(160)
	check_eq(s.last_buzz, 0, "and Vibration off means off")


func _b() -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = JOY_BUTTON_B
	return e


func test_credits_carry_the_licences() -> void:
	tree.change_scene_to_file("res://scenes/title.tscn")
	await frames(5)
	var title := scene()
	title._show_credits()
	await frames(2)
	var text := "\n".join(CreditsPanel.credits().map(func(b: Array) -> String: return "%s\n%s" % [b[0], b[1]]))
	check(text.contains("All rights reserved"), "the game's licence")
	check(text.contains(Engine.get_license_text().substr(0, 60)), "Godot's MIT licence, from the engine")
	check(text.contains("FreeType"), "and its third-party components (FreeType renders the text)")
	await press("ui_cancel")
	check(title._panel_of(title._menu).visible, "back to the menu")

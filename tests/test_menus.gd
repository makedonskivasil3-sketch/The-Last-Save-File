extends "res://tests/test_case.gd"
## Title screen, pause menu, quitting, settings.


func test_pause_opens_and_esc_closes() -> void:
	var w := await start_session()
	await press("pause")
	check(tree.paused, "Esc pauses")
	await press("pause")
	check(not tree.paused, "Esc again resumes (and doesn't instantly reopen)")


func test_quit_to_title_counts_against_you() -> void:
	var w := await start_session()
	var purge_before: int = memory().purge
	w._pause_menu.open()
	w._pause_menu._ask_quit(true)
	w._pause_menu._do_quit()
	await wait_until(func() -> bool: return scene() != null and scene().scene_file_path == TITLE_SCENE, 5.0, "title screen")
	check_eq(memory().purge, purge_before + 1, "quitting raises purge")
	check_eq(memory().last_exit, "quit", "session closed as a quit")


func test_title_shows_slot_two_after_a_win() -> void:
	memory().wins = 1
	tree.change_scene_to_file(TITLE_SCENE)
	await wait(0.5)
	check(_title_text().contains("SLOT 2"), "Slot 2 appears once you've won")
	check(_title_text().contains("???"), "nameless until you remember")
	for f in Story.FRAGMENTS:
		memory().add_fragment(f.id)
	tree.reload_current_scene()
	await wait(0.5)
	check(_title_text().contains(Story.SECOND_PLAYER_NAME), "with every memory, Slot 2 has your name")


func test_settings_apply_and_clamp() -> void:
	var s := settings()
	s.set_value("volume", 0.0)
	check(AudioServer.is_bus_mute(0), "zero volume mutes")
	s.set_value("volume", 0.8)
	check(not AudioServer.is_bus_mute(0), "volume restores")
	s.set_value("screen_effects", 0)
	var w := await start_session()
	await frames(2)
	check(not w.fx.visible, "screen effects Off removes the full-screen pass")
	s.set_value("screen_effects", 2)
	await frames(2)
	check(w.fx.visible, "Full brings it back")


func _title_text() -> String:
	var out := ""
	for l in scene().find_children("*", "Label", true, false):
		out += (l as Label).text + "\n"
	return out


func test_back_from_a_page_returns_to_its_button() -> void:
	var w := await start_session()
	var menu: PauseMenu = w._pause_menu
	menu.open()
	await frames(2)
	menu._show_main()
	var help_button: Button = null
	for b in menu._main.find_children("*", "Button", true, false):
		if (b as Button).text == "How to Play":
			help_button = b
	check(help_button != null, "the pause menu has How to Play")
	help_button.grab_focus()
	await frames(1)
	help_button.pressed.emit()
	await frames(2)
	check(menu._panel_of(menu._help_box).visible, "the help page opens in a run")
	menu._help.closed.emit()
	await frames(2)
	check_eq(get_focus(menu._main), help_button, "focus comes back to the button that opened it")
	menu.close()


func get_focus(c: Control) -> Control:
	return c.get_viewport().gui_get_focus_owner()

extends "res://tests/test_case.gd"
## The vertical slice (docs/VERTICAL_SLICE.md): sessions count only once
## play starts; a controller dropping out holds the game; and the slice's
## route-level guarantees.


## A first launch, left on the boot text (start_session would wait it out).
func _first_launch_at_boot_text() -> Node:
	tree.change_scene_to_file(MAIN_SCENE)
	await wait_until(func() -> bool: return scene() != null and scene().get("hud") != null and scene().hud.is_cinematic(), 5.0, "the boot text")
	return scene()


func test_closing_during_the_boot_text_costs_nothing() -> void:
	# D1: a first launch, closed while the boot text is still up.
	await _first_launch_at_boot_text()
	check(not memory().session_armed(), "the boot text isn't play yet")
	var before := {"purge": memory().purge, "quits": memory().quits, "sessions": memory().sessions}
	memory().record_quit()  # what closing the window does
	check_eq(memory().purge, before.purge, "no purge for a run that never started")
	check_eq(memory().quits, before.quits, "and no quit counted")
	check_eq(memory().sessions, before.sessions - 1, "the session that never began isn't counted either")


func test_a_crash_during_the_boot_text_costs_nothing() -> void:
	await _first_launch_at_boot_text()
	var purge: int = memory().purge
	memory().load_memory()  # as if the process died and the game was reopened
	check_eq(memory().purge, purge, "a crash before play costs nothing")
	check(memory().last_exit != "crash", "and isn't recorded as one (%s)" % memory().last_exit)


func test_once_playing_a_quit_still_counts() -> void:
	await start_session()
	check(memory().session_armed(), "playing: the session counts")
	var purge: int = memory().purge
	memory().record_quit()
	check_eq(memory().purge, purge + 1, "quitting mid-run still costs what the menu says")


func test_a_controller_dropping_out_holds_the_game() -> void:
	# D2: a pad disconnecting mid-play opens the pause menu, ignoring the
	# focus-loss setting (the player can't play on without it).
	var w := await start_session()
	Settings.using_gamepad = true
	w._on_joy_connection_changed(0, false)
	await frames(2)
	check(tree.paused, "the game holds")
	check(w._pause_menu.visible, "on the pause menu, to resume when ready")
	w._pause_menu.close()
	await frames(2)
	Settings.using_gamepad = false
	w._on_joy_connection_changed(0, false)
	await frames(2)
	check(not tree.paused, "a pad nobody was using doesn't stop keyboard play")


func test_the_title_room_drifts_within_bounds_and_holds_with_reduced_motion() -> void:
	settings().opening_seen = true
	tree.change_scene_to_file("res://scenes/title.tscn")
	await wait(0.5)
	var art: TitleArt = scene().find_children("*", "TitleArt", true, false)[0]
	var buttons := scene().find_children("*", "Button", true, false)
	var before := buttons.map(func(b: Button) -> Vector2: return b.global_position)
	var widest := 0.0
	for i in 200:
		art.elapsed = i * 0.7
		widest = maxf(widest, art.layer_offset("near").length())
		check(art.layer_offset("wall").length() <= art.layer_offset("near").length() + 0.001, "further layers move less")
	check(widest > 1.0 and widest <= TitleArt.PARALLAX * 1.42, "the nearest layer drifts, at most %.0f px (%.2f)" % [TitleArt.PARALLAX, widest])
	await wait(0.5)
	check_eq(buttons.map(func(b: Button) -> Vector2: return b.global_position), before, "the menu never moves")
	settings().reduce_motion = true
	for i in 20:
		art.elapsed = i * 3.1
		check_eq(art.layer_offset("near"), Vector2.ZERO, "reduced motion: no drift")
	check(Opening.calm(), "and the opening's push is off too")

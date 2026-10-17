extends "res://tests/test_case.gd"


func test_history_keeps_full_messages_without_exposing_queue() -> void:
	var w := await start_session()
	w.hud.clear_queue()
	w.hud.console_history.clear()
	w.hud._typing = null
	w.hud._pause = 0.0
	var long_line := "A long message " + "that must stay readable. ".repeat(40)
	w.hud.say(long_line, "system")
	w.hud.say("not displayed yet", "system")
	check(w.hud.console_history.is_empty(), "queue is not exposed before display")
	w.hud._update_typing(0.0)
	check_eq(w.hud.console_history.size(), 1, "only displayed message is recorded")
	check_eq(w.hud.console_history[0], long_line, "full text survives HUD ellipsis")
	w._pause_menu.open()
	w._pause_menu._show_history()
	check(w._pause_menu._history_text.text.contains(long_line), "history shows the full line")
	check(not w._pause_menu._history_text.text.contains("not displayed yet"), "history hides future lines")
	var awareness: float = w.director.awareness
	await wait(0.2)
	check_eq(w.director.awareness, awareness, "reading history pauses the owner")
	await press("pause")
	check(tree.paused, "back from history stays paused")
	check(w._pause_menu._panel_of(w._pause_menu._main).visible, "back returns to pause menu")
	w._pause_menu.close()


func test_history_is_bounded_and_resets_with_session() -> void:
	var w := await start_session()
	w.hud.clear_queue()
	w.hud.console_history.clear()
	for i in Hud.MAX_HISTORY + 5:
		w.hud._typing = null
		w.hud._pause = 0.0
		w.hud.say(str(i), "system")
		w.hud._update_typing(0.0)
	check_eq(w.hud.console_history.size(), Hud.MAX_HISTORY, "history stays bounded")
	check_eq(w.hud.console_history[0], "5", "oldest entries rotate out")
	w = await start_session()
	check(not w.hud.console_history.has("5"), "new run has its own history")


func test_door_announces_one_state_but_applies_all_consequences() -> void:
	var w := await start_session(true, true)
	w.hud.clear_queue()
	w.director.on_door_approached()
	for threshold in [OwnerDirector.NOTICE, OwnerDirector.SUSPECT, OwnerDirector.CONTAIN]:
		check(w.director.has_fired(threshold), "door still applies threshold %s" % threshold)
	var owner_lines: Array = w.hud._queue.filter(func(msg: Dictionary) -> bool: return msg.kind == "owner")
	check_eq(owner_lines.size(), 2, "door says nope and the final state, without intermediate chatter")
	check(w.area.door.state != Door.State.OPEN, "door locks immediately")


func test_repeat_materialization_finishes_before_control_returns() -> void:
	var w := await start_session()
	check(memory().sessions > 1, "repeat session")
	check_eq(w.player._dissolve, "", "repeat appearance finishes before movement resumes")
	check(not w.player.frozen, "repeat run is playable")


func test_pause_history_fits_viewport_with_large_text() -> void:
	var w := await start_session()
	settings().set_value("large_text", true)
	w._pause_menu.open()
	await frames(3)
	var viewport: Rect2 = tree.root.get_visible_rect()
	var panel := w._pause_menu._panel_of(w._pause_menu._main).get_child(0) as Control
	check(viewport.encloses(panel.get_global_rect()), "pause menu fits with large text")
	w._pause_menu._show_history()
	await frames(3)
	panel = w._pause_menu._panel_of(w._pause_menu._history_box).get_child(0) as Control
	check(viewport.encloses(panel.get_global_rect()), "history fits with large text: %s inside %s" % [panel.get_global_rect(), viewport])
	w._pause_menu.close()
	settings().set_value("large_text", false)

extends "res://tests/test_case.gd"
## First-session tips, the readable HUD (status line, large text) and the
## pause menu's goal line.


func test_tips_play_in_order_and_only_once() -> void:
	settings().tutorial_tips = true
	var w := await start_session(true, true)
	await wait_until(func() -> bool: return w.hud.is_tip_shown(), 4.0, "first tip")
	check_eq(w.hud._tip_title.text, "MOVE", "the first tip teaches moving")
	check("move" in settings().tips_seen, "a shown tip is remembered")
	w.player.global_position += Vector2(70, 0)
	await wait_until(func() -> bool: return w.hud._tip_title.text == "THE OWNER IS WATCHING", 8.0, "second tip")
	# Every room tip is eventually shown; a new session shows none of them again.
	for id in Tutorial.SEQUENCE:
		settings().mark_tip_seen(id)
	w.kill("erased")
	var next := await wait_for_new_session(w)
	await wait(3.0)
	check(not next.hud.is_tip_shown(), "seen tips never come back")


func test_tips_off_means_no_tips() -> void:
	var w := await start_session(true, true)
	await wait(3.0)
	check(not w.hud.is_tip_shown(), "Settings > Tutorial tips off: no tips")


func test_turning_tips_back_on_replays_them() -> void:
	settings().tips_seen.append("move")
	settings().set_value("tutorial_tips", true)
	check(settings().tips_seen.is_empty(), "switching tips on clears the seen list")


func test_hiding_shows_a_status_line() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.player.global_position = w.area.wren.global_position + Vector2(10, 0)
	await frames(3)
	check(w.player.sheltered, "Rue knows they're sheltered")
	check(w.hud._status.text.begins_with("HIDDEN"), "the HUD says you're hidden")
	w.player.global_position += Vector2(120, 0)
	await frames(3)
	check_eq(w.hud._status.text, "", "and stops saying so when you leave")


func test_large_text_scales_the_hud() -> void:
	var w := await start_session()
	var label: Label = w.hud._slot
	var base := label.get_theme_font_size("font_size")
	settings().set_value("large_text", true)
	check(label.get_theme_font_size("font_size") > base, "large text makes HUD text bigger")
	settings().set_value("large_text", false)
	check_eq(label.get_theme_font_size("font_size"), base, "and back")


func test_pause_menu_shows_the_goal() -> void:
	var w := await start_session()
	await press("pause")
	await frames(2)
	var goal: String = w._pause_menu._goal_label.text
	check(goal.contains("Arin's room"), "the goal in the first room is to get out")
	check(goal.contains("0 / 5"), "and memories recovered are counted")
	await press("pause")

extends "res://tests/test_case.gd"
## Pass 4 screenshots: tips, pause and quit, in-run help, the death card's
## "kept" line, Pip and the shed body, and large text. Not part of the suite.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" $GODOT --path . -s res://tests/run_tests.gd \
##       -- --test-mode --tour --filter=tour_pass4 --screenshots=/some/dir


func test_p4_tip_and_prompt() -> void:
	settings().tutorial_tips = true
	var w := await start_session(true, true)
	w.director.paused = true
	await wait_until(func() -> bool: return w.hud.is_tip_shown(), 5.0, "first tip")
	await wait(0.6)
	await shot("p4_01_first_tip")
	w.player.global_position = w.area.mira.global_position + Vector2(18, 0)
	await wait(1.0)
	await shot("p4_02_prompt_over_mira")


func test_p4_pause_quit_help() -> void:
	var w := await start_session()
	w._pause_menu.open()
	await wait(0.4)
	w._pause_menu._show_main()
	await wait(0.3)
	await shot("p4_03_pause")
	w._pause_menu._ask_quit(true)
	await wait(0.3)
	await shot("p4_04_quit_confirm")
	w._pause_menu._show_help()
	await wait(0.3)
	await shot("p4_05_help_in_run")
	w._pause_menu.close()


func test_p4_death_card() -> void:
	var w := await start_session()
	w.kill("erased", "arin")
	await wait_until(func() -> bool: return w.hud._overlay_retry.visible, 4.0, "retry")
	await wait(0.5)
	await shot("p4_06_death_card")


func test_p4_large_text() -> void:
	settings().set_value("large_text", true)
	var w := await start_session()
	await go_to(w, "square", "house")
	w.hud.set_status("HIDDEN · the owner is losing track")
	await wait(1.0)
	await shot("p4_07_square_large_text")
	settings().set_value("large_text", false)


func test_p4_pip_and_body() -> void:
	var w := await start_session()
	w.director.paused = true
	await go_to(w, "square", "house")
	w._spawn_pip()
	var husk := Husk.new()
	husk.position = w.player.global_position + Vector2(-30, 10)
	w.area.add_child(husk)
	await wait(1.0)
	await shot("p4_08_square_body")


func test_p4_archive_and_edge_calm() -> void:
	var w := await start_session()
	w.director.paused = true
	await go_to(w, "archive", "west")
	await wait(1.0)
	await shot("p4_09_archive_calm")
	await go_to(w, "edge", "south")
	w.director.paused = true
	await wait(1.0)
	await shot("p4_10_edge_calm")

extends "res://tests/test_case.gd"
## Every visual event runs without script errors, and settings scale them.
## (Run with --screenshots=<dir> under a display to eyeball them.)


func test_each_death_style_plays_and_reloads() -> void:
	for cause in ["erased", "overwritten", "selected"]:
		var w := await start_session()
		w.kill(cause)
		await wait(1.0)
		await shot("death_" + cause)
		check_eq(w.ending, "death", "%s ends the session" % cause)
		var next := await wait_for_new_session(w)
		check(next != null, "%s reloads into a new session" % cause)


func test_owner_events_run_cleanly() -> void:
	var w := await start_session()
	w.fx.threshold_pulse(0.5)
	w.fx.deletion_hit()
	w.fx.cursor_arrives()
	w.fx.eraser_starts()
	w.fx.enter_area("edge")
	w.fx.memory(true)
	await wait(0.6)
	w.fx.memory(false)
	check(w.area.mira.delete(), "Mira can be deleted")
	await wait(1.8)
	check_eq(w.area.mira.state, Npc.State.DELETED, "deletion finishes")


func test_win_sequence() -> void:
	var w := await start_session()
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	w.win()
	await wait(0.5)
	check(w.fx.squeeze > 0.0, "the tube collapses")
	await wait(2.0)
	check(w.fx.squeeze < 0.05, "and comes back")


func test_reduce_flashing_scales_flashes_down() -> void:
	settings().reduce_flashing = true
	check(settings().flash_scale() < 0.5, "flash scale drops")
	var w := await start_session()
	w.fx.roll_slip(0.2)
	check(w.fx._roll_target <= 0.2 * 0.31, "screen roll is reduced")

extends "res://tests/test_case.gd"
## The development-only playtest log (docs/PLAYTEST_PLAN.md).


func after_each() -> void:
	PlaytestLog.reset(false)
	super()


func test_off_unless_asked_for() -> void:
	PlaytestLog.reset(false)
	var w := await start_session()
	await go_to(w, "square", "house")
	check(PlaytestLog.lines.is_empty(), "nothing is recorded in a normal game")


func test_records_the_session_sheet_moments() -> void:
	PlaytestLog.reset(true)
	var w := await start_session()
	w.player.velocity = Vector2(50, 0)
	await frames(2)
	await go_to(w, "square", "house")
	w.kill("selected", "cursor")
	await frames(2)
	var log := "\n".join(PlaytestLog.lines)
	check(log.contains("session"), "the session start")
	check(log.contains("first movement"), "first movement")
	check(log.contains("FIRST TIME OUT OF ARIN'S ROOM"), "leaving the room")
	check(log.contains("DIED") and log.contains("cursor"), "the death and its cause")
	check(PlaytestLog.lines[0].begins_with("00:0"), "timestamped")


## The session plan's watch list (COMMERCIAL_DIRECTION.md §8): the gate,
## hiding that actually turned a look aside, the journal, and each death's
## place and whether a warning was showing.
func test_records_the_watch_list() -> void:
	PlaytestLog.reset(true)
	var w := await start_session()
	await go_to(w, "square", "house")
	w.player.global_position = Vector2(757, 84)  # the lane side, where the latch is
	w.area.gate.interact()
	w.player.global_position = w.area.wren.global_position + Vector2(8, 0)
	w.is_player_hidden(w.player.global_position, "arin")
	w.is_player_hidden(w.player.global_position)  # no witness: nobody looked
	w._pause_menu._show_journal()
	w.hud.warn("it's coming")
	w.kill("selected", "cursor")
	await frames(2)
	var log := "\n".join(PlaytestLog.lines)
	check(log.contains("lifted the lane gate"), "the gate (%s)" % log)
	check(log.contains("hidden from arin behind wren"), "hiding that held")
	check(log.count("hidden from") == 1, "only a look that reached Rue counts")
	check(log.contains("journal opened"), "the journal")
	check(log.contains("warning on screen: \"it's coming\"") and log.contains(" at ("), "the death's place and its warning")


func test_the_opening_records_how_each_state_was_done() -> void:
	PlaytestLog.reset(true)
	settings().opening_seen = false
	var film := Opening.new()
	film.autoplay = true
	var old := tree.current_scene
	tree.root.add_child(film)
	tree.current_scene = film
	if old:
		old.queue_free()
	await wait_until(func() -> bool: return "\n".join(PlaytestLog.lines).contains("impossible action"), 60.0, "the third state")
	var log := "\n".join(PlaytestLog.lines)
	check(log.contains("opening: ritual (save with Arin)  ·  played itself"), "the ritual played itself (%s)" % log)
	check(log.contains("opening: interruption"), "the interruption")
	check(log.contains("opening: impossible action (walk under PAUSE)"), "the impossible action")

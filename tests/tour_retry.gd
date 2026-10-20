extends "res://tests/bot_playthrough.gd"
## Measures the walk back after a death at the Edge (docs/GAMEPLAY_CONSISTENCY.md,
## pass 8): a save that has everything a finale needs (every memory, Pip,
## the pointer) and just died at the Edge. The bot's real-input driving goes
## from waking up to the Edge; the tour prints how long each leg took and
## what was said on the way. Not part of the suite:
##   ... -s res://tests/run_tests.gd -- --test-mode --tour --filter=tour_retry


# (The bots themselves don't run from here.)
func test_full_game_escape() -> void:
	pass


func test_full_game_message() -> void:
	pass


func test_full_game_escape_purge_3() -> void:
	pass


func test_wren_ending() -> void:
	pass


func _ready_for_the_finale(purge: int) -> void:
	memory().wipe()
	for f in Story.FRAGMENTS:
		memory().fragments.append(f.id)
	memory().found_pip = true
	memory().met_archivist = true
	memory().found_controller = true
	memory().sessions = 3
	memory().deaths = purge
	memory().purge = purge
	memory().edge_mercy_used = true
	memory().last_exit = "death"
	memory().deaths_log.append({"area": "edge", "x": 300.0, "y": 200.0, "session": 3})


func _retry(purge: int) -> void:
	_ready_for_the_finale(purge)
	_t0 = _now()
	var w := await start_session(true, false)
	var woke := _now() - _t0
	var left := await _leave_room(w)
	var out_room := _now() - _t0
	var aw_out: float = w.director.awareness
	var at_edge := false
	if left:
		at_edge = await _north(w)
	var total := _now() - _t0
	print("RETRY purge %d: control after %.1f s · out of the room %.1f s (aw %.0f) · at the Edge %.1f s (aw %.0f) · reached %s" % [
		purge, woke, out_room, aw_out, total, w.director.awareness, at_edge])
	check(at_edge, "the bot got back to the Edge (purge %d)" % purge)


func test_retry_after_an_edge_death_purge_1() -> void:
	await _retry(1)


func test_retry_after_an_edge_death_purge_3() -> void:
	await _retry(3)

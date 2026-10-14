extends "res://tests/test_case.gd"
## CPU budget and leak checks. Budgets are generous so slower CI machines
## pass; locally the game runs at ~0.3-0.5 ms per frame.

const FRAME_BUDGET_MS := 4.0


func test_worst_case_frame_stays_in_budget() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.stop()
	w.area._unleash()
	w.area.cursor.player = null
	w.player.global_position = Vector2(-80, -80)  # stay alive while the room fills
	w.area.erasure.interval = 0.002
	w.area.erasure.burst = 4
	await wait(3.0)
	var ms := await _measure(240)
	check(ms < FRAME_BUDGET_MS, "fully hunted square: %.2f ms/frame (budget %.1f)" % [ms, FRAME_BUDGET_MS])


func test_no_leaks_across_area_changes() -> void:
	var w := await start_session()
	w.flags["pointer"] = true
	var route := [["square", "house"], ["archive", "west"], ["square", "east"], ["edge", "south"]]
	# Warm up caches (fonts, strings), then measure growth over more loops.
	for a in route:
		await go_to(w, a[0], a[1])
	await frames(10)
	var objects := Performance.get_monitor(Performance.OBJECT_COUNT)
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	for loop in 4:
		for a in route:
			await go_to(w, a[0], a[1])
	await frames(10)
	check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == 0, "no orphan nodes")
	# A few nodes of slack: the console fills up to its line limit, transient
	# tweens/effects come and go. A leak would grow by dozens over 16 loads.
	var node_growth := Performance.get_monitor(Performance.OBJECT_NODE_COUNT) - nodes
	check(node_growth <= 3, "node count stable (+%d)" % node_growth)
	check(Performance.get_monitor(Performance.OBJECT_COUNT) - objects < 60, "object count stable (+%d)" % (Performance.get_monitor(Performance.OBJECT_COUNT) - objects))


## Wall-clock ms per frame with the headless idle sleep removed.
func _measure(n: int) -> float:
	var sleep := OS.low_processor_usage_mode_sleep_usec
	OS.low_processor_usage_mode_sleep_usec = 0
	await frames(5)
	var t0 := Time.get_ticks_usec()
	await frames(n)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0 / n
	OS.low_processor_usage_mode_sleep_usec = sleep
	return ms

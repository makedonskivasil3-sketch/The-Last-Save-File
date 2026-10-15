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


func test_theme_builds_in_slices_identically() -> void:
	memory().runtime_cache.clear()
	var whole: AudioStreamWAV = MusicBox.render(3, "invert")
	memory().runtime_cache.clear()
	var job := MusicBox.Job.new(3, "invert")
	var slices := 1
	while not job.step(500):  # half a millisecond at a time
		slices += 1
	check(slices > 1, "the theme was built over several slices (%d)" % slices)
	check(job.result.data == whole.data, "and comes out exactly the same")


func test_session_prewarms_the_themes_it_will_need() -> void:
	memory().runtime_cache.clear()
	var w := await start_session()
	await wait_until(func() -> bool: return not Sfx.is_busy(), 10.0, "background building")
	for key in ["theme_1_normal", "theme_0_reverse", "theme_0_invert"]:
		check(memory().runtime_cache.has(key), "%s is ready before it's needed" % key)
	# Entering the Edge then costs no render on the spot.
	w.flags["pointer"] = true
	var sleep := OS.low_processor_usage_mode_sleep_usec
	OS.low_processor_usage_mode_sleep_usec = 0
	var worst := [0.0]
	var last := [Time.get_ticks_usec()]
	var on_frame := func() -> void:
		var now := Time.get_ticks_usec()
		worst[0] = maxf(worst[0], (now - last[0]) / 1000.0)
		last[0] = now
	tree.process_frame.connect(on_frame)
	await go_to(w, "edge", "south")
	await frames(10)
	tree.process_frame.disconnect(on_frame)
	OS.low_processor_usage_mode_sleep_usec = sleep
	check(worst[0] < 30.0, "no hitch entering the Edge (worst frame %.1f ms)" % worst[0])


func test_building_waits_while_you_are_chased() -> void:
	memory().runtime_cache.clear()
	var w := await start_session()
	await wait_until(func() -> bool: return not Sfx.is_busy(), 10.0, "background building")
	w.owner_moves.start_save_over()  # the owner is saving over you
	MusicBox.prewarm(5, "invert")
	await frames(10)
	check(Sfx.is_busy(), "nothing is built mid-chase")
	check(not memory().runtime_cache.has("theme_5_invert"), "(still queued)")
	# But if it's needed right now, it's built on the spot.
	check(MusicBox.stream(5, "invert") != null, "asking for it finishes it")
	check(not Sfx.is_busy(), "and takes it off the queue")


func test_frame_time_overlay_toggles() -> void:
	var w := await start_session()
	w.debug("perf")
	await frames(2)
	check(w.get_node_or_null("PerfOverlay") != null, "F3 / Debug shows frame times")
	w.debug("perf")
	await frames(2)
	check(w.get_node_or_null("PerfOverlay") == null, "and hides them again")
	World.show_perf = false

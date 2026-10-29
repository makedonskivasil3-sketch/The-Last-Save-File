extends "res://tests/test_case.gd"
## The game camera in the square (wider than the screen): what it does on a
## reversal and during a story hold, and whether it ever shows past the
## map. Prints numbers; not part of the suite.


func test_game_camera() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	w.area.arin.paused = true
	w.player.global_position = Vector2(400, 262)
	await wait(1.0)
	var limit: float = maxf(0.0, w.area.view_size.x - Area.BACKDROP_SIZE.x)
	var lo := INF
	var hi := -INF
	Input.action_press("move_right")
	for i in 90:
		await tree.physics_frame
		lo = minf(lo, w.view_offset.x)
		hi = maxf(hi, w.view_offset.x)
	Input.action_release("move_right")
	var before: float = w.view_offset.x
	Input.action_press("move_left")
	var swing := 0.0
	var max_step := 0.0
	var last: float = w.view_offset.x
	for i in 36:
		await tree.physics_frame
		swing = maxf(swing, absf(w.view_offset.x - before))
		max_step = maxf(max_step, absf(w.view_offset.x - last))
		last = w.view_offset.x
		lo = minf(lo, w.view_offset.x)
		hi = maxf(hi, w.view_offset.x)
	Input.action_release("move_left")
	print("CAMERA reversal (0.6 s back after 1.5 s right): view moved %.1f px, largest frame step %.2f px" % [swing, max_step])
	print("CAMERA view offset stayed within [%.1f, %.1f]; map allows [0, %.1f]" % [lo, hi, limit])
	check(lo >= -0.01 and hi <= limit + 0.01, "never shows past the map")

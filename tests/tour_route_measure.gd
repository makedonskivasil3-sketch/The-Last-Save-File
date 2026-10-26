extends "res://tests/test_case.gd"
## Measures the Square's routes to the Archive (docs/REVIEW_OCT22.md):
## direct crossing, the bench detour, and the lane shortcut, at purge 0/3/5.
## Rue walks with real input (move actions) between waypoints; Arin is held
## at the far west so only the crossing's own threat (the lamp) is measured.
## Not part of the suite; writes route_measure.txt beside the screenshots.

const ROUTES := {
	"direct": [Vector2(600, 182), Vector2(930, 182)],
	"bench": [Vector2(600, 240), Vector2(734, 264), "wait", Vector2(850, 230), Vector2(870, 182), Vector2(930, 182)],
	"shortcut": [Vector2(530, 112), Vector2(530, 88), Vector2(757, 84), Vector2(757, 116), Vector2(870, 170), Vector2(930, 182)],
}


func _steer_to(w: Node, target: Vector2, seconds: float) -> bool:
	var until := Time.get_ticks_msec() + seconds * 1000.0
	while Time.get_ticks_msec() < until and w.area.area_id == "square":
		var d: Vector2 = target - w.player.global_position
		for a in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(a)
		if d.length() < 6.0:
			return true
		if d.x < -2: Input.action_press("move_left")
		if d.x > 2: Input.action_press("move_right")
		if d.y < -2: Input.action_press("move_up")
		if d.y > 2: Input.action_press("move_down")
		await frames(1)
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)
	return w.area.area_id != "square"


func _run(name: String, purge: int, phase := 0.0) -> Array:
	memory().wipe()
	memory().purge = purge
	memory().square_gate_open = name == "shortcut"
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.global_position = Vector2(60, 280)
	w.area.arin.paused = true
	w.player.global_position = Vector2(560, 182)
	w.director.awareness = 0.0
	await frames(5)
	var lamp: OwnerLamp = w.area.lamp
	lamp._t = phase
	var seen := [0.0]
	lamp.sees_player.connect(func(d: float) -> void: seen[0] += d)
	var t0 := Time.get_ticks_msec()
	var a0: float = w.director.awareness
	for step in ROUTES[name]:
		if step is String:
			# Hidden on the bench until the beam is at its far end and turning.
			var until := Time.get_ticks_msec() + 8000
			while Time.get_ticks_msec() < until and not (lamp.is_turning() and lamp.facing() > 1.4):
				w.area.arin.paused = true
				await frames(1)
			continue
		w.area.arin.paused = true
		if await _steer_to(w, step, 12.0) and w.area.area_id != "square":
			break
	var secs := (Time.get_ticks_msec() - t0) / 1000.0
	var reached: bool = w.area.area_id == "archive"
	var aw: float = w.director.awareness - a0
	return [reached, secs, aw, seen[0]]


func _measure(name: String, purge: int) -> void:
	# Across the lamp's whole cycle (it is wherever it is when Rue arrives).
	var cycle := (OwnerLamp.new().sweep_time + OwnerLamp.HOLD) * 2.0
	var times: Array = []
	var gains: Array = []
	var beams: Array = []
	var missed := 0
	for k in 8:
		var r: Array = await _run(name, purge, cycle * k / 8.0)
		if not r[0]:
			missed += 1
		times.append(r[1])
		gains.append(r[2])
		beams.append(r[3])
	var line := "%-9s purge %d: reached %d/8; time %.1f-%.1f s; awareness mean +%.1f, worst +%.1f; beam mean %.2f s, worst %.2f s" % [
		name, purge, 8 - missed, times.min(), times.max(), gains.reduce(func(x, y): return x + y) / 8.0, gains.max(),
		beams.reduce(func(x, y): return x + y) / 8.0, beams.max()]
	print("ROUTE ", line)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			var path := arg.trim_prefix("--screenshots=").path_join("route_measure.txt")
			var f := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
			f.seek_end()
			f.store_line(line)


func test_direct_purge_0() -> void: await _measure("direct", 0)
func test_bench_purge_0() -> void: await _measure("bench", 0)
func test_shortcut_purge_0() -> void: await _measure("shortcut", 0)
func test_direct_purge_3() -> void: await _measure("direct", 3)
func test_bench_purge_3() -> void: await _measure("bench", 3)
func test_shortcut_purge_3() -> void: await _measure("shortcut", 3)
func test_direct_purge_5() -> void: await _measure("direct", 5)
func test_bench_purge_5() -> void: await _measure("bench", 5)
func test_shortcut_purge_5() -> void: await _measure("shortcut", 5)

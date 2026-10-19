extends "res://tests/test_case.gd"
## Frame-time and memory profile of representative heavy scenes, rendered
## (run with a display: xvfb-run ... -- --test-mode --tour --filter=profile).
## Prints a table; asserts nothing. Results in docs/RELEASE_READINESS.md.

var _times: Array[float] = []
var _last := 0


func _on_frame() -> void:
	var now := Time.get_ticks_usec()
	if _last > 0:
		_times.append((now - _last) / 1000.0)
	_last = now


func _sample(label: String, seconds: float) -> void:
	_times.clear()
	_last = 0
	tree.process_frame.connect(_on_frame)
	await wait(seconds)
	tree.process_frame.disconnect(_on_frame)
	var sorted := _times.duplicate()
	sorted.sort()
	var n := sorted.size()
	if n == 0:
		return
	var p := func(q: float) -> float: return sorted[mini(n - 1, int(q * n))]
	var hitches := sorted.filter(func(t: float) -> bool: return t > 33.4).size()
	print("PROFILE | %-34s | frames %4d | p50 %6.2f ms | p95 %6.2f ms | max %6.2f ms | >33 ms %d | nodes %d | objects %d | static %.1f MB" % [
		label, n, p.call(0.5), p.call(0.95), sorted[n - 1], hitches,
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_COUNT),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0])


func test_profile() -> void:
	OS.low_processor_usage_mode_sleep_usec = 0
	var w := await start_session()
	await _sample("room, session start", 3.0)
	await go_to(w, "square", "house")
	await _sample("square, calm (effects: full)", 3.0)
	settings().screen_effects = 0
	await _sample("square, calm (effects: off)", 3.0)
	settings().screen_effects = 2
	w.director.add_awareness(OwnerDirector.HUNT + 1.0 - w.director.awareness)
	w.start_escort(w.area.wren)
	await wait(1.0)
	await _sample("square, HUNT + Wren escort", 4.0)
	await go_to(w, "edge", "south")
	w.area.grace = 0.1  # start the static now; Rue stands on the protected road home
	await wait(1.0)
	await _sample("edge, static spreading", 3.0)
	await go_to(w, "square", "north")
	await go_to(w, "oob", "well")
	await _sample("out of bounds", 3.0)
	# Memory across repeated area changes: nodes and objects should settle.
	for i in 4:
		await go_to(w, "square", "well")
		await go_to(w, "archive", "west")
	await _sample("archive after 8 area changes", 2.0)

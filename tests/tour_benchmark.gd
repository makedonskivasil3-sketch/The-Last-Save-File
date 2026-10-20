extends "res://tests/test_case.gd"
## Hardware benchmark (docs/RELEASE_READINESS.md, "Measuring on a real GPU").
## Launch it with tools/run_benchmark.sh. Every workload is checked before
## and throughout its capture: if Rue dies, the area changes, a threat
## stops, the escort or the visit ends, the static stops spreading or the
## portrait goes, the sample is marked INVALID (kept in the file, never
## mixed into the results).
##
## Groups: gameplay (representative play, a fixed route for Rue), stress
## (the heaviest rendering on purpose), transitions (area changes) and the
## opening film. Environment: BENCH_SECONDS (capture per workload, default
## 60), BENCH_WARMUP (default 5), BENCH_RUNS (repeats, default 3),
## BENCH_OUT (JSON path, default user://benchmark.json), BENCH_ONLY (comma
## list of workload names).
##
## Development-only protection, the one thing it changes: World.bench_immune
## makes Rue impossible to kill, so a pursuit sample is never a death card.
## Everything else runs: Arin patrols, sees and chases; awareness rises; the
## cursor and the static hunt. The test harness's own clean save is used
## (user://test/), never a player's.

var _results: Array = []
var _invalid: Array = []


func _env_f(key: String, fallback: float) -> float:
	return float(OS.get_environment(key)) if OS.get_environment(key) != "" else fallback


func _wanted(label: String) -> bool:
	var only := OS.get_environment("BENCH_ONLY")
	return only == "" or Array(only.split(",")).any(func(o: String) -> bool: return label.contains(o.strip_edges()))


## Captures `label` while `valid` (Callable() -> String: "" when the workload
## is what its label says, else why not) holds every frame. `drive` is
## called every frame (Rue's fixed route).
func _capture(group: String, label: String, valid: Callable, drive := Callable()) -> void:
	var warm := _env_f("BENCH_WARMUP", 5.0)
	var secs := _env_f("BENCH_SECONDS", 60.0)
	var t := 0.0
	while t < warm:
		await tree.process_frame
		t += tree.root.get_process_delta_time()
		if drive.is_valid():
			drive.call(t)
	var why: String = valid.call()
	if why != "":
		_invalid.append({"group": group, "workload": label, "reason": "before capture: " + why})
		print("BENCH | %-34s | INVALID before capture: %s" % [label, why])
		return
	var frames: Array[float] = []
	var cpu: Array[float] = []
	var last := Time.get_ticks_usec()
	t = 0.0
	while t < secs:
		await tree.process_frame
		var now := Time.get_ticks_usec()
		frames.append((now - last) / 1000.0)
		last = now
		cpu.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		t += tree.root.get_process_delta_time()
		if drive.is_valid():
			drive.call(warm + t)
		why = valid.call()
		if why != "":
			_invalid.append({"group": group, "workload": label, "reason": "during capture at %.1f s: %s" % [t, why]})
			print("BENCH | %-34s | INVALID at %.1f s: %s" % [label, t, why])
			return
	_results.append(_summary(group, label, frames, cpu))


func _summary(group: String, label: String, frames: Array[float], cpu: Array[float]) -> Dictionary:
	var s := frames.duplicate()
	s.sort()
	var c := cpu.duplicate()
	c.sort()
	var q := func(a: Array, x: float) -> float: return a[mini(a.size() - 1, int(x * a.size()))]
	var row := {
		"group": group, "workload": label, "samples": s.size(),
		"frame_ms": {"p50": q.call(s, 0.5), "p95": q.call(s, 0.95), "p99": q.call(s, 0.99), "max": s[s.size() - 1]},
		"over_16_7ms": s.filter(func(v: float) -> bool: return v > 16.7).size(),
		"cpu_process_ms": {"p50": q.call(c, 0.5), "p95": q.call(c, 0.95), "p99": q.call(c, 0.99)},
		"static_mem_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"video_mem_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
	}
	print("BENCH | %-34s | n %5d | frame p50 %6.2f p95 %6.2f p99 %6.2f max %6.2f ms | cpu p50 %5.2f ms | draws %d" % [
		label, row.samples, row.frame_ms.p50, row.frame_ms.p95, row.frame_ms.p99, row.frame_ms.max, row.cpu_process_ms.p50, row.draw_calls])
	return row


## Rue's fixed loop in the square (a rectangle on open ground), by position:
## the same path every run.
func _loop(w: Node, center: Vector2, half: Vector2, period := 12.0) -> Callable:
	return func(t: float) -> void:
		var k := fmod(t / period, 1.0) * 4.0
		var corners := [center + Vector2(-half.x, -half.y), center + Vector2(half.x, -half.y), center + half, center + Vector2(-half.x, half.y)]
		var i := int(k)
		w.player.global_position = (corners[i] as Vector2).lerp(corners[(i + 1) % 4], k - i)


func _alive(w: Node, area: String) -> String:
	if not is_instance_valid(w) or not w.is_inside_tree():
		return "the run ended"
	if w.ending != "":
		return "Rue died or the run ended (%s)" % w.ending
	if w.area.area_id != area:
		return "left %s for %s" % [area, w.area.area_id]
	return ""


func _gameplay() -> void:
	var w := await start_session()
	w.bench_immune = true
	w.director.paused = true
	if _wanted("room"):
		await _capture("gameplay", "room, exploring", func() -> String: return _alive(w, "room"), _loop(w, Vector2(320, 210), Vector2(60, 30)))
	await go_to(w, "square", "house")
	if _wanted("square, calm"):
		await _capture("gameplay", "square, calm", func() -> String: return _alive(w, "square"), _loop(w, Vector2(320, 260), Vector2(90, 20)))
	if _wanted("square, hunted"):
		w.director.paused = false
		w.director.add_awareness(OwnerDirector.HUNT + 1.0 - w.director.awareness)
		w.start_escort(w.area.wren)
		var arin: OwnerAvatar = w.area.arin
		await _capture("gameplay", "square, hunted, Wren escort", func() -> String:
			var why := _alive(w, "square")
			if why != "":
				return why
			if w.escort == null or not is_instance_valid(w.escort):
				return "the escort is gone"
			if arin.paused or arin.stunned > 0.0:
				return "Arin isn't running"
			if w.director.awareness < OwnerDirector.HUNT:
				return "the hunt ended"
			return "", _loop(w, Vector2(320, 260), Vector2(90, 20)))
		w.director.paused = true
	await go_to(w, "archive", "east")
	if _wanted("archive, dialogue"):
		await interact_with(w, w.area.archivist)
		await _capture("gameplay", "archive, dialogue portrait", func() -> String:
			var why := _alive(w, "archive")
			if why != "":
				return why
			if not w.hud.is_dialogue_open():
				return "the conversation closed"
			if not (w.hud._dialogue_portrait and w.hud._dialogue_portrait.is_visible_in_tree()):
				return "no portrait on screen"
			return "")
		w.hud.close_dialogue()
	await go_to(w, "square", "east")
	await go_to(w, "house", "front")
	if _wanted("house"):
		w.area.next_visit = 0.05
		await wait(0.3)
		w.area._visit_left = 9999.0  # the visit lasts the whole capture (the one change: its length)
		await _capture("gameplay", "house, Arin visiting", func() -> String:
			var why := _alive(w, "house")
			if why != "":
				return why
			return "" if w.area.arin != null else "no visit under way", _loop(w, Vector2(250, 240), Vector2(40, 12)))
	await go_to(w, "square", "house")
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	if _wanted("edge"):
		await wait_until(func() -> bool: return not w.hud.is_act_shown(), 8.0, "the act card")
		w.director.paused = false
		w.area.grace = 0.05
		await wait(0.5)
		await _capture("gameplay", "edge, static spreading", func() -> String:
			var why := _alive(w, "edge")
			if why != "":
				return why
			return "" if w.area.erasure.active else "the static isn't spreading")


func _stress() -> void:
	if not _wanted("stress"):
		return
	var w := await start_session()
	w.bench_immune = true
	await go_to(w, "square", "house")
	settings().crt_screen = true
	settings().screen_effects = 2
	settings().apply()
	w.director.add_awareness(OwnerDirector.HUNT + 1.0 - w.director.awareness)
	await _capture("stress", "stress: square, hunted, CRT, full effects", func() -> String: return _alive(w, "square"), _loop(w, Vector2(320, 260), Vector2(90, 20)))
	settings().crt_screen = false
	settings().apply()


func _transitions() -> void:
	if not _wanted("transition"):
		return
	var w := await start_session()
	w.director.paused = true
	var times: Array[float] = []
	for i in int(_env_f("BENCH_TRANSITIONS", 12.0)):
		var t := Time.get_ticks_usec()
		await go_to(w, "square" if i % 2 == 0 else "archive", "house" if i % 2 == 0 else "west")
		times.append((Time.get_ticks_usec() - t) / 1000.0)
	_results.append(_summary("transitions", "area change (go_to, wall clock)", times, times))


func _opening() -> void:
	if not _wanted("opening"):
		return
	var film := Opening.new()
	film.replay = true
	var old := tree.current_scene
	tree.root.add_child(film)
	tree.current_scene = film
	if old:
		old.queue_free()
	await _capture("opening", "opening film", func() -> String: return "" if is_instance_valid(film) and film.is_inside_tree() else "the film ended")


func test_benchmark() -> void:
	OS.low_processor_usage_mode_sleep_usec = 0
	for run in int(_env_f("BENCH_RUNS", 3.0)):
		print("BENCH run %d" % (run + 1))
		await _gameplay()
		await _stress()
		await _transitions()
		await _opening()
	_write()


func _write() -> void:
	var gpu := RenderingServer.get_video_adapter_name()
	var software := ["llvmpipe", "softpipe", "swiftshader", "lavapipe", "microsoft basic render"].any(func(n: String) -> bool: return gpu.to_lower().contains(n))
	var commit := OS.get_environment("BENCH_COMMIT")
	if commit == "":
		var out := []
		if OS.execute("git", ["rev-parse", "--short", "HEAD"], out) == 0 and not out.is_empty():
			commit = str(out[0]).strip_edges()
	var info := {
		"commit": commit, "godot": Engine.get_version_info().string, "debug_build": OS.is_debug_build(),
		"os": OS.get_name() + " " + OS.get_version(), "cpu": OS.get_processor_name(), "cpu_threads": OS.get_processor_count(),
		"gpu": gpu, "gpu_vendor": RenderingServer.get_video_adapter_vendor(), "driver": RenderingServer.get_video_adapter_api_version(),
		"software_renderer": software,
		"renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"window": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"render_resolution": [tree.root.get_visible_rect().size.x, tree.root.get_visible_rect().size.y],
		"vsync": DisplayServer.window_get_vsync_mode(), "max_fps": Engine.max_fps,
		"effects": {"screen_effects": Settings.screen_effects, "crt_screen": Settings.crt_screen, "glitch_intensity": Settings.glitch_intensity},
		"warmup_s": _env_f("BENCH_WARMUP", 5.0), "capture_s": _env_f("BENCH_SECONDS", 60.0), "runs": int(_env_f("BENCH_RUNS", 3.0)),
		"gpu_timing": "not measured (frame time is wall clock; CPU process time is Godot's monitor)",
		"results": _results, "invalid": _invalid,
	}
	var path := OS.get_environment("BENCH_OUT") if OS.get_environment("BENCH_OUT") != "" else "user://benchmark.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	check(f != null, "results file written")
	if f:
		f.store_string(JSON.stringify(info, "  "))
		print("BENCH results: ", ProjectSettings.globalize_path(path))
	print("BENCH machine: %s | %s (%s)%s | %s | %s" % [info.os, gpu, info.driver, " [SOFTWARE RENDERER: not a hardware GPU]" if software else "", info.cpu, info.renderer])
	check(_invalid.is_empty(), "every workload stayed what its label says (%d invalid)" % _invalid.size())

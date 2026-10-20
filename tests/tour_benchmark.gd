extends "res://tests/test_case.gd"
## Real-hardware benchmark (docs/RELEASE_READINESS.md, "Measuring on a real
## GPU"). A fixed route through the representative workloads, a warm-up
## before each, then BENCH_SECONDS of frames (default 60). Writes the
## machine, renderer and settings with p50/p95/p99/max frame time, CPU
## process time and memory per workload to BENCH_OUT (default
## user://benchmark.json) and prints a table.
##
##   BENCH_SECONDS=60 BENCH_OUT=/tmp/bench.json $GODOT --path . -s res://tests/run_tests.gd \
##       -- --test-mode --tour --filter=tour_benchmark
##
## Run it on the machine being measured, with a window (not --headless) and
## nothing else heavy running. Frame time here is wall-clock between frames:
## it includes GPU time only as far as the frame waits for it (VSync off
## gives the clearest number). CPU process time is Godot's own monitor.

var _times: Array[float] = []
var _last := 0
var _results: Array = []


func _on_frame() -> void:
	var now := Time.get_ticks_usec()
	if _last > 0:
		_times.append((now - _last) / 1000.0)
	_last = now


func _seconds() -> float:
	return float(OS.get_environment("BENCH_SECONDS")) if OS.get_environment("BENCH_SECONDS") != "" else 60.0


func _workload(label: String) -> void:
	await wait(3.0)  # warm-up: first-use allocations, shader compiles
	_times.clear()
	_last = 0
	var cpu: Array[float] = []
	tree.process_frame.connect(_on_frame)
	var t := 0.0
	while t < _seconds():
		await tree.process_frame
		t += tree.root.get_process_delta_time()
		cpu.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	tree.process_frame.disconnect(_on_frame)
	var s := _times.duplicate()
	s.sort()
	cpu.sort()
	var n := s.size()
	if n == 0:
		return
	var q := func(a: Array, x: float) -> float: return a[mini(a.size() - 1, int(x * a.size()))]
	var row := {
		"workload": label, "frames": n,
		"p50_ms": q.call(s, 0.5), "p95_ms": q.call(s, 0.95), "p99_ms": q.call(s, 0.99), "max_ms": s[n - 1],
		"over_16_7ms": s.filter(func(v: float) -> bool: return v > 16.7).size(),
		"cpu_process_p50_ms": q.call(cpu, 0.5), "cpu_process_p95_ms": q.call(cpu, 0.95),
		"static_mem_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"video_mem_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
	}
	_results.append(row)
	print("BENCH | %-30s | p50 %6.2f | p95 %6.2f | p99 %6.2f | max %6.2f ms | >16.7 ms %d/%d | cpu p50 %5.2f ms | draws %d | static %.1f MB" % [
		label, row.p50_ms, row.p95_ms, row.p99_ms, row.max_ms, row.over_16_7ms, n, row.cpu_process_p50_ms, row.draw_calls, row.static_mem_mb])


func test_benchmark() -> void:
	OS.low_processor_usage_mode_sleep_usec = 0
	var w := await start_session()
	w.director.paused = true
	await _workload("room")
	await go_to(w, "square", "house")
	await _workload("square, calm")
	w.director.paused = false
	w.director.add_awareness(OwnerDirector.HUNT + 1.0 - w.director.awareness)
	w.start_escort(w.area.wren)
	await _workload("square, hunted, Wren escort")
	w.director.paused = true
	await go_to(w, "archive", "east")
	await _workload("archive")
	w.hud.show_dialogue("THE ARCHIVIST", Color("8cf2ff"), ["A portrait, held open for the benchmark."], "", null)
	await _workload("archive, dialogue portrait")
	w.hud.close_dialogue()
	await go_to(w, "square", "well")
	await go_to(w, "house", "front")
	w.area.next_visit = 0.1
	await _workload("house, Arin visiting")
	await go_to(w, "square", "house")
	await go_to(w, "edge", "south")
	w.area.grace = 0.1
	await _workload("edge, static spreading")
	var info := {
		"os": OS.get_name() + " " + OS.get_version(),
		"cpu": OS.get_processor_name(), "cpu_count": OS.get_processor_count(),
		"gpu": RenderingServer.get_video_adapter_name(), "gpu_vendor": RenderingServer.get_video_adapter_vendor(),
		"driver": RenderingServer.get_video_adapter_api_version(),
		"renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"window": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"vsync": DisplayServer.window_get_vsync_mode(), "max_fps": Engine.max_fps,
		"effects": Settings.screen_effects, "build_debug": OS.is_debug_build(),
		"godot": Engine.get_version_info().string,
		"commit_note": "record `git rev-parse --short HEAD` with these results",
		"workloads": _results,
	}
	var out := OS.get_environment("BENCH_OUT") if OS.get_environment("BENCH_OUT") != "" else "user://benchmark.json"
	var f := FileAccess.open(out, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(info, "  "))
		print("BENCH results written to ", ProjectSettings.globalize_path(out))
	print("BENCH machine: %s | %s (%s) | %s | %s" % [info.os, info.gpu, info.driver, info.cpu, info.renderer])

extends SceneTree
## Worst frames while the title starts (the first 3 s): where synthesis on
## the main thread shows up as hitches.
##   godot --path . -s res://tools/title_startup.gd -- --test-mode
var _times: Array[float] = []
var _last := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await process_frame
	root.get_node("OwnerMemory").runtime_cache.clear()
	process_frame.connect(func() -> void:
		var now := Time.get_ticks_usec()
		if _last > 0:
			_times.append((now - _last) / 1000.0)
		_last = now)
	change_scene_to_file("res://scenes/title.tscn")
	await create_timer(3.0).timeout
	var s := _times.duplicate()
	s.sort()
	print("STARTUP title first 3 s: frames %d · worst %s ms · p50 %.1f ms" % [s.size(), str(s.slice(-5).map(func(x: float) -> int: return int(x))), s[s.size() / 2]])
	quit()

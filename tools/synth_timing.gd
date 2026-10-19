extends SceneTree
## How long each generated sound takes to build, on this machine:
##   godot --headless --path . -s res://tools/synth_timing.gd -- --test-mode
## Sfx builds sounds a few per frame within BUILD_BUDGET, but one sound is
## one indivisible job: anything longer than a frame (16.7 ms) is a hitch
## if it's built during play.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var sfx: Node = root.get_node("Sfx")
	var rows: Array = []
	for name in sfx.PREWARM:
		var t := Time.get_ticks_usec()
		sfx._build(name)
		rows.append([name, (Time.get_ticks_usec() - t) / 1000.0])
	var mb = load("res://scripts/audio/music_box.gd")
	for level in 6:
		for variant in ["normal", "invert"]:
			var t := Time.get_ticks_usec()
			mb.render(level, variant)
			rows.append(["theme_%d_%s (whole)" % [level, variant], (Time.get_ticks_usec() - t) / 1000.0])
	var drone = load("res://scripts/fx/drone.gd")
	for f in ["_build_hum", "_build_dread", "_build_shimmer", "_build_crackle"]:
		var t := Time.get_ticks_usec()
		drone.call(f)
		rows.append(["drone" + f.trim_prefix("_build"), (Time.get_ticks_usec() - t) / 1000.0])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	var total := 0.0
	for r in rows:
		total += r[1]
	print("TIMING %d sounds, %.0f ms in all · %s" % [rows.size(), total, OS.get_processor_name()])
	for r in rows.slice(0, 15):
		print("TIMING %-28s %7.2f ms" % [r[0], r[1]])
	quit()

extends SceneTree
## Bakes the drone layers that are deterministic (same samples every build),
## and every music-box theme, into res://audio/baked/, so the game loads them instead of synthesising
## them on the title (the hum took ~80 ms on one frame, the dread ~65 ms;
## several times that on the threadless web build).
##   godot --headless --path . -s res://tools/bake_audio.gd -- --test-mode
## tests/test_baked_audio.gd fails if a baked file no longer matches the code.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute("res://audio/baked")
	var drone = load("res://scripts/fx/drone.gd")  # after the autoloads exist
	for key in drone.BAKED:
		var wav: AudioStreamWAV = drone.build(key)
		var path: String = drone.baked_path(key)
		var err := ResourceSaver.save(wav, path)
		print("BAKED %s -> %s (%d bytes, err %d)" % [key, path, wav.data.size(), err])
	var mb = load("res://scripts/audio/music_box.gd")
	for level in mb.MAX_LEVEL + 1:
		for variant in mb.VARIANTS:
			var wav: AudioStreamWAV = mb.build(level, variant)
			var path: String = mb.baked_path(level, variant)
			var err := ResourceSaver.save(wav, path)
			print("BAKED theme %d %s -> %s (%d bytes, err %d)" % [level, variant, path, wav.data.size(), err])
	quit()

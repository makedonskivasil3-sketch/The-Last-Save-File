extends "res://tests/test_case.gd"
## Baked drone layers (tools/bake_audio.gd) must be exactly what the code
## builds: change a layer's synthesis and this fails until it's re-baked.


func test_baked_layers_match_the_code() -> void:
	for key in Drone.BAKED:
		var path := Drone.baked_path(key)
		check(ResourceLoader.exists(path), "%s is baked" % key)
		var baked: AudioStreamWAV = load(path)
		var fresh: AudioStreamWAV = Drone.build(key)
		check(baked.data == fresh.data and baked.mix_rate == fresh.mix_rate and baked.loop_mode == fresh.loop_mode,
			"%s matches the code (re-run tools/bake_audio.gd if not)" % key)


func test_loading_is_far_cheaper_than_building() -> void:
	var t := Time.get_ticks_usec()
	var _w: AudioStreamWAV = ResourceLoader.load(Drone.baked_path("hum"), "", ResourceLoader.CACHE_MODE_IGNORE)
	var load_ms := (Time.get_ticks_usec() - t) / 1000.0
	t = Time.get_ticks_usec()
	Drone.build("hum")
	var build_ms := (Time.get_ticks_usec() - t) / 1000.0
	print("BAKED hum: load %.1f ms vs build %.1f ms" % [load_ms, build_ms])
	check(load_ms * 5.0 < build_ms, "loading the hum (%.1f ms) is much cheaper than building it (%.1f ms)" % [load_ms, build_ms])

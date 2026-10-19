extends SceneTree
## Measures what the game actually sends to the output, not just whether
## something called play(): an AudioEffectCapture on the Master bus records
## the final mix while the title, the first room and a memory play.
##
##   godot --headless --path . -s res://tools/audio_probe.gd -- --test-mode
##
## Headless Godot mixes through its dummy driver, so this measures the native
## (Stream) mixer: level, silent share, clipping and the low/mid balance.
## It says nothing about the web's Sample playback (tests/web/
## audio_output_check.cjs) or about what a person hears.

var _cap: AudioEffectCapture


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var om: Node = root.get_node("OwnerMemory")
	om.wipe()  # the test-mode save only (user://test_owner_memory.json)
	_cap = AudioEffectCapture.new()
	_cap.buffer_length = 2.0
	AudioServer.add_bus_effect(0, _cap)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--dump="):
			_dump_dir = a.trim_prefix("--dump=")
	print("PROBE buses: ", _buses(), " · mix rate ", AudioServer.get_mix_rate())
	change_scene_to_file("res://scenes/title.tscn")
	await _settle(1.5)
	_open_dump("title")
	_report("title", await _listen(6.0))
	var music: AudioStreamPlayer = current_scene.get("_music")
	print("PROBE title theme: playing %s · stream %s · cached %s · jobs %s · queue %d" % [music.playing if music else "?",
		music.stream if music else "?", root.get_node("OwnerMemory").runtime_cache.keys(), root.get_node("Sfx")._jobs.keys(), root.get_node("Sfx")._queue.size()])
	await _per_bus("title")
	om.sessions = 1  # skip the boot log
	change_scene_to_file("res://scenes/main.tscn")
	await _settle(2.0)
	_open_dump("first room")
	_report("first room", await _listen(8.0))
	await _per_bus("first room")
	var amb: Node = current_scene.get("_ambience")
	var mt: AudioStreamPlayer = amb.get("_memory_theme") if amb else null
	print("PROBE room theme: %s" % ("none" if mt == null else "playing %s at %.1f dB" % [mt.playing, mt.volume_db]))
	var w: Node = current_scene
	for m in w.area.get_children():
		if m is MemoryFragment:
			w.recover_fragment(m)
			break
	await _settle(0.5)
	_open_dump("first memory")
	_report("first memory", await _listen(6.0))
	await om.prepare_quit()
	quit()


## Each bus alone (solo), to see what the level and the low end come from.
func _per_bus(label: String) -> void:
	for i in range(1, AudioServer.bus_count):
		AudioServer.set_bus_solo(i, true)
		await _settle(0.3)
		_open_dump("%s/%s" % [label, AudioServer.get_bus_name(i)])
		_report("%s/%s" % [label, AudioServer.get_bus_name(i)], await _listen(3.0))
		AudioServer.set_bus_solo(i, false)


func _buses() -> String:
	var out: Array = []
	for i in AudioServer.bus_count:
		out.append("%s(%.1f dB%s -> %s)" % [AudioServer.get_bus_name(i), AudioServer.get_bus_volume_db(i),
			", muted" if AudioServer.is_bus_mute(i) else "", AudioServer.get_bus_send(i)])
	return ", ".join(out)


func _settle(seconds: float) -> void:
	await create_timer(seconds).timeout
	_cap.clear_buffer()


## Set by --dump=DIR: each listen also writes its mono capture as raw
## float32 (DIR/<label>.f32) for spectral analysis outside Godot.
var _dump: FileAccess
var _dump_dir := ""


func _listen(seconds: float) -> Dictionary:
	var sum_sq := 0.0
	var n := 0
	var peak := 0.0
	var clipped := 0
	var windows := 0
	var loud := 0
	# One-pole splits: below ~200 Hz, and a 300 Hz - 4 kHz band.
	var lp := 0.0
	var hp_lp := 0.0
	var band_lp := 0.0
	var low_e := 0.0
	var mid_e := 0.0
	var rate := AudioServer.get_mix_rate()
	var a_low := 1.0 - exp(-TAU * 200.0 / rate)
	var a_300 := 1.0 - exp(-TAU * 300.0 / rate)
	var a_4k := 1.0 - exp(-TAU * 4000.0 / rate)
	var t := 0.0
	while t < seconds:
		await process_frame
		t += root.get_process_delta_time()
		var frames := _cap.get_frames_available()
		if frames <= 0:
			continue
		var buf := _cap.get_buffer(frames)
		if _dump:
			for f in buf:
				_dump.store_float((f.x + f.y) * 0.5)
		var w_sq := 0.0
		for f in buf:
			var s := (f.x + f.y) * 0.5  # mono: what a phone speaker plays
			w_sq += s * s
			peak = maxf(peak, maxf(absf(f.x), absf(f.y)))
			if absf(f.x) >= 0.999 or absf(f.y) >= 0.999:
				clipped += 1
			lp += a_low * (s - lp)
			low_e += lp * lp
			hp_lp += a_300 * (s - hp_lp)
			var hp := s - hp_lp
			band_lp += a_4k * (hp - band_lp)
			mid_e += band_lp * band_lp
		sum_sq += w_sq
		n += buf.size()
		windows += 1
		if sqrt(w_sq / buf.size()) > 0.001:
			loud += 1
	return {"rms": sqrt(sum_sq / maxf(n, 1)), "peak": peak, "clipped": clipped,
		"audible_share": 100.0 * loud / maxf(windows, 1), "low": low_e, "mid": mid_e, "frames": n}


func _open_dump(label: String) -> void:
	_dump = FileAccess.open(_dump_dir.path_join(label.replace("/", "_").replace(" ", "_") + ".f32"), FileAccess.WRITE) if _dump_dir != "" else null


func _report(label: String, r: Dictionary) -> void:
	var db := func(x: float) -> String: return "%.1f" % (20.0 * log(x) / log(10.0)) if x > 0.0 else "-inf"
	var tilt := "n/a"
	if r.low > 0.0 and r.mid > 0.0:
		tilt = "%.1f dB" % (10.0 * log(r.mid / r.low) / log(10.0))
	print("PROBE %-13s rms %s dBFS | peak %s dBFS | audible %d%% | clipped %d | mid vs low %s | %d frames" % [
		label, db.call(r.rms), db.call(r.peak), int(r.audible_share), r.clipped, tilt, r.frames])

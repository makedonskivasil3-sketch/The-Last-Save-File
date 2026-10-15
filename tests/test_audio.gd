extends "res://tests/test_case.gd"
## Sound design: every sound renders, isn't silent, renders fast; buses and
## settings are wired; accessibility settings tame the harsh sounds.

## No single sound may take long to render (they're built lazily, so a slow
## one would hitch). Locally the slowest is ~70 ms; the margin is for slow CI.
const MAX_BUILD_MS := 250.0


func test_every_sound_renders() -> void:
	var sfx := tree.root.get_node("Sfx")
	var names: Array = sfx.PREWARM.duplicate()
	for id in ["mira", "wren", "tobben", "someone"]:
		names.append("deletion_" + id)
	var total := 0.0
	for n in names:
		sfx._cache.erase(n)
		var t0 := Time.get_ticks_usec()
		var s: AudioStreamWAV = sfx.stream(n)
		var ms := (Time.get_ticks_usec() - t0) / 1000.0
		total += ms
		check(s != null and s.data.size() > 0, "%s rendered" % n)
		check(_peak(s) > 0.05, "%s is audible" % n)
		check(ms < MAX_BUILD_MS, "%s built in %.1f ms (max %.0f)" % [n, ms, MAX_BUILD_MS])
		if OS.get_cmdline_user_args().has("--verbose-audio"):
			print("        %-20s %6.1f ms" % [n, ms])
	print("        all sounds built in %.0f ms" % total)


func test_loops_are_loops() -> void:
	var sfx := tree.root.get_node("Sfx")
	for n in ["select_loop", "memory_loop"]:
		check_eq(sfx.stream(n).loop_mode, AudioStreamWAV.LOOP_FORWARD, "%s loops" % n)


func test_buses_exist_and_follow_settings() -> void:
	for bus in ["Music", "Memory", "SFX", "UI"]:
		check(AudioServer.get_bus_index(bus) != -1, "%s bus exists" % bus)
	settings().set_value("music_volume", 0.0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "music slider at 0 mutes Music")
	settings().set_value("music_volume", 0.8)
	settings().set_value("sfx_volume", 0.5)
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")) - linear_to_db(0.5)) < 0.01, "effects slider drives SFX")
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("UI")) - linear_to_db(0.5)) < 0.01, "effects slider drives UI")
	settings().set_value("sfx_volume", 0.9)


func test_accessibility_softens_harsh_sounds() -> void:
	var sfx := tree.root.get_node("Sfx")
	var full: float = sfx.harshness()
	settings().reduce_flashing = true
	check(sfx.harshness() <= full * 0.5 + 0.001, "reduce flashing halves harsh sounds")
	settings().reduce_flashing = false
	settings().glitch_intensity = 0.0
	check(sfx.harshness() < full, "low glitch intensity softens them")


func test_muffle_toggles_lowpass() -> void:
	var sfx := tree.root.get_node("Sfx")
	var i := AudioServer.get_bus_index("SFX")
	sfx.muffle(true)
	check(AudioServer.is_bus_effect_enabled(i, 1), "pause muffles the world")
	sfx.muffle(false)
	check(not AudioServer.is_bus_effect_enabled(i, 1), "and un-muffles")


func test_drone_layers_build_and_follow_tension() -> void:
	var w := await start_session()
	await frames(6)  # layers build one per frame
	w.director.stop()  # otherwise the owner keeps setting tension itself
	var d: Drone = w.drone
	check(d._layers.has("dread") and d._layers.has("shimmer"), "drone layers built")
	d.tension = 0.0
	await wait(0.6)
	var calm: float = d._layers["dread"].volume_db
	d.tension = 0.9
	await wait(1.5)
	check(d._layers["dread"].volume_db > calm + 10.0, "dread layer swells with awareness")


func _peak(s: AudioStreamWAV) -> float:
	var m := 0
	for i in range(0, s.data.size() - 1, 2):
		m = maxi(m, absi(s.data.decode_s16(i)))
	return m / 32767.0


## The gameplay hooks: each key event asks Sfx for its sound.
func test_gameplay_events_make_sounds() -> void:
	var sfx := tree.root.get_node("Sfx")
	var w := await start_session(true, true)
	w.player.global_position = Vector2(320, 100)
	await wait(0.3)
	check("door_lock" in sfx.history, "the door locks audibly")
	check("stinger" in sfx.history, "awareness thresholds play a stinger")
	sfx.history.clear()
	await go_to(w, "square", "house")
	check("transition" in sfx.history, "area changes play a transition")
	w.area.wren.delete()
	check("deletion_wren" in sfx.history, "deleting Wren plays her own deletion sound")
	w.director.add_awareness(OwnerDirector.HUNT + 1.0)
	await wait(0.5)
	check("erase_start" in sfx.history, "the eraser announces itself")
	check("cursor_arrive" in sfx.history, "the cursor arrives with a sound")
	check(sfx.history.any(func(n: String) -> bool: return n.begins_with("erase_cell")), "cells crackle into void")
	w.kill("overwritten")
	check("death_overwritten" in sfx.history, "each death has its own sound")


func test_the_theme_grows_with_memories() -> void:
	check_eq(MusicBox.notes_at(0), 2, "with no memories, the theme is two notes")
	for level in range(1, MusicBox.MAX_LEVEL + 1):
		check(MusicBox.notes_at(level) > MusicBox.notes_at(level - 1), "memory %d adds to the theme" % level)
	check(MusicBox.stream(5).data != MusicBox.stream(4).data, "the last memory changes how it ends")
	var fwd := MusicBox.stream(5)
	var back := MusicBox.stream(5, "reverse")
	check_eq(back.data.decode_s16(0), fwd.data.decode_s16(fwd.data.size() - 2), "the Edge plays it backwards")
	check(MusicBox.stream(5, "invert").data.size() > 0, "out of bounds plays it upside down")


func test_area_beds() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	check(w._ambience != null and w._ambience.area_id == "square", "the square has its own sound bed")
	var full_life: float = w._ambience.village_life()
	memory().npc_fates["wren"] = "deleted"
	check(w._ambience.village_life() < full_life, "the village thins as characters are deleted")
	await go_to(w, "archive", "west")
	check_eq(w._ambience.area_id, "archive", "and the archive hums")


func test_positional_sound_and_the_owner_voice() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	check(w.area.arin._steps is AudioStreamPlayer2D, "Arin's footsteps are positional")
	var sfx := tree.root.get_node("Sfx")
	sfx.history.clear()
	w.hud.clear_queue()
	w.director.say("hello there, little bug")
	var spoke := false
	for i in 80:
		await frames(1)
		if "owner_voice" in sfx.history:
			spoke = true
			break
	check(spoke, "the owner's lines are spoken in blips")

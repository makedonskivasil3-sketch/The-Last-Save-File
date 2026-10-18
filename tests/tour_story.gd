extends "res://tests/tour_visual.gd"
## The story-presentation tour: dialogue, memories with Rue's portrait, a
## danger warning, the History page and large text with effects reduced.
## Staged moments (the run's state is set directly), not a playthrough.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" $GODOT --path . -s res://tests/run_tests.gd \
##       -- --test-mode --tour --filter=tour_story --screenshots=/some/dir


func _scene(hud: Hud, title: String, lines: Array, portrait: CharacterArt.Portrait) -> void:
	await hud.cinematic(title, lines, Hud.SELF_COLOR, 0.5, "", portrait)


func _reveal(w: Node) -> void:
	await wait(0.6)
	await press("interact")  # the whole line: the continue marker shows
	await wait(0.4)


func test_tour_story() -> void:
	var w := await start_session()
	_calm(w)
	# Dialogue: Mira, a whole line shown, waiting for the player.
	await interact_with(w, w.area.mira)
	await press("interact")
	await wait(0.3)
	await _measure("60_dialogue_mira", 10)
	await finish_dialogue(w)
	# A memory with no memories back yet: Rue's face is still missing.
	var f := Story.fragment("controller")
	_scene.call_deferred(w.hud, f.title, f.lines, CharacterArt.rue("remembering", w.player.palette()))
	await _reveal(w)
	await _measure("61_memory_rue_missing", 10)
	await read_through_cinematic(w)
	# Rue fully restored, relieved (the epilogue's look).
	_scene.call_deferred(w.hud, "EPILOGUE", ["you wrote yourself into the last save file."], CharacterArt.rue("relieved"))
	await _reveal(w)
	await _measure("62_epilogue_rue_restored", 10)
	await read_through_cinematic(w)
	# A danger warning: the owner loading the autosave.
	w.director.paused = false
	w.debug("load")
	await wait(0.5)
	await _measure("63_danger_reload_banner", 10)
	await wait(4.0)
	# The History page.
	w._pause_menu.open()
	w._pause_menu._show_history()
	await wait(0.3)
	await _measure("64_history", 5)
	w._pause_menu.close()


func test_tour_story_accessible() -> void:
	var s := settings()
	s.set_value("large_text", true)
	s.set_value("subtitle_size", 2)
	s.set_value("screen_effects", 0)
	s.set_value("reduce_flashing", true)
	var w := await start_session()
	_calm(w)
	await interact_with(w, w.area.mira)
	await press("interact")
	await wait(0.3)
	await _measure("65_dialogue_large_text_effects_off", 10)
	await finish_dialogue(w)
	var f := Story.fragment("controller")
	_scene.call_deferred(w.hud, f.title, f.lines, CharacterArt.rue("remembering", w.player.palette()))
	await _reveal(w)
	await _measure("66_memory_large_text_effects_off", 10)
	await read_through_cinematic(w)
	w._pause_menu.open()
	w._pause_menu._show_settings()
	await wait(0.3)
	await _measure("67_settings_large_text", 5)
	w._pause_menu.close()
	for k in [["large_text", false], ["subtitle_size", 0], ["screen_effects", 2], ["reduce_flashing", false]]:
		s.set_value(k[0], k[1])


func test_tour_rue_sheet() -> void:
	# The reference sheet for docs/CHARACTER_ART.md, from the game's own code.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			var dir := arg.trim_prefix("--screenshots=")
			CharacterArt.sheet("rue", Player.RUE).save_png(dir.path_join("rue_expressions_restored.png"))
			CharacterArt.sheet("rue", Player.MISSING).save_png(dir.path_join("rue_expressions_missing.png"))
			var partly := Player.MISSING.duplicate()
			for keys in Player.RESTORE_ORDER.slice(0, 3):
				for k in keys:
					partly[k] = Player.RUE[k]
			CharacterArt.sheet("rue", partly).save_png(dir.path_join("rue_expressions_three_memories.png"))

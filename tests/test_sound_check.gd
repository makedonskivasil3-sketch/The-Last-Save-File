extends "res://tests/test_case.gd"
## Settings > Sound check (docs/AUDIO_DIAGNOSIS.md): it plays, it says
## truthfully what stops sound, it restores only the sound settings, and it
## never touches the run or the save.


func _panel() -> Node:
	var p := SettingsPanel.new()
	tree.root.add_child(p)
	await frames(2)
	return p


func test_it_plays_each_kind_of_sound() -> void:
	var panel := await _panel()
	var check: Node = panel.find_child("SoundCheck", true, false)
	check(check != null, "Settings has a sound check")
	Sfx.history.clear()
	check._test_effect()
	check("pop" in Sfx.history, "an effect plays")
	check._test_music()
	check(check._music.playing and check._music.bus == &"Music", "the music box plays on the Music bus")
	check._test_voice()
	await wait(0.4)
	check(check.status_text().contains("Procedural voice"), "the voice sample says what it is (%s)" % check.status_text())
	panel.queue_free()


func test_a_zero_volume_is_named_not_raised() -> void:
	settings().music_volume = 0.0
	settings().apply()
	var panel := await _panel()
	var check: Node = panel.find_child("SoundCheck", true, false)
	check._test_music()
	check(check.status_text().contains("Music is at 0"), "it says why nothing will play (%s)" % check.status_text())
	check_eq(settings().music_volume, 0.0, "and leaves the volume alone")
	panel.queue_free()


func test_restoring_defaults_touches_only_sound() -> void:
	memory().sessions = 3
	memory().purge = 2
	memory().fragments.append("well")
	memory().save_memory()
	settings().volume = 0.1
	settings().music_volume = 0.0
	settings().large_text = true
	settings().narration = true
	var panel := await _panel()
	var check: Node = panel.find_child("SoundCheck", true, false)
	check._restore_defaults()
	check_eq(settings().volume, 0.8, "Master back to its default")
	check_eq(settings().music_volume, 0.8, "Music too")
	check(settings().large_text and settings().narration, "other settings untouched")
	memory().load_memory()
	check(memory().sessions == 3 and memory().purge == 2 and memory().has_fragment("well"), "the story untouched")
	panel.queue_free()


func test_it_works_from_the_pause_menu() -> void:
	var w := await start_session()
	var purge: int = memory().purge
	tree.paused = true
	var panel := await _panel()
	var check: Node = panel.find_child("SoundCheck", true, false)
	check._test_music()
	await wait(0.5)
	check(check._music.playing, "the music box plays while the game is paused")
	tree.paused = false
	panel.queue_free()
	check_eq(memory().purge, purge, "and the run is untouched")
	check_eq(w.ending, "", "still playing")


func test_narration_looks_for_voices_again() -> void:
	# The voice list used to be read once and cached, empty, for good.
	var src := FileAccess.get_file_as_string("res://scripts/audio/narration.gd")
	check(not src.contains("_voices_checked"), "no permanent 'already checked' flag")
	check(src.contains("supported = available()"), "speak() asks again if no voice was found yet")

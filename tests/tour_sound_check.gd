extends "res://tests/test_case.gd"
## Screenshot of Settings with the sound check, on the title (tour mode).


func test_settings_sound_check() -> void:
	tree.change_scene_to_file("res://scenes/title.tscn")
	await wait(1.0)
	scene()._show_settings()
	await wait(0.5)
	var check: Node = scene().find_child("SoundCheck", true, false)
	check._test_music()
	await wait(1.5)
	await shot("settings_sound_check")

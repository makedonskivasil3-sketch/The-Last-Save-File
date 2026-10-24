extends "res://tests/test_case.gd"
## The first 90 s from a fresh profile, as captured evidence (docs/
## INTRO_REBUILD.md): every frame the renderer manages, named with its time
## (ms), on the watched (no input) path, and on a prompt path (the festival
## played at once: autoplay stands in for a player who acts as soon as asked).
## Run with --tour --filter=tour_intro_capture --screenshots=<dir>.

func _capture(prefix: String, prompt: bool) -> void:
	settings().opening_seen = false
	tree.change_scene_to_file(TITLE_SCENE)
	await frames(5)
	scene()._start()
	var t0 := Time.get_ticks_msec()
	var i := 0
	while Time.get_ticks_msec() - t0 < 90000:
		var s := scene()
		if prompt and s is Prologue:
			s.autoplay = true
		await shot("%s_%04d_%06d" % [prefix, i, Time.get_ticks_msec() - t0])
		i += 1
		var due := t0 + int(i * 1000.0 / 30.0)
		while Time.get_ticks_msec() < due:
			await tree.process_frame
		s = scene()
		if s is World and s.hud.is_cinematic():
			if i % 45 == 0:
				Input.action_press("interact")
			elif i % 45 == 2:
				Input.action_release("interact")


func test_first_90_seconds_watched() -> void:
	await _capture("intro", false)


func test_first_90_seconds_prompt() -> void:
	await _capture("prompt", true)

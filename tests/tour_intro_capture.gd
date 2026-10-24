extends "res://tests/test_case.gd"
## The first 90 s from a fresh profile, as captured evidence: a frame every
## 1/30 s (for the clip) on the watched (no input) path. Run with --tour
## --filter=tour_intro_capture --screenshots=<dir>.

func test_first_90_seconds_watched() -> void:
	settings().opening_seen = false
	tree.change_scene_to_file(TITLE_SCENE)
	await frames(5)
	scene()._start()
	var t0 := Time.get_ticks_msec()
	var i := 0
	while Time.get_ticks_msec() - t0 < 90000:
		await shot("intro_%04d_%06d" % [i, Time.get_ticks_msec() - t0])
		i += 1
		var due := t0 + int(i * 1000.0 / 30.0)
		while Time.get_ticks_msec() < due:
			await tree.process_frame
		var s := scene()
		if s is World and s.hud.is_cinematic():
			if i % 45 == 0:
				Input.action_press("interact")
			elif i % 45 == 2:
				Input.action_release("interact")

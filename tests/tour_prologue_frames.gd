extends "res://tests/test_case.gd"
## Key frames of the festival (docs/review/intro/after_*), on the prompt path:
## autoplay plays it straight through. Run with --tour
## --filter=tour_prologue_frames --screenshots=<dir>.


func test_key_frames() -> void:
	settings().opening_seen = false
	tree.change_scene_to_file(TITLE_SCENE)
	await frames(5)
	scene()._start()
	await wait_until(func() -> bool: return scene() is Prologue, 3.0, "the festival")
	var p: Prologue = scene()
	p.autoplay = true
	await wait(1.5)
	await shot("after_0_start")
	var marks := [
		["lit_1", "after_a_first_lantern", 0.6],
		["lit_3", "after_b_maypole", 0.6],
		["lit_4", "after_c_fourth", 0.6],
		["p1_left", "after_d_p1_left", 0.8],
		["p2_left", "after_e_p2_left", 1.2],
		["timelapse", "after_f_years", 8.0],
	]
	for m in marks:
		await wait_until(func() -> bool: return p.acted.has(m[0]), 180.0, m[0])
		await wait(m[2])
		await shot(m[1])
	await wait_until(func() -> bool: return p.elapsed >= float(p.acted.timelapse) + 16.0, 30.0, "3 YEARS LATER")
	await shot("after_h_three_years")
	await wait_until(func() -> bool: return p.acted.has("load"), 30.0, "the load")
	await wait(1.0)
	await shot("after_g_load")
	await wait(2.4)
	await shot("after_i_whos_in_my_save")
	# Leave only once the hand-off has gone through: quitting with the scene
	# change still pending is not a state the game can be in.
	await wait_until(func() -> bool: return scene() is World, 15.0, "the room")
	await wait(1.0)

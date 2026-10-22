extends "res://tests/test_case.gd"
## The wider Square (docs/VERTICAL_SLICE.md §3c): the camera across it, its
## subspaces, the lamp and the gate. Not part of the suite.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" $GODOT --path . -s res://tests/run_tests.gd \
##       -- --test-mode --tour --filter=tour_square --screenshots=/some/dir


func _walk_to(w: Node, at: Vector2, settle := 1.6) -> void:
	w.player.global_position = at
	await wait(settle)


func test_square_expansion() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.global_position = Vector2(200, 130)
	await _walk_to(w, Vector2(200, 200))
	await shot("sq1_arrival_west")
	await _walk_to(w, Vector2(470, 200))
	await shot("sq2_panning_east")
	await _walk_to(w, Vector2(690, 200))
	await shot("sq3_crossing_lamp")
	await _walk_to(w, Vector2(734, 266))
	await shot("sq4_recess_hidden")
	await _walk_to(w, Vector2(700, 70))
	await shot("sq5_lane_gate")
	await _walk_to(w, Vector2(860, 180))
	await shot("sq6_archive_front")
	settings().reduce_motion = true
	await _walk_to(w, Vector2(500, 200), 0.3)
	await shot("sq7_reduced_motion_cut")
	settings().reduce_motion = false
	# A threat off the screen's edge is marked.
	w.player.global_position = Vector2(880, 180)
	w.area.arin.global_position = Vector2(200, 130)
	await wait(0.8)
	await shot("sq8_offscreen_marker")

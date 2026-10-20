extends "res://tests/test_case.gd"
## Storyboard of the opening film: one frame at each beat. Not part of the suite.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" $GODOT --path . -s res://tests/run_tests.gd \
##       -- --test-mode --tour --filter=tour_opening --screenshots=/some/dir


func test_opening_storyboard() -> void:
	settings().opening_seen = false
	var film := Opening.new()
	film.replay = true
	tree.root.add_child(film)
	tree.current_scene = film
	for beat in [[1.5, "o1_tv"], [6.0, "o2_together"], [10.0, "o3_disconnected"], [14.5, "o4_saving"],
			[18.2, "o5_going_out"], [22.0, "o6_left_standing"], [24.5, "o7_looks_up"], [27.2, "o8_push_in"]]:
		while film._t < beat[0]:
			await tree.process_frame
		await shot(beat[1])
	film._finish()
	await frames(5)

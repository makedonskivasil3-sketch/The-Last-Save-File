extends "res://tests/test_case.gd"
## The title room (scripts/fx/title_art.gd): stills, and a short frame
## sequence for motion review. Not part of the suite.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" $GODOT --path . -s res://tests/run_tests.gd \
##       -- --test-mode --tour --filter=tour_title --screenshots=/some/dir


func test_title_stills_and_motion() -> void:
	settings().opening_seen = true
	tree.change_scene_to_file("res://scenes/title.tscn")
	await wait(1.5)
	await shot("title_after")
	var art: TitleArt = scene().find_children("*", "TitleArt", true, false)[0]
	# The drift's extremes (the nearest layer at its furthest).
	art.elapsed = 14.0
	await frames(2)
	await shot("title_drift_a")
	art.elapsed = 43.0
	await frames(2)
	await shot("title_drift_b")
	# Motion: 6 s at 10 frames a second, from the drift's middle.
	art.elapsed = 20.0
	for i in 60:
		art.elapsed = 20.0 + i * 0.1
		await frames(1)
		await shot("motion_%03d" % i)
	settings().reduce_motion = true
	art.elapsed = 14.0
	await frames(2)
	await shot("title_reduced_motion")

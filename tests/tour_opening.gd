extends "res://tests/test_case.gd"
## Storyboard of the opening film: one frame at each beat. Not part of the suite.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" $GODOT --path . -s res://tests/run_tests.gd \
##       -- --test-mode --tour --filter=tour_opening --screenshots=/some/dir


func test_opening_storyboard() -> void:
	settings().opening_seen = false
	var film := Opening.new()
	film.replay = true
	film.autoplay = true  # each state acts at once
	var old := tree.current_scene
	tree.root.add_child(film)
	tree.current_scene = film
	if old:
		old.queue_free()  # (else the previous scene keeps running behind it)
	# The continuity animatic's eight shots (docs/NARRATIVE_CONTRACT.md §8).
	# Interactive (docs/VERTICAL_SLICE.md §3): autoplay walks each state.
	for beat in [[3.0, "o1_two_players"], [5.0, "o2_ritual_walk", 2.0], [8.4, "o2b_saving"], [10.8, "o4_stuck_87", 0.7],
			[14.5, "o3_asleep"], [23.0, "o5_paused_she_walks", 2.5], [30.0, "o6_the_well"], [37.0, "o7_looks_out"], [42.0, "o8_unfinished"]]:
		while film._t < beat[0]:
			await tree.process_frame
		if beat.size() > 2:
			var until: float = film.elapsed + beat[2]
			while film.elapsed < until:
				await tree.process_frame
		await shot(beat[1])
	film._finish()
	await frames(5)

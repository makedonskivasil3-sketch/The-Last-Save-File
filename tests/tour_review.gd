extends "res://tests/test_case.gd"
## Before/after captures for the 22 October review (docs/REVIEW_OCT22.md):
## the same states, at the same scale, for each area the pass touches.
## Not part of the suite. Name prefix from TOUR_LABEL (default "after").
##
##   TOUR_LABEL=before xvfb-run -a -s "-screen 0 1280x720x24" $GODOT --path . \
##       -s res://tests/run_tests.gd -- --test-mode --tour --filter=tour_review --screenshots=DIR


func _l(name: String) -> String:
	var label := OS.get_environment("TOUR_LABEL")
	return "%s_%s" % [label if label != "" else "after", name]


func _calm(w: Node) -> void:
	w.director.paused = true
	if w.area.get("arin"):
		w.area.arin.paused = true


func test_review_states() -> void:
	# A true first launch: title, the opening skipped, the boot read, the
	# first controllable frame.
	settings().opening_seen = false
	settings().tutorial_tips = true
	tree.change_scene_to_file("res://scenes/title.tscn")
	await wait(1.5)
	await shot(_l("01_title"))
	scene()._start()
	await wait_until(func() -> bool: return scene() is Opening, 3.0, "opening")
	await wait(0.6)  # (a press already down when the film starts doesn't skip)
	Input.action_press("interact")
	await wait(1.0)
	Input.action_release("interact")
	await wait_until(func() -> bool: return scene() is World, 5.0, "the room")
	var w := scene()
	await wait_until(func() -> bool: return w.hud.is_cinematic(), 3.0, "boot")
	await read_through_cinematic(w)
	await wait_until(func() -> bool: return not w._cutscene, 5.0, "first control")
	await wait(1.5)
	await shot(_l("02_first_room"))
	# The square, west then east.
	await go_to(w, "square", "house")
	_calm(w)
	await wait(1.5)
	await shot(_l("03_square_west"))
	w.player.global_position = Vector2(700, 200)
	await wait(2.0)
	await shot(_l("04_square_east_crossing"))
	w.player.global_position = Vector2(860, 182)
	await wait(1.5)
	await shot(_l("05_square_archive_front"))
	# The Archive.
	await go_to(w, "archive", "west")
	_calm(w)
	await wait(1.5)
	await shot(_l("06_archive"))
	# The house, as the door chimes.
	await go_to(w, "house", "front")
	w.area.next_visit = ArinsHouse.CHIME_LEAD - 1.5
	await wait(0.6)
	await shot(_l("07_house_chime"))
	# Out of bounds: a chunk about to go, normal then reduced flashing.
	await go_to(w, "oob", "well")
	_calm(w)
	w.area._t = 1.85  # (chunks at offset 0 are in their last half second)
	await frames(2)
	await shot(_l("08_oob_warning"))
	settings().reduce_flashing = true
	await frames(2)
	await shot(_l("09_oob_warning_reduced"))
	settings().reduce_flashing = false
	# The bin, about to empty.
	await go_to(w, "bin", "west")
	_calm(w)
	w.area.next_empty = 1.0
	w.player.global_position = Vector2(205, 85)  # (in the first file's shadow)
	await wait(0.5)
	await shot(_l("10_bin_shelter"))
	# The edge.
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	_calm(w)
	await wait(1.5)
	await shot(_l("11_edge"))

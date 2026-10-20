extends "res://tests/test_case.gd"
## The opening film (scripts/ui/opening.gd): first launch only, skippable,
## replayable, and no run starts until it ends.


func _title() -> Node:
	tree.change_scene_to_file("res://scenes/title.tscn")
	await frames(5)
	return scene()


func test_first_launch_plays_the_film_before_any_run() -> void:
	settings().opening_seen = false
	var title := await _title()
	title._start()
	await frames(5)
	check(scene() is Opening, "the film plays first")
	check_eq(memory().sessions, 0, "and no run has started")
	await wait(2.0)
	check_eq(memory().sessions, 0, "still none while it plays (quitting now costs nothing)")


func test_holding_interact_skips_into_the_run() -> void:
	settings().opening_seen = false
	var title := await _title()
	title._start()
	await frames(5)
	await wait(1.0)
	Input.action_press("interact")
	await wait(0.4)
	check(scene() is Opening and scene()._hint.modulate.a > 0.1, "a press shows how to skip")
	await wait(0.6)
	Input.action_release("interact")
	await wait_until(func() -> bool: return scene() is World, 5.0, "the run")
	check(settings().opening_seen, "seen once skipped: it won't play again by itself")
	check_eq(memory().sessions, 1, "the run starts after it")


func test_it_runs_its_length_and_then_the_game_begins() -> void:
	settings().opening_seen = false
	var film := Opening.new()
	tree.root.add_child(film)
	tree.current_scene = film
	check(Opening.LENGTH >= 20.0 and Opening.LENGTH <= 35.0, "20–35 s (%.0f)" % Opening.LENGTH)
	film._t = Opening.LENGTH - 0.5
	await wait_until(func() -> bool: return scene() is World, 4.0, "the run after the last frame")


func test_it_can_be_replayed_from_the_title_and_comes_back() -> void:
	settings().opening_seen = true
	var title := await _title()
	var replay: Button = null
	for b in title.find_children("*", "Button", true, false):
		if (b as Button).text == "Opening":
			replay = b
	check(replay != null, "the title offers the opening again")
	replay.pressed.emit()
	await frames(5)
	check(scene() is Opening and scene().replay, "it plays")
	scene()._finish()
	await wait_until(func() -> bool: return scene() != null and scene().has_method("_start"), 4.0, "the title again")
	check_eq(memory().sessions, 0, "a replay never starts a run")


func test_reduced_motion_holds_the_camera_still() -> void:
	settings().reduce_flashing = true
	check(Opening.calm(), "reduce flashing: no push, no flicker")
	settings().reduce_flashing = false
	settings().glitch_intensity = 0.0
	check(Opening.calm(), "zero glitch intensity: the same")

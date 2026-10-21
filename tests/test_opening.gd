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
	var old := tree.current_scene
	tree.root.add_child(film)
	tree.current_scene = film
	if old:
		old.queue_free()  # (else the previous scene keeps running behind it)
	# The continuity milestone's animatic (NARRATIVE_CONTRACT.md §8) is about
	# 45 s, inside its 60–90 s prototype budget (was 20–35 s for the 28 s film).
	check(Opening.LENGTH >= 40.0 and Opening.LENGTH <= 60.0, "40–60 s (%.0f)" % Opening.LENGTH)
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


func _film() -> Opening:
	settings().opening_seen = false
	var film := Opening.new()
	var old := tree.current_scene
	tree.root.add_child(film)
	tree.current_scene = film
	if old:
		old.queue_free()
	await frames(2)
	return film


func test_a_press_held_over_from_the_title_does_not_skip() -> void:
	Input.action_press("interact")  # still down from choosing Load
	var film := await _film()
	await wait(1.5)
	check(is_instance_valid(film) and not film._done, "held from before the film: it plays on")
	Input.action_release("interact")
	await frames(2)
	Input.action_press("interact")
	await wait(1.0)
	Input.action_release("interact")
	await wait_until(func() -> bool: return scene() is World, 5.0, "a fresh hold skips")


func test_looking_away_holds_the_film_and_its_skip() -> void:
	var film := await _film()
	await wait(1.0)
	film._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var at := film._t
	Input.action_press("interact")
	await wait(1.2)
	check_eq(film._t, at, "no time passes while the window is elsewhere")
	check(not film._done, "and a key held meanwhile doesn't skip")
	film._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await wait(1.2)
	check(not film._done, "back again, that key must be let go before it can skip")
	check(film._t > at + 0.5, "the film carries on from the same frame")
	Input.action_release("interact")
	await frames(3)


func test_the_skip_key_is_let_go_before_the_room_takes_input() -> void:
	var film := await _film()
	await wait(0.3)
	Input.action_press("interact")
	await wait(1.2)
	check(film._done, "skipped")
	check(scene() is Opening, "but the room waits while the key is still down")
	Input.action_release("interact")
	await wait_until(func() -> bool: return scene() is World, 4.0, "the room, once it's let go")
	check(not (scene() as World).glitch.is_charging() if (scene() as World).glitch and (scene() as World).glitch.has_method("is_charging") else true, "no glitch charging from the skip")


func test_the_opening_names_no_one() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/ui/opening.gd")
	check(not src.contains("\"P2  RUE\""), "Player 2 is not labelled with Rue's name")



func test_the_impossible_event_happens_on_screen() -> void:
	settings().opening_seen = false
	var film := Opening.new()
	var old := tree.current_scene
	tree.root.add_child(film)
	tree.current_scene = film
	if old:
		old.queue_free()
	# Fast-forward through the film the way it plays: frame by frame.
	var arin_at_pause := 0.0
	var rue_at_pause := 0.0
	while film._t < 22.5:
		film._process(0.05)
	arin_at_pause = film._arin_x
	rue_at_pause = film._rue_x
	while film._t < 30.0:
		film._process(0.05)
	check_eq(film._arin_x, arin_at_pause, "paused: Arin doesn't move")
	check(film._rue_x > rue_at_pause + 10.0, "paused: she keeps walking, with nobody's hands on her (%.0f -> %.0f)" % [rue_at_pause, film._rue_x])
	check(film._tune_started, "the music box comes from the wrong place")
	while film._t < 43.0:
		film._process(0.05)
	check(film._caption.text == "" or film._caption.text.begins_with("["), "captions describe sounds, they don't explain")
	check(not FileAccess.get_file_as_string("res://scripts/ui/opening.gd").contains("\"RUE\""), "still names no one")
	film._finish()
	Input.action_release("interact")
	await wait_until(func() -> bool: return scene() is World, 4.0, "the room after")

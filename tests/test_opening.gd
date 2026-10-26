extends "res://tests/test_case.gd"
## The opening film (scripts/ui/opening.gd) and the first launch. Since the
## festival (scripts/ui/prologue.gd, docs/INTRO_REBUILD.md) the first launch
## plays the festival, not the film; the film's own behaviour is still
## tested here (it is kept, off the first-run path: author question Q3).


func _title() -> Node:
	tree.change_scene_to_file("res://scenes/title.tscn")
	await frames(5)
	return scene()


func test_first_launch_plays_the_festival_before_any_run() -> void:
	settings().opening_seen = false
	var title := await _title()
	title._start()
	await frames(5)
	check(scene() is Prologue, "the festival plays first")
	check_eq(memory().sessions, 0, "and no run has started")
	await wait(2.0)
	check_eq(memory().sessions, 0, "still none while it plays (quitting now costs nothing)")


func test_holding_skip_skips_into_the_run() -> void:
	settings().opening_seen = false
	var title := await _title()
	title._start()
	await frames(5)
	await wait(1.0)
	Input.action_press("ui_cancel")
	await wait(0.4)
	check(scene() is Prologue and scene()._skip_t > 0.1, "a held skip shows its bar")
	await wait(0.6)
	Input.action_release("ui_cancel")
	await wait_until(func() -> bool: return scene() is World, 12.0, "the run")
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
		if (b as Button).text == "The Festival":
			replay = b
	check(replay != null, "the title offers the festival again")
	replay.pressed.emit()
	await frames(5)
	check(scene() is Prologue and scene().replay, "it plays")
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
	# Fast-forward through the film the way it plays: frame by frame, with
	# nobody at the controls (each state's hands act by themselves).
	var arin_at_pause := 0.0
	var rue_at_pause := 0.0
	while film._t < 22.5:
		film._process(0.05)
	arin_at_pause = film._arin_x
	rue_at_pause = film._rue_x
	while film._t < 30.0:
		film._process(0.05)
	check_eq(film._arin_x, arin_at_pause, "paused: Arin doesn't move")
	check(absf(film._rue_x - rue_at_pause) > 10.0, "paused: she keeps walking (%.0f -> %.0f)" % [rue_at_pause, film._rue_x])
	check(film.acted.has("ritual_auto") and film.acted.has("interrupt_auto") and film.acted.has("impossible_auto"),
		"left alone, every state still plays out (%s)" % film.acted)
	check(film._tune_started, "the music box comes from the wrong place")
	while film._t < 43.0:
		film._process(0.05)
	check(film._caption.text == "" or film._caption.text.begins_with("["), "captions describe sounds, they don't explain")
	check(not FileAccess.get_file_as_string("res://scripts/ui/opening.gd").contains("\"RUE\""), "still names no one")
	film._finish()
	Input.action_release("interact")
	await wait_until(func() -> bool: return scene() is World, 4.0, "the room after")


func test_the_last_shot_matches_the_canon() -> void:
	# docs/NARRATIVE_CONTRACT.md §0.4 C1: her message arrived whole; the
	# owner's reply stopped mid-word and was never sent.
	check_eq(Opening.HER_MESSAGE, "still have my save?", "her message, whole, as in DELETE and owner note 6")
	check(Opening.OWNER_REPLY.begins_with("yes i still have your") and not Opening.OWNER_REPLY.ends_with("save"),
		"the owner's reply, unfinished, as in the Bin's draft")
	check(Story.OWNER_NOTES.any(func(n: String) -> bool: return n.contains("i started typing yes")), "the owner's note says the same")
	check(Opening.LATER > 33.0 and Opening.LATER < Opening.LENGTH - 4.0, "months later is its own shot, before the end")
	var src := FileAccess.get_file_as_string("res://scripts/ui/opening.gd")
	check(not src.contains("UNFINISHED"), "no unfinished sentence of hers")


func test_the_well_clicks_with_her_gesture() -> void:
	# The opening's shot 2 (taps at 7.0 and 7.25 s, the press at 7.6 s) and
	# the well's first click are the same gesture: two taps, then a press.
	var p: Array = WellSequence.CLICK_PATTERN
	check_eq(p.size(), 3, "three clicks")
	check(is_equal_approx(p[1][0] - p[0][0], 0.25) and is_equal_approx(p[2][0] - p[0][0], 0.6), "the same spacing as hers")
	check(p[0][1] < p[2][1] and p[1][1] < p[2][1], "two light taps, then a firmer press")


## The interactive states (docs/VERTICAL_SLICE.md §3), played the way a
## player would: keys, then taps on the picture.
func _step(film: Opening, seconds: float) -> void:
	for i in int(seconds / 0.05):
		if film._done:
			return
		film._process(0.05)


func _tap_key(film: Opening, action: String) -> void:
	Input.action_press(action)
	film._process(0.05)
	film._process(0.05)
	Input.action_release(action)
	film._process(0.05)


func test_the_player_walks_her_to_the_save_point_and_presses() -> void:
	var film := await _film()
	_step(film, 0.5)  # (arms: nothing was held)
	_step(film, 5.0)
	check_eq(film._gate, Opening.Gate.RITUAL, "the ritual waits for the player")
	check(is_equal_approx(film._t, Opening.GATE_AT[Opening.Gate.RITUAL]), "film time holds (%.2f)" % film._t)
	_tap_key(film, "interact")
	_step(film, 1.2)
	check_eq(film._gate, Opening.Gate.RITUAL, "a press away from the save point is only her habit")
	Input.action_press("move_right")
	while film._rue_x < Opening.SAVE_X - 2.0 and film.elapsed < 30.0:
		film._process(0.05)
	Input.action_release("move_right")
	check(absf(film._rue_x - Opening.SAVE_X) < 14.0, "walked there (%.0f)" % film._rue_x)
	_tap_key(film, "interact")
	_step(film, 1.2)
	check(film.acted.has("ritual") and not film.acted.has("ritual_auto"), "the player did it")
	check_eq(film._gate, Opening.Gate.INTERRUPT, "on to the save")
	_step(film, 8.0)
	check(is_equal_approx(film._t, Opening.GATE_AT[Opening.Gate.INTERRUPT]), "the save stops at 87%% and waits (%.2f)" % film._t)
	_tap_key(film, "interact")
	_step(film, 1.5)
	check(film.acted.has("interrupt") and not film.acted.has("interrupt_auto"), "the same press, refused")
	check_eq(film._gate, Opening.Gate.IMPOSSIBLE, "then the pause")
	while film._t < Opening.GATE_AT[Opening.Gate.IMPOSSIBLE] and film.elapsed < 60.0:
		film._process(0.05)
	var arin := film._arin_x
	Input.action_press("move_left")
	_step(film, 1.0)
	check(film.acted.has("walked_paused"), "under PAUSE she walks when the player moves her")
	check_eq(film._caption.text, "[her hands are still. she moves anyway.]", "said once, as a caption")
	while film._gate == Opening.Gate.IMPOSSIBLE and film.elapsed < 80.0:
		film._process(0.05)
	Input.action_release("move_left")
	check_eq(film._arin_x, arin, "Arin doesn't")
	check(film.acted.has("impossible") and not film.acted.has("impossible_auto"), "the player took her to the well")
	check(film._t >= 28.9, "and the music box plays from it")
	film._finish()
	await wait_until(func() -> bool: return scene() is World, 5.0, "the room")


func test_taps_on_the_picture_play_it_too() -> void:
	var film := await _film()
	_step(film, 6.0)
	film._tap_at(Vector2(Opening.SAVE_X + 10.0, 200))  # tap the save point
	while film._gate == Opening.Gate.RITUAL and film.elapsed < 30.0:
		film._process(0.05)
	check(film.acted.has("ritual") and not film.acted.has("ritual_auto"), "a tap at the save point walks there and presses")
	while film._t < Opening.GATE_AT[Opening.Gate.INTERRUPT] and film.elapsed < 40.0:
		film._process(0.05)
	film._tap_at(Vector2(320, 200))
	_step(film, 1.5)
	check(film.acted.has("interrupt"), "a tap is the press")
	while film._t < Opening.GATE_AT[Opening.Gate.IMPOSSIBLE] and film.elapsed < 60.0:
		film._process(0.05)
	film._tap_at(Vector2(Opening.WELL_X, 210))
	while film._gate == Opening.Gate.IMPOSSIBLE and film.elapsed < 80.0:
		film._process(0.05)
	check(film.acted.has("impossible") and not film.acted.has("impossible_auto"), "a tap where the well is takes her there")
	film._finish()
	await wait_until(func() -> bool: return scene() is World, 5.0, "the room")


func test_a_tap_acts_and_a_hold_skips_never_both() -> void:
	var film := await _film()
	_step(film, 6.0)
	Input.action_press("interact")
	_step(film, 1.0)
	Input.action_release("interact")
	check(film._done, "held: skipped")
	check(film._habit_t < 0.0 and film.acted.is_empty(), "and the hold didn't also press (%s)" % film.acted)
	await wait_until(func() -> bool: return scene() is World, 5.0, "the room")


func test_waiting_shows_what_to_do_then_the_hands_do_it() -> void:
	var film := await _film()
	_step(film, 5.0 + Opening.HINT_AFTER + 0.5)
	check(film._hint.text.contains("save point"), "a hint after a while (%s)" % film._hint.text)
	check(not film._hint.text.to_lower().contains("rue") and not film._hint.text.contains("she"), "essential only: no names, no meaning")
	_step(film, Opening.AUTO_AFTER[Opening.Gate.RITUAL] + 8.0)
	check(film.acted.has("ritual_auto") and film._gate != Opening.Gate.RITUAL, "nobody pressed: she did it herself")
	film._finish()
	await wait_until(func() -> bool: return scene() is World, 5.0, "the room")


func test_a_controller_dropping_out_holds_the_film() -> void:
	var film := await _film()
	_step(film, 6.0)
	settings().using_gamepad = true
	film._on_joy_connection_changed(0, false)
	var at := film._t
	var idle := film._idle_t
	_step(film, 3.0)
	check(film._held and film._idle_t == idle, "held: no autopilot creeping on (%.1f)" % film._idle_t)
	check(film._hint.text.contains("disconnected"), "and says why")
	film._on_joy_connection_changed(0, true)
	check(not film._held, "back when it's back")
	check_eq(film._t, at, "from the same frame")
	settings().using_gamepad = false
	film._finish()
	await wait_until(func() -> bool: return scene() is World, 5.0, "the room")


## Who holds what (docs/OPENING_REVIEW.md): Arin is at the save point first
## and waits for her; "you" is on her controller from the moment the
## ritual asks (before any hint), then on the figure once her hands are
## still; her controller's light is out while she walks under PAUSE.
func test_who_holds_what_reads_before_any_hint() -> void:
	var film := await _film()
	_step(film, 0.5)
	_step(film, 5.0)
	check(film._gate == Opening.Gate.RITUAL and film._idle_t < Opening.HINT_AFTER + 0.6, "at the ritual")
	check(not film._you_moved.get(Opening.Gate.RITUAL, false), "'you' is shown on her controller, before the hint")
	Input.action_press("move_right")
	_step(film, 0.3)
	check(film._you_moved.get(Opening.Gate.RITUAL, false), "moving her: the cue has done its job")
	while film._rue_x < Opening.SAVE_X - 2.0 and film.elapsed < 30.0:
		film._process(0.05)
	Input.action_release("move_right")
	check(absf(film._arin_x - (Opening.SAVE_X + 22.0)) < 1.0, "walking her straight there, Arin is there first (%.0f), waiting" % film._arin_x)
	_tap_key(film, "interact")
	check(film._together_t >= 0.0, "they save together: the shared beat")
	while film._t < Opening.GATE_AT[Opening.Gate.IMPOSSIBLE] and film.elapsed < 60.0:
		film._process(0.05)
	check(not film._you_moved.get(Opening.Gate.IMPOSSIBLE, false), "under PAUSE, 'you' moves onto the figure")
	Input.action_press("move_left")
	_step(film, 0.5)
	Input.action_release("move_left")
	check(film._you_moved.get(Opening.Gate.IMPOSSIBLE, false), "and goes once she walks")
	check(absf(film._stick) < 0.01, "her thumb doesn't move: the controller isn't driving her")
	film._finish()
	await wait_until(func() -> bool: return scene() is World, 5.0, "the room")


func test_the_first_room_says_which_one_is_you_until_she_moves() -> void:
	var w := await start_session(true, true)
	await wait_until(func() -> bool: return w._awake, 10.0, "awake")
	check(w.player.you_cue, "first run: 'you' over her")
	Input.action_press("move_right")
	await wait(0.4)
	Input.action_release("move_right")
	check(not w.player.you_cue, "gone at the first step")
	w.kill("overwritten", "arin")
	var w2 := await wait_for_new_session(w)
	await wait_until(func() -> bool: return w2._awake, 10.0, "awake again")
	check(not w2.player.you_cue, "not on later runs")


func test_the_save_point_catches_her_on_the_way_past() -> void:
	var film := await _film()
	_step(film, 5.5)
	Input.action_press("move_right")
	_step(film, 9.0)  # held far longer than the walk takes
	check(absf(film._rue_x - Opening.SAVE_X) < 1.0, "she stops on the save point (%.0f)" % film._rue_x)
	Input.action_release("move_right")
	_step(film, 0.2)
	Input.action_press("move_right")
	_step(film, 1.0)
	Input.action_release("move_right")
	check(film._rue_x > Opening.SAVE_X + 10.0, "a fresh press walks on past it")
	film._finish()
	await wait_until(func() -> bool: return scene() is World, 5.0, "the room")

extends "res://tests/test_case.gd"
## The festival (Prologue, docs/INTRO_REBUILD.md §2): the girl's last
## session, played. Stepped in game time unless a test needs real frames.


func _festival(replay := false) -> Prologue:
	settings().opening_seen = false
	var p := Prologue.new()
	p.replay = replay
	var old := tree.current_scene
	tree.root.add_child(p)
	tree.current_scene = p
	if old:
		old.queue_free()
	await frames(2)
	return p


func _step(p: Prologue, seconds: float) -> void:
	for i in int(seconds / 0.05):
		if p._done:
			return
		p._process(0.05)


## Done with it: gone, without a scene change.
func _end(p: Prologue) -> void:
	p._done = true
	p._handed_off = true
	p.queue_free()
	await frames(2)


func _until(p: Prologue, cond: Callable, seconds: float) -> bool:
	for i in int(seconds / 0.05):
		if cond.call():
			return true
		if p._done:
			return cond.call()
		p._process(0.05)
		# This helper drives a route; it also plays the reader. Manual holds
		# and release ownership are covered separately in test_prologue_story.
		if p.story.visible:
			p.story.advance()
	return cond.call()


func test_the_whole_festival_plays_in_order() -> void:
	var p := await _festival(true)
	p.autoplay = true
	check(await _until(p, func() -> bool: return p.beat == Prologue.Beat.LOAD, 400.0), "it reaches the present (%s, %s)" % [Prologue.Beat.keys()[p.beat], str(p.acted)])
	var order := ["lit_1", "lit_2", "lit_3", "lit_4", "p1_left", "choice", "p2_left", "timelapse", "load"]
	var last := -1.0
	for k in order:
		check(p.acted.has(k), "%s happened" % k)
		if p.acted.has(k):
			check(float(p.acted[k]) >= last, "%s in order" % k)
			last = float(p.acted[k])
	check_eq(p.choice, "lit", "playing straight through, she lights the last one herself")
	check(float(p.acted.get("load", 999.0)) <= 240.0, "the festival, the leaves and 3 YEARS LATER in under 4 minutes of game time (%.0f s)" % float(p.acted.get("load", 0.0)))
	await _end(p)


func test_the_player_has_her_at_once() -> void:
	var p := await _festival(true)
	var start := p.rue_pos
	Input.action_press("move_right")
	_step(p, 0.5)
	Input.action_release("move_right")
	check(p.rue_pos.x > start.x + 20.0, "moving her from the first frames")
	check(p.acted.has("control") and float(p.acted.control) < 1.0, "control within a second (%s)" % [str(p.acted.get("control"))])
	await _end(p)


func test_the_gate_opens_only_while_arin_holds_the_plate() -> void:
	var p := await _festival(true)
	check(not p._gate_open(), "at first, shut")
	p.arin_pos = Prologue.PLATE
	check(p._gate_open(), "Arin on the plate: open")
	p.arin_pos = Prologue.PLATE + Vector2(30, 0)
	check(not p._gate_open(), "off it: shut again")
	p.lit[0] = true
	check(p._gate_open(), "once the lantern's lit it stays open")
	await _end(p)


func test_beside_arin_tobben_doesnt_see_her() -> void:
	var p := await _festival(true)
	p._to_beat(Prologue.Beat.L2)
	# Put her in his look, away from Arin.
	var dir := Vector2.from_angle(p._look_angle())
	p.rue_pos = Prologue.TOBBEN_AT + dir * 60.0
	p.arin_pos = p.rue_pos + Vector2(60, 0)
	check(p._seen_by_tobben(), "in his look, alone: seen")
	p.arin_pos = p.rue_pos + Vector2(10, 0)
	check(not p._seen_by_tobben(), "right beside Arin: not seen")
	await _end(p)


func test_the_maypole_needs_both_of_them() -> void:
	var p := await _festival(true)
	p._to_beat(Prologue.Beat.L3)
	p.rue_pos = Prologue.SPECIAL_RIGHT
	p.arin_pos = Prologue.SPECIAL_LEFT + Vector2(0, 40)
	p._set_arin_goal(p.arin_pos)
	Input.action_press("interact")
	_step(p, 2.0)
	check(not p.lit[2], "holding alone: nothing")
	p.arin_pos = Prologue.SPECIAL_LEFT
	p._set_arin_goal(p.arin_pos)
	_step(p, Prologue.SPECIAL_TIME + 0.5)
	Input.action_release("interact")
	check(p.lit[2], "both holding: the co-op special lights it")
	await _end(p)


func test_the_spotlight_watches_only_the_gap() -> void:
	var p := await _festival(true)
	p._to_beat(Prologue.Beat.L4)
	var gap := Vector2((Prologue.GAP.x + Prologue.GAP.y) * 0.5, (Prologue.HEDGE_Y.x + Prologue.HEDGE_Y.y) * 0.5)
	var on := false
	var off := false
	for i in 200:
		p.elapsed = i * 0.05
		if p._in_beam(gap):
			on = true
		else:
			off = true
	check(on and off, "the gap is lit, then not: a crossing can be timed")
	p.elapsed = 0.0
	var beside := Vector2(Prologue.GAP.x - 20, 276)
	var ever := false
	for i in 200:
		p.elapsed = i * 0.05
		ever = ever or p._in_beam(beside)
	check(not ever, "waiting beside the gap is safe")
	await _end(p)


func _at_the_break(p: Prologue) -> void:
	for i in 4:
		p.lit[i] = true
	p._to_beat(Prologue.Beat.P1_LEFT)
	p.arin_pos = Prologue.ARIN_STOPS
	p._set_arin_goal(Prologue.ARIN_STOPS)
	p.rue_pos = Prologue.ARIN_STOPS + Vector2(40, 0)
	_step(p, 0.2)


func test_player_one_leaves_and_she_can_light_the_last_one_alone() -> void:
	var p := await _festival(true)
	await _at_the_break(p)
	check(p.acted.has("p1_left") and not p._arin_present, "PLAYER 1 HAS LEFT THE SESSION")
	check(p._toast.contains("PLAYER 1 HAS LEFT"), "said on screen (%s)" % p._toast)
	check(p.step_hint().contains("light the last one") and p.step_hint().contains("stay beside him"), "the decision is offered (%s)" % p.step_hint())
	p.rue_pos = Prologue.LANTERNS[4] + Vector2(0, 14)
	p._interact()
	check_eq(p.choice, "lit", "she lit it, alone")
	_step(p, 2.0)
	check_eq(p.beat, Prologue.Beat.P2_LEFT, "then PLAYER 2 HAS LEFT THE SESSION")
	var at := p.rue_pos
	Input.action_press("move_left")
	_step(p, 0.4)
	Input.action_release("move_left")
	check(p.rue_pos.x < at.x - 10.0, "and she still moves")
	await _end(p)


func test_staying_beside_him_is_a_choice_and_she_lights_it_anyway() -> void:
	var p := await _festival(true)
	await _at_the_break(p)
	p.rue_pos = p.arin_pos + Vector2(10, 0)
	_step(p, 3.0)
	check_eq(p.choice, "stayed", "she stayed beside him")
	check(await _until(p, func() -> bool: return p.lit[4], 40.0), "during the years, with nobody holding her, she lights it herself")
	check(p.acted.has("lit_by_herself"), "(that's recorded)")
	await _end(p)


func test_doing_nothing_still_moves_on() -> void:
	var p := await _festival(true)
	await _at_the_break(p)
	check(await _until(p, func() -> bool: return p.choice != "", Prologue.DECIDE_TIME + 6.0), "no input: it doesn't wait forever")
	check_eq(p.choice, "idle", "recorded as neither")
	await _end(p)


func test_skipping_reaches_the_present_fast() -> void:
	var p := await _festival(true)
	_step(p, 0.2)
	Input.action_press("ui_cancel")
	_step(p, Prologue.SKIP_HOLD + 0.1)
	Input.action_release("ui_cancel")
	check_eq(p.beat, Prologue.Beat.LOAD, "held Esc: straight to the present")
	_step(p, Prologue.LOAD_TIME + 0.2)
	check(p._done, "the owner's line, then the game")
	check(float(p.acted.handoff) <= 15.0, "a skip reaches the present in %.1f s (≤ 15)" % float(p.acted.handoff))
	await _end(p)


func test_a_first_run_records_the_festival_and_the_room_skips_the_boot() -> void:
	var title := TITLE_SCENE
	settings().opening_seen = false
	tree.change_scene_to_file(title)
	await frames(5)
	scene()._start()
	await wait_until(func() -> bool: return scene() is Prologue, 3.0, "the festival")
	var p: Prologue = scene()
	_step(p, 0.2)
	Input.action_press("ui_cancel")
	await wait(Prologue.SKIP_HOLD + 0.2)
	Input.action_release("ui_cancel")
	await wait_until(func() -> bool: return scene() is World, 15.0, "the room")
	var w := scene()
	check(memory().festival_seen, "the profile has seen the festival")
	check_eq(memory().festival_choice, "skipped", "skipped is recorded as skipped")
	check(settings().opening_seen, "and won't play it again unasked")
	await wait(1.0)
	check(not w.hud.is_cinematic(), "no boot log in the room: the festival showed it, in the square")
	await wait_until(func() -> bool: return w._awake, 6.0, "awake")
	check(w._awake, "she wakes in Arin's room")


func test_a_replay_changes_nothing_in_the_save() -> void:
	memory().festival_seen = true
	memory().festival_choice = "stayed"
	var p := await _festival(true)
	p.autoplay = true
	await _until(p, func() -> bool: return p._done, 400.0)
	check_eq(memory().festival_choice, "stayed", "a replay from the title doesn't overwrite the first decision")
	await _end(p)


func test_profiles_that_already_started_dont_get_it() -> void:
	memory().sessions = 3
	settings().opening_seen = false
	check(not Prologue.wanted(), "an older profile (sessions already run) goes straight in")
	memory().sessions = 0
	settings().opening_seen = true
	check(not Prologue.wanted(), "a profile that saw an opening goes straight in")


func test_the_festival_fields_survive_a_save_and_old_saves_load() -> void:
	memory().festival_seen = true
	memory().festival_choice = "lit"
	memory().save_memory()
	memory().festival_seen = false
	memory().festival_choice = ""
	memory().load_memory()
	check(memory().festival_seen and memory().festival_choice == "lit", "round trip")
	# A save written before the festival existed (no festival keys at all).
	memory().clear_state()
	memory().sessions = 2
	memory().save_memory()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(memory()._path))
	data.erase("festival_seen")
	data.erase("festival_choice")
	SafeFile.write_atomic(memory()._path, JSON.stringify(data))
	memory().festival_choice = "junk"
	memory().load_memory()
	check_eq(memory().sessions, 2, "the old save loads")
	check(not memory().festival_seen and memory().festival_choice == "", "with no festival in it")


func test_looking_away_holds_it() -> void:
	var p := await _festival(true)
	_step(p, 0.5)
	p._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var e := p.elapsed
	_step(p, 2.0)
	check_eq(p.elapsed, e, "nothing moves while the window is elsewhere")
	p._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_step(p, 0.5)
	check(p.elapsed > e, "back: it goes on")
	await _end(p)


func test_reduced_motion_plays_the_years_still() -> void:
	settings().reduce_motion = true
	var p := await _festival(true)
	check(Prologue.calm(), "calm")
	p._to_beat(Prologue.Beat.TIMELAPSE)
	p.lit[4] = true
	await _until(p, func() -> bool: return p.beat == Prologue.Beat.LOAD, Prologue.TIMELAPSE + 2.0)
	check_eq(p.beat, Prologue.Beat.LOAD, "the years pass, without particles or flicker")
	settings().reduce_motion = false
	await _end(p)


func test_every_step_says_what_to_do_without_sound() -> void:
	var p := await _festival(true)
	p.acted["control"] = 0.0
	for b in [Prologue.Beat.L1, Prologue.Beat.L2, Prologue.Beat.L3, Prologue.Beat.L4]:
		p.beat = b
		check(p.step_hint() != "", "%s has its words on screen" % Prologue.Beat.keys()[b])
	await _end(p)


func test_a_phone_can_play_it() -> void:
	# The festival had no on-screen controls: on a phone she couldn't move.
	var p := await _festival(true)
	var touch: TouchControls = null
	for c in p.get_children():
		if c is TouchControls:
			touch = c
	check(touch != null, "the same on-screen stick and E button as the game")
	if touch:
		check(touch.BUTTONS.interact.actions.has("interact"), "E is interact (light, hold at the maypole)")
		var e_button := Rect2(touch.BUTTONS.interact.center - Vector2.ONE * touch.BUTTONS.interact.radius, Vector2.ONE * touch.BUTTONS.interact.radius * 2.0)
		check(not e_button.intersects(Prologue.SKIP_CHIP), "and it doesn't cover the skip chip")
	await _end(p)

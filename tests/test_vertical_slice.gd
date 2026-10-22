extends "res://tests/test_case.gd"
## The vertical slice (docs/VERTICAL_SLICE.md): sessions count only once
## play starts; a controller dropping out holds the game; and the slice's
## route-level guarantees.


## A first launch, left on the boot text (start_session would wait it out).
func _first_launch_at_boot_text() -> Node:
	tree.change_scene_to_file(MAIN_SCENE)
	await wait_until(func() -> bool: return scene() != null and scene().get("hud") != null and scene().hud.is_cinematic(), 5.0, "the boot text")
	return scene()


func test_closing_during_the_boot_text_costs_nothing() -> void:
	# D1: a first launch, closed while the boot text is still up.
	await _first_launch_at_boot_text()
	check(not memory().session_armed(), "the boot text isn't play yet")
	var before := {"purge": memory().purge, "quits": memory().quits, "sessions": memory().sessions}
	memory().record_quit()  # what closing the window does
	check_eq(memory().purge, before.purge, "no purge for a run that never started")
	check_eq(memory().quits, before.quits, "and no quit counted")
	check_eq(memory().sessions, before.sessions - 1, "the session that never began isn't counted either")


func test_a_crash_during_the_boot_text_costs_nothing() -> void:
	await _first_launch_at_boot_text()
	var purge: int = memory().purge
	memory().load_memory()  # as if the process died and the game was reopened
	check_eq(memory().purge, purge, "a crash before play costs nothing")
	check(memory().last_exit != "crash", "and isn't recorded as one (%s)" % memory().last_exit)


func test_once_playing_a_quit_still_counts() -> void:
	await start_session()
	check(memory().session_armed(), "playing: the session counts")
	var purge: int = memory().purge
	memory().record_quit()
	check_eq(memory().purge, purge + 1, "quitting mid-run still costs what the menu says")


func test_a_controller_dropping_out_holds_the_game() -> void:
	# D2: a pad disconnecting mid-play opens the pause menu, ignoring the
	# focus-loss setting (the player can't play on without it).
	var w := await start_session()
	Settings.using_gamepad = true
	w._on_joy_connection_changed(0, false)
	await frames(2)
	check(tree.paused, "the game holds")
	check(w._pause_menu.visible, "on the pause menu, to resume when ready")
	w._pause_menu.close()
	await frames(2)
	Settings.using_gamepad = false
	w._on_joy_connection_changed(0, false)
	await frames(2)
	check(not tree.paused, "a pad nobody was using doesn't stop keyboard play")


func test_the_title_room_drifts_within_bounds_and_holds_with_reduced_motion() -> void:
	settings().opening_seen = true
	tree.change_scene_to_file("res://scenes/title.tscn")
	await wait(0.5)
	var art: TitleArt = scene().find_children("*", "TitleArt", true, false)[0]
	var buttons := scene().find_children("*", "Button", true, false)
	var before := buttons.map(func(b: Button) -> Vector2: return b.global_position)
	var widest := 0.0
	for i in 200:
		art.elapsed = i * 0.7
		widest = maxf(widest, art.layer_offset("near").length())
		check(art.layer_offset("wall").length() <= art.layer_offset("near").length() + 0.001, "further layers move less")
	check(widest > 1.0 and widest <= TitleArt.PARALLAX * 1.42, "the nearest layer drifts, at most %.0f px (%.2f)" % [TitleArt.PARALLAX, widest])
	await wait(0.5)
	check_eq(buttons.map(func(b: Button) -> Vector2: return b.global_position), before, "the menu never moves")
	settings().reduce_motion = true
	for i in 20:
		art.elapsed = i * 3.1
		check_eq(art.layer_offset("near"), Vector2.ZERO, "reduced motion: no drift")
	check(Opening.calm(), "and the opening's push is off too")


# --- the wider Square (§3c) ---------------------------------------------------

func _square(arrival := "house") -> Node:
	var w := await start_session()
	await go_to(w, "square", arrival)
	w.area.arin.global_position = Vector2(200, 130)  # (out of the way)
	return w


func test_the_square_camera_follows_within_its_limits() -> void:
	var w := await _square()
	var limit: float = w.area.view_size.x - 640.0
	check(limit > 0.0, "the square is wider than the screen")
	check_eq(w.view_offset.x, 0.0, "arriving from the house: the west framing")
	w.player.global_position = Vector2(880, 180)
	await wait(2.0)
	check(is_equal_approx(w.view_offset.x, limit), "followed east, up to the limit (%.0f)" % w.view_offset.x)
	check(w.view_rect().has_point(w.player.global_position), "Rue on screen")
	w.player.global_position = Vector2(60, 200)
	await wait(2.0)
	check_eq(w.view_offset.x, 0.0, "and back, never past the west edge")
	await go_to(w, "archive", "west")
	check_eq(w.view_offset.x, 0.0, "a one-screen area doesn't scroll")
	await go_to(w, "square", "east")
	check(is_equal_approx(w.view_offset.x, limit), "arriving from the Archive: already framed east, no pan in")


func test_reduced_motion_cuts_instead_of_panning() -> void:
	settings().reduce_motion = true
	var w := await _square()
	var limit: float = w.area.view_size.x - 640.0
	var seen := {}
	for x in range(80, 900, 20):
		w.player.global_position = Vector2(x, 200)
		await frames(2)
		seen[w.view_offset.x] = true
		check(w.view_rect().has_point(w.player.global_position), "Rue always on screen (x %d)" % x)
	check_eq(seen.keys().size(), 2, "only two framings, cut between (%s)" % [seen.keys()])
	check(seen.has(0.0) and seen.has(limit), "the west and east framings")


func test_a_prompt_follows_the_camera() -> void:
	var w := await _square()
	w.player.global_position = Vector2(757, 84)  # by the gate, in the lane
	await wait(2.0)
	await frames(3)
	check(w.get("_focused") == w.area.gate, "the gate is in reach")
	var p: Vector2 = w.hud._prompt.position
	check(p.x > 100.0 and p.x < 600.0, "the prompt is drawn on screen near the gate, not at its area x (%s)" % p)


func test_the_lamp_sees_the_crossing_not_the_bench_or_the_lane() -> void:
	var w := await _square()
	var lamp: OwnerLamp = w.area.lamp
	lamp._t = OwnerLamp.HOLD  # (any time: aim it straight at what's tested)
	var in_beam := func(p: Vector2) -> bool:
		lamp._angle = (p - lamp.global_position).angle()
		return lamp.can_see(p)
	check(in_beam.call(Vector2(668, 200)), "the crossing is in the beam")
	check(not in_beam.call(Vector2(734, 266)), "the bench under the awning hides you")
	check(not in_beam.call(Vector2(700, 70)), "the fence shelters the lane")
	check(not in_beam.call(Vector2(668, 300)), "out of reach beyond the crossing")
	check(w.is_player_hidden(Vector2(734, 266)), "the bench is a hiding place")


func test_the_lamp_turns_on_a_steady_beat_and_says_so() -> void:
	var w := await _square()
	var lamp: OwnerLamp = w.area.lamp
	var turns := 0
	var was := false
	var t := 0.0
	while t < (lamp.sweep_time + OwnerLamp.HOLD) * 2.0:
		lamp._t = t
		lamp._process(0.0)
		if lamp.is_turning() and not was:
			turns += 1
		was = lamp.is_turning()
		t += 0.05
	check_eq(turns, 2, "it holds (and ticks) before each turn")
	w.pause_owner(1.0)
	await frames(3)
	var at := lamp._t
	await wait(0.4)
	check_eq(lamp._t, at, "PAUSE holds the lamp too")


func test_the_gate_opens_from_the_lane_and_stays_open() -> void:
	var w := await _square()
	var gate: LaneGate = w.area.gate
	w.player.global_position = Vector2(757, 116)  # the crossing side
	check(gate.interact() is String and not gate.is_open(), "from the crossing it's latched")
	w.player.global_position = Vector2(757, 84)  # the lane side
	gate.interact()
	check(gate.is_open() and memory().square_gate_open, "lifted from the lane")
	await frames(4)
	var grid: NavGrid = w.area.arin.nav()
	check(grid.reaches(Vector2(757, 84), Vector2(757, 130)), "walkable through")
	memory().load_memory()
	check(memory().square_gate_open, "kept in the save")
	await go_to(w, "archive", "west")
	await go_to(w, "square", "east")
	check(w.area.gate.is_open(), "still open on the way back")
	check(w.area.lamp.arc_from < 0.0, "and the owner has turned the lamp to watch it")


func test_arin_and_the_cursor_can_cross_the_whole_square() -> void:
	var w := await _square()
	var grid: NavGrid = w.area.arin.nav()
	for p: Vector2 in [Vector2(880, 180), Vector2(734, 230), Vector2(640, 70), Vector2(320, 260)]:
		check(grid.reaches(Vector2(200, 130), p), "Arin's grid reaches %s" % p)
	check(w.area.erasure != null and w.area.bounds.end.x > 900.0, "the static's grid spans the new bounds")
	w.player.global_position = Vector2(860, 180)
	w.area._unleash()
	await frames(2)
	check(w.area.cursor.global_position.x < 500.0, "the cursor comes in far from Rue (%s)" % w.area.cursor.global_position)

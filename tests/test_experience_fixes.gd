extends "res://tests/test_case.gd"
## Fixes from the experience-polish audit (docs/EXPERIENCE_POLISH_BASELINE.md).


func test_first_visits_are_noticed() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	check(w._voiced.has("square_first"), "Rue's first line in the square plays (it never did)")
	await go_to(w, "archive", "west")
	check(w._voiced.has("archive_first"), "and in the Archive")


func test_a_refused_seam_stays_open() -> void:
	var w := await start_session()
	var seam: Seam = w.area.seam
	w.director.add_awareness(OwnerDirector.SUSPECT + 1.0)
	await frames(3)
	check(seam.open, "the seam is open")
	w.start_escort(w.area.mira)
	w.escort.global_position = seam.global_position + Vector2(-200, 120)
	w.escort.set_physics_process(false)  # Mira lags behind
	w.player.global_position = seam.global_position + Vector2(10, 0)
	await wait(0.3)
	check_eq(w.area.area_id, "room", "you wait for Mira")
	check(not seam._used, "and the seam isn't used up")
	w.escort.set_physics_process(true)
	w.escort.global_position = w.player.global_position + Vector2(-10, 4)
	await wait_until(func() -> bool: return w.area.area_id == "square", 3.0, "through the seam together")


func test_reading_is_not_standing_still() -> void:
	var w := await start_session()
	await interact_with(w, w.area.mira)
	check(w.hud.is_dialogue_open(), "talking to Mira")
	var before: float = w.player.idle_time
	await wait(1.0)
	check(w.player.idle_time - before < 0.2, "reading doesn't count toward the save-over (%.2f)" % (w.player.idle_time - before))


func test_a_question_holds_the_owner() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.route = [Vector2(560, 270)] as Array[Vector2]
	w.player.global_position = Vector2(470, 250)
	w.director.add_awareness(OwnerDirector.HUNT + 1.0)
	await wait(1.0)
	var picked := [-1]
	var ask := func() -> void: picked[0] = await w.choose_safely("Q?", ["a", "b"])
	ask.call()
	await frames(2)
	check(w.is_owner_paused(), "the owner holds while you answer")
	check(not w.area.erasure.is_processing(), "the static holds")
	var aw: float = w.director.awareness
	await wait(1.0)
	check_eq(w.director.awareness, aw, "awareness holds")
	w.hud._chosen.emit(1)
	await frames(3)
	check_eq(picked[0], 1, "the answer")
	check(not w.is_owner_paused(), "and then everything resumes")
	check(w.area.erasure.is_processing(), "the static too")


func test_mashing_cannot_pick_an_answer() -> void:
	var w := await start_session()
	var picked := [-1]
	var ask := func() -> void: picked[0] = await w.hud.choose("Q?", ["first", "second"])
	ask.call()
	await frames(3)
	await press("interact", false)
	await frames(2)
	check_eq(picked[0], -1, "a press right as the choice appears is ignored")
	await wait(Hud.CHOICE_GRACE_MS / 1000.0)
	await press("interact")
	await frames(3)
	check_eq(picked[0], 0, "a deliberate press picks")


func test_wren_stays_in_the_square_while_mira_walks_with_you() -> void:
	var w := await start_session()
	w.start_escort(w.area.mira)
	w.escort.global_position = w.player.global_position
	await go_to(w, "square", "house")
	check(w.area.wren != null, "Wren is there to hide you")


func test_pip_does_not_lead_to_the_planted_memory() -> void:
	var m := memory()
	m.found_pip = true
	m.add_fragment("controller")
	m.add_fragment("well")
	var w := await start_session()
	await go_to(w, "square", "house")
	var lie: MemoryFragment = null
	for c in w.area.get_children():
		if c is MemoryFragment and c.planted:
			lie = c
	check(lie != null, "the owner planted a memory")
	check(w.guide_target() != lie.global_position, "Pip doesn't lead you to it")


func test_areas_never_play_the_rue_ending_theme() -> void:
	var m := memory()
	for f in Story.FRAGMENTS:
		m.add_fragment(f.id)
	check_eq(Ambience._level(), MusicBox.MAX_LEVEL - 1, "five memories: one short of whole, in the world")


func test_phase_gets_through_the_dragged_crates() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.route = [Vector2(560, 270)] as Array[Vector2]
	w.glitch.unlock_all = true
	var crates: DragProp = w.area.crates
	crates.global_position = Vector2(330, 250)  # dragged across the road
	await frames(2)
	w.player.global_position = Vector2(330 - 20 - 7, 250)
	w.player._sprite.facing = Vector2.RIGHT
	await frames(2)
	var landing: Vector2 = w.glitch.phase_landing()
	check(landing != Vector2.INF, "PHASE finds the far side of the crates (as the game promises)")
	check(landing.x > 350.0, "past them, not into them (%s)" % landing)


func _hud_text(w: Node) -> String:
	var out := ""
	for q in w.hud._queue:
		out += str(q.text) + "\n"
	for l in w.hud.find_children("*", "Label", true, false):
		out += (l as Label).text + "\n"
	return out


func test_hidden_costs_say_why() -> void:
	var w := await start_session()
	await interact_with(w, w.area.mira)
	await frames(2)
	check(_hud_text(w).contains("+8  ·  talking to MIRA"), "talking to Mira shows its price and why")


func test_the_owner_warns_before_a_reload() -> void:
	var w := await start_session()
	w.director.add_awareness(OwnerDirector.NOTICE + 2.0)
	w.owner_moves._load_cd = 0.0
	for i in OwnerMoves.GLITCHES_PER_LOAD - 1:
		w.owner_moves.on_glitch("freeze")
	await frames(2)
	check(_hud_text(w).contains(Story.RELOAD_WARNING), "one glitch before the reload, the owner says so")


func test_holding_f9_mid_run_does_not_wipe() -> void:
	memory().sessions = 4
	memory().deaths = 2
	var w := await start_session()
	w.debug_forced_off = true
	Input.action_press("wipe_memory")
	await wait(World.WIPE_HOLD_TIME + 0.4)
	Input.action_release("wipe_memory")
	check_eq(memory().deaths, 2, "progress survives a held F9 outside the purge screen")


func test_screen_shake_can_be_turned_off() -> void:
	var w := await start_session()
	settings().screen_shake = false
	w.fx.shake(8.0)
	await frames(3)
	check_eq(w.get_viewport().canvas_transform, Transform2D.IDENTITY, "no shake")
	settings().screen_shake = true


func test_ws_move_through_choices() -> void:
	var w := await start_session()
	var ask := func() -> void: await w.hud.choose("Q?", ["a", "b", "c"])
	ask.call()
	await wait(Hud.CHOICE_GRACE_MS / 1000.0 + 0.05)
	var s := InputEventKey.new()
	s.physical_keycode = KEY_S
	s.pressed = true
	Input.parse_input_event(s)
	await frames(2)
	s = s.duplicate()
	s.pressed = false
	Input.parse_input_event(s)
	await frames(2)
	check_eq(w.get_viewport().gui_get_focus_owner().get_index(), 1, "S moves to the next answer")
	w.hud._chosen.emit(0)


func test_a_medium_press_still_talks() -> void:
	var w := await start_session()
	w.player.global_position = w.area.mira.global_position + Vector2(0, 14)
	await frames(3)
	await hold("interact", 0.4)  # past HOLD_START, well short of the freeze
	await frames(3)
	check(w.hud.is_dialogue_open(), "a slightly long press on Mira still talks to her")

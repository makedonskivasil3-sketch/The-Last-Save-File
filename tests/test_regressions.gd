extends "res://tests/test_case.gd"
## Bugs found in the code review of the glitch / owner / Wren / endings /
## records / bin work, one test each, so they stay fixed.


func test_closing_a_dialogue_with_e_does_not_reopen_it() -> void:
	var w := await start_session(true, true)
	await interact_with(w, w.area.mira)
	check(w.hud.is_dialogue_open(), "talking to Mira")
	for i in 30:
		if not w.hud.is_dialogue_open():
			break
		_act("interact", true)
		await frames(2)
		_act("interact", false)
		await frames(2)
	await frames(5)
	check(not w.hud.is_dialogue_open(), "the last E closes it, and it stays closed")


func test_slot_two_choice_holds_the_owner_still() -> void:
	var w := await start_session()
	w.debug("wren")
	w.debug("slot2")
	await wait_until(func() -> bool: return w.area.area_id == "edge" and not w._transitioning, 3.0, "at the Edge")
	w.escort.global_position = w.player.global_position
	w.director.add_awareness(OwnerDirector.HUNT + 1.0 - w.director.awareness)
	w.reach_slot2()
	await frames(2)
	w.owner_moves.start_save_over()
	w.owner_moves.start_wren_delete()
	await wait(OwnerMoves.WREN_DELETE_TIME + 0.5)
	check_eq(w.ending, "", "nobody dies while you choose")
	check(w.escort != null, "and Wren is still there to give the slot to")
	check(w.hud.is_choosing(), "still choosing")


func test_a_lie_wears_off() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.player.global_position = w.area.board.global_position + Vector2(0, 20)
	await frames(2)
	w.glitch._fire({"id": "falsify", "node": w.area.board, "pos": w.area.board.global_position})
	check(w.director.is_believing_lie(), "the board lies")
	w.director.forget_lie()
	var before: float = w.director.awareness
	w.area._tobben_report_lands()
	check(w.director.awareness > before, "when the owner stops believing it, Tobben's reports count again")


func test_the_crates_can_be_dragged_again() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var crates: DragProp = w.area.crates
	crates.global_position = crates.home + Vector2(0.4, -0.3)  # back "home", off by float error
	w.owner_moves._drag_cd = 0.0
	w.owner_moves._drag_back = -1.0
	w.director.add_awareness(OwnerDirector.HUNT + 1.0 - w.director.awareness)
	w.area.arin.position = Vector2(560, 280)
	w.player.global_position = VillageSquare.BLOCK_NORTH + Vector2(0, 80)
	w.owner_moves.update(0.016)
	check(w.area.cursor.is_dragging(), "a crate stack that's back home (give or take a pixel) can be dragged again")


func test_one_reload_at_a_time() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.add_awareness(OwnerDirector.NOTICE + 2.0)
	await wait(1.0)
	var loads := [0]
	for i in OwnerMoves.GLITCHES_PER_LOAD + 2:
		w.owner_moves.on_glitch("freeze")
		await wait(0.3)
	# Count rewinds over the next few seconds.
	var was := false
	for i in 120:
		var now: bool = w.owner_moves.rewinding
		if now and not was:
			loads[0] += 1
		was = now
		await frames(2)
	check_eq(loads[0], 1, "five quick glitches make the owner reload once, not twice")


func test_walking_away_from_wren_does_not_pop_the_choice() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.position = Vector2(560, 280)
	w.area.arin.route = [Vector2(560, 280)] as Array[Vector2]
	var wren: Npc = w.area.wren
	w.area._wren_line = 2  # she asks now
	await interact_with(w, wren, Vector2(14, 0))
	check(w.hud.is_dialogue_open(), "she asks")
	w.player.global_position += Vector2(0, 120)  # walk off
	await frames(10)
	check(not w.hud.is_dialogue_open(), "walking off closes the dialogue")
	check(not w.hud.is_choosing(), "without freezing you in a choice box")
	check(not w.player.frozen, "you can keep moving")


func test_a_frozen_arin_sees_nothing() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var arin: OwnerAvatar = w.area.arin
	var in_front: Vector2 = arin.global_position + arin._facing * 30.0
	check(arin.can_see(in_front), "Arin sees what's in front")
	arin.stun(2.0)
	check(not arin.can_see(in_front), "frozen, Arin sees nothing")


func test_waiting_for_wren_at_an_exit() -> void:
	var w := await start_session()
	await go_to(w, "archive", "west")
	w.debug("wren")
	w.escort.global_position = Vector2(400, 260)
	var exit_pos := Vector2(w.area.bounds.position.x - 2, 180)
	w.player.global_position = exit_pos
	await wait(0.4)
	check_eq(w.area.area_id, "archive", "you wait for Wren")
	w.escort.global_position = exit_pos + Vector2(20, 0)
	await wait_until(func() -> bool: return w.area.area_id == "square", 2.0, "leaving once she's caught up")


func test_restored_mira_brings_the_village_sound_back() -> void:
	memory().purge = 3
	memory().restored.append("mira")
	var w := await start_session()
	await go_to(w, "square", "house")
	var amb: Ambience = null
	for c in w.get_children():
		if c is Ambience:
			amb = c
	check(amb != null and is_equal_approx(amb.village_life(), 1.0), "a restored Mira counts as back (life %.2f)" % (amb.village_life() if amb else -1.0))


func test_the_title_theme_is_built_in_the_background() -> void:
	memory().runtime_cache.clear()
	tree.change_scene_to_file("res://scenes/title.tscn")
	await frames(2)
	var title := scene()
	check(not title._music.playing, "the title appears without waiting for the theme")
	await wait_until(func() -> bool: return title._music.playing, 5.0, "the theme")
	check(title._music.stream != null, "then the theme plays")


func test_closing_a_dialogue_with_the_phone_e_button_does_not_reopen_it() -> void:
	# The on-screen E button sends action events (not keys).
	var w := await start_session(true, true)
	await interact_with(w, w.area.mira)
	check(w.hud.is_dialogue_open(), "talking to Mira")
	for i in 30:
		if not w.hud.is_dialogue_open():
			break
		await press("interact")
		await frames(2)
	await frames(5)
	check(not w.hud.is_dialogue_open(), "the last E closes it, and it stays closed")


func test_closing_pips_line_does_not_reopen_it() -> void:
	memory().found_pip = true
	var w := await start_session()
	await wait_until(func() -> bool: return w.pip != null, 3.0, "Pip")
	await wait(1.0)
	w.player.global_position = w.pip.global_position + Vector2(8, 0)
	await frames(3)
	check(w._focused == w.pip, "Pip is right there")
	# Thumb taps on the phone's E button: down a few frames, up a few frames.
	var opened := false
	var reopened := false
	for k in 6:
		var was_open: bool = w.hud.is_dialogue_open()
		await _tap(3)
		var now_open: bool = w.hud.is_dialogue_open()
		if now_open:
			opened = true
		if was_open and now_open and k > 0 and w.hud._dialogue_lines.size() == 1 and _closed_between:
			reopened = true
	check(opened, "talking to Pip")
	check(not reopened, "the tap that closes Pip's line doesn't open it again")


var _closed_between := false


## One tap of the E button as an action event, held for `hold` frames;
## notes whether the dialogue was closed at any point during it.
func _tap(hold: int) -> void:
	_closed_between = false
	var w: Node = scene()
	var down := InputEventAction.new()
	down.action = "interact"
	down.pressed = true
	Input.parse_input_event(down)
	for f in hold:
		await frames(1)
		if not w.hud.is_dialogue_open():
			_closed_between = true
	var up := InputEventAction.new()
	up.action = "interact"
	up.pressed = false
	Input.parse_input_event(up)
	for f in 3:
		await frames(1)
		if not w.hud.is_dialogue_open() and f == 0:
			_closed_between = true

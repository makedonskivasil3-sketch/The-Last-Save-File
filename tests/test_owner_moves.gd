extends "res://tests/test_case.gd"
## The owner's active moves: load last save, saving over you, dragging the
## crates, Arin's route memory, and the debug tools that force them.


func test_load_last_save_drags_you_back() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var arin: OwnerAvatar = w.area.arin
	w.player.global_position = Vector2(150, 260)
	await wait(1.0)
	var earlier: Vector2 = w.player.global_position
	w.player.global_position = Vector2(480, 260)
	await wait(1.0)
	arin.stun(5.0)  # a glitch effect the reload should undo
	w.owner_moves.load_last_save()
	check(w.owner_moves.rewinding, "the owner reloads")
	check(w.hud.banner_text().begins_with("◀◀"), "and the screen says LOADING AUTOSAVE")
	await wait_until(func() -> bool: return not w.owner_moves.rewinding, 3.0, "the rewind")
	check(w.player.global_position.distance_to(earlier) < 2.0, "Rue is back where she was (%s)" % w.player.global_position)
	check_eq(arin.stunned, 0.0, "and the freeze is undone")


func test_three_glitches_make_the_owner_reload() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.add_awareness(OwnerDirector.NOTICE + 2.0)
	await wait(1.0)
	for i in OwnerMoves.GLITCHES_PER_LOAD:
		w.owner_moves.on_glitch("freeze")
	await wait_until(func() -> bool: return w.owner_moves.rewinding, 2.0, "a reload after the third glitch")


func test_saving_over_you_kills_if_you_stand_still() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.position = Vector2(560, 280)
	w.area.arin.route = [Vector2(560, 280)] as Array[Vector2]
	w.player.global_position = Vector2(150, 150)
	w.owner_moves.start_save_over()
	check(w.owner_moves.save_progress >= 0.0, "a save starts over Rue")
	await wait_until(func() -> bool: return w.ending == "death", OwnerMoves.SAVE_TIME + 2.0, "being saved over")


func test_a_glitch_interrupts_the_save() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.owner_moves.start_save_over()
	await wait(1.0)
	w.owner_moves.on_glitch("freeze")
	check(w.owner_moves.save_progress < 0.0, "any glitch breaks the save")
	check_eq(w.ending, "", "and you live")


func test_no_moves_where_the_owner_cannot_see() -> void:
	var w := await start_session()
	await go_to(w, "archive", "west")
	w.owner_moves.start_save_over()
	check(w.owner_moves.save_progress < 0.0, "no saving over you in the Archive")


func test_cursor_drags_the_crates_across_the_road() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.position = Vector2(560, 280)
	w.area.arin.route = [Vector2(560, 280)] as Array[Vector2]
	w.player.global_position = Vector2(150, 150)
	w.debug("drag")
	var blocked := false
	for i in 220:
		await wait(0.1)
		if not is_instance_valid(w):
			break
		w.owner_moves.save_progress = -1.0  # not testing that here
		var square := w.area as VillageSquare
		if square and square.crates.global_position.distance_to(VillageSquare.BLOCK_NORTH) < 1.0:
			blocked = true
			break
	check(blocked, "the cursor drags the crates across the north road")
	await frames(5)
	var sq := w.area as VillageSquare if is_instance_valid(w) else null
	check(sq != null and not sq.cursor.is_dragging(), "and drops them")


func test_arin_learns_your_routes() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	memory().note_spot("square", Vector2(520, 270))
	memory().note_spot("square", Vector2(522, 268))
	w.kill("erased")
	check(not memory().route_spots("square", 3).is_empty(), "the owner remembers where it saw you")
	var next := await wait_for_new_session(w)
	await go_to(next, "square", "house")
	check(next.area.arin.route.size() > VillageSquare.ROUTE.size(), "Arin's patrol detours through it")


func test_debug_tools() -> void:
	var w := await start_session()
	check(w.debug_enabled(), "debug tools are on in tests")
	w.debug("glitches")
	check(w.glitch.unlocked("pause"), "F5 unlocks every glitch")
	w.debug("slot2")
	await wait_until(func() -> bool: return w.area.area_id == "edge", 3.0, "F10 jumps to the Edge")
	check(w.player.global_position.distance_to(TheEdge.SLOT_POS) < 80.0, "next to Slot 2")

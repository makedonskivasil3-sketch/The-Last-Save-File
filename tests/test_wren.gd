extends "res://tests/test_case.gd"
## Wren's side story: she asks to see the Edge; escort her (slow, noticed,
## hunted) and she's saved for good, or lose her.


func _ask(w: Node) -> void:
	var wren: Npc = w.area.wren
	for i in 3:
		await interact_with(w, wren, Vector2(14, 0))
		await finish_dialogue(w)
		await frames(3)
		if w.hud.is_choosing():
			return


func test_wren_asks_and_comes_along() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.position = Vector2(560, 280)
	w.area.arin.route = [Vector2(560, 280)] as Array[Vector2]
	await _ask(w)
	check(w.hud.is_choosing(), "after a couple of talks she asks to see the Edge")
	await press("interact")  # the first option: take her
	await frames(3)
	check(w.escort != null, "she comes with you")
	await finish_dialogue(w)
	# She follows your footsteps.
	var start: Vector2 = w.escort.global_position
	w.player.global_position += Vector2(0, -30)
	await wait(0.3)
	w.player.global_position += Vector2(60, 0)
	await wait(1.6)
	check(w.escort.global_position.distance_to(start) > 30.0, "she follows you")


func test_declining_leaves_her_there() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await _ask(w)
	w.hud._chosen.emit(1)
	await frames(3)
	check(w.escort == null, "'not now' leaves her in her corner")


func test_you_cannot_leave_her_behind() -> void:
	var w := await start_session()
	w.debug("wren")
	w.player.global_position = Vector2(300, 250)
	w.escort.global_position = Vector2(140, 120)
	w.change_area("square", "house")
	await wait(0.6)
	check_eq(w.area.area_id, "room", "you have to wait for Wren before you leave")


func test_wren_sees_the_edge_and_is_saved() -> void:
	var w := await start_session()
	w.debug("wren")
	w.flags["pointer"] = true
	w.escort.global_position = w.player.global_position
	await go_to(w, "edge", "south")
	await frames(3)
	check(memory().wren_saved, "Wren saw the Edge: she's cut content now")
	check(w.escort != null, "and she's still with you, for Slot 2")
	# Even if you die now, the owner can't delete her.
	w.kill("erased")
	var next := await wait_for_new_session(w)
	await go_to(next, "square", "house")
	check(not memory().is_deleted("wren"), "the owner can never delete her again")
	check(next.area.wren.is_present(), "she's in the square next time")


func test_the_owner_deletes_her_if_you_let_it() -> void:
	var w := await start_session()
	w.debug("wren")
	w.owner_moves.start_wren_delete()
	check(w.owner_moves.wren_delete >= 0.0, "a delete ring starts over her")
	await wait_until(func() -> bool: return w.escort == null, OwnerMoves.WREN_DELETE_TIME + 2.0, "losing her")
	check(memory().is_deleted("wren"), "for good")


func test_a_glitch_saves_her() -> void:
	var w := await start_session()
	w.debug("wren")
	w.owner_moves.start_wren_delete()
	await wait(1.0)
	w.owner_moves.on_glitch("freeze")
	check(w.owner_moves.wren_delete < 0.0, "any glitch interrupts her deletion")
	check(w.escort != null, "and she's still here")


func test_a_saved_wren_still_comes_along() -> void:
	# She saw the Edge last run, then you died before Slot 2: her ending
	# must still be possible.
	memory().sessions = 3
	memory().wren_saved = true
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.position = Vector2(560, 280)
	w.area.arin.route = [Vector2(560, 280)] as Array[Vector2]
	await _ask(w)
	check(w.hud.is_choosing(), "she asks to come to the Edge again")
	await press("interact")
	await frames(3)
	check(w.escort != null, "and comes along")

extends "res://tests/test_case.gd"
## Owner AI fixes from the audit: the idle save-over, hiding everywhere
## counting as hiding, reloads and doorways, PAUSE across a doorway.


func _square(w: Node) -> void:
	await go_to(w, "square", "house")
	w.area.arin.route = [Vector2(560, 270)] as Array[Vector2]  # keep Arin out of it
	w.area.arin.position = Vector2(560, 270)


func test_standing_still_in_the_open_gets_you_saved_over() -> void:
	var w := await start_session()
	await _square(w)
	w.director.add_awareness(OwnerDirector.SUSPECT + 2.0)
	w.player.global_position = Vector2(400, 230)
	w.player.idle_time = OwnerMoves.IDLE_SAVE + 0.5
	await frames(3)
	check(w.owner_moves.save_progress >= 0.0, "under suspicion, standing still too long: the save ring starts")


func test_but_not_while_you_hide() -> void:
	var w := await start_session()
	await _square(w)
	w.director.add_awareness(OwnerDirector.SUSPECT + 2.0)
	w.player.global_position = w.area.wren.global_position + Vector2(10, 0)
	w.player.idle_time = OwnerMoves.IDLE_SAVE + 0.5
	await frames(3)
	check(w.owner_moves.save_progress < 0.0, "hiding with Wren is the answer, not the mistake")


func test_not_before_the_owner_warns_you() -> void:
	check(OwnerMoves.IDLE_SAVE > OwnerDirector.IDLE_WARN, "the warning comes first")


func test_closets_count_as_hiding() -> void:
	var w := await start_session()
	await go_to(w, "house", "front")
	w.area.next_visit = 60.0
	w.director.add_awareness(OwnerDirector.SUSPECT + 2.0)
	var before: float = w.director.awareness
	w.player.global_position = ArinsHouse.CLOSETS[0].get_center()
	await wait(1.0)
	check(w.player.sheltered, "the player knows they're hidden")
	check(w.hud._status.text.begins_with("HIDDEN"), "the HUD says so (%s)" % w.hud._status.text)
	check(w.director.awareness < before, "and the owner loses track, like beside Wren")


func test_no_doorways_mid_reload() -> void:
	var w := await start_session()
	await _square(w)
	w.owner_moves.rewinding = true
	w.change_area("archive", "west")
	await frames(3)
	check_eq(w.area.area_id, "square", "being dragged back, you can't walk out")
	w.owner_moves.rewinding = false


func test_pause_carries_through_a_doorway() -> void:
	var w := await start_session()
	await _square(w)
	w.director.add_awareness(OwnerDirector.HUNT + 1.0)
	await frames(3)
	w.pause_owner(5.0)
	await go_to(w, "edge", "south")
	check(w.is_owner_paused(), "still paused")
	check(not w.area.erasure.is_processing(), "the Edge's static holds still too")
	check(w.area.cursor.paused, "and so does the cursor")

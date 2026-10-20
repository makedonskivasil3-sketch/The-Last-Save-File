extends "res://tests/test_case.gd"
## The Edge finale reads in order and is fair (docs/GAMEPLAY_CONSISTENCY.md,
## pass 5): a safe arrival, a goal line that follows what's happening, and no
## progress gained or lost while Rue can't act.


func _at_edge(w: Node) -> TheEdge:
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	return w.area


func test_the_countdown_waits_for_the_act_card() -> void:
	var w := await start_session()
	var edge := await _at_edge(w)
	edge.grace = TheEdge.grace_time()
	w.hud.show_act("ACT V", "THE LAST SAVE FILE", "THE EDGE")
	var before := edge.grace
	var cursor_at: Vector2 = edge.cursor.global_position
	await wait(1.0)
	check(w.hud.is_act_shown(), "(the card is still up)")
	check_eq(edge.grace, before, "no countdown under the act card")
	check(edge.cursor.global_position.distance_to(cursor_at) < 0.5, "the cursor holds still while it's up")
	await wait_until(func() -> bool: return not w.hud.is_act_shown(), 8.0, "the card to go")
	await wait(0.5)
	check(edge.grace < before, "then the countdown starts")


func test_writing_neither_fills_nor_drains_behind_a_text_box() -> void:
	var w := await start_session()
	var edge := await _at_edge(w)
	edge.slot.progress = 0.3
	w.hud.show_dialogue("WREN", Color.WHITE, ["wait.", "don't go yet."])
	await wait(0.6)
	check_eq(edge.slot.progress, 0.3, "nothing drains while reading, out of the slot")
	w.player.global_position = edge.slot.global_position
	await wait(0.6)
	check_eq(edge.slot.progress, 0.3, "nothing fills while reading, in it")
	w.hud.close_dialogue()
	await wait(0.4)
	check(edge.slot.progress > 0.3, "writing resumes once Rue can act")


func test_the_goal_follows_the_confrontation() -> void:
	var w := await start_session()
	var edge := await _at_edge(w)
	edge.cursor.global_position = edge.slot.global_position + Vector2(-10, 10)
	check(edge.goal_text().contains("Lead it away"), "cursor by the slot: lead it away (%s)" % edge.goal_text())
	edge.cursor.global_position = Vector2(100, 250)
	check(edge.goal_text().begins_with("Stand in Slot 2"), "cursor away: stand in the slot")
	edge.slot.progress = 0.2
	check(edge.goal_text().contains("Stay in the slot"), "writing: stay in it")
	edge.fight = "drag"
	check(edge.goal_text().contains("dragging it away"), "the owner has it: say so")
	edge.fight = "done"
	check(edge.goal_text().contains("yours again"), "released: it's yours again")
	await wait(0.6)
	check(w.hud._objective.text.contains("yours again"), "and the HUD shows it")


func test_every_place_the_slot_can_be_is_reachable_from_the_road() -> void:
	var w := await start_session()
	var edge := await _at_edge(w)
	var road: Vector2 = edge.entries["south"]
	for spot in [TheEdge.SLOT_POS] + TheEdge.DROP_SPOTS:
		check(edge.guard_grid().reaches(road, spot), "Slot 2 at %s can be walked to from the road" % spot)


func test_menu_pause_freezes_the_whole_confrontation() -> void:
	var w := await start_session()
	var edge := await _at_edge(w)
	await wait_until(func() -> bool: return not w.hud.is_act_shown(), 8.0, "the card")
	edge.cursor.global_position = Vector2(80, 250)
	w.player.global_position = edge.slot.global_position
	edge.slot.progress = TheEdge.FIGHT_AT
	await wait_until(func() -> bool: return edge.fight == "reach", 4.0, "the reach")
	var cursor_at: Vector2 = edge.cursor.global_position
	var prog: float = edge.slot.progress
	w.open_pause()
	await wait(1.0)
	check_eq(edge.fight, "reach", "the owner's reach waits with the menu open")
	check(edge.cursor.global_position.distance_to(cursor_at) < 0.5, "the cursor holds still")
	check_eq(edge.slot.progress, prog, "and the slot neither fills nor drains")
	w._pause_menu.close()
	await wait(1.0)
	check(edge.cursor.global_position.distance_to(cursor_at) > 1.0 or edge.fight != "reach", "closing the menu lets it go on")

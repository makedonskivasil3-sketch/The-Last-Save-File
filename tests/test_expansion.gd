extends "res://tests/test_case.gd"
## Act III and friends: the well, Out of Bounds and its streaming floor, Pip,
## act cards, the map, focus brackets and the epilogue.


func test_the_well_leads_out_of_bounds() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await interact_with(w, w.area.well, Vector2(0, 6))
	await wait_until(func() -> bool: return w.area.area_id == "oob" and not w._transitioning, 3.0, "climbing into the well")
	check(w.hud.is_act_shown(), "Act III's title card shows the first time")
	check_eq(w.player.global_position, OutOfBounds.ENTRY, "you land on the first platform")


func test_owner_cannot_see_out_of_bounds() -> void:
	var w := await start_session()
	w.director.add_awareness(30.0)
	await go_to(w, "oob", "well")
	await wait(1.5)
	check(w.director.awareness < 30.0, "awareness cools out of bounds")
	check(w.area.erasure == null or not w.area.erasure.active, "no eraser down here")


func test_stepping_into_the_void_drops_you_back() -> void:
	var w := await start_session()
	await go_to(w, "oob", "well")
	w.player.global_position = Vector2(340, 150)  # nothing under here, ever
	await wait_until(func() -> bool: return w.player.global_position == OutOfBounds.ENTRY and not w.player.frozen, 3.0, "falling back")
	check_eq(w.ending, "", "falling isn't a death")
	check_eq(memory().deaths, 0, "and the owner never saw it")


func test_anchors_hold_and_chunks_stream() -> void:
	var w := await start_session()
	await go_to(w, "oob", "well")
	w.player.global_position = OutOfBounds.ANCHORS[2].get_center()
	await wait(1.0)
	check(w.player.global_position.distance_to(OutOfBounds.ANCHORS[2].get_center()) < 1.0, "anchors are always solid")
	# Every chunk is there most of the time, gone for a while, and warns first.
	var on := 0
	for i in 64:
		if OutOfBounds.chunk_present(0.0, i * OutOfBounds.PERIOD / 64.0):
			on += 1
	check(on > 32 and on < 64, "chunks come and go (%d/64 on)" % on)
	check(OutOfBounds.chunk_warning(0.0, OutOfBounds.ON - 0.1) > 0.5, "they flicker just before vanishing")


func test_finding_pip() -> void:
	var w := await start_session()
	await go_to(w, "oob", "well")
	var fox: Companion = w.area.pip
	check(fox != null and fox.mode == Companion.Mode.WAITING, "Pip is curled up on the ledge")
	await interact_with(w, fox, Vector2(-12, 0))
	check(w.hud.is_dialogue_open(), "Pip wakes up and talks")
	await finish_dialogue(w)
	await frames(3)
	check(w.pip == fox, "Pip joins you")
	check(memory().found_pip, "and that's remembered")
	await go_to(w, "square", "well")
	check(is_instance_valid(w.pip) and w.pip.is_inside_tree(), "Pip comes along to the next area")
	check(w.pip.global_position.distance_to(w.player.global_position) < 30.0, "right beside you")
	# A new session: Pip is still with you.
	w.kill("erased")
	var next := await wait_for_new_session(w)
	check(next.pip != null, "Pip is with you in every session")


func test_pip_leads_the_way() -> void:
	memory().found_pip = true
	var w := await start_session()
	await go_to(w, "archive", "west")
	var shard := Story.fragment("new_game")
	check(w.guide_target().distance_to(shard.pos) < 1.0, "Pip goes for your memories first")
	for c in w.area.get_children():
		if c is MemoryFragment:
			c.free()
	check(w.guide_target().distance_to(w.area.archivist.global_position) < 20.0, "Pip leads to the Archivist first")
	w.flags["pointer"] = true
	check(w.guide_target().x < 120.0, "then back west to the square")
	await go_to(w, "square", "east")
	check(w.guide_target().y < 50.0, "then up the north road")


func test_act_cards_show_once() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	check(w.hud.is_act_shown(), "Act II card on the first visit")
	check("square" in memory().acts_seen, "remembered")
	await go_to(w, "archive", "west")
	await go_to(w, "square", "east")
	check(not w.hud.is_act_shown(), "just the place name after that")


func test_focus_brackets_follow_what_you_can_use() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.player.global_position = w.area.well.global_position + Vector2(0, 6)
	await frames(3)
	check(w._focus_marker.target == w.area.well, "brackets on the well")
	w.player.global_position = Vector2(560, 260)
	await frames(3)
	check(w._focus_marker.target == null, "and nowhere when nothing is near")


func test_pause_map_knows_where_you_are() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await press("pause")
	await frames(2)
	check_eq(w._pause_menu.current_area, "square", "the map marks where you are")
	check(w._pause_menu.visited_areas.has("room"), "and where you've been")
	w._pause_menu._show_map()
	await frames(2)
	check(w._pause_menu._map.is_visible_in_tree(), "the map opens")
	await press("pause")
	await press("pause")


func test_true_ending_plays_the_epilogue() -> void:
	for f in Story.FRAGMENTS:
		memory().add_fragment(f.id)
	memory().found_pip = true
	var w := await start_session()
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	w.win()
	await wait_until(func() -> bool: return w.hud.is_cinematic(), 4.0, "the epilogue")
	check(not w._win_card_shown, "the end card waits for the epilogue")
	for i in 40:
		if w._win_card_shown:
			break
		await press("interact")
		await wait(0.25)
	check(w._win_card_shown, "then the end card")
	check(w.hud._overlay_title.text.contains("RUE"), "with Rue's name on it")

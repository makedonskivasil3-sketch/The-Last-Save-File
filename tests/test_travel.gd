extends "res://tests/test_case.gd"
## Travel between maps (docs/prompts/TRAVEL_AND_DEPTH_2026-10-30.md): leaving
## needs intent, no bounce back on arrival, the walk out and in, the passage
## card (long when it has something to say, short otherwise, skippable),
## people noticing her arrive, and the doorway's threshold.


func _square(travel: bool) -> Node:
	World.travel_beats_default = travel
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.paused = true
	w.area.arin.position = Vector2(560, 300)
	w.area.arin.route = [Vector2(560, 300)] as Array[Vector2]
	return w


func _east(w: Node) -> Exit:
	for e: Exit in w.area.exits:
		if e.target_area == "archive":
			return e
	return null


func test_brushing_past_a_doorway_does_not_leave() -> void:
	var w := await _square(false)
	var e := _east(w)
	check(e != null and e.outward == Vector2.RIGHT, "the east road leads out to the right")
	w.player.global_position = e.global_position + Vector2(-2, 14)
	await frames(2)
	await hold("move_up", 0.4)  # along the gap, not through it
	check_eq(w.area.area_id, "square", "walking along the doorway: still in the square")
	await hold("move_right", 0.6)
	check(await wait_until(func() -> bool: return w.area.area_id == "archive", 4.0, "through"), "walking through it: the Archive")


func test_no_bounce_straight_back() -> void:
	var w := await _square(false)
	await go_to(w, "archive", "west")
	await hold("move_left", 0.15)
	check_eq(w.area.area_id, "archive", "holding back the way she came, just arrived: she stays")
	check(not w.arrival_cleared(w.player.global_position), "the exit waits until she's moved away from where she arrived")


func test_the_passage_card_says_where_why_and_with_whom() -> void:
	var w := await _square(true)
	memory().found_pip = true
	var started := Time.get_ticks_msec()
	w.change_area("archive", "west", Vector2.RIGHT)
	check(await wait_until(func() -> bool: return w.hud.passage_shown, 3.0, "the card"), "a passage card between the maps")
	var text: String = w.hud.passage_text()
	check(text.contains(w.area.display_name.to_upper()), "the place (%s)" % text)
	check(text.contains("(") and text.length() > w.area.display_name.length() + 10, "and why she's going")
	check(w.is_owner_paused(), "threats hold while it shows")
	await wait_until(func() -> bool: return not w._transitioning, 6.0, "arrived")
	var ms := Time.get_ticks_msec() - started
	check(ms >= 1800, "a passage, not a cut: %d ms (was ~550)" % ms)
	check_eq(w.area.area_id, "archive", "in the Archive")


func test_the_same_reason_again_is_a_short_beat() -> void:
	var w := await _square(true)
	var first: Dictionary = w.passage_for("archive")
	var again: Dictionary = w.passage_for("archive")
	check_eq(first.seconds, World.PASSAGE_LONG, "something to say: the long beat")
	check_eq(again.seconds, World.PASSAGE_SHORT, "nothing new: the short one")
	check(again.why == "" and again.place != "", "the name only")


func test_a_press_ends_the_card() -> void:
	var w := await _square(true)
	w._last_passage = ""
	w.change_area("archive", "west", Vector2.RIGHT)
	await wait_until(func() -> bool: return w.hud.passage_shown, 3.0, "the card")
	var at := Time.get_ticks_msec()
	await press("interact")
	check(await wait_until(func() -> bool: return not w.hud.passage_shown, 0.6, "gone"), "a press moves on")
	check(Time.get_ticks_msec() - at < 600, "at once")


func test_she_walks_out_and_in() -> void:
	var w := await _square(true)
	var e := _east(w)
	var before: Vector2 = w.player.global_position
	w.change_area("archive", "west", e.outward)
	await frames(10)
	check(w.player.scripted.x > 0.0, "she walks out through the doorway")
	await wait_until(func() -> bool: return w.area.area_id == "archive" and w.player.scripted != Vector2.ZERO, 5.0, "walking in")
	check(w.player.scripted.x > 0.0, "and walks in from the west")
	await wait_until(func() -> bool: return not w._transitioning, 3.0, "arrived")
	check_eq(w.player.scripted, Vector2.ZERO, "then she's the player's again")
	check(not w.player.frozen, "free to move")


func test_reduced_motion_keeps_the_meaning_without_the_walk() -> void:
	settings().reduce_motion = true
	var w := await _square(true)
	w.change_area("archive", "west", Vector2.RIGHT)
	await frames(6)
	check_eq(w.player.scripted, Vector2.ZERO, "no walk")
	check(await wait_until(func() -> bool: return w.hud.passage_shown, 3.0, "the card"), "the card still says where and why")
	await wait_until(func() -> bool: return not w._transitioning, 6.0, "arrived")
	settings().reduce_motion = false


func test_people_notice_her_arrive() -> void:
	memory().meet("wren", "square")
	memory().meet("tobben", "square")
	var w := await _square(false)
	var who: Array = w.area.on_arrival(false)
	check(who.has("wren") and who.has("tobben"), "Wren and Tobben look up (%s)" % [who])
	memory().encounters.erase("tobben")
	check(not w.area.on_arrival(false).has("tobben"), "not someone she hasn't met")
	w.director.add_awareness(OwnerDirector.HUNT + 1.0 - w.director.awareness)
	check(w.area.on_arrival(false).is_empty(), "nobody waves while the owner hunts")


func test_the_doorway_lights_up_as_she_comes_near() -> void:
	var w := await _square(false)
	var e := _east(w)
	w.player.global_position = Vector2(400, 180)
	await wait(0.6)
	var far := e.glow
	w.player.global_position = e.global_position + Vector2(-20, 0)
	await wait(0.6)
	check(e.glow > far + 0.3, "brighter near the doorway (%.2f -> %.2f)" % [far, e.glow])


func test_dust_when_she_sets_off() -> void:
	var w := await _square(false)
	w.player.global_position = Vector2(400, 230)
	await wait(0.3)
	_act("move_right", true)
	await frames(6)
	var n: int = w.player.dust_count()
	_act("move_right", false)
	check(n > 0, "a puff at her feet when she sets off")

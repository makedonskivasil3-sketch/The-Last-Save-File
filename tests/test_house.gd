extends "res://tests/test_case.gd"
## Arin's house: behind the locked door in the square. UNLOCK opens it; inside,
## the second controller under the couch, and Arin coming home now and then.


func _to_square(w: Node) -> void:
	await go_to(w, "square", "house")
	w.area.arin.route = [Vector2(560, 270)] as Array[Vector2]  # keep Arin out of it
	w.area.arin.position = Vector2(560, 270)


func _readable(w: Node, title: String) -> Readable:
	for n in w.area.interactables:
		if n is Readable and n.title == title:
			return n
	return null


func test_unlock_opens_arins_front_door() -> void:
	var w := await start_session()
	await _to_square(w)
	check_eq(w.area.door.state, Door.State.LOCKED, "Arin's front door is locked")
	w.player.global_position = Vector2(111, 114)
	w.player._sprite.facing = Vector2.UP
	await frames(3)
	check_eq(w.glitch.target.get("id", ""), "unlock", "facing it offers UNLOCK")
	await hold("interact", 0.9)
	check(w.area.door.is_forced_open(), "the lock pops")
	await wait_until(func() -> bool: return w.area.area_id == "house" and not w._transitioning, 4.0, "walking into the house")
	check(w._visited.has("house"), "the house is on the map now")


func test_the_way_back_out() -> void:
	var w := await start_session()
	await go_to(w, "house", "front")
	w.area.next_visit = 60.0
	var targets: Array = []
	for e in w.area.exits:
		targets.append(e.target_area)
	check("square" in targets, "the front door leads back to the square")
	await go_to(w, "square", "house")
	check(w.player.global_position.distance_to(Vector2(111, 118)) < 4.0, "you come out on the doorstep")


func test_the_second_controller() -> void:
	var w := await start_session()
	await go_to(w, "house", "front")
	w.area.next_visit = 60.0
	var couch := _readable(w, "THE COUCH")
	check(couch != null, "the couch is there")
	var before: float = w.director.awareness
	var talk: Dictionary = couch.interact()
	check("\n".join(talk.lines).contains("PLAYER 2"), "under the couch: the second controller")
	check(memory().found_controller, "found, and remembered")
	check(w.director.awareness > before, "the owner notices you touching it")
	check(Story.secrets().any(func(s: Array) -> bool: return s[0] == "The second controller" and s[2]), "a secret in the records")
	check("\n".join(Story.slot2_recap(false)).contains("controller"), "and the owner brings it up at Slot 2")
	memory().load_memory()
	check(memory().found_controller, "it survives a reload")


func test_arin_comes_home_and_closets_hide_you() -> void:
	var w := await start_session()
	await go_to(w, "house", "front")
	var closet: Rect2 = ArinsHouse.CLOSETS[0]
	w.player.global_position = closet.get_center()
	check(w.is_player_hidden(w.player.global_position), "the closet hides you")
	check(not w.is_player_hidden(Vector2(320, 200)), "the living room doesn't")
	w.area.next_visit = 2.0
	await wait_until(func() -> bool: return w.area.arin != null, 4.0, "the door chimes and Arin walks in")
	await wait(3.0)
	check(w.ending == "", "in the closet, Arin walks right past")
	await wait_until(func() -> bool: return w.area.arin == null, ArinsHouse.VISIT_TIME + 2.0, "Arin leaving again")


func test_arin_catches_you_in_the_open() -> void:
	var w := await start_session()
	await go_to(w, "house", "front")
	w.area.next_visit = 0.1
	await wait_until(func() -> bool: return w.area.arin != null, 2.0, "Arin comes home")
	w.player.global_position = w.area.arin.global_position + Vector2(0, -6)
	await wait_until(func() -> bool: return w.ending != "", 3.0, "Arin walking into you")
	check_eq(w.ending, "death", "there's only room for one of you")


func _hold_move(action: String, seconds: float) -> void:
	Input.action_press(action)
	await wait(seconds)
	Input.action_release(action)
	await frames(2)


func test_walking_into_a_closet_hides_you_and_walking_out_ends_it() -> void:
	var w := await start_session()
	await go_to(w, "house", "front")
	w.director.paused = true
	# Both closets, each from its open side (the side facing the room).
	for closet: Rect2 in ArinsHouse.CLOSETS:
		var into := "move_up" if closet.get_center().y < 160.0 else "move_down"
		var out := "move_down" if into == "move_up" else "move_up"
		var ty: float = w.area.threshold_y(closet)
		w.player.global_position = Vector2(closet.get_center().x, ty + (14.0 if into == "move_up" else -14.0))
		await frames(3)
		check(not w.is_hidden_now(), "outside, not hidden")
		await _hold_move(into, 0.4)  # real movement input, through the open side
		check(w.is_hidden_now(), "walking in hides you")
		check(w.hud._status.text.contains("closet"), "the status says the closet hides you (%s)" % w.hud._status.text)
		await _hold_move(out, 0.5)
		check(not w.is_hidden_now(), "walking out ends it")
	check_eq(w.hud._status.text, "", "and the status clears")


func test_the_chime_leaves_time_to_reach_a_closet() -> void:
	var entry: Vector2 = ArinsHouse.new().entries["front"]
	var nearest := INF
	for c in ArinsHouse.CLOSETS:
		nearest = minf(nearest, entry.distance_to(Vector2(c.get_center().x, c.end.y - 4)))
	var walk := nearest / 90.0
	check(ArinsHouse.CHIME_LEAD >= walk + 0.8, "%.1f s of warning for a %.1f s walk plus a moment to react" % [ArinsHouse.CHIME_LEAD, walk])


func test_arin_s_house_loop_goes_through_the_doorway() -> void:
	var w := await start_session()
	await go_to(w, "house", "front")
	var route: Array[Vector2] = ArinsHouse.ARIN_ROUTE
	var space: PhysicsDirectSpaceState2D = w.get_world_2d().direct_space_state
	for i in route.size():
		var a := route[i]
		var b := route[(i + 1) % route.size()]
		var q := PhysicsRayQueryParameters2D.create(a, b, 1)
		q.exclude = [w.player.get_rid()]
		var hit: Dictionary = space.intersect_ray(q)
		check(hit.is_empty() or hit.collider is Npc, "segment %s -> %s crosses nothing solid" % [a, b])

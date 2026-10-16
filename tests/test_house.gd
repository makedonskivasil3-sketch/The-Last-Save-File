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

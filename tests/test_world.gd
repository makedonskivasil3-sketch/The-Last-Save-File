extends "res://tests/test_case.gd"
## The world end to end: the room, its seam, the square's characters, the
## Archive's pointer, the Edge and Slot 2.


func test_session_starts_in_arins_room() -> void:
	var w := await start_session()
	check_eq(w.area.area_id, "room", "start area")
	check(not w.player.frozen, "player can move after waking")
	check(w.director._running, "the owner is watching")


func test_seam_opens_at_contain_and_leads_to_square() -> void:
	var w := await start_session()
	var seam: Seam = w.area.seam
	check(not seam.open, "seam closed while the owner is calm")
	w.player.global_position = seam.global_position + Vector2(10, 0)
	await wait(0.3)
	check_eq(w.area.area_id, "room", "a closed seam can't be used")
	w.director.add_awareness(OwnerDirector.CONTAIN + 1.0)
	await frames(3)
	check(seam.open, "seam opens once the owner rewrites the room")
	await wait_until(func() -> bool: return w.area.area_id == "square", 3.0, "slipping into the square")
	check_eq(memory().session_seam, seam.id, "the seam used is remembered")


func test_door_locks_when_approached() -> void:
	var w := await start_session(true, true)
	w.player.global_position = Vector2(320, 100)
	await wait(0.3)
	check_eq(w.area.door.state, Door.State.LOCKED, "door locks")
	check(w.director.awareness >= OwnerDirector.CONTAIN, "approaching the door jumps awareness to CONTAIN")


func test_talking_to_mira_opens_dialogue() -> void:
	var w := await start_session()
	await interact_with(w, w.area.mira)
	check(w.hud.is_dialogue_open(), "dialogue box opens")
	await finish_dialogue(w)
	check(not w.hud.is_dialogue_open(), "dialogue closes")


func test_wren_hides_you_and_pays_for_it() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var wren: Npc = w.area.wren
	var near := wren.global_position + Vector2(10, 0)
	check(w.is_player_hidden(near), "standing beside Wren hides you")
	check(not w.is_player_hidden(near + Vector2(80, 0)), "away from Wren you're visible")
	check("wren" in memory().session_helpers, "the owner can find out she helped")
	w.kill("selected")
	await wait_until(func() -> bool: return memory().last_exit == "death", 2.0, "death recorded")
	check(memory().is_deleted("wren"), "Wren is deleted after you die")
	# Next session she's gone from the square.
	var w2 := await wait_for_new_session(w)
	await go_to(w2, "square", "house")
	check_eq(w2.area.wren.state, Npc.State.DELETED, "Wren stays deleted")


func test_tobben_reports_you() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.route = [Vector2(560, 270)] as Array[Vector2]  # keep Arin out of it
	await interact_with(w, w.area.tobben)
	await finish_dialogue(w)
	var before: float = w.director.awareness
	await wait(4.6)
	check(w.director.awareness >= before + 10.0, "Tobben tells the owner a few seconds later")


func test_north_road_needs_the_archivists_pointer() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	w.player.global_position = Vector2(320, 31)
	await wait(0.4)
	check_eq(w.area.area_id, "square", "north road blocked without the pointer")
	await go_to(w, "archive", "west")
	await interact_with(w, w.area.archivist, Vector2(-14, 14))
	await finish_dialogue(w)
	check(w.flags.get("pointer", false), "the Archivist gives you the pointer")
	check(memory().met_archivist, "the meeting is remembered")
	await go_to(w, "square", "east")
	w.player.global_position = Vector2(320, 31)
	await wait_until(func() -> bool: return w.area.area_id == "edge", 3.0, "taking the north road")


func test_reaching_slot_two_wins() -> void:
	var w := await start_session()
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	w.player.global_position = Vector2(580, 66)
	await wait_until(func() -> bool: return w.ending == "win", 3.0, "touching Slot 2")
	check_eq(memory().wins, 1, "win recorded")
	check_eq(memory().last_exit, "win", "session closed as a win")


func test_hunt_starts_eraser_and_cursor_in_square() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.add_awareness(OwnerDirector.HUNT + 1.0)
	await frames(3)
	check(w.area.erasure.active, "eraser running")
	check(w.area.cursor != null, "cursor sent in")

extends "res://tests/test_case.gd"
## Rue's glitch power: hold [E] to corrupt things, at a cost in awareness.


func test_tap_still_interacts() -> void:
	var w := await start_session(true, true)
	await interact_with(w, w.area.mira)
	check(w.hud.is_dialogue_open(), "a quick tap of E still talks")


func test_freeze_arin_costs_awareness() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var arin: OwnerAvatar = w.area.arin
	w.player.global_position = arin.global_position + Vector2(-30, 0)
	await frames(2)
	check_eq(w.glitch.target.get("id", ""), "freeze", "Arin is the glitch target")
	var before: float = w.director.awareness
	await hold("interact", 0.8)
	check(arin.stunned > 0.0, "holding E freezes Arin")
	check(w.director.awareness >= before + Glitch.cost("freeze") - 0.5, "and it costs awareness")
	check_eq(w.glitches_used, 1, "counted")
	var at := arin.global_position
	await wait(0.5)
	check(arin.global_position.distance_to(at) < 0.5, "a frozen Arin doesn't move")


func test_falsify_note_makes_the_owner_relax() -> void:
	var w := await start_session(true, true)
	w.player.global_position = w.area.note.global_position + Vector2(0, 20)
	await frames(2)
	check_eq(w.glitch.target.get("id", ""), "falsify", "the note can be falsified")
	await hold("interact", 0.8)
	check(w.area.note.falsified, "the note lies")
	check(w.area.note.text.begins_with("Welcome home"), "with the room's lie")
	check(w.director.is_believing_lie(), "and the owner believes it for a while")


func test_unlock_door_is_a_way_out() -> void:
	var w := await start_session(true, true)
	w.player.global_position = Vector2(320, 100)
	await wait(0.3)
	check_eq(w.area.door.state, Door.State.LOCKED, "door locked")
	w.player.global_position = Vector2(320, 64)
	await frames(2)
	await hold("interact", 0.9)
	check(w.area.door.is_forced_open(), "UNLOCK glitches it open")
	w.player.global_position = Vector2(320, 34)
	await wait_until(func() -> bool: return w.area.area_id == "square", 3.0, "walking out through the door")


func test_phase_through_a_thin_wall() -> void:
	var w := await start_session(true, true)
	# Under the table, facing up at it.
	w.player.global_position = Vector2(134, 246)
	w.player._sprite.facing = Vector2.UP
	await frames(2)
	check_eq(w.glitch.target.get("id", ""), "phase", "facing a wall offers PHASE")
	await hold("interact", 0.9)
	check(w.player.global_position.y < 216.0, "you come out on the other side (%s)" % w.player.global_position)


func test_memories_unlock_glitches() -> void:
	var w := await start_session()
	check(not w.glitch.unlocked("decoy"), "DECOY needs a memory")
	memory().add_fragment("controller")
	w._learn_glitch(1)
	check(w.glitch.unlocked("decoy"), "the first memory unlocks DECOY")
	check(w.hud.is_act_shown(), "with a big NEW GLITCH card")
	check(not w.glitch.unlocked("pause"), "PAUSE needs all five")


func test_decoy_draws_the_cursor() -> void:
	var w := await start_session()
	w.glitch.unlock_all = true
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	w.area.cursor.position = Vector2(500, 260)
	_act("move_left", true)
	await wait(0.15)
	await hold("interact", 0.9)
	_act("move_left", false)
	check(is_instance_valid(w.decoy), "running + hold leaves a decoy")
	check(w.lure_point() != Vector2.INF, "the hunters go for it")


func test_pause_stops_the_owner() -> void:
	var w := await start_session()
	w.glitch.unlock_all = true
	w.director.add_awareness(30.0)
	await go_to(w, "archive", "west")
	w.player.global_position = Vector2(150, 250)  # nothing else in reach
	await frames(2)
	check_eq(w.glitch.target.get("id", ""), "pause", "standing still offers PAUSE")
	await hold("interact", 1.2)
	check(w.is_owner_paused(), "the owner's world stops")
	check(w.hud.banner_text() != "", "and the screen says so")
	await wait(Glitch.PAUSE_TIME + 0.5)
	check(not w.is_owner_paused(), "for a few seconds")


func test_restore_brings_wren_back() -> void:
	memory().npc_fates["wren"] = "deleted"
	var w := await start_session()
	w.glitch.unlock_all = true
	await go_to(w, "square", "house")
	check_eq(w.area.wren.state, Npc.State.DELETED, "Wren is gone")
	w.area.arin.position = Vector2(440, 130)  # out of range
	w.player.global_position = w.area.wren.global_position + Vector2(14, 0)
	await frames(2)
	check_eq(w.glitch.target.get("id", ""), "restore", "her outline can be restored")
	await hold("interact", 1.6)
	check(w.area.wren.is_present(), "RESTORE brings her back")
	check(not memory().is_deleted("wren"), "for good")


func test_blind_and_scrub() -> void:
	var w := await start_session()
	w.glitch.unlock_all = true
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	var c: OwnerCursor = w.area.cursor
	w.player.global_position = Vector2(560, 120)
	c.position = Vector2(590, 120)
	await frames(2)
	check_eq(w.glitch.target.get("id", ""), "blind", "the cursor can be blinded")
	await hold("interact", 0.8)
	check(c.blinded > 0.0, "BLIND")
	await wait(0.7)
	# Scrub: void right next to you.
	c.position = Vector2(60, 60)
	w.player.global_position = Vector2(200, 260)
	w.area.erasure.seed_at(Vector2(220, 262))
	await frames(2)
	check_eq(w.glitch.target.get("id", ""), "scrub", "the eraser's void can be scrubbed")
	await hold("interact", 0.9)
	check(w.area.erasure.nearest_cell(Vector2(220, 262), 10.0) == Vector2.INF, "SCRUB wipes it")

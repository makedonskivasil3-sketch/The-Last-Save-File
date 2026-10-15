extends "res://tests/test_case.gd"
## The owner plays hard but fair: reloads never drop you into danger, the
## save ring leaves Slot 2 alone, deaths explain themselves, and the first
## glitch is taught by the first room.


func test_reload_skips_moments_next_to_the_cursor() -> void:
	var w := await start_session()
	var m: OwnerMoves = w.owner_moves
	# Ten seconds of history: the oldest moment had the cursor right on Rue.
	m._history.clear()
	m._clock = 20.0
	m._history.append({"t": 11.0, "player": Vector2(300, 200), "cursor": Vector2(305, 200)})
	m._history.append({"t": 13.0, "player": Vector2(320, 200), "cursor": Vector2(200, 100)})
	m._history.append({"t": 19.0, "player": Vector2(340, 200), "cursor": Vector2(200, 100)})
	check_eq(m._pick_snapshot(), 1, "the oldest safe moment, not the one under the cursor")
	# Arin within reach is just as bad.
	m._history[1]["arin"] = Vector2(330, 200)
	check_eq(m._pick_snapshot(), 2, "nor one beside Arin")


func test_reload_gives_you_a_beat() -> void:
	var w := await start_session()
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	var cursor: OwnerCursor = w.area.cursor
	w.player.global_position = Vector2(320, 260)
	await wait(1.0)
	w.owner_moves.load_last_save()
	await wait_until(func() -> bool: return not w.owner_moves.rewinding, 3.0, "the rewind")
	check(cursor.blinded > 0.0, "the cursor loses you for a moment after a reload")
	check_eq(cursor._select, 0.0, "and its click starts over")


func test_no_save_over_while_writing_slot_two() -> void:
	var w := await start_session()
	w.debug("slot2")
	await wait_until(func() -> bool: return w.area.area_id == "edge" and not w._transitioning, 3.0, "at the Edge")
	var slot: SlotTwo = w.area.slot
	w.area.cursor.blind(30.0)  # keep the click out of this test
	w.player.global_position = slot.global_position
	await wait(0.3)
	check(slot.is_writing(), "Rue is writing herself in")
	w.owner_moves.start_save_over()
	check_eq(w.owner_moves.save_progress, -1.0, "the owner can't start saving over you there")
	w.owner_moves.save_progress = 0.5
	await wait(0.5)
	check_eq(w.owner_moves.save_progress, 0.5, "and a save in progress holds while you write")


func test_deaths_explain_themselves() -> void:
	var w := await start_session()
	w.kill("overwritten", "arin")
	await wait(0.8)
	check(w.hud._overlay_title.text == "OVERWRITTEN", "the death card")
	check(w.hud.death_tip_text().contains("freeze"), "says what to try next, with the glitch you have for it (%s)" % w.hud.death_tip_text())
	# Before you have the glitch for it, the tip is plain advice.
	check(w.death_tip("cursor").contains("holds still"), "no BLIND yet: keep moving")
	w.glitch.unlock_all = true
	check(w.death_tip("cursor").contains("blind"), "with BLIND: use it")


func test_save_over_death_names_the_save() -> void:
	var w := await start_session()
	w.owner_moves.save_progress = 0.99
	await wait(1.0)
	check_eq(w.last_death, "save", "the save ring killed you")
	check(Story.DEATHS.save[1].contains("saved over"), "and the card says so")


func test_first_room_teaches_phase() -> void:
	var w := await start_session(true, true)
	var wall: CrackedWall = w.area.cracked
	check(wall != null and not wall.is_open(), "the room's memory is behind a cracked wall")
	check_eq(w.area.guide_point(), ArinsRoom.CRACK, "and the guide points at the crack")
	# Below the crack, facing it.
	w.player.global_position = ArinsRoom.CRACK + Vector2(0, 10)
	w.player._sprite.facing = Vector2.UP
	await frames(2)
	check_eq(w.glitch.target.get("id", ""), "phase", "the crack can be phased through")
	await hold("interact", 0.9)
	check(w.player.global_position.y < 116.0, "Rue slips through (%s)" % w.player.global_position)
	# The memory brings the wall down so you're never shut in.
	memory().add_fragment(wall.fragment_id)
	await frames(3)
	check(wall.is_open(), "once the memory is yours, the wall comes down")


func test_charging_shows_the_price() -> void:
	var w := await start_session(true, true)
	w.player.global_position = w.area.note.global_position + Vector2(0, 20)
	await frames(2)
	check(w.hud.glitch_prompt_text().contains("+%d" % int(Glitch.cost("falsify"))), "the prompt names the cost")
	_act("interact", true)
	await wait(0.3)
	check(w.hud.cost_preview() > 0.0, "while charging, the meter shows what it will cost")
	check(w.touch.hold_label != "", "and the phone's E button says HOLD")
	_act("interact", false)
	await frames(3)
	check_eq(w.hud.cost_preview(), 0.0, "the preview goes when you let go")

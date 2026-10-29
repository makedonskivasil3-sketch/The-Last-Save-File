extends "res://tests/test_case.gd"
## Wren's game (docs/production/WREN_ARC.md): warmth before sadness. She
## starts it, it has her rules, she goes to see a mark for herself (she
## never judges what she hasn't seen), refuses a bad one, fixes the R, and
## answers Rue hiding at her X without a word. The ending remembers it.


func _talk(w: Node, who: Node) -> Array:
	await interact_with(w, who)
	var said: Array = []
	for i in 12:
		if not w.hud.is_dialogue_open():
			break
		said.append(w.hud._dialogue_text.text)
		await press("interact")
		await press("interact")
		await wait(0.05)
	await frames(3)
	return said


func _square() -> Node:
	for e in ["wren.met", "wren.sheltered", "wren.lantern", "wren.promised"]:
		memory().add_event(e)
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	w.area.arin.paused = true
	w.area.arin.position = Vector2(560, 300)
	w.area.arin.route = [Vector2(560, 300)] as Array[Vector2]
	return w


func _until_wren_at(w: Node, spot: String) -> bool:
	return await wait_until(func() -> bool: return w.area._wren_at_spot == spot, 20.0, "Wren at the " + spot)


func test_her_game_her_rules() -> void:
	var w := await _square()
	var sq: VillageSquare = w.area
	check(Relationships._wren_own().is_empty(), "nothing sad before her game")
	var heard := await _talk(w, sq.wren)
	check(Relationships.WREN_GAME_START[0] in heard, "she starts it: \"You hide like a lamp post\" (%s)" % str(heard))
	check(memory().has_event("wren.game"), "kept")
	check(sq._chalk_spots.recess.can_interact() and sq._chalk_spots.crossing.can_interact(), "two places to try")
	# Rue picks the open crossing.
	sq._chalk_spots.crossing.interact()
	check(memory().has_event("wren.mark_crossing"), "Rue's mark on the crossing")
	check(not sq._chalk_spots.recess.can_interact(), "one mark at a time")
	heard = await _talk(w, sq.wren)
	check(Relationships.WREN_GAME_SHOW[1] in heard, "she won't judge it from her corner: she goes to look")
	check(not memory().has_event("wren.mark_refused"), "(no verdict yet: she hasn't seen it)")
	check(await _until_wren_at(w, "crossing"), "she walks there herself")
	check(sq.wren.global_position.distance_to(VillageSquare.CHALK_LOOK.crossing) < 2.0, "and stands beside it")
	w.player.global_position = sq.wren.global_position + Vector2(-14, 0)
	heard = await _talk(w, sq.wren)
	check(Relationships.WREN_GAME_NO[0] in heard, "the lamp goes right over it (%s)" % str(heard))
	check(memory().has_event("wren.mark_refused"), "she refuses it")
	check(not sq._chalk_spots.crossing.can_interact() and sq._chalk_spots.recess.can_interact(), "rubbed out: the awning is left")
	check(await wait_until(func() -> bool: return sq._wren_path.is_empty() and sq.wren.global_position.distance_to(VillageSquare.WREN_HOME) < 2.0, 20.0, "home"), "she walks back to her corner")
	# Now the awning.
	sq._chalk_spots.recess.interact()
	w.player.global_position = VillageSquare.WREN_HOME + Vector2(20, 0)
	await _talk(w, sq.wren)
	check(await _until_wren_at(w, "recess"), "she goes to look again")
	w.player.global_position = sq.wren.global_position + Vector2(-14, 0)
	heard = await _talk(w, sq.wren)
	check(Relationships.WREN_GAME_OK[1] in heard, "a real one, and the R is backwards (%s)" % str(heard))
	check(memory().has_event("wren.mark_ok") and memory().has_event("wren.chalk_back"), "kept; her chalk back")
	check_eq(Relationships._wren_own().get("id"), "wren.watched", "her own story can go on now")


func test_next_time_the_r_is_fixed() -> void:
	for e in ["wren.met", "wren.sheltered", "wren.game", "wren.mark_recess", "wren.mark_ok", "wren.chalk_back"]:
		memory().add_event(e)
	memory().sessions = 3
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	w.area.arin.paused = true
	w.area.arin.position = Vector2(560, 300)
	var told: Dictionary = w.area._chalk_game_lines()
	check_eq(told.get("lines", []), [Relationships.WREN_R_FIXED], "\"I fixed your R. You're welcome.\"")


func test_she_answers_rue_hiding_at_her_x() -> void:
	var w := await _square()
	memory().add_event("wren.game")
	var sq: VillageSquare = w.area
	w.player.global_position = sq.wren.global_position + Vector2(6, 2)
	await frames(2)
	check(w.hiding_npc() == sq.wren, "(hidden beside her)")
	w.director.awareness = OwnerDirector.SUSPECT + 5.0
	await frames(3)
	check(sq._nodded, "while the owner hunts, Rue hides at her X: Wren answers without a word")
	check_eq(sq.wren._emote, "shh", "(shh)")


func test_the_ending_remembers_the_game() -> void:
	memory().add_event("wren.mark_ok")
	check(Story.epilogue("escape", 0, false).has(Story.EPILOGUE_WREN_GAME), "an R under the awning, the right way round")
	check(not Story.epilogue("overwrite", 0, false).has(Story.EPILOGUE_WREN_GAME), "not in overwrite")


func test_the_gift_is_warmer_after_the_game() -> void:
	check_eq(Relationships.chalk_ask(), Relationships.WREN_CHALK_ASK, "without the game: the plain offer")
	memory().add_event("wren.chalk_back")
	check_eq(Relationships.chalk_ask(), Relationships.WREN_CHALK_ASK_AGAIN, "after lending it: for keeps this time")


## Revised 2026-10-28 (WREN_ARC.md, "Order rules"): her introduction and
## her lantern line first, then her game, then her ask to see the Edge.
func test_her_introduction_comes_first_then_her_game() -> void:
	memory().add_event("wren.met")
	var w := await start_session()
	await go_to(w, "square", "house")
	check(w.area._chalk_game_lines().is_empty(), "before her lantern line: no game yet")
	memory().add_event("wren.lantern")
	check(not w.area._chalk_game_lines().is_empty(), "then she starts it, whether or not she has hidden Rue yet")


## Between sessions she keeps drawing by her corner (her own life, not a
## quest): one more each session after the game, up to three, and Rue
## notices each once, without anything said aloud.
func test_she_keeps_drawing_between_sessions() -> void:
	memory().sessions = 4
	memory().event_at("wren.game", 4)
	check(VillageSquare.wren_doodles().is_empty(), "the session of her game: nothing new yet")
	memory().event_at("wren.game", 2)
	check_eq(VillageSquare.wren_doodles(), ["lantern", "bird"], "two sessions on: two drawings")
	memory().found_pip = true
	check_eq(VillageSquare.wren_doodles(), ["lantern", "fox"], "a fox once she's seen Pip with Rue")
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	w.area.arin.paused = true
	w.hud.clear_queue()
	w.player.global_position = VillageSquare.WREN_DOODLES.lantern[0] + Vector2(0, 8)
	await wait(0.4)
	check(memory().has_conversation("wren.doodle.lantern"), "Rue notices the lantern")
	var said := func() -> bool: return w.hud.console_history.any(func(l: String) -> bool: return l.contains("from her corner she can just see it"))
	check(await wait_until(said, 20.0, "the thought"), "and thinks it once (%s)" % str(w.hud.console_history.slice(-3)))

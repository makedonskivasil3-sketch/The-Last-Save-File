extends "res://tests/test_case.gd"
## A fresh profile reaches Wren's game through ordinary play
## (docs/production/WREN_ARC.md, "Order rules"): nothing is pre-set. Rue
## walks into the square, talks to Wren, and the game comes before Wren's ask
## to see the Edge, so a player who takes her along has played it first.
## (Before 2026-10-28 the ask came first: accepting it took Wren out of the
## square before the game could start.)


func _talk(w: Node, who: Node) -> Array:
	await interact_with(w, who)
	var said: Array = []
	for i in 14:
		if not w.hud.is_dialogue_open():
			break
		said.append(w.hud._dialogue_text.text)
		if w.hud.is_choosing():
			break
		await press("interact")
		await press("interact")
		await wait(0.05)
	await frames(3)
	return said


func _calm_square() -> Node:
	var w := await start_session()
	await go_to(w, "square", "house")
	# Arin kept across the square so no hunt interrupts the conversation
	# (the order of what she says is what's measured, not the threat).
	w.director.paused = true
	w.area.arin.paused = true
	w.area.arin.position = Vector2(560, 300)
	w.area.arin.route = [Vector2(560, 300)] as Array[Vector2]
	return w


func test_a_fresh_player_plays_her_game_before_her_ask() -> void:
	check(not memory().has_event("wren.met"), "(a fresh profile)")
	var w := await _calm_square()
	var sq: VillageSquare = w.area
	var talks := 0
	var game_at := -1
	var ask_at := -1
	for i in 6:
		var heard := await _talk(w, sq.wren)
		talks += 1
		if game_at < 0 and Relationships.WREN_GAME_START[0] in heard:
			game_at = talks
		if ask_at < 0 and Story.WREN_ASK in heard:
			ask_at = talks
		if w.hud.is_choosing() or game_at > 0:
			break
	check(game_at > 0, "her game starts by the %dth talk" % talks)
	check(ask_at < 0, "before she has asked to come to the Edge")
	check(game_at <= 3, "within three talks (%d)" % game_at)
	check(sq.wren.doing == "waiting for your mark", "her prompt says what she's waiting for (%s)" % sq.wren.doing)
	# Mark the awning the ordinary way: walk to it, press E.
	await interact_with(w, sq._chalk_spots.recess, Vector2(-8, 0))
	await frames(3)
	check(memory().has_event("wren.mark_recess"), "Rue's mark under the awning")
	w.player.global_position = VillageSquare.WREN_HOME + Vector2(18, 0)
	await wait(0.3)
	var heard := await _talk(w, sq.wren)
	check(Relationships.WREN_GAME_SHOW[1] in heard, "she goes to look (%s)" % str(heard))
	check(await wait_until(func() -> bool: return sq._wren_at_spot == "recess", 20.0, "Wren at the awning"), "she walks there")
	heard = await _talk(w, sq.wren)
	check(Relationships.WREN_GAME_OK[0] in heard, "a real one")
	check(memory().has_event("wren.chalk_back"), "her chalk is back")
	# Back at her corner, the next talks reach her ask.
	await wait_until(func() -> bool: return sq._wren_path.is_empty(), 20.0, "home")
	var asked := false
	for i in 4:
		heard = await _talk(w, sq.wren)
		if Story.WREN_ASK in heard or w.hud.is_choosing():
			asked = true
			break
	check(asked, "then she asks to come to the Edge")


func test_her_invitation_shows_before_its_explained() -> void:
	var w := await _calm_square()
	var sq: VillageSquare = w.area
	await _talk(w, sq.wren)
	await _talk(w, sq.wren)  # her lantern line
	check(memory().has_event("wren.lantern"), "(her lantern line)")
	w.player.global_position = sq.wren.global_position + Vector2(40, 0)
	await wait(0.4)
	check_eq(sq.wren.doing, "chalk out", "her chalk is out before she says why")
	check(sq.wren._emote != "", "and she holds it up when Rue comes near")

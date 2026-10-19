extends "res://tests/test_case.gd"
## Fairness fixes from the cohesion pass (docs/COHESION_PASS.md): the owner's
## reload is always announced and previewed, FREEZE means Arin when Arin is
## in reach, holds pause the Edge's countdown, and reading a tip is not
## standing still.


func test_a_reload_is_never_unannounced() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var moves: OwnerMoves = w.owner_moves
	# Three glitches before the owner has noticed you: no warning yet.
	for i in 3:
		moves.on_glitch("phase")
	w.director.add_awareness(OwnerDirector.NOTICE + 2.0 - w.director.awareness)
	await wait(1.0)
	moves.on_glitch("phase")
	await wait(1.4)
	check(not moves.rewinding and OwnerMemory.total_reloads == 0, "the glitch that would have reloaded unwarned only warns")
	check(w.hud.history.any(func(e: Dictionary) -> bool: return e.text == Story.RELOAD_WARNING), "with the owner's warning")
	check(moves.next_glitch_reloads(), "now the next one would reload")
	w.glitch.target = {"id": "phase", "node": null, "pos": w.player.global_position}
	w.glitch._update_prompt()
	check(w.hud.glitch_prompt_text().contains("RELOADS"), "and the glitch prompt says so (%s)" % w.hud.glitch_prompt_text())
	moves.on_glitch("phase")
	await wait_until(func() -> bool: return OwnerMemory.total_reloads == 1, 3.0, "the announced reload")


func test_freeze_means_arin_not_the_friend_beside_you() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var arin: OwnerAvatar = w.area.arin
	var wren: Npc = w.area.wren
	w.player.global_position = wren.global_position + Vector2(10, 0)
	arin.paused = true
	arin.global_position = w.player.global_position + Vector2(55, 0)
	await frames(3)
	var t: Dictionary = w.glitch.find_target()
	check_eq(t.get("id", ""), "freeze", "FREEZE is offered")
	check(t.get("node") == arin, "on Arin, not on Wren beside you")


func test_holds_pause_the_edge_countdown() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "edge", "south")
	var edge: TheEdge = w.area
	check(edge.grace > 0.0, "the Edge counts down")
	w.hud.show_dialogue("WREN", Color.WHITE, ["the edge is so quiet."], "npc.wren")
	await frames(2)
	var left: float = edge.grace
	await wait(1.5)
	check(absf(edge.grace - left) < 0.05, "it waits while you read (%.2f → %.2f)" % [left, edge.grace])
	await finish_dialogue(w)
	await wait(0.6)
	check(edge.grace < left - 0.3, "and carries on after")


func test_reading_a_tip_is_not_standing_still() -> void:
	settings().tutorial_tips = true
	var w := await start_session()
	w.hud.show_tip("A TIP", "a long tip about the owner, the meter and the walls, to be read at your own pace.")
	await frames(2)
	check(w.hud.is_tip_shown(), "a tip is up")
	var before: float = w.player.idle_time
	await wait(1.0)
	check(w.player.idle_time - before < 0.1, "reading it doesn't count as standing still (%.2f)" % (w.player.idle_time - before))

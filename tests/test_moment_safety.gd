extends "res://tests/test_case.gd"
## Scenes, sound state and companions behave the same however a moment ends
## (docs/GAMEPLAY_CONSISTENCY.md, pass 3).


func _mira_in_square() -> Node:
	var w := await start_session()
	w.start_escort(w.area.mira)
	w.player.global_position = w.escort.global_position + Vector2(10, 0)
	await frames(2)
	await go_to(w, "square", "house")
	return w


func test_mira_s_scene_holds_the_owner() -> void:
	var w := await _mira_in_square()
	w.director.add_awareness(OwnerDirector.HUNT + 2.0 - w.director.awareness)  # the cursor is out
	await wait(0.5)
	w.mira_pins_note.call_deferred()
	await wait_until(func() -> bool: return w.hud.is_cinematic(), 3.0, "her scene")
	await frames(2)
	check(w.is_owner_paused(), "her scene holds the owner, like a question")
	var before: float = w.director.awareness
	await wait(1.5)
	check_eq(w.ending, "", "nobody dies while she pins it")
	check_eq(w.director.awareness, before, "nor does the owner grow more aware")
	await read_through_cinematic(w)
	await wait_until(func() -> bool: return not w._cutscene, 5.0, "the scene's end")
	check_eq(memory().mira_quest, "pinned", "her note stays pinned")
	check(not w.player.frozen, "Rue can move again")
	await frames(3)
	check(not w.is_owner_paused(), "and the owner is back")


func test_muffles_do_not_cancel_each_other() -> void:
	var sfx := Sfx
	sfx.muffle(true, 500.0, "memory")
	sfx.muffle(true)  # the pause menu opens over a memory
	sfx.muffle(false)  # and closes
	var i := AudioServer.get_bus_index("Music")
	check(AudioServer.is_bus_effect_enabled(i, 0), "the memory's muffle is still on")
	sfx.muffle(false, 700.0, "memory")
	check(not AudioServer.is_bus_effect_enabled(i, 0), "and goes when the memory ends")


func test_a_new_run_starts_with_clean_sound() -> void:
	Sfx.muffle(true, 500.0, "memory")
	Sfx.duck_for_speech(true, "narration")
	var w := await start_session()
	check(Sfx._muffles.is_empty(), "nothing muffled carries in")
	check_eq(Sfx._duck_target, 0.0, "nor any duck")
	check(not AudioServer.is_bus_effect_enabled(AudioServer.get_bus_index("Music"), 0), "the music is open")
	check(w != null, "the run started")


# --- companions -------------------------------------------------------------------

func _wren(w: Node) -> Npc:
	w.start_escort(w.area.wren)
	return w.escort


func test_fidgeting_beside_her_is_not_replayed() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.paused = true
	var wren := _wren(w)
	var home := wren.global_position + Vector2(10, 0)
	for i in 40:  # small steps right beside her
		w.player.global_position = home + Vector2(sin(i * 0.7) * 5.0, cos(i * 0.7) * 5.0)
		await frames(1)
	check(w._crumbs.size() <= 2, "steps taken beside her are forgotten (%d kept)" % w._crumbs.size())
	var there := wren.global_position
	for i in 30:  # then walk away
		w.player.global_position += Vector2(2.5, 0)
		await frames(1)
	await wait(0.6)
	check(wren.global_position.x > there.x + 20.0, "she comes straight after you")


func test_she_hurries_when_far_behind() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.paused = true
	var wren := _wren(w)
	var start := wren.global_position
	# A trail 60 px long leading away from her, Rue at its end.
	for i in 12:
		w.player.global_position = start + Vector2(5.0 * (i + 1), 0)
		await frames(1)
	var t0 := wren.global_position
	await wait(0.3)
	var speed := (wren.global_position.x - t0.x) / 0.3
	check(speed > Npc.ESCORT_SPEED + 5.0, "she hurries to catch up (%.0f px/s)" % speed)


func test_she_waits_when_rue_goes_through_a_wall() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.paused = true
	var wren := _wren(w)
	var spot := wren.global_position
	w.player.phase_to(spot + Vector2(0, -90))  # through, somewhere she can't walk
	await wait(1.0)
	check(wren.global_position.distance_to(spot) < 4.0, "she doesn't walk through walls after her")
	var said := w.hud.history.any(func(e: Dictionary) -> bool: return e.text == Story.ESCORT_CUT % "wren") \
		or w.hud._queue.any(func(m: Dictionary) -> bool: return m.text == Story.ESCORT_CUT % "wren")
	check(said, "Rue notices she's been left behind")
	w.player.global_position = spot + Vector2(20, 0)  # back to her
	await frames(3)
	w.player.global_position += Vector2(40, 0)
	await wait(1.0)
	check(wren.global_position.distance_to(spot) > 15.0, "together again: she follows")

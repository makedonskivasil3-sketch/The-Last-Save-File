extends "res://tests/test_case.gd"
## Fixes from the code review after the dark-truth pass: questions that stop
## holding the owner, questions that outlive the run, LEAVE THIS BODY taking
## over FREEZE, lines that repeat per visit, a body that vanished, colours
## that didn't come back, a mute Tobben who could be heard, a crowded bin.


func _knowing() -> void:
	for f in Story.FRAGMENTS:
		memory().fragments.append(f.id)
	memory().knows_truth = true


func _square(w: Node) -> void:
	await go_to(w, "square", "house")
	var arin: OwnerAvatar = w.area.arin
	arin.paused = true
	arin.global_position = Vector2(560, 60)
	w.player.global_position = w.area.wren.global_position + Vector2(12, 0)
	await frames(3)


func test_a_question_holds_the_owner_past_the_end_of_pause() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.pause_owner(0.3)
	w.choose_safely.call_deferred("A question?", ["Yes", "No"])
	await until_choosing(w)
	await wait(1.0)
	check(w.director.owner_paused <= 0.0, "PAUSE ran out")
	check(w.is_owner_paused(), "but the question still holds the owner")
	check(w.area.arin.paused, "Arin too")
	w.hud._chosen.emit(1)
	await frames(3)
	check(not w.is_owner_paused(), "and lets go once answered")


func test_a_question_open_when_rue_dies_answers_nothing() -> void:
	_knowing()
	var w := await start_session()
	await _square(w)
	w.offer_shed.call_deferred(w.area.wren)
	await until_choosing(w)
	w.kill("erased", "arin")
	await frames(3)
	check(not w.hud.is_choosing(), "the question closes with the run")
	await wait(2.0)
	await press("interact")
	await frames(3)
	check(memory().frayed.is_empty(), "nothing was taken")
	check_eq(memory().sheds, 0, "and no body was counted")


func test_the_refusal_is_selected_first() -> void:
	_knowing()
	var w := await start_session()
	await _square(w)
	w.offer_shed.call_deferred(w.area.wren)
	await until_choosing(w)
	var focused: Control = w.hud.get_viewport().gui_get_focus_owner()
	check(focused is Button and focused.text == Story.shed_options("wren")[1], "\"Not her\" has the focus (%s)" % (focused.text if focused is Button else "none"))
	w.hud._chosen.emit(1)


func test_freeze_on_arin_beats_leaving_a_body() -> void:
	_knowing()
	var w := await start_session()
	await _square(w)
	var arin: OwnerAvatar = w.area.arin
	arin.global_position = w.player.global_position + Vector2(55, 0)
	await frames(3)
	var t: Dictionary = w.glitch.find_target()
	check_eq(t.get("id", ""), "freeze", "with Arin in reach, holding means FREEZE")


func test_the_archivist_says_it_once() -> void:
	_knowing()
	memory().met_archivist = true
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "archive", "west")
	check(w.can_shed(w.area.archivist), "she can try")
	w.offer_shed(w.area.archivist)
	await finish_dialogue(w)
	check(not w.can_shed(w.area.archivist), "once: then the hold is a glitch again near him")


func test_a_frayed_line_is_said_once_a_run_not_once_a_visit() -> void:
	memory().frayed.assign(["wren"])
	var w := await start_session()
	var count := 0
	for visit in 2:
		await go_to(w, "square", "house" if visit == 0 else "east")
		await interact_with(w, w.area.wren)
		for i in 6:
			if not w.hud.is_dialogue_open():
				break
			if w.hud._dialogue_text.text == Story.FRAY_RECALL.wren:
				count += 1
			await press("interact")
			await press("interact")
		await frames(3)
		if visit == 0:
			await go_to(w, "archive", "west")
	check_eq(count, 1, "Wren remembers it once this run")


func test_the_body_stays_where_she_left_it() -> void:
	_knowing()
	var w := await start_session()
	await _square(w)
	w.offer_shed.call_deferred(w.area.wren)
	await until_choosing(w)
	w.hud._chosen.emit(0)
	await frames(3)
	await finish_dialogue(w)
	var focus: Variant = w.get("_focused")
	check(not (focus is Husk), "the prompt stays on Wren, not on the body")
	await go_to(w, "archive", "west")
	await go_to(w, "square", "east")
	check(w.area.interactables.any(func(n: Node) -> bool: return n is Husk), "back in the square, the body is still there")
	memory().load_memory()
	check(memory().husk_in("square"), "and it's in the save")


func test_a_returned_piece_restores_the_colours() -> void:
	memory().frayed.assign(["wren"])
	var w := await start_session()
	await go_to(w, "square", "house")
	var wren: Npc = w.area.wren
	wren.sprite()
	check(wren.accent_color == wren.hair_color, "frayed: no ribbon")
	memory().frayed.clear()
	wren.refresh_fray()
	wren.sprite()
	check(wren.accent_color != wren.hair_color, "given back: the ribbon is drawn again")


func test_frayed_tobben_is_not_voiced() -> void:
	memory().frayed.assign(["tobben"])
	var w := await start_session()
	await go_to(w, "square", "house")
	check_eq(World.dialogue_voice_prefix(w.area.tobben, {}), "", "no voice id for his written lines")


func test_every_piece_fits_in_the_bin() -> void:
	memory().frayed.assign(["wren", "mira", "tobben"])
	memory().npc_fates = {"wren": "deleted", "tobben": "deleted"}
	memory().purge = 3  # Mira deleted by the purge too
	memory().met_archivist = true
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "archive", "west")
	await go_to(w, "bin", "west")
	var assets: Array = w.area.files.filter(func(f: BinFile) -> bool: return f.asset != "").map(func(f: BinFile) -> String: return f.npc_id)
	check_eq(assets.size(), 3, "all three pieces are there (%s)" % str(assets))


func test_no_body_reads_back_as_session_zero() -> void:
	memory().save_memory()
	memory().load_memory()
	check_eq(memory().husk_session, -1, "-1 stays -1 through a save")

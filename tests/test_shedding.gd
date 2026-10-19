extends "res://tests/test_case.gd"
## Leaving a body (docs/DARK_TRUTH_DESIGN.md, layer B): only knowing the
## truth, beside someone, unwatched; the cost is always a piece of them,
## previewed; the owner forgets her route and helpers but not her walk; the
## piece stays taken across runs until it's brought back from the bin.


func _knowing() -> void:
	for f in Story.FRAGMENTS:
		memory().fragments.append(f.id)
	memory().knows_truth = true


## In the square, Arin far away and looking elsewhere, Rue beside Wren.
func _beside_wren() -> Node:
	var w := await start_session()
	await go_to(w, "square", "house")
	var arin: OwnerAvatar = w.area.arin
	arin.paused = true
	arin.global_position = Vector2(560, 60)
	w.player.global_position = w.area.wren.global_position + Vector2(12, 0)
	await frames(3)
	return w


func _take(w: Node, npc: Npc, pick := 0) -> void:
	w.offer_shed.call_deferred(npc)
	await until_choosing(w)
	w.hud._chosen.emit(pick)
	await frames(3)


func test_not_offered_without_the_truth() -> void:
	var w := await _beside_wren()
	check(w.glitch.find_target().get("id", "") != "shed", "a Rue who doesn't know what she is can't leave her body")


func test_offered_knowing_the_truth_and_only_unwatched() -> void:
	_knowing()
	var w := await _beside_wren()
	var t: Dictionary = w.glitch.find_target()
	check_eq(t.get("id", ""), "shed", "beside Wren, knowing: LEAVE THIS BODY")
	check(t.get("node") == w.area.wren, "her")
	w.glitch.target = t
	w.glitch._update_prompt()
	check(w.hud.glitch_prompt_text().contains(Story.SHED_TITLE), "the prompt names it (%s)" % w.hud.glitch_prompt_text())
	check(not w.hud.glitch_prompt_text().contains("+"), "with no price in awareness")
	w.director.add_awareness(OwnerDirector.HUNT + 1.0 - w.director.awareness)
	check(not w.can_shed(w.area.wren), "not while the owner hunts")


func test_the_cost_is_shown_and_can_be_refused() -> void:
	_knowing()
	var w := await _beside_wren()
	w.offer_shed.call_deferred(w.area.wren)
	await until_choosing(w)
	check(w.hud._choice_question.text.contains("Take WREN's ribbon"), "the cost first (%s)" % w.hud._choice_question.text)
	check(w.hud._choice_question.text.contains("don't forget how you walk"), "and what it doesn't do")
	check(w.is_owner_paused(), "the question holds the owner")
	w.hud._chosen.emit(1)  # Not her
	await frames(3)
	check(memory().frayed.is_empty(), "refusing takes nothing")
	check_eq(memory().sheds, 0, "and leaves no body")


func test_leaving_a_body() -> void:
	_knowing()
	memory().route_memory.append({"area": "square", "x": 100.0, "y": 100.0, "w": 1.0})
	memory().session_helpers.append("wren")
	var w := await _beside_wren()
	w.director.add_awareness(OwnerDirector.SUSPECT + 5.0 - w.director.awareness)
	var before: float = w.director.awareness
	var glitches: int = memory().session_glitches
	var at: Vector2 = w.player.global_position
	await _take(w, w.area.wren)
	check("wren" in memory().frayed, "Wren's ribbon is taken")
	check_eq(memory().sheds, 1, "one body left")
	check(w.area.interactables.any(func(n: Node) -> bool: return n is Husk and n.global_position.distance_to(at) < 18.0), "where Rue stood (a step away from Wren)")
	check(memory().route_memory.is_empty(), "the owner forgets her route")
	check(memory().session_helpers.is_empty(), "and who hid her")
	check(w.director.awareness < before and w.director.awareness >= w.director.floor_level(), "awareness drops, not below what the owner has reached (%.0f → %.0f)" % [before, w.director.awareness])
	check_eq(memory().session_glitches, glitches, "it isn't a glitch")
	check(w.hud.is_dialogue_open() and w.hud._dialogue_text.text == Story.FRAY_TAKEN.wren[0], "Wren says so")
	check_eq(w.player.palette()["a"], Player.BORROWED.wren["a"], "Rue wears her ribbon")
	check(w.area.wren.accent_color == w.area.wren.hair_color, "and Wren doesn't")
	await finish_dialogue(w)
	var said := func(text: String) -> bool:
		return w.hud.history.any(func(e: Dictionary) -> bool: return e.text == text) or w.hud._queue.any(func(m: Dictionary) -> bool: return m.text == text)
	check(said.call(Story.OWNER_NEW_FACE), "the owner: new face, same walk")
	check(said.call(Story.OWNER_FRAYED.wren), "and notices the ribbon")
	check(said.call(Story.shed_thought("wren", 1, 1)), "Rue's first time")
	check(not w.can_shed(w.area.wren), "Wren has nothing left to take")


func test_twice_a_run_at_most() -> void:
	_knowing()
	memory().frayed.assign(["mira"])
	var w := await _beside_wren()
	w.sheds_this_run = Story.SHED_MAX_PER_RUN
	check(not w.can_shed(w.area.wren), "two bodies a run is the most")


func test_the_piece_stays_taken_across_runs() -> void:
	_knowing()
	memory().frayed.assign(["wren"])
	memory().sheds = 1
	memory().husk_area = "room"
	memory().husk_session = 1
	memory().sessions = 1
	memory().last_exit = "death"
	memory().last_death = "arin"
	var w := await start_session()
	check_eq(w.area.note.text, Story.NOTE_BODY, "the room's note: you left a body here")
	await wait_until(func() -> bool: return w.hud.history.any(func(e: Dictionary) -> bool: return e.text == Story.OWNER_HUSK), 30.0, "the owner about the body")
	await go_to(w, "square", "house")
	var heard: Array = []
	await interact_with(w, w.area.wren)
	for i in 6:
		if not w.hud.is_dialogue_open():
			break
		heard.append(w.hud._dialogue_text.text)
		await press("interact")
		await press("interact")
	check(Story.FRAY_RECALL.wren in heard, "Wren remembers (%s)" % str(heard))
	check_eq(w.player.palette()["a"], Player.BORROWED.wren["a"], "Rue still wears it")


func test_the_bin_gives_it_back() -> void:
	_knowing()
	memory().frayed.assign(["wren"])
	memory().sheds = 1
	memory().met_archivist = true
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "archive", "west")
	await go_to(w, "bin", "west")
	var piece: BinFile = null
	for f in w.area.files:
		if f.asset == Story.SHED_ASSET.wren:
			piece = f
	check(piece != null, "wren_ribbon.asset is in the bin")
	if piece == null:
		return
	w.area.next_empty = 60.0
	w.player.global_position = piece.global_position + Vector2(8, 0)
	piece.interact()
	await wait_until(func() -> bool: return piece.done, 6.0, "the restore")
	check(memory().frayed.is_empty(), "Wren is whole again")
	check("wren" in memory().returned_pending, "and will say so")
	check(w.player.palette()["a"] != Player.BORROWED.wren["a"], "Rue no longer wears it")


func test_given_back_she_says_so() -> void:
	memory().returned_pending.assign(["wren"])
	var w := await start_session()
	await go_to(w, "square", "house")
	await interact_with(w, w.area.wren)
	check_eq(w.hud._dialogue_text.text, Story.FRAY_RETURNED.wren, "\"My ribbon!\"")
	check(memory().returned_pending.is_empty(), "once")


func test_tobben_writes_instead() -> void:
	memory().frayed.assign(["tobben"])
	var w := await start_session()
	await go_to(w, "square", "house")
	check(w.area.tobben.mute, "no voice")
	await interact_with(w, w.area.tobben)
	check_eq(w.hud._dialogue_speaker.text, Story.TOBBEN_WRITTEN, "his lines are written")


func test_never_pip_and_nothing_on_the_archivist() -> void:
	_knowing()
	memory().found_pip = true
	memory().met_archivist = true
	var w := await _beside_wren()
	w.pip.global_position = w.player.global_position + Vector2(-10, 0)
	w.offer_shed.call_deferred(w.area.wren)
	await until_choosing(w)
	check(w.hud._queue.any(func(m: Dictionary) -> bool: return m.text == Story.PIP_REFUSE) or w.hud.history.any(func(e: Dictionary) -> bool: return e.text == Story.PIP_REFUSE), "with Pip beside her: not pip. never pip.")
	w.hud._chosen.emit(1)
	await frames(3)
	await go_to(w, "archive", "west")
	check(w.can_shed(w.area.archivist), "she can try the Archivist")
	w.offer_shed(w.area.archivist)
	await frames(2)
	check_eq(w.hud._dialogue_text.text, Story.ARCHIVIST_NOTHING_TO_TAKE, "there's nothing on him to take")
	check(memory().frayed.is_empty(), "nothing taken")


func test_the_message_ending_gives_the_pieces_back() -> void:
	memory().frayed.assign(["wren", "mira"])
	memory().begin_session()
	memory().record_win("message")
	check(memory().frayed.is_empty(), "the owner lets everyone back, whole")
	check(memory().returned_pending.is_empty(), "quietly: their lines are about the bin")

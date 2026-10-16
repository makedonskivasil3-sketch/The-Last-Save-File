extends "res://tests/test_case.gd"
## Phase 3, side stories: Mira's note, Tobben's guest book, Pip knowing you,
## Wren's last words.


## Talks to Mira until she asks to come along (the choice box is up).
func _until_mira_asks(w: Node) -> void:
	for i in 4:
		await interact_with(w, w.area.mira)
		await finish_dialogue(w)
		await frames(3)
		if w.hud.is_choosing():
			return


func _take_mira(w: Node) -> void:
	await _until_mira_asks(w)
	await press("interact")  # "Take her with you"
	await frames(3)
	await finish_dialogue(w)


func test_mira_asks_to_see_the_square() -> void:
	var w := await start_session(true, true)
	await _until_mira_asks(w)
	check(w.hud.is_choosing(), "after a couple of talks she asks to come")
	await press("interact")
	await frames(3)
	check_eq(w.escort_id(), "mira", "she walks with you")


func test_mira_pins_her_note_herself() -> void:
	var w := await start_session(true, true)
	await _take_mira(w)
	await go_to(w, "square", "house")
	w.area.arin.position = Vector2(560, 280)
	w.area.arin.route = [Vector2(560, 280)] as Array[Vector2]
	var before: float = w.director.awareness
	await wait(1.0)
	check(w.director.awareness > before, "out of her room, the owner can tell")
	w.escort.global_position = w.area.board.global_position + Vector2(0, 20)
	await wait_until(func() -> bool: return memory().mira_quest == "pinned", 3.0, "the board")
	await wait_until(func() -> bool: return not w._cutscene, 30.0, "her moment")
	check(w.area.board.text.begins_with("MIRA WAS HERE"), "the board says so")
	check(w.escort == null, "and she walks home on her own")
	w.kill("erased", "eraser")
	var next := await wait_for_new_session(w)
	await go_to(next, "square", "house")
	check(next.area.board.text.begins_with("MIRA WAS HERE"), "it stays up, every run")
	check(Story.recall("mira").contains("With my own hands"), "and Mira knows")


func test_the_owner_resets_mira_if_you_let_it() -> void:
	var w := await start_session(true, true)
	await _take_mira(w)
	await go_to(w, "square", "house")
	w.owner_moves.start_wren_delete()
	await wait_until(func() -> bool: return w.escort == null, OwnerMoves.MIRA_RESET_TIME + 2.0, "the reset")
	check_eq(memory().mira_quest, "reset", "reset to her defaults, for good")
	w.kill("erased", "eraser")
	var next := await wait_for_new_session(w)
	var talk: Dictionary = next.area.mira.interact()
	check("\n".join(talk.lines).contains("Welcome home, Arin"), "she doesn't know you any more")


func test_a_glitch_keeps_mira_herself() -> void:
	var w := await start_session(true, true)
	await _take_mira(w)
	await go_to(w, "square", "house")
	w.owner_moves.start_wren_delete()
	await wait(1.0)
	w.owner_moves.on_glitch("freeze")
	check(w.owner_moves.wren_delete < 0.0, "any glitch interrupts the reset")
	check_eq(w.escort_id(), "mira", "she's still with you")


func test_dying_with_mira_out_loses_her_note() -> void:
	var w := await start_session(true, true)
	await _take_mira(w)
	w.kill("erased", "eraser")
	var next := await wait_for_new_session(w)
	check_eq(memory().mira_quest, "lost", "the owner found her out of her room")
	await go_to(next, "archive", "west")
	check("\n".join(next.area._deleted_assets()).contains("note confiscated"), "the Archive logs it")
	await go_to(next, "bin", "west")
	var found := false
	for n in next.area.interactables:
		if n is Readable and n.title == "mira_note.txt":
			found = true
	check(found, "and it's in the Recycle Bin")


func test_writing_rue_back_into_the_guest_book() -> void:
	memory().sessions = 3
	memory().found_guestbook = true
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.position = Vector2(560, 280)
	w.area.arin.route = [Vector2(560, 280)] as Array[Vector2]
	await interact_with(w, w.area.tobben, Vector2(0, 14))
	await finish_dialogue(w)
	await frames(3)
	check(w.hud.is_choosing(), "Tobben's book: write the name back?")
	await press("interact")
	await wait_until(func() -> bool: return memory().guestbook_restored, 3.0, "the name")
	check(memory().guestbook_restored, "RUE is back in the book")
	await wait_until(func() -> bool: return not w.hud.is_cinematic(), 30.0, "the quiet moment")
	memory().begin_session()
	check(Story.recall("tobben").contains("Two names"), "Tobben reads them every morning")


func test_pip_knows_you_as_well_as_you_do() -> void:
	check(Story.pip_moment(0).contains("doesn't know you"), "no memories")
	check(Story.pip_moment(2).contains("raincoat"), "some")
	check(Story.pip_moment(5).contains("RUE'S"), "all: it was always your fox")


func test_wren_gets_half_a_sentence() -> void:
	var w := await start_session()
	w.debug("wren")
	w.lose_escort()
	var said := ""
	for q in w.hud._queue:
		said += str(q.text) + "\n"
	check(said.contains(Story.WREN_LAST_WORDS), "her last words")

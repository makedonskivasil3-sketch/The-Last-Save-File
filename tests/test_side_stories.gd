extends "res://tests/test_case.gd"
## Phase 3, side stories: Mira's note, Tobben's guest book, Pip knowing you,
## Wren's last words.


func _talk_until_note(w: Node) -> void:
	for i in 4:
		await interact_with(w, w.area.mira)
		await finish_dialogue(w)
		if memory().mira_quest != "":
			return


func test_mira_gives_you_her_note_and_it_gets_pinned() -> void:
	var w := await start_session(true, true)
	await _talk_until_note(w)
	check_eq(memory().mira_quest, "carried", "Mira asks you to pin her note")
	await go_to(w, "square", "house")
	w.area.arin.position = Vector2(560, 280)
	w.area.arin.route = [Vector2(560, 280)] as Array[Vector2]
	await interact_with(w, w.area.board, Vector2(0, 16))
	await finish_dialogue(w)
	check_eq(memory().mira_quest, "pinned", "pinned on the board")
	check(w.area.board.text.begins_with("MIRA WAS HERE"), "the board says so")
	# Every run after.
	w.kill("erased", "eraser")
	var next := await wait_for_new_session(w)
	await go_to(next, "square", "house")
	check(next.area.board.text.begins_with("MIRA WAS HERE"), "it stays up")
	check(Story.recall("mira").contains("pinned it"), "and Mira knows")


func test_dying_with_the_note_loses_it() -> void:
	var w := await start_session(true, true)
	await _talk_until_note(w)
	w.kill("erased", "eraser")
	var next := await wait_for_new_session(w)
	check_eq(memory().mira_quest, "lost", "the owner found it on you")
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

extends "res://tests/test_case.gd"
## Tobben's report is something you can watch (docs/production/CHARACTERS.md):
## he hesitates, walks to the notice board and writes on it; Rue can catch
## him on the way; after the guest book he scratches his own name off.


func _square() -> Node:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.paused = true
	w.area.arin.position = Vector2(560, 300)
	w.area.arin.route = [Vector2(560, 300)] as Array[Vector2]
	return w


func _talk(w: Node) -> void:
	await interact_with(w, w.area.tobben)
	await finish_dialogue(w)
	await frames(2)


func test_he_walks_to_the_board_and_writes_it_there() -> void:
	var w := await _square()
	var sq: VillageSquare = w.area
	await _talk(w)
	check(await wait_until(func() -> bool: return sq.tobben.doing == "pen in hand", 3.0, "hesitating"), "first, pen in hand")
	check(await wait_until(func() -> bool: return sq._tobben_errand == "report", 4.0, "setting off"), "then he sets off")
	check_eq(sq.tobben.doing, "going to the notice board", "and his prompt says where")
	w.player.global_position = Vector2(560, 240)  # out of his way
	check(await wait_until(func() -> bool: return sq.board.text.contains(VillageSquare.TOBBEN_SEEN), VillageSquare.REPORT_DELAY + 2.0, "the note"), "he writes it on the board")
	check(sq.tobben.global_position.distance_to(VillageSquare.TOBBEN_TO_BOARD[-1]) < 4.0, "standing at the board")
	check(await wait_until(func() -> bool: return sq.tobben.global_position.distance_to(VillageSquare.TOBBEN_HOME) < 1.0, 10.0, "home"), "and goes back to his stall")


func test_rue_can_catch_him_on_the_way() -> void:
	var w := await _square()
	var sq: VillageSquare = w.area
	await _talk(w)
	await wait_until(func() -> bool: return sq._tobben_errand == "report", 6.0, "setting off")
	await wait(0.6)
	var before: float = w.director.awareness
	await interact_with(w, sq.tobben, Vector2(0, 10))
	check(w.hud.is_dialogue_open(), "she stops him")
	check(w.hud._dialogue_text.text.contains("going for a walk"), "caught (%s)" % w.hud._dialogue_text.text)
	await finish_dialogue(w)
	check(memory().has_event("tobben.caught"), "kept: you caught him")
	await wait(VillageSquare.REPORT_DELAY)
	check(not sq.board.text.contains(VillageSquare.TOBBEN_SEEN), "nothing written")
	check(w.director.awareness < before + 10.0, "and the owner wasn't told this time")


func test_after_the_guest_book_he_scratches_his_name_off() -> void:
	memory().guestbook_restored = true
	Relationships.add("tobben.guestbook")
	memory().sessions = 2
	var w := await _square()
	var sq: VillageSquare = w.area
	check(sq.board.text.contains("TELL TOBBEN"), "(the board says to tell him)")
	await _talk(w)
	w.player.global_position = Vector2(560, 240)
	check(await wait_until(func() -> bool: return memory().has_event("tobben.crossed_out"), VillageSquare.REPORT_DELAY + 3.0, "crossed out"), "he goes to the board all the same")
	check(not sq.board.text.contains("TELL TOBBEN") and not sq.board.text.contains(VillageSquare.TOBBEN_SEEN), "and scratches his own name off, writing nothing about her (%s)" % sq.board.text)

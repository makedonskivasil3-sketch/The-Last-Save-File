extends "res://tests/test_case.gd"
## The supporting cast at gameplay scale, in their places: Tobben's stall
## and his walk to the board, Mira's corner, Pip, the Archivist. Not part
## of the suite; screenshots for review.


func _crop_note(name: String) -> void:
	await shot(name)


func test_tobben() -> void:
	memory().sessions = 2
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	w.area.arin.paused = true
	w.area.arin.position = Vector2(560, 300)
	var sq: VillageSquare = w.area
	w.player.global_position = Vector2(470, 120)
	await wait(0.8)
	await shot("c01_tobben_stall")
	await interact_with(w, sq.tobben)
	await finish_dialogue(w)
	w.player.global_position = Vector2(380, 150)
	await wait_until(func() -> bool: return sq._tobben_errand == "report", 6.0, "set off")
	await wait(1.6)
	await shot("c02_tobben_walking")
	await wait_until(func() -> bool: return sq.board.text.contains(VillageSquare.TOBBEN_SEEN), 10.0, "note")
	await wait(0.4)
	await shot("c03_tobben_at_board")

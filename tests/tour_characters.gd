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


func _mira_shot(quest: String, purge: int, name: String) -> void:
	memory().sessions = 2 if quest != "" or purge > 0 else 1
	memory().mira_quest = quest
	memory().purge = purge
	var w := await start_session()
	w.director.paused = true
	w.player.global_position = ArinsRoom.MIRA_TABLE + Vector2(-30, 40)
	await wait(1.0)
	await shot(name)


func test_mira_before() -> void:
	await _mira_shot("", 0, "m01_mira_before")


func test_mira_pinned() -> void:
	await _mira_shot("pinned", 0, "m02_mira_pinned")


func test_mira_lost() -> void:
	await _mira_shot("lost", 0, "m03_mira_lost")


func test_mira_kept() -> void:
	await _mira_shot("", 1, "m04_mira_kept")


func test_pip() -> void:
	memory().found_pip = true
	var w := await start_session()
	await wait_until(func() -> bool: return w.pip != null and w._awake, 8.0, "Pip")
	await go_to(w, "square", "house")
	w.director.paused = true
	w.area.arin.paused = true
	w.area.arin.position = Vector2(860, 300)
	w.player.global_position = Vector2(400, 250)
	await wait_until(func() -> bool: return w.pip.resting(), 12.0, "resting")
	await wait(0.5)
	await shot("p01_pip_resting")
	w.area.arin.global_position = w.player.global_position + Vector2(60, 0)
	await wait(1.4)
	await shot("p02_pip_afraid")

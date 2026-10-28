extends "res://tests/test_case.gd"
## Wren's corner three sessions after her game: her X, Rue's fixed R under
## the awning is elsewhere; here, her drawings. Screenshot for review.


func test_wren_corner() -> void:
	memory().sessions = 4
	for e in ["wren.met", "wren.lantern", "wren.mark_recess", "wren.mark_ok", "wren.chalk_back"]:
		memory().event_at(e, 1)
	memory().event_at("wren.game", 1)
	memory().found_pip = true
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	w.area.arin.paused = true
	w.player.global_position = VillageSquare.WREN_HOME + Vector2(60, -20)
	await wait(1.0)
	await shot("wren_corner")

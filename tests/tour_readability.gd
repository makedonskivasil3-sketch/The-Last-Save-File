extends "res://tests/test_case.gd"
## Interactables at gameplay scale, focused, with the name line over the
## prompt (UI-9). Not part of the suite; screenshots for review.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" $GODOT --path . -s res://tests/run_tests.gd \
##       -- --test-mode --tour --filter=tour_readability --screenshots=/some/dir


func _at(w: World, p: Vector2, name: String) -> void:
	w.player.global_position = p
	await wait(0.8)
	await shot(name)


func test_focused_objects() -> void:
	var w := await start_session()
	w.director.paused = true
	await wait(1.0)
	await _at(w, ArinsRoom.SAVE_POS + Vector2(-2, 16), "r01_room_save_point")
	await _at(w, ArinsRoom.NOTE_POS + Vector2(0, 20), "r02_room_note")
	await go_to(w, "square", "house")
	w.director.paused = true
	w.area.arin.paused = true
	var square: VillageSquare = w.area
	await _at(w, square.well.global_position + Vector2(0, 8), "r03_square_well")
	await _at(w, square.rim.global_position + Vector2(0, -8), "r04_square_rim")
	if square.wren:
		await _at(w, square.wren.global_position + Vector2(14, 0), "r05_square_wren")
	await _at(w, square.board.global_position + Vector2(0, 18), "r06_square_board")

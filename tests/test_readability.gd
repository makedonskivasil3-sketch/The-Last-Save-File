extends "res://tests/test_case.gd"
## What you are about to touch is named (docs/production/ISSUE_REGISTER.md
## UI-9): the prompt says what [E] does, and a line over it says what the
## thing is, so nothing is interacted with blind.


func _focus_on(w: World, at: Vector2) -> void:
	w.director.paused = true
	if w.area.get("arin"):
		w.area.arin.paused = true
	w.player.global_position = at
	await wait(0.3)


func test_the_room_names_its_things() -> void:
	var w := await start_session()
	await _focus_on(w, ArinsRoom.SAVE_POS + Vector2(0, 14))
	check_eq(w.hud.prompt_name(), "SAVE POINT", "beside the crystal")
	await _focus_on(w, ArinsRoom.MIRA_POS + Vector2(0, 14))
	check_eq(w.hud.prompt_name(), "MIRA", "beside Mira, her name")


func test_the_square_names_the_well_and_wren() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var square: VillageSquare = w.area
	await _focus_on(w, square.well.global_position + Vector2(0, 6))
	check_eq(w.hud.prompt_name(), "THE WELL", "in front of the well")
	await _focus_on(w, square.rim.global_position + Vector2(0, -6))
	check_eq(w.hud.prompt_name(), "THE WELL'S RIM", "behind it, its rim")
	if square.wren:
		await _focus_on(w, square.wren.global_position + Vector2(12, 0))
		check_eq(w.hud.prompt_name(), "WREN", "beside Wren")


func test_the_chalk_spots_say_where_they_are() -> void:
	var a := ChalkSpot.new()
	a.id = "recess"
	var b := ChalkSpot.new()
	b.id = "crossing"
	check_eq(World.object_name(a), "under the awning", "the sheltered spot")
	check_eq(World.object_name(b), "out on the crossing", "the exposed one says so before you choose")
	a.free()
	b.free()


func test_nothing_named_shows_no_name_line() -> void:
	var w := await start_session()
	w.hud.set_prompt("", Vector2.INF, "THE WELL")
	check_eq(w.hud.prompt_name(), "", "no prompt, no name")

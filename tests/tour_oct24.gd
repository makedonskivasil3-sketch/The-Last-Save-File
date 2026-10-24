extends "res://tests/test_case.gd"
## Review captures for 24 October (docs/REVIEW_OCT24.md). The same stops run
## on the old head for "before". Not playtest evidence. Run with
## --tour --filter=tour_oct24 --screenshots=<directory>.


func _quiet() -> void:
	settings().reduce_flashing = true
	settings().glitch_intensity = 0.0
	settings().tutorial_tips = false


func test_square_after_mira_and_tobben() -> void:
	_quiet()
	OwnerMemory.mira_quest = "pinned"
	OwnerMemory.guestbook_restored = true
	var w := await start_session()
	await go_to(w, "square", "house")
	w.player.global_position = Vector2(300, 110)
	await wait(1.2)
	await shot("square_board_and_stall")


func test_archive_arrival() -> void:
	_quiet()
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "archive", "west")
	await wait(1.2)
	await shot("archive_arrival")


func test_wren_waves() -> void:
	_quiet()
	var w := await start_session()
	await go_to(w, "square", "house")
	var wren: Node2D = w.area.wren
	w.player.global_position = wren.global_position + Vector2(56, 0)
	w.area.arin.global_position = w.player.global_position + Vector2(90, 10)
	await wait(0.5)
	await shot("wren_waves")


func test_room_save_point_own_press() -> void:
	_quiet()
	var w := await start_session()
	for i in 3:
		await interact_with(w, w.area.save_point, Vector2(0, 12))
		await wait(1.0)
	await wait(0.2)
	await shot("room_own_press")


## Everything that can sit on screen at once, at the largest text, with the
## touch controls shown: the act card, a tip, a dialogue, the objective.
func test_ui_stack_at_max_text() -> void:
	settings().large_text = true
	settings().subtitle_size = 2
	settings().tutorial_tips = true
	settings().using_touch = true
	var w := await start_session()
	w.hud.apply_subtitle_style()
	await go_to(w, "square", "house", false)
	w.hud.show_tip("HIDE", "Stand beside Wren while Arin passes. The owner can't see what she stands beside.")
	await wait(0.5)
	await shot("ui_max_text_card_and_tip")
	w.hud.dismiss_title()
	await interact_with(w, w.area.wren)
	await wait(1.0)
	await shot("ui_max_text_dialogue_and_tip")
	w.hud.close_dialogue()
	settings().large_text = false
	settings().subtitle_size = 0
	settings().using_touch = false


## Motion: Rue starting, stopping, turning (30 frames a second of game time),
## then Wren waving her over as Arin comes. Frames: <clip>_NNN.png.
func _clip(name: String, seconds: float, each: Callable = Callable()) -> void:
	for i in int(seconds * 30.0):
		if each.is_valid():
			each.call(i)
		await wait(1.0 / 30.0)
		await shot("%s_%03d" % [name, i])


func test_motion_start_stop_and_wave() -> void:
	_quiet()
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	w.area.arin.paused = true
	w.area.arin.global_position = Vector2(60, 300)
	w.player.global_position = Vector2(300, 200)
	await _clip("motion_start_stop", 3.0, func(i: int) -> void:
		if i == 6: Input.action_press("move_right")
		if i == 30: Input.action_release("move_right")
		if i == 45: Input.action_press("move_left")
		if i == 60: Input.action_release("move_left"))
	var wren: Node2D = w.area.wren
	w.player.global_position = wren.global_position + Vector2(64, 0)
	w.area.arin.paused = false
	w.area.arin.global_position = w.player.global_position + Vector2(150, 10)
	await _clip("motion_wave", 2.5, func(i: int) -> void:
		if i == 30: Input.action_press("move_left")
		if i == 48: Input.action_release("move_left"))

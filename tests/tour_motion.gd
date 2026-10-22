extends "res://tests/test_case.gd"
## Short in-engine motion clips at normal speed (10 frames a second of game
## time), for docs/REVIEW_OCT22.md: walking and stopping, an escort
## following, a conversation typing out and then waiting, Tobben at his
## wares. Not part of the suite. Frames: <clip>_NNN.png.


func _clip(name: String, seconds: float, each: Callable = Callable()) -> void:
	for i in int(seconds * 10.0):
		if each.is_valid():
			each.call(i)
		await wait(0.1)
		await shot("%s_%03d" % [name, i])


func test_motion_clips() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	w.area.arin.global_position = Vector2(60, 280)
	w.area.arin.paused = true
	# 1. Rue walks east along the road, then stops (the settle).
	w.player.global_position = Vector2(200, 190)
	await _clip("walk", 2.4, func(i: int) -> void:
		if i == 0: Input.action_press("move_right")
		if i == 14: Input.action_release("move_right"))
	# 2. Tobben at his wares (no one close), then waving as Rue comes near.
	w.player.global_position = Vector2(560, 200)
	await _clip("tobben", 2.0, func(i: int) -> void:
		if i == 10: w.player.global_position = Vector2(500, 120))
	# 3. A conversation: Wren's line types out, then waits after it's shown.
	w.player.global_position = w.area.wren.global_position + Vector2(0, 14)
	await frames(3)
	await press("interact")
	await _clip("dialogue", 3.0)
	await finish_dialogue(w)
	# 4. Wren following: start the escort and walk.
	w.start_escort(w.area.wren)
	w.player.global_position = Vector2(200, 240)
	await _clip("escort", 2.4, func(i: int) -> void:
		if i == 0: Input.action_press("move_right")
		if i == 20: Input.action_release("move_right"))

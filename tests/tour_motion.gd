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


## 5. A return after a death: Arin's touch, the dissolve, the reload, and
## Rue waking in the room (the clip the review listed as not captured).
func test_return_after_death_clip() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	w.player.global_position = Vector2(300, 200)
	await frames(3)
	w.kill("overwritten", "arin")
	# The card waits for retry: pressed after 3.5 s, as a player reading it would.
	await _clip("death_return_a", 3.5)
	await press("interact")
	await _clip("death_return_b", 6.5)


## 6. The opening at a person's pace: "you" on her controller, walking her
## to Arin at the save point, the press (the shared hop), 87%, her hands
## going slack, PAUSE, "you" lifting onto the figure, and her walking with
## the controller dark. 10 frames a second of game time.
func test_opening_clip() -> void:
	settings().opening_seen = false
	var film := Opening.new()
	film.replay = true
	var old := tree.current_scene
	tree.root.add_child(film)
	tree.current_scene = film
	if old:
		old.queue_free()
	await wait(0.5)
	film._t = 4.5
	await _clip("opening_a", 2.0)  # the ritual asks; "you" on the controller
	Input.action_press("move_right")
	await _clip("opening_b", 5.0)
	Input.action_release("move_right")
	await press("interact")
	await _clip("opening_c", 3.0)  # the press, together; the save starts
	film._t = 10.6
	await _clip("opening_d", 2.0)  # 87%
	await press("interact")
	await _clip("opening_e", 4.0)  # refused; her hands go slack
	film._t = 22.9
	await _clip("opening_f", 1.5)  # PAUSE; "you" lifts onto her
	Input.action_press("move_left")
	await _clip("opening_g", 4.0)  # she walks; her controller stays dark
	Input.action_release("move_left")
	film._finish()

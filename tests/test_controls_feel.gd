extends "res://tests/test_case.gd"
## Controls (docs/prompts/PLAYER_EXPERIENCE_PASS_2026-11-02.md, C1 and C2):
## corner assist and the early-press buffer. Both were measured first:
## clipping a bench corner by 1 px stopped Rue dead, and an [E] pressed
## 0.1 s before she came in reach did nothing.


func _workshop() -> World:
	var w: World = await start_session()
	await go_to(w, "workshop", "stairs")
	await frames(3)
	return w


## How far Rue's body is inside the west bench (px²): touching is 0.
func _overlap(w: World) -> float:
	var shape := w.player.get_node("CollisionShape2D") as CollisionShape2D
	var half: Vector2 = (shape.shape as RectangleShape2D).size * 0.5
	var body := Rect2(w.player.global_position + shape.position - half, half * 2.0)
	return body.intersection(Rect2(150, 100, 66, 12)).get_area()


func _walk(dir: String, seconds: float) -> void:
	Input.action_press(dir)
	await wait(seconds)
	Input.action_release(dir)
	await frames(2)


func test_she_rounds_a_corner_she_only_clips() -> void:
	var w := await _workshop()
	# The west bench is Rect2(150, 100, 66, 12); Rue's body is 8 x 8.
	for overlap in [1, 2, 3, 4]:
		w.player.global_position = Vector2(146 + overlap, 140)
		await frames(2)
		var fits := true
		Input.action_press("move_up")
		var t := 0.0
		while t < 1.2:
			await frames(1)
			t += tree.root.get_process_delta_time()
			fits = fits and _overlap(w) < 0.5
		Input.action_release("move_up")
		await frames(2)
		check(w.player.global_position.y < 100.0, "clipping by %d px, she gets past the bench (at %s)" % [overlap, w.player.global_position])
		check(w.player.global_position.x <= 146.0, "by going round its corner, not through it")
		check(fits, "never inside the bench on the way")


func test_a_corner_she_walks_squarely_into_stays_solid() -> void:
	var w := await _workshop()
	w.player.global_position = Vector2(170, 140)  # well inside the bench's width
	await frames(2)
	await _walk("move_up", 0.8)
	check(w.player.global_position.y > 112.0, "blocked by the bench (y %.1f)" % w.player.global_position.y)
	check(absf(w.player.global_position.x - 170.0) < 0.5, "and not nudged sideways (x %.1f)" % w.player.global_position.x)


func test_a_long_wall_stays_a_wall() -> void:
	var w := await _workshop()
	w.player.global_position = Vector2(250, 60)
	await frames(2)
	await _walk("move_up", 0.8)
	check(absf(w.player.global_position.x - 250.0) < 0.5, "pressing into the top wall never slides her along it (x %.1f)" % w.player.global_position.x)


func test_diagonals_are_left_alone() -> void:
	var w := await _workshop()
	w.player.global_position = Vector2(147, 140)
	await frames(2)
	var before: int = w.player.corner_assists
	Input.action_press("move_up")
	Input.action_press("move_right")
	await wait(0.4)
	Input.action_release("move_up")
	Input.action_release("move_right")
	await frames(2)
	check_eq(w.player.corner_assists, before, "a diagonal already slides on its own")


func test_an_early_press_is_kept_for_a_moment() -> void:
	var w := await _workshop()
	var room: LanternWorkshop = w.area
	w.player.global_position = room.lamp.global_position + Vector2(0, 40)
	await frames(3)
	Input.action_press("move_up")
	var pressed := false
	for i in 120:
		await frames(1)
		var d := w.player.global_position.distance_to(room.lamp.global_position)
		if not pressed and d < World.INTERACT_DISTANCE + 9.0:
			pressed = true
			check(w._focused == null, "pressed before the lamp is in reach")
			w.tap_interact()
		if d < World.INTERACT_DISTANCE - 4.0:
			break
	Input.action_release("move_up")
	await frames(3)
	var said: Array = (w.hud.history + w.hud._queue).map(func(h: Dictionary) -> String: return str(h.text))
	check(said.any(func(s: String) -> bool: return s.contains("Cold glass")), "the early press is used once she arrives")


func test_a_press_with_nothing_near_expires() -> void:
	var w := await _workshop()
	var room: LanternWorkshop = w.area
	w.player.global_position = room.lamp.global_position + Vector2(0, 60)
	await frames(3)
	w.tap_interact()
	await wait(0.35)
	w.player.global_position = room.lamp.global_position + Vector2(0, 12)
	await frames(6)
	var said: Array = (w.hud.history + w.hud._queue).map(func(h: Dictionary) -> String: return str(h.text))
	check(not said.any(func(s: String) -> bool: return s.contains("Cold glass")), "a stale press does nothing")


func test_a_press_never_carries_into_the_next_place() -> void:
	var w := await _workshop()
	w.tap_interact()
	check(w._tap_buffered >= 0, "buffered")
	w.change_area("archive", "workshop")
	check_eq(w._tap_buffered, -1, "dropped when she leaves")

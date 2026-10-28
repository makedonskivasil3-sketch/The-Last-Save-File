extends "res://tests/test_case.gd"
## Movement (docs/production/MOVEMENT_SPEC.md): one specification for the
## festival and the game. Rue stops where she's sent, never passes through
## thin things on a long frame, animates what she actually travels, and
## keeps her facing steady on near-diagonal input.


func _festival() -> Prologue:
	settings().opening_seen = false
	var p := Prologue.new()
	var old := tree.current_scene
	tree.root.add_child(p)
	tree.current_scene = p
	if old:
		old.queue_free()
	await frames(2)
	p.autoplay = false
	p._rue_free = true
	return p


func _end(p: Prologue) -> void:
	p._done = true
	p._handed_off = true
	p.queue_free()
	await frames(2)


# --- D1: pointer arrival -----------------------------------------------------------

func test_a_pointer_target_is_reached_and_held() -> void:
	var p := await _festival()
	p.rue_pos = Vector2(200, 260)
	p._walk_to = Vector2(204.5, 260)
	var xs: Array[float] = []
	for i in 8:
		p._move_rue(0.1)
		xs.append(p.rue_pos.x)
	check(absf(xs[0] - 204.5) < 0.01, "the first 0.1 s step stops on the target, not past it (%s)" % str(xs))
	check(xs.all(func(x: float) -> bool: return absf(x - 204.5) < 0.01), "and stays there: no oscillation (%s)" % str(xs))
	check(p._walk_to == Vector2.INF, "the destination is done with")
	check(p._rue_vel.length() < 0.01, "and nothing is still walking")
	await _end(p)


func test_any_frame_length_arrives_without_overshoot() -> void:
	var p := await _festival()
	for dt in [1.0 / 144.0, 1.0 / 60.0, 1.0 / 30.0, 0.1, 0.25]:
		p.rue_pos = Vector2(200, 260)
		p._walk_to = Vector2(237.3, 251.0)
		var worst := 0.0
		for i in 200:
			p._move_rue(dt)
			worst = maxf(worst, p.rue_pos.x - 237.3)
			if p._walk_to == Vector2.INF:
				break
		check(p.rue_pos.distance_to(Vector2(237.3, 251.0)) < 0.01, "%.3f s frames: arrives (%s)" % [dt, p.rue_pos])
		check(worst < 0.01, "%.3f s frames: never past it (%.2f)" % [dt, worst])
	await _end(p)


func test_a_lantern_tap_lights_once_on_arrival() -> void:
	var p := await _festival()
	var fired := [0]
	p.rue_pos = Prologue.LANTERNS[1] + Vector2(-30, 14)
	p._walk_to = Prologue.LANTERNS[1] + Vector2(0, 14)
	p._act_queued = true
	for i in 40:
		var was: bool = p._act_queued
		p._move_rue(0.05)
		if was and not p._act_queued:
			fired[0] += 1
	check_eq(fired[0], 1, "the queued interaction fires once, at arrival")
	await _end(p)


func test_an_unreachable_target_stops_and_says_so() -> void:
	var p := await _festival()
	# Inside the closed fence, from outside: the fence is in the way.
	p.lit[0] = false
	p.arin_pos = Vector2(300, 300)
	p.rue_pos = Vector2(130, 140)
	p._walk_to = Vector2(80, 140)
	var steps := 0
	for i in 100:
		p._move_rue(0.05)
		steps += 1
		if p._walk_to == Vector2.INF:
			break
	check(p._walk_to == Vector2.INF and steps < 40, "she gives up within two seconds (%d steps)" % steps)
	check(p._emotes.has("rue"), "and shows she can't get there (%s)" % str(p._emotes))
	check(not Prologue.FENCE.grow(-1).has_point(p.rue_pos), "without going through the fence")
	await _end(p)


func test_keys_take_over_from_a_pointer_target() -> void:
	var p := await _festival()
	p.rue_pos = Vector2(200, 260)
	p._walk_to = Vector2(300, 260)
	Input.action_press("move_up")
	p._move_rue(0.1)
	Input.action_release("move_up")
	check(p._walk_to == Vector2.INF, "a key press cancels the destination")
	check(p.rue_pos.y < 260.0 and absf(p.rue_pos.x - 200.0) < 0.01, "and moves only where the key says")
	await _end(p)


# --- D2: thin objects on long frames ------------------------------------------------

func test_the_closed_gate_holds_on_a_long_frame() -> void:
	var p := await _festival()
	p.lit[0] = false
	p.arin_pos = Vector2(300, 300)
	check(not p._gate_open(), "(the gate is closed)")
	var x := Prologue.GATE.get_center().x
	for dt in [0.12, 0.25, 0.5]:
		p.rue_pos = Vector2(x, Prologue.GATE.end.y + 3.5)  # just outside, below
		Input.action_press("move_up")
		p._move_rue(dt)
		Input.action_release("move_up")
		check(p.rue_pos.y - 3.0 >= Prologue.GATE.end.y - 0.01, "%.2f s frame: still outside the gate (y %.1f)" % [dt, p.rue_pos.y])
	await _end(p)


func test_corners_slide_the_same_whichever_way() -> void:
	var p := await _festival()
	# Into the well's corner diagonally, from both sides.
	var well := Prologue.WELL
	var results := []
	for d in [Vector2(1, 1), Vector2(-1, 1)]:
		var start := Vector2(well.position.x - 6.0, well.position.y - 6.0) if d.x > 0 else Vector2(well.end.x + 6.0, well.position.y - 6.0)
		p.rue_pos = start
		for i in 20:
			p.rue_pos = p._slide(p.rue_pos, d.normalized() * 2.0, true)
		results.append(p.rue_pos - start)
		check(not well.intersects(Rect2(p.rue_pos - Vector2(4, 3), Vector2(8, 6))), "no penetration (%s)" % p.rue_pos)
	check(absf(absf(results[0].x) - absf(results[1].x)) < 0.6 and absf(results[0].y - results[1].y) < 0.6, "mirror-image slides match (%s)" % str(results))
	await _end(p)


# --- D3: intent vs actual motion -----------------------------------------------------

func test_pushing_into_a_wall_is_not_walking() -> void:
	var p := await _festival()
	p.rue_pos = Vector2(Prologue.WELL.get_center().x, Prologue.WELL.position.y - 3.5)
	Input.action_press("move_down")
	for i in 6:
		p._process(0.05)
	var vel: Vector2 = p._rue_vel
	var moving: bool = p.rue.moving
	var facing: Vector2 = p.rue.facing
	Input.action_release("move_down")
	check(vel.length() < 0.01, "no velocity against the well (%s)" % vel)
	check(not moving, "so no walk cycle")
	check_eq(facing, Vector2.DOWN, "but she faces where she's pushing")
	await _end(p)


func test_the_game_too_animates_actual_motion() -> void:
	var w := await start_session()
	var p: Player = w.player
	# Into the room's bottom wall.
	for i in 40:
		Input.action_press("move_down")
		await frames(1)
	await frames(3)
	var moving: bool = p._sprite.moving
	var facing: Vector2 = p._sprite.facing
	Input.action_release("move_down")
	check(not moving, "against the wall: not walking")
	check_eq(facing, Vector2.DOWN, "facing the wall")


# --- D5: facing ---------------------------------------------------------------------

func test_near_diagonal_input_doesnt_flicker_facing() -> void:
	var c := HeroFigure.new("rue", Player.RUE)
	c.facing = Vector2.RIGHT
	var flips := 0
	var last := c.facing
	for i in 40:
		var v := Vector2(60.0, 58.0) if i % 2 == 0 else Vector2(58.0, 60.0)
		c.update(1.0 / 60.0, v)
		if c.facing != last:
			flips += 1
			last = c.facing
	check(flips <= 1, "wobbling around 45° keeps one facing (%d flips)" % flips)
	c.update(1.0 / 60.0, Vector2(-80, 0))
	check_eq(c.facing, Vector2.LEFT, "a deliberate turn is immediate")
	c.update(1.0 / 60.0, Vector2(0, 80))
	check_eq(c.facing, Vector2.DOWN, "so is a clear change of axis")


# --- D6: gait -----------------------------------------------------------------------

func test_the_stride_follows_distance() -> void:
	var c := HeroFigure.new("rue", Player.RUE)
	for speed in [18.0, 45.0, 90.0]:
		c._walk = 0.0
		for i in 60:
			c.update(1.0 / 60.0, Vector2(speed, 0))
		var strides: float = c._walk
		var expect: float = speed / PixelCharacter.STRIDE
		check(absf(strides - expect) < 0.05, "%d px/s: %.2f strides in a second (distance / stride: %.2f)" % [speed, strides, expect])


# --- D4: input ----------------------------------------------------------------------

func test_diagonals_are_no_faster_and_a_light_stick_is_slow() -> void:
	var w := await start_session()
	var p: Player = w.player
	p.global_position = Vector2(320, 230)
	Input.action_press("move_right")
	Input.action_press("move_down")
	await frames(4)
	var diag := p.velocity.length()
	Input.action_release("move_right")
	Input.action_release("move_down")
	check(absf(diag - p.speed) < 0.5, "diagonal speed is the same as straight (%.1f)" % diag)
	await frames(2)
	Input.action_press("move_left", 0.6)
	await frames(4)
	var light := p.velocity.length()
	var facing: Vector2 = p._sprite.facing
	Input.action_release("move_left")
	check(light > 1.0 and light < p.speed * 0.8, "a light push walks slowly (%.1f)" % light)
	check_eq(facing, Vector2.LEFT, "and turns her")

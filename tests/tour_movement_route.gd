extends "res://tests/test_case.gd"
## The movement acceptance route (docs/production/MOVEMENT_SPEC.md):
## the same measurements on the festival's movement (stepped at several
## frame lengths) and the game's physics movement (the real loop). Prints a
## table; it is evidence, not a pass mark: a bot reaching a spot says
## nothing about how the movement feels. Not part of the suite:
##   --tour --filter=tour_movement_route


const FRAMES := [1.0 / 144.0, 1.0 / 60.0, 1.0 / 30.0, 0.1]


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
	for i in 4:
		p.lit[i] = false
	p.arin_pos = Vector2(600, 330)  # out of the way; the gate stays closed
	return p


## Deepest overlap of Rue's footprint with any festival solid.
func _penetration(p: Prologue) -> float:
	var box := Rect2(p.rue_pos - Vector2(4, 3), Vector2(8, 6))  # her footprint (same in every revision)
	var worst := 0.0
	for s in p._solids(true):
		var i := s.intersection(box)
		if i.has_area():
			worst = maxf(worst, minf(i.size.x, i.size.y))
	return worst


func _hold(p: Prologue, action: String, seconds: float, dt: float, strength := 1.0) -> Dictionary:
	var out := {"pen": 0.0, "flips": 0}
	var last: Vector2 = p.rue.facing
	Input.action_press(action, strength)
	var t := 0.0
	while t < seconds:
		p._process(dt)
		t += dt
		out.pen = maxf(out.pen, _penetration(p))
		if p.rue.facing != last:
			out.flips += 1
			last = p.rue.facing
	Input.action_release(action)
	return out


func test_route() -> void:
	var rows: Array[String] = []
	for dt: float in FRAMES:
		var p := await _festival()
		var r := {}
		# 1. Open floor: walk, release, how far after the release?
		p.rue_pos = Vector2(200, 250)
		await _hold(p, "move_right", 0.5, dt)
		var at := p.rue_pos
		p._process(dt)
		r.stop = p.rue_pos.distance_to(at)
		# 2. Pointer target: arrival error.
		p._walk_to = Vector2(263.7, 231.2)
		for i in int(3.0 / dt):
			p._process(dt)
			if p._walk_to == Vector2.INF:
				break
		r.arrive = p.rue_pos.distance_to(Vector2(263.7, 231.2))
		# 3. Thin gate, closed: push up into it for a second.
		p.rue_pos = Vector2(Prologue.GATE.get_center().x, Prologue.GATE.end.y + 8.0)
		r.gate = (await _hold(p, "move_up", 1.0, dt)).pen
		r.gate_crossed = p.rue_pos.y < Prologue.GATE.position.y
		# 4. Outside corner (the fence's bottom-right), diagonally.
		p.rue_pos = Vector2(Prologue.FENCE.end.x + 6.0, Prologue.FENCE.end.y + 6.0)
		Input.action_press("move_up")
		var corner := await _hold(p, "move_left", 0.8, dt)
		Input.action_release("move_up")
		r.corner = corner.pen
		# 5. Inside corner: the well's top-left, from outside, both keys.
		p.rue_pos = Prologue.WELL.position - Vector2(10, 10)
		Input.action_press("move_down")
		r.inside = (await _hold(p, "move_right", 0.8, dt)).pen
		Input.action_release("move_down")
		# 6. Low-speed analogue: stride vs distance (foot slide), in px.
		p.rue_pos = Vector2(200, 250)
		var from := p.rue_pos
		var walk0: float = p.rue._walk
		await _hold(p, "move_right", 1.0, dt, 0.5)
		var dist := p.rue_pos.distance_to(from)
		r.slow_speed = dist
		r.slide = absf((p.rue._walk - walk0) * 10.0 - dist)  # 10 px a stride
		# 7. Near-diagonal stick wobble: facing flips.
		p.rue_pos = Vector2(200, 250)
		var flips := 0
		var last: Vector2 = p.rue.facing
		for i in int(1.0 / dt):
			var a := deg_to_rad(45.0 + (4.0 if i % 2 == 0 else -4.0))
			Input.action_press("move_right", cos(a))
			Input.action_press("move_down", sin(a))
			p._process(dt)
			if p.rue.facing != last:
				flips += 1
				last = p.rue.facing
		Input.action_release("move_right")
		Input.action_release("move_down")
		r.flips = flips
		# 8. Camera boundary: into the square's corner; the view never shows past it.
		p.rue_pos = Vector2(40, 90)
		await _hold(p, "move_left", 0.6, dt)
		var view := Vector2(640, 360) / p.scale.x
		var tl := -p.position / p.scale.x
		r.bounds_ok = tl.x >= -0.01 and tl.y >= -0.01 and tl.x + view.x <= 640.01 and tl.y + view.y <= 360.01
		rows.append("| %.4f s | %.2f | %.3f | %.2f%s | %.2f | %.2f | %.0f px/s, slide %.2f | %d | %s |" % [
			dt, r.stop, r.arrive, r.gate, " CROSSED" if r.gate_crossed else "", r.corner, r.inside, r.slow_speed, r.slide, r.flips, "ok" if r.bounds_ok else "SHOWS PAST"])
		p._done = true
		p._handed_off = true
		p.queue_free()
		await frames(2)
	print("ROUTE  festival (custom movement, stepped):")
	print("ROUTE  | frame | moved after release | pointer arrival error | gate penetration | outside corner | inside corner | 0.5 stick | facing flips (±4° wobble, 1 s) | view bounds |")
	for row in rows:
		print("ROUTE  " + row)
	# The game: physics movement in the real loop (physics at the project's rate).
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	w.area.arin.paused = true
	var pl: Player = w.player
	var crate: DragProp = w.area.crates
	var cr := crate.rect()
	pl.global_position = Vector2(cr.get_center().x, cr.end.y + 12.0)
	await frames(2)
	var worst := 0.0
	var walking_frames := 0
	Input.action_press("move_up")
	for i in 60:
		await frames(1)
		var body := Rect2(pl.global_position + Vector2(-4, -2), Vector2(8, 8))
		var inter := body.intersection(crate.rect())
		if inter.has_area():
			worst = maxf(worst, minf(inter.size.x, inter.size.y))
		if i > 30 and pl._sprite.moving:
			walking_frames += 1
	var facing: Vector2 = pl._sprite.facing
	Input.action_release("move_up")
	var at2 := pl.global_position
	await frames(1)
	await frames(1)
	print("ROUTE  game (physics, %d ticks/s): pushing into the crates 1 s: penetration %.2f px; walking frames while blocked: %d; facing %s; moved after release %.2f px" % [
		Engine.physics_ticks_per_second, worst, walking_frames, facing, pl.global_position.distance_to(at2)])

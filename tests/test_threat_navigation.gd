extends "res://tests/test_case.gd"
## Arin walks where the level says it can (docs/GAMEPLAY_CONSISTENCY.md,
## passes 5 and 6): its whole body stays clear of walls, furniture and
## missing-texture blocks on patrol, chasing a decoy, guarding a body, in the
## house and at the Edge; it goes around things, through doorways, gives up
## on what it can't reach, and gets back out of a solid without crossing it.


## Does a body of Arin's radius at `p` overlap a solid (people don't count)?
## Slightly under the radius: touching a wall is fine, being in it isn't.
func _overlaps(w: Node, p: Vector2) -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	var c := CircleShape2D.new()
	c.radius = OwnerAvatar.RADIUS - 0.75
	q.shape = c
	q.transform = Transform2D(0.0, p)
	q.collision_mask = w.player.collision_mask
	q.exclude = [w.player.get_rid()]
	for hit in w.get_world_2d().direct_space_state.intersect_shape(q, 8):
		if not (hit.collider is Npc):
			return true
	return false


## The area's solid rectangles (walls and furniture), largest first.
func _solids(w: Node) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for c in w.area._body.get_children():
		if c is CollisionShape2D and c.shape is RectangleShape2D:
			var s: Vector2 = (c.shape as RectangleShape2D).size
			out.append(Rect2(c.position - s * 0.5, s))
	out.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.get_area() > b.get_area())
	return out


## Watches Arin for `seconds`: counts frames with its body inside a solid and
## the biggest single-frame jump (a teleport would show here).
func _watch(w: Node, arin: OwnerAvatar, seconds: float, label: String) -> Array:
	var inside := 0
	var jump := 0.0
	var visited: Array[Vector2] = []
	var t := 0.0
	var last := arin.global_position
	while t < seconds and is_instance_valid(arin):
		await tree.physics_frame
		if not is_instance_valid(arin):
			break  # (left: a house visit ends)
		t += 1.0 / Engine.physics_ticks_per_second
		if _overlaps(w, arin.global_position):
			inside += 1
		jump = maxf(jump, arin.global_position.distance_to(last))
		last = arin.global_position
		if visited.is_empty() or visited.back().distance_to(last) > 24.0:
			visited.append(last)
	check_eq(inside, 0, "%s: Arin's body never overlaps a solid" % label)
	check(jump < 3.0, "%s: no jumps (largest step %.1f px)" % [label, jump])
	return visited


func _square(w: Node) -> OwnerAvatar:
	await go_to(w, "square", "house")
	w.player.global_position = Vector2(60, 330)  # out of the way
	w.director.paused = true
	await frames(3)
	return w.area.arin


## A free-standing solid (open floor all round it): the stall, the well.
func _freestanding(w: Node) -> Array[Rect2]:
	var b: Rect2 = w.area.bounds
	return _solids(w).filter(func(r: Rect2) -> bool:
		return r.size.x >= 20.0 and r.size.y >= 12.0 and b.grow(-20.0).encloses(r))


## A solid at least this big, with open floor on both sides of it.
func _solid_with_sides(w: Node, arin: OwnerAvatar) -> Array:
	for r in _solids(w):
		if r.size.x < 30.0 or r.size.y < 12.0 or r.size.x > 300.0:
			continue
		var a := Vector2(r.position.x - 12.0, r.get_center().y)
		var b := Vector2(r.end.x + 12.0, r.get_center().y)
		if arin.nav().clear(a) and arin.nav().clear(b):
			return [r, a, b]
	return []


func test_a_decoy_behind_a_solid_is_reached_around_it() -> void:
	var w := await start_session()
	var arin := await _square(w)
	var found := _solid_with_sides(w, arin)
	check(not found.is_empty(), "a solid with floor on both sides")
	if found.is_empty():
		return
	arin.global_position = found[1]
	w.spawn_decoy()
	w.decoy.global_position = found[2]
	var decoy_at: Vector2 = found[2]
	Engine.time_scale = 3.0
	await _watch(w, arin, 8.0, "decoy behind a solid")
	Engine.time_scale = 1.0
	check(not is_instance_valid(w.decoy) or arin.global_position.distance_to(decoy_at) < 14.0,
		"Arin walks around and gets to it (%.0f px away)" % arin.global_position.distance_to(decoy_at))


func test_an_unreachable_decoy_is_given_up_and_the_round_resumes() -> void:
	var w := await start_session()
	var arin := await _square(w)
	var r: Rect2 = _freestanding(w)[0]
	w.spawn_decoy()
	w.decoy.global_position = r.get_center()  # inside it: nothing can stand there
	# (Arin starts on its own round.)
	Engine.time_scale = 3.0
	var visited := await _watch(w, arin, 14.0, "unreachable decoy")
	Engine.time_scale = 1.0
	check(not arin.is_chasing(), "it gives up rather than pushing at it forever")
	check(visited.size() >= 3, "then it goes back to its round (%d places)" % visited.size())


func test_the_square_patrol_goes_around_furniture() -> void:
	var w := await start_session()
	var arin := await _square(w)
	# Learned spots from earlier sightings, some inside furniture.
	var route: Array[Vector2] = w.area.ROUTE.duplicate()
	for r in _solids(w).slice(0, 4):
		route.append(r.get_center())
	arin.set_route(route)
	for p in arin.route:
		check(arin.nav().clear(p), "every destination has room for Arin's body (%s)" % p)
	Engine.time_scale = 4.0
	var visited := await _watch(w, arin, 16.0, "square patrol")
	Engine.time_scale = 1.0
	check(visited.size() >= 4, "it walks its round (%d places)" % visited.size())


func test_a_route_with_nowhere_valid_is_dropped_and_arin_still_watches() -> void:
	var w := await start_session()
	var arin := await _square(w)
	var r: Rect2 = _solids(w)[0]
	var far := Vector2(-500, -500)
	arin.set_route([far, far + Vector2(10, 0)] as Array[Vector2])
	check(arin.route.is_empty(), "nothing rejected is kept (%s)" % [arin.route])
	var seen := [false]
	arin.sees_player.connect(func(_d: float) -> void: seen[0] = true)
	var spot := arin.global_position
	w.player.global_position = spot + arin._facing * 30.0
	await wait(0.5)
	check(seen[0], "with no route it keeps watch: it still sees you")
	check(arin.global_position.distance_to(spot) < 2.0, "and stays where it is")
	check(r.size.x > 0.0, "")


func test_arin_steps_out_of_a_solid_without_crossing_it() -> void:
	var w := await start_session()
	var arin := await _square(w)
	var r: Rect2 = _freestanding(w)[0]
	var start := Vector2(r.get_center().x, r.position.y + 2.0)  # just inside its top edge
	arin.global_position = start
	var biggest := 0.0
	var last := start
	var out_at := Vector2.INF
	for i in 90:
		await tree.physics_frame
		biggest = maxf(biggest, arin.global_position.distance_to(last))
		last = arin.global_position
		if out_at == Vector2.INF and not _overlaps(w, last):
			out_at = last  # the moment it's back on open floor
	check(out_at != Vector2.INF, "it gets back onto open floor")
	check(out_at.distance_to(start) <= OwnerAvatar.RECOVER_RANGE + 2.0, "right beside where it was, not across the solid (%.0f px)" % out_at.distance_to(start))
	check(out_at.y <= r.position.y + 2.0, "out of the side it was nearest")
	check(biggest < 3.0, "walking, not teleporting (%.1f px)" % biggest)


func test_stuck_fast_it_holds_still_rather_than_walk_through() -> void:
	var w := await start_session()
	var arin := await _square(w)
	var big: Rect2 = _solids(w).filter(func(s: Rect2) -> bool: return s.size.x >= 60.0 and s.size.y >= 40.0 and s.size.x <= 300.0)[0]
	arin.global_position = big.get_center()  # deep inside: no open floor within reach
	var start := arin.global_position
	await wait(1.0)
	check(arin.global_position.distance_to(start) < 1.0, "no way out within reach: it holds still instead of crossing the solid")


func test_the_house_visit_goes_through_the_doorway() -> void:
	var w := await start_session()
	await go_to(w, "house", "front")
	w.director.paused = true
	w.player.global_position = ArinsHouse.CLOSETS[0].get_center()  # hidden, out of the way
	w.area.next_visit = 0.05
	await wait_until(func() -> bool: return w.area.arin != null, 3.0, "Arin coming home")
	var arin: OwnerAvatar = w.area.arin
	Engine.time_scale = 2.0
	var visited := await _watch(w, arin, 7.0, "house visit")  # 14 s of a 15 s visit
	Engine.time_scale = 1.0
	check(visited.any(func(p: Vector2) -> bool: return p.x > ArinsHouse.WALL_X + 10.0), "it gets into Player 2's room")


func test_every_edge_guard_route_is_walkable_and_walked() -> void:
	var w := await start_session()
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	var edge: TheEdge = w.area
	w.player.global_position = Vector2(320, 270)
	for c in [TheEdge.SLOT_POS] + TheEdge.DROP_SPOTS:
		var route := edge.guard_route(c)
		check(not route.is_empty(), "a guard route around %s" % c)
		for i in route.size():
			check(edge.guard_grid().clear(route[i]), "guard point %s has room for Arin (slot at %s)" % [route[i], c])
			check(edge.guard_grid().reaches(route[i], route[(i + 1) % route.size()]), "and leads on to the next")
	# One guard actually walking it, at the slot's start.
	edge.slot.global_position = TheEdge.SLOT_POS
	edge._send_arin()
	edge.arin.paused = false
	w.player.global_position = Vector2(60, 270)
	Engine.time_scale = 3.0
	await _watch(w, edge.arin, 10.0, "Edge guard")
	Engine.time_scale = 1.0

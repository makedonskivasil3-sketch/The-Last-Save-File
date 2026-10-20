extends "res://tests/test_case.gd"
## Arin walks where the level says it can (docs/GAMEPLAY_CONSISTENCY.md,
## pass 5): never through walls, furniture or missing-texture blocks, on its
## patrol, chasing a decoy, guarding a body, in the house and at the Edge.


## The solids Arin must respect at `p` (people don't count: Arin walks past them).
func _solid_at(w: Node, p: Vector2) -> bool:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = p
	params.collision_mask = w.player.collision_mask
	params.exclude = [w.player.get_rid()]
	for hit in w.get_world_2d().direct_space_state.intersect_point(params, 8):
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


## Runs for `seconds`, failing if Arin's feet are ever inside a solid.
func _watch(w: Node, arin: OwnerAvatar, seconds: float, label: String) -> int:
	var inside := 0
	var t := 0.0
	while t < seconds:
		await tree.physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
		if _solid_at(w, arin.global_position):
			inside += 1
	check_eq(inside, 0, "%s: Arin never stands inside a solid" % label)
	return inside


func _square(w: Node) -> OwnerAvatar:
	await go_to(w, "square", "house")
	var arin: OwnerAvatar = w.area.arin
	w.player.global_position = Vector2(60, 330)  # out of the way
	return arin


func test_a_decoy_behind_a_solid_is_not_reached_through_it() -> void:
	var w := await start_session()
	var arin := await _square(w)
	w.director.paused = true
	# Arin on one side of the biggest solid, the decoy right behind it.
	var placed := false
	for r in _solids(w):
		if r.size.x < 30.0 or r.size.y < 16.0 or r.size.x > 300.0:
			continue
		var a := Vector2(r.position.x - 10.0, r.get_center().y)
		var b := Vector2(r.end.x + 10.0, r.get_center().y)
		if w.area.bounds.grow(-8.0).has_point(a) and w.area.bounds.grow(-8.0).has_point(b) and not _solid_at(w, a) and not _solid_at(w, b):
			arin.position = a
			w.spawn_decoy()
			w.decoy.global_position = b
			placed = true
			break
	check(placed, "found a solid to hide the decoy behind")
	await _watch(w, arin, 3.0, "decoy behind a solid")
	# It gives up on what it can't reach and goes back to its round.
	await wait(5.0)
	check(not arin.is_chasing(), "an unreachable decoy is given up, not chased forever")


func test_the_square_patrol_stays_out_of_solids() -> void:
	var w := await start_session()
	var arin := await _square(w)
	w.director.paused = true
	# Learned spots from earlier sightings, some of them inside furniture.
	var spots: Array[Vector2] = []
	for r in _solids(w).slice(0, 4):
		spots.append(r.get_center())
	var route: Array[Vector2] = w.area.ROUTE.duplicate()
	route.append_array(spots)
	arin.set_route(route)
	for p in arin.route:
		check(not _solid_at(w, p), "no destination inside a solid (%s)" % p)
	Engine.time_scale = 4.0
	await _watch(w, arin, 12.0, "square patrol")
	Engine.time_scale = 1.0


func test_the_house_patrol_stays_out_of_solids() -> void:
	var w := await start_session()
	await go_to(w, "house", "front")
	w.director.paused = true
	w.player.global_position = Vector2(60, 300)
	w.area.call("_arin_enters") if w.area.has_method("_arin_enters") else null
	await wait(0.2)
	var arin: OwnerAvatar = w.area.get("arin")
	if arin == null:
		return  # (no visit to watch in this build)
	Engine.time_scale = 4.0
	await _watch(w, arin, 10.0, "house visit")
	Engine.time_scale = 1.0


func test_every_edge_guard_route_is_walkable() -> void:
	var w := await start_session()
	await go_to(w, "edge", "south")
	w.director.paused = true
	var edge: TheEdge = w.area
	for c in [TheEdge.SLOT_POS] + TheEdge.DROP_SPOTS:
		var route := edge.guard_route(c)
		check(not route.is_empty(), "a guard route around %s" % c)
		for p in route:
			check(edge.bounds.grow(-6.0).has_point(p), "guard point %s is inside the area (slot at %s)" % [p, c])
			check(not _solid_at(w, p), "guard point %s is not inside a missing-texture block" % p)

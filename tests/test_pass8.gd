extends "res://tests/test_case.gd"
## Pass 8 (docs/GAMEPLAY_CONSISTENCY.md): one protection rule everywhere
## (large cards hold the owner outside the Edge too; small text doesn't), and
## the walking grid's lifecycle when the level changes (openings, crates,
## shared grids, a watch ended by a new way through), plus recovery that never
## deepens an overlap or crosses a solid.


func _hunted_square(w: Node) -> void:
	await go_to(w, "square", "house")
	w.player.global_position = Vector2(200, 300)
	w.director.add_awareness(OwnerDirector.HUNT + 2.0 - w.director.awareness)
	await wait_until(func() -> bool: return w.area.cursor != null, 2.0, "the hunt")


## A wall that appears (and goes) in the middle of the area, on the solids' layer.
func _wall(w: Node, r: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = w.area._body.collision_layer
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	col.shape = shape
	body.position = r.get_center()
	body.add_child(col)
	w.area.add_child(body)
	return body


## The centre of a stretch of open floor at least `half` px each way.
func _open_spot(grid: NavGrid, half: float) -> Vector2:
	var b := grid.bounds.grow(-half - 8.0)
	var y := b.end.y
	while y > b.position.y:
		var x := b.position.x
		while x < b.end.x:
			var ok := true
			var dx := -half
			while ok and dx <= half:
				var dy := -half
				while ok and dy <= half:
					ok = grid.clear(Vector2(x + dx, y + dy))
					dy += 8.0
				dx += 8.0
			if ok:
				return Vector2(x, y)
			x += 16.0
		y -= 16.0
	return Vector2.INF


# --- protection ------------------------------------------------------------------------

func test_an_act_card_outside_the_edge_holds_every_threat() -> void:
	var w := await start_session()
	await _hunted_square(w)
	var aw: float = w.director.awareness
	var arin: OwnerAvatar = w.area.arin
	var arin_at := arin.global_position
	var cursor_at: Vector2 = w.area.cursor.position
	w.hud.show_act("ACT II", "THE SQUARE", "ASHVALE")
	await wait(1.2)
	check(w.hud.is_act_shown(), "the card is up")
	check(w.is_owner_paused(), "it holds the owner")
	check(absf(w.director.awareness - aw) < 0.5, "awareness doesn't climb under it (%.1f -> %.1f)" % [aw, w.director.awareness])
	check(arin.global_position.distance_to(arin_at) < 1.0, "Arin holds still")
	check(w.area.cursor.position.distance_to(cursor_at) < 1.0, "the cursor holds still")
	check(not w.area.erasure.is_processing(), "the static holds")
	w.hud.dismiss_title()
	await wait(0.6)
	check(not w.is_owner_paused(), "it lets go when the card goes")
	check(w.area.erasure.is_processing(), "and the static moves again")


func test_a_new_glitch_card_holds_the_owner_in_the_square() -> void:
	var w := await start_session()
	await _hunted_square(w)
	var aw: float = w.director.awareness
	w._learn_glitch(1)
	await frames(3)
	check(w.hud.is_act_shown(), "NEW GLITCH is a centre card")
	await wait(1.0)
	check(w.is_owner_paused() and absf(w.director.awareness - aw) < 0.5, "the owner waits while it's read")


func test_small_text_does_not_hold_the_owner() -> void:
	var w := await start_session()
	await _hunted_square(w)
	w.hud.say("a console line", "system")
	w.hud.show_tip("A TIP", "a small tip")
	await frames(3)
	check(not w.is_owner_paused(), "console lines and tips don't stop the world")


func test_closing_a_card_never_lands_a_banked_click() -> void:
	var w := await start_session()
	await _hunted_square(w)
	var cursor: OwnerCursor = w.area.cursor
	cursor._select = OwnerCursor.SELECT_TIME * 0.9  # the click was nearly done
	w.hud.show_act("NEW GLITCH", "X", "Y")
	await frames(4)
	w.hud.dismiss_title()
	await frames(2)
	check(cursor._select < OwnerCursor.SELECT_TIME * 0.3, "the click starts again from nothing (%.2f)" % cursor._select)
	check_eq(w.ending, "", "and nobody was clicked")


# --- the grid's lifecycle --------------------------------------------------------

func test_an_opening_becomes_walkable_and_a_closing_blocks_again() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	var arin: OwnerAvatar = w.area.arin
	var grid := arin.nav()
	var spot := _open_spot(grid, 24.0)
	check(spot != Vector2.INF and grid.clear(spot), "open floor to start with (%s)" % spot)
	var v := grid.version
	var wall := _wall(w, Rect2(spot - Vector2(16, 16), Vector2(32, 32)))
	w.area.geometry_changed(Rect2(spot - Vector2(16, 16), Vector2(32, 32)))
	await wait_until(func() -> bool: return grid.version > v, 1.0, "the refresh")
	check(not grid._open(grid._cell(spot)), "a wall that appears is solid on the grid")
	v = grid.version
	wall.queue_free()
	w.area.geometry_changed(Rect2(spot - Vector2(16, 16), Vector2(32, 32)))
	await wait_until(func() -> bool: return grid.version > v, 1.0, "the refresh")
	check(grid._open(grid._cell(spot)), "and walkable again once it's gone")


func test_dragged_crates_move_the_blocked_cells_with_them() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	var grid: NavGrid = w.area.arin.nav()
	var crates: DragProp = w.area.crates
	var was := crates.global_position
	var to := Vector2(220, 300)
	check(not grid._open(grid._cell(was)), "the stack is solid where it stands")
	var v := grid.version
	crates.global_position = to
	await wait_until(func() -> bool: return grid.version > v, 2.0, "the refresh after the drag")
	await frames(2)
	check(grid._open(grid._cell(was)), "where it was is a passage again")
	check(not grid._open(grid._cell(to)), "where it went is blocked")
	# A drag is not a rebuild a frame: small moves are merged.
	v = grid.version
	for i in 10:
		crates.global_position += Vector2(0.3, 0)
		await tree.process_frame
	check(grid.version - v <= 1, "small moves don't rebuild every frame (%d refreshes)" % (grid.version - v))


func test_walkers_in_one_area_share_one_grid_and_see_the_change() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	var a: OwnerAvatar = w.area.arin
	var b := OwnerAvatar.new()
	b.player = w.player
	b.position = Vector2(500, 300)
	w.area.add_child(b)
	await frames(2)
	check(a.nav() == b.nav(), "both walkers use the area's one grid")
	var v := a.nav().version
	w.area.geometry_changed()
	await wait_until(func() -> bool: return b.nav().version > v, 1.0, "the refresh")
	check(a.nav().version == b.nav().version, "and both see the new version")
	b.queue_free()


func test_a_watch_over_an_unreachable_point_ends_when_a_way_opens() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	w.player.global_position = Vector2(60, 330)
	var grid: NavGrid = w.area.arin.nav()
	var goal := _open_spot(grid, 56.0)
	check(goal != Vector2.INF, "open floor for the test")
	# A walker of our own (the square rewrites its Arin's round), on a
	# one-point round inside a pen: four walls, nothing gets in.
	var walls: Array[StaticBody2D] = [
		_wall(w, Rect2(goal + Vector2(-30, -30), Vector2(60, 6))), _wall(w, Rect2(goal + Vector2(-30, 24), Vector2(60, 6))),
		_wall(w, Rect2(goal + Vector2(-30, -30), Vector2(6, 60))), _wall(w, Rect2(goal + Vector2(24, -30), Vector2(6, 60)))]
	w.area.geometry_changed(Rect2(goal - Vector2(32, 32), Vector2(64, 64)))
	await wait(0.2)
	var arin := OwnerAvatar.new()
	arin.player = w.player
	arin.position = goal + Vector2(-50, 0)
	w.area.add_child(arin)
	arin.route = [goal] as Array[Vector2]
	await wait_until(func() -> bool: return arin._watching_blocked, 3.0, "the walker giving up and keeping watch")
	var watch_left: float = arin._wait  # what the watch had still to run
	walls[2].queue_free()  # the west side opens
	w.area.geometry_changed(Rect2(goal - Vector2(32, 32), Vector2(64, 64)))
	await wait_until(func() -> bool: return not arin._watching_blocked, 1.0, "the watch ending on the change")
	check(arin._wait <= 0.0 and watch_left > 1.0, "the watch ends early (it had %.1f s left)" % watch_left)
	await wait_until(func() -> bool: return arin.global_position.distance_to(goal) < 8.0, 6.0, "the walker using the new way in")
	arin.queue_free()


# --- recovery and path ends -----------------------------------------------------------

## Watches a recovery: the overlap never grows, the body never jumps, and it
## ends on open floor on the near side (or holds still).
func _watch_recovery(w: Node, arin: OwnerAvatar, start: Vector2, frames_n: int) -> Dictionary:
	arin.global_position = start
	var worst_growth := 0.0
	var last_depth := arin._penetration(start)
	var biggest := 0.0
	var last := start
	for i in frames_n:
		await tree.physics_frame
		var d := arin._penetration(arin.global_position)
		worst_growth = maxf(worst_growth, d - last_depth)
		last_depth = d
		biggest = maxf(biggest, arin.global_position.distance_to(last))
		last = arin.global_position
	return {"growth": worst_growth, "step": biggest, "end": arin.global_position, "depth": last_depth}


func test_recovery_from_a_thin_wall_leaves_by_the_near_side() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	w.player.global_position = Vector2(60, 330)
	var arin: OwnerAvatar = w.area.arin
	var wall_r := Rect2(300, 270, 60, 6)  # thin: 6 px
	_wall(w, wall_r)
	w.area.geometry_changed(wall_r)
	await wait(0.2)
	var r := await _watch_recovery(w, arin, Vector2(330, 271.5), 60)  # just inside its top edge
	check(r.growth <= 0.01, "the overlap never grows (worst %.2f)" % r.growth)
	check(r.step < 3.0, "no jumps (%.1f px)" % r.step)
	check(r.end.y < wall_r.position.y, "out of the top, the side it was nearest (%s)" % r.end)


func test_recovery_in_an_inside_corner_never_deepens() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	w.player.global_position = Vector2(60, 330)
	var arin: OwnerAvatar = w.area.arin
	_wall(w, Rect2(300, 260, 40, 10))
	_wall(w, Rect2(300, 260, 10, 40))
	w.area.geometry_changed(Rect2(290, 250, 60, 60))
	await wait(0.2)
	var r := await _watch_recovery(w, arin, Vector2(312, 272), 60)
	check(r.growth <= 0.01, "the overlap never grows (worst %.2f)" % r.growth)
	check(r.step < 3.0, "no jumps (%.1f px)" % r.step)
	check(r.end.x > 300 and r.end.y > 260, "it stays on its own side of the corner (%s)" % r.end)


func test_every_path_step_is_safe_for_the_whole_body() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var grid: NavGrid = w.area.arin.nav()
	var b: Rect2 = w.area.bounds
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	var unsafe := 0
	var checked := 0
	for i in 40:
		var from := Vector2(rng.randf_range(b.position.x, b.end.x), rng.randf_range(b.position.y, b.end.y))
		var to := Vector2(rng.randf_range(b.position.x, b.end.x), rng.randf_range(b.position.y, b.end.y))
		if not grid.clear(from) or not grid.clear(to):
			continue
		var pts := grid.path(from, to)
		for k in range(1, pts.size()):
			checked += 1
			if not grid.sweep_clear(pts[k - 1], pts[k]):
				unsafe += 1
	check(checked > 50, "enough steps checked (%d)" % checked)
	check_eq(unsafe, 0, "no step of any path grazes a solid")


# --- the finale -------------------------------------------------------------------------

func _at_edge(w: Node) -> TheEdge:
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	w.area.grace = 99.0  # no static in these tests
	return w.area


func test_slot_two_written_before_the_hand_arrives_is_a_clean_win() -> void:
	var w := await start_session()
	var edge := await _at_edge(w)
	w.player.global_position = TheEdge.SLOT_POS
	edge.cursor.global_position = Vector2(600, 280)  # lured far away
	edge.slot.progress = TheEdge.FIGHT_AT - 0.02
	await wait_until(func() -> bool: return edge.fight == "reach", 3.0, "the owner noticing")
	edge.cursor.blind(5.0)  # blinded: the hand can't find the slot in time
	await wait_until(func() -> bool: return edge.slot._done, 5.0, "Slot 2 finished")
	await frames(2)
	check_eq(edge.fight, "beaten", "the confrontation ends as beaten, not abandoned mid-reach")
	check(w.flags.get("slot2_beaten", false), "and the run remembers it")
	check(edge.arin == null, "nobody is sent for after it's written")
	check_eq(w.hud.banner_text(), "", "no stale 'THE OWNER HAS SEEN SLOT 2' banner over the recap")
	check_eq(edge.goal_text(), "", "and no stale goal")


func test_the_full_confrontation_still_happens_when_the_hand_is_close() -> void:
	var w := await start_session()
	var edge := await _at_edge(w)
	w.player.global_position = TheEdge.SLOT_POS
	edge.cursor.global_position = TheEdge.SLOT_POS + Vector2(60, 0)
	edge.slot.progress = TheEdge.FIGHT_AT - 0.02
	await wait_until(func() -> bool: return edge.fight == "drag", 4.0, "the grab")
	check(edge.slot.held, "a close hand gets there first: the slot is taken")
	check(not edge.slot._done, "and writing stops")


func test_back_from_an_edge_death_the_way_out_is_already_open() -> void:
	memory().met_archivist = true
	memory().sessions = 2
	memory().last_exit = "death"
	memory().deaths_log.append({"area": "edge", "x": 300.0, "y": 200.0, "session": 2})
	var w := await start_session()
	await frames(5)
	check(w.director.awareness < OwnerDirector.SUSPECT, "the owner isn't suspicious yet (%.0f)" % w.director.awareness)
	check(w.area.back_from_the_edge(), "the room knows this is a retry of the finale")
	check(w.area.seam.open, "and the seam is open from the start")
	check_eq(memory().purge, 0, "nothing else changed: no purge added or removed by it")


func test_a_death_elsewhere_keeps_the_room_closed() -> void:
	memory().sessions = 2
	memory().last_exit = "death"
	memory().deaths_log.append({"area": "square", "x": 300.0, "y": 200.0, "session": 2})
	var w := await start_session()
	await frames(5)
	check(not w.area.back_from_the_edge(), "a death in the square isn't a finale retry")
	check(not w.area.seam.open, "the seam waits for the owner as before")

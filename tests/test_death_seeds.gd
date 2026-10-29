extends "res://tests/test_case.gd"
## PL-4b: where Rue died in an area before, the owner's static starts again,
## but only after the spot has glowed for DEATH_SEED_WARNING seconds, so a
## player can read it and go round.


func test_a_death_spot_glows_before_its_static_starts() -> void:
	var spot := Vector2(470, 108)
	memory().deaths_log.append({"area": "square", "x": spot.x, "y": spot.y, "session": 0})
	var w := await start_session()
	await go_to(w, "square", "house")
	w.player.global_position = Vector2(150, 270)  # far from it
	var ghost: GhostMarker = null
	for g in w.area.get_children():
		if g is GhostMarker and g.position.distance_to(spot) < 1.0:
			ghost = g
	check(ghost != null, "the death spot is marked")
	w.area.start_erasure()
	check(ghost != null and ghost.warn_left > 2.5, "it glows as the static begins")
	check(not w.area.erasure._cells.has(w.area.erasure._to_cell(spot)), "and nothing is erased there yet")
	check_eq(w.area.erasure.pending_seeds(), 1, "the seed is waiting")
	await wait(Area.DEATH_SEED_WARNING + 0.4)
	check(w.area.erasure._cells.has(w.area.erasure._to_cell(spot)), "then the static starts where she died")
	check(ghost.warn_left <= 0.0, "and the glow has gone")

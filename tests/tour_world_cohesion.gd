extends "res://tests/test_case.gd"
## Rendered mission route using ordinary movement and interaction, not
## teleporting between the mission's objects. Run with --tour/screenshots.


func _walk(w: World, target: Vector2) -> void:
	var left := 12.0
	while w.player.position.distance_to(target) > 3 and left > 0:
		var off := target - w.player.position
		for action in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(action)
		if absf(off.x) > 3:
			Input.action_press("move_right" if off.x > 0 else "move_left")
		elif absf(off.y) > 3:
			Input.action_press("move_down" if off.y > 0 else "move_up")
		await frames(1)
		left -= 1.0 / 60.0
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	check(w.player.position.distance_to(target) <= 4, "walk reached %s (at %s)" % [target, w.player.position])
	await frames(3)


func test_lantern_mission_and_connected_thresholds() -> void:
	var w: World = await start_session()
	await go_to(w, "archive", "workshop")
	await shot("01_archive_stairs")
	Input.action_press("move_down")
	await wait_until(func() -> bool: return w.area is LanternWorkshop and not w._transitioning, 5.0, "walk down workshop stairs")
	Input.action_release("move_down")
	await shot("02_workshop_before")
	await _walk(w, Vector2(450, 134))
	await _walk(w, Vector2(182, 134))
	await press("interact")
	check(await wait_until(func() -> bool: return Relationships.has(LanternRoute.SPOOL), 2.0, "wick tap resolved"), "ordinary input picked up the wick")
	await _walk(w, Vector2(250, 134))
	await _walk(w, Vector2(250, 194))
	await _walk(w, Vector2(320, 194))
	await press("interact")
	check(await wait_until(LanternRoute.repaired, 2.0, "lamp tap resolved"), "ordinary input repaired the service light")
	await wait(0.5)
	await shot("03_workshop_repaired")
	await _walk(w, Vector2(250, 194))
	await _walk(w, Vector2(250, 250))
	await _walk(w, Vector2(144, 250))
	await press("interact")
	await wait_until(func() -> bool: return w.area.area_id == "oob" and not w._transitioning, 5.0, "hatch below well")
	if w.hud.is_act_shown():
		w.hud.dismiss_title()
	await shot("04_well_service_return")
	check(w.body_fits(w.player.position), "hatch arrives on safe ground")

extends "res://tests/test_case.gd"
## Captures for docs/prompts/TRAVEL_AND_DEPTH_2026-10-30.md. Not in the suite.


func test_travel_frames() -> void:
	World.travel_beats_default = true
	memory().found_pip = true
	memory().meet("wren", "square")
	memory().meet("tobben", "square")
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.paused = true
	w.area.arin.position = Vector2(560, 300)
	w.director.paused = true
	var e: Exit = null
	for x: Exit in w.area.exits:
		if x.target_area == "archive":
			e = x
	w.player.global_position = e.global_position + Vector2(-30, 0)
	await wait(0.8)
	await shot("t01_threshold_near")
	w.change_area("archive", "west", e.outward)
	await wait_until(func() -> bool: return w.hud.passage_shown, 3.0, "card")
	await wait(0.3)
	await shot("t02_passage_card")
	await wait_until(func() -> bool: return not w._transitioning, 6.0, "in")
	await shot("t03_arrived_archive")
	await go_to(w, "square", "east")
	w.area.on_arrival(false)
	await wait(0.7)
	await shot("t04_wren_tobben_notice")

extends "res://tests/test_case.gd"
## Static composition captures, not a frame-time benchmark or a human run.
## The historical 90-frame-per-shot tour can exceed its 90 s method budget
## under software GL. This keeps capture work separate from benchmarking.

func test_seven_area_composition() -> void:
	settings().screen_effects = 0
	settings().glitch_intensity = 0.0
	settings().reduce_flashing = true
	var w := await start_session()
	w.director.paused = true
	w.player.set_physics_process(false)
	var stops := [["room", "start"], ["square", "house"], ["archive", "west"],
		["house", "front"], ["bin", "west"], ["oob", "well"], ["edge", "south"]]
	for stop in stops:
		if w.area.area_id != stop[0]:
			await go_to(w, stop[0], stop[1])
		# Hold threats without invoking PAUSE's deliberate cyan memory wash:
		# this sheet reviews surfaces and silhouettes, not the glitch effect.
		w.director.owner_paused = 60.0
		w.area.set_owner_paused(true)
		# Goals poll every 0.5 s; let the named area's guidance settle too.
		await wait(0.7)
		await frames(4)
		check_eq(w.area.area_id, stop[0], "capture is in the named area")
		await shot("map_" + stop[0])

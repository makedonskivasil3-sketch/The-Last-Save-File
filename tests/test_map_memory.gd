extends "res://tests/test_case.gd"
## The map remembers where Rue has been across runs (docs/COHERENCE_MILESTONE.md,
## F10): found in any run, visited this run, open right now, and here, each
## shown differently; places never found stay "???".


func test_found_places_stay_found_after_a_death() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "archive", "west")
	w.kill("arin", "test")
	var w2 := await wait_for_new_session(w)
	var map: Dictionary = w2.map_state()
	check_eq(map.current, "room", "a new run starts in the room")
	check(map.discovered.has("square") and map.discovered.has("archive"), "the square and the Archive are still found")
	check(not map.visited.has("square"), "but not visited this run")
	check(not map.discovered.has("edge") and not map.discovered.has("bin"), "nothing never found is given away")
	w2.open_pause()
	w2._pause_menu._show_map()
	await frames(2)
	var view: MapView = w2._pause_menu._map
	check(view.is_found("archive"), "the map names the Archive")
	check(not view.is_found("edge"), "and still doesn't name the Edge")
	check(view.visited.has("room") and not view.visited.has("archive"), "this run's visits are told apart from earlier ones")
	w2._pause_menu.close()


func test_closed_ways_say_why() -> void:
	var w := await start_session()
	check(not w.map_state().closed.has("room"), "in the room: it's where you are")
	await go_to(w, "square", "house")
	var closed: Dictionary = w.map_state().closed
	check_eq(closed.get("room", ""), "no way back in", "out of the room: its door locks behind you")
	check_eq(closed.get("edge", ""), "not loaded", "no pointer: the north road isn't loaded")
	w.flags["pointer"] = true
	check(not w.map_state().closed.has("edge"), "with the pointer: open")


func test_pip_no_longer_stands_in_for_the_map() -> void:
	# Before, finding Pip was the only thing that kept "out of bounds" on the
	# map between runs. Now any found place is kept, Pip or not.
	memory().sessions = 2
	memory().places.assign(["room", "square", "oob"])
	var w := await start_session()
	check(w.map_state().discovered.has("oob"), "found out of bounds without Pip")

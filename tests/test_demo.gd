extends "res://tests/test_case.gd"
## The demo build's endpoint (COMMERCIAL_DIRECTION.md §4; proposed, off by
## default): it ends under the Archive's arch, and nothing past it is
## reachable.


func after_each() -> void:
	World.demo_override = -1
	super()


func test_off_unless_asked_for() -> void:
	check(not World.demo_build(), "a normal build is not the demo")
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "archive", "west")
	check_eq(w.area.area_id, "archive", "the full game goes on into the Archive")


func test_the_demo_ends_under_the_arch_and_costs_nothing() -> void:
	World.demo_override = 1
	var w := await start_session()
	await go_to(w, "square", "house")
	var purge: int = memory().purge
	var quits: int = memory().quits
	w.change_area("archive", "west")
	await wait_until(func() -> bool: return w.ending == "demo", 3.0, "the demo's end")
	check_eq(w.area.area_id, "square", "the Archive is never loaded")
	check(w.hud._overlay.visible and w.hud._overlay_body.text.begins_with(Story.DEMO_END), "the last card: %s" % w.hud._overlay_body.text)
	check_eq(memory().last_exit, "demo", "the session closed cleanly")
	check_eq(memory().purge, purge, "no purge for reaching the end")
	check_eq(memory().quits, quits, "not counted as a quit")
	check(memory().endings_seen.is_empty(), "no ending seen")


## Nothing the demo withholds is reachable: every way out of the areas it
## keeps leads only to areas it keeps, or to the end card.
func test_nothing_past_the_arch_is_reachable() -> void:
	World.demo_override = 1
	var kept := ["room", "square", "house", "oob"]
	var ways := 0
	for id in kept:
		var w := await start_session()
		if id != "room":
			await go_to(w, id, {"square": "house", "house": "front", "oob": "well"}[id])
		for e in w.area.find_children("*", "Exit", true, false):
			var target: String = e.target_area
			ways += 1
			check(target in kept or target in World.DEMO_END_AREAS, "%s -> %s is kept or ends the demo" % [id, target])
			if target == "edge":
				check(not e.open, "the north road stays closed (no pointer without the Archivist)")
		for p in w.area.find_children("*", "Passage", true, false):
			check(p.target_area in kept, "%s's passage -> %s is kept" % [id, p.target_area])
		w.queue_free()
		await frames(2)
	check(ways >= 3, "the exits were actually checked (%d)" % ways)
	# Doors and scripted moves call change_area directly: every literal
	# target in the kept areas' scripts is kept too.
	var moves := 0
	for f in ["arins_room", "village_square", "arins_house", "out_of_bounds"]:
		var src := FileAccess.get_file_as_string("res://scripts/world/areas/%s.gd" % f)
		var re := RegEx.create_from_string("change_area\\(\"(\\w+)\"")
		for m in re.search_all(src):
			moves += 1
			check(m.get_string(1) in kept, "%s moves Rue to %s, which the demo keeps" % [f, m.get_string(1)])
	check(moves >= 3, "the scripted moves were actually found (%d)" % moves)
	for later in World.DEMO_END_AREAS:
		var w := await start_session()
		await go_to(w, "square", "house")
		w.change_area(later, "south" if later == "edge" else "west")
		await wait_until(func() -> bool: return w.ending == "demo", 3.0, "%s ends the demo" % later)
		check_eq(w.area.area_id, "square", "%s is never loaded" % later)
		w.queue_free()
		await frames(2)

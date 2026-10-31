extends "res://tests/test_case.gd"
## The demo build's endpoint (COMMERCIAL_DIRECTION.md §4; proposed, off by
## default): it ends under the Archive's arch, and nothing past it is
## reachable.


func after_each() -> void:
	World.demo_override = -1
	World.demo_endpoint_override = ""
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


## The candidate endpoint (revision brief §18): up the well's service
## ladder, repair the light, and the demo ends once Wren has noticed it.
func test_the_workshop_candidate_ends_after_wren_sees_the_light() -> void:
	World.demo_override = 1
	World.demo_endpoint_override = "workshop"
	check_eq(World.demo_endpoint(), "workshop", "the candidate is asked for")
	var w := await start_session()
	await go_to(w, "oob", "well")
	var ladder: Passage
	for node in w.area.interactables:
		if node is Passage and node.target_area == "workshop":
			ladder = node
	check(ladder != null, "a ladder up from under the well, before the repair")
	if ladder == null:
		return
	check_eq(ladder.object_name, "DARK SERVICE LADDER", "and it reads as dark")
	await interact_with(w, ladder, Vector2(0, 8))
	check(await wait_until(func() -> bool: return w.area.area_id == "workshop" and not w._transitioning, 5.0, "up the ladder"), "it reaches the workshop")
	var room: LanternWorkshop = w.area
	await interact_with(w, room.wick, Vector2(0, 12))
	await interact_with(w, room.lamp, Vector2(0, 12))
	check(LanternRoute.repaired(), "the mission can be finished in the demo")
	await finish_dialogue(w)
	check_eq(w.ending, "", "the repair alone doesn't end it")
	await go_to(w, "square", "well")
	Relationships.add("wren.met")
	var wren: Npc = w.area.wren
	await interact_with(w, wren)
	for i in 12:
		if not w.hud.is_dialogue_open():
			break
		await press("interact")
		await press("interact")
		await wait(0.05)
	check(await wait_until(func() -> bool: return w.ending == "demo", 3.0, "the demo's end"), "it ends once Wren has said it")
	check(OwnerMemory.has_conversation("wren.service_light"), "after her acknowledgement, not before")
	check(memory().endings_seen.is_empty(), "no ending seen")
	check_eq(memory().last_exit, "demo", "closed cleanly")
	World.demo_endpoint_override = ""


func test_the_stairs_up_still_end_the_candidate_at_the_archive() -> void:
	World.demo_override = 1
	World.demo_endpoint_override = "workshop"
	var w := await start_session()
	await go_to(w, "workshop", "well")
	w.change_area("archive", "workshop")
	await wait_until(func() -> bool: return w.ending == "demo", 3.0, "the demo's end")
	check_eq(w.area.area_id, "workshop", "the Archive is never loaded")
	World.demo_endpoint_override = ""


func test_the_full_game_has_no_ladder_before_the_repair() -> void:
	var w := await start_session()
	await go_to(w, "oob", "well")
	var any: bool = w.area.interactables.any(func(n: Node) -> bool: return n is Passage and n.target_area == "workshop")
	check(not any, "the service route is still earned in the full game")


func test_a_demo_keeps_its_own_save() -> void:
	check_eq(OwnerMemory.save_path_for(false, false), OwnerMemory.SAVE_PATH, "the full game's save")
	check_eq(OwnerMemory.save_path_for(false, true), OwnerMemory.DEMO_SAVE_PATH, "the demo's, separate")
	check(OwnerMemory.DEMO_SAVE_PATH != OwnerMemory.SAVE_PATH, "never the same file")
	check_eq(OwnerMemory.save_path_for(true, true), OwnerMemory.TEST_SAVE_PATH, "tests never touch either")


func test_nothing_past_the_candidate_is_reachable_from_the_workshop() -> void:
	World.demo_override = 1
	World.demo_endpoint_override = "workshop"
	var kept := ["room", "square", "house", "oob", "workshop"]
	var w := await start_session()
	await go_to(w, "workshop", "well")
	var ways := 0
	for e in w.area.find_children("*", "Exit", true, false):
		ways += 1
		check(e.target_area in kept or e.target_area in World.DEMO_END_AREAS, "workshop -> %s is kept or ends the demo" % e.target_area)
	Relationships.add(LanternRoute.REPAIRED)
	(w.area as LanternWorkshop)._refresh()
	for p in w.area.find_children("*", "Passage", true, false):
		ways += 1
		check(p.target_area in kept, "workshop passage -> %s is kept" % p.target_area)
	check(ways >= 2, "the ways out were checked (%d)" % ways)
	var src := FileAccess.get_file_as_string("res://scripts/world/areas/lantern_workshop.gd")
	for m in RegEx.create_from_string("change_area\\(\"(\\w+)\"").search_all(src):
		check(m.get_string(1) in kept, "the workshop moves Rue only to kept places")

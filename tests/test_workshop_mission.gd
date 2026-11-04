extends "res://tests/test_case.gd"
## The workshop mission, deepened (revision brief §7): a personal reason, a
## readable problem, an observation, a decision with a lasting consequence,
## an emotional beat and the route benefit, all in the one small room.


func _workshop() -> World:
	var w: World = await start_session()
	await go_to(w, "workshop", "stairs")
	return w


func _repair(w: World) -> void:
	var room: LanternWorkshop = w.area
	await interact_with(w, room.wick, Vector2(0, 12))
	await interact_with(w, room.lamp, Vector2(0, 12))
	await finish_dialogue(w)


func test_she_says_why_this_room_matters_on_first_arrival() -> void:
	var w := await _workshop()
	# The console is reader-paced: her line may still be waiting behind an
	# owner's note. Shown or queued, it is on its way to the player.
	var lines: Array = w.hud.history + w.hud._queue
	check(lines.any(func(h: Dictionary) -> bool: return str(h.text).contains("the fifth was the one i lit")), "Rue's reason: the fifth lantern was hers")
	await go_to(w, "archive", "workshop")
	await go_to(w, "workshop", "stairs")
	var again: Array = (w.hud.history + w.hud._queue).filter(func(h: Dictionary) -> bool: return str(h.text).contains("the fifth was the one i lit"))
	check_eq(again.size(), 1, "said once, not on every return")


func test_the_problem_reads_before_anything_is_fixed() -> void:
	var w := await _workshop()
	var room: LanternWorkshop = w.area
	var problem: String = room.lamp.interact()
	check(problem.contains("hatch") and problem.contains("dark"), "the lamp says what is wrong and why it matters (%s)" % problem)
	var frame: String = room.fifth.interact()
	check(frame.contains("fifth label is blank"), "the fifth frame can be read before the light (%s)" % frame)
	check(not LanternRoute.named(), "reading it decides nothing")


func test_writing_her_name_lasts_and_wren_notices() -> void:
	var w := await _workshop()
	var room: LanternWorkshop = w.area
	await _repair(w)
	check(LanternRoute.repaired(), "the light is on")
	check(Quests.line("workshop").contains("blank label"), "the goal points at the open decision")
	await interact_with(w, room.fifth, Vector2(0, 10))
	check(await until_choosing(w), "the fifth frame asks")
	await press("interact")  # "Write RUE"
	await frames(4)
	check(LanternRoute.named(), "her name is written")
	check(memory().journal.any(func(e: Dictionary) -> bool: return str(e.get("id", "")) == "workshop:" + LanternRoute.NAMED), "and kept in the journal")
	check(not Quests.line("workshop").contains("blank label"), "the goal no longer asks")
	check(str(room.fifth.interact()).contains("RUE"), "the label reads RUE")
	memory().load_memory()  # relaunch
	check(LanternRoute.named(), "it survives a reload")
	Relationships.add("wren.met")
	var told: Dictionary = Relationships.wren(0, false, false)
	check_eq(told.get("lines", []), Relationships.WREN_SERVICE_LIGHT_NAMED, "Wren's acknowledgement mentions the name")


func test_wren_without_the_name_keeps_her_first_line() -> void:
	Relationships.add(LanternRoute.REPAIRED)
	Relationships.add("wren.met")
	var told: Dictionary = Relationships.wren(0, false, false)
	check_eq(told.get("lines", []), Relationships.WREN_SERVICE_LIGHT, "unchanged when the label is blank")


func test_leaving_it_blank_is_a_real_answer_and_can_change() -> void:
	var w := await _workshop()
	var room: LanternWorkshop = w.area
	await _repair(w)
	await interact_with(w, room.fifth, Vector2(0, 10))
	check(await until_choosing(w), "the fifth frame asks")
	await press("move_down")
	await press("interact")  # "Leave it blank"
	await frames(4)
	check(not LanternRoute.named(), "nothing is written")
	check(not memory().journal.any(func(e: Dictionary) -> bool: return str(e.get("id", "")) == "workshop:" + LanternRoute.NAMED), "nothing recorded")
	check(LanternRoute.repaired() and room.hatch.can_interact(), "the route stays open either way")
	await finish_dialogue(w)
	await interact_with(w, room.fifth, Vector2(0, 10))
	check(await until_choosing(w), "she can still choose later")
	await press("interact")
	await frames(4)
	check(LanternRoute.named(), "and change her mind")
	var count: int = memory().journal.size()
	room.fifth.interact()
	room.interact_extra(room.fifth)
	await frames(2)
	check_eq(memory().journal.size(), count, "no second record")

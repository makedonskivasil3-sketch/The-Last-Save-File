extends "res://tests/test_case.gd"
## Missions (Quests, docs/INTRO_REBUILD.md §3): one active mission, a reason
## for every map, read from the save (so old saves open on the right one),
## and the festival remembered by the people who saw it.


func _talk(w: Node, who: Node) -> Array:
	await interact_with(w, who)
	var said: Array = []
	for i in 12:
		if not w.hud.is_dialogue_open():
			break
		said.append(w.hud._dialogue_text.text)
		await press("interact")
		await press("interact")
		await wait(0.05)
	await frames(3)
	return said


func test_every_first_hour_map_has_a_mission_with_a_reason() -> void:
	for area in ["room", "square", "oob", "archive", "house", "bin", "edge"]:
		var id := Quests.active(area)
		check(Quests.TITLES.has(id) and Quests.WHY.has(id), "%s has a mission (%s)" % [area, id])
		check(Quests.line(area) != "", "%s says what to do" % area)
		check(Quests.goal(area).begins_with(Quests.TITLES[id] + Quests.SEP), "%s's goal line is titled" % area)


func test_the_first_mission_is_the_fifth_lantern() -> void:
	var w := await start_session()
	await wait(0.3)
	check(w.current_goal().begins_with("THE FIFTH LANTERN"), "the room's mission (%s)" % w.current_goal())
	check(w.hud.objective_text().contains("Find who kept the fifth lantern burning"), "on screen, with its reason (%s)" % w.hud.objective_text())
	check(w.hud.objective_text().contains("get out of Arin's room"), "and the way to start it")


func test_missions_follow_the_story() -> void:
	check_eq(Quests.story_mission(), "fifth_lantern", "a new save")
	memory().discover_place("square")
	check_eq(Quests.story_mission(), "well_light", "in the square: the light by the well")
	check(Quests.done("fifth_lantern"), "the first one is done")
	memory().found_pip = true
	check_eq(Quests.story_mission(), "who_kept", "after the well: ask the Archive")
	check(Quests.line("square").contains("Archive"), "the square says where (%s)" % Quests.line("square"))
	memory().met_archivist = true
	check_eq(Quests.story_mission(), "slot2", "with the pointer: what's left of Slot 2")
	check(Quests.line("square").contains("north road"), "the way out is still the north road")


func test_dangerous_places_say_how_to_survive_first() -> void:
	check(Hud.first_thought(Quests.goal("bin")).contains("shadow"), "the bin: the shelter is on screen")
	check(Hud.first_thought(Quests.goal("house")).contains("closet"), "the house: the closets are on screen")
	check(Hud.first_thought(Quests.goal("edge", "Lead the cursor away.")).contains("cursor"), "the Edge: its own reading of the moment")


func test_an_old_save_opens_on_the_mission_it_has_reached() -> void:
	# A save from before missions existed: no festival keys, but progress.
	memory().sessions = 4
	memory().found_pip = true
	memory().places.append_array(["room", "square", "oob"])
	memory().save_memory()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(memory()._path))
	data.erase("festival_seen")
	data.erase("festival_choice")
	SafeFile.write_atomic(memory()._path, JSON.stringify(data))
	memory().clear_state()
	memory().load_memory()
	check_eq(Quests.story_mission(), "who_kept", "the old save is on the Archive mission")
	check(Quests.done("under_well") and Quests.done("well_light"), "with what it did marked done")
	var log := Quests.log_text("square")
	check(log.begins_with("NOW  ·  WHO KEPT IT BURNING"), "the quest log leads with it (%s)" % log)
	check(log.contains("✓ THE FIFTH LANTERN") and log.contains("✓ UNDER THE WELL"), "and lists what's done")
	check(not log.contains("WHAT SHE LEFT"), "an optional mission not started isn't listed")


func test_the_journal_has_the_mission_lead() -> void:
	Quests.area_now = "room"
	var lead: Array = ArchivePages.leads().filter(func(e: Dictionary) -> bool: return e.key == "lead:mission")
	check_eq(lead.size(), 1, "one mission lead")
	if lead.size() == 1:
		check(lead[0].body.contains(Quests.WHY.fifth_lantern), "with why she goes")


func test_mira_remembers_the_festival_once() -> void:
	memory().festival_choice = "stayed"
	var w := await start_session(true, true)
	var heard: Array = []
	for i in 6:
		heard.append_array(await _talk(w, w.area.mira))
		if w.hud.is_choosing():
			await press("move_down")
			await press("interact")  # "Not now"
			await frames(3)
			await finish_dialogue(w)
	check(Relationships.MIRA_FESTIVAL_HOW.stayed in heard, "she saw her stay beside him")
	check(Relationships.MIRA_FESTIVAL_LAST in heard, "\"You lit the last one. Nobody else came.\"")
	var at := heard.find(Relationships.MIRA_FESTIVAL_OPEN)
	check(at > 0 and heard[at - 1] == ArinsRoom.MIRA_LINES[2], "straight after she sees Rue isn't Arin")
	check(Relationships.has("mira.festival"), "kept as something that happened between them")
	var again: Array = []
	for i in 3:
		again.append_array(await _talk(w, w.area.mira))
	check(not again.has(Relationships.MIRA_FESTIVAL_LAST), "said once")


func test_how_the_festival_ended_changes_what_mira_saw() -> void:
	for c in ["lit", "tried", "stayed", "idle", "skipped", ""]:
		memory().conversations.clear()
		memory().festival_choice = c
		var told := Relationships.mira_festival()
		check_eq(told.lines[-1], Relationships.MIRA_FESTIVAL_LAST, "%s: the last one, lit" % c)
		var how: String = told.lines[1]
		check_eq(how, Relationships.MIRA_FESTIVAL_HOW.get(c, Relationships.MIRA_FESTIVAL_HOW[""]), "%s: what she saw" % c)


func test_wren_and_tobben_remember_it_too() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var heard: Array = []
	for i in 2:
		heard.append_array(await _talk(w, w.area.wren))
	check(Relationships.WREN_FESTIVAL[0] in heard, "Wren: the lantern by the well, still lit")
	heard.clear()
	for i in 2:
		heard.append_array(await _talk(w, w.area.tobben))
	check(Relationships.TOBBEN_FESTIVAL[1] in heard, "Tobben: nobody came back to set the fireworks off")


func test_the_archive_records_who_lit_the_fifth_lantern() -> void:
	check(Story.festival_log("lit").has("LANTERN 5 · lit by P2 · never saved off."), "she lit it with P2 holding")
	for c in ["tried", "stayed", "idle"]:
		check(Story.festival_log(c).any(func(l: String) -> bool: return l.contains("controller: none")), "%s: lit with no controller held" % c)
	var w := await start_session()
	await go_to(w, "archive", "west")
	var log: Array = w.area._session_log()
	check(log.any(func(l: String) -> bool: return l.begins_with("LANTERN 5")), "the SESSION LOG has it")


func test_the_message_ending_remembers_the_festival() -> void:
	for f in Story.FRAGMENTS:
		memory().fragments.append(f.id)
	var lines := Story.epilogue("message", Story.FRAGMENTS.size(), false)
	check(lines.any(func(l: String) -> bool: return l.begins_with(">") and l.contains("festival") and l.contains("last lantern")),
		"the owner says they walked off before the last lantern")
	var edge := TheEdge.new()
	check(edge.has_method("_draw_fifth_lantern"), "and the fifth lantern is drawn beside Slot 2")
	edge.free()


func test_the_title_says_where_she_was_going() -> void:
	memory().sessions = 2
	memory().found_pip = true
	tree.change_scene_to_file(TITLE_SCENE)
	await frames(5)
	var next := scene().find_child("NextMission", true, false) as Label
	check(next != null, "a returning profile sees its next mission on the title")
	if next:
		check(next.text.contains(Quests.TITLES.who_kept), "the one it reached (%s)" % next.text)
	memory().sessions = 0
	tree.change_scene_to_file(TITLE_SCENE)
	await frames(5)
	check(scene().find_child("NextMission", true, false) == null, "a new profile doesn't: the festival tells it")

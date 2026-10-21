extends "res://tests/test_case.gd"
## Relationship continuity (docs/NARRATIVE_CONTRACT.md §3–4): meeting someone
## is remembered for good; what was said is committed only when read to the
## end; history survives death and restart; characters acknowledge only
## what they witnessed; older saves migrate without losing anyone.


func _wren(w: Node) -> Npc:
	return w.area.wren


func _talk_lines(w: Node, who: Npc) -> Array:
	var told: Dictionary = who.interact()
	w.hud.close_dialogue()
	return told.lines


func test_first_meeting_versus_reunion() -> void:
	var w := await start_session()
	await interact_with(w, w.area.mira)
	check(w.hud._dialogue_text.text.contains("You're up early"), "first meeting: Mira's introduction (%s)" % w.hud._dialogue_text.text)
	check(memory().has_met("mira"), "meeting Mira is remembered as soon as the box opens")
	await finish_dialogue(w)
	await go_to(w, "square", "house")
	await interact_with(w, _wren(w))
	check(w.hud._dialogue_text.text.contains("Mira talks about"), "first meeting: Wren's introduction")
	await finish_dialogue(w)
	check(memory().has_event("wren.met"), "met Wren")
	# A new run, as after a death.
	memory().last_exit = "death"
	memory().last_death = "arin"
	var w2 := await start_session()
	await interact_with(w2, w2.area.mira)
	var all: String = " ".join(w2.hud._dialogue_lines)
	check(not all.contains("You're up early"), "a reunion doesn't introduce Mira again (%s)" % all)
	await finish_dialogue(w2)
	await go_to(w2, "square", "house")
	await interact_with(w2, _wren(w2))
	all = " ".join(w2.hud._dialogue_lines)
	check(not all.contains("Mira talks about"), "nor Wren (%s)" % all)
	check(all.contains(Relationships.WREN_GREETING), "she greets you as someone she knows")
	await finish_dialogue(w2)


func test_an_interrupted_reunion_is_not_committed() -> void:
	# Wren saw you die last run.
	memory().sessions = 1
	memory().encounters["wren"] = {"first": 1, "last": 1, "count": 1}
	memory().rel_events["wren.met"] = 1
	memory().rel_events["wren.saw_death"] = 1
	memory().last_exit = "death"
	memory().last_death = "arin"
	var w := await start_session()
	await go_to(w, "square", "house")
	await interact_with(w, _wren(w))
	check(" ".join(w.hud._dialogue_lines).contains("I saw them take you"), "she says she saw it")
	# Walk away halfway.
	w.player.global_position += Vector2(120, 0)
	await wait_until(func() -> bool: return not w.hud.is_dialogue_open(), 3.0, "the box to close as you leave")
	check(not memory().has_event("wren.reunited"), "walked away: the reunion isn't counted")
	# Come back and hear it out.
	await interact_with(w, _wren(w))
	check(" ".join(w.hud._dialogue_lines).contains("I saw them take you"), "she tries again")
	await finish_dialogue(w)
	check(memory().has_event("wren.reunited"), "read to the end: the reunion is committed")
	var told: Dictionary = _wren(w).interact()
	w.hud.close_dialogue()
	check(not " ".join(told.lines).contains("I saw them take you"), "and isn't repeated")


func test_history_survives_death_and_restart() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await interact_with(w, _wren(w))
	await finish_dialogue(w)
	w.kill("arin", "test")
	var w2 := await wait_for_new_session(w)
	check(memory().has_met("wren"), "still met after a death")
	check(memory().has_event("wren.saw_death"), "she was there: she saw it")
	memory().load_memory()  # as after closing and reopening the game
	check(memory().has_event("wren.met") and memory().has_event("wren.saw_death"), "and after a restart")
	await go_to(w2, "square", "house")
	await interact_with(w2, _wren(w2))
	check(" ".join(w2.hud._dialogue_lines).contains("I saw them take you"), "the next run, she says so")
	await finish_dialogue(w2)


func test_characters_acknowledge_only_what_they_saw() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await interact_with(w, _wren(w))
	await finish_dialogue(w)
	await go_to(w, "room", "start")
	w.kill("arin", "test")  # in Arin's room: Wren isn't there
	var w2 := await wait_for_new_session(w)
	check(not memory().has_event("wren.saw_death"), "Wren didn't see a death in Arin's room")
	await go_to(w2, "square", "house")
	await interact_with(w2, _wren(w2))
	check(not " ".join(w2.hud._dialogue_lines).contains("take you"), "so she doesn't mention it")
	await finish_dialogue(w2)


func test_a_promise_and_a_restoration_are_remembered() -> void:
	memory().sessions = 2
	memory().encounters["wren"] = {"first": 1, "last": 1, "count": 2}
	memory().rel_events["wren.met"] = 1
	memory().rel_events["wren.promised"] = 1
	memory().rel_events["wren.promise_broken"] = 1
	var w := await start_session()
	w.note_restored("wren")
	await go_to(w, "square", "house")
	var told: Dictionary = _wren(w).interact()
	w.hud.close_dialogue()
	check(" ".join(told.lines).contains("You said you'd"), "restored after a broken promise: she half-remembers it (%s)" % [told.lines])
	check_eq(told.conversation, "wren.after_restore", "a conversation of its own")
	check_eq(Relationships.unresolved("wren"), "You promised her the Edge. She was deleted before you got there.", "the promise is still open in the journal")
	var hist := Relationships.history("wren")
	check(hist.has(Relationships.EVENTS["wren.restored"]) and hist.has(Relationships.EVENTS["wren.promised"]), "history lists what happened (%s)" % [hist])
	check(not hist.has(Relationships.EVENTS["wren.promise_kept"]), "and nothing that didn't")
	memory().rel_events["wren.sheltered"] = 1
	hist = Relationships.history("wren")
	check(hist.find(Relationships.EVENTS["wren.met"]) < hist.find(Relationships.EVENTS["wren.sheltered"]), "same run: meeting her comes first (%s)" % [hist])


func test_a_version_1_save_migrates_without_losing_anyone() -> void:
	var file := FileAccess.open(memory().TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "sessions": 4, "last_exit": "death", "wren_saved": true, "met_archivist": true,
		"mira_quest": "pinned", "acts_seen": ["room", "square", "oob"],
		"journal": [{"id": "square:NOTICE", "kind": "note", "title": "NOTICE", "area": "square", "lines": ["MISSING"]}]}))
	file.close()
	var m := memory()
	m.load_memory()
	check(m.has_met("wren") and m.has_met("mira") and m.has_met("archivist"), "everyone the old save implies was met (%s)" % [m.encounters.keys()])
	check(m.has_event("wren.promise_kept"), "Wren saw the Edge: that promise was kept")
	check_eq(m.places, ["room", "square", "oob"] as Array[String], "places come from the acts seen")
	check_eq(m.journal.size(), 1, "the journal is kept")
	check(not m.has_met("tobben"), "nobody is invented")
	m.save_memory()
	var data: Dictionary = SafeFile.read_json(m.TEST_SAVE_PATH)[0]
	check_eq(int(data.version), m.SAVE_VERSION, "saved back as the current version")

extends "res://tests/test_case.gd"
## Relationships beyond Wren (docs/NARRATIVE_CONTRACT.md §4, rev 2): Mira
## and Tobben choose what to say from what happened between you, through one
## selection path; events keep their order and how often they happened;
## nothing is acknowledged that the character couldn't know; old saves
## migrate.


func _lines(w: Node) -> String:
	return " ".join(w.hud._dialogue_lines)


func _died_in_room_with_mira(w: Node) -> Node:
	w.player.global_position = w.area.mira.global_position + Vector2(0, 30)
	await frames(2)
	w.kill("overwritten", "arin")
	return await wait_for_new_session(w)


func test_mira_reunion_after_she_saw_you_taken() -> void:
	var w := await start_session()
	await interact_with(w, w.area.mira)
	check(_lines(w).contains("You're up early"), "first meeting: her introduction")
	await finish_dialogue(w)
	var w2 := await _died_in_room_with_mira(w)
	check(memory().has_event("mira.saw_death"), "she was in the room: she saw it")
	await interact_with(w2, w2.area.mira)
	var said := _lines(w2)
	check(said.contains("You went grey"), "she talks about what she saw (%s)" % said)
	check(said.begins_with(Relationships.MIRA_HUSHED), "restricted now, so quickly (%s)" % said)
	check(not said.contains("You're up early"), "and never introduces herself again")
	await finish_dialogue(w2)
	await interact_with(w2, w2.area.mira)
	said = _lines(w2)
	check(not said.contains("You went grey"), "said once (%s)" % said)
	check(said.begins_with(Relationships.MIRA_GREETING_HUSHED), "then the familiar greeting (%s)" % said)
	await finish_dialogue(w2)


func test_an_interrupted_mira_conversation_is_said_again() -> void:
	memory().sessions = 2
	memory().encounters["mira"] = {"first": 1, "last": 2, "count": 2}
	memory().event_at("mira.met", 1)
	memory().event_at("mira.saw_death", 2)
	memory().last_exit = "death"
	memory().last_death = "arin"
	memory().purge = 1
	var w := await start_session()
	await interact_with(w, w.area.mira)
	check(_lines(w).contains("You went grey"), "she starts to tell you")
	w.player.global_position += Vector2(-160, 0)
	await wait_until(func() -> bool: return not w.hud.is_dialogue_open(), 3.0, "the box to close as you leave")
	check(not memory().has_conversation("mira.after_death:2"), "walked away: not heard")
	await interact_with(w, w.area.mira)
	check(_lines(w).contains("You went grey"), "so she tries again")
	await finish_dialogue(w)
	check(memory().has_conversation("mira.after_death:2"), "read to the end: heard")


func test_several_sessions_later() -> void:
	# She saw you taken in session 2 and hasn't seen you since (you woke
	# elsewhere, or quit): the first time you meet again, she says so.
	memory().sessions = 5
	memory().encounters["mira"] = {"first": 1, "last": 2, "count": 2}
	memory().event_at("mira.met", 1)
	memory().event_at("mira.saw_death", 2)
	memory().last_exit = "quit"
	memory().purge = 0
	var w := await start_session()
	var told: Dictionary = w.area.mira.interact()
	w.hud.close_dialogue()
	check(" ".join(told.lines).contains("You went grey"), "not met since: she still says it, three runs later")
	# Met since, and said: then it's old news, and only a greeting.
	memory().complete_conversation(told.conversation)
	memory().session_recalled.clear()
	told = w.area.mira.interact()
	w.hud.close_dialogue()
	check(not " ".join(told.lines).contains("You went grey"), "said once")
	check(told.lines[0] == Relationships.MIRA_GREETING, "a familiar greeting (%s)" % str(told.lines))
	check(not " ".join(told.lines).contains("You're up early"), "not an introduction")


func test_a_consequence_waits_for_the_next_meeting() -> void:
	# Met in session 3 after a death in session 2 that she didn't talk about
	# (say, the box was never opened): met since, so it isn't brought up as new.
	memory().sessions = 4
	memory().encounters["mira"] = {"first": 1, "last": 3, "count": 3}
	memory().event_at("mira.saw_death", 2)
	check_eq(Relationships.unacknowledged("mira", "mira.saw_death"), -1, "seen since: not the first meeting after it")
	memory().encounters["mira"].last = 2
	check_eq(Relationships.unacknowledged("mira", "mira.saw_death"), 2, "not seen since: still to be said")


func test_each_restoration_is_its_own_moment() -> void:
	memory().sessions = 3
	memory().encounters["mira"] = {"first": 1, "last": 2, "count": 2}
	memory().event_at("mira.met", 1)
	var w := await start_session()
	w.note_restored("mira")
	await interact_with(w, w.area.mira)
	check(_lines(w).contains("dark in between"), "restored: she remembers the dark")
	await finish_dialogue(w)
	check(memory().has_conversation("mira.after_restore:1"), "that one's been said")
	w.note_restored("mira")
	check_eq(memory().event_count("mira.restored"), 2, "a second restoration is counted")
	await interact_with(w, w.area.mira)
	check(_lines(w).contains("dark in between"), "and she has something to say about it too")
	await finish_dialogue(w)
	check(Relationships.history("mira").any(func(h: String) -> bool: return h.contains("Recycle Bin") and h.contains("2 times")),
		"the journal lists it once, with its count (%s)" % str(Relationships.history("mira")))


func test_reset_mira_knows_nothing_of_you() -> void:
	memory().sessions = 3
	memory().encounters["mira"] = {"first": 1, "last": 2, "count": 2}
	memory().event_at("mira.met", 1)
	memory().event_at("mira.pinned", 1)
	memory().event_at("mira.reset", 2)
	memory().mira_quest = "reset"
	memory().last_exit = "death"
	var w := await start_session()
	var told: Dictionary = w.area.mira.interact()
	w.hud.close_dialogue()
	check_eq(told.lines, [Story.MIRA_RESET_LINES[0]], "reset: only her defaults, no greeting, no history")
	check(Relationships.unresolved("mira") == "She doesn't remember you.", "the journal says so")
	check(Relationships.history("mira").any(func(h: String) -> bool: return h.contains("reset")), "Rue still remembers what happened")


func test_fraying_is_urgent_alone_and_ordered_in_history() -> void:
	var w := await start_session()
	await interact_with(w, w.area.mira)
	await finish_dialogue(w)
	memory().fray("mira", "room")
	w.area.mira.refresh_fray()
	var told: Dictionary = w.area.mira.interact()
	w.hud.close_dialogue()
	check_eq(told.lines, [Story.FRAY_LINES.mira], "wearing her colour: that's all she can talk about")
	memory().return_piece("mira")
	told = w.area.mira.interact()
	w.hud.close_dialogue()
	check_eq(told.lines, [Story.FRAY_RETURNED.mira], "given back: said once, alone")
	check(Relationships.unresolved("mira") != "You're still wearing her colour.", "returned: nothing open")
	# Taken again, in the same session: the later occurrence wins.
	memory().fray("mira", "room")
	check(Relationships.after("mira.piece_taken", "mira.piece_returned"), "taken again after it was returned")
	check_eq(Relationships.unresolved("mira"), "You're still wearing her colour.", "so it's open again")
	var hist := Relationships.history("mira")
	var taken := hist.find(Relationships.EVENTS["mira.piece_taken"] + " (2 times)")
	var back := hist.find(Relationships.EVENTS["mira.piece_returned"])
	check(taken >= 0 and back > taken, "history: taken (twice) before given back (%s)" % str(hist))


func test_every_written_event_has_a_journal_label() -> void:
	# What the game writes (OwnerMemory.fray/return_piece, World, the areas).
	for who in Story.SHED_TARGETS:
		var piece := "ribbon" if who == "wren" else "piece"
		for id in ["%s.%s_taken" % [who, piece], "%s.%s_returned" % [who, piece], "%s.restored" % who]:
			check(Relationships.EVENTS.has(id), "%s is in the registry" % id)
	for id in ["mira.walked", "mira.pinned", "mira.note_lost", "mira.reset", "mira.saw_death", "mira.deleted", "mira.asked",
			"tobben.guestbook", "archivist.pointer"]:
		check(Relationships.EVENTS.has(id), "%s is in the registry" % id)


func test_one_topic_per_conversation() -> void:
	# Every memory and a witnessed death: before, the truth line, a recall
	# and a greeting all stacked in front of her usual lines.
	memory().sessions = 2
	memory().encounters["mira"] = {"first": 1, "last": 2, "count": 2}
	memory().event_at("mira.met", 1)
	memory().event_at("mira.saw_death", 2)
	memory().last_exit = "death"
	memory().last_death = "arin"
	memory().purge = 1
	for f in Story.FRAGMENTS:
		memory().fragments.append(f.id)
	var w := await start_session()
	var told: Dictionary = w.area.mira.interact()
	w.hud.close_dialogue()
	check_eq(told.lines, [Relationships.MIRA_HUSHED] + Relationships.MIRA_AFTER_DEATH, "first the consequence, alone")
	memory().complete_conversation(told.conversation)
	told = w.area.mira.interact()
	w.hud.close_dialogue()
	check_eq(told.lines, [Relationships.MIRA_HUSHED, Story.TRUTH_LINES.mira], "then the new topic, alone")


func test_mira_on_the_walk_and_after_it() -> void:
	var w := await start_session(true, true)
	w.player.global_position = w.area.mira.global_position + Vector2(0, 16)
	w.start_escort(w.area.mira)
	check(memory().has_event("mira.walked"), "walking her out is something that happened")
	await go_to(w, "square", "house")
	check(w.escort_id() == "mira", "she came with you")
	w.kill("overwritten", "arin")
	var w2 := await wait_for_new_session(w)
	check(memory().has_event("mira.note_lost"), "taken with her: her note is lost")
	check(not memory().has_event("mira.saw_death"), "in the square she didn't see it happen in her room")
	var told := Relationships.mira(w2.area.mira.state == Npc.State.RESTRICTED, false, false)
	check(" ".join(told.lines).contains("they took it off me"), "she says it was taken from her, not from you (%s)" % str(told.lines))


func test_tobben_remembers_without_reintroducing() -> void:
	memory().sessions = 3
	memory().encounters["tobben"] = {"first": 1, "last": 1, "count": 1}
	memory().event_at("tobben.met", 1)
	memory().found_guestbook = true
	memory().guestbook_restored = true
	memory().event_at("tobben.guestbook", 2)
	var w := await start_session()
	await go_to(w, "square", "house")
	await interact_with(w, w.area.tobben)
	check(_lines(w).contains("Two names"), "the guest book first (%s)" % _lines(w))
	await finish_dialogue(w)
	await interact_with(w, w.area.tobben)
	check_eq(_lines(w), Story.TRUTH_LINES.tobben, "then what he noticed: a new topic beats a greeting")
	await finish_dialogue(w)
	await interact_with(w, w.area.tobben)
	var said := _lines(w)
	check(said.begins_with(Relationships.TOBBEN_GREETING_BOOK), "then a greeting (%s)" % said)
	check(not said.contains("Finest wares"), "never the shop introduction again")
	await finish_dialogue(w)


func test_version_2_events_migrate_in_order() -> void:
	var m := memory()
	var v2 := {"version": 2, "sessions": 4, "last_exit": "death",
		"rel_events": {"wren.ribbon_returned": 3, "wren.met": 1, "wren.ribbon_taken": 3, "wren.sheltered": 1, "bad": "x", "inf": 1e400},
		"archive_seen": ["person:wren", "journal:note:a"], "mira_quest": "carried"}
	var data: Dictionary = m._migrate(v2)
	var ev: Dictionary = data.rel_events
	check(not ev.has("bad") and not ev.has("inf"), "unreadable values are dropped")
	check(int(ev["wren.met"].seq) < int(ev["wren.sheltered"].seq), "same session: story order")
	check(int(ev["wren.ribbon_taken"].seq) < int(ev["wren.ribbon_returned"].seq), "taken before returned")
	check(int(ev["wren.sheltered"].seq) < int(ev["wren.ribbon_taken"].seq), "earlier sessions first")
	check_eq(int(data.event_seq), 4, "the counter continues after them")
	check_eq(data.archive_seen, {"person:wren": "*", "journal:note:a": "*"}, "read entries stay read")
	check_eq(data.mira_quest, "", "no carried note in this build: she still has it")


func test_malformed_event_records_are_dropped() -> void:
	var m := memory()
	var path := OwnerMemory.TEST_SAVE_PATH
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 3, "sessions": 2, "last_exit": "death", "event_seq": 1,
		"rel_events": {"wren.met": {"first": 1, "last": 1, "count": 1, "seq": 7, "first_seq": 7},
			"wren.sheltered": {"first": 1.5, "last": 1, "seq": 2}, "wren.promised": "yes", "wren.saw_death": {"first": 1}},
		"facts": {"tobben.reports": 3, "oops": "z"}}))
	f.close()
	m.load_memory()
	check(m.has_event("wren.met"), "a good record loads")
	check(not m.has_event("wren.sheltered") and not m.has_event("wren.promised") and not m.has_event("wren.saw_death"),
		"half numbers, strings and missing fields are dropped")
	check(m.event_seq >= 7, "the counter can't hand out an order already used")
	check(m.knows_fact("tobben.reports") and not m.knows_fact("oops"), "facts load the same way")

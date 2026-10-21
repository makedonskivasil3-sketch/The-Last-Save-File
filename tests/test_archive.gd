extends "res://tests/test_case.gd"
## The archive (docs/NARRATIVE_CONTRACT.md §3): people only once met, facts
## only once learned, objects with where they are now (remembered isn't
## carried), places that survive retries, and nothing important silently
## dropped by a limit.


func _titles(section: String) -> Array:
	return ArchivePages.section(section).map(func(e: Dictionary) -> String: return e.title)


func _entry(section: String, key: String) -> Dictionary:
	for e in ArchivePages.section(section):
		if e.key == key:
			return e
	return {}


func test_people_appear_only_once_met_and_without_spoilers() -> void:
	var w := await start_session()
	check(_titles("people").is_empty(), "nobody before anyone is met")
	await go_to(w, "square", "house")
	await interact_with(w, w.area.wren)
	await finish_dialogue(w)
	check_eq(_titles("people"), ["WREN"], "Wren, once met (and only her: %s)" % [_titles("people")])
	var wren := _entry("people", "person:wren")
	check(wren.body.contains("SEEN:") and wren.body.contains("Stands by the crates"), "what you saw, marked as seen")
	check(not wren.body.contains("owner can't see"), "not what she hasn't told you yet")
	check(not wren.body.contains("CUT CONTENT"), "nor her future")
	check(wren.body.contains("LAST SEEN: Ashvale square"), "where you last saw her")
	check(not wren.body.contains("RUE:"), "no reading of her yet: one line isn't enough")
	check(not memory().look_of("wren").is_empty(), "her look as you saw her (for the portrait)")
	# Her second line tells you something: a claim, with its open question.
	await interact_with(w, w.area.wren)
	await finish_dialogue(w)
	wren = _entry("people", "person:wren")
	check(wren.body.contains("SAID:") and wren.body.contains("owner can't see what she stands beside"), "what she said, marked as said")
	check(wren.body.contains("UNKNOWN:") and wren.body.contains("Why the owner can't see"), "and what nobody has explained")
	check(wren.body.contains("RUE:"), "now Rue has a reading of her, marked as hers")
	Relationships.add("wren.promised")
	check(not _entry("people", "person:wren").body.contains("wants to see the Edge before"), "a promise isn't her telling you why")
	w._on_line_shown(Story.WREN_ASK)
	check(_entry("people", "person:wren").body.contains("wants to see the Edge before they delete her"), "learned when she asks")
	check(_entry("people", "person:wren").body.contains("STILL OPEN: You promised her the Edge."), "the open promise")


func test_facts_wait_for_the_line_that_tells_them() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await interact_with(w, w.area.tobben)
	await finish_dialogue(w)
	var tob := _entry("people", "person:tobben")
	check(not tob.body.contains("script"), "met: not yet told he reports you (%s)" % tob.body)
	for i in 2:
		await interact_with(w, w.area.tobben)
		await finish_dialogue(w)
	check(_entry("people", "person:tobben").body.contains("He says he has to report you"), "told: now it's known, as his claim")
	# Every fact's line is one the game really says.
	for id in ArchivePages.FACTS:
		var f: Dictionary = ArchivePages.FACTS[id]
		if f.has("line"):
			check(_line_exists(str(f.line)), "%s is taught by a real line" % id)


func _line_exists(line: String) -> bool:
	for scene in [ArinsRoom, VillageSquare, ArchiveArea]:
		for stem in scene.voice_lines():
			if line in scene.voice_lines()[stem]:
				return true
	return line in Story.TRUTH_LINES.values() or line == Story.WREN_ASK


func test_condition_is_what_rue_saw() -> void:
	memory().sessions = 2
	memory().encounters["mira"] = {"first": 1, "last": 1, "count": 1, "seen": {"state": "well", "session": 1}}
	memory().npc_fates["mira"] = "deleted"  # the owner did it after the last run; Rue hasn't seen
	memory().purge = 1
	check(_entry("people", "person:mira").body.contains("Themselves, when you last saw them. Since then: unknown."),
		"before she sees the room, she doesn't know (%s)" % _entry("people", "person:mira").body)
	check(not _entry("people", "person:mira").body.contains("Deleted"), "no omniscient deletion")
	check(not _entry("people", "person:mira").body.contains("Restricted"), "nor restriction from the purge count")
	memory().purge = 3  # far enough that the room loads her deleted
	var w := await start_session()
	check(_entry("people", "person:mira").body.contains("Deleted: you saw them gone."), "she sees it on waking (%s)" % _entry("people", "person:mira").body)


func test_objects_say_where_they_are_now() -> void:
	var w := await start_session()
	memory().fray("wren", "square")
	var ribbon := _entry("objects", "object:wren_piece")
	check(ribbon.body.contains("CARRIED"), "taken: carried (%s)" % ribbon.get("body", ""))
	memory().return_piece("wren")
	ribbon = _entry("objects", "object:wren_piece")
	check(ribbon.body.contains("RETURNED") and not ribbon.body.contains("CARRIED"), "given back: returned, not still carried")
	memory().add_fragment("controller")
	var pad := _entry("objects", "object:controller")
	check(pad.body.contains("REMEMBERED") and not pad.body.contains("CARRIED"), "remembered isn't carried")
	memory().found_controller = true
	pad = _entry("objects", "object:controller")
	check(pad.body.contains("SEEN") and pad.body.contains("Left there"), "seen, and left where it was")
	# Mira's note: heard of, carried by HER on the walk, then used or lost.
	check(_entry("objects", "object:mira_note").is_empty(), "nothing before she mentions it")
	memory().learn_fact("mira.note")
	check(_entry("objects", "object:mira_note").body.contains("HEARD OF"), "she told you about it")
	ArchivePages.escort_now = "mira"
	check(_entry("objects", "object:mira_note").body.contains("CARRIED") and _entry("objects", "object:mira_note").body.contains("Not by you"),
		"on the walk she carries it, not you")
	ArchivePages.escort_now = ""
	memory().mira_quest = "lost"
	var note := _entry("objects", "object:mira_note")
	check(note.body.contains("LOST") and note.body.contains("off Mira"), "lost: taken from her (%s)" % note.body)
	memory().mira_quest = "pinned"
	check(_entry("objects", "object:mira_note").body.contains("USED"), "pinned: used")


func test_places_survive_a_retry() -> void:
	var w := await start_session()
	check("room" in memory().places, "the room is discovered on waking")
	await go_to(w, "square", "house")
	w.kill("arin", "test")
	var w2 := await wait_for_new_session(w)
	check("square" in memory().places, "the square stays discovered after a death")
	check_eq(_titles("places"), ["Arin's room", "Ashvale square"], "listed in the order found")
	check(not _titles("places").has("The Edge"), "no place you haven't been")


func test_nothing_important_is_dropped_silently() -> void:
	var m := memory()
	var long: Array = []
	for i in 40:
		long.append("line %d" % i)
	check(m.record_read("bin:long.txt", "file", "long.txt", "BIN", long), "a long file is kept")
	check_eq(m.journal[0].lines.size(), 40, "with every line")
	for i in 150:
		m.record_read("test:%d" % i, "note", "NOTE %d" % i, "TEST", ["x"])
	check_eq(m.journal.size(), 151, "far more entries than the game has are all kept")
	m.save_memory()
	m.load_memory()
	check_eq(m.journal.size(), 151, "and loaded back")
	check_eq(m.journal[0].lines.size(), 40, "with every line")


func test_the_archive_panel_has_sections_and_marks_new_entries() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await interact_with(w, w.area.wren)
	await finish_dialogue(w)
	memory().record_read("square:NOTICE", "note", "NOTICE", "ASHVALE", ["MISSING: ONE (1) INTRUDER."])
	w._pause_menu.open()
	w._pause_menu._show_journal()
	await frames(3)
	var j: JournalPanel = w._pause_menu._journal
	check_eq(j.section, "documents", "the first time: opens on the newest kept thing")
	check(j.page_text().contains("INTRUDER"), "showing it")
	var people_tab: Button = j._tabs.get_child(ArchivePages.SECTIONS.find("people"))
	check(people_tab.text.begins_with(JournalPanel.NEW_MARK), "a new person is marked on its tab")
	people_tab.pressed.emit()
	await frames(2)
	check(j.page_text().contains("Stands by the crates"), "Wren's page")
	check(j._portrait.visible, "with her face")
	check_eq(memory().archive_mark("person:wren", _entry("people", "person:wren").rev), "new", "a glance isn't reading it")
	await wait(JournalPanel.DWELL + 0.3)
	check_eq(memory().archive_mark("person:wren", _entry("people", "person:wren").rev), "", "on the page long enough: read")
	check(not people_tab.text.begins_with(JournalPanel.NEW_MARK), "the mark goes")
	w._pause_menu.close()
	# Something new happens between you: the page is marked updated.
	Relationships.add("wren.promised")
	w._pause_menu.open()
	w._pause_menu._show_journal()
	await frames(3)
	check_eq(j.section, "people", "it reopens where you were reading")
	check_eq(j.shown_key(), "person:wren", "on the same entry")
	check(people_tab.text.begins_with(JournalPanel.UPDATED_MARK), "her page says something new: updated (%s)" % people_tab.text)
	w._pause_menu.close()


func test_a_mouse_pass_doesnt_mark_things_read() -> void:
	for i in 3:
		memory().record_read("test:%d" % i, "note", "NOTE %d" % i, "TEST", ["x %d" % i])
	var w := await start_session()
	w._pause_menu.open()
	w._pause_menu._show_journal()
	await frames(3)
	var j: JournalPanel = w._pause_menu._journal
	for b in j._list.get_children():
		b.mouse_entered.emit()  # sweeping the pointer down the list
		await frames(1)
	var unread := ArchivePages.documents().filter(func(e: Dictionary) -> bool: return JournalPanel.mark_of(e) == "new")
	check(unread.size() >= 2, "a sweep past entries reads none of them (%d still new)" % unread.size())
	(j._list.get_child(0) as Button).pressed.emit()
	await frames(2)
	check_eq(JournalPanel.mark_of(ArchivePages.documents()[0]), "", "a click is reading on purpose")
	w._pause_menu.close()

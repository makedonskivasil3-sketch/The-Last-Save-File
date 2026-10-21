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
	check(wren.body.contains("Stands by the crates"), "what you saw")
	check(not wren.body.contains("Wants to see the Edge"), "not what she hasn't told you yet")
	check(not wren.body.contains("Cut content"), "nor her future")
	check(wren.body.contains("LAST SEEN: Ashvale square"), "where you last saw her")
	check(wren.body.contains("RUE:"), "Rue's own reading, marked as hers")
	check(not memory().look_of("wren").is_empty(), "her look as you saw her (for the portrait)")
	Relationships.add("wren.promised")
	check(_entry("people", "person:wren").body.contains("Wants to see the Edge"), "learned once she asked and you promised")
	check(_entry("people", "person:wren").body.contains("STILL OPEN: You promised her the Edge."), "the open promise")


func test_objects_say_where_they_are_now() -> void:
	var w := await start_session()
	memory().fray("wren", "square")
	var ribbon := _entry("objects", "object:wren_piece")
	check(ribbon.body.contains("Carried"), "taken: carried (%s)" % ribbon.get("body", ""))
	memory().return_piece("wren")
	ribbon = _entry("objects", "object:wren_piece")
	check(ribbon.body.contains("Returned") and not ribbon.body.contains("Carried"), "given back: returned, not still carried")
	memory().found_controller = true
	var pad := _entry("objects", "object:controller")
	check(pad.body.contains("Left there"), "a remembered thing isn't in your pocket")
	memory().mira_quest = "lost"
	check(_entry("objects", "object:mira_note").body.contains("Lost"), "a lost note says lost")


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
	check_eq(j.section, "documents", "opens on the newest kept thing")
	check(j.page_text().contains("INTRUDER"), "showing it")
	var people_tab: Button = j._tabs.get_child(ArchivePages.SECTIONS.find("people"))
	check(people_tab.text.begins_with(JournalPanel.NEW_MARK), "a new person is marked on its tab")
	j.show_section("people")
	await frames(2)
	check(j.page_text().contains("Stands by the crates"), "Wren's page")
	check(j._portrait.visible, "with her face")
	check("person:wren" in memory().archive_seen, "opened: no longer new")
	j.show_section("people")
	check(not people_tab.text.begins_with(JournalPanel.NEW_MARK), "the mark goes")
	w._pause_menu.close()

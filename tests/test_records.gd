extends "res://tests/test_case.gd"
## Replay: the RECORDS screen, and characters (and the owner) remembering
## how your last runs went.


func test_records_count_endings_including_rue() -> void:
	var m := memory()
	m.begin_session()
	m.record_win("escape")
	check_eq(m.endings_seen, ["escape"] as Array[String], "the plain escape")
	for f in Story.FRAGMENTS:
		m.add_fragment(f.id)
	m.begin_session()
	m.record_win("escape")
	check("rue" not in m.endings_seen, "every memory without the truth is still the escape")
	m.knows_truth = true
	m.begin_session()
	m.record_win("escape")
	check("rue" in m.endings_seen, "taking the slot with every memory, knowing what you are, is RUE")
	check(RecordsPanel.progress_line().begins_with("ENDINGS 2/6"), RecordsPanel.progress_line())
	check(RecordsPanel.progress_line().contains("MEMORIES 5/5"), "memories counted")


func test_deaths_remember_why() -> void:
	var m := memory()
	m.begin_session()
	m.record_death("edge", Vector2.ZERO, "cursor")
	m.begin_session()
	m.record_death("edge", Vector2.ZERO, "cursor")
	check_eq(m.last_death, "cursor", "the last death's cause")
	check_eq(int(m.death_causes.get("cursor", 0)), 2, "counted per cause")
	check(RecordsPanel.worst_death().contains("selected"), "the records name what got you most")
	m.load_memory()
	check_eq(m.last_death, "cursor", "and it survives a reload")


func test_owner_remembers_how_you_died() -> void:
	var m := memory()
	m.sessions = 2
	m.deaths = 1
	m.last_exit = "death"
	m.last_death = "cursor"
	var w := await start_session()
	check(_owner_said(w).contains(Story.OWNER_DEATH_RECALL.cursor), "the owner brings up the click")
	check_eq(w.area.note.text, Story.NOTE_RECALL.cursor, "and so does the note")


func test_mira_remembers_the_message() -> void:
	var m := memory()
	m.sessions = 2
	m.wins = 1
	m.last_ending = "message"
	m.last_exit = "win"
	var w := await start_session()
	var talk: Dictionary = w.area.mira.interact()
	check(str(talk.lines[0]).contains("watched"), "Mira's first line remembers the message ending (%s)" % talk.lines[0])
	var again: Dictionary = w.area.mira.interact()
	check(not str(again.lines[0]).contains("watched"), "only once a session")


func test_tobben_misses_wren() -> void:
	var m := memory()
	m.sessions = 3
	m.last_exit = "death"
	m.npc_fates["wren"] = "deleted"
	var w := await start_session()
	await go_to(w, "square", "house")
	var talk: Dictionary = w.area.tobben.interact()
	check(str(talk.lines[0]).contains("buy nothing"), "Tobben remembers Wren (%s)" % talk.lines[0])


func test_nothing_to_remember_on_a_first_run() -> void:
	var w := await start_session(true, true)
	var talk: Dictionary = w.area.mira.interact()
	check_eq(talk.lines.size(), 1, "just Mira's usual line")


func test_title_shows_records() -> void:
	var m := memory()
	m.sessions = 2
	m.begin_session()
	m.record_win("wren")
	m.wren_saved = true
	m.save_memory()
	tree.change_scene_to_file("res://scenes/title.tscn")
	await frames(5)
	check(_text().contains("ENDINGS 1/6"), "the save card shows progress")
	var title := scene()
	title._show_records()
	await frames(2)
	var text := _text()
	check(text.contains("A NEW GAME FOR WREN"), "the ending you saw is named")
	check(text.contains("Take Slot 2 with every memory, knowing what you are."), "the rest give a hint")
	check(text.contains("Wren saw the Edge"), "secrets found are listed")
	await press("ui_cancel")
	check(title._panel_of(title._menu).visible, "back to the menu")


func _owner_said(w: Node) -> String:
	var out := ""
	for q in w.hud._queue:
		out += str(q.text) + "\n"
	for l in w.hud._console.find_children("*", "Label", true, false):
		out += (l as Label).text + "\n"
	if w.hud._typing:
		out += w.hud._typing.text
	return out


func _text() -> String:
	var out := ""
	for l in scene().find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out += (l as Label).text + "\n"
	return out

extends "res://tests/test_case.gd"
## Mira's corner (docs/production/CHARACTERS.md): her two cups, and what her
## story has left on her table; she keeps watch at the window once her note
## is up; the owner's restriction is drawn round her.


func _room() -> Node:
	var w := await start_session()
	w.director.paused = true
	await wait(0.3)
	return w


func test_her_note_is_on_the_table_before_she_asks() -> void:
	var w := await _room()
	var room: ArinsRoom = w.area
	check(room.corner != null and room.corner.note_on_table(), "her note, folded, on her table")
	var folded: Readable = null
	for n in room.interactables:
		if n is Readable and n.title == "MIRA'S NOTE":
			folded = n
	check(folded != null, "Rue can look at it")
	check(folded != null and World.object_name(folded) == "MIRA'S NOTE", "named")
	var said: Array = folded.interact().lines if folded else []
	check(said.size() > 0 and str(said[0]).contains("FOR THE BOARD"), "only the outside (%s)" % str(said))


func test_pinned_she_watches_from_the_window() -> void:
	memory().sessions = 2
	memory().mira_quest = "pinned"
	var w := await _room()
	var room: ArinsRoom = w.area
	check(not room.corner.note_on_table(), "the note is in the square now")
	check(room.mira.global_position.distance_to(ArinsRoom.MIRA_WINDOW) < 1.0, "she keeps watch at the window")


func test_lost_and_reset_leave_their_marks() -> void:
	memory().sessions = 2
	memory().mira_quest = "lost"
	var w := await _room()
	check_eq(w.area.corner.quest, "lost", "the confiscated note: a cup upside down, a blank sheet")
	check(not w.area.corner.note_on_table(), "no note")


func test_kept_by_the_owner_is_drawn() -> void:
	memory().sessions = 2
	memory().purge = 1
	var w := await _room()
	check(w.area.mira.state == Npc.State.RESTRICTED, "(restricted)")
	check(w.area.corner.kept, "the owner's selection box round where she's kept")


func test_a_deleted_mira_leaves_no_table_and_nothing_behind() -> void:
	memory().purge = 3  # Mira deleted (World.is_mira_deleted)
	var before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var w := await start_session()
	check(w.area.corner == null, "no table: she isn't there")
	await go_to(w, "square", "house")
	check_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), before, "and no stray node left over from the room")

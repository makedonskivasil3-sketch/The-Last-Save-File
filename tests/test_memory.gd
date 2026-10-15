extends "res://tests/test_case.gd"
## OwnerMemory: what the owner learns, what survives, what a reset clears.


func test_uses_test_save_file() -> void:
	check_eq(memory()._path, memory().TEST_SAVE_PATH, "tests must never write the real save")


func test_wipe_resets_everything() -> void:
	var m := memory()
	m.begin_session()
	m.note_helper("wren")
	m.add_fragment("well")
	m.record_death("square", Vector2(10, 20))
	m.wipe()
	check_eq(m.sessions, 0, "sessions")
	check_eq(m.deaths, 0, "deaths")
	check_eq(m.purge, 0, "purge")
	check(m.deaths_log.is_empty(), "deaths_log cleared")
	check(m.npc_fates.is_empty(), "npc fates cleared")
	check(m.fragments.is_empty(), "fragments cleared")
	check_eq(m.last_exit, "none", "last exit")


func test_death_records_area_position_and_purge() -> void:
	var m := memory()
	m.begin_session()
	m.record_death("archive", Vector2(120, 80))
	check_eq(m.deaths, 1, "death counted")
	check_eq(m.purge, 1, "purge rises")
	check_eq(m.last_exit, "death", "last exit")
	check_eq(m.deaths_in("archive"), [Vector2(120, 80)] as Array[Vector2], "death position remembered per area")
	check(m.deaths_in("room").is_empty(), "other areas unaffected")


func test_session_closes_only_once() -> void:
	var m := memory()
	m.begin_session()
	m.record_death("room", Vector2.ZERO)
	m.record_quit()  # e.g. window closed during the death screen
	check_eq(m.quits, 0, "a closed session can't also be quit")
	check_eq(m.purge, 1, "purge only rises once per session")


func test_bad_ending_teaches_owner_helpers_and_seam() -> void:
	var m := memory()
	m.begin_session()
	m.note_helper("wren")
	m.note_seam(2)
	m.record_quit()
	check(m.is_deleted("wren"), "the owner deletes whoever helped")
	check(2 in m.patched_seams, "the seam used gets patched")


func test_owner_never_patches_the_last_seam() -> void:
	var m := memory()
	for i in m.SEAM_COUNT:
		m.begin_session()
		m.note_seam(i)
		m.record_death("room", Vector2.ZERO)
	check_eq(m.patched_seams.size(), m.SEAM_COUNT - 1, "one seam always stays open")


func test_win_does_not_purge() -> void:
	var m := memory()
	m.begin_session()
	m.note_helper("wren")
	m.record_win()
	check_eq(m.wins, 1, "win counted")
	check_eq(m.purge, 0, "winning isn't punished")
	check(not m.is_deleted("wren"), "helpers are safe after a win")


func test_killed_process_counts_as_crash() -> void:
	var m := memory()
	m.begin_session()  # last_exit is now "active", as if the game is running
	m.load_memory()    # ...and is launched again without closing properly
	check_eq(m.last_exit, "crash", "unclosed session becomes a crash")
	check_eq(m.quits, 1, "crash counts as a quit")
	check_eq(m.purge, 1, "crash raises purge")


func test_fragments_survive_death_and_purge() -> void:
	var m := memory()
	m.begin_session()
	m.add_fragment("controller")
	m.record_death("room", Vector2.ZERO)
	m.load_memory()
	check(m.has_fragment("controller"), "your memories aren't the owner's to take")


func test_old_save_format_migrates() -> void:
	var file := FileAccess.open(memory().TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"sessions": 3, "deaths": 1, "purge": 1, "last_exit": "death", "death_positions": [[100, 50]]}))
	file.close()
	var m := memory()
	m.load_memory()
	check_eq(m.sessions, 3, "sessions read")
	check_eq(m.deaths_in("room"), [Vector2(100, 50)] as Array[Vector2], "old death positions move to Arin's room")


func test_purge_reaches_max() -> void:
	var m := memory()
	for i in m.MAX_PURGE:
		m.begin_session()
		m.record_quit()
	check(m.is_purged(), "six quits purge the intruder")

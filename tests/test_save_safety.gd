extends "res://tests/test_case.gd"
## The owner's memory file can't be lost: atomic writes with a backup,
## recovery from a damaged file, typed reads, a version number.


func _path() -> String:
	return OwnerMemory.TEST_SAVE_PATH


func _write_raw(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func test_saves_are_versioned_and_backed_up() -> void:
	var m := memory()
	m.sessions = 3
	m.save_memory()
	m.sessions = 4
	m.save_memory()
	check_eq(int(_read(_path()).get("version", -1)), OwnerMemory.SAVE_VERSION, "the save carries its version")
	check_eq(int(_read(_path()).sessions), 4, "the new save is in place")
	check_eq(int(_read(_path() + SafeFile.BAK).sessions), 3, "the previous one is kept as a backup")
	check(not FileAccess.file_exists(_path() + SafeFile.TMP), "no temp file left behind")


func test_a_half_written_save_recovers_from_the_backup() -> void:
	var m := memory()
	m.sessions = 5
	m.add_fragment("couch")
	m.save_memory()
	m.save_memory()  # now the backup holds it too
	_write_raw(_path(), "{\n\t\"sessions\": 5,\n\t\"fragm")  # killed mid-write
	m.sessions = 0
	m.fragments.clear()
	m.load_memory()
	check_eq(m.sessions, 5, "progress comes back from the backup")
	check("couch" in m.fragments, "memories too")
	check(FileAccess.file_exists(_path() + SafeFile.CORRUPT), "the damaged file is kept, not silently overwritten")


func test_nothing_readable_starts_fresh_without_crashing() -> void:
	var m := memory()
	m.save_memory()
	_write_raw(_path(), "garbage")
	_write_raw(_path() + SafeFile.BAK, "[1, 2, 3]")
	m.sessions = 9
	m.load_memory()
	check_eq(m.sessions, 9, "nothing usable: nothing is overwritten in memory either")


func test_wrong_types_fall_back_instead_of_stopping_the_load() -> void:
	var m := memory()
	var log: Array = []
	for i in 30:
		log.append({"area": "room", "x": 10.0, "y": 10.0, "session": i})
	_write_raw(_path(), JSON.stringify({
		"version": 1,
		"sessions": "abc",
		"found_pip": "true",
		"wins": [1],
		"purge": 999,
		"fragments": "abc",
		"endings_seen": {"rue": 1},
		"npc_fates": [1, 2],
		"death_causes": {"cursor": [1], "save": 2},
		"route_memory": [{"x": 1, "y": 2}],
		"deaths_log": log,
		"patched_seams": [1, 1, "x", 2],
		"found_controller": true,
		"last_exit": "death",
	}))
	SafeFile.remove_copies(_path())
	m.load_memory()
	check_eq(m.sessions, 0, "a string count falls back to 0")
	check(not m.found_pip, "\"true\" (a string) isn't true")
	check_eq(m.wins, 0, "a list count falls back to 0")
	check_eq(m.purge, OwnerMemory.MAX_PURGE, "purge is clamped")
	check(m.fragments.is_empty(), "a string isn't split into fragments")
	check(m.endings_seen.is_empty(), "a dictionary isn't a list of endings")
	check(m.npc_fates.is_empty(), "a list isn't a dictionary of fates")
	check_eq(m.death_causes, {"save": 2}, "only numeric death counts survive")
	check(m.route_memory.is_empty(), "route spots need a weight and an area")
	check_eq(m.deaths_log.size(), OwnerMemory.MAX_REMEMBERED_DEATHS, "the death log is capped on load")
	check_eq(m.patched_seams, [1, 2] as Array[int], "seams: numbers, once each")
	check(m.found_controller, "the fields after the bad ones still load")
	check_eq(m.last_exit, "death", "all the way to the end")


func test_an_unversioned_save_still_loads() -> void:
	var m := memory()
	_write_raw(_path(), JSON.stringify({"sessions": 2, "death_positions": [[10, 20]], "last_exit": "quit"}))
	SafeFile.remove_copies(_path())
	m.load_memory()
	check_eq(m.sessions, 2, "version 0 saves load")
	check_eq(m.deaths_log.size(), 1, "and their old death positions convert")


func test_reset_removes_the_backup() -> void:
	var m := memory()
	m.sessions = 7
	m.save_memory()
	m.save_memory()
	m.wipe()
	check(not FileAccess.file_exists(_path() + SafeFile.BAK), "a reset can't be undone by the backup")
	_write_raw(_path(), "garbage")
	m.load_memory()
	check_eq(m.sessions, 0, "after a reset there's nothing old to recover")

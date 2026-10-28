extends "res://tests/test_case.gd"
## Save and exit never reports success it didn't get (ISSUE_REGISTER SV-3).
## Every step of SafeFile.write_atomic is made to fail in turn: the run stays
## open, the last save and its backup are untouched, and Retry works.


func after_each() -> void:
	SafeFile.fail_at = ""
	super()


func _calm_square() -> Node:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.position = Vector2(560, 280)
	w.area.arin.route = [Vector2(560, 280)] as Array[Vector2]
	w.player.global_position = Vector2(200, 200)
	w.director.awareness = 0.0
	await frames(3)
	return w


func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<none>"


func test_unwritable_destination_is_a_failure() -> void:
	var w := await _calm_square()
	var real: String = memory()._path
	memory()._path = "user://no_such_dir/deeper/save.json"
	var ok: bool = memory().record_suspend("square", Vector2(200, 200), World.SUSPEND_VERSION, {})
	var exists := FileAccess.file_exists(memory()._path)
	memory()._path = real
	check(not exists, "nothing was written")
	check(not ok, "so record_suspend reports failure")
	check(memory().session_armed(), "the run is still open")
	check_eq(memory().last_exit, "active", "and still counted as running")
	check(memory().suspend.is_empty(), "no suspend record left in memory")
	check(memory().suspend_error.contains("couldn't create"), "with a reason (%s)" % memory().suspend_error)
	check(not memory().suspend_error.contains("user://"), "that doesn't show the player a path")
	check(SafeFile.support_log.any(func(l: String) -> bool: return l.contains("no_such_dir")), "the path is in the support log")
	check_eq(w.ending, "", "the run carries on")


func test_every_step_of_the_write_can_fail_safely() -> void:
	var w := await _calm_square()
	var path: String = memory()._path
	memory().save_memory()
	memory().save_memory()  # so there is a backup too
	for step in ["open", "readback", "park", "backup", "rename"]:
		var main_before := _read(path)
		var bak_before := _read(path + SafeFile.BAK)
		check(main_before != "<none>" and bak_before != "<none>", "%s: a save and a backup to protect" % step)
		SafeFile.fail_at = step
		var ok: bool = memory().record_suspend("square", Vector2(200, 200), World.SUSPEND_VERSION, {})
		SafeFile.fail_at = ""
		check(not ok, "%s: reported as a failure" % step)
		check_eq(_read(path), main_before, "%s: the last save is untouched" % step)
		check_eq(_read(path + SafeFile.BAK), bak_before, "%s: and its backup" % step)
		check(not FileAccess.file_exists(path + SafeFile.TMP) and not FileAccess.file_exists(path + SafeFile.BAK + SafeFile.OLD), "%s: nothing half-written left behind" % step)
		check(memory().session_armed() and memory().last_exit == "active" and memory().suspend.is_empty(), "%s: the run is still open" % step)
	check(memory().record_suspend("square", Vector2(200, 200), World.SUSPEND_VERSION, {}), "then a retry succeeds")
	var data: Dictionary = JSON.parse_string(_read(path))
	check_eq(str(data.get("last_exit")), "suspend", "and the file on disk says so")
	check_eq(str((data.get("suspend", {}) as Dictionary).get("area", "")), "square", "with the record")
	check_eq(w.ending, "", "(record_suspend alone doesn't leave the run)")


func test_the_pause_menu_stays_and_offers_retry() -> void:
	var w := await _calm_square()
	w.open_pause()
	await frames(2)
	var menu = w._pause_menu
	SafeFile.fail_at = "rename"
	menu._do_suspend()
	await frames(2)
	check(menu.visible and tree.paused, "still paused in the menu")
	check(menu._panel_of(menu._save_failed).visible, "NOT SAVED is shown")
	check(menu._save_failed_label.text.contains("Nothing was lost"), "and says nothing was lost (%s)" % menu._save_failed_label.text)
	check(not menu._save_failed_label.text.contains("user://") and not menu._save_failed_label.text.contains(".json"), "without a path")
	check_eq(w.ending, "", "no SAVED, no leaving")
	check(w.hud._overlay_title.text != "SAVED", "the SAVED card never showed")
	SafeFile.fail_at = ""
	menu._do_suspend()
	await frames(2)
	check(not menu.visible, "Retry worked: the menu closes")
	check_eq(w.ending, "suspend", "and the run leaves, saved")
	check_eq(memory().last_exit, "suspend", "on disk as a suspend")


func test_return_to_game_keeps_playing() -> void:
	var w := await _calm_square()
	w.open_pause()
	await frames(2)
	var menu = w._pause_menu
	SafeFile.fail_at = "open"
	menu._do_suspend()
	SafeFile.fail_at = ""
	await frames(2)
	menu.close()
	await frames(2)
	check(not tree.paused and w.ending == "", "back in the run")
	var at: Vector2 = w.player.global_position
	await hold("move_right", 0.3)
	check(w.player.global_position.x > at.x + 5.0, "and Rue moves")
	memory().record_quit()
	check_eq(memory().quits, 1, "quitting afterwards still counts once, as before")


func test_a_crash_between_steps_never_loses_the_save() -> void:
	var path: String = memory()._path
	memory().sessions = 7
	memory().save_memory()
	memory().sessions = 8
	memory().save_memory()  # main: 8, bak: 7
	var newest := '{"sessions": 9}'
	# Died after parking the backup: main is still the newest complete file.
	DirAccess.rename_absolute(path + SafeFile.BAK, path + SafeFile.BAK + SafeFile.OLD)
	check_eq(int(SafeFile.read_json(path)[0].get("sessions", 0)), 8, "after parking: the save is read")
	# Died after moving main to the backup, before the new file went in.
	DirAccess.rename_absolute(path, path + SafeFile.BAK)
	var f := FileAccess.open(path + SafeFile.TMP, FileAccess.WRITE)
	f.store_string(newest)
	f.close()
	var got: Array = SafeFile.read_json(path)
	check_eq(int(got[0].get("sessions", 0)), 9, "before the final move: the complete new file is read")
	# The new file was cut short: the backup still holds the last save.
	f = FileAccess.open(path + SafeFile.TMP, FileAccess.WRITE)
	f.store_string('{"sessio')
	f.close()
	check_eq(int(SafeFile.read_json(path)[0].get("sessions", 0)), 8, "a torn new file falls back to the last good one")
	SafeFile.remove_copies(path)

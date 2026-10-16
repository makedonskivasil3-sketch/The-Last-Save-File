extends "res://tests/test_case.gd"
## The Recycle Bin: east of the Archive. Restore deleted characters between
## sweeps, shelter in a system file's shadow when the bin empties.


func _to_bin(w: Node) -> void:
	await go_to(w, "archive", "west")
	await go_to(w, "bin", "west")


func test_the_archive_leads_to_the_bin() -> void:
	var w := await start_session()
	await go_to(w, "archive", "west")
	var targets: Array = []
	for e in w.area.exits:
		targets.append(e.target_area)
	check("bin" in targets, "the Archive has a door east, to the bin")
	await go_to(w, "bin", "west")
	check_eq(w.area.area_id, "bin", "into the Recycle Bin")


func test_restore_wren_from_the_bin() -> void:
	memory().sessions = 3
	memory().npc_fates["wren"] = "deleted"
	var w := await start_session()
	await _to_bin(w)
	var file: BinFile = null
	for f in w.area.files:
		if f.npc_id == "wren":
			file = f
	check(file != null, "Wren's file is in the bin")
	w.area.next_empty = 60.0  # no sweep during this test
	w.player.global_position = file.global_position + Vector2(0, 12)
	w._interact(file)
	check(file.is_restoring(), "interacting starts the restore")
	await wait(BinFile.RESTORE_TIME + 0.5)
	check(file.done, "standing beside it finishes it")
	check(not memory().is_deleted("wren"), "Wren is back")
	check("wren" in memory().restored, "and the records remember it")


func test_stepping_away_pauses_a_restore() -> void:
	memory().sessions = 3
	memory().npc_fates["wren"] = "deleted"
	var w := await start_session()
	await _to_bin(w)
	var file: BinFile = w.area.files[0]
	w.area.next_empty = 60.0
	w.player.global_position = file.global_position + Vector2(0, 12)
	w._interact(file)
	await wait(1.0)
	w.player.global_position = file.global_position + Vector2(0, 80)
	var held := file.progress
	await wait(1.0)
	check_eq(file.progress, held, "away from the file, the restore waits")


func test_the_sweep_deletes_you_in_the_open() -> void:
	var w := await start_session()
	await _to_bin(w)
	w.player.global_position = Vector2(330, 150)
	w.area.next_empty = 0.5
	await wait_until(func() -> bool: return w.ending == "death", 6.0, "the sweep")
	check_eq(memory().last_death, "bin", "emptied with the bin")


func test_a_system_files_shadow_is_safe() -> void:
	var w := await start_session()
	await _to_bin(w)
	var f: Rect2 = RecycleBin.SYSTEM_FILES[0]
	var safe := Vector2(f.end.x + 10, f.get_center().y)
	check(RecycleBin.sheltered_at(safe), "just east of a system file is sheltered")
	w.player.global_position = safe
	w.area.next_empty = 0.3
	await wait_until(func() -> bool: return w.area.sweep_x >= 0.0, 3.0, "the sweep starts")
	await wait_until(func() -> bool: return w.area.sweep_x < 0.0, RecycleBin.SWEEP_TIME + 1.0, "the sweep ends")
	check_eq(w.ending, "", "you survived the sweep")


func test_pause_stops_the_bin() -> void:
	var w := await start_session()
	await _to_bin(w)
	w.area.next_empty = 5.0
	w.area.set_owner_paused(true)
	await wait(0.5)
	check_eq(w.area.next_empty, 5.0, "while the owner is paused the bin waits")


func test_the_guest_book_page() -> void:
	var w := await start_session()
	await _to_bin(w)
	var page: Node = null
	for n in w.area.interactables:
		if n is Readable and n.title == "guestbook_p2.txt":
			page = n
	check(page != null, "the torn page is in the bin")
	var text: Dictionary = page.interact()
	check(str(text.lines).contains("RUE"), "two names")
	check(memory().found_guestbook, "found, for good")
	check(RecordsPanel.progress_line().contains("SECRETS 1/7"), RecordsPanel.progress_line())
	memory().begin_session()
	check(Story.recall("tobben").contains("RUE"), "Tobben remembers the other name")


func test_a_sweep_resets_an_unfinished_restore() -> void:
	memory().sessions = 3
	memory().npc_fates["wren"] = "deleted"
	var w := await start_session()
	await _to_bin(w)
	var file: BinFile = w.area.files[0]
	w.player.global_position = file.global_position + Vector2(0, 12)
	w._interact(file)
	await wait(1.0)
	var f: Rect2 = RecycleBin.SYSTEM_FILES[0]
	w.player.global_position = Vector2(f.end.x + 10, f.get_center().y)  # shelter
	w.area.next_empty = 0.1
	await wait_until(func() -> bool: return w.area.sweep_x > file.global_position.x + 4.0, 4.0, "the sweep passes the file")
	check_eq(file.progress, 0.0, "the restore starts over")

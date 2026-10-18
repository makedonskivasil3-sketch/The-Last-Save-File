extends "res://tests/test_case.gd"
## The visual tour: every area and key moment as a screenshot, and the frame
## time in each. Not part of the test suite; for comparing the look (and the
## cost) before and after a visual change.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" $GODOT --path . -s res://tests/run_tests.gd \
##       -- --test-mode --tour --screenshots=/some/dir
##
## Frame times under xvfb use software GL: compare runs with each other on
## the same machine, never with real hardware. Each shot also appends a line
## to <dir>/frame_times.txt.


func _measure(name: String, frames_n := 90) -> void:
	await frames(5)
	var total := 0.0
	var worst := 0.0
	for i in frames_n:
		var t := Time.get_ticks_usec()
		await tree.process_frame
		var dt := (Time.get_ticks_usec() - t) / 1000.0
		total += dt
		worst = maxf(worst, dt)
	await shot(name)
	var w: Node = scene()
	if w and w.get("fx") != null:
		var fx: ScreenFx = w.fx
		print("TOUR %s aw=%.1f base=%.2f glitch=%.2f noise=%.2f smear=%.2f void=%.2f memory=%.2f squeeze=%.2f" % [name,
			w.director.awareness, fx.base_glitch, fx._glitch, fx._noise, fx.smear, fx.void_amount, fx.memory_amount, fx.squeeze])
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			var path := arg.trim_prefix("--screenshots=").path_join("frame_times.txt")
			var f := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
			f.seek_end()
			f.store_line("%-28s avg %6.2f ms   worst %6.2f ms" % [name, total / frames_n, worst])
			f.close()


func _calm(w: Node) -> void:
	w.director.paused = true
	var arin: Variant = w.area.get("arin")
	if arin is OwnerAvatar:
		arin.route = [Vector2(560, 270)] as Array[Vector2]


func test_tour_title() -> void:
	tree.change_scene_to_file("res://scenes/title.tscn")
	await wait(1.0)
	await _measure("00_title_first_launch")
	memory().sessions = 3
	memory().deaths = 2
	memory().purge = 2
	tree.change_scene_to_file("res://scenes/title.tscn")
	await wait(1.0)
	await _measure("01_title_after_runs")


## A true first launch: the boot, then the first seconds in control.
func test_tour_opening() -> void:
	tree.change_scene_to_file(MAIN_SCENE)
	await wait_until(func() -> bool: return scene() != null and scene().get("hud") != null, 5.0, "main scene")
	var w := scene()
	await wait(1.2)
	await _measure("02_opening_boot", 20)
	while w._cutscene:
		if w.hud.is_cinematic():
			await press("interact")
		await wait(0.3)
	await _measure("03a_wake_0s", 5)
	await wait(1.5)
	await _measure("03b_wake_2s", 5)
	await wait(3.0)
	await _measure("03c_wake_5s", 5)
	await wait(5.0)
	await _measure("03d_wake_10s", 5)


func test_tour_areas() -> void:
	var w := await start_session()
	await _measure("04_room")
	w.director.add_awareness(OwnerDirector.SUSPECT + 2.0)
	await wait(1.0)
	await _measure("05_room_suspect")
	for stop in [["square", "house"], ["archive", "west"], ["bin", "west"], ["house", "front"], ["oob", "top"], ["edge", "south"]]:
		await go_to(w, stop[0], stop[1])
		_calm(w)
		await wait(0.8)
		await _measure("1%d_%s" % [["square", "archive", "bin", "house", "oob", "edge"].find(stop[0]), stop[0]])


## Threats are frozen with the real PAUSE glitch once they've arrived (its
## pale "memory" tint is switched back off, and awareness is held), so the
## shots show the screen at that awareness, not a death.
func _freeze(w: Node) -> void:
	w.director.paused = true
	w.pause_owner(60.0)
	w.hud.set_banner("")
	await wait(0.7)
	w.fx.memory_amount = 0.0


func test_tour_threats() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.player.global_position = Vector2(470, 250)
	w.director.add_awareness(OwnerDirector.SUSPECT + 2.0)
	await wait(1.0)
	await _freeze(w)
	await _measure("19_square_suspect")
	w.resume_owner()
	w.director.owner_paused = 0.0
	w.director.paused = false
	w.director.add_awareness(OwnerDirector.HUNT + 1.0 - w.director.awareness)
	await wait(0.3)
	await _freeze(w)
	await _measure("20_square_hunt", 20)
	await wait(2.5)
	await _measure("20b_square_hunt_settled")


func test_tour_deaths() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	_calm(w)
	w.kill("selected", "cursor")
	await wait(1.4)
	await _measure("23_death_card_square", 20)
	await wait(0.6)
	await _measure("24_death_card_square_late", 20)
	w = await wait_for_new_session(w)
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	_calm(w)
	await wait(1.5)
	w.kill("erased", "eraser")
	await wait(1.4)
	await _measure("25_death_card_edge", 20)
	await wait(0.6)
	await _measure("26_death_card_edge_late", 20)


func test_tour_purged() -> void:
	var m := memory()
	m.sessions = 8
	m.deaths = 4
	m.quits = 2
	m.purge = OwnerMemory.MAX_PURGE
	m.last_exit = "death"
	m.save_memory()
	tree.change_scene_to_file(MAIN_SCENE)
	await wait(2.0)
	await _measure("40_purged_quiet", 20)
	await wait(World.PURGED_CARD_DELAY)
	await _measure("41_purged_card", 20)


func test_tour_slot_two() -> void:
	var w := await start_session()
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	w.area.cursor.position = Vector2(60, 270)
	w.player.global_position = Vector2(580, 66)
	await wait(2.0)
	await _measure("30_writing_slot_two")
	await wait_until(func() -> bool: return w._cutscene or w.hud.is_choosing(), 8.0, "Slot 2")
	await until_choosing(w)
	await _measure("31_slot_two_choice")
	await press("interact")
	await wait(4.0)
	await _measure("32_ending")


func test_tour_settings() -> void:
	tree.change_scene_to_file("res://scenes/title.tscn")
	await wait(1.0)
	scene()._show_settings()
	await wait(0.3)
	await _measure("50_settings", 5)
	settings().large_text = true
	settings().apply()
	await wait(0.3)
	await _measure("51_settings_large_text", 5)
	settings().large_text = false
	settings().apply()


func test_tour_journal() -> void:
	var m := memory()
	m.sessions = 2
	var f: Dictionary = Story.FRAGMENTS[0]
	m.record_read("room:NOTE", "note", "NOTE", "ARIN'S ROOM", ["STAY IN YOUR ROOM.", "I SAW YOU."])
	m.record_read("archive:SESSION LOG", "book", "SESSION LOG", "THE ARCHIVE", ["session 1: new game.", "session 2: something in arin's room."])
	m.record_read("memory:" + f.id, "memory", f.title, "ARIN'S ROOM", f.lines)
	tree.change_scene_to_file("res://scenes/title.tscn")
	await wait(1.0)
	await _measure("52_title_journal_button", 5)
	scene()._show_journal()
	await wait(0.3)
	await _measure("53_journal", 5)


func test_tour_tells() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var arin: OwnerAvatar = w.area.arin
	w.director.paused = true
	arin.route = [arin.global_position] as Array[Vector2]
	w.player.global_position = arin.global_position + arin._facing * 34.0
	await wait(0.5)
	await _measure("52_arin_points", 5)
	w.director.notice(8.0, "talking to MIRA")
	await wait(0.2)
	await _measure("53_awareness_reason", 3)

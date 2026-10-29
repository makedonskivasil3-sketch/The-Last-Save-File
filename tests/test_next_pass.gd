extends "res://tests/test_case.gd"
## docs/prompts/NEXT_PASS_2026-10-29.md: the build stamp, "Previously", the
## Owner pace setting and "Report a problem".


func after_each() -> void:
	settings().owner_pace = 0
	memory().away_seconds = 0.0
	BuildInfo.reset()
	super()


# --- 4. The build stamp ---------------------------------------------------------

func test_the_stamp_reads_dev_without_a_file() -> void:
	BuildInfo.reset()
	if FileAccess.file_exists(BuildInfo.PATH):
		check(BuildInfo.stamp().begins_with("build "), "a CI file: build %s" % BuildInfo.info().commit)
	else:
		check_eq(BuildInfo.stamp(), "build dev", "no file: dev")


func test_the_title_and_pause_menu_show_it() -> void:
	var title: Node = load("res://scenes/title.tscn").instantiate()
	tree.root.add_child(title)
	await frames(2)
	check_eq(title.build_label.text, BuildInfo.stamp(), "the title shows the build")
	var r: Rect2 = title.build_label.get_global_rect()
	check(r.position.x >= 400.0 and r.end.y <= 360.0, "bottom right, clear of the menu column (%s)" % r)
	title.queue_free()
	await frames(1)
	var w := await start_session()
	check_eq(w._pause_menu.build_label.text, BuildInfo.stamp(), "and the pause menu")


# --- 1. Previously ---------------------------------------------------------------

func test_previously_after_a_long_break() -> void:
	memory().sessions = 3
	memory().record_read("note:test", "note", "A NOTE", "room", ["the first line", "the second"], false)
	var w := await start_session()
	memory().away_seconds = World.RECAP_AFTER + 60.0
	w._recapped = false
	var lines: Array = w.previously()
	check(not lines.is_empty(), "back after a break: a recap")
	check(str(lines).contains("where i was"), "with the goal")
	check(str(lines).contains("A NOTE"), "and something she read")
	check(w.previously().is_empty(), "once per launch")


func test_no_previously_on_a_quick_return_or_a_first_run() -> void:
	memory().sessions = 3
	memory().record_read("note:test", "note", "A NOTE", "room", ["a line"], false)
	var w := await start_session()
	memory().away_seconds = 60.0
	w._recapped = false
	check(w.previously().is_empty(), "a minute away: nothing")
	memory().sessions = 1
	memory().away_seconds = World.RECAP_AFTER * 3.0
	w._recapped = false
	check(w.previously().is_empty(), "a first run: nothing")


func test_previously_only_tells_what_was_seen() -> void:
	memory().sessions = 2
	var w := await start_session()
	memory().journal.clear()
	memory().away_seconds = World.RECAP_AFTER * 2.0
	w._recapped = false
	check(w.previously().is_empty(), "nothing read yet: no recap that could invent one")


func test_the_save_keeps_when_it_was_written() -> void:
	memory().last_saved_unix_override = Time.get_unix_time_from_system() - 3600.0
	memory().save_memory()
	memory().last_saved_unix_override = -1.0
	memory().load_memory()
	check(memory().away_seconds > 3500.0 and memory().away_seconds < 3700.0, "an hour away (%.0f s)" % memory().away_seconds)


# --- 2. Owner pace ---------------------------------------------------------------

func test_normal_pace_changes_nothing() -> void:
	settings().owner_pace = 0
	for k in ["arin", "cursor", "static", "warning", "anything"]:
		check_eq(settings().pace(k), 1.0, "%s: 1.0 at Normal" % k)


func test_gentle_pace_slows_the_threats() -> void:
	settings().owner_pace = 1
	check_eq(settings().pace("arin"), 0.8, "Arin at 80%")
	check_eq(settings().pace("cursor"), 0.8, "the cursor at 80%")
	check_eq(settings().pace("static"), 0.6, "the static spreads at 60%")
	check_eq(settings().pace("warning"), 2.0, "a death spot warns twice as long")
	var w := await start_session()
	await go_to(w, "square", "house")
	var arin: OwnerAvatar = w.area.arin
	arin.paused = false
	var start := arin.global_position
	await wait(1.0)
	var gentle := arin.global_position.distance_to(start)
	check(gentle <= arin.speed * 0.8 * 1.15 + 1.0, "Arin walks no faster than 80%% of his speed (%.1f px in 1 s)" % gentle)


func test_the_pace_is_kept() -> void:
	settings().owner_pace = 1
	settings().save()
	settings().owner_pace = 0
	settings()._load()
	check_eq(settings().owner_pace, 1, "kept")


# --- 3. Report a problem ------------------------------------------------------------

func test_the_report_has_what_the_author_needs() -> void:
	var w := await start_session()
	w.hud.say("a line on the console", "self")
	await frames(2)
	var text: String = w.problem_report()
	for need in ["build ", "area: room", "session ", "goal: ", "owner pace normal", "last lines:"]:
		check(text.contains(need), "has %s" % need)
	check(not text.contains(OS.get_user_data_dir()), "no local paths")
	w.open_pause()
	await frames(1)
	w._pause_menu._show_report()
	check(w._pause_menu.last_report.contains("area: room"), "the pause menu's page shows (and copies) it")
	check(w._pause_menu._log_text.text.contains("Nothing is sent"), "and says nothing is sent")

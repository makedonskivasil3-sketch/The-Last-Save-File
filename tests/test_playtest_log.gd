extends "res://tests/test_case.gd"
## The development-only playtest log (docs/PLAYTEST_PLAN.md).


func after_each() -> void:
	PlaytestLog.reset(false)
	super()


func test_off_unless_asked_for() -> void:
	PlaytestLog.reset(false)
	var w := await start_session()
	await go_to(w, "square", "house")
	check(PlaytestLog.lines.is_empty(), "nothing is recorded in a normal game")


func test_records_the_session_sheet_moments() -> void:
	PlaytestLog.reset(true)
	var w := await start_session()
	w.player.velocity = Vector2(50, 0)
	await frames(2)
	await go_to(w, "square", "house")
	w.kill("selected", "cursor")
	await frames(2)
	var log := "\n".join(PlaytestLog.lines)
	check(log.contains("session"), "the session start")
	check(log.contains("first movement"), "first movement")
	check(log.contains("FIRST TIME OUT OF ARIN'S ROOM"), "leaving the room")
	check(log.contains("DIED") and log.contains("cursor"), "the death and its cause")
	check(PlaytestLog.lines[0].begins_with("00:0"), "timestamped")

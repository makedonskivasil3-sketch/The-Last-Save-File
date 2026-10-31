extends "res://tests/test_case.gd"
## The workshop mission's writes (ISSUE_REGISTER WS-1): each step is one
## write, failure is returned and told, the game retries, a relaunch loads
## the last good save, and nothing is half-saved or rewarded twice.


func after_each() -> void:
	SafeFile.fail_at = ""
	super()


func _workshop() -> World:
	var w: World = await start_session()
	await go_to(w, "workshop", "stairs")
	return w


func _on_disk() -> Dictionary:
	var read: Array = SafeFile.read_json(memory()._path)
	return read[0] if read[0] is Dictionary else {}


func _disk_has_event(id: String) -> bool:
	return (_on_disk().get("rel_events", {}) as Dictionary).has(id)


func _disk_has_note(id: String) -> bool:
	for e in _on_disk().get("journal", []):
		if e is Dictionary and str(e.get("id", "")) == id:
			return true
	return false


func test_a_step_is_one_write_event_and_note_together() -> void:
	var w := await _workshop()
	var room: LanternWorkshop = w.area
	check(room.wick.interact().begins_with("WICK KEPT"), "the wick is taken")
	check(_disk_has_event(LanternRoute.SPOOL) and _disk_has_note("workshop:" + LanternRoute.SPOOL), "event and note reached the disk together")


func test_a_failed_write_keeps_the_step_says_so_and_retries() -> void:
	var w := await _workshop()
	var room: LanternWorkshop = w.area
	SafeFile.fail_at = "rename"
	var said: String = room.wick.interact()
	check(said.contains("NOT SAVED YET"), "the feedback says it isn't saved (%s)" % said)
	check(Relationships.has(LanternRoute.SPOOL), "the wick stays taken in this run")
	check(memory().unsaved, "the game knows progress is unsaved")
	check(not _disk_has_event(LanternRoute.SPOOL) and not _disk_has_note("workshop:" + LanternRoute.SPOOL), "and nothing half-written is on disk")
	await wait(0.3)
	check(_said(w, "NOT SAVED"), "the console tells the player once")
	SafeFile.fail_at = ""
	check(await wait_until(func() -> bool: return not memory().unsaved, World.UNSAVED_RETRY + 2.0, "retry"), "the write is retried and lands")
	check(_disk_has_event(LanternRoute.SPOOL) and _disk_has_note("workshop:" + LanternRoute.SPOOL), "now both are on disk")
	await wait(0.3)
	check(_said(w, "progress saved"), "and the player is told")


func test_a_relaunch_after_a_failed_write_starts_the_step_again_cleanly() -> void:
	var w := await _workshop()
	var room: LanternWorkshop = w.area
	SafeFile.fail_at = "rename"
	room.wick.interact()
	SafeFile.fail_at = ""
	memory().unsaved = false  # quit before any retry: what a relaunch reads
	memory().load_memory()
	check(not Relationships.has(LanternRoute.SPOOL), "relaunched: the wick was never saved, so it's on the bench")
	check(not LanternRoute.repaired(), "and nothing later is half-done")
	var w2 := await start_session()
	await go_to(w2, "workshop", "stairs")
	check((w2.area as LanternWorkshop).wick.can_interact(), "the step can be done again: not stranded")


func test_no_reward_twice() -> void:
	var w := await _workshop()
	var room: LanternWorkshop = w.area
	room.wick.interact()
	room.lamp.interact()
	var n: int = memory().journal.size()
	var events: int = (memory().rel_events as Dictionary).size()
	check(memory().commit_step([LanternRoute.REPAIRED], "workshop:" + LanternRoute.REPAIRED, "A light kept burning", "workshop", ["again"]), "re-committing writes")
	check_eq(memory().journal.size(), n, "no second journal entry")
	check_eq((memory().rel_events as Dictionary).size(), events, "no second event")


func _said(w: Node, text: String) -> bool:
	for e in w.hud.history:
		if str(e.text).contains(text):
			return true
	for m in w.hud._queue:
		if str(m.text).contains(text):
			return true
	return false

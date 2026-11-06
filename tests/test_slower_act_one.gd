extends "res://tests/test_case.gd"
## A slower first act (Pacing; docs/production/SLOWER_ACT_ONE.md): glitches
## open one or two at a time, and Tobben doesn't report Rue in Act 1.


func before_each() -> void:
	await super.before_each()
	Pacing.staged = true


func after_each() -> void:
	Pacing.staged = false
	await super.after_each()


func _give_memories(n: int) -> void:
	memory().fragments.clear()
	for i in n:
		memory().fragments.append(Story.FRAGMENTS[i].id)


func test_in_arins_room_only_phase_is_offered() -> void:
	var w := await start_session(true, true)
	# Beside Mira: no FREEZE on someone friendly in the first minute.
	w.player.global_position = w.area.mira.global_position + Vector2(0, 14)
	w.player._sprite.facing = Vector2.UP
	await frames(4)
	check(w.glitch.target.get("id", "") != "freeze", "no FREEZE on Mira yet (%s)" % w.glitch.target.get("id", ""))
	# By the note: no FALSIFY yet.
	w.player.global_position = w.area.note.global_position + Vector2(0, 20)
	await frames(4)
	check(w.glitch.target.get("id", "") != "falsify", "no FALSIFY on the note yet")
	# At the crack: PHASE, the room's one lesson.
	w.player.global_position = ArinsRoom.CRACK + Vector2(0, 10)
	w.player._sprite.facing = Vector2.UP
	await frames(4)
	check_eq(w.glitch.target.get("id", ""), "phase", "the cracked wall can be phased")


func test_glitches_open_one_or_two_at_a_time() -> void:
	check_eq(Pacing.glitches_opened_by(1), ["freeze"] as Array[String], "the first memory: FREEZE alone")
	check_eq(Pacing.glitches_opened_by(2), ["unlock", "decoy"] as Array[String], "the well: UNLOCK and DECOY")
	check(Pacing.glitches_opened_by(3).size() <= 3, "never more than three at once")
	for id: String in Glitch.DEFS:
		check(Glitch.is_unlocked(id, Story.FRAGMENTS.size()), "%s is open by the last memory" % id)
	check(not Glitch.is_unlocked("freeze", 0) and Glitch.is_unlocked("phase", 0), "the start: PHASE only")


func test_the_first_memory_announces_freeze() -> void:
	var w := await start_session(true, true)
	_give_memories(1)
	w._learn_glitch(1)
	await frames(3)
	check(w.hud._area_title.text.contains("FREEZE"), "a NEW GLITCH card names FREEZE (%s)" % w.hud._area_title.text)


func test_two_new_glitches_get_a_card_each() -> void:
	var w := await start_session(true, true)
	_give_memories(2)
	w._learn_glitch(2)
	await frames(3)
	check(w.hud._area_title.text.contains("UNLOCK"), "first UNLOCK")
	await wait(3.6)
	check(w.hud._area_title.text.contains("DECOY"), "then DECOY, on its own card")


func test_tobben_does_not_report_in_act_one() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var sq: Node = w.area
	sq._tobben_reports()
	check(not sq._report_pending and sq._tobben_errand == "", "with one memory or none, talking to Tobben costs nothing")
	_give_memories(2)
	sq._tobben_reports()
	check(sq._report_pending or sq._tobben_errand != "", "from the well's memory on, he reports as before")


func test_staging_off_keeps_the_flat_rule() -> void:
	Pacing.staged = false
	check(Glitch.is_unlocked("freeze", 0) and Glitch.is_unlocked("falsify", 0), "tests and the flat rule: four from the start")
	check_eq(Glitch.unlocked_by(1), "decoy", "and DECOY with the first memory")

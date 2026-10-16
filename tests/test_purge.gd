extends "res://tests/test_case.gd"
## The purge ending: a clear end card with real buttons, a confirmed restore,
## and a warning on the death card one step before it.


func _purged_session() -> Node:
	var m := memory()
	m.sessions = 8
	m.deaths = 4
	m.quits = 2
	m.purge = OwnerMemory.MAX_PURGE
	m.last_exit = "death"
	m.save_memory()
	tree.change_scene_to_file(MAIN_SCENE)
	await wait_until(func() -> bool: return scene() != null and scene().get("purged") == true, 5.0, "the purged room")
	return scene()


func test_the_purged_screen_explains_itself() -> void:
	var w := await _purged_session()
	check(not w.hud.is_choosing(), "a moment of quiet first")
	await wait_until(func() -> bool: return w.hud.is_choosing(), World.PURGED_CARD_DELAY + 2.0, "the purge card")
	check_eq(w.hud._overlay_title.text, Story.PURGED_TITLE, "it says what happened")
	check(w.hud._overlay_body.text.contains("you died 4 times and you left twice"), "and how it got here (%s)" % w.hud._overlay_body.text)


func test_purged_by_quitting_alone_mentions_no_marks() -> void:
	var m := memory()
	m.deaths = 0
	m.quits = 6
	var body := Story.purged_body()
	check(body.contains("you left 6 times") and not body.contains("died"), body)
	check(not body.contains("marks"), "no deaths, no marks on the floor")


func test_back_to_the_title_from_the_purge() -> void:
	var w := await _purged_session()
	await wait_until(func() -> bool: return w.hud.is_choosing(), World.PURGED_CARD_DELAY + 2.0, "the purge card")
	w.hud._chosen.emit(1)
	await wait_until(func() -> bool: return scene() != null and scene().scene_file_path == World.TITLE_SCENE, 3.0, "the title")
	check(memory().is_purged(), "leaving changes nothing")


func test_restoring_needs_a_second_yes() -> void:
	var w := await _purged_session()
	await wait_until(func() -> bool: return w.hud.is_choosing(), World.PURGED_CARD_DELAY + 2.0, "the purge card")
	w.hud._chosen.emit(0)
	await frames(3)
	check(w.hud.is_choosing() and w.hud._choice_question.text == Story.PURGED_CONFIRM, "restoring asks first")
	w.hud._chosen.emit(1)  # No
	await frames(3)
	check(memory().is_purged(), "saying no keeps everything")
	check_eq(w.hud._choice_question.text, Story.PURGED_QUESTION, "back to the choice")
	w.hud._chosen.emit(0)
	await frames(3)
	var old_id := w.get_instance_id()
	w.hud._chosen.emit(0)  # Yes
	await wait_until(func() -> bool:
		var s := scene()
		return s != null and s.get_instance_id() != old_id and s.get("purged") == false and s.get("area") != null, 5.0, "a new game")
	check(not memory().is_purged(), "the owner forgot")
	check_eq(memory().deaths, 0, "everything")


func test_the_death_card_warns_one_step_before() -> void:
	memory().purge = OwnerMemory.MAX_PURGE - 2
	var w := await start_session()
	await go_to(w, "square", "house")
	w.kill("selected", "cursor")
	await wait_until(func() -> bool: return w.hud._overlay.visible, 3.0, "the death card")
	check_eq(memory().purge, OwnerMemory.MAX_PURGE - 1, "one step from the end")
	check(w.hud._overlay_body.text.contains(Story.PURGE_WARNING), "the death card says so (%s)" % w.hud._overlay_body.text)

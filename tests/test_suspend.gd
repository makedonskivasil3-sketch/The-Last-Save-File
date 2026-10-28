extends "res://tests/test_case.gd"
## Save and exit (docs/SAVE_AND_EXIT_PROPOSAL.md, option b): offered only at
## a safe moment, costs nothing, resumes where she stood once, and is spent
## the moment play starts. Quitting still counts.


## The square, calm, Rue away from Arin.
func _calm_square() -> Node:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.position = Vector2(560, 280)
	w.area.arin.route = [Vector2(560, 280)] as Array[Vector2]
	w.player.global_position = Vector2(200, 200)
	w.director.awareness = 0.0
	await frames(3)
	return w


func test_save_and_exit_resumes_once_and_counts_nothing() -> void:
	var w := await _calm_square()
	check_eq(w.suspend_blocker(), "", "a calm moment in the square is safe")
	var at: Vector2 = w.player.global_position
	var purge: int = memory().purge
	var quits: int = memory().quits
	var fates: Dictionary = memory().npc_fates.duplicate()
	w.flags["seen_by_lamp"] = true
	var old_id := w.get_instance_id()
	w._suspend()
	await wait_until(func() -> bool: return scene() != null and scene().get_instance_id() != old_id and scene().get("player") == null, 5.0, "the title")
	check_eq(memory().last_exit, "suspend", "the run was suspended, not quit")
	check_eq(memory().purge, purge, "no purge")
	check_eq(memory().quits, quits, "no quit counted")
	check_eq(memory().npc_fates, fates, "nobody who helped is found out")
	check_eq(memory().suspend.get("area"), "square", "one record: where she stood")
	var w2 := await start_session()
	check_eq(w2.area.area_id, "square", "the next launch resumes in the square")
	check(w2.woke_from_suspend, "from the suspend")
	check(w2.player.global_position.distance_to(at) < 2.0, "where she stood (%s)" % w2.player.global_position)
	check(w2.flags.get("seen_by_lamp", false), "with the run's flags")
	check(memory().suspend.is_empty(), "the record is spent once play starts")
	check_eq(memory().last_exit, "active", "an ordinary run from here")
	memory().record_quit()
	var w3 := await start_session()
	check_eq(w3.area.area_id, "room", "no second resume: a quit starts in Arin's room")
	check(not w3.woke_from_suspend, "and isn't a resume")


func test_only_at_a_safe_moment() -> void:
	var w := await _calm_square()
	w.director.awareness = OwnerDirector.HUNT + 1.0
	check(w.suspend_blocker().contains("looking for you"), "not while hunted (%s)" % w.suspend_blocker())
	w.director.awareness = 0.0
	w.area.arin.position = w.player.global_position + Vector2(30, 0)
	check(w.suspend_blocker().contains("this close"), "not with the owner beside her (%s)" % w.suspend_blocker())
	w.area.arin.position = Vector2(560, 280)
	w.debug("wren")
	await wait_until(func() -> bool: return w.escort != null, 3.0, "Wren following")
	check_eq(w.suspend_blocker(), "", "an escort doesn't block it: she goes home and asks again")
	w.lose_escort()
	await frames(2)
	w.player.frozen = false
	w.hud.show_dialogue("WREN", Color.WHITE, ["wait."])
	await frames(2)
	check(w.suspend_blocker().contains("conversation"), "not mid-conversation (%s)" % w.suspend_blocker())
	await finish_dialogue(w)
	var purge: int = memory().purge
	w.director.awareness = OwnerDirector.HUNT + 1.0
	w._suspend()
	await frames(3)
	check_eq(w.ending, "", "refused: the run carries on")
	check(memory().suspend.is_empty() and memory().purge == purge, "and nothing was written")


func test_never_at_the_edge() -> void:
	var w := await start_session()
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	check(w.suspend_blocker().contains("where it ends"), "the finale can't be suspended (%s)" % w.suspend_blocker())


func test_the_pause_menu_says_when_and_why() -> void:
	var w := await _calm_square()
	w.open_pause()
	await frames(2)
	var menu = w._pause_menu
	check(not menu._suspend.disabled, "offered when it's safe")
	check(menu._suspend_note.text.contains("nothing is counted"), "and says it costs nothing (%s)" % menu._suspend_note.text)
	check(menu._suspend_note.text.contains("may have moved on"), "without promising an exact snapshot")
	menu.close()
	await frames(2)
	w.director.awareness = OwnerDirector.HUNT + 1.0
	w.open_pause()
	await frames(2)
	check(menu._suspend.disabled, "not offered while hunted")
	check(menu._suspend_note.text.contains("looking for you"), "and says why (%s)" % menu._suspend_note.text)
	menu._ask_quit(true)
	check(menu._confirm_label.text.contains("Quitting counts"), "quitting still warns that it counts")
	menu.close()


func test_an_outdated_or_stale_record_starts_in_the_room() -> void:
	memory().sessions = 3
	memory().last_exit = "suspend"
	memory().suspend = {"area": "square", "x": 200.0, "y": 200.0, "version": World.SUSPEND_VERSION - 1, "session": 3, "flags": {}}
	var w := await start_session()
	check_eq(w.area.area_id, "room", "an older map's suspend isn't trusted")
	check(memory().suspend.is_empty(), "and is dropped")
	memory().record_quit()
	memory().last_exit = "death"  # not a suspend: a record left behind is never used
	memory().suspend = {"area": "square", "x": 200.0, "y": 200.0, "version": World.SUSPEND_VERSION, "session": memory().sessions, "flags": {}}
	var w2 := await start_session()
	check_eq(w2.area.area_id, "room", "only the launch straight after a suspend resumes")


func test_the_record_survives_a_save_and_bad_data_is_ignored() -> void:
	var w := await _calm_square()
	check(memory().record_suspend("square", Vector2(210, 190), World.SUSPEND_VERSION, {"pointer": true, "junk": 3}), "written")
	var kept: Dictionary = memory().suspend.duplicate(true)
	memory().clear_state()
	memory().load_memory()
	check_eq(memory().suspend, kept, "round trip")
	check(not kept.flags.has("junk"), "only true/false flags are kept")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(memory()._path))
	data["suspend"] = {"area": 5, "x": "a"}
	SafeFile.write_atomic(memory()._path, JSON.stringify(data))
	memory().clear_state()
	memory().load_memory()
	check(memory().suspend.is_empty(), "a damaged record is ignored")
	check(not memory().record_suspend("square", Vector2.ZERO, 1, {}), "and no second suspend once the run is closed")
	check_eq(w.area.area_id, "square", "(the run itself is untouched)")


## G3: a resumed spot is checked against her whole body in the rebuilt map.
func test_never_resumes_inside_something() -> void:
	memory().sessions = 4
	memory().last_exit = "suspend"
	var crates_at: Vector2 = VillageSquare.CRATES.get_center()
	memory().suspend = {"area": "square", "x": crates_at.x, "y": crates_at.y, "version": World.SUSPEND_VERSION, "session": 4, "flags": {}}
	var w := await start_session()
	check_eq(w.area.area_id, "square", "resumed in the square")
	check(not w.area.crates.rect().grow(-1.0).has_point(w.player.global_position), "not inside the crates (%s)" % w.player.global_position)
	check(w.body_fits(w.player.global_position), "somewhere her whole body fits")
	check(w.player.global_position.distance_to(crates_at) < 70.0, "and near where she was")



## G4: stopping mid-escort costs nobody anything.
func test_save_and_exit_during_an_escort() -> void:
	var w := await _calm_square()
	w.debug("wren")
	await wait_until(func() -> bool: return w.escort != null, 3.0, "Wren following")
	memory().add_event("wren.promised")
	var fates: Dictionary = memory().npc_fates.duplicate()
	check_eq(w.try_suspend(), "", "saved mid-escort")
	await wait_until(func() -> bool: return scene() != null and scene().get("player") == null, 5.0, "the title")
	check_eq(memory().npc_fates, fates, "Wren isn't lost or deleted for it")
	var w2 := await start_session()
	check(w2.woke_from_suspend and w2.escort == null, "resumed; she isn't trailing her")
	check_eq(w2._resumed_escort, "wren", "it knows who was walking with her")
	check(w2.area.wren != null, "she's back at her place in the square")
	# Shown, or waiting its turn behind the owner's lines in the console.
	var said := await wait_until(func() -> bool: return w2.hud.history.any(func(e: Dictionary) -> bool: return str(e.text).contains("went home while i was gone")) \
		or w2.hud._queue.any(func(m: Dictionary) -> bool: return str(m.text).contains("went home while i was gone")), 3.0, "Rue's line")
	check(said, "and Rue says where she went (%s)" % str(w2.hud.history.map(func(e: Dictionary) -> String: return str(e.text)).slice(-6)))
	check(memory().has_event("wren.promised") and not memory().has_event("wren.promise_broken"), "the promise is still open, not broken")

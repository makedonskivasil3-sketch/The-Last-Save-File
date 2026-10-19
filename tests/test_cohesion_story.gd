extends "res://tests/test_case.gd"
## Story and character fixes from the cohesion pass (docs/COHESION_PASS.md):
## lines that were unreachable, memories that never played, a repeated
## errand, a way out without evidence, and endings whose promise the next run
## didn't keep.


func _talk(w: Node, who: Node) -> Array:
	await interact_with(w, who)
	var said: Array = []
	for i in 10:
		if not w.hud.is_dialogue_open():
			break
		said.append(w.hud._dialogue_text.text)
		await press("interact")
		await press("interact")
		await wait(0.05)
	await frames(3)
	return said


func test_saying_not_now_doesnt_hide_who_mira_is() -> void:
	var w := await start_session(true, true)
	var heard: Array = []
	for i in 3:
		heard.append_array(await _talk(w, w.area.mira))
	check(w.hud.is_choosing(), "on the third talk she asks to come along")
	await press("move_down")
	await press("interact")  # "Not now"
	await frames(3)
	await finish_dialogue(w)
	for i in 2:
		heard.append_array(await _talk(w, w.area.mira))
	check(ArinsRoom.MIRA_LINES[2] in heard, "after a 'not now' she still says \"You're not Arin. Who are you?\"")
	check(ArinsRoom.MIRA_LINES[3] in heard, "and the next of her own lines")
	await _talk(w, w.area.mira)
	check(w.hud.is_choosing(), "then she asks again")


func test_restricted_mira_still_remembers() -> void:
	memory().sessions = 1
	memory().last_exit = "death"
	memory().last_death = "arin"
	memory().purge = 1
	var w := await start_session()
	check_eq(w.area.mira.state, Npc.State.RESTRICTED, "after a death she isn't allowed to talk to you")
	var heard: Array = await _talk(w, w.area.mira)
	check(not heard.is_empty() and heard[0] == Story.recall("mira"), "but the first thing she says is what she remembers (%s)" % str(heard))
	check(heard.size() >= 2 and heard[1] == ArinsRoom.MIRA_RESTRICTED[0], "then that she isn't allowed to talk")


func test_the_pointer_is_kept_between_runs() -> void:
	memory().met_archivist = true
	var w := await start_session()
	check(w.flags.get("pointer", false), "the Archivist's pointer is still in the save")
	await go_to(w, "square", "house")
	check(w.area.north_exit.open, "so the north road is open without the errand")
	await go_to(w, "archive", "west")
	var heard: Array = await _talk(w, w.area.archivist)
	check(ArchiveArea.ARCHIVIST_BACK in heard and ArchiveArea.ARCHIVIST_AGAIN in heard, "he greets you as someone who kept it (%s)" % str(heard))


func test_later_runs_show_the_way_out() -> void:
	memory().sessions = 1
	memory().last_exit = "death"
	memory().purge = 1
	var w := await start_session()
	check_eq(w.area.door.state, Door.State.DELETED, "the door is gone")
	await frames(3)
	check(w.area.seam.hint and not w.area.seam.open, "a hairline shows where the wall will tear")
	await wait_until(func() -> bool: return w.hud.history.any(func(e: Dictionary) -> bool: return e.text == Story.VOICE["door_gone"][0]), 30.0, "Rue saying the door is gone")
	check_eq(w.ending, "", "standing still to read the start of the run doesn't get Rue saved over")


func test_after_the_rue_ending_the_owner_keeps_their_word() -> void:
	memory().sessions = 2
	memory().last_exit = "win"
	memory().last_ending = "rue"
	var w := await start_session()
	check(w.director.truce, "the owner only watches this run")
	check(w.current_goal().begins_with("TRUCE"), "the goal states the rule (%s)" % w.current_goal())
	# The goal line refreshes every 0.5 s and waits for cards to clear.
	await wait_until(func() -> bool: return w.hud.objective_text().contains("TRUCE"), 5.0, "the truce on the goal line")
	w.director.add_awareness(80.0)
	check(w.director.awareness < OwnerDirector.SILENCE, "watching never turns into deleting (%.0f)" % w.director.awareness)
	w.owner_moves._next_save = 0.0
	await go_to(w, "square", "house")
	await wait(1.0)
	check_eq(w.owner_moves.save_progress, -1.0, "no save-overs")
	for i in OwnerDirector.TRUCE_STRIKES - 1:
		w.owner_moves.on_glitch("phase")
	check(w.director.truce, "two glitches are warned")
	check(w.hud.warning_text() == OwnerDirector.TRUCE_STRIKE_LINES[1], "out loud (%s)" % w.hud.warning_text())
	w.owner_moves.on_glitch("phase")
	check(not w.director.truce, "the third breaks the truce")
	check_eq(OwnerMemory.total_reloads, 0, "and none of them reloaded")


func test_a_run_after_another_ending_has_no_truce() -> void:
	memory().sessions = 2
	memory().last_exit = "win"
	memory().last_ending = "escape"
	var w := await start_session()
	check(not w.director.truce, "escape: the owner is back to watching closely")


func test_wren_remembers_her_own_ending() -> void:
	memory().previous_exit = "win"
	memory().last_ending = "wren"
	check(Story.recall("wren").begins_with("I was somewhere else last night"), "Wren remembers the slot she was given")

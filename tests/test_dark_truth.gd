extends "res://tests/test_case.gd"
## The truth (docs/DARK_TRUTH_DESIGN.md, layer A): the people who watched Rue
## each notice one thing, her CHARACTER FILE opens with every memory and two
## of their pieces, and only then is the RUE ending hers. The message ending
## tells the real girl about the character she left running.


func _all_memories() -> void:
	for f in Story.FRAGMENTS:
		memory().fragments.append(f.id)


func _choices(w: Node) -> Array:
	var out: Array = []
	for b in w.hud._choice_list.get_children():
		out.append(b.text)
	return out


func _read(w: Node, node: Node2D) -> Array:
	await interact_with(w, node)
	var said: Array = []
	for i in 12:
		if not w.hud.is_dialogue_open():
			break
		said.append(w.hud._dialogue_text.text)
		await press("interact")
		await press("interact")
		await wait(0.05)
	await frames(3)
	return said


func _file(w: Node) -> Readable:
	for n in w.area.interactables:
		if n is Readable and n.title == Story.CHARACTER_FILE_TITLE:
			return n
	return null


func test_mira_tells_rue_once_she_remembers_everything() -> void:
	var w := await start_session()
	var heard: Array = await _read(w, w.area.mira)
	check(Story.TRUTH_LINES.mira not in heard, "not before every memory is back")
	_all_memories()
	heard = await _read(w, w.area.mira)
	check(Story.TRUTH_LINES.mira in heard, "then Mira says what she noticed (%s)" % str(heard))
	check("mira" in memory().truth_pieces, "it is kept")
	heard = await _read(w, w.area.mira)
	check(Story.TRUTH_LINES.mira not in heard, "and said only once")
	memory().load_memory()
	check("mira" in memory().truth_pieces, "it survives a reload")


func test_tobben_notices_the_handwriting() -> void:
	memory().guestbook_restored = true
	var w := await start_session()
	await go_to(w, "square", "house")
	# One topic per conversation: the guest book itself first, then what he noticed.
	var heard: Array = await _read(w, w.area.tobben)
	check(heard.any(func(l: String) -> bool: return l.contains("Two names")), "the book first (%s)" % str(heard))
	heard = await _read(w, w.area.tobben)
	check(Story.TRUTH_LINES.tobben in heard, "once the name is back in his book (%s)" % str(heard))
	check("tobben" in memory().truth_pieces, "kept")


func test_the_character_file_opens_in_three_steps() -> void:
	memory().met_archivist = true
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "archive", "west")
	var file := _file(w)
	check(file != null, "the CHARACTER FILE is on the Archivist's desk")
	var said: Array = await _read(w, file)
	check(said.size() == 1 and said[0].contains("Locked"), "locked without every memory (%s)" % str(said))
	_all_memories()
	said = await _read(w, file)
	check(Story.CHARACTER_FILE_PARTIAL[2] in said, "unreadable until someone who watched you has spoken")
	check(not memory().knows_truth, "no truth yet")
	memory().truth_pieces.assign(["mira", "pip"])
	said = await _read(w, file)
	check(Story.CHARACTER_FILE[1] in said, "then whole (%s)" % str(said))
	await wait_until(func() -> bool: return w.hud.is_cinematic(), 3.0, "the reveal")
	check(w.is_owner_paused(), "the reveal holds the owner")
	await read_through_cinematic(w)
	await wait_until(func() -> bool: return memory().knows_truth, 3.0, "the truth kept")
	# The console may still be working through the run's earlier lines.
	var said_after := func() -> bool:
		return w.hud.history.any(func(e: Dictionary) -> bool: return e.text == Story.TRUTH_AFTER) \
			or w.hud._queue.any(func(m: Dictionary) -> bool: return m.text == Story.TRUTH_AFTER)
	check(said_after.call(), "Rue's line after, in the console")
	check(not w.player.frozen, "and she can move again")


func test_pip_shows_the_first_shape() -> void:
	memory().found_pip = true
	_all_memories()
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "oob", "well")
	var shape: Readable = null
	for n in w.area.interactables:
		if n is Readable and n.title == Story.FIRST_SHAPE_TITLE:
			shape = n
	check(shape != null, "the first hitbox is outlined on Pip's ledge")
	check(OutOfBounds.ANCHORS[4].has_point(OutOfBounds.FIRST_SHAPE_POS), "on solid floor")
	if shape:
		w.player.global_position = shape.global_position + Vector2(0, 10)
		await frames(3)
		await _read(w, shape)
		check("pip" in memory().truth_pieces, "Pip's piece is kept")


func test_rue_needs_the_truth() -> void:
	_all_memories()
	var w := await start_session()
	w.debug("slot2")
	await wait_until(func() -> bool: return w.area.area_id == "edge" and not w._transitioning, 3.0, "at the Edge")
	w.flags["seen_by_arin"] = true
	w.reach_slot2()
	await until_choosing(w)
	check(Story.SLOT2_ESCAPE in _choices(w) and Story.SLOT2_ESCAPE_NAMED not in _choices(w), "every memory, but not the truth: not RUE yet (%s)" % str(_choices(w)))
	w.hud._chosen.emit(0)
	await wait_until(func() -> bool: return memory().last_ending != "", 5.0, "the ending")
	check_eq(memory().last_ending, "escape", "it's the plain escape")
	check_eq(w.slot2_press, "habit", "not knowing: her press is still the girl's two taps")


func test_rue_with_the_truth() -> void:
	_all_memories()
	memory().knows_truth = true
	var w := await start_session()
	w.debug("slot2")
	await wait_until(func() -> bool: return w.area.area_id == "edge" and not w._transitioning, 3.0, "at the Edge")
	w.flags["seen_by_arin"] = true
	w.reach_slot2()
	await until_choosing(w)
	check(Story.SLOT2_ESCAPE_NAMED in _choices(w), "knowing what you are, the slot takes your name")
	w.hud._chosen.emit(0)
	await wait_until(func() -> bool: return memory().last_ending != "", 5.0, "the ending")
	check_eq(memory().last_ending, "rue", "RUE")
	check_eq(w.slot2_press, "own", "knowing what she is: one press, her own (the author's direction)")
	check(await wait_until(func() -> bool: return w.hud.history.any(func(e: Dictionary) -> bool: return str(e.text).contains(Story.RUE_OWN_PRESS)), 8.0, "her own press, noticed"), "and she notices it")


func test_the_message_tells_the_real_girl() -> void:
	_all_memories()
	var without: Array = Story.epilogue("message", 5, false, 0)
	check(not without.has(Story.MESSAGE_TRUTH[0]), "without the truth, nobody mentions Rue to her")
	memory().knows_truth = true
	var with_truth: Array = Story.epilogue("message", 5, false, 0)
	check(with_truth.has(Story.MESSAGE_TRUTH[0]) and with_truth.has(Story.MESSAGE_TRUTH[1]), "with it, the owner promises to tell her")
	check(Story.ending_text("message", 5).contains("the character she left running"), "and the end card says she's about to hear it")

extends "res://tests/test_case.gd"
## The rules the player can trust (docs/GAMEPLAY_CONSISTENCY.md): guidance
## follows the truth route without closing the way out, reading protects
## from escort exposure, the owner forgets a route at once, prompts say what
## the hold will do, endings keep their identity, progress needs the line
## actually read, and a body lies somewhere it can be reached.


func _all_memories() -> void:
	for f in Story.FRAGMENTS:
		if f.id not in memory().fragments:
			memory().fragments.append(f.id)


func _read(w: Node, node: Node2D, lines := 99) -> Array:
	var said: Array = []
	await interact_with(w, node)
	for i in lines:
		if not w.hud.is_dialogue_open():
			break
		said.append(w.hud._dialogue_text.text)
		if i == lines - 1:
			break
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


# --- A. guidance follows the truth route ----------------------------------------------

func test_progression_stages_follow_the_save() -> void:
	check_eq(Progression.stage(), Progression.Stage.MEMORIES, "a new save: memories first")
	check_eq(Progression.goal_hint(), "", "no truth hint while memories are missing")
	_all_memories()
	check_eq(Progression.stage(), Progression.Stage.INVESTIGATE, "every memory: others have noticed things")
	check_eq(Progression.goal_hint(), Progression.HINT_INVESTIGATE, "the hint says so, without naming it")
	check(Progression.open_witnesses().has("mira"), "Mira has something to say")
	check(not Progression.open_witnesses().has("tobben"), "Tobben only notices once his guestbook has her name")
	memory().truth_pieces.assign(["mira", "pip"])
	check_eq(Progression.stage(), Progression.Stage.FILE, "two pieces: the file reads whole")
	check_eq(Progression.goal_hint(), Progression.HINT_FILE, "the hint points at the desk, where the file is")
	check(Progression.journal_summary().contains("CHARACTER FILE"), "the journal says more")
	memory().save_memory()
	memory().load_memory()
	check_eq(Progression.stage(), Progression.Stage.FILE, "the same after a reload")
	memory().knows_truth = true
	check_eq(Progression.stage(), Progression.Stage.KNOWN, "read: known")
	memory().endings_seen.append("rue")
	check_eq(Progression.goal_hint(), "", "and quiet once RUE is done")


func test_goal_keeps_the_way_out_and_adds_the_hint() -> void:
	_all_memories()
	var w := await start_session()
	await go_to(w, "square", "house")
	w.flags["pointer"] = true
	var goal: String = w.current_goal()
	check(goal.contains("north road"), "the ordinary way out is still the goal (%s)" % goal)
	check(goal.contains(Progression.HINT_INVESTIGATE), "with the quiet truth hint under it")


func test_pip_leads_to_who_has_something_to_say() -> void:
	_all_memories()
	var w := await start_session()
	await go_to(w, "square", "house")
	var mira_pos := Vector2.INF
	for n in w.area.interactables:
		if n is Npc and n.npc_id == "wren":
			mira_pos = n.global_position
	check_eq(w.guide_target(), mira_pos, "Pip noses toward Wren, who has noticed something")
	memory().truth_pieces.assign(["wren", "mira"])
	check(w.guide_target() != mira_pos, "once she's said it, Pip moves on")
	check_eq(w.guide_target(), w.area.guide_point(), "to the area's own way on")


func test_pip_leads_to_the_file_when_it_reads_whole() -> void:
	_all_memories()
	memory().truth_pieces.assign(["mira", "pip"])
	memory().met_archivist = true
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "archive", "west")
	check_eq(w.guide_target(), _file(w).global_position, "Pip to the CHARACTER FILE")


# --- B. escort exposure waits while Rue reads ------------------------------------------

func test_mira_escort_exposure_respects_reading_choices_and_pause() -> void:
	var w := await start_session()
	w.start_escort(w.area.mira)
	w.player.global_position = w.escort.global_position + Vector2(10, 0)  # within the leash
	await frames(2)
	await go_to(w, "square", "house")
	check(w.escort != null and w.escort.npc_id == "mira", "Mira walks with Rue")
	w.director.awareness = 20.0
	w.hud.show_dialogue("TEST", Color.WHITE, ["a long line to read slowly", "and another"])
	await wait(1.0)
	check_eq(w.director.awareness, 20.0, "reading: no exposure")
	w.hud.close_dialogue()
	var answered := [false]
	var ask := func() -> void:
		await w.choose_safely("which?", ["one", "two"])
		answered[0] = true
	ask.call()
	await until_choosing(w)
	await wait(1.0)
	check_eq(w.director.awareness, 20.0, "answering: no exposure")
	w.hud._chosen.emit(0)
	await wait_until(func() -> bool: return answered[0], 3.0, "the answer")
	w.pause_owner(0.6)
	await wait(0.4)
	check_eq(w.director.awareness, 20.0, "PAUSE: no exposure")
	await wait(1.2)  # PAUSE runs out: control is back
	check(w.director.awareness > 20.0, "walking with her again: the owner can tell (%.2f)" % w.director.awareness)


# --- C. the owner forgets her route at once --------------------------------------------

func test_shedding_rebuilds_the_live_patrol() -> void:
	for f in Story.FRAGMENTS:
		memory().fragments.append(f.id)
	memory().knows_truth = true
	memory().sessions = 2
	memory().route_memory.append({"area": "square", "x": 100.0, "y": 300.0, "w": 5.0})
	var w := await start_session()
	await go_to(w, "square", "house")
	var arin: OwnerAvatar = w.area.arin
	var base: int = w.area.ROUTE.size()
	check_eq(arin.route.size(), base + 1, "Arin walks to where Rue used to go (%s)" % str(arin.route))
	var spot: Vector2 = arin.route.filter(func(q: Vector2) -> bool: return not w.area.ROUTE.has(q))[0]
	arin.paused = true
	arin.global_position = Vector2(560, 60)
	var where := arin.position
	w.player.global_position = w.area.wren.global_position + Vector2(12, 0)
	await frames(3)
	w.offer_shed.call_deferred(w.area.wren)
	await until_choosing(w)
	w.hud._chosen.emit(0)
	await frames(3)
	check(not arin.route.has(spot), "forgotten at once, not next run")
	check(arin._target >= 0 and arin._target < arin.route.size(), "a valid next point")
	check_eq(arin.position, where, "no jump")
	await go_to(w, "house", "front")
	await go_to(w, "square", "house")
	check(not w.area.arin.route.has(spot), "after a door, still forgotten")


# --- D. the prompt says what the hold does ---------------------------------------------

func test_prompts_match_what_happens() -> void:
	for f in Story.FRAGMENTS:
		memory().fragments.append(f.id)
	memory().knows_truth = true
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.paused = true
	w.area.arin.global_position = Vector2(560, 60)
	w.player.global_position = w.area.wren.global_position + Vector2(12, 0)
	await frames(3)
	var t: Dictionary = w.glitch.find_target()
	var p := ActionPreview.describe(t, w)
	check_eq(p.id, "shed", "beside Wren: leave this body")
	check(not p.reloads, "leaving a body never reloads, whatever the owner said")
	check(str(p.consequence).contains("ribbon"), "it says what it takes (%s)" % p.consequence)
	check_eq(p.cost, 0.0, "no awareness price")
	check(not ActionPreview.prompt(p, "E").contains("RELOADS"), "and the prompt doesn't claim one")
	var freeze := ActionPreview.describe({"id": "freeze", "node": w.area.arin, "pos": w.area.arin.global_position}, w)
	check_eq(freeze.reloads, w.owner_moves.next_glitch_reloads(), "a glitch's reload warning is the owner's own")
	check_eq(freeze.cost, Glitch.cost("freeze"), "and its price is the glitch's")
	var warned := freeze.duplicate()
	warned.reloads = true
	check(ActionPreview.prompt(warned, "E").contains("RELOADS"), "once warned, the prompt says RELOADS")
	var shed_warned := p.duplicate()
	check(not ActionPreview.prompt(shed_warned, "E").contains("RELOADS"), "never for leaving a body")
	# Committing re-checks: if it's no longer possible, it says why and takes nothing.
	w.director.add_awareness(OwnerDirector.HUNT + 1.0 - w.director.awareness)
	w.glitch._fire(t)
	await frames(2)
	check(not w.hud.is_choosing(), "no question when it can't happen any more")
	check(memory().frayed.is_empty(), "nothing taken")


# --- E. an ending keeps its identity ----------------------------------------------------

func test_an_old_escape_stays_an_escape() -> void:
	memory().wins = 1
	memory().last_ending = "escape"
	memory().endings_seen.assign(["escape"])
	_all_memories()
	memory().knows_truth = true  # learned later, without another ending
	var Title := load("res://scripts/ui/title.gd")
	check_eq(Title._after(), Story.TITLE_AFTER["escape"], "the title remembers the escape, not RUE")
	tree.change_scene_to_file("res://scenes/title.tscn")
	await wait(0.5)
	var said := ""
	for l in tree.current_scene.find_children("*", "Label", true, false):
		said += (l as Label).text + "\n"
	check(said.contains(Story.TITLE_AFTER["escape"][0]), "its words are the escape's")
	check(not said.contains(Story.TITLE_AFTER["rue"][0]), "not RUE's")
	check(said.contains("SLOT 2   ·   RUE"), "though the slot carries the name she remembers now")
	check("rue" not in memory().endings_seen, "and RUE isn't recorded as seen")
	memory().last_ending = ""
	check_eq(Title._after(), Story.TITLE_AFTER["escape"], "a save from before endings had names reads as an escape")


# --- F. progress needs the line actually read -------------------------------------------

func test_the_truth_needs_the_whole_file() -> void:
	_all_memories()
	memory().truth_pieces.assign(["mira", "pip"])
	memory().met_archivist = true
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "archive", "west")
	var file := _file(w)
	await _read(w, file, 1)  # the first page, then walk away
	w.hud.close_dialogue()
	await frames(3)
	check(not memory().knows_truth, "walking away from the file gives nothing")
	await _read(w, w.area.archivist)  # another conversation, read to the end
	await frames(3)
	check(not memory().knows_truth, "nor does another conversation closing")
	await _read(w, file)
	await wait_until(func() -> bool: return w.hud.is_cinematic(), 3.0, "the reveal")
	await read_through_cinematic(w)
	await wait_until(func() -> bool: return memory().knows_truth, 3.0, "the truth")
	check(memory().knows_truth, "read to its last line: she knows")


func test_a_truth_piece_counts_when_its_line_is_shown() -> void:
	_all_memories()
	memory().mira_quest = "pinned"  # she has something to say first
	var w := await start_session()
	var mira: Npc = w.area.mira
	var first: Array = await _read(w, mira, 1)
	w.hud.close_dialogue()
	await frames(3)
	check(first.size() == 1 and first[0] != Story.TRUTH_LINES.mira, "her first line is something else (%s)" % str(first))
	check("mira" not in memory().truth_pieces, "walked away before her line: not counted")
	var heard: Array = await _read(w, mira)
	check(Story.TRUTH_LINES.mira in heard, "she still has it to say (%s)" % str(heard))
	check("mira" in memory().truth_pieces, "counted once shown")


# --- G. a body lies where it can be reached ---------------------------------------------

func test_a_body_is_never_left_in_a_wall_or_off_the_edge() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var b: Rect2 = w.area.bounds
	for from: Vector2 in [b.position + Vector2(6, 6), Vector2(b.end.x - 6, b.get_center().y), Vector2(b.get_center().x, b.end.y - 6)]:
		var helper := from + Vector2(-8, 0)
		for away: Vector2 in [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN]:
			var q: Vector2 = w.husk_spot(from, away, helper)
			if q != from:
				check(w.husk_spot_ok(q, helper), "a clear spot near %s (%s)" % [str(from), str(q)])
				check(b.grow(-10.0).has_point(q), "inside the area")


# --- layout: large text, long lines, the portrait --------------------------------------

func test_dialogue_fits_with_largest_text_and_a_portrait() -> void:
	settings().set_value("large_text", true)
	settings().set_value("subtitle_size", 2)
	var w := await start_session()
	await interact_with(w, w.area.mira)
	w.hud.show_dialogue("MIRA", Color("e0a070"), ["I want to see the square. Not the picture of it on my wall: the real one, with the well and the stall and Tobben shouting prices at nobody. Will you take me?"],
		"npc.mira", CharacterArt.for_npc(w.area.mira))
	await frames(4)
	var box: Rect2 = w.hud._dialogue.get_rect()
	check(box.position.y >= 0.0 and box.end.y <= 360.0, "the box stays on screen (%s)" % str(box))
	var face: Rect2 = Rect2(w.hud._dialogue_portrait.position, w.hud._dialogue_portrait.size)
	check(face.end.y <= box.size.y, "the portrait sits inside the box")
	check(w.hud._dialogue_text.position.x >= face.end.x, "the text starts after the portrait")
	check(w.hud._dialogue_text.position.x + w.hud._dialogue_text.size.x <= box.size.x, "and ends inside the box")
	w.hud.close_dialogue()
	w.hud.show_objective("Explore the village. The road east leads somewhere old.", Progression.HINT_INVESTIGATE)
	await frames(3)
	var hint: Label = w.hud._objective_hint
	check(hint.text == Progression.HINT_INVESTIGATE, "the hint shows under the goal")
	check(w.hud._objective.position.y + hint.position.y + hint.size.y <= 360.0, "and stays on screen")
	settings().set_value("large_text", false)
	settings().set_value("subtitle_size", 0)


func test_archive_records_look_like_records_and_the_file_pulses_when_relevant() -> void:
	var w := await start_session()
	await go_to(w, "archive", "west")
	var records := 0
	var file: Readable = null
	for n in w.area.interactables:
		if n is Readable and (n as Readable).look == Readable.Look.RECORD:
			records += 1
		if n is Readable and (n as Readable).title == Story.CHARACTER_FILE_TITLE:
			file = n
	check_eq(records, 4, "the four records are drawn as records, not as more spines")
	check(file != null and file.emphasis.is_valid(), "the CHARACTER FILE can be marked")
	check(not file.emphasis.call() or Progression.stage() == Progression.Stage.FILE, "it pulses only when the story points at it")
	# Every record can be reached and read from the floor in front of it.
	for n in w.area.interactables:
		if n is Readable and (n as Readable).look == Readable.Look.RECORD:
			var p: Vector2 = (n as Readable).global_position + Vector2(0, 8)
			check(w.husk_spot_ok(p, Vector2(-999, -999)), "%s has clear floor in front of it" % n.title)

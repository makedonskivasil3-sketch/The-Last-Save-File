extends "res://tests/test_case.gd"
## The well's sequence and the one checkpoint it makes
## (docs/NARRATIVE_CONTRACT.md §5–6), and map continuity: arrivals on the
## side you came from, no repeated first-arrival lines.


## Said, or waiting its turn in the console.
func _said(w: Node, text: String) -> bool:
	return w.hud.history.any(func(e: Dictionary) -> bool: return str(e.text).contains(text)) \
		or w.hud._queue.any(func(m: Dictionary) -> bool: return str(m.text).contains(text))


func _to_well(w: Node) -> void:
	w.player.global_position = w.area.rim.global_position + Vector2(0, -10)
	await frames(3)


func _listen(w: Node) -> void:
	w.hud.close_dialogue()
	w._interact(w.area.rim)
	await frames(2)


func _hear_out(w: Node) -> void:
	await finish_dialogue(w)
	await frames(2)


func test_the_well_follows_its_steps_in_order() -> void:
	var w := await start_session()
	w.director.stop()
	await go_to(w, "square", "house")
	check(not WellSequence.done("click"), "nothing before you're near it")
	await _to_well(w)
	await wait_until(func() -> bool: return WellSequence.done("click"), 2.0, "the click")
	check(_said(w, "a real one"), "Rue hears a real button")
	await _listen(w)
	check(not WellSequence.done("words"), "listening before the tune: nothing yet")
	WellSequence.record("words")
	check(not WellSequence.done("words"), "a step can't be skipped")
	# Down at the pillar, without the memory of the well: no tune.
	await go_to(w, "oob", "well")
	w.player.global_position = OutOfBounds.PILLAR_POS + Vector2(20, 18)
	await wait(0.3)
	check(not WellSequence.done("tune"), "no tune without the memory of the well")
	memory().add_fragment("well")
	await wait_until(func() -> bool: return WellSequence.done("tune"), 2.0, "the tune")
	check(_said(w, "the same note's missing"), "one note short")
	check(memory().anchor.is_empty(), "the tune alone keeps no place: that's Rue's choice")
	await go_to(w, "square", "well")
	await _to_well(w)
	# Her words: heard only when read to the end.
	await _listen(w)
	check(" ".join(w.hud._dialogue_lines).contains("still have my save?"), "typed up from below")
	check(w.hud.dialogue_silent, "typed, not spoken")
	w.hud.close_dialogue()
	await frames(2)
	check(not WellSequence.done("words"), "cut off: not heard yet")
	await _listen(w)
	await _hear_out(w)
	check(WellSequence.done("words"), "read whole: heard")
	check(memory().journal.any(func(e: Dictionary) -> bool: return e.id == "square:THE WELL"), "kept in the journal")
	check(ArchivePages.leads().any(func(e: Dictionary) -> bool: return e.key == "lead:well_words"), "and a lead to follow")
	# Again: exactly the same. Kept, not said.
	await _listen(w)
	await _hear_out(w)
	check(_said(w, "it's playing it back"), "the same pause: a recording")
	check(not WellSequence.done("compared"), "not compared before she remembers where she heard it")
	check(_said(w, WellSequence.COMPARED_NOT_YET), "she half-remembers")
	memory().add_fragment("delete")
	await _listen(w)
	await _hear_out(w)
	check(WellSequence.done("compared"), "with the memory: her message, kept")
	check(_said(w, "i don't know if she's still asking"), "and what it doesn't prove")
	check(not _said(w, "(it's her. outside. she's still asking.)"), "never that she's asking now")
	var note: Array = memory().journal.filter(func(e: Dictionary) -> bool: return e.id == "square:THE WELL")[0].lines
	check(note.size() > 2, "the journal's note grows with what she worked out (%d lines)" % note.size())
	check_eq(w.area.rim.interact_prompt(), WellSequence.ANSWER_PROMPT, "now the rim offers an answer")
	w.director._running = true  # the owner watches the answer (its cost)
	w.area.arin.paused = true
	var before: float = w.director.awareness
	await press("interact")  # a tap starts the answer
	await frames(3)
	check(w.area._answer_t >= 0.0, "answering")
	await wait(WellSequence.ANSWER_SECONDS + 0.4)
	check(WellSequence.done("answered"), "stayed long enough: answered")
	check(w.director.awareness >= before + WellSequence.ANSWER_AWARENESS * 0.8, "it cost something: the owner noticed (%.0f -> %.0f)" % [before, w.director.awareness])
	check(memory().anchor.is_empty(), "answering keeps no place by itself")
	# What it proves: it plays her own answer back.
	await wait(1.0)
	await _listen(w)
	check(" ".join(w.hud._dialogue_lines).contains("> i'm here."), "listening again: her own answer, kept")
	await _hear_out(w)
	check(_said(w, "it doesn't carry it anywhere"), "so it keeps; it doesn't send")
	check(ArchivePages.leads().any(func(e: Dictionary) -> bool: return e.key == "lead:well_known" and e.body.contains("UNKNOWN")),
		"the lead keeps what isn't known")


func test_the_place_under_the_well_is_earned_and_chosen() -> void:
	memory().well_events.append("click")
	var w := await start_session()
	await go_to(w, "oob", "well")
	var mark: AnchorMark = w.area.mark
	check(not mark.can_interact(), "nothing to keep before the tune")
	check(w.player.global_position.distance_to(mark.global_position) > World.INTERACT_DISTANCE,
		"the arrival point isn't on the mark's prompt")
	memory().add_fragment("well")
	w.player.global_position = OutOfBounds.PILLAR_POS + Vector2(20, 18)
	await wait_until(func() -> bool: return WellSequence.done("tune"), 2.0, "the tune")
	check(mark.can_interact() and mark.interact_prompt() == "keep my place here", "now it can be kept")
	check(ArchivePages.leads().any(func(e: Dictionary) -> bool: return e.key == "lead:well_place"), "the journal says so")
	# Never mid-conversation (World.set_anchor; an escort is refused the same way).
	w.hud.show_dialogue("TEST", Color.WHITE, ["..."])
	w.area._on_keep_place(mark)
	await frames(2)
	check(memory().anchor.is_empty(), "refused during a conversation")
	check(_said(w, WellSequence.ANCHOR_NOT_NOW), "and she says not now")
	w.hud.close_dialogue()
	await frames(2)
	w.player.global_position = mark.global_position + Vector2(0, 6)
	await frames(3)
	w._interact(mark)
	await frames(2)
	check(World.anchor_valid(), "kept")
	check(w.area.pillar.lit and mark.is_kept, "the pillar and the mark show it")
	check(_said(w, WellSequence.ANCHOR_KEPT), "and she says what it means")
	check(not ArchivePages.leads().any(func(e: Dictionary) -> bool: return e.key == "lead:well_place"), "the lead is done")
	check(ArchivePages.objects().any(func(e: Dictionary) -> bool: return e.key == "object:anchor"), "the journal keeps it")


func test_stepping_away_cuts_the_answer_off() -> void:
	for st in ["click", "tune", "words", "compared"]:
		memory().well_events.append(st)
	var w := await start_session()
	await go_to(w, "square", "house")
	await _to_well(w)
	await press("interact")
	await frames(3)
	check(w.area._answer_t >= 0.0, "answering")
	await wait(0.6)
	w.player.global_position += Vector2(0, -60)
	await wait(WellSequence.ANSWER_SECONDS)
	check(not WellSequence.done("answered"), "stepped away early: no answer")
	check(memory().anchor.is_empty(), "and no anchor")


func test_after_a_death_you_wake_under_the_well() -> void:
	memory().fragments.assign(["controller"])
	memory().event_at("wren.promised", 1)
	var w := await start_session()
	check(w.set_anchor("oob:pillar"), "anchor set")
	check_eq(memory().anchor.keys(), ["id", "version", "session"], "a place by id: no items, no choices, no coordinates")
	await go_to(w, "square", "house")
	var purge_before: int = memory().purge
	w.kill("overwritten", "arin")
	check(World.death_kept_line().contains("under the well"), "the death card says where you'll wake")
	var w2 := await wait_for_new_session(w)
	check_eq(w2.area.area_id, "oob", "woke out of bounds, not in Arin's room")
	check(w2.woke_at_anchor, "at the anchor")
	check(w2.player.global_position.distance_to(OutOfBounds.ENTRY) < 2.0, "on the landing that never streams away")
	check(w2.area.floor_at(w2.player.global_position), "on solid floor")
	check(w2.area.pillar.lit, "the pillar keeps its light")
	check_eq(memory().purge, purge_before + 1, "the death still counts: purge rules unchanged")
	check_eq(memory().fragments, ["controller"] as Array[String], "memories kept, not duplicated")
	check(memory().has_event("wren.promised"), "a promise isn't undone")
	await wait(2.0)
	check_eq(w2.ending, "", "no death waiting at the anchor")


func test_quitting_or_crashing_starts_in_the_room() -> void:
	var w := await start_session()
	w.set_anchor("oob:pillar")
	memory().record_quit()
	var w2 := await start_session()
	check_eq(w2.area.area_id, "room", "after a quit: Arin's room")
	check(World.anchor_valid(), "the anchor is still kept for a death")
	memory().last_exit = "crash"
	var w3 := await start_session()
	check_eq(w3.area.area_id, "room", "after a crash: Arin's room")


func test_an_invalid_anchor_falls_back_to_the_room() -> void:
	memory().anchor = {"id": "nowhere:gone", "version": World.ANCHOR_VERSION, "session": 1}
	memory().last_exit = "death"
	var w := await start_session()
	check_eq(w.area.area_id, "room", "an unknown anchor: the room")
	check(memory().anchor.is_empty(), "and it's dropped")
	memory().anchor = {"id": "oob:pillar", "version": World.ANCHOR_VERSION + 7, "session": 1}
	memory().last_exit = "death"
	var w2 := await start_session()
	check_eq(w2.area.area_id, "room", "an anchor from another version: the room")
	check(memory().anchor.is_empty(), "dropped too")


func test_the_anchor_is_never_set_mid_story() -> void:
	var w := await start_session()
	w.hud.show_dialogue("MIRA", Hud.NPC_COLOR, ["one."])
	check(not w.set_anchor("oob:pillar"), "not during a conversation")
	w.hud.close_dialogue()
	await go_to(w, "square", "house")
	w.start_escort(w.area.wren)
	check(not w.set_anchor("oob:pillar"), "not during an escort")
	check(memory().anchor.is_empty(), "nothing saved")


func test_an_ending_clears_the_anchor() -> void:
	var w := await start_session()
	w.set_anchor("oob:pillar")
	memory().record_win("escape")
	check(memory().anchor.is_empty(), "an ending is a new start")


func test_arrivals_face_the_way_you_came() -> void:
	var w := await start_session()
	# Leaving east arrives on the west side, and back.
	await go_to(w, "archive", "west")
	check(w.player.global_position.x < w.area.bounds.get_center().x, "into the archive from the west: on its west side")
	await go_to(w, "square", "east")
	check(w.player.global_position.x > w.area.bounds.get_center().x, "back into the square from the east: on its east side")
	await go_to(w, "edge", "south")
	check(w.player.global_position.y > w.area.bounds.get_center().y, "up the north road: arriving at the Edge's south")
	await go_to(w, "square", "north")
	check(w.player.global_position.y < w.area.bounds.get_center().y, "back down: at the square's north")
	# Up out of the well: beside it, not on its own prompt.
	await go_to(w, "square", "well")
	await frames(3)
	check(w.player.global_position.distance_to(w.area.well.global_position) > World.INTERACT_DISTANCE, "not standing on 'climb into the well' as you arrive")


func test_a_place_from_an_earlier_run_isnt_new_again() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	check(_said(w, Story.VOICE["square_first"][0]), "first time ever: the first-arrival line")
	w.kill("overwritten", "arin")
	var w2 := await wait_for_new_session(w)
	await go_to(w2, "square", "house")
	await frames(3)
	check(not _said(w2, Story.VOICE["square_first"][0]), "next run: not again")
	check(_said(w2, Story.VOICE_BACK["square"]), "a short 'back' instead")


func test_malformed_anchor_data_falls_back_to_the_room() -> void:
	var m := memory()
	for bad in [{"id": "oob:pillar", "version": 1.5}, {"id": "oob:pillar", "version": "1"}, {"id": 7, "version": 1},
			{"id": "oob:pillar"}, "oob:pillar", {"id": "oob:pillar", "version": 1e400}]:
		var f := FileAccess.open(OwnerMemory.TEST_SAVE_PATH, FileAccess.WRITE)
		# 1e400 can't be written by JSON.stringify: write it as text.
		var text := JSON.stringify({"version": 3, "sessions": 2, "last_exit": "death", "anchor": bad})
		f.store_string(text.replace("inf", "1e400"))
		f.close()
		m.load_memory()
		check(m.anchor.is_empty(), "unreadable anchor dropped: %s" % str(bad))
	var w := await start_session()
	check_eq(w.area.area_id, "room", "so a death with a broken anchor wakes in the room")


func test_waking_at_the_anchor_keeps_what_the_owner_learned() -> void:
	memory().found_pip = true
	memory().route_memory.append({"area": "square", "x": 300.0, "y": 200.0, "w": 3.0})
	memory().owner_notes_seen = 2
	var w := await start_session()
	check(w.set_anchor("oob:pillar"), "kept")
	await go_to(w, "square", "house")
	w.kill("overwritten", "arin")
	var deaths: int = memory().deaths_log.size()
	var w2 := await wait_for_new_session(w)
	check_eq(w2.area.area_id, "oob", "woke under the well")
	check(w2.pip != null and w2.pip.global_position.distance_to(w2.player.global_position) < 40.0, "Pip is beside her, not left behind")
	check(memory().route_memory.size() >= 1, "the owner still knows her routes")
	check_eq(memory().deaths_log.size(), deaths, "and every death")
	check(memory().owner_notes_seen >= 2, "the owner's notes aren't reset (one more a run, as always)")
	check(w2.escort == null, "no escort carried over")

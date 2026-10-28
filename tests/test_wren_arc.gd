extends "res://tests/test_case.gd"
## Wren's own story (docs/production/WREN_ARC.md): she watched the festival,
## learns the well keeps only people who were played, gives Rue her chalk,
## and Rue writes her name on the rim. Each step once, kept in the save.


func _talk(w: Node, who: Node) -> Array:
	await interact_with(w, who)
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


func _ready_to_ask() -> void:
	Relationships.chalk_declined_session = -1
	# Her game (test_wren_game) is played out: the chalk is back with her.
	for e in ["wren.met", "wren.lantern", "wren.watched", "wren.heard_well", "wren.promised", "wren.game", "wren.mark_recess", "wren.mark_ok", "wren.chalk_back"]:
		memory().add_event(e)


func test_her_story_comes_in_order_and_once() -> void:
	Relationships.chalk_declined_session = -1
	memory().add_event("wren.met")
	check(Relationships._wren_own().is_empty(), "nothing of her own before the festival comes up")
	memory().add_event("wren.lantern")
	memory().festival_choice = "tried"
	var told := Relationships._wren_own()
	check_eq(told.get("id"), "wren.watched", "first: she was there")
	check(Relationships.WREN_WATCHED.tried in told.lines, "and saw how this save's festival ended")
	memory().add_event("wren.watched")
	check(Relationships._wren_own().is_empty(), "the well comes before the question: she needs to have heard it")
	memory().add_event("wren.heard_well")
	told = Relationships._wren_own()
	check_eq(told.get("id"), "wren.unplayed", "then: is there one of me?")
	check_eq(told.get("offer"), "chalk", "and she offers her chalk")
	memory().add_event("wren.unplayed")
	told = Relationships._wren_own()
	check_eq(told.get("offer"), "chalk", "not taken yet: she offers again")
	Relationships.chalk_declined_session = memory().sessions
	check(Relationships._wren_own().is_empty(), "but not twice in one session after \"not now\"")
	memory().add_event("wren.chalk")
	check(Relationships._wren_own().is_empty(), "with the chalk: nothing to say until it's used")
	memory().add_event("wren.named")
	told = Relationships._wren_own()
	check_eq(told.get("lines"), Relationships.WREN_SAW_NAME_NO_MARK, "then she sees her name (no drawing of hers on this route)")
	memory().complete_conversation("wren.saw_name")
	check(Relationships._wren_own().is_empty(), "said once")


func test_her_ask_to_see_the_edge_comes_first() -> void:
	memory().add_event("wren.lantern")
	check(Relationships.wren(3, true, false).is_empty(), "her ask is due: her own story waits (the square asks)")
	check_eq(Relationships.wren(1, false, false).get("id"), "wren.watched", "between asks, she tells it")
	memory().add_event("wren.promised")
	memory().add_event("wren.promise_kept")
	check_eq(Relationships.wren(3, true, false).get("id"), "wren.watched", "once the Edge is settled, it isn't held back")


func test_what_she_saw_follows_the_festival() -> void:
	memory().add_event("wren.lantern")
	for c in ["tried", "stayed", "lit", "idle", "skipped", ""]:
		memory().festival_choice = c
		var how: String = Relationships._wren_own().lines[1]
		check_eq(how, Relationships.WREN_WATCHED.get(c, Relationships.WREN_WATCHED[""]), "%s: what she saw" % c)


func test_she_gives_the_chalk_and_rue_writes_her_name() -> void:
	_ready_to_ask()
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.position = Vector2(560, 280)
	w.area.arin.route = [Vector2(560, 280)] as Array[Vector2]
	var heard := await _talk(w, w.area.wren)
	check(Relationships.WREN_UNPLAYED[2] in heard, "\"...Is there one of me?\" (%s)" % str(heard))
	check(memory().has_event("wren.unplayed"), "kept once read")
	check(await until_choosing(w), "she asks: will you remember me?")
	await press("interact")  # "I'll remember you."
	await frames(3)
	check(memory().has_event("wren.chalk"), "Rue has her chalk")
	await finish_dialogue(w)
	await frames(3)
	check_eq(w.area.rim.interact_prompt(), "write WREN in chalk", "the rim offers it")
	w.area.rim.interact()
	await frames(2)
	check(memory().has_event("wren.named"), "her name is on the rim")
	check(memory().journal.any(func(e: Dictionary) -> bool: return str(e.get("title", "")) == "THE WELL'S RIM"), "and in the journal")
	check(w.area.rim.interact_prompt() != "write WREN in chalk", "written once")
	heard = await _talk(w, w.area.wren)
	check(Relationships.WREN_SAW_NAME[1] in heard, "\"Now there's one of me.\" (%s)" % str(heard))


func test_not_now_is_a_real_answer() -> void:
	_ready_to_ask()
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.position = Vector2(560, 280)
	w.area.arin.route = [Vector2(560, 280)] as Array[Vector2]
	await _talk(w, w.area.wren)
	check(await until_choosing(w), "she asks")
	await press("move_down")
	await press("interact")  # "Not now."
	await frames(3)
	check(not memory().has_event("wren.chalk"), "no chalk")
	await finish_dialogue(w)
	var heard := await _talk(w, w.area.wren)
	check(not heard.has(Relationships.WREN_CHALK_AGAIN), "not asked again this session")
	check(w.area.rim.interact_prompt() != "write WREN in chalk", "nothing to write")


func test_every_ending_but_overwrite_remembers_her_name() -> void:
	memory().add_event("wren.named")
	for ending in ["escape", "wren", "message", "rue", "unseen"]:
		var lines := Story.epilogue(ending, 0, false)
		check(lines.has(Story.EPILOGUE_WREN_NAME_ONLY), "%s: her name is still there" % ending)
		check(not lines.has(Story.EPILOGUE_WREN_NAMED), "%s: and no drawing that was never made" % ending)
	check(not Story.epilogue("overwrite", 0, false).has(Story.EPILOGUE_WREN_NAME_ONLY), "overwrite: Rue is Arin now; not hers to remember")
	memory().add_event("wren.marked_well")
	check(Story.epilogue("escape", 0, false).has(Story.EPILOGUE_WREN_NAMED), "with her drawing too: both marks")


## G2: the two chalk marks, in either order, and what each page says.
func test_name_first_then_her_drawing() -> void:
	memory().add_event("wren.met")
	memory().add_event("wren.chalk")
	memory().add_event("wren.named")
	check_eq(Relationships.rim_journal(), ["Four letters in your hand, on the rim: WREN."], "name only: the rim says just that")
	check_eq(Relationships._wren_own().get("lines"), Relationships.WREN_SAW_NAME_NO_MARK, "she sees it where everybody passes, not \"next to you\"")
	# Saved and loaded between the two.
	memory().save_memory()
	memory().clear_state()
	memory().load_memory()
	check(memory().has_event("wren.named") and not memory().has_event("wren.marked_well"), "(kept as it was)")
	Relationships.wren_at_well = true
	var told := Relationships.wren(0, false, false)
	Relationships.wren_at_well = false
	check(told.get("lines", []).has(Relationships.WREN_MARKED_BESIDE), "her drawing scene, after: she sees her name and puts Rue beside it")
	memory().add_event("wren.marked_well")
	check_eq(Relationships.rim_journal().size(), 2, "the rim's page now says both")
	check(Relationships.rim_journal()[1].contains("beside it"), "in their order on the stone")


func test_drawing_first_then_her_name() -> void:
	memory().add_event("wren.met")
	memory().add_event("wren.marked_well")
	memory().add_event("wren.chalk")
	memory().add_event("wren.named")
	check(Relationships.rim_journal()[0].contains("Two dots"), "the drawing first")
	check(Relationships.rim_journal()[1].contains("beside it"), "then her name beside it")
	check_eq(Relationships._wren_own().get("lines"), Relationships.WREN_SAW_NAME, "\"next to you\"")


func test_her_fear_is_hers_not_the_wells_rule() -> void:
	var said := " ".join(Relationships.WREN_UNPLAYED)
	check(said.contains("never heard mine"), "she says what she has heard")
	check(not said.contains("can't keep") and not said.contains("cannot keep"), "not what the well can't do")
	check(not str(Relationships.EVENTS["wren.unplayed"]).contains("can't"), "and the journal records her question, not a law")


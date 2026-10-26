extends "res://tests/test_case.gd"
## Character beats added on 24 October (docs/REVIEW_OCT24.md, characters):
## Rue's first gesture of her own, Mira hearing her note is still up, Wren
## acting before she explains, a kept promise that changes what Wren can do,
## the Archivist's shorter first exchange with topics after it, and Pip's
## return.


# --- Rue -------------------------------------------------------------------------

func _press_save(w: Node) -> void:
	await interact_with(w, w.area.save_point, Vector2(0, 12))
	await wait(0.9)


func test_rue_presses_the_save_point_once_her_own_way() -> void:
	var w := await start_session()
	await _press_save(w)
	check(w.area.save_point._denied > 0.0 or w.area.save_point._uses == 1, "first: the habit, denied")
	await _press_save(w)
	check(not Relationships.has("rue.own_press"), "two presses: still the habit")
	await _press_save(w)
	check(Relationships.has("rue.own_press"), "the third: one press, her own")
	check(w.hud.history.any(func(e: Dictionary) -> bool: return e.text == Story.RUE_FIRST_OWN_PRESS) \
		or w.hud._queue.any(func(m: Dictionary) -> bool: return m.text == Story.RUE_FIRST_OWN_PRESS), "and she notices it")
	check(not Story.RUE_FIRST_OWN_PRESS.contains("her"), "without the truth: nothing about whose habit it was")


func test_the_habit_is_two_taps_and_a_press() -> void:
	var w := await start_session()
	check_eq(w.area.save_point.press_kind(), "habit", "the first press is the habit")


# --- Mira ------------------------------------------------------------------------

func test_mira_hears_her_note_is_still_up() -> void:
	OwnerMemory.mira_quest = "pinned"
	Relationships.add("mira.pinned")
	OwnerMemory.complete_conversation("mira.after_pinned")  # she asked Rue to look
	var w := await start_session()
	await go_to(w, "square", "house")
	await interact_with(w, w.area.board)
	await finish_dialogue(w)
	check(Relationships.has("mira.board_checked"), "Rue looked at the board for her")
	await go_to(w, "room", "start")
	var told: Variant = w.area._mira_lines()
	var lines: Array = told if told is Array else told.get("lines", [])
	check(lines == Relationships.MIRA_STILL_UP, "she hears it's still up (%s)" % [str(lines)])


func test_mira_does_not_thank_rue_for_looking_before_she_asked() -> void:
	OwnerMemory.mira_quest = "pinned"
	Relationships.add("mira.pinned")
	var w := await start_session()
	await go_to(w, "square", "house")
	await interact_with(w, w.area.board)
	await finish_dialogue(w)
	check(not Relationships.has("mira.board_checked"), "she hadn't asked yet: just reading the board")


# --- Wren ------------------------------------------------------------------------

func test_wren_waves_rue_over_before_she_explains() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var wren: Npc = w.area.wren
	w.player.global_position = wren.global_position + Vector2(60, 0)
	w.area.arin.global_position = w.player.global_position + Vector2(90, 0)
	await wait(0.4)
	check(w.area.wren_beckoned, "Arin coming, Rue in the open near her: Wren waves her over")
	check_eq(wren._emote, VillageSquare.WREN_BECKON, "a gesture, not a speech")
	check(not memory().has_conversation("wren.explained") and not Relationships.has("wren.sheltered"), "before any explanation")


func test_a_kept_promise_makes_her_shelter_wider() -> void:
	OwnerMemory.wren_saved = true
	Relationships.add("wren.promise_kept")
	var w := await start_session()
	await go_to(w, "square", "house")
	check(w.area.wren.hide_radius > 22.0, "safe for good: she can stand further out for Rue (%.0f)" % w.area.wren.hide_radius)


# --- the Archivist ----------------------------------------------------------------

func test_the_archivist_s_first_exchange_is_short_and_keeps_the_pointer() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "archive", "west")
	check(ArchiveArea.ARCHIVIST_FIRST.size() <= 4, "four lines, not seven (%d)" % ArchiveArea.ARCHIVIST_FIRST.size())
	await interact_with(w, w.area.archivist)
	check(w.flags.get("pointer", false), "the pointer at once")
	await finish_dialogue(w)
	check(Relationships.has("archivist.introduced"), "heard whole: introduced")


func test_the_rest_is_there_if_she_asks_again() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "archive", "west")
	await interact_with(w, w.area.archivist)
	await finish_dialogue(w)
	var seen := []
	for i in ArchiveArea.ARCHIVIST_TOPICS.size():
		await interact_with(w, w.area.archivist)
		seen.append(w.hud._dialogue_source_lines[0])
		await finish_dialogue(w)
	for t in ArchiveArea.ARCHIVIST_TOPICS:
		check(t in seen, "talking again, he tells the rest a piece at a time: %s" % t.left(30))
	await interact_with(w, w.area.archivist)
	check(w.hud._dialogue_source_lines[0] == ArchiveArea.ARCHIVIST_POINTER[0], "then the usual directions")
	await finish_dialogue(w)


func test_walking_off_a_topic_keeps_it() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "archive", "west")
	await interact_with(w, w.area.archivist)
	await finish_dialogue(w)
	await interact_with(w, w.area.archivist)
	var first: String = w.hud._dialogue_source_lines[0]
	w.hud.close_dialogue()
	await frames(3)
	await interact_with(w, w.area.archivist)
	check_eq(w.hud._dialogue_source_lines[0], first, "not heard: told next time")
	await finish_dialogue(w)


# --- Pip ---------------------------------------------------------------------------

func test_pip_greets_her_when_she_comes_back() -> void:
	memory().found_pip = true
	var w := await start_session()
	await wait_until(func() -> bool: return w.pip != null, 6.0, "Pip")
	check(w.pip.greeting(), "back after a run: Pip runs to her first")


func test_pip_leads_only_when_she_hesitates() -> void:
	memory().found_pip = true
	var w := await start_session()
	await wait_until(func() -> bool: return w.pip != null and w._awake, 8.0, "Pip")
	await go_to(w, "square", "house")
	await wait(Companion.ARRIVAL_LEAD + 0.5)
	Input.action_press("move_down")
	await wait(0.6)
	check(not w.pip.leading(), "while she walks: at her heel, not a route arrow")
	Input.action_release("move_down")
	await wait(Companion.HESITATE + 0.6)
	check(w.pip.leading(), "stood still: Pip noses toward what's next")

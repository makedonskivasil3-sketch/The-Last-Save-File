extends "res://tests/test_case.gd"
## The first friends' playtest (2026-11-05): E "not working or buggy",
## "a list to the side of what we should be looking for", characters
## arriving too suddenly, and the missing moment of shock for Wren.


func _all_memories() -> void:
	for f in Story.FRAGMENTS:
		if f.id not in memory().fragments:
			memory().fragments.append(f.id)


func _said(w: World) -> Array:
	return (w.hud.history + w.hud._queue).map(func(h: Dictionary) -> String: return str(h.text))


# --- E --------------------------------------------------------------------------

func test_a_half_second_press_on_mira_talks_and_freezes_nobody() -> void:
	var w := await start_session()
	var mira: Npc = w.area.mira
	w.player.global_position = mira.global_position + Vector2(0, 14)
	await frames(3)
	var glitches: int = memory().session_glitches
	await hold("interact", 0.6)  # the old FREEZE fired at about 0.62 s
	await frames(3)
	check(w.hud.is_dialogue_open(), "a press of 0.6 s on Mira talks to her")
	check_eq(mira.frozen, 0.0, "and doesn't freeze her")
	check_eq(memory().session_glitches, glitches, "no glitch fired")


func test_a_deliberate_hold_still_glitches_her() -> void:
	var w := await start_session()
	var mira: Npc = w.area.mira
	w.player.global_position = mira.global_position + Vector2(0, 14)
	await frames(3)
	check(GlitchController.hold_need(w.glitch.target) >= GlitchController.FRIENDLY_HOLD, "someone friendly needs a deliberate hold")
	await hold("interact", GlitchController.HOLD_START + GlitchController.FRIENDLY_HOLD + 0.3)
	await frames(3)
	check(mira.frozen > 0.0 or w.glitch._cooldown > 0.0, "held long enough, the glitch fires")


# --- the side checklist -----------------------------------------------------------

func test_the_side_list_shows_the_mission_steps_and_ticks_them() -> void:
	var w := await start_session()
	await wait(0.7)
	var text: String = w.hud.checklist_text()
	check(text.begins_with(Quests.TITLES.fifth_lantern), "the room: the first mission (%s)" % text)
	check(text.contains("○ Find a way out of the room"), "with its open steps")
	await go_to(w, "square", "house")
	await wait(0.7)
	text = w.hud.checklist_text()
	check(text.begins_with(Quests.TITLES.well_light), "the square: the next mission (%s)" % text)
	await go_to(w, "workshop", "stairs")
	w.area.wick.interact()
	await finish_dialogue(w)
	await wait(0.7)
	text = w.hud.checklist_text()
	check(text.contains("✓ Find the spare wick"), "a step done is ticked (%s)" % text)
	check(text.contains("○ Repair the service lamp"), "the next one still open")


func test_the_side_list_steps_aside_for_conversations() -> void:
	var w := await start_session()
	await wait(0.7)
	check(w.hud.checklist_text() != "", "shown in play")
	w.hud.show_dialogue("Mira", Color.WHITE, ["(a line)"], "", null, [], true)
	await frames(3)
	check_eq(w.hud.checklist_text(), "", "hidden while someone is talking")


# --- first meetings ----------------------------------------------------------------

func test_meeting_wren_starts_with_who_she_is_and_where_we_are() -> void:
	World.introductions = true
	var w := await start_session()
	await go_to(w, "square", "house")
	var wren: Npc = w.area.wren
	await interact_with(w, wren, Vector2(14, 0))
	await wait_until(func() -> bool: return w.hud.is_cinematic(), 3.0, "the introduction")
	check(w.hud._cine_title.text.contains("WREN"), "a card with her name (%s)" % w.hud._cine_title.text)
	await read_through_cinematic(w)
	await wait_until(func() -> bool: return w.hud.is_dialogue_open(), 3.0, "then her first words")
	await finish_dialogue(w)
	await interact_with(w, wren, Vector2(14, 0))
	await frames(4)
	check(not w.hud.is_cinematic(), "only the first time")
	World.introductions = false


# --- Wren sees what Rue is --------------------------------------------------------

func test_wren_sees_that_nobody_is_holding_rue() -> void:
	_all_memories()
	memory().met_archivist = true
	var w := await start_session()
	await go_to(w, "square", "house")
	var told: Dictionary = Relationships.wren(5, false, false)
	check(told.get("shock", false), "her truth comes as a shock")
	var lines: Array = told.get("lines", [])
	check(lines.size() == Story.WREN_SEES.size() + 1 and lines[0] == Story.WREN_SEES[0], "she sees it first, then says it")
	check_eq(lines[-1], Story.TRUTH_LINES.wren, "and her piece of the truth is still the last line")

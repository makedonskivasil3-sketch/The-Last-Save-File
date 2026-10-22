extends "res://tests/test_case.gd"
## A first session from a clean profile (2026-10-22 opening review, §10):
## title, the opening (played, skipped, or left to play itself), the
## hand-off, the boot, the first step, Mira, and leaving the room. Nothing
## is fabricated: no earlier death, no earlier run.



func _fresh_title() -> Node:
	settings().opening_seen = false
	check_eq(memory().last_exit, "none", "a profile that has never entered a run")
	check_eq(memory().sessions, 0, "no earlier session")
	tree.change_scene_to_file(TITLE_SCENE)
	await frames(5)
	return scene()


## From the film to the room: the boot read, Rue awake, "you" over her.
func _into_the_room() -> Node:
	await wait_until(func() -> bool: return scene() is World, 8.0, "the first room")
	var w := scene()
	await wait_until(func() -> bool: return w.hud.is_cinematic(), 4.0, "the boot text")
	await read_through_cinematic(w)
	await wait_until(func() -> bool: return w._awake and not w._cutscene, 6.0, "awake")
	check_eq(memory().sessions, 1, "one genuine first session")
	check_eq(memory().deaths + memory().quits, 0, "no death or quit was fabricated")
	check(w.player.you_cue, "'you' over her: the same figure the player drove")
	return w


## The first step, Mira, and the way out.
func _first_minute(w: Node) -> void:
	var start: Vector2 = w.player.global_position
	Input.action_press("move_up")
	await wait(0.4)
	Input.action_release("move_up")
	check(w.player.global_position.distance_to(start) > 4.0, "she moves on the first input")
	check(not w.player.you_cue, "the cue goes at the first step")
	await interact_with(w, w.area.mira)
	check(w.hud.is_dialogue_open(), "Mira talks")
	await finish_dialogue(w)
	check(memory().has_met("mira"), "Mira met")
	await go_to(w, "square", "house")
	check_eq(w.area.area_id, "square", "out of Arin's room")


func test_played_through() -> void:
	var title := await _fresh_title()
	title._start()
	await wait_until(func() -> bool: return scene() is Opening, 3.0, "the film")
	var film: Opening = scene()
	film.autoplay = true  # each state is done at once (the player's actions are covered in test_opening)
	await wait_until(func() -> bool: return film._t > Opening.GATE_AT[Opening.Gate.IMPOSSIBLE] + 1.0, 60.0, "through the three states")
	check(film.acted.has("ritual_auto") and film.acted.has("interrupt_auto") and film.acted.has("impossible"), "every state done, in order (%s)" % film.acted)
	film._t = Opening.LENGTH - 0.5  # (the rest is film)
	var w := await _into_the_room()
	await _first_minute(w)


func test_skipped() -> void:
	var title := await _fresh_title()
	title._start()
	await wait_until(func() -> bool: return scene() is Opening, 3.0, "the film")
	await frames(2)
	Input.action_press("interact")
	await wait(Opening.SKIP_HOLD + 0.2)
	check(scene() is Opening and scene()._done, "held to the end: skipped, and the hand-off waits for the release")
	Input.action_release("interact")
	var w := await _into_the_room()
	check_eq(w.glitch._charge, 0.0, "the skip's press didn't charge anything in the room")
	await _first_minute(w)


func test_left_to_play_itself() -> void:
	var title := await _fresh_title()
	title._start()
	await wait_until(func() -> bool: return scene() is Opening, 3.0, "the film")
	var film: Opening = scene()
	# No input at all: each state hints, then plays itself. (Time is
	# advanced through the waiting, not skipped: the gates still decide.)
	for i in 400:
		if film._done or not is_instance_valid(film):
			break
		film._process(0.25)
	check(film.acted.has("ritual_auto") and film.acted.has("interrupt_auto") and film.acted.has("impossible_auto"), "nobody pressed: all three played themselves (%s)" % film.acted)
	var w := await _into_the_room()
	await _first_minute(w)


## Interrupted: walking off from Mira mid-sentence and coming back never
## turns a first meeting into a reunion.
func test_interrupted_first_meeting_is_not_a_reunion() -> void:
	var w := await start_session(true, true)
	await wait_until(func() -> bool: return w._awake, 10.0, "awake")
	await interact_with(w, w.area.mira)
	await press("interact")
	w.hud.close_dialogue()  # walked off mid-sentence
	await frames(3)
	check(not Relationships.has("mira.asked"), "her request was never heard, so it isn't asked")
	var told: Variant = w.area._mira_lines()
	var lines: Array = told if told is Array else told.get("lines", [])
	check(not str(lines).contains("again"), "still a first acquaintance, not 'again' (%s)" % [str(lines)])

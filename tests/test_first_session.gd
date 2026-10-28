extends "res://tests/test_case.gd"
## A first session from a clean profile: title, the festival (played,
## skipped, or left to play itself: scripts/ui/prologue.gd), the hand-off,
## the room (no boot log: the festival showed its own), the first step,
## Mira, and leaving the room. Nothing is fabricated: no earlier death, no
## earlier run.



func _fresh_title() -> Node:
	settings().opening_seen = false
	check_eq(memory().last_exit, "none", "a profile that has never entered a run")
	check_eq(memory().sessions, 0, "no earlier session")
	tree.change_scene_to_file(TITLE_SCENE)
	await frames(5)
	return scene()


## From the festival to the room: no boot log, Rue awake, "you" over her.
func _into_the_room() -> Node:
	await wait_until(func() -> bool: return scene() is World, 12.0, "the first room")
	var w := scene()
	await wait_until(func() -> bool: return w._awake and not w._cutscene, 8.0, "awake")
	check(not w.hud.is_cinematic(), "no boot log: the festival showed it, in the square")
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


func _the_festival() -> Prologue:
	await past_cold_open()
	await wait_until(func() -> bool: return scene() is Prologue, 3.0, "the festival")
	return scene()


## Steps the festival in game time until `cond` (the rest is covered in
## test_prologue), then lets the hand-off happen in real frames.
func _step_until(p: Prologue, cond: Callable, seconds: float) -> void:
	for i in int(seconds / 0.05):
		if cond.call() or p._done:
			return
		p._process(0.05)


func test_played_through() -> void:
	var title := await _fresh_title()
	title._start()
	var p := await _the_festival()
	p.autoplay = true  # the player acts as soon as asked (the steps are covered in test_prologue)
	_step_until(p, func() -> bool: return p._done, 400.0)
	check(p.acted.has("lit_4") and p.acted.has("p1_left") and p.acted.has("p2_left") and p.acted.has("load"), "every beat, in order (%s)" % [str(p.acted)])
	check_eq(memory().festival_choice, "tried", "her first decision is kept")
	check(p.acted.has("lit_by_herself"), "and the impossible action was played")
	var w := await _into_the_room()
	await _first_minute(w)


func test_skipped() -> void:
	var title := await _fresh_title()
	title._start()
	var p := await _the_festival()
	await frames(2)
	Input.action_press("ui_cancel")
	await wait(Prologue.SKIP_HOLD + 0.2)
	_step_until(p, func() -> bool: return p._done, Prologue.LOAD_TIME + 1.0)
	check(scene() is Prologue and p._done, "held to the end: skipped, and the hand-off waits for the release")
	Input.action_release("ui_cancel")
	var w := await _into_the_room()
	check_eq(w.glitch._charge, 0.0, "the skip's press didn't charge anything in the room")
	await _first_minute(w)


func test_left_to_play_itself() -> void:
	var title := await _fresh_title()
	title._start()
	var p := await _the_festival()
	# Movement assistance may demonstrate a step, but it must not erase a
	# story page. A passive player stops at the first readable conversation.
	_step_until(p, func() -> bool: return p.story.visible, 300.0)
	check(p.story.visible, "the first conversation waits for its reader")
	var at := p.beat_t
	_step_until(p, func() -> bool: return p._done, 60.0)
	check_eq(p.beat_t, at, "waiting to read never advances the festival")
	# Read each story page deliberately; otherwise let assistance demonstrate
	# the movement. Doing nothing at the decision still means neither option.
	for i in 18000:
		if p._done:
			break
		p._process(0.05)
		if p.story.visible:
			p.story.advance()
	check(p._done and p.acted.has("lit_4"), "assisted movement plus acknowledged pages completes (%s)" % [str(p.acted)])
	check_eq(p.choice, "idle", "the decision isn't made for them: doing nothing is recorded as such")
	check(p.acted.has("lit_by_herself"), "and Rue lights the last one herself, with nobody holding her")
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

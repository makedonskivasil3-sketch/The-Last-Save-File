extends "res://tests/test_case.gd"
## What a character's body says matches what the story says
## (docs/PRESENTATION_FUNCTIONALITY_AUDIT.md, character states): a mouth moves
## only while that character's line is being typed or voiced; someone who
## answers in writing, or can't speak, never mouths; a restricted character
## stands still (no greeting hop, no wave, no reading); a book is never drawn
## on someone's back; and the portrait's mouth runs on one clock.


func test_mira_s_mouth_moves_only_while_her_line_is_spoken() -> void:
	var w := await start_session()
	var mira: Npc = w.area.mira
	check(not mira.sprite().talking, "before talking: her mouth is still")
	await interact_with(w, mira)
	await frames(2)
	check(w.hud.is_dialogue_open() and mira.talking, "talking to Mira")
	check(w.hud.is_line_speaking(), "her line is being typed")
	check(mira.sprite().talking, "so her mouth moves")
	await press("interact")  # show the rest of the line
	await wait_until(func() -> bool: return not w.hud.is_line_speaking(), 6.0, "the line to be done")
	await frames(2)
	check(w.hud.is_dialogue_open() and mira.talking, "the box waits for the next press")
	check(not mira.sprite().talking, "and her mouth rests while it waits")
	check(w.hud._dialogue_portrait.frame != "talk", "the portrait's too")
	await finish_dialogue(w)
	await frames(2)
	check(not mira.sprite().talking and not mira.talking, "after: still")


func test_frayed_tobben_writes_and_never_mouths() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	memory().frayed.append("tobben")
	var tobben: Npc = w.area.tobben
	tobben.refresh_fray()
	await interact_with(w, tobben)
	await frames(2)
	check_eq(w.hud._dialogue_speaker.text, Story.TOBBEN_WRITTEN, "Tobben answers in writing")
	check(w.hud.dialogue_silent, "a written answer is not spoken")
	var mouthed := false
	var portrait_talked := false
	for i in 30:
		mouthed = mouthed or tobben.sprite().talking
		portrait_talked = portrait_talked or w.hud._dialogue_portrait.frame == "talk"
		await frames(2)
	check(not mouthed, "his mouth never moves while his note is shown")
	check(not portrait_talked, "nor does his portrait's")
	await finish_dialogue(w)
	memory().frayed.erase("tobben")
	tobben.refresh_fray()


func test_a_mute_character_never_mouths() -> void:
	var w := await start_session()
	w.area._build_purged_extras()  # the real Arin, who says nothing
	await frames(2)
	var arin: Npc = null
	for n in w.area.interactables:
		if n is Npc and n.npc_id == "arin":
			arin = n
	check(arin != null and arin.mute, "the real Arin is here, and mute")
	if arin == null:
		return
	await interact_with(w, arin)
	await frames(2)
	check(w.hud.is_dialogue_open(), "the box opens on her silence")
	var mouthed := false
	for i in 30:
		mouthed = mouthed or arin.sprite().talking or w.hud._dialogue_portrait.frame == "talk"
		await frames(2)
	check(not mouthed, "she never mouths a line")
	await finish_dialogue(w)


func test_restricted_characters_stand_still() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var tobben: Npc = w.area.tobben
	var wren: Npc = w.area.wren
	w.player.global_position = tobben.global_position + Vector2(0, 40)
	await frames(3)
	check(tobben.sprite().waving, "free, Tobben waves you over")
	tobben.state = Npc.State.RESTRICTED
	wren.state = Npc.State.RESTRICTED
	await frames(2)
	check(not tobben.sprite().waving, "restricted, he doesn't")
	check_eq(wren.sprite().idle_style, "", "restricted, Wren has no idle (no hop)")
	var hopped := false
	for i in 60:
		hopped = hopped or wren.sprite()._hop > 0.0
		await wait(0.1)
	check(not hopped, "and doesn't hop in six seconds")
	tobben.state = Npc.State.NORMAL
	wren.state = Npc.State.NORMAL
	await frames(2)
	check(tobben.sprite().waving, "freed, he waves again")
	check_eq(wren.sprite().idle_style, "hop", "and her own idle comes back")


func test_the_book_is_never_drawn_on_a_back() -> void:
	var c := PixelCharacter.new("adult", {})
	c.idle_style = "read"
	c.facing = Vector2.DOWN
	check(c.shows_book(), "reading, facing you: the book")
	c.facing = Vector2.LEFT
	check(c.shows_book(), "to the side: the book")
	c.facing = Vector2.UP
	check(not c.shows_book(), "facing away: no book on the back")
	c.facing = Vector2.DOWN
	c.talking = true
	check(not c.shows_book(), "talking: the book is lowered")
	c.talking = false
	c.moving = true
	check(not c.shows_book(), "walking: not reading")


func test_the_portrait_mouth_has_one_clock() -> void:
	var w := await start_session()
	await interact_with(w, w.area.mira)
	await frames(2)
	var view: PortraitView = w.hud._dialogue_portrait
	var frames_seen := {}
	var opens := {}
	for i in 24:
		if w.hud.is_line_speaking():
			frames_seen[view.frame] = true
			opens[view.mouth_open()] = true
			check_eq(view.mouth_open(), fmod(view._figure._t, 0.24) < 0.12, "open exactly on the figure's beat")
		await frames(1)
	if not Settings.reduce_flashing:
		check_eq(frames_seen.keys(), ["talk"], "while speaking the HUD holds one 'talk' state (no second toggle)")
		check_eq(opens.size(), 2, "and the mouth still opens and closes")
	await finish_dialogue(w)

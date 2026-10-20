extends "res://tests/test_case.gd"
## Phase 2: the fantasy, said louder. First boot, title, death cards, the
## feel of spending awareness, the first room, the Records the owner reads.


func test_death_cards_are_specific() -> void:
	check(Story.death_body("arin", "square", 1, true).contains("wren"), "Wren saw it")
	check(Story.death_body("cursor", "edge", 1, false).contains("slot 2"), "the click at the Edge")
	check(Story.death_body("save", "room", 2, false).contains("again"), "saved over again")
	check(Story.death_body("eraser", "edge", 1, false) != Story.death_body("eraser", "square", 1, false), "the Edge's static is its own death")


func test_the_death_card_uses_them() -> void:
	var w := await start_session()
	w.owner_moves.save_progress = 0.99
	await wait(1.4)
	check(w.hud._overlay_body.text.contains("version of this room without you"), "saved over: %s" % w.hud._overlay_body.text)


func test_a_glitch_leaves_a_scar_and_shakes_the_world() -> void:
	var w := await start_session(true, true)
	w.player.global_position = w.area.note.global_position + Vector2(0, 20)
	await frames(2)
	await hold("interact", 0.8)
	var scars: Array = w.area.get_children().filter(func(n: Node) -> bool: return n is GlitchScar)
	check(scars.size() == 1, "a scar where it fired")



func test_the_owner_loses_patience() -> void:
	var w := await start_session()
	w.glitches_used = 2
	w.glitch._reacted["phase"] = true  # past the first reaction
	w.glitch._pay("phase")
	await wait(1.2)
	var said := ""
	for q in w.hud._queue:
		said += str(q.text)
	for l in w.hud._console.find_children("*", "Label", true, false):
		said += (l as Label).text
	said += w.hud._typing.text if w.hud._typing else ""
	check(said.contains(Story.GLITCH_ESCALATION[3]), "the third glitch: '%s'" % Story.GLITCH_ESCALATION[3])


func test_the_first_glitch_teaches_its_price() -> void:
	settings().tutorial_tips = true
	var w := await start_session(true, true)
	settings().tips_seen.append_array(["move", "watched", "quit", "wren", "interact", "way_out", "crack", "glitch"])
	w.glitches_used = 1
	await wait_until(func() -> bool: return w.hud.is_tip_shown(), 8.0, "a tip")  # after the act card
	check(w.hud._tip_title.text == Story.PRICE_TIP[0], "THE PRICE (%s)" % w.hud._tip_title.text)


func test_the_title_whispers_the_first_time() -> void:
	tree.change_scene_to_file("res://scenes/title.tscn")
	await frames(3)
	var title := scene()
	title._whisper_t = 13.7
	await frames(2)
	check(title._load.text != "Load Slot 1", "the Load button says what it means (%s)" % title._load.text)
	title._whisper_t = 9.0
	await wait(2.5)
	check(title._owner_line.text == Story.TITLE_FIRST_OWNER and title._owner_line.visible_characters > 3, "the owner types into the menu")


func test_the_records_are_read_by_the_owner() -> void:
	memory().sessions = 3
	memory().deaths = 2
	tree.change_scene_to_file("res://scenes/title.tscn")
	await frames(3)
	var title := scene()
	title._show_records()
	await wait(4.5)
	var text := ""
	for l in title.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			text += (l as Label).text + "\n"
	check(text.contains("> " + Story.records_margin("counted")), "the owner's margin notes")
	check(text.contains("> i read this"), "and the owner types while you read")

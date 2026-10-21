extends "res://tests/test_case.gd"

func test_written_tobben_and_silent_arin_do_not_mouth_typing() -> void:
	var w := await start_session()
	for entry in [[Story.TOBBEN_WRITTEN, "tobben", "I wrote this."], ["ARIN", "arin", "..."]]:
		var p := CharacterArt.Portrait.new(entry[1], "neutral", {})
		w.hud.show_dialogue(entry[0], Color.WHITE, [entry[2]], "", p)
		w.hud._face_t = 0.0
		w.hud._update_dialogue_face(0.0)
		check(w.hud._dialogue_portrait.frame != "talk", "%s is text, not mouth speech" % entry[0])
	w.hud.close_dialogue()

func test_world_mouth_stops_while_waiting_for_the_next_press() -> void:
	var w := await start_session()
	var npc: Npc = w.area.mira
	w._talking_to = npc
	w.hud.show_dialogue("MIRA", Color.WHITE, ["Hello there."], "", CharacterArt.for_npc(npc))
	w.hud._dialogue_typed = 1000
	w.hud._dialogue_text.visible_characters = -1
	w.hud._pacer.reveal(Engine.get_process_frames())
	w._process(0.0)
	npc._process(0.0)
	check(not npc.sprite().talking, "a fully revealed silent line does not flap until the conversation closes")

func test_speaking_escort_does_not_restart_turn_squash_every_frame() -> void:
	var w := await start_session()
	var npc: Npc = w.area.mira
	npc.set_process(false)
	npc.escorted = true
	npc.global_position = Vector2(340, 180)
	w.player.global_position = Vector2(320, 180)
	npc._walk_velocity = Vector2(60, 0)
	npc.talking = true
	npc._process(0.02)
	for i in 20:
		npc._process(0.02)
	check_eq(npc.sprite().facing, Vector2.LEFT, "conversation gaze still faces Rue")
	check_eq(npc.sprite().turn, 0.0, "movement and gaze do not fight over a perpetual turn")

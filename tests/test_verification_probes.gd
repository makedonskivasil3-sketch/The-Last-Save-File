extends "res://tests/test_case.gd"
## Re-verification of the narrative reliability pass (docs/VERIFICATION.md):
## behaviour the earlier tests did not exercise end to end.


func _clip(seconds: float) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = 11025
	var data := PackedByteArray()
	data.resize(int(11025 * seconds) * 2)
	w.data = data
	return w


func _scene(hud: Hud, done: Array) -> void:
	await hud.cinematic("TEST", ["a scene over the conversation."], Hud.SELF_COLOR, 0.5)
	done[0] = true


func test_a_scene_over_a_recorded_conversation_says_the_line_again() -> void:
	var w := await start_session()
	var line: String = ArinsRoom.MIRA_LINES[0]
	var id := Hud.voice_id("npc.mira", line)
	VoiceOver.register(id, _clip(4.0))
	await interact_with(w, w.area.mira)
	check(w.hud.is_dialogue_open(), "talking to Mira")
	check_eq(VoiceOver.current_id(), id, "her recorded line plays")
	var done := [false]
	_scene.call_deferred(w.hud, done)
	await wait_until(func() -> bool: return w.hud.is_cinematic(), 3.0, "the scene")
	await frames(2)
	check(VoiceOver.current_id() != id, "the scene cuts her voice at once")
	await read_through_cinematic(w)
	await wait_until(func() -> bool: return done[0], 3.0, "the scene to end")
	check(w.hud.is_dialogue_open(), "back in the conversation")
	check_eq(w.hud._dialogue_text.text, line, "on the same line")
	check_eq(VoiceOver.current_id(), id, "and the line is said again from the start")
	check(w.hud._pacer.phase == LinePacer.Phase.REVEALING, "and types out again: a press reveals it before one can skip it")
	await finish_dialogue(w)


func test_the_death_card_ignores_presses_while_paused() -> void:
	var w := await start_session()
	w.kill("erased", "arin")
	await wait_until(func() -> bool: return w.hud._overlay_retry.visible, 4.0, "the retry prompt")
	tree.paused = true
	await press("interact")
	await frames(3)
	check(is_instance_valid(w) and scene() == w, "a press while paused doesn't retry")
	tree.paused = false
	var next := await wait_for_new_session(w)
	check(next != null, "unpaused, a press retries")


func test_rue_cannot_walk_while_reading() -> void:
	var w := await start_session()
	await interact_with(w, w.area.mira)
	check(w.hud.is_dialogue_open(), "talking to Mira")
	var at: Vector2 = w.player.global_position
	await hold("move_left", 0.6)
	check(w.player.global_position.distance_to(at) < 1.0, "real movement keys don't move Rue while she reads")
	check(w.hud.is_dialogue_open(), "and the conversation stays open")
	await finish_dialogue(w)
	at = w.player.global_position
	await hold("move_left", 0.4)
	check(w.player.global_position.distance_to(at) > 4.0, "after the box closes she walks again")


## The guest book scene froze Rue but not the owner: a save-over or the
## cursor could land in the middle of it. Every scene holds the owner.
func test_a_scene_holds_the_owner_like_a_conversation() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.add_awareness(OwnerDirector.HUNT + 1.0 - w.director.awareness)
	w.player.frozen = true  # as the guest book scene does
	var done := [false]
	_scene.call_deferred(w.hud, done)
	await wait_until(func() -> bool: return w.hud.is_cinematic(), 3.0, "the scene")
	await frames(2)
	var aw: float = w.director.awareness
	w.owner_moves.start_save_over()
	check_eq(w.owner_moves.save_progress, -1.0, "no save-over starts during a scene")
	await wait(2.0)
	check(w.director.awareness <= aw + 0.01, "awareness holds during the scene")
	check(w.area.cursor.paused, "the cursor holds")
	await read_through_cinematic(w)
	w.player.frozen = false
	await frames(3)
	check(not w.is_owner_paused(), "and lets go afterwards")

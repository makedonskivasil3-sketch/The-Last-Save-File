extends "res://tests/test_case.gd"

func test_nearby_targets_remain_stable_and_release_out_of_range() -> void:
	var w := await start_session()
	w.director.stop()
	var origin := Vector2(320, 210)
	var a: Readable = w.area.add_readable("A", origin + Vector2(-10, 0), Readable.Look.SIGN, func() -> Array: return ["First"])
	var b: Readable = w.area.add_readable("B", origin + Vector2(10, 0), Readable.Look.SIGN, func() -> Array: return ["Second"])
	w.area.interactables = [a, b] as Array[Node2D]
	w.player.global_position = origin + Vector2(-1, 0)
	w._update_focus()
	check(w._focused == a, "first nearby object is focused")
	w.player.global_position = origin + Vector2(1, 0)
	w._update_focus()
	check(w._focused == a, "one-pixel movement does not steal the prompt")
	w.player.global_position = origin + Vector2(8, 0)
	w._update_focus()
	check(w._focused == b, "walking toward the other object switches focus")
	w.tap_interact()
	check_eq(w.hud._dialogue_speaker.text, "B", "interaction uses the indicated target")
	w.hud.close_dialogue()
	w.player.global_position = origin + Vector2(0, 100)
	w._update_focus()
	check(w._focused == null, "stability never extends interaction range")

func test_safe_area_music_responds_to_dialogue_and_danger() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.stop()
	w.player.global_position = Vector2(320, 270)
	var ambience: Ambience = w._ambience
	await wait_until(func() -> bool: return ambience._memory_theme.playing, 5.0, "background music")
	ambience._update_memory_theme(10.0)
	var calm := ambience._memory_theme.volume_db
	w.hud.show_dialogue("MIRA", Color.WHITE, ["Listen."])
	ambience._update_memory_theme(10.0)
	check(ambience._memory_theme.volume_db < calm - 6.0, "dialogue has room above the music")
	w.hud.close_dialogue()
	w.director.awareness = 90.0
	ambience._update_memory_theme(10.0)
	check(ambience._memory_theme.volume_db < calm - 6.0, "danger thins the musical layer")

func test_narration_is_optional_and_persists() -> void:
	var s := settings()
	var previous: bool = s.narration
	s.set_value("narration", true)
	s.narration = false
	s._load()
	check(s.narration, "spoken narration preference survives loading settings")
	s.set_value("narration", false)
	var w := await start_session()
	w.hud.show_dialogue("MIRA", Color.WHITE, ["You can still read me."])
	check_eq(w.hud.narrator.last_text, "", "disabled narration never speaks")
	check_eq(w.hud._dialogue_text.text, "You can still read me.", "captions remain available")
	w.hud.narrator.stop()
	s.set_value("narration", previous)


func test_contextual_tips_do_not_follow_you_into_another_area() -> void:
	var w := await start_session()
	settings().tutorial_tips = true
	settings().tips_seen.clear()
	var tutorial: Tutorial = null
	for child in w.get_children():
		if child is Tutorial:
			tutorial = child
	check(tutorial != null, "session has contextual tutorial")
	if tutorial == null:
		return
	tutorial._show("way_out")
	await go_to(w, "square", "house")
	await frames(2)
	check(tutorial._current != "way_out", "room's locked-door lesson ends when the player leaves")
	check(tutorial._next_tip() != "way_out", "the house door does not teach the room's seam puzzle")
	settings().tutorial_tips = false


class RecordingNarration extends Narration:
	func speak(text: String, speaker := "") -> void:
		last_text = speaker + ": " + text

func test_dialogue_sends_the_correct_speaker_and_cancels_on_close() -> void:
	var w := await start_session()
	w.hud.narrator.queue_free()
	var recording := RecordingNarration.new()
	w.hud.add_child(recording)
	w.hud.narrator = recording
	w.hud.show_dialogue("WREN", Color.WHITE, ["Stay beside me.", "Keep going."])
	check_eq(recording.last_text, "WREN: Stay beside me.", "narration receives the readable speaker and line")
	w.hud._dialogue_index = 1
	w.hud._show_dialogue_line()
	check_eq(recording.last_text, "WREN: Keep going.", "advancing replaces the previous spoken line")
	w.hud.close_dialogue()
	check_eq(recording.last_text, "", "walking away cancels old narration")


func test_each_character_speaks_in_their_own_voice() -> void:
	# Spoken narration (Settings): own pitch and pace for everyone, and their
	# own system voice where the device has several (an iPhone has many).
	var many := {}
	for who in ["", "OWNER", "MIRA", "WREN", "TOBBEN", "THE ARCHIVIST", "ARIN", "PIP"]:
		var how: Dictionary = Narration.speech_for(who, 12)
		check(not how.say_name, "%s: with their own voice, no name read out first" % who)
		many[how.voice] = true
		check(how.pitch > 0.0 and how.pitch <= 2.0 and how.rate >= 0.5 and how.rate <= 2.0, "%s: a pitch and pace the device accepts" % who)
	check_eq(many.size(), 8, "eight speakers, eight different voices")
	check(Narration.speech_for("WREN", 12).pitch > Narration.speech_for("MIRA", 12).pitch, "Wren, the child, speaks higher than Mira")
	check(Narration.speech_for("THE ARCHIVIST", 12).pitch < Narration.speech_for("TOBBEN", 12).pitch, "the Archivist lowest")
	var one: Dictionary = Narration.speech_for("MIRA", 1)
	check_eq(one.voice, 0, "one device voice: everyone shares it")
	check(one.say_name, "and the name is read out so you know who is talking")
	check_eq(Narration.speech_for("SOMEONE NEW", 12).voice, Narration.speech_for("", 12).voice, "an unknown speaker uses the narration voice")

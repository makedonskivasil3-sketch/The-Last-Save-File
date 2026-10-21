extends "res://tests/test_case.gd"
## Staged UI/pose references, not a human playtest or hardware benchmark.

func test_dialogue_and_large_recorded_caption() -> void:
	var w := await start_session()
	w.director.paused = true
	w.hud.show_dialogue("MIRA", Color("e0a070"), ["Who are you?"], "", CharacterArt.for_npc(w.area.mira, "afraid"))
	await frames(4)
	await shot("mira_live_dialogue")
	w.hud._dialogue_typed = 1000
	w.hud._pacer.reveal(Engine.get_process_frames())
	await frames(4)
	check(not w.hud.dialogue_is_speaking(), "mouth rests while the visible line waits")
	await shot("mira_waiting_for_input")
	settings().large_text = true
	settings().subtitle_size = 2
	w.hud.apply_subtitle_style()
	var text := "This is a synthetic caption fixture. A long recorded performance keeps playing as its captions turn into readable pages. This reference checks the largest combined text settings beside the real character portrait. No new voice performance is supplied by this test."
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 8000
	var bytes := PackedByteArray()
	bytes.resize(80000)
	bytes.fill(128)
	wav.data = bytes
	VoiceOver.register(Hud.voice_id("tour.caption", text), wav)
	w.hud.show_dialogue("MIRA", Color.WHITE, [text], "tour.caption", CharacterArt.for_npc(w.area.mira))
	w.hud._dialogue_typed = 1000
	w.hud._pacer.reveal(Engine.get_process_frames())
	await frames(4)
	w.hud._fit_dialogue()
	check(w.hud._dialogue.position.y >= Hud.SAFE.y, "large caption remains in the safe area")
	await shot("large_recorded_caption")
	w.hud.close_dialogue()

func test_written_and_restricted_poses() -> void:
	var w := await start_session()
	w.director.paused = true
	await go_to(w, "square", "house")
	var npc: Npc = w.area.tobben
	memory().frayed.assign(["tobben"])
	npc.refresh_fray()
	w._talking_to = npc
	w.hud.show_dialogue(Story.TOBBEN_WRITTEN, Color.WHITE, ["The words are written. He has no voice left."], "", CharacterArt.for_npc(npc))
	await frames(6)
	check(not npc.sprite().talking, "the written world response is mute")
	check(w.hud._dialogue_portrait.frame != "talk", "the written portrait is mute")
	await shot("tobben_written_response")
	w.hud.close_dialogue()

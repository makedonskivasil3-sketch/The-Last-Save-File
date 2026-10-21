extends "res://tests/test_case.gd"
## Exercise the actual illustrated portrait, not CharacterArt's legacy raster.

class SpeechHud:
	extends Hud
	var speech_active := false
	func voice_busy() -> bool:
		return speech_active


func test_visible_portrait_advances_its_animation_clock() -> void:
	var host := Control.new()
	tree.root.add_child(host)
	var view := PortraitView.new()
	host.add_child(view)
	view.set_process(false)
	view.portrait = CharacterArt.mira()
	view._figure._t = 0.0
	view.frame = "talk"
	view._process(0.15)
	check(absf(view._figure._t - 0.15) < 0.0001, "the real renderer clock advances while the portrait is visible")
	check(view._figure.talking, "speech pose survives animation updates")
	host.hide()
	var at: float = view._figure._t
	view._process(0.15)
	check_eq(view._figure._t, at, "a hidden ancestor suspends portrait animation")
	host.queue_free()
	await frames(2)


func test_portrait_tracks_speech_after_text_is_fully_revealed() -> void:
	var hud := SpeechHud.new()
	tree.root.add_child(hud)
	hud.set_process(false)
	hud.show_dialogue("MIRA", Hud.SELF_COLOR, ["still speaking"], "", CharacterArt.mira())
	hud._pacer.reveal(Engine.get_process_frames())
	hud.speech_active = true
	hud._face_t = 0.0
	hud._update_dialogue_face(0.0)
	check_eq(hud._dialogue_portrait.frame, "talk", "a speaking line animates even after its text is fully shown")
	hud.speech_active = false
	hud._update_dialogue_face(0.0)
	check_eq(hud._dialogue_portrait.frame, "", "speech completion releases the mouth pose")
	hud.speech_active = true
	settings().reduce_flashing = true
	hud._update_dialogue_face(0.0)
	check(hud._dialogue_portrait.frame != "talk", "reduced flashing still suppresses mouth alternation")
	hud.queue_free()
	await frames(2)

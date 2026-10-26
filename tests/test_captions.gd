extends "res://tests/test_case.gd"
## A long recorded line is one performance shown as caption pages
## (docs/STORY_PACING.md): the take plays once, uninterrupted, while its
## pages follow it; every word is shown; the story event for the line happens
## once; and the box always fits the screen, at every text size. The audio
## here is a silent test fixture, not a performance.

const LONG := "the controller was still warm when she put it down. she said she'd be back for the last level, the one with the lighthouse, and that i should keep her slot exactly as it was. i did. i kept it for three years. the owner didn't know i was listening. nobody ever thinks the save is listening, but the save is all we are."


func _clip(seconds: float) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = 11025
	var data := PackedByteArray()
	data.resize(int(11025 * seconds) * 2)
	w.data = data
	return w


func _press(w: Node) -> void:
	await press("interact", false)
	await frames(2)


func _cleanup() -> void:
	VoiceOver.clear_registered()
	settings().subtitle_size = 0
	settings().large_text = false
	settings().advance_mode = 0
	settings().auto_speed = 1


func test_a_long_recorded_line_plays_once_across_its_caption_pages() -> void:
	var w := await start_session()
	var id := Hud.voice_id("test.long", LONG)
	VoiceOver.register(id, _clip(8.0))
	var shown := []
	w.hud.line_revealed.connect(func(t: String) -> void: shown.append(t))
	w.hud.show_dialogue("RUE", Hud.SELF_COLOR, [LONG], "test.long")
	await frames(2)
	var pages: int = w.hud._dialogue_lines.size()
	check(pages >= 2, "a 300-character recorded line is shown in pages (%d)" % pages)
	check_eq(" ".join(w.hud._dialogue_lines), LONG, "every word is on a page, the last ones too")
	var take := VoiceOver.current()
	check(take != null and take.playing, "the take starts with the first page")
	await _press(w)  # reveal
	await _press(w)  # next page
	check_eq(w.hud._dialogue_index, 1, "on the second page")
	check(VoiceOver.current() == take and is_instance_valid(take) and take.playing, "the same take carries on: not restarted, not cut")
	while w.hud.is_dialogue_open():
		await _press(w)
	check_eq(shown.size(), 1, "the line's story event happens once, not once per page")
	_cleanup()


func test_in_auto_the_last_page_waits_for_the_last_words() -> void:
	var w := await start_session()
	settings().advance_mode = 1  # auto
	settings().auto_speed = 2  # fast reading, so the take (slower) is what sets the end
	var id := Hud.voice_id("test.long", LONG)
	VoiceOver.register(id, _clip(StoryPacing.reading_time(LONG, 2) + 6.0))
	w.hud.show_dialogue("RUE", Hud.SELF_COLOR, [LONG], "test.long")
	var take := VoiceOver.current()
	var pages: int = w.hud._dialogue_lines.size()
	await wait_until(func() -> bool: return w.hud._dialogue_index == pages - 1 or not w.hud.is_dialogue_open(), 60.0, "the last page")
	check(w.hud.is_dialogue_open(), "the box is still open on the last page")
	check(is_instance_valid(take) and take.playing, "the take is still speaking the last page's words")
	await wait_until(func() -> bool: return not w.hud.is_dialogue_open(), 60.0, "the box to close after the take")
	check(not is_instance_valid(take) or not take.playing, "it closed only after the take finished")
	_cleanup()


func test_the_box_fits_the_screen_at_every_text_size() -> void:
	var w := await start_session()
	VoiceOver.register(Hud.voice_id("test.long", LONG), _clip(8.0))
	for big in [false, true]:
		for size in [0, 1, 2]:
			settings().subtitle_size = size
			settings().large_text = big
			UiStyle.rescale_text(tree)
			w.hud.show_dialogue("RUE", Hud.SELF_COLOR, [LONG], "test.long", CharacterArt.rue("neutral", w.player.palette()))
			for i in w.hud._dialogue_lines.size():
				w.hud._dialogue_text.visible_characters = -1
				w.hud._fit_dialogue()
				await frames(1)
				var box := Rect2(w.hud._dialogue.position, w.hud._dialogue.size)
				check(Rect2(0, 0, 640, 360).encloses(box), "subtitles %d, large %s, page %d: the box is on screen (%s)" % [size, big, i, box])
				check(box.size.y <= Hud.DIALOGUE_MAX_H + 0.5, "and no taller than the cap (%.0f)" % box.size.y)
				var needed: float = w.hud._dialogue_text.get_line_count() * w.hud._dialogue_text.get_line_height()
				check(needed <= w.hud._dialogue_text.size.y + 1.0, "subtitles %d, large %s, page %d: every line of the page fits (%d lines)" % [size, big, i, w.hud._dialogue_text.get_line_count()])
				if i + 1 < w.hud._dialogue_lines.size():
					w.hud._dialogue_index += 1
					w.hud._show_dialogue_line()
			w.hud.close_dialogue()
	_cleanup()
	UiStyle.rescale_text(tree)


func test_a_scene_carries_one_take_across_its_pages_too() -> void:
	var w := await start_session()
	var id := Hud.voice_id("test.scene", LONG)
	VoiceOver.register(id, _clip(8.0))
	var done := [false]
	var run := func() -> void:
		await w.hud.cinematic("TEST", [LONG], Hud.SELF_COLOR, 0.5, "test.scene")
		done[0] = true
	run.call_deferred()
	await wait_until(func() -> bool: return w.hud._cine_pacer != null, 3.0, "the scene")
	var take := VoiceOver.current()
	check(take != null and take.playing, "the take starts on the first page")
	var first: String = w.hud._cine_text.text
	check(first != LONG and LONG.begins_with(first), "the scene shows the line in pages")
	await wait_until(func() -> bool: return w.hud._cine_pacer.phase != LinePacer.Phase.REVEALING, 10.0, "the first page typed")
	await frames(2)
	await press("interact", false)
	await wait_until(func() -> bool: return w.hud._cine_text.text != first, 3.0, "the next page")
	await frames(2)
	check(VoiceOver.current() == take and is_instance_valid(take) and take.playing, "the scene's next page keeps the same take playing")
	while not done[0]:
		await press("interact", false)
		await frames(3)
	_cleanup()

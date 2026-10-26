extends "res://tests/test_case.gd"

const LONG := "This is a deliberately long caption used to verify that a single continuous performance is not restarted when the player reads the next page. Each page must fit safely beside the face, keep the original line in history once, and let the audio finish before automatic progression leaves the final page. Nothing here is a real voice performance; this is a synthetic regression fixture for subtitle and playback ownership."

func _clip(seconds := 30.0) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.mix_rate = 8000
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	var bytes := PackedByteArray()
	bytes.resize(int(seconds * wav.mix_rate))
	bytes.fill(128)
	wav.data = bytes
	return wav

func test_recorded_caption_pages_share_one_player_and_one_source_event() -> void:
	var w := await start_session()
	VoiceOver.register(Hud.voice_id("test.pages", LONG), _clip())
	var count := [0]
	w.hud.line_revealed.connect(func(line: String) -> void:
		if line == LONG: count[0] += 1)
	w.hud.show_dialogue("MIRA", Color.WHITE, [LONG], "test.pages", CharacterArt.for_npc(w.area.mira))
	var player := VoiceOver.current()
	check(w.hud._dialogue_lines.size() > 1, "recordings do not bypass caption pagination")
	for i in range(1, w.hud._dialogue_lines.size()):
		w.hud._next_dialogue_line()
		check(VoiceOver.current() == player, "caption continuation never restarts/stops the recording")
	check_eq(count[0], 0, "the last page isn't revealed yet: no journal event")
	check_eq(w.hud.history.filter(func(e: Dictionary) -> bool: return e.text == LONG).size(), 1, "history keeps the full source once")
	w.hud._pacer.reveal(Engine.get_process_frames())
	w.hud._page_revealed()
	w.hud._page_revealed()
	check_eq(count[0], 1, "the original source emits one completion/journal event")
	w.hud._pacer.auto = true
	w.hud._pacer.read_left = 0.0
	w.hud._pacer.delay_left = 0.0
	w.hud._pacer.tick(1.0)
	check(not w.hud._pacer.is_done(), "the final page waits for the still-playing recording")
	w.hud.close_dialogue()
	check(VoiceOver.current() == null, "manual close stops the old performance")

func test_large_voiced_caption_pages_stay_inside_the_safe_canvas() -> void:
	var w := await start_session()
	settings().large_text = true
	settings().subtitle_size = 2
	w.hud.apply_subtitle_style()
	VoiceOver.register(Hud.voice_id("test.large.pages", LONG), _clip())
	w.hud.show_dialogue("MIRA", Color.WHITE, [LONG], "test.large.pages", CharacterArt.for_npc(w.area.mira))
	for i in w.hud._dialogue_lines.size():
		await frames(3)
		w.hud._fit_dialogue()
		check(w.hud._dialogue.position.y >= Hud.SAFE.y, "large subtitle page fits above the bottom safe margin")
		check(w.hud._dialogue.get_rect().end.y <= 360.0, "page remains on the logical canvas")
		if i + 1 < w.hud._dialogue_lines.size():
			w.hud._next_dialogue_line()
	w.hud.close_dialogue()

func test_cinematic_pages_keep_the_take_and_source_history() -> void:
	var w := await start_session()
	VoiceOver.register(Hud.voice_id("test.cine.pages", LONG), _clip())
	var done := [false]
	var play := func() -> void:
		await w.hud.cinematic("TEST", [LONG], Color.WHITE, 0.1, "test.cine.pages", CharacterArt.rue())
		done[0] = true
	play.call()
	await wait_until(func() -> bool: return VoiceOver.current() != null, 3.0, "the recording")
	var player := VoiceOver.current()
	var first_text: String = w.hud._cine_text.text
	w.hud._cine_pacer.phase = LinePacer.Phase.DONE
	await frames(3)
	check(w.hud._cine_text.text != first_text, "a subsequent caption page is shown")
	check(VoiceOver.current() == player, "cinematic page changes share the original player too")
	check_eq(w.hud.history.filter(func(e: Dictionary) -> bool: return e.text == LONG).size(), 1, "cinematic history logs the source once")
	await read_through_cinematic(w)
	check(done[0], "the scene can complete manually without waiting for the synthetic take")

func test_system_speech_rate_is_bounded_persisted_and_separate_from_captions() -> void:
	var base: float = Narration.speech_for("MIRA", 3).rate
	settings().speech_rate = 0
	check(is_equal_approx(Narration.speech_for("MIRA", 3).rate, base * 0.75), "speech can be slowed without changing reading/reveal speed")
	settings().speech_rate = 3
	check(is_equal_approx(Narration.speech_for("MIRA", 3).rate, base * 1.1), "speech speed has a conservative upper preference")
	settings().save()
	settings().speech_rate = 0
	settings()._load()
	check_eq(settings().speech_rate, 3, "the independent preference survives reload")
	check_eq(settings().text_speed, 1, "speech rate did not alter text reveal speed")

func test_long_unbroken_identifiers_still_have_bounded_caption_pages() -> void:
	var text := "asset_path_".repeat(50)
	var pages := StoryPacing.pages(text)
	check(pages.size() > 1, "resource identifiers cannot escape pagination")
	check_eq("".join(pages), text, "splitting a long identifier does not lose source characters")
	for page in pages:
		check(page.length() <= StoryPacing.PAGE_CHARS, "every identifier page is bounded")

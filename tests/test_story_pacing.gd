extends "res://tests/test_case.gd"
## Story pacing (docs/STORY_PACING.md): manual reveal then advance, auto
## timing that waits for reading AND voice, pause and focus, interruptions,
## missing recordings, the history, and quitting in the middle of a memory.

const LONG := "a second controller, the cable taped where the dog chewed it, two people on one couch."
const SHORT := "one save."


## A silent clip of `seconds` (headless audio still advances playback).
func _clip(seconds: float) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = 11025
	var data := PackedByteArray()
	data.resize(int(11025 * seconds) * 2)
	w.data = data
	return w


func _scene(hud: Hud, lines: Array, prefix: String, done: Array) -> void:
	await hud.cinematic("TEST", lines, Hud.SELF_COLOR, 0.5, prefix)
	done[0] = true


func _start(w: Node, lines: Array, prefix := "") -> Array:
	var done := [false]
	_scene.call_deferred(w.hud, lines, prefix, done)
	await wait_until(func() -> bool: return w.hud._cine_pacer != null, 3.0, "the scene to start")
	return done


func _line(w: Node) -> String:
	return w.hud._cine_text.text


# --- the rule itself ------------------------------------------------------------

func test_reading_allowance_follows_length_and_punctuation() -> void:
	check_eq(StoryPacing.reading_time("ok.", 1), StoryPacing.MIN_TIME, "a short line gets the minimum")
	check_eq(StoryPacing.reading_time("word ".repeat(200), 1), StoryPacing.MAX_TIME, "a very long line is capped")
	var plain := "two people on one couch one screen one save"
	var punctuated := "two people on one couch. one screen, one save."
	check(StoryPacing.reading_time(punctuated, 1) > StoryPacing.reading_time(plain, 1), "sentence ends and commas add time")
	# The documented formula, checked on a mid-length line.
	var expected := clampf(StoryPacing.BASE + StoryPacing.letters(LONG) / StoryPacing.CPS
		+ StoryPacing.SENTENCE * StoryPacing.sentence_ends(LONG) + StoryPacing.CLAUSE * StoryPacing.clause_marks(LONG),
		StoryPacing.MIN_TIME, StoryPacing.MAX_TIME)
	check(is_equal_approx(StoryPacing.reading_time(LONG, 1), expected), "the formula in docs/STORY_PACING.md")
	check_eq(StoryPacing.letters("> who is in my save?"), 14, "the owner's prompt and spaces aren't read")
	check_eq(StoryPacing.sentence_ends("wait... no. go!"), 3, "an ellipsis is one sentence end")
	check(StoryPacing.reading_time(LONG, 0) > StoryPacing.reading_time(LONG, 1) and StoryPacing.reading_time(LONG, 1) > StoryPacing.reading_time(LONG, 2), "slow > normal > fast")


func test_one_press_never_reveals_and_advances() -> void:
	var p := LinePacer.new(LONG, false)
	check_eq(p.press(10), "reveal", "first press reveals")
	check_eq(p.press(10), "", "the same frame can't also advance")
	check(p.is_shown(), "still on the line")
	check_eq(p.press(11), "advance", "a later press advances")
	var typed := LinePacer.new(LONG, false)
	typed.reveal(20)  # the typewriter finished on frame 20...
	check_eq(typed.press(20), "", "...so a press on that frame only lands as the reveal")


# --- manual (the default) ------------------------------------------------------

func test_manual_first_press_reveals_second_advances() -> void:
	var w := await start_session()
	var done := await _start(w, [LONG, SHORT])
	await frames(3)
	check(w.hud._cine_text.visible_characters != -1, "the line is still typing")
	await press("interact")
	check_eq(w.hud._cine_text.visible_characters, -1, "first press: the whole line")
	check_eq(_line(w), LONG, "and nothing more")
	# The old rule moved on after 2.4 s + 0.045 s per letter (6.3 s here).
	await wait(7.0)
	check_eq(_line(w), LONG, "manual lines never leave by themselves")
	check(w.hud._cine_hint.text.contains("▼"), "a continue marker shows once the line is complete")
	await press("interact")
	await frames(2)
	check_eq(_line(w), SHORT, "second press: the next line")
	await press("interact")
	await press("interact")
	await wait_until(func() -> bool: return done[0], 3.0, "the scene to end")


func test_mashing_reads_every_line_in_turn() -> void:
	var w := await start_session()
	var lines := [LONG, LONG + " two", LONG + " three"]
	var before: int = w.hud.history.size()
	var done := await _start(w, lines)
	for i in 4:
		await press("interact", false)
	await frames(2)
	check_eq(_line(w), lines[2], "4 rapid presses = reveal and advance twice: on the third line")
	check_eq(w.hud.history.size() - before, 3, "each line was shown (and logged) once, none skipped unseen")
	for i in 4:
		await press("interact", false)
	await wait_until(func() -> bool: return done[0], 3.0, "the scene to end")


# --- auto ------------------------------------------------------------------------

func test_auto_waits_for_the_voice_then_the_delay() -> void:
	settings().advance_mode = 1
	settings().text_speed = 3  # instant: the allowance starts at once
	VoiceOver.register(Hud.voice_id("test.auto", SHORT), _clip(3.0))
	var w := await start_session()
	var done := await _start(w, [SHORT, LONG], "test.auto")
	check(VoiceOver.is_playing(), "the recorded line plays")
	check(Sfx._duck_target < 0.0, "music ducks under recorded speech")
	await wait(2.4)  # reading allowance (1.6 s) is over; the voice isn't
	check_eq(_line(w), SHORT, "auto waits for the voice to finish")
	await wait(2.0)  # voice ends at ~3.0 s, then the 0.5 s delay
	check_eq(_line(w), LONG, "then moves on after the voice and the delay")
	check_eq(Sfx._duck_target, 0.0, "music comes back after the line")
	await wait_until(func() -> bool: return done[0], StoryPacing.MAX_TIME + 3.0, "auto to finish the scene")


func test_auto_allowance_starts_when_the_line_is_complete() -> void:
	settings().advance_mode = 1
	settings().text_speed = 0  # slow typing: ~3.5 s for LONG
	var w := await start_session()
	var done := await _start(w, [LONG, SHORT])
	await wait(1.0)
	var pacer: LinePacer = w.hud._cine_pacer
	check(pacer.phase == LinePacer.Phase.REVEALING, "still typing after 1 s")
	check(is_equal_approx(pacer.read_left, StoryPacing.reading_time(LONG)), "no reading time used up while typing")
	await wait_until(func() -> bool: return pacer.is_shown(), 6.0, "the line to complete")
	await wait(StoryPacing.reading_time(LONG) - 0.6)
	check_eq(_line(w), LONG, "the whole allowance is given after the reveal")
	await wait_until(func() -> bool: return _line(w) == SHORT, 3.0, "auto to move on")
	await wait_until(func() -> bool: return done[0], 8.0, "the scene to end")


# --- pause, focus, interruption ------------------------------------------------

func test_pausing_freezes_reading_time_and_voice() -> void:
	settings().advance_mode = 1
	settings().text_speed = 3
	VoiceOver.register(Hud.voice_id("test.pause", LONG), _clip(2.0))
	var w := await start_session()
	var done := await _start(w, [LONG, SHORT], "test.pause")
	await wait(0.5)
	var pacer: LinePacer = w.hud._cine_pacer
	var left := pacer.read_left
	var pos := VoiceOver.current().get_playback_position()
	w.open_pause()
	await wait(2.5)
	check(is_equal_approx(pacer.read_left, left), "paused: no reading time passes")
	check_eq(_line(w), LONG, "paused: the line stays")
	check(VoiceOver.current() != null, "paused: the voice is held, not finished")
	check(absf(VoiceOver.current().get_playback_position() - pos) < 0.1, "paused: the voice doesn't play on")
	w._pause_menu.close()
	await wait(0.5)
	check(pacer.read_left < left, "unpaused: reading resumes")
	await wait_until(func() -> bool: return done[0], StoryPacing.MAX_TIME + 4.0, "the scene to end")


func test_losing_focus_pauses_and_returning_resumes() -> void:
	var w := await start_session()
	w.focus_lost()
	check(tree.paused, "losing focus pauses the game")
	check(w._pause_menu.visible, "with the pause menu up, to resume when ready")
	w._pause_menu.close()
	w.ending = "win"  # an epilogue: no menu, just hold it
	w.focus_lost()
	check(tree.paused, "an ending holds while unfocused")
	w.focus_returned()
	check(not tree.paused, "and resumes by itself when focus returns")
	w.ending = ""
	settings().pause_on_focus_loss = false
	w.focus_lost()
	check(not tree.paused, "the setting can turn it off")


func test_leaving_the_scene_stops_its_voice() -> void:
	VoiceOver.register(Hud.voice_id("test.leave", LONG), _clip(6.0))
	var w := await start_session()
	await _start(w, [LONG], "test.leave")
	check(VoiceOver.is_playing(), "the line is speaking")
	tree.change_scene_to_file("res://scenes/title.tscn")
	await wait(0.5)
	check(VoiceOver.current() == null, "the voice ends with its scene")
	check_eq(Sfx._duck_target, 0.0, "and the music comes back")


func test_missing_recordings_fall_back_to_text() -> void:
	var w := await start_session()
	var done := await _start(w, [SHORT, LONG], "test.never_recorded")
	check(not VoiceOver.is_playing(), "nothing to play")
	check_eq(_line(w), SHORT, "the text is there")
	check(await read_through_cinematic(w), "and the scene can be read through")
	check(done[0], "progression isn't blocked")
	var last: Dictionary = w.hud.history[-1]
	check_eq(last.voice, "", "the history offers no replay for an unrecorded line")


# --- history, queueing ---------------------------------------------------------

func test_history_keeps_every_route_with_speakers() -> void:
	VoiceOver.register(Hud.voice_id("test.mira", "Welcome home!"), _clip(0.5))
	var w := await start_session()
	w.hud.clear_queue()
	w.hud.show_dialogue("MIRA", Hud.NPC_COLOR, ["Welcome home!", "Don't forget to save!"], "test.mira")
	await frames(2)
	w.hud.say("a thought said while she talks.", "self")
	await wait(1.0)
	check(not w.hud.history.any(func(e: Dictionary) -> bool: return e.text == "a thought said while she talks."), "the console holds its line while dialogue is up")
	await finish_dialogue(w)
	# (After the line already on screen has had its reading time: the run's
	# opening note can still be typing when this test starts.)
	await wait_until(func() -> bool: return w.hud.history.any(func(e: Dictionary) -> bool: return e.text == "a thought said while she talks."), 12.0, "the held line")
	var done := await _start(w, ["> who is in my save?"])
	await read_through_cinematic(w)
	var text := PauseMenu.history_text(w.hud.history)
	check(text.contains("MIRA  Welcome home!"), "dialogue, with its speaker")
	check(text.contains("RUE  (a thought said while she talks.)"), "the console, with its speaker")
	check(text.contains("OWNER  > who is in my save?"), "cinematic owner lines, with the owner")
	w._pause_menu.open()
	w._pause_menu._show_history()
	await frames(2)
	check(w._pause_menu._replay_row.visible, "a recorded line can be replayed")
	w._pause_menu.close()
	settings().speaker_labels = false
	check(not PauseMenu.history_text(w.hud.history).contains("MIRA  "), "speaker labels can be turned off")


func test_console_lines_stay_long_enough_to_read() -> void:
	var w := await start_session()
	w.hud.clear_queue()
	w.hud._typing = null
	w.hud._pause = 0.0
	settings().text_speed = 3
	w.hud.say(LONG, "self")
	w.hud.say(SHORT, "self")
	await wait(0.6)  # the old pause was 0.5 s
	check(not w.hud.history.any(func(e: Dictionary) -> bool: return e.text == SHORT), "the next line waits while the first is read")
	check(w.hud._pause > 1.0, "reading time: %s" % w.hud._pause)
	var newest := w.hud._console.get_child(w.hud._console.get_child_count() - 1) as Label
	check(newest.autowrap_mode != TextServer.AUTOWRAP_OFF, "long lines wrap instead of being cut off")
	check_eq(StoryPacing.ambient_time(LONG, StoryPacing.BACKLOG), StoryPacing.MIN_TIME, "a backlog moves at the minimum pace")


# --- consequences, skipping, the representative character ----------------------

func _touch_first_memory(w: Node) -> MemoryFragment:
	for c in w.area.get_children():
		if c is MemoryFragment:
			w.player.global_position = c.global_position
			await wait_until(func() -> bool: return w.hud.is_cinematic(), 3.0, "the memory")
			return c
	failures.append("no memory in Arin's room")
	return null


func test_quitting_mid_memory_keeps_the_story_coherent() -> void:
	var w := await start_session()
	await _touch_first_memory(w)
	tree.change_scene_to_file("res://scenes/title.tscn")
	await wait(0.6)
	check(not memory().has_fragment("controller"), "an unfinished memory isn't counted")
	check(memory().journal.is_empty(), "nor kept in the journal")
	w = await start_session()
	await _touch_first_memory(w)
	check(await read_through_cinematic(w), "next run, the memory is still there to live through")
	await wait_until(func() -> bool: return not w._cutscene, 3.0, "the memory to end")
	check(memory().has_fragment("controller"), "now it counts")
	check_eq(memory().journal.size(), 1, "and is kept once")


func test_holding_skips_a_scene_but_not_its_consequences() -> void:
	var w := await start_session()
	await _touch_first_memory(w)
	await wait(0.2)
	await hold("interact", StoryPacing.SKIP_HOLD + 0.4)
	await wait_until(func() -> bool: return not w._cutscene, 3.0, "the skipped memory to end")
	check(not w.hud.is_cinematic(), "a deliberate hold skips the rest")
	check(memory().has_fragment("controller"), "the memory still counts")
	var f := Story.fragment("controller")
	for line in f.lines:
		check(w.hud.history.any(func(e: Dictionary) -> bool: return e.text == line), "skipped lines are still in the history")


func test_a_tap_never_skips() -> void:
	var w := await start_session()
	var done := await _start(w, [LONG, SHORT])
	await hold("interact", 0.3)
	await wait(0.5)
	check(not done[0] and w.hud.is_cinematic(), "a short press is a press, not a skip")
	await read_through_cinematic(w)


func test_rue_portrait_matches_her_sprite() -> void:
	var w := await start_session()
	await _touch_first_memory(w)
	check(w.hud._cine_portrait.visible and w.hud._cine_portrait.portrait.who == "rue", "the memory shows Rue")
	check_eq(w.hud._cine_portrait.portrait.palette, w.player.palette(), "as she looks right now (still missing her face)")
	var missing := CharacterArt.image(CharacterArt.rue("neutral", w.player.palette()))
	var restored := CharacterArt.image(CharacterArt.rue("neutral"))
	check(missing.get_pixel(15, 17).get_luminance() < 0.1, "no memories yet: her face is still missing, as on her sprite")
	check(restored.get_pixel(15, 17).is_equal_approx(Player.RUE["s"]), "restored: her own skin tone")
	check(missing.get_pixel(12, 6).is_equal_approx(Player.MISSING["h"]), "portrait hair uses the sprite's hair key")
	for e in CharacterArt.EXPRESSIONS:
		check(CharacterArt.FACES.has(e), "expression %s is drawn" % e)
	await read_through_cinematic(w)


func test_subtitle_settings_apply_and_persist() -> void:
	var w := await start_session()
	settings().set_value("subtitle_size", 2)
	check_eq(w.hud._cine_text.get_theme_font_size("font_size"), roundi(12 * 1.4), "larger subtitles")
	settings().set_value("subtitle_bg", 0.3)
	check(is_equal_approx(w.hud._dialogue_box_style.bg_color.a, 0.3), "backing opacity")
	settings().set_value("advance_mode", 1)
	settings().set_value("voice_delay", 3)
	settings()._load()
	check_eq(settings().subtitle_size, 2, "subtitle size persists")
	check_eq(settings().advance_mode, 1, "advance mode persists")
	check_eq(settings().voice_delay, 3, "voice delay persists")
	settings().set_value("subtitle_size", 0)
	settings().set_value("subtitle_bg", 0.75)
	settings().set_value("advance_mode", 0)
	settings().set_value("voice_delay", 1)


func test_owner_warnings_go_ahead_of_thoughts() -> void:
	var w := await start_session()
	w.hud.clear_queue()
	w.hud._typing = null
	w.hud._pause = 0.0
	settings().text_speed = 3
	w.hud.say(LONG, "self")
	await wait_until(func() -> bool: return w.hud.history.any(func(e: Dictionary) -> bool: return e.text == LONG), 2.0, "the first line")
	w.hud.say("a second thought.", "self")
	w.hud.say("do that again and i'm loading the autosave.", "owner")
	check_eq(w.hud._queue[0].kind, "owner", "the warning goes ahead of the waiting thought")
	await wait(StoryPacing.OWNER_GAP + 0.4)
	check(w.hud.history.any(func(e: Dictionary) -> bool: return e.kind == "owner" and e.text.begins_with("do that again")), "the warning is on screen within %.1f s" % (StoryPacing.OWNER_GAP + 0.4))
	check(not w.hud.history.any(func(e: Dictionary) -> bool: return e.text == "a second thought."), "the thought waits its turn")


func test_the_goal_shows_when_it_changes() -> void:
	var w := await start_session()
	await wait(0.3)
	check(w.hud.objective_text().contains("Get out of Arin's room."), "the first goal is on screen without opening a menu")
	await wait(StoryPacing.reading_time("Get out of Arin's room.") + 5.0)
	check_eq(w.hud.objective_text(), "", "and fades once read")
	await go_to(w, "square", "house")
	await wait(0.6)
	check(w.hud.objective_text().contains("Explore the village"), "a new area brings its goal back")


# --- review fixes ------------------------------------------------------------------

func test_a_scene_over_a_conversation_holds_it_without_ending_it() -> void:
	var w := await start_session()
	var closed := [0]
	w.hud.dialogue_closed.connect(func() -> void: closed[0] += 1)
	w.hud.show_dialogue("MIRA", Hud.NPC_COLOR, ["first line.", "second line."])
	await frames(2)
	var done := await _start(w, [SHORT])
	check(not w.hud.is_dialogue_open(), "the dialogue box is hidden under the scene")
	check_eq(closed[0], 0, "and the conversation is not ended (no dialogue_closed side effects)")
	await read_through_cinematic(w)
	check(done[0], "the scene finishes")
	check(w.hud.is_dialogue_open(), "the conversation comes back where it was")
	check_eq(w.hud._dialogue_text.text, "first line.", "on the same line")
	await finish_dialogue(w)


func test_a_big_jump_still_says_a_warning() -> void:
	var w := await start_session()
	w.hud.clear_queue()
	w.director.awareness = OwnerDirector.CONTAIN - 2.0
	w.director._fired.clear()
	for t in OwnerDirector.THRESHOLDS:
		if t < OwnerDirector.CONTAIN:
			w.director._fired[t] = true
	w.director.add_awareness(OwnerDirector.SILENCE + 2.0 - w.director.awareness)
	var owner_lines: Array = w.hud._queue.filter(func(m: Dictionary) -> bool: return m.kind == "owner")
	check(owner_lines.any(func(m: Dictionary) -> bool: return m.text == "stay where i can see you."), "crossing CONTAIN and SILENCE at once still warns (SILENCE has no line)")


func test_replaying_history_keeps_the_paused_story_voice() -> void:
	VoiceOver.register(Hud.voice_id("test.keep", LONG), _clip(4.0))
	VoiceOver.register("test.old", _clip(1.0))
	var w := await start_session()
	await _start(w, [LONG], "test.keep")
	var story := VoiceOver.current()
	w.open_pause()
	VoiceOver.preview(w._pause_menu, "test.old")
	await wait(0.2)
	check(VoiceOver.current() == story and is_instance_valid(story), "the story line keeps its place while a replay plays")
	w._pause_menu.close()
	await read_through_cinematic(w)

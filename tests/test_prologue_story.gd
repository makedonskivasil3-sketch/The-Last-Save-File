extends "res://tests/test_case.gd"


func _festival(replay := false) -> Prologue:
	var p := Prologue.new()
	p.replay = replay
	tree.root.add_child(p)
	var old := tree.current_scene
	tree.current_scene = p
	if old:
		old.queue_free()
	await frames(2)
	return p


func _step(p: Prologue, seconds: float) -> void:
	for i in int(seconds / 0.05):
		if p._done:
			return
		p._process(0.05)


func _close(p: Prologue) -> void:
	p._done = true
	p._handed_off = true
	p.queue_free()
	await frames(2)


func test_reading_holds_the_scene_and_never_arms_a_session() -> void:
	var p := await _festival()
	p._light(0)
	check(p.story.visible, "the first shared achievement opens their conversation")
	var time := p.beat_t
	var place := p.rue_pos
	_step(p, 45.0)
	check(p.story.visible and p.story.page == 0, "the page survives an arbitrarily slow reader")
	check_eq(p.beat_t, time, "no decision or assistance clock runs while reading")
	check_eq(p.rue_pos, place, "no one moves Rue while the text owns attention")
	check(memory().journal.is_empty(), "merely displaying a line does not record reading")
	check(not memory().session_armed(), "no punitive session exists before the handoff")
	await _close(p)


func test_the_triggering_hold_cannot_read_the_next_page() -> void:
	var p := await _festival()
	Input.action_press("interact")
	p._light(0)
	_step(p, 3.0)
	check_eq(p.story.page, 0, "the lighting press is not also Continue")
	Input.action_release("interact")
	_step(p, 0.3)
	p.story.advance()
	check_eq(p.story.page, 1, "a deliberate continuation advances one page")
	p.story.advance()
	check_eq(p.story.page, 1, "the next page has its own release and debounce")
	check_eq(memory().journal.size(), 1, "one acknowledged page was kept")
	check_eq(memory().journal[0].lines.size(), 1, "not the unread reply")
	await _close(p)


func test_skipping_a_story_cancels_it_without_claiming_it_read() -> void:
	var p := await _festival()
	p._light(0)
	_step(p, 0.3)
	Input.action_press("ui_cancel")
	_step(p, Prologue.SKIP_HOLD + 0.2)
	Input.action_release("ui_cancel")
	check(not p.story.visible, "skip dismissed the panel")
	check_eq(p.beat, Prologue.Beat.LOAD, "skip still goes directly to the present")
	check(memory().journal.is_empty(), "no unread speech was filed as read")
	_step(p, Prologue.LOAD_TIME + 0.5)
	check(p._done, "skip never acquires another manual hold")
	await _close(p)


func test_a_replay_cannot_write_story_into_a_profile() -> void:
	var p := await _festival(true)
	p._light(0)
	_step(p, 0.3)
	p.story.advance()
	_step(p, 0.3)
	p.story.advance()
	check(memory().journal.is_empty(), "replaying the opening changes no collection")
	await _close(p)


func test_completed_speech_is_available_in_the_archive_and_save() -> void:
	var p := await _festival()
	p._light(0)
	_step(p, 0.3)
	p.story.advance()
	_step(p, 0.3)
	p.story.advance()
	check(not p.story.visible, "two acknowledged pages close the break")
	memory().load_memory()
	var entries := ArchivePages.documents()
	check_eq(entries.size(), 1, "the conversation survives reopening the profile")
	if not entries.is_empty():
		check(entries[0].body.contains("You always check whether I will."), "the reply is readable again")
		check(entries[0].body.contains("beside the television"), "outside speakers cannot be mistaken for Rue or Arin")
	await _close(p)


func test_present_day_revelation_waits_for_the_reader() -> void:
	var p := await _festival()
	p._to_beat(Prologue.Beat.LOAD)
	_step(p, 3.3)
	check(p.story.visible and p.story.story_id == "owner", "the Owner's words are a readable scene")
	_step(p, 30.0)
	check(not p._done, "three seconds cannot erase the story")
	p.story.advance()
	_step(p, 0.3)
	p.story.advance()
	_step(p, Prologue.LOAD_TIME + 0.5)
	check(p._done, "acknowledging the revelation returns to gameplay")
	await _close(p)


func test_focus_loss_stops_automatic_reading_allowance() -> void:
	var p := await _festival()
	settings().advance_mode = 1
	p._light(0)
	p._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_step(p, 30.0)
	check_eq(p.story.page, 0, "auto mode never consumes pages in another window")
	p._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_step(p, 0.3)
	check_eq(p.story.page, 0, "focus return did not inherit the absence as reading time")
	_step(p, StoryPacing.reading_time("You always let me do the first one.") + 0.2)
	check_eq(p.story.page, 1, "auto mode respects the shared reading allowance")
	await _close(p)


func test_large_text_reflows_and_touch_is_suspended() -> void:
	settings().large_text = true
	var p := await _festival()
	p._touch._touch_down(42, TouchControls.BUTTONS.interact.center)
	p._touch._touch_down(43, Vector2(70, 240))
	p._light(0)
	await frames(4)
	check(p._touch._held.is_empty() and p._touch._stick_finger == -1, "opening a reader cancels held virtual controls")
	check(not p._touch.buttons_enabled, "touch gameplay cannot consume the reader's taps")
	check(p.story.get_rect().end.y <= 360.0, "the largest text fits in the viewport (%s)" % str(p.story.get_rect()))
	check(p.story._body.size.y >= p.story._body.get_minimum_size().y, "no caption line is clipped")
	await _close(p)


func test_reduce_flashing_is_independent_of_reduce_motion() -> void:
	settings().reduce_motion = false
	settings().reduce_flashing = true
	check(not Prologue.load_flicker(), "moving camera does not override reduced flashing")
	settings().reduce_flashing = false
	settings().glitch_intensity = 0.0
	check(not Prologue.load_flicker(), "zero glitch intensity removes the load tear")


func test_the_final_story_break_can_also_be_skipped() -> void:
	var p := await _festival()
	p._to_beat(Prologue.Beat.LOAD)
	_step(p, 3.3)
	check(p.story.visible, "reading the Owner's first words")
	Input.action_press("ui_cancel")
	_step(p, Prologue.SKIP_HOLD + 0.2)
	Input.action_release("ui_cancel")
	check(not p.story.visible and p.acted.has("skipped"), "Esc works even in the final reading hold")
	_step(p, Prologue.LOAD_TIME + 0.5)
	check(p._done, "the final scene cannot trap a player who skips")
	await _close(p)

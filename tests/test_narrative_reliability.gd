extends "res://tests/test_case.gd"
## Narrative reliability and safety (docs/NARRATIVE_RELIABILITY.md): urgent
## warnings reach the screen in time whatever else is being read, long text
## gets the time it needs, a death waits for the player, reading never kills,
## voice ids exist for every spoken route and the manifest is the same
## whatever the local save holds.
##
## Each of these began as a probe that failed on the code it describes.

## A long thought (about 150 characters, like the longest authored lines).
const THOUGHT := "the guestbook remembers every name the owner ever typed into it, and somewhere under the coffee stain is the name of the second player, still waiting."


## The text is on screen, fully revealed, in a visible label.
func _on_screen(w: Node, needle: String) -> bool:
	var stack: Array[Node] = [w.hud]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is Label and n.is_visible_in_tree() and n.text.contains(needle):
			var l := n as Label
			if l.visible_characters == -1 or l.visible_characters >= l.text.length():
				if l.modulate.a > 0.5 and l.self_modulate.a > 0.5:
					return true
	return false


# --- urgent warnings ---------------------------------------------------------------

func test_a_warning_is_readable_at_once_behind_slow_typing() -> void:
	settings().text_speed = 0  # Slow: the console types at 0.6×
	var w := await start_session()
	w.hud.say(THOUGHT, "self")
	await wait(0.3)  # the thought is now half typed
	w.owner_moves.start_save_over()
	check(w.owner_moves.save_progress >= 0.0, "the save-over started")
	# SAVE_TIME is 4 s standing still: the warning must be readable well inside it.
	var ok := await wait_until(func() -> bool: return _on_screen(w, "sav"), 1.0, "the save-over warning on screen")
	check(ok, "the warning was readable within 1 s, not after the thought finished typing")
	await wait(0.2)
	check(w.hud.history.any(func(e: Dictionary) -> bool: return e.text.contains("sav") and e.kind == "owner"), "and it is in the History once")


func test_a_warning_is_not_lost_in_a_backlog() -> void:
	settings().text_speed = 0
	var w := await start_session()
	for i in 6:
		w.hud.say("system line %d" % i, "system")
	w.hud.say(THOUGHT, "self")
	w.owner_moves.start_save_over()
	check(await wait_until(func() -> bool: return _on_screen(w, "sav"), 1.0, "the warning ahead of the backlog"), "a backlog doesn't delay a warning")


# --- reading time ------------------------------------------------------------------

func test_long_lines_get_the_time_they_need_on_slow() -> void:
	# At every reading speed, a fully shown line gets at least the time its
	# letters take at that speed. A flat cap cut long lines short on Slow.
	for speed in StoryPacing.READ_SPEEDS.size():
		for text in [THOUGHT, THOUGHT + " " + THOUGHT]:
			var need: float = (StoryPacing.BASE + StoryPacing.letters(text) / StoryPacing.CPS) / StoryPacing.READ_SPEEDS[speed]
			check(StoryPacing.reading_time(text, speed) >= need, "%d letters at speed %d: %.1f s given, %.1f s needed" % [StoryPacing.letters(text), speed, StoryPacing.reading_time(text, speed), need])


func test_a_very_long_line_is_shown_in_pages() -> void:
	var long := THOUGHT + " " + THOUGHT + " " + THOUGHT
	var sp: Variant = load("res://scripts/ui/story_pacing.gd")
	check(sp.has_method("pages"), "StoryPacing.pages exists")
	if not sp.has_method("pages"):
		return
	var pages: Array = sp.pages(long)
	check(pages.size() > 1, "a line too long for one box is split")
	check_eq(" ".join(pages), long, "and nothing is lost or reordered")
	for p in pages:
		check(p.length() <= sp.PAGE_CHARS, "each page fits (%d chars)" % p.length())
	check_eq(sp.pages(THOUGHT), [THOUGHT], "an authored line fits on one page")


# --- death -------------------------------------------------------------------------

func test_death_advice_waits_for_the_player() -> void:
	var w := await start_session()
	w.kill("erased", "arin")
	await wait_until(func() -> bool: return w.hud.death_tip_text() != "" or w.hud._overlay.visible, 3.0, "the death card")
	await wait(5.0)  # the old card restarted after 2.8–3.6 s, read or not
	if not (is_instance_valid(w) and scene() == w):
		check(false, "the death card stays until the player is ready")
		return
	check(_on_screen(w, "retry"), "it says how to continue")
	var next := await wait_for_new_session(w)  # presses retry, like a player
	check(next != null and next != w, "a press retries")


func test_a_mashed_press_does_not_skip_the_death_card() -> void:
	var w := await start_session()
	w.kill("erased", "arin")
	await wait_until(func() -> bool: return w.hud._overlay.visible, 3.0, "the death card")
	for i in 3:
		await press("interact", false)
	await frames(3)
	check(is_instance_valid(w) and scene() == w, "presses in the first moment are ignored (the card is read)")


# --- reading is safe ---------------------------------------------------------------

func test_reading_a_conversation_holds_the_owner() -> void:
	var w := await start_session()
	await interact_with(w, w.area.mira)
	check(w.hud.is_dialogue_open(), "talking to Mira")
	# The hunt begins while you read.
	w.director.add_awareness(OwnerDirector.HUNT + 1.0 - w.director.awareness)
	var aw: float = w.director.awareness
	w.owner_moves.start_save_over()
	check_eq(w.owner_moves.save_progress, -1.0, "no save-over starts under a conversation")
	await wait(OwnerMoves.SAVE_TIME + 1.0)
	check_eq(w.ending, "", "nobody dies while reading")
	check(w.director.awareness <= aw + 0.01, "awareness doesn't climb while reading (%.1f → %.1f)" % [aw, w.director.awareness])
	await finish_dialogue(w)
	await wait(0.5)
	check(not w.is_owner_paused(), "closing the conversation lets the owner go again")


func test_a_save_in_progress_holds_while_you_read_and_resumes_after() -> void:
	var w := await start_session()
	w.director.add_awareness(OwnerDirector.HUNT + 1.0 - w.director.awareness)
	w.owner_moves.start_save_over()
	w.owner_moves.save_progress = 0.6
	# (At HUNT Mira has been deleted: any conversation will do.)
	w.hud.show_dialogue("TOBBEN", Color.WHITE, [THOUGHT], "npc.tobben")
	await frames(2)
	check(w.hud.is_dialogue_open(), "a conversation is open")
	await wait(OwnerMoves.SAVE_TIME)
	check_eq(w.ending, "", "the ring doesn't fill under the conversation")
	check(w.owner_moves.save_progress >= 0.0 and w.owner_moves.save_progress < 0.7, "it holds where it was (%.2f)" % w.owner_moves.save_progress)
	await finish_dialogue(w)
	await wait(0.5)
	check(w.owner_moves.save_progress > 0.6, "and fills again, visibly, once the box closes")


# --- voice ids for every spoken route ---------------------------------------------

func test_ordinary_dialogue_asks_for_a_voice_line() -> void:
	var w := await start_session()
	await interact_with(w, w.area.mira)
	check(w.hud.is_dialogue_open(), "talking to Mira")
	var id: String = w.hud._dialogue_voice
	check(id != "", "Mira's line has a voice id")
	check(id.begins_with("npc.mira."), "named for the speaker (%s)" % id)
	var ids := {}
	for r in VoiceManifest.rows():
		ids[r.id] = true
	check(ids.has(id), "and it is in the manifest (%s)" % id)
	await finish_dialogue(w)


# --- the manifest ------------------------------------------------------------------

func test_the_manifest_does_not_depend_on_the_save() -> void:
	var clean := VoiceManifest.to_csv(VoiceManifest.rows())
	var m := memory()
	m.wren_saved = true
	m.npc_fates["wren"] = "saved"
	m.mira_quest = "pinned"
	m.guestbook_restored = true
	m.found_controller = true
	var played := VoiceManifest.to_csv(VoiceManifest.rows())
	check(played == clean, "the same manifest from a clean save and a played one")
	check(m.wren_saved and m.mira_quest == "pinned" and m.npc_fates.get("wren") == "saved", "and generating it leaves the save as it was")


# --- memories are kept in one save ---------------------------------------------------

func test_a_memory_is_kept_in_one_write() -> void:
	var m := memory()
	check("save_count" in m and m.has_method("keep_memory"), "OwnerMemory.keep_memory exists")
	if not m.has_method("keep_memory"):
		return
	var before: int = m.save_count
	var f := Story.fragment("controller")
	m.keep_memory(f.id, f.title, "Arin's room", f.lines)
	check_eq(m.save_count - before, 1, "the fragment and its journal page are one save")
	check(f.id in m.fragments, "the fragment is kept")
	check(m.journal.any(func(e: Dictionary) -> bool: return e.id == "memory:" + f.id), "and its page")

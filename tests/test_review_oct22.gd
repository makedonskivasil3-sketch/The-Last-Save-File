extends "res://tests/test_case.gd"
## The 22 October review's confirmed defects (docs/REVIEW_OCT22.md), each
## driven the way it happens in play. Each failed before its fix.


func _wren_entry() -> String:
	for e: Dictionary in ArchivePages.section("people"):
		if e.key == "person:wren":
			return str(e.body)
	return ""


func _square() -> Node:
	var w := await start_session()
	await go_to(w, "square", "house")
	return w


# --- A. The journal says only what Rue saw ----------------------------------------

func test_standing_by_wren_with_arin_far_away_witnesses_nothing() -> void:
	var w := await _square()
	await interact_with(w, w.area.wren)
	await finish_dialogue(w)
	w.area.arin.global_position = w.area.wren.global_position + Vector2(700, -100)  # far off, across the square
	w.player.global_position = w.area.wren.global_position + Vector2(8, 0)
	await wait(1.0)
	check(Relationships.has("wren.sheltered"), "hiding beside her is recorded (it happened)")
	check(not Relationships.has("wren.concealed"), "but Arin never looked: no concealment")
	var body := _wren_entry()
	check(not body.contains("Arin looked straight past you"), "the journal doesn't claim Arin looked (%s)" % body)
	check(body.contains("You stood beside her"), "it says what did happen")


func test_a_look_turned_aside_by_wren_is_remembered() -> void:
	var w := await _square()
	await interact_with(w, w.area.wren)
	await finish_dialogue(w)
	var spot: Vector2 = w.area.wren.global_position + Vector2(8, 0)
	w.player.global_position = spot
	var arin: OwnerAvatar = w.area.arin
	arin.global_position = spot + Vector2(40, 0)
	arin.route = [spot + Vector2(40, 0), spot + Vector2(40, 1)] as Array[Vector2]
	arin._facing = Vector2.LEFT
	check(not arin.can_see(spot), "Arin looks right at her and doesn't see her")
	check(Relationships.has("wren.concealed"), "that look is what's remembered")
	check(_wren_entry().contains("Arin looked straight past you"), "and the journal can say so")


func test_old_saves_keep_their_shelter_event() -> void:
	memory().event_at("wren.met", 1)
	memory().event_at("wren.sheltered", 1)
	memory().save_memory()
	memory().load_memory()
	check(Relationships.has("wren.sheltered"), "kept")
	check(not Relationships.has("wren.concealed"), "and not upgraded into something nobody saw")


# --- B. The lamp turns to the gate as it opens ------------------------------------

func test_the_lamp_turns_to_the_gate_when_it_opens_not_later() -> void:
	var w := await _square()
	var lamp: OwnerLamp = w.area.lamp
	var before := lamp.arc_from
	w.player.global_position = Vector2(757, 84)  # the lane side
	w.area.gate.interact()
	await wait(2.0)
	check(lamp.arc_from < before - 0.3, "watched turning onto the gate (%.2f -> %.2f)" % [before, lamp.arc_from])
	check(is_equal_approx(lamp.arc_from, VillageSquare.LAMP_GATE_ARC), "to the same place a later visit finds it")
	await go_to(w, "archive", "west")
	await go_to(w, "square", "east")
	check(is_equal_approx(w.area.lamp.arc_from, VillageSquare.LAMP_GATE_ARC), "same rule on the way back")
	memory().load_memory()
	check(memory().square_gate_open, "and in the save")


# --- C. Out of Bounds warns without flashing --------------------------------------

func test_floor_warnings_hold_still_with_reduce_flashing() -> void:
	settings().reduce_flashing = true
	var src := FileAccess.get_file_as_string("res://scripts/world/areas/out_of_bounds.gd")
	check(not src.contains("fmod(_t, 0.16)"), "no fast blink left in the floor")
	# The timer bar follows the same clock as the floor itself.
	for t in [0.0, 1.0, 1.7, 2.1, 2.5, 3.0]:
		var left := OutOfBounds.chunk_time_left(0.0, t)
		check((left > 0.0) == OutOfBounds.chunk_present(0.0, t), "timer and floor agree at %.1f s" % t)
	check(OutOfBounds.chunk_time_until(0.0, 2.5) > 0.0 and OutOfBounds.chunk_time_until(0.0, 1.0) == 0.0, "a missing chunk counts down to coming back")


# --- Bin: one shelter, drawn where it is ------------------------------------------

func test_the_bins_glow_is_exactly_its_shelter() -> void:
	for f: Rect2 in RecycleBin.SYSTEM_FILES:
		var r := RecycleBin.shelter_rect(f)
		check(RecycleBin.sheltered_at(r.get_center()), "inside the drawn shadow is safe")
		check(not RecycleBin.sheltered_at(r.end + Vector2(2, 2)), "just outside it isn't")
	var src := FileAccess.get_file_as_string("res://scripts/world/areas/recycle_bin.gd")
	check(src.count("grow_individual(0, 6, 0, 6)") == 1, "the shadow is defined once")


# --- Pip: the first hitbox counts as something to find -----------------------------

func test_pip_leads_to_the_first_hitbox_when_it_still_has_something_to_say() -> void:
	for f in Story.FRAGMENTS:
		memory().add_fragment(f.id)
	memory().found_pip = true
	var w := await start_session()
	await go_to(w, "oob", "well")
	check_eq(Progression.stage(), Progression.Stage.INVESTIGATE, "every memory, the truth not yet ready")
	var shape: Variant = null
	for n in w.area.interactables:
		if n is Readable and n.title == Story.FIRST_SHAPE_TITLE:
			shape = n
	check(shape != null, "the first hitbox is on the ledge")
	check(w.guide_target().distance_to(shape.global_position) < 1.0, "Pip leads there, not to the pillar (%s)" % w.guide_target())
	memory().learn_truth_piece("pip")
	check(w.guide_target().distance_to(shape.global_position) > 10.0, "once read, not again")


# --- House: the chime is seen at once ------------------------------------------------

func test_the_chime_shows_at_once_even_behind_a_busy_console() -> void:
	var w := await start_session()
	await go_to(w, "house", "front")
	for i in 8:
		w.hud.say("a long line the console is still typing out, one of several queued up %d" % i, "system")
	w.area.next_visit = ArinsHouse.CHIME_LEAD + 0.05
	await wait(0.3)
	check(w.hud.warning_text().contains("the door"), "on screen at once, not queued (%s)" % w.hud.warning_text())


# --- Captions: a scene over a long recorded take ----------------------------------

func _clip(seconds: float) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = 11025
	var data := PackedByteArray()
	data.resize(int(11025 * seconds) * 2)
	w.data = data
	return w


const LONG_TAKE := "This is one long recorded line, long enough that its caption has to be split across several pages of the dialogue box, so that each page owns only its own share of the single take, and nobody should have to wait for the whole recording to finish on the very first page of it before moving on."


func _long_take_conversation(w: Node) -> void:
	VoiceOver.register(Hud.voice_id("npc.test", LONG_TAKE), _clip(12.0))
	w.hud.show_dialogue("TEST", Color.WHITE, [LONG_TAKE], "npc.test")
	await frames(3)


func test_a_scene_over_an_early_page_resumes_that_page_not_the_whole_take() -> void:
	settings().advance_mode = 1  # Auto: the page moves on when its share is said
	var w := await start_session()
	await _long_take_conversation(w)
	check(w.hud._dialogue_lines.size() >= 2, "the take spans pages (%d)" % w.hud._dialogue_lines.size())
	check_eq(w.hud._dialogue_index, 0, "on its first page")
	await wait(0.6)
	var typed_before: int = w.hud._dialogue_text.visible_characters
	var done := [false]
	(func() -> void:
		await w.hud.cinematic("TEST", ["a scene over the conversation."], Hud.SELF_COLOR, 0.5)
		done[0] = true).call_deferred()
	await wait_until(func() -> bool: return w.hud.is_cinematic(), 3.0, "the scene")
	await read_through_cinematic(w)
	await wait_until(func() -> bool: return done[0], 4.0, "the scene to end")
	check_eq(w.hud._dialogue_index, 0, "back on the same page")
	check_eq(VoiceOver.current_id(), Hud.voice_id("npc.test", LONG_TAKE), "the same take, resumed")
	var shown: int = w.hud._dialogue_text.visible_characters
	check(shown < 0 or shown >= typed_before, "the caption keeps its place with the voice (%d, was %d)" % [shown, typed_before])
	# Past the first page's share of the take, the first page is done even
	# though the take plays on: the page's own rule, as before the scene.
	var p := VoiceOver.current()
	var fraction: float = w.hud._page_fraction(w.hud._dialogue_lines, w.hud._dialogue_sources, 0)
	p.seek(p.stream.get_length() * fraction + 0.3)
	await frames(2)
	check(VoiceOver.is_playing(), "the take is still playing")
	check(not w.hud._pacer.voice_busy.call(), "but the first page isn't waiting for all of it")
	w.hud.close_dialogue()
	settings().advance_mode = 0


func _scene_over(w: Node) -> void:
	var done := [false]
	(func() -> void:
		await w.hud.cinematic("TEST", ["a scene over the conversation."], Hud.SELF_COLOR, 0.5)
		done[0] = true).call_deferred()
	await wait_until(func() -> bool: return w.hud.is_cinematic(), 3.0, "the scene")
	await read_through_cinematic(w)
	await wait_until(func() -> bool: return done[0], 4.0, "the scene to end")


func test_a_scene_over_a_later_page_comes_back_to_that_page_once() -> void:
	var w := await start_session()
	await _long_take_conversation(w)
	await press("interact")  # reveal
	await press("interact")  # next page
	await frames(2)
	check_eq(w.hud._dialogue_index, 1, "on the second page")
	var history: int = w.hud.console_history.size()
	await _scene_over(w)
	check_eq(w.hud._dialogue_index, 1, "back on the second page, not the first")
	check_eq(VoiceOver.current_id(), Hud.voice_id("npc.test", LONG_TAKE), "the take is still the one playing")
	check_eq(w.hud.console_history.filter(func(l: String) -> bool: return l.contains("one long recorded line")).size(), 0, "the conversation line isn't logged again by the scene")
	check(w.hud.console_history.size() <= history + 2, "only the scene's own line was added to the history")
	w.hud.close_dialogue()


func test_without_a_recording_the_page_is_typed_again_from_its_start() -> void:
	var w := await start_session()
	w.hud.show_dialogue("TEST", Color.WHITE, [LONG_TAKE], "npc.unrecorded")
	await wait(0.5)
	check(VoiceOver.current() == null, "nothing recorded")
	await _scene_over(w)
	check_eq(w.hud._dialogue_index, 0, "the same page")
	check(w.hud._pacer.phase == LinePacer.Phase.REVEALING and w.hud._dialogue_text.visible_characters < 5, "typed again from its start, so it can be read")
	w.hud.close_dialogue()


# --- HUD: one actionable thought ------------------------------------------------------

func test_the_goal_on_screen_is_one_actionable_thought() -> void:
	check_eq(Hud.first_thought("Get out of Arin's room."), "Get out of Arin's room.", "a one-sentence goal is shown whole")
	check_eq(Hud.first_thought("Explore the village: the road east leads somewhere old. The well looks deeper than it should."),
		"Explore the village: the road east leads somewhere old.", "the rest waits in the journal")
	check(Hud.first_thought("TRUCE: the owner only watches this run, unless you glitch. Get out of Arin's room.").begins_with("TRUCE  ·  Get out"),
		"a truce keeps its mark and the action")
	var w := await start_session()
	await go_to(w, "bin", "west")
	await wait(0.8)
	check(w.current_goal().contains("system file's shadow"), "the full goal has the shelter")
	check(Hud.first_thought(w.current_goal().get_slice("\n", 0)).contains("shadow"), "and so does what the screen shows: the survival part comes first")


func test_held_in_the_lamp_the_owner_learns_the_crossing() -> void:
	var w := await _square()
	var lamp: OwnerLamp = w.area.lamp
	w.area.arin.global_position = Vector2(60, 280)
	var spot := Vector2(668, 200)
	w.player.global_position = spot
	var before: int = memory().session_spots.size()
	for i in 20:  # a second in the beam, aimed at her
		lamp._angle = (spot - lamp.global_position).angle()
		w.area._on_lamp_sees(0.05)
	check_eq(memory().session_spots.size(), before + 1, "one spot learned for one time in the beam")
	check(memory().session_spots[-1].area == "square", "in the square")
	var quick: int = memory().session_spots.size()
	w.area._lamp_seen_frame = -100  # a later, separate crossing
	for i in 5:  # under the grace: crossing quickly
		w.area._on_lamp_sees(0.05)
		await frames(1)
	check_eq(memory().session_spots.size(), quick, "a quick crossing teaches it nothing")


func test_leaving_the_house_takes_its_chime_alert_with_it() -> void:
	var w := await start_session()
	await go_to(w, "house", "front")
	w.area.next_visit = ArinsHouse.CHIME_LEAD - 0.1
	await wait(0.3)
	check_eq(w.hud.warning_text(), ArinsHouse.CHIME_ALERT, "the chime's alert")
	await go_to(w, "square", "house")
	check_eq(w.hud.warning_text(), "", "gone once Rue has left the house")

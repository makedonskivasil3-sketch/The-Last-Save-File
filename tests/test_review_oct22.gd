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

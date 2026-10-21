extends "res://tests/test_case.gd"
## Captures of the continuity slice (docs/CONTINUITY_MILESTONE.md). Not part
## of the suite:
##   xvfb-run -a -s "-screen 0 1280x720x24" $GODOT --path . -s res://tests/run_tests.gd \
##       -- --test-mode --tour --filter=tour_continuity --screenshots=/some/dir


func test_continuity_captures() -> void:
	settings().tutorial_tips = false
	# A reunion after Wren saw you taken.
	var w := await start_session()
	w.director.stop()
	await go_to(w, "square", "house")
	await interact_with(w, w.area.wren)
	await finish_dialogue(w)
	await shot("c1_first_meeting_done")
	w.kill("arin", "tour")
	await wait(1.5)
	await shot("c2_death_card_kept")
	var w2 := await wait_for_new_session(w)
	w2.director.stop()
	await go_to(w2, "square", "house")
	await interact_with(w2, w2.area.wren)
	await wait(1.2)
	await shot("c3_wren_reunion")
	await finish_dialogue(w2)
	# The archive's People page.
	w2._pause_menu.open()
	w2._pause_menu._show_journal()
	await frames(3)
	w2._pause_menu._journal.show_section("people")
	await wait(0.4)
	await shot("c4_archive_people")
	w2._pause_menu.close()
	await frames(3)
	# The well's words.
	for s in ["click", "tune"]:
		memory().well_events.append(s)
	w2.player.global_position = w2.area.rim.global_position + Vector2(0, -10)
	await frames(3)
	w2._interact(w2.area.rim)
	await wait(1.5)
	await shot("c5_well_words")
	await finish_dialogue(w2)
	# Answered: the anchor; the next death wakes you under the well.
	memory().add_fragment("delete")
	memory().well_events.append_array(["words", "compared"])
	w2.set_anchor("oob:pillar")
	memory().well_events.append("answered")
	w2.kill("arin", "tour")
	await wait(1.5)
	await shot("c6_death_card_anchor")
	var w3 := await wait_for_new_session(w2)
	await wait(1.5)
	await shot("c7_woke_under_the_well")

extends "res://tests/test_case.gd"
## Captures of the coherence milestone (docs/COHERENCE_MILESTONE.md). Not
## part of the suite:
##   xvfb-run -a -s "-screen 0 1280x720x24" $GODOT --path . -s res://tests/run_tests.gd \
##       -- --test-mode --tour --filter=tour_coherence --screenshots=/some/dir


func test_coherence_captures() -> void:
	settings().tutorial_tips = false
	var w := await start_session()
	w.director.stop()
	# Mira: met, then taken in front of her.
	await interact_with(w, w.area.mira)
	await finish_dialogue(w)
	await go_to(w, "square", "house")
	w.director.stop()
	for i in 2:
		await interact_with(w, w.area.wren)
		await finish_dialogue(w)
	await go_to(w, "archive", "west")
	await go_to(w, "room", "start")
	w.player.global_position = w.area.mira.global_position + Vector2(0, 30)
	await frames(2)
	w.kill("arin", "tour")
	var w2 := await wait_for_new_session(w)
	w2.director.stop()
	# 1. The map after a death: everything found is still named.
	w2.open_pause()
	w2._pause_menu._show_map()
	await wait(0.4)
	await shot("k1_map_after_a_death")
	w2._pause_menu.close()
	await frames(3)
	# 2. Mira, the first time she sees you since.
	await interact_with(w2, w2.area.mira)
	await wait(1.2)
	await shot("k2_mira_saw_you_taken")
	await finish_dialogue(w2)
	# 3. Wren's page: seen, said, unknown, Rue's reading.
	w2._pause_menu.open()
	w2._pause_menu._show_journal()
	await frames(3)
	var j: JournalPanel = w2._pause_menu._journal
	(j._tabs.get_child(ArchivePages.SECTIONS.find("people")) as Button).pressed.emit()
	await frames(2)
	for i in j._entries.size():
		if j._entries[i].key == "person:wren":
			(j._list.get_child(i) as Button).pressed.emit()
	await wait(0.4)
	await shot("k3_archive_wren_kinds")
	w2._pause_menu.close()
	await frames(3)
	# 4. Under the well, after the tune: keep your place.
	memory().well_events.append("click")
	memory().add_fragment("well")
	await go_to(w2, "square", "house")
	await go_to(w2, "oob", "well")
	w2.player.global_position = OutOfBounds.PILLAR_POS + Vector2(20, 18)
	await wait_until(func() -> bool: return WellSequence.done("tune"), 3.0, "the tune")
	w2.player.global_position = w2.area.mark.global_position + Vector2(0, 8)
	await wait(1.0)
	await shot("k4_keep_my_place_offered")
	w2._interact(w2.area.mark)
	await wait(1.2)
	await shot("k5_place_kept")

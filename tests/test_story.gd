extends "res://tests/test_case.gd"
## Boot sequence, inner voice, memory fragments, endings.


func test_first_launch_boots_then_wakes() -> void:
	tree.change_scene_to_file(MAIN_SCENE)
	await wait_until(func() -> bool: return scene() != null and scene().get("hud") != null, 5.0, "main scene")
	var w := scene()
	await wait(0.6)
	check(w.hud.is_cinematic(), "boot cinematic plays on first launch")
	check(w.player.frozen, "can't move during the boot")
	for i in 20:
		if not w._cutscene:
			break
		await press("interact")
		await wait(0.2)
	await wait_until(func() -> bool: return not w._cutscene, 8.0, "boot to finish")
	check(not w.player.frozen, "player wakes up and can move")
	check(w._voiced.has("wake_first"), "first thought spoken")


func test_fragment_plays_flashback_and_is_kept() -> void:
	var w := await start_session()
	var frag: MemoryFragment = null
	for c in w.area.get_children():
		if c is MemoryFragment:
			frag = c
	check(frag != null, "Arin's room has a fragment")
	if frag == null:
		return
	w.player.global_position = frag.global_position
	await wait_until(func() -> bool: return w._cutscene, 2.0, "flashback to start")
	check(w.hud.is_cinematic(), "flashback is a cinematic")
	check(w.area.process_mode == Node.PROCESS_MODE_DISABLED, "the world holds still")
	for i in 20:
		if not w._cutscene:
			break
		await press("interact")
		await wait(0.2)
	await wait_until(func() -> bool: return not w._cutscene, 10.0, "flashback to end")
	check(memory().has_fragment("controller"), "memory kept")
	check(w.area.process_mode == Node.PROCESS_MODE_INHERIT, "the world resumes")


func test_collected_fragments_dont_respawn() -> void:
	memory().add_fragment("controller")
	var w := await start_session()
	await frames(2)
	for c in w.area.get_children():
		check(not c is MemoryFragment, "a recovered memory doesn't appear again")


func test_full_memory_changes_the_ending() -> void:
	for f in Story.FRAGMENTS:
		memory().add_fragment(f.id)
	check(Story.win_text(Story.FRAGMENTS.size()).contains(Story.SECOND_PLAYER_NAME), "the full ending names you")
	check(not Story.win_text(2).contains(Story.SECOND_PLAYER_NAME), "partial endings don't")


func test_every_fragment_is_placed_in_a_real_area() -> void:
	var areas := ["room", "square", "archive", "edge"]
	var ids := {}
	for f in Story.FRAGMENTS:
		check(f.area in areas, "fragment %s is in a real area" % f.id)
		check(not ids.has(f.id), "fragment id %s is unique" % f.id)
		ids[f.id] = true

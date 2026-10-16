extends "res://tests/test_case.gd"
## Character readability (docs/CHARACTER_DIRECTION.md): gameplay state drives
## the tells, and a tell never implies something gameplay didn't do.


func test_arin_points_instead_of_waving() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var arin: OwnerAvatar = await _arin_watching(w)
	check(arin._sprite.pointing, "Arin points at you")
	check(not arin._sprite.waving, "not a friendly wave")
	w.player.global_position = arin.global_position - arin._facing * 120.0
	await frames(4)
	check(not arin._sprite.pointing, "and stops when it loses you")


func test_the_real_arin_never_moves_its_mouth() -> void:
	var m := memory()
	m.sessions = 8
	m.purge = OwnerMemory.MAX_PURGE
	m.last_exit = "death"
	tree.change_scene_to_file(MAIN_SCENE)
	await wait_until(func() -> bool: return scene() != null and scene().get("purged") == true, 5.0, "the purged room")
	var arin: Npc = null
	for n in scene().area.interactables:
		if n is Npc and n.npc_id == "arin":
			arin = n
	check(arin != null and arin.mute, "the real Arin is silent")
	arin.talking = true
	await frames(2)
	check(not arin.sprite().talking, "its mouth stays still even mid-dialogue")


func test_rue_reacts_while_targeted() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.player._sprite.startled = 0.0
	var arin: OwnerAvatar = await _arin_watching(w)
	check(w.player._sprite.startled > 0.0, "wide eyes while Arin has her")
	w.player.global_position = arin.global_position - arin._facing * 120.0
	await wait(0.6)
	check_eq(w.player._sprite.startled, 0.0, "and they settle once it looks away")


## Arin held still (the owner paused), with Rue standing in its view cone.
func _arin_watching(w: Node) -> OwnerAvatar:
	var arin: OwnerAvatar = w.area.arin
	w.director.paused = true
	arin.route = [arin.global_position] as Array[Vector2]
	w.player.global_position = arin.global_position + arin._facing * 30.0
	await wait_until(func() -> bool: return arin.is_seeing(), 2.0, "Arin seeing Rue")
	await frames(2)
	return arin

extends "res://tests/test_case.gd"
## The cast in the world, the same states before and after the character
## pass (docs/ART_BIBLE.md): Rue and Mira in the room, the square (Wren,
## Tobben, Arin, the fifth lantern), the Archivist, Slot 2 at the Edge.
## Not part of the suite. Prefix from TOUR_LABEL (default "after").
##   TOUR_LABEL=before ... --tour --filter=tour_world_cast --screenshots=DIR


func _l(name: String) -> String:
	var label := OS.get_environment("TOUR_LABEL")
	return "%s_%s" % [label if label != "" else "after", name]


func _hold(w: Node) -> void:
	w.director.paused = true
	if w.area.get("arin"):
		w.area.arin.paused = true


func test_cast_in_the_world() -> void:
	var w := await start_session()
	_hold(w)
	w.hud.show_objective("")
	w.player.global_position = w.area.mira.global_position + Vector2(-34, 10)
	await wait(1.2)
	await shot(_l("cast_1_room"))
	await go_to(w, "square", "house")
	_hold(w)
	w.player.global_position = w.area.wren.global_position + Vector2(24, 4)
	w.area.arin.global_position = w.area.wren.global_position + Vector2(70, -10)
	await wait(1.2)
	await shot(_l("cast_2_square_wren"))
	w.player.global_position = w.area.tobben.global_position + Vector2(-26, 26)
	await wait(1.0)
	await shot(_l("cast_3_square_tobben"))
	w.player.global_position = VillageSquare.WELL.get_center() + Vector2(-10, 30)
	await wait(1.0)
	await shot(_l("cast_4_square_lantern"))
	await go_to(w, "archive", "west")
	_hold(w)
	w.player.global_position = w.area.archivist.global_position + Vector2(-30, 20)
	await wait(1.0)
	await shot(_l("cast_5_archive"))
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	_hold(w)
	w.player.global_position = TheEdge.SLOT_POS + Vector2(-50, 40)
	await wait(1.0)
	await shot(_l("cast_6_edge_slot2"))

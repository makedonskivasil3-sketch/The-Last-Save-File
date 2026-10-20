extends "res://tests/test_case.gd"
## Threats play by the same rules as the player (docs/GAMEPLAY_CONSISTENCY.md):
## what blocks walking blocks Arin's eyes, and the cone drawn is the look.


func _square() -> Node:
	var w := await start_session()
	await go_to(w, "square", "house")
	var arin: OwnerAvatar = w.area.arin
	arin.paused = true
	return w


func test_arin_cannot_see_through_the_stall() -> void:
	var w := await _square()
	var arin: OwnerAvatar = w.area.arin
	var stall: Rect2 = VillageSquare.STALL
	arin.global_position = Vector2(stall.get_center().x, stall.end.y + 30)
	arin._facing = Vector2.UP
	var behind := Vector2(stall.get_center().x, stall.position.y - 4)
	check(arin.global_position.distance_to(behind) < arin.view_distance, "close enough to be seen")
	arin.paused = false  # (paused, Arin sees nothing at all; no frame passes before the checks)
	check(not arin.can_see(behind), "but the stall is in the way")
	arin._facing = Vector2.LEFT
	var open := arin.global_position + Vector2(-60, 0)
	check(arin.can_see(open), "in the open at the same distance: seen")


func test_the_cone_stops_where_the_look_stops() -> void:
	var w := await _square()
	var arin: OwnerAvatar = w.area.arin
	var stall: Rect2 = VillageSquare.STALL
	arin.global_position = Vector2(stall.get_center().x, stall.end.y + 30)
	arin._facing = Vector2.UP
	var tip := arin._blocked(arin.global_position + Vector2.UP * arin.view_distance)
	check(tip.y >= stall.end.y - 1.0, "the look up ends at the stall's front (%s)" % str(tip))
	check(tip.distance_to(arin.global_position) < arin.view_distance, "short of its full reach")

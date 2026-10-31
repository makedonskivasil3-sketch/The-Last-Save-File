extends "res://tests/test_case.gd"
## People notice Rue arrive (Area.on_arrival) and dust at her feet. The
## doorway itself (threshold, facing, timing) is main's design, tested in
## test_world_cohesion.


func _square() -> Node:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.paused = true
	w.area.arin.position = Vector2(560, 300)
	w.area.arin.route = [Vector2(560, 300)] as Array[Vector2]
	return w


func test_people_notice_her_arrive() -> void:
	memory().meet("wren", "square")
	memory().meet("tobben", "square")
	var w := await _square()
	var who: Array = w.area.on_arrival(false)
	check(who.has("wren") and who.has("tobben"), "Wren and Tobben look up (%s)" % [who])
	memory().encounters.erase("tobben")
	check(not w.area.on_arrival(false).has("tobben"), "not someone she hasn't met")
	w.director.add_awareness(OwnerDirector.HUNT + 1.0 - w.director.awareness)
	check(w.area.on_arrival(false).is_empty(), "nobody waves while the owner hunts")


func test_dust_when_she_sets_off() -> void:
	var w := await _square()
	w.player.global_position = Vector2(400, 230)
	await wait(0.3)
	_act("move_right", true)
	await frames(6)
	var n: int = w.player.dust_count()
	_act("move_right", false)
	check(n > 0, "a puff at her feet when she sets off")


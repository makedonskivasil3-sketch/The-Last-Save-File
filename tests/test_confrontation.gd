extends "res://tests/test_case.gd"
## The final confrontation at Slot 2: the owner grabs the slot halfway,
## BLIND makes it let go, Arin walks in to guard it.


func _at_edge(w: Node) -> void:
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	# Arrival is safe: nothing moves until the act card has gone.
	await wait_until(func() -> bool: return not w.hud.is_act_shown(), 8.0, "the act card")
	w.area.grace = 99.0  # no static in these tests


func test_the_owner_grabs_the_slot_halfway() -> void:
	var w := await start_session()
	await _at_edge(w)
	var edge: TheEdge = w.area
	edge.cursor.position = Vector2(60, 270)
	edge.slot.progress = TheEdge.FIGHT_AT
	await wait_until(func() -> bool: return edge.fight == "drag", 8.0, "the cursor reaching the slot")
	check(edge.slot.held, "the owner has hold of it: no writing")
	var at := edge.slot.global_position
	await wait(1.0)
	check(edge.slot.global_position.distance_to(at) > 20.0, "and drags it away")


func test_blind_makes_it_let_go() -> void:
	var w := await start_session()
	await _at_edge(w)
	var edge: TheEdge = w.area
	edge.slot.progress = TheEdge.FIGHT_AT
	await wait_until(func() -> bool: return edge.fight == "drag", 8.0, "the drag")
	await wait(0.5)
	edge.cursor.blind(3.0)
	await frames(3)
	check(not edge.slot.held, "BLIND: it drops the slot")
	check(edge.slot.global_position.distance_to(TheEdge.SLOT_POS) > 10.0, "where it was, mid-drag")


func test_arin_comes_to_guard_it() -> void:
	var w := await start_session()
	await _at_edge(w)
	var edge: TheEdge = w.area
	edge.slot.progress = TheEdge.FIGHT_AT
	await wait_until(func() -> bool: return edge.fight == "done", 30.0, "the drag and drop")
	check(edge.arin != null, "Arin walks in")
	var near := false
	for spot in TheEdge.DROP_SPOTS:
		near = near or edge.slot.global_position.distance_to(spot) < 2.0
	check(near, "the slot is where the owner left it")
	# You can still finish writing yourself in.
	edge.arin.stun(10.0)
	edge.cursor.blind(10.0)
	w.player.global_position = edge.slot.global_position
	await wait_until(func() -> bool: return w._cutscene, 4.0, "finishing the slot")
	check(w._cutscene, "the slot fills and the choice comes")

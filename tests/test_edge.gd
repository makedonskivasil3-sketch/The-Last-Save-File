extends "res://tests/test_case.gd"
## The Edge is the finale, not a wall: a grace period with a countdown, a
## slower static that only partly hunts you, no traps where you died, and one
## death out there that doesn't count.


func _at_edge(w: Node) -> void:
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")


func test_the_static_waits_and_counts_down() -> void:
	var w := await start_session()
	await _at_edge(w)
	var edge: TheEdge = w.area
	check(not edge.erasure.active, "no static the moment you arrive")
	# The act card comes first; the countdown starts once it's gone.
	await wait_until(func() -> bool: return not w.hud.is_act_shown(), 8.0, "the act card")
	await wait(1.0)
	check(w.hud.banner_text().begins_with("THE EDGE IS UNLOADING"), "a countdown says so (%s)" % w.hud.banner_text())
	await wait(TheEdge.GRACE - 1.5)
	check(not edge.erasure.active, "still waiting just before the grace runs out")
	await wait(1.2)
	check(edge.erasure.active, "then it starts")
	check(w.hud.banner_text() == "", "and the countdown clears")


func test_the_static_is_gentler_here() -> void:
	var w := await start_session()
	await _at_edge(w)
	var edge: TheEdge = w.area
	edge.grace = 0.01
	await frames(3)
	check_eq(edge.erasure.burst, 1, "one cell at a time, whatever the purge")
	check(edge.erasure.hunt_chance < 0.6, "it only partly hunts you")
	check(edge.erasure.mature_time >= 1.0, "new cells flicker longer before they're lethal")
	check(edge.spread_interval() > 0.95, "calm: about a cell a second (%.2f)" % edge.spread_interval())
	memory().purge = 6
	w.director.add_awareness(100.0)
	check(edge.spread_interval() >= TheEdge.MIN_INTERVAL, "never faster than the floor (%.2f)" % edge.spread_interval())
	check(edge.spread_interval() < 0.95, "but faster when it's angry")


func test_no_traps_where_you_died() -> void:
	memory().sessions = 2
	memory().deaths_log.append({"area": "edge", "x": 320.0, "y": 240.0, "session": 1})
	var w := await start_session()
	await _at_edge(w)
	var edge: TheEdge = w.area
	edge.grace = 0.01
	await frames(3)
	check(not edge.erasure.is_void(Vector2(320, 240)), "where you died is marked, not seeded")


func test_grace_grows_after_the_static_gets_you() -> void:
	var m := memory()
	var before := TheEdge.grace_time()
	m.begin_session()
	m.record_death("edge", Vector2.ZERO, "eraser")
	check(TheEdge.grace_time() > before, "a longer grace next time (%.1f -> %.1f)" % [before, TheEdge.grace_time()])
	m.begin_session()
	m.record_death("square", Vector2.ZERO, "arin")
	check_eq(TheEdge.grace_time(), TheEdge.GRACE, "back to normal once you die somewhere else")


func test_one_edge_death_does_not_count() -> void:
	var m := memory()
	m.purge = 3
	m.begin_session()
	check(m.record_death("edge", Vector2.ZERO, "eraser"), "the first death at the Edge is forgiven")
	check_eq(m.purge, 3, "no purge for it")
	m.begin_session()
	check(not m.record_death("edge", Vector2.ZERO, "eraser"), "the second one counts")
	check_eq(m.purge, 4, "purge rises")
	m.begin_session()
	m.record_win("escape")
	m.begin_session()
	check(m.record_death("edge", Vector2.ZERO, "cursor"), "reaching Slot 2 earns the mercy back")


func test_the_forgiven_death_says_so() -> void:
	var w := await start_session()
	await _at_edge(w)
	w.kill("erased", "eraser")
	await wait(0.8)
	check(w.hud._overlay_body.text.contains("didn't count"), "the death card says it didn't count")
	check(w.hud.death_tip_text().contains("waits"), "and that the static will wait longer (%s)" % w.hud.death_tip_text())

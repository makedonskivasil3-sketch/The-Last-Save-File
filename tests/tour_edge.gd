extends "res://tests/test_case.gd"
## The Edge confrontation, phase by phase, for review screenshots. Not part
## of the suite.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" $GODOT --path . -s res://tests/run_tests.gd \
##       -- --test-mode --tour --filter=tour_edge --screenshots=/some/dir


func test_edge_phases() -> void:
	var w := await start_session()
	w.bench_immune = true  # (screenshots only: Rue can't die mid-shot)
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	var edge: TheEdge = w.area
	await wait(0.8)
	await shot("e1_arrival_act_card")
	await wait_until(func() -> bool: return not w.hud.is_act_shown(), 8.0, "the card")
	await wait(1.2)
	await shot("e2_countdown")
	edge.grace = 0.05
	await wait(3.0)
	await shot("e3_static_spreading")
	# Luring: the cursor follows Rue away from the slot.
	w.player.global_position = Vector2(200, 230)
	await wait(2.0)
	await shot("e4_luring")
	# Writing: Rue in the slot, the cursor away.
	edge.cursor.global_position = Vector2(80, 250)
	edge.cursor.blind(3.0)  # (lured away and blinded, as a player would)
	w.player.global_position = edge.slot.global_position
	await wait(1.0)
	await shot("e5_writing")
	edge.slot.progress = TheEdge.FIGHT_AT
	await wait_until(func() -> bool: return edge.fight == "reach", 4.0, "the owner noticing the slot")
	w.player.global_position = edge.slot.global_position + Vector2(-60, 60)  # steps out (else she finishes first)
	await wait(0.5)
	await shot("e5b_owner_notices")
	await wait_until(func() -> bool: return edge.fight == "drag", 8.0, "the owner grabbing the slot")
	await wait(0.6)
	await shot("e6_dragging")
	await wait_until(func() -> bool: return edge.fight in ["arin", "done"], 15.0, "the release")
	await shot("e7_released")
	await wait(4.0)
	await shot("e8_guard_arrives")


func test_edge_reduced_effects() -> void:
	settings().reduce_flashing = true
	settings().glitch_intensity = 0.0
	settings().screen_effects = 0
	var w := await start_session()
	w.bench_immune = true
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	await wait_until(func() -> bool: return not w.hud.is_act_shown(), 8.0, "the card")
	w.area.grace = 0.05
	await wait(3.0)
	await shot("e9_reduced_effects")

extends "res://tests/test_case.gd"
## Terminal finale state and directional animation must survive normal updates.

func test_terminal_slot_keeps_cursor_stopped_after_generic_resume() -> void:
	var w := await start_session()
	await go_to(w, "edge", "south")
	var edge: TheEdge = w.area
	for state in ["reach", "drag", "beaten"]:
		edge.fight = state
		edge.set_owner_paused(true)
		edge.set_owner_paused(false)
		check(edge.cursor.paused, "generic resume cannot restart the cursor during %s" % state)
	edge.fight = ""
	edge.slot._done = true
	edge.set_owner_paused(false)
	check(edge.cursor.paused, "a completed slot is terminal even without a confrontation")
	check_eq(edge.goal_text(), "", "completed writing must not ask the player to write again")

func test_reading_holds_the_pending_arin_spawn_and_grace() -> void:
	var w := await start_session()
	await go_to(w, "edge", "south")
	var edge: TheEdge = w.area
	edge.fight = "arin"
	edge.grace = 5.0
	w.hud.show_act("NEW GLITCH", "READ THIS", "test")
	edge.area_process(0.5)
	check_eq(edge.fight, "arin", "no confrontation transition behind the reading card")
	check(edge.arin == null, "Arin is not spawned while the story holds the owner")
	check_eq(edge.grace, 5.0, "static countdown observes the same hold")

func test_gaze_turn_animates_once_and_does_not_chatter_near_diagonal() -> void:
	var s := PixelCharacter.new("rue", {})
	s.look_at(Vector2.ZERO, Vector2(100, 0))
	check_eq(s.facing, Vector2.RIGHT, "gaze selects the new direction")
	check(s.turn > 0.0, "stationary gaze uses the turn animation too")
	s.update(0.05, Vector2.ZERO)
	var left := s.turn
	s.look_at(Vector2.ZERO, Vector2(100, 0))
	check_eq(s.turn, left, "repeated gaze does not restart the turn every frame")
	for direction in [Vector2(1.1, 1), Vector2(0.95, 1), Vector2(1.05, 1)]:
		s.look_at(Vector2.ZERO, direction * 100)
		check_eq(s.facing, Vector2.RIGHT, "small diagonal jitter keeps the current horizontal facing")
	s.look_at(Vector2.ZERO, Vector2(0.7, 1) * 100)
	check_eq(s.facing, Vector2.DOWN, "a deliberate vertical turn still works")

func test_completed_slot_clears_the_previous_objective() -> void:
	var w := await start_session()
	await go_to(w, "edge", "south")
	w.area.slot.set_physics_process(false)
	w.hud.show_objective("Stay in Slot 2 to finish writing.")
	w.area.slot._done = true
	w.reach_slot2()
	await frames(2)
	check_eq(w.hud._objective.text, "", "the obsolete instruction is removed at completion")
	check(w.hud._objective_tween == null, "no hidden objective animation survives the ending transition")

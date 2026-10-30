extends "res://tests/test_case.gd"


func test_ordinary_doors_do_not_signal_corruption() -> void:
	var w := await start_session()
	w.fx._glitch = 0.0
	w.fx.enter_area("archive")
	check_eq(w.fx._glitch, 0.0, "ordinary room change does not tear the picture")
	w.fx.enter_area("edge")
	check(w.fx._glitch > 0.5, "the Edge retains its intentional rupture")


func test_wren_recognises_the_repair_only_after_it_happens() -> void:
	Relationships.add("wren.met")
	check(not Relationships.wren(4, false, false).get("lines", []).has(Relationships.WREN_SERVICE_LIGHT[0]), "no invented knowledge before repair")
	Relationships.add(LanternRoute.REPAIRED)
	var told := Relationships.wren(4, false, false)
	check_eq(told.lines, Relationships.WREN_SERVICE_LIGHT, "a personal response to the changed world")
	check(not Relationships.has("wren.service_light"), "requesting a line is not acknowledging it")
	memory().complete_conversation(told.id)
	for id in told.commit:
		Relationships.add(id)
	check(not Relationships.wren(4, false, false).get("lines", []).has(Relationships.WREN_SERVICE_LIGHT[0]), "not repeated after acknowledgement")


func test_planted_feet_follow_ground_in_all_eight_directions() -> void:
	for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN,
			Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(), Vector2(1, -1).normalized(), Vector2(-1, -1).normalized()]:
		for scale: float in [1.0, 1.35]:
			var c := HeroFigure.new("rue", Player.RUE)
			var body := Vector2.ZERO
			var planted := [Vector2.INF, Vector2.INF]
			var worst := 0.0
			for i in 480:
				c.update(1.0 / 240.0, direction * 45.0)
				body += direction * 45.0 / 240.0
				var rig := {"side": c.facing.x != 0, "a": c._walk * PI, "running": false, "dy": 0.0, "s_legs": 0.0, "k": scale}
				for k in 2:
					var pose := c._leg_pose(-1.0 if k == 0 else 1.0, rig)
					var foot: Vector2 = pose.foot * scale
					foot.x *= -1.0 if c.facing.x < 0 else 1.0
					var ground: Vector2 = body + foot
					if pose.lift <= 0.001:
						if planted[k] == Vector2.INF:
							planted[k] = ground
						worst = maxf(worst, ground.distance_to(planted[k]))
					else:
						planted[k] = Vector2.INF
			check(worst < 0.1, "stance ground contact %s at %.2fx: %.3f px" % [direction, scale, worst])


func _workshop() -> World:
	var w: World = await start_session()
	await go_to(w, "workshop", "stairs")
	return w


func test_stair_approach_is_walkable_without_a_furniture_snag() -> void:
	var w := await _workshop()
	Input.action_press("move_down")
	await wait(0.85)
	Input.action_release("move_down")
	check(w.player.position.y > 130, "clear walking route from the stair, not blocked by the lantern rack")


func test_workshop_loop_opens_a_persistent_bidirectional_shortcut() -> void:
	var w := await _workshop()
	var room: LanternWorkshop = w.area
	check(not room.hatch.can_interact(), "hatch is earned, not open on arrival")
	await interact_with(w, room.lamp, Vector2(0, 12))
	check(not LanternRoute.repaired(), "inspecting without a wick cannot repair it")
	await interact_with(w, room.wick, Vector2(0, 12))
	check(Relationships.has(LanternRoute.SPOOL), "real interact input takes the wick")
	check(not room.wick.can_interact(), "cannot pick it up twice")
	await interact_with(w, room.lamp, Vector2(0, 12))
	check(LanternRoute.repaired(), "fitting it restores the lamp")
	check(room._service_light.enabled, "visible light changes")
	check(room.hatch.can_interact(), "hatch opens")
	check(Quests.done("service_light"), "mission complete")
	var count: int = memory().journal.size()
	room.lamp.interact()
	check_eq(memory().journal.size(), count, "repeat inspection does not duplicate the reward")
	await interact_with(w, room.hatch, Vector2(18, 0))
	check(await wait_until(func() -> bool: return w.area.area_id == "oob" and not w._transitioning, 5.0, "well hatch"), "hatch leads below the well")
	var service: Passage
	for node in w.area.interactables:
		if node is Passage and node.target_area == "workshop":
			service = node
	check(service != null, "the return connection exists")
	if service:
		await interact_with(w, service, Vector2(0, 8))
		await wait_until(func() -> bool: return w.area.area_id == "workshop" and not w._transitioning, 5.0, "return workshop")
		check(w.area is LanternWorkshop and w.area._service_light.enabled, "return rebuild preserves the result")
	check(memory().endings_seen.is_empty(), "side mission does not finish the campaign")


func test_workshop_state_survives_save_reload_and_free_suspension() -> void:
	var w := await _workshop()
	w.area.wick.interact()
	w.area.lamp.interact()
	var used := ArchivePages.objects().filter(func(e: Dictionary) -> bool: return e.key == "object:festival_wick")
	check_eq(used.size(), 1, "artefact has one journal entry")
	check(used[0].body.contains("USED"), "journal distinguishes used from carried")
	w.player.position = Vector2(250, 240)
	await frames(3)
	check_eq(w.try_suspend(), "", "workshop supports safe stopping")
	check_eq(str(memory().suspend.area), "workshop", "saved destination is valid")
	memory().clear_state()
	memory().load_memory()
	check(LanternRoute.repaired(), "repair event survives disk reload")
	check(Relationships.has(LanternRoute.SPOOL), "artefact survives disk reload")


func test_optional_room_does_not_replace_the_main_mission() -> void:
	var w := await _workshop()
	check_eq(Quests.active("workshop"), "service_light", "local purpose is clear")
	check(Quests.line("workshop").contains("west workbench"), "first actionable objective")
	w.area.wick.interact()
	check(Quests.line("workshop").contains("centre workbench"), "next objective reacts to pickup")
	w.area.lamp.interact()
	check_eq(Quests.active("square", true), "slot2", "north road story remains intact")
	check(Quests.log_text("square").contains("✓ A LIGHT KEPT BURNING"), "completed side mission stays in the journal")


func test_orientation_holds_hazards_without_clearing_the_menu() -> void:
	var w := await start_session()
	var original := tree.root.size
	w.touch.active = true
	tree.root.size = Vector2i(360, 640)
	w.touch._process(0.01)
	check(tree.paused and w._pause_menu.visible, "portrait opens a real pause")
	var age: float = w.player.idle_time
	await wait(0.2)
	check_eq(w.player.idle_time, age, "gameplay clocks do not run unseen")
	w._pause_menu.close()
	check(tree.paused, "cannot resume behind portrait notice")
	tree.root.size = original
	w.touch._process(0.01)
	check(tree.paused and w._pause_menu.visible, "landscape does not auto-resume")
	w._pause_menu.close()
	check(not tree.paused, "explicit resume in landscape works")


func test_transition_holds_threats_and_arrives_clear_of_the_exit() -> void:
	var w := await start_session()
	w.change_area("archive", "west")
	check(w._transitioning and w.player.frozen, "transition is guarded immediately")
	check(w.story_holds() and w.is_owner_paused(), "threat protection includes the fade")
	await wait_until(func() -> bool: return not w._transitioning, 5.0, "archive")
	check_eq(w.player._sprite.facing, Vector2.RIGHT, "west arrival faces into the Archive")
	check(w.player.position.x > w.area.bounds.position.x + 12, "arrival clears the threshold")
	await frames(10)
	check_eq(w.area.area_id, "archive", "no immediate bounce back")
	await go_to(w, "workshop", "stairs")
	check_eq(w.player._sprite.facing, Vector2.DOWN, "stairs face down into the workshop")
	check(w.body_fits(w.player.position), "arrival body fits on clear floor")

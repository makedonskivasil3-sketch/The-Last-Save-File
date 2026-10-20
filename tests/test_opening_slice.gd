extends "res://tests/test_case.gd"
## Integration regressions for the opening/cast consolidation pass.

func test_charge_counts_only_time_after_hold_and_cooldown() -> void:
	var w := await start_session()
	w.director.paused = true
	w.glitch.set_process(false)
	w.player.set_physics_process(false)
	Input.action_press("interact")
	await frames(2)
	for fps in [30, 60, 120]:
		var dt: float = 1.0 / fps
		for cooling in [false, true]:
			w.glitch.target = {"id": "pause", "node": null, "pos": w.player.position}
			w.glitch._pressing = true
			w.glitch._charge = 0.0
			w.glitch._held = GlitchController.HOLD_START - dt * 0.5 if not cooling else GlitchController.HOLD_START
			w.glitch._cooldown = dt * 0.5 if cooling else 0.0
			w.glitch._process(dt)
			check(absf(w.glitch._charge - dt * 0.5) < 0.00001,
				"%d FPS, cooling=%s: only half a frame was eligible (got %.6f)" % [fps, cooling, w.glitch._charge])
	Input.action_release("interact")

func test_companion_faces_travel_then_the_speaker() -> void:
	var w := await start_session()
	w.director.paused = true
	var npc: Npc = w.area.mira
	npc.set_process(false)
	npc.escorted = true
	npc.global_position = Vector2(340, 180)
	w.player.global_position = Vector2(320, 180)
	npc._walk_velocity = Vector2(60, 0)
	npc.talking = false
	npc._process(1.0 / 60.0)
	check_eq(npc.sprite().facing, Vector2.RIGHT, "a walking companion faces her path, not Rue behind her")
	npc.talking = true
	npc._process(1.0 / 60.0)
	check_eq(npc.sprite().facing, Vector2.LEFT, "conversation deliberately faces Rue")
	npc._walk_velocity = Vector2.ZERO
	npc.talking = false
	npc._process(1.0 / 60.0)
	check_eq(npc.sprite().facing, Vector2.LEFT, "stopped nearby: looks at Rue")

func test_phase_never_commits_to_a_changed_destination() -> void:
	var w := await start_session()
	w.director.paused = true
	w.player.global_position = Vector2(450, 100)
	w.player._sprite.facing = Vector2.RIGHT
	await frames(3)
	var promised: Vector2 = w.glitch.phase_landing()
	check(promised != Vector2.INF, "the first partition has a PHASE landing")
	var t := {"id": "phase", "node": null, "pos": promised}
	# The player moves during the hold: another landing must never replace
	# the preview they committed to. Cancel without cost instead.
	w.player.global_position = Vector2(450, 96)
	var at: Vector2 = w.player.global_position
	var paid: int = memory().total_glitches
	w.glitch._fire(t)
	check_eq(w.player.global_position, at, "a changed PHASE destination cancels")
	check_eq(memory().total_glitches, paid, "cancelled PHASE pays no cost")

func test_a_genuinely_fresh_title_reaches_a_clean_room() -> void:
	settings().opening_seen = false
	settings().tutorial_tips = true
	check_eq(memory().last_exit, "none", "fixture has never entered a run")
	tree.change_scene_to_file(TITLE_SCENE)
	await frames(5)
	var title := scene()
	title._start()
	await wait_until(func() -> bool: return scene() is Opening, 3.0, "first-launch film")
	await frames(2)
	Input.action_press("interact")
	await wait(0.9)
	check(scene() is Opening and scene()._done, "skipped film holds input hand-off")
	Input.action_release("interact")
	await wait_until(func() -> bool: return scene() is World, 5.0, "first room")
	var w := scene()
	await wait_until(func() -> bool: return w.hud.is_cinematic(), 3.0, "fresh boot")
	await read_through_cinematic(w)
	await wait_until(func() -> bool: return not w._cutscene, 4.0, "arrival")
	check_eq(memory().sessions, 1, "one genuine first session")
	check_eq(memory().deaths, 0, "no fabricated death")
	check_eq(memory().quits, 0, "no fabricated quit")
	check_eq(w.glitch._charge, 0.0, "skip did not charge an action")
	check(w.area.note.text != "", "first-run note is readable")
	check(w.player.palette().s == Player.MISSING.s, "Rue remains intentionally faceless")

func test_objective_yields_without_spending_its_reading_time() -> void:
	var w := await start_session()
	w.director.paused = true
	w.hud.show_objective("Find the seam.", "Watch the edge of the wall.")
	await wait(0.5)
	w.hud.show_dialogue("MIRA", Hud.NPC_COLOR, ["Please read this first."])
	await frames(2)
	check(not w.hud._objective.visible, "dialogue owns the screen")
	var elapsed: float = w.hud._objective_tween.get_total_elapsed_time()
	await wait(0.5)
	check(absf(w.hud._objective_tween.get_total_elapsed_time() - elapsed) < 0.05, "hidden objective retains its reading time")
	w.hud.close_dialogue()
	await frames(2)
	check(w.hud._objective.visible, "the objective returns")
	w.hud.set_banner("DANGER")
	await frames(2)
	check(not w.hud._objective.visible, "danger owns the screen")
	w.hud.set_banner("")
	w.hud.show_objective("")
	check(w.hud._objective_tween == null, "clearing a goal starts no tween")
	check_eq(w.hud.objective_text(), "", "cleared goal has no bullet")
	# A finished tween must not be paused into validity and played again.
	w.hud.show_objective("Go.")
	w.hud._objective_tween.custom_step(30.0)
	check(w.hud._objective_tween == null, "completed goal releases its tween")
	w.hud.set_banner("DANGER")
	w.hud._update_objective_priority()
	w.hud.set_banner("")
	w.hud._update_objective_priority()

func test_charge_feedback_fits_large_text_at_the_screen_edge() -> void:
	var w := await start_session()
	settings().large_text = true
	w.glitch.set_process(false)
	w.player.position = Vector2(630, 345)
	w.glitch.target = {"id": "phase", "node": null, "pos": Vector2(620, 345)}
	w.glitch._charge = Glitch.hold_time("phase") * 0.5
	w.glitch._update_prompt()
	await frames(2)
	check(w.glitch._charge_label.text.contains("PHASE 50%"), "action and progress are explicit without audio")
	check(Rect2(8, 8, 624, 344).encloses(w.glitch._charge_label.get_global_rect()), "large feedback remains inside the logical viewport")
	w.glitch._cancel()
	check(not w.glitch._charge_label.visible, "cancel removes stale feedback immediately")

extends "res://tests/test_case.gd"
## Save contract gaps from the release brief (2026-11-03, section 5): what is
## on disk after calm and danger alternate quickly, and what a story reset
## keeps. Each check reads the disk back the way the next launch would.


func _calm_square() -> Node:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.area.arin.position = Vector2(560, 280)
	w.area.arin.route = [Vector2(560, 280)] as Array[Vector2]
	w.player.global_position = Vector2(200, 200)
	w.director.awareness = 0.0
	await frames(3)
	return w


## What the next launch reads: the in-memory state is thrown away first.
func _relaunch_exit() -> String:
	memory().clear_state()
	memory().load_memory()
	return str(memory().last_exit)


func test_rapid_calm_and_danger_always_leave_the_latest_on_disk() -> void:
	var w := await _calm_square()
	await wait(0.6)
	check_eq(memory().last_exit, "safe", "calm first")
	# Flip several times; the disk must follow the game's latest decision,
	# never an older one.
	for i in 4:
		# Unsafe without a chase: a conversation open (World.story_holds).
		w.hud.show_dialogue("Wren", Color.WHITE, ["(a line)"], "", null, [], true)
		await wait(World.SAFE_CHECK + 0.3)
		check_eq(memory().last_exit, "active", "talking (%d): the calm moment is withdrawn" % i)
		w.hud.close_dialogue()
		await wait_until(func() -> bool: return w.suspend_blocker() == "", 5.0, "calm again (%d)" % i)
		await wait(World.SAFE_CHECK + 0.3)
		check_eq(memory().last_exit, "safe", "calm again (%d)" % i)
	check(memory().safe_marks >= 5 and memory().unsafe_marks >= 4, "every change was written (%d safe, %d unsafe)" % [memory().safe_marks, memory().unsafe_marks])
	var at: Vector2 = w.player.global_position
	check_eq(_relaunch_exit(), "suspend", "the disk holds the last calm moment")
	check(str(memory().suspend.get("area", "")) == "square", "with where she was")
	var resumed := Vector2(float(memory().suspend.get("x", 0.0)), float(memory().suspend.get("y", 0.0)))
	check(resumed.distance_to(at) < 20.0, "and where she was then (%s vs %s)" % [resumed, at])


func test_danger_right_after_calm_is_never_resumed_as_calm() -> void:
	var w := await _calm_square()
	await wait(0.6)
	check_eq(memory().last_exit, "safe", "calm")
	w.director.awareness = OwnerDirector.HUNT + 1.0
	await wait(0.6)
	var purge: int = memory().purge
	check_eq(_relaunch_exit(), "crash", "closing now is running away")
	check(memory().suspend.is_empty(), "no stale calm record to resume into")
	check_eq(memory().purge, purge + 1, "and it counts")


func test_settings_survive_a_story_reset() -> void:
	var s := settings()
	s.large_text = true
	s.music_volume = 0.35
	s.save()
	memory().wipe()  # the story, not the person's settings
	s.large_text = false
	s.music_volume = 0.8
	s._load()
	check(s.large_text, "large text kept")
	check(absf(s.music_volume - 0.35) < 0.001, "music volume kept (%.2f)" % s.music_volume)
	s.large_text = false
	s.music_volume = 0.8
	s.save()

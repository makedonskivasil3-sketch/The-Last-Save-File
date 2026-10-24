extends "res://tests/test_case.gd"
## Wall-clock times through the new first session (the festival, then the
## room), on four paths. Injected input, real time, one machine: the game's
## own waits, not people's (docs/INTRO_REBUILD.md §6). The prompt path's
## player acts as soon as asked (autoplay, after a first real keypress); the
## hesitant one waits for each step's words first; no input touches nothing;
## skip holds Esc at once. Run with --tour --filter=tour_timing_intro.

var _t0 := 0
var _acted := {}
var _choice := ""


func _s() -> float:
	return (Time.get_ticks_msec() - _t0) / 1000.0


func _begin() -> Prologue:
	settings().opening_seen = false
	tree.change_scene_to_file(TITLE_SCENE)
	await frames(5)
	_t0 = Time.get_ticks_msec()
	scene()._start()
	await wait_until(func() -> bool: return scene() is Prologue, 3.0, "the festival")
	var p: Prologue = scene()
	p.finished.connect(func() -> void:
		_acted = p.acted.duplicate()
		_choice = p.choice)
	return p


func _report(path: String, room_s: float, decided: String) -> void:
	var a := _acted
	var f := func(k: String) -> String: return ("%.1f s" % (float(a[k]) + 0.0)) if a.has(k) else "—"
	print("TIMING  %-9s  control %s · co-op success (1st lantern) %s · P1 leaves %s · decision %s (%s) · P2 leaves %s · 3 YEARS LATER %s · present %s · in the room %.1f s (wall)" % [
		path, f.call("control"), f.call("lit_1"), f.call("p1_left"), f.call("choice"), decided, f.call("p2_left"),
		("%.1f s" % (float(a.timelapse) + 15.0)) if a.has("timelapse") else "—", f.call("load"), room_s])


func _to_room(path: String) -> void:
	await wait_until(func() -> bool: return scene() is World, 400.0, "the room")
	var room := _s()
	var w := scene()
	await wait_until(func() -> bool: return w._awake, 10.0, "awake")
	_report(path, room, _choice)


func test_prompt() -> void:
	var p := await _begin()
	Input.action_press("move_up")
	await wait(0.15)
	Input.action_release("move_up")
	p.autoplay = true
	await _to_room("prompt")


func test_hesitant() -> void:
	var p := await _begin()
	var last := -1
	while is_instance_valid(p) and not p._done and scene() == p:
		if p.beat != last:
			last = p.beat
			p.autoplay = false
			await wait(Prologue.HINT_AFTER + 1.0)  # reads the step's words first
			if is_instance_valid(p) and p.beat == last:
				p.autoplay = true
				if not p.acted.has("control"):
					p.acted["control"] = p.elapsed
		await frames(1)
	await _to_room("hesitant")


func test_no_input() -> void:
	var p := await _begin()
	await _to_room("no input")


func test_skip() -> void:
	var p := await _begin()
	await frames(2)
	Input.action_press("ui_cancel")
	await wait(Prologue.SKIP_HOLD + 0.2)
	Input.action_release("ui_cancel")
	await _to_room("skip")

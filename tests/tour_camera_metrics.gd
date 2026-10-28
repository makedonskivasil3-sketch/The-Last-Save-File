extends "res://tests/test_case.gd"
## The festival camera, measured (docs/production/MOVEMENT_SPEC.md, Camera).
## Runs on any revision (it reads only _cam, rue_pos, arin_pos): scripted
## input, 60 Hz steps, no rendering. With --screenshots it also captures the
## reversal at three moments. Not part of the suite:
##   --tour --filter=tour_camera_metrics [--screenshots=DIR]
## CAMERA_LABEL names the captures (default "cam").


func _festival() -> Prologue:
	settings().opening_seen = false
	var p := Prologue.new()
	var old := tree.current_scene
	tree.root.add_child(p)
	tree.current_scene = p
	if old:
		old.queue_free()
	await frames(2)
	p.autoplay = false
	return p


func _l(name: String) -> String:
	var label := OS.get_environment("CAMERA_LABEL")
	return "%s_%s" % [label if label != "" else "cam", name]


func _run(p: Prologue, action: String, seconds: float, trace: Array) -> void:
	if action != "":
		Input.action_press(action)
	for i in int(seconds * 60.0):
		p._process(1.0 / 60.0)
		trace.append(p._cam.x - p.rue_pos.x)
	if action != "":
		Input.action_release(action)


func test_camera_metrics() -> void:
	var p := await _festival()
	if p.get("camera_fixed") != null and OS.get_environment("CAMERA_FIXED") == "1":
		p.camera_fixed = true
	for i in 4:
		p.lit[i] = true  # open square, no lantern to frame
	p._arin_present = false
	p.rue_pos = Vector2(160, 250)
	p._cam = p.rue_pos + Vector2(0, -16)
	var trace: Array = []
	await _run(p, "", 0.5, trace)
	await _run(p, "move_right", 1.2, trace)
	var before := trace.size()
	await _run(p, "move_left", 0.6, trace)
	await _run(p, "move_right", 0.6, trace)
	var window := trace.slice(before - 10)
	var lo: float = window.min()
	var hi: float = window.max()
	print("CAMERA  reversal: camera-minus-Rue x ranged %.1f..%.1f px (swing %.1f px) over a 0.6 s reversal and back" % [lo, hi, hi - lo])
	# Arin crossing the shared-framing distance while Rue stands still.
	p._arin_present = true
	p.rue_pos = Vector2(300, 250)
	var jumps := 0.0
	var last := Vector2.INF
	for i in 120:
		p.arin_pos = p.rue_pos + Vector2(130.0 + i * 0.5, 0)
		p._process(1.0 / 60.0)
		if last != Vector2.INF:
			jumps = maxf(jumps, p._cam.distance_to(last))
		last = p._cam
	print("CAMERA  shared framing: largest camera move in one frame while Arin went 130 -> 190 px away: %.2f px" % jumps)
	# Arin hovering around 150 px (where the old framing switched).
	var path := 0.0
	last = p._cam
	for i in 240:
		p.arin_pos = p.rue_pos + Vector2(150.0 + sin(i / 60.0 * TAU * 0.8) * 8.0, 0)
		p._process(1.0 / 60.0)
		path += p._cam.distance_to(last)
		last = p._cam
	print("CAMERA  Arin hovering 142..158 px away for 4 s, Rue still: the camera travelled %.1f px" % path)
	# Standing at an unlit lantern: is it still framed where she left it?
	p._arin_present = false
	p.lit[1] = false
	p.rue_pos = Prologue.LANTERNS[1] + Vector2(-60, 14)
	var at_lantern: Array = []
	await _run(p, "move_right", 0.66, at_lantern)
	await _run(p, "", 1.0, at_lantern)
	var settle := Vector2(p._cam.x - Prologue.LANTERNS[1].x, p._cam.y - Prologue.LANTERNS[1].y)
	print("CAMERA  at a lantern 1 s after stopping: view centre is %s from it" % settle.round())
	if OS.get_environment("CAMERA_SHOTS") == "1":
		p.lit[1] = true
		p.rue_pos = Vector2(160, 250)
		var t: Array = []
		await _run(p, "move_right", 1.0, t)
		await frames(1)
		await shot(_l("1_running_right"))
		await _run(p, "move_left", 0.25, t)
		await frames(1)
		await shot(_l("2_reversed_250ms"))
		await _run(p, "move_left", 0.5, t)
		await frames(1)
		await shot(_l("3_reversed_750ms"))
	p._done = true
	p._handed_off = true
	p.queue_free()
	await frames(2)

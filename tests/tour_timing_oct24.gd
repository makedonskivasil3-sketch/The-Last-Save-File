extends "res://tests/test_case.gd"
## Wall-clock times through the first session, on four paths (prompt,
## hesitant, no input, skip). Injected input, real time, one machine: a
## measurement of the game's own waits, not of people (docs/REVIEW_OCT24.md).
## Run with --tour --filter=tour_timing_oct24. Prints one line per path.

var _t0 := 0
var _marks := {}


func _mark(name: String) -> void:
	if not _marks.has(name):
		_marks[name] = (Time.get_ticks_msec() - _t0) / 1000.0


func _report(path: String) -> void:
	var keys := ["first agency (opening)", "film over", "boot over", "awake in the room", "first step", "first decision (Mira's request)"]
	var parts := []
	for k in keys:
		parts.append("%s %s" % [k, ("%.1f s" % _marks[k]) if _marks.has(k) else "—"])
	print("TIMING  %-9s  %s" % [path, "  ·  ".join(parts)])


func _begin() -> Opening:
	_marks.clear()
	settings().opening_seen = false
	tree.change_scene_to_file(TITLE_SCENE)
	await frames(5)
	_t0 = Time.get_ticks_msec()
	scene()._start()
	await wait_until(func() -> bool: return scene() is Opening, 3.0, "the film")
	return scene()


## Each state, as soon as it asks (or after the hint, if hesitant).
func _play_film(film: Opening, hesitate: float) -> void:
	var start_x := film._rue_x
	for gate in [Opening.Gate.RITUAL, Opening.Gate.INTERRUPT, Opening.Gate.IMPOSSIBLE]:
		await wait_until(func() -> bool: return film._done or (film._gate == gate and film._t >= Opening.GATE_AT[gate]), 60.0, "state %d" % gate)
		if hesitate > 0.0:
			await wait(hesitate)
		if film._gate != gate:
			continue  # it played itself while we hesitated
		match gate:
			Opening.Gate.RITUAL:
				Input.action_press("move_right")
				await wait_until(func() -> bool: return film._rue_x != start_x, 2.0, "she moves")
				_mark("first agency (opening)")
				await wait_until(func() -> bool: return film._parked or absf(film._rue_x - Opening.SAVE_X) < 1.0, 6.0, "the save point")
				Input.action_release("move_right")
				await frames(2)
				await press("interact")
			Opening.Gate.INTERRUPT:
				await wait_until(func() -> bool: return film._habit_t < 0.0, 3.0, "her hands free")
				await press("interact")
			Opening.Gate.IMPOSSIBLE:
				var way := "move_right" if Opening.WELL_X > film._rue_x else "move_left"
				Input.action_press(way)
				await wait_until(func() -> bool: return film.acted.has("impossible"), 8.0, "the well")
				Input.action_release(way)


func _after_film(path: String) -> void:
	await wait_until(func() -> bool: return scene() is World, 120.0, "the room")
	_mark("film over")
	var w := scene()
	await wait_until(func() -> bool: return w.hud.is_cinematic(), 4.0, "the boot")
	await read_through_cinematic(w)  # pressed through, line by line
	_mark("boot over")
	await wait_until(func() -> bool: return w._awake and not w._cutscene, 8.0, "awake")
	_mark("awake in the room")
	if w.hud.is_act_shown():
		w.hud.dismiss_title()
	Input.action_press("move_up")
	await wait(0.3)
	Input.action_release("move_up")
	_mark("first step")
	for i in 6:
		await interact_with(w, w.area.mira)
		await finish_dialogue(w)
		for f in 30:
			if w.hud.is_choosing():
				break
			await frames(2)
		if w.hud.is_choosing():
			break
	if w.hud.is_choosing():
		_mark("first decision (Mira's request)")
	_report(path)


func test_prompt() -> void:
	var film := await _begin()
	await _play_film(film, 0.0)
	await _after_film("prompt")


func test_hesitant() -> void:
	var film := await _begin()
	await _play_film(film, Opening.HINT_AFTER + 1.0)
	await _after_film("hesitant")


func test_no_input() -> void:
	await _begin()
	await _after_film("no input")


func test_skip() -> void:
	await _begin()
	await frames(2)
	Input.action_press("interact")
	await wait(Opening.SKIP_HOLD + 0.2)
	Input.action_release("interact")
	await _after_film("skip")


## The boot text, if read at the game's own reading allowance (auto mode),
## instead of pressed through.
func test_boot_reading_allowance() -> void:
	var total := 0.0
	for line in Story.BOOT:
		total += StoryPacing.reading_time(line)
	print("TIMING  boot      %d lines, %.1f s at the reading allowance (auto mode)" % [Story.BOOT.size(), total])

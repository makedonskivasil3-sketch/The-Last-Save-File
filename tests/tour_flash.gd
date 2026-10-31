extends "res://tests/test_case.gd"
## UI-4: an automated flash measurement against WCAG 2.3.1 (three flashes).
## Not part of the suite: it needs a real renderer (xvfb + opengl3):
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 \
##     -s res://tests/run_tests.gd -- --test-mode --tour --filter=tour_flash
##
## Every frame is captured while the harshest effects play, reduced to a
## 32x18 grid of relative luminance. A frame-to-frame change of at least 0.1
## (with the darker side under 0.8) over at least a quarter of the screen is
## a transition; a flash is a pair of opposing transitions. The general
## threshold is more than three flashes in any one-second window. This is an
## engineering check of the game's own effects, not a certified PSE test,
## and human review of the captures is still needed.

const GRID := Vector2i(32, 18)
const AREA := 0.25
const DELTA := 0.1
const SLOW := 0.25


func _lum(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)


func _frame() -> PackedFloat32Array:
	await RenderingServer.frame_post_draw
	var img := tree.root.get_texture().get_image()
	var out := PackedFloat32Array()
	if img == null or img.is_empty():
		return out
	img.resize(GRID.x, GRID.y, Image.INTERPOLATE_BILINEAR)
	for y in GRID.y:
		for x in GRID.x:
			out.append(_lum(img.get_pixel(x, y)))
	return out


## Records `seconds` of frames; returns [frame times, transition signs].
func _record(seconds: float, start: Callable) -> Array:
	var times: Array[float] = []
	var signs: Array[int] = []
	# The game runs at a quarter speed while it's filmed: capturing a frame
	# is slow, and this keeps the samples dense in game time (times below
	# are game seconds).
	var scale := Engine.time_scale
	Engine.time_scale = SLOW
	var prev := await _frame()
	start.call()
	var t := 0.0
	while t < seconds:
		var cur := await _frame()
		t += tree.root.get_process_delta_time()
		if cur.is_empty() or prev.is_empty():
			prev = cur
			continue
		var up := 0
		var down := 0
		for i in cur.size():
			var d := cur[i] - prev[i]
			if absf(d) >= DELTA and minf(cur[i], prev[i]) < 0.8:
				if d > 0.0:
					up += 1
				else:
					down += 1
		var need := int(AREA * cur.size())
		var s := 1 if up >= need else (-1 if down >= need else 0)
		times.append(t)
		signs.append(s)
		prev = cur
	Engine.time_scale = scale
	return [times, signs]


## Most flashes (pairs of opposing transitions) in any one-second window.
static func worst_window(times: Array, signs: Array) -> int:
	var events: Array[float] = []
	var last := 0
	for i in signs.size():
		if signs[i] != 0 and signs[i] != last:
			events.append(times[i])
			last = signs[i]
	var best := 0
	for i in events.size():
		var n := 0
		for j in range(i, events.size()):
			if events[j] - events[i] <= 1.0:
				n += 1
		best = maxi(best, n / 2)
	return best


func _effects(w: Node) -> void:
	w.fx.wash(Color("ff2040"), 0.8, 1.6)
	w.fx.spike(1.0, 1.4)
	w.fx.noise(1.0, 1.4)
	w.fx.shake(6.0)


func _measure(reduced: bool) -> int:
	settings().reduce_flashing = reduced
	var w := await start_session()
	w.director.paused = true
	await wait(0.5)
	var a: Array = await _record(3.0, _effects.bind(w))
	var flashes := worst_window(a[0], a[1])
	print("FLASH %s: effects burst: %d flashes in the worst second (%d samples in 3 s of game time)" % ["reduced" if reduced else "default", flashes, a[0].size()])
	var worst := flashes
	for cause in ["selected", "overwritten", "erased"]:
		var b: Array = await _record(3.0, w.fx.play_death.bind(cause))
		var n := worst_window(b[0], b[1])
		print("FLASH %s: death (%s): %d flashes in the worst second (%d samples in 3 s of game time)" % ["reduced" if reduced else "default", cause, n, b[0].size()])
		worst = maxi(worst, n)
		await wait(2.5)
	# And a real death, with its card.
	var k: Array = await _record(4.0, func() -> void: w.kill("selected", "cursor"))
	var killed := worst_window(k[0], k[1])
	print("FLASH %s: a real death and its card: %d flashes in the worst second (%d samples)" % ["reduced" if reduced else "default", killed, k[0].size()])
	return maxi(worst, killed)


func test_flash_default() -> void:
	var n := await _measure(false)
	check(n <= 3, "no more than three flashes in any second (%d)" % n)


func test_flash_reduced() -> void:
	var n := await _measure(true)
	check(n <= 1, "reduced flashing: at most one (%d)" % n)

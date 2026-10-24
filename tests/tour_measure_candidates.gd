extends "res://tests/test_case.gd"
## Measures the two profiling candidates from docs/REVIEW_OCT22.md before
## anyone refactors them. Prints numbers; asserts nothing.
## Run: xvfb-run ... -s res://tests/run_tests.gd -- --test-mode --tour --filter=measure_candidates

const ITER := 2000


## The lamp casts up to 4 rays per point: once for its look (can_see) and
## eleven more times in _draw() for the beam. How much of a frame is that?
func test_lamp_ray_cost() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var lamp: OwnerLamp = w.area.lamp
	var target: Vector2 = w.player.global_position
	await frames(5)
	var t0 := Time.get_ticks_usec()
	for i in ITER:
		lamp.can_see(target)
	var look_us := float(Time.get_ticks_usec() - t0) / ITER
	t0 = Time.get_ticks_usec()
	for i in ITER:
		for k in 11:
			var ang := lamp.facing() - lamp.width * 0.5 + lamp.width * k / 10.0
			lamp._blocked(lamp.global_position + Vector2.from_angle(ang) * lamp.reach)
	var beam_us := float(Time.get_ticks_usec() - t0) / ITER
	# The whole frame, for scale.
	var times: Array[float] = []
	var last := Time.get_ticks_usec()
	for i in 180:
		await frames(1)
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
	times.sort()
	print("MEASURE | lamp look (can_see) %.1f us/frame | lamp beam (11 rays in _draw) %.1f us/frame | frame p50 %.2f ms, p95 %.2f ms | lamp share of p50 %.2f%%" % [
		look_us, beam_us, times[90], times[171], (look_us + beam_us) / (times[90] * 1000.0) * 100.0])



# The second candidate (the static's path shared the global RNG with every
# frame's cosmetic draws) was confirmed and fixed; its regression is
# test_review_oct22.test_the_static_goes_the_same_way_however_often_it_is_drawn.

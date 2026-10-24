extends "res://tests/test_case.gd"
## Rue's visual glitches (tears, dropped frames, colour dropouts) happen as
## often, and show as long, at 30, 60 and 120 FPS (A09): rates and holds are
## in seconds, not rolled once per frame. Simulated frame rates on the real
## Player, not hardware. Purely visual: no threat timing is involved.

const SECONDS := 600.0
const RATES := [30, 60, 120]


## Runs the player at `fps` for SECONDS and returns, per effect, events per
## second and the share of time it was on screen.
func _measure(p: Player, fps: int) -> Dictionary:
	seed(4242 + fps)
	var dt := 1.0 / float(fps)
	var out := {"tear": [0, 0.0], "dropout": [0, 0.0], "colour": [0, 0.0]}
	var was := {"tear": false, "dropout": false, "colour": false}
	for i in fps / 5:  # let anything already showing (from other settings) finish
		p._process(dt)
	for i in int(SECONDS * fps):
		p.instability = 1.0
		p._process(dt)
		var now := {"tear": p._tear_rows[0] != 0.0, "dropout": p._blink, "colour": p._sprite.palette == Player.MISSING}
		for k in now:
			if now[k]:
				out[k][1] += dt
				if not was[k]:
					out[k][0] += 1
			was[k] = now[k]
	for k in out:
		out[k] = [out[k][0] / SECONDS, out[k][1] / SECONDS]
	return out


func test_glitches_look_the_same_at_30_60_and_120_fps() -> void:
	var w := await start_session()
	var p: Player = w.player
	w.set_process(false)  # nothing else drives instability meanwhile
	p.set_process(false)
	settings().glitch_intensity = 1.0
	settings().reduce_flashing = false
	p._restored = 3
	p._palette = Player.palette_for(3, [])
	var at := {}
	for fps in RATES:
		at[fps] = _measure(p, fps)
	for k in ["tear", "dropout", "colour"]:
		var lo: Array = at[30][k]
		var hi: Array = at[120][k]
		var mid: Array = at[60][k]
		print("  %s: %s/s, %.1f%% | %s/s, %.1f%% | %s/s, %.1f%%  (30 | 60 | 120 FPS)" % [k, snappedf(lo[0], 0.01), lo[1] * 100, snappedf(mid[0], 0.01), mid[1] * 100, snappedf(hi[0], 0.01), hi[1] * 100])
		check(mid[0] > 0.1, "%s happens at all (%.2f/s)" % [k, mid[0]])
		for fps in [30, 120]:
			var r: Array = at[fps][k]
			check(absf(r[0] / mid[0] - 1.0) < 0.25, "%s: as often at %d FPS as at 60 (%.2f vs %.2f per s)" % [k, fps, r[0], mid[0]])
			check(absf(r[1] / mid[1] - 1.0) < 0.25, "%s: on screen as long at %d FPS (%.1f%% vs %.1f%%)" % [k, fps, r[1] * 100, mid[1] * 100])
	# Each event holds for its time in seconds, not one frame.
	var hold_120: float = at[120]["dropout"][1] / at[120]["dropout"][0]
	check(absf(hold_120 - Player.GLITCH_HOLD) < 0.01, "a dropped frame lasts %.0f ms at 120 FPS (%.0f ms)" % [Player.GLITCH_HOLD * 1000, hold_120 * 1000])
	p.set_process(true)
	w.set_process(true)


func test_reduced_flashing_and_zero_intensity_still_hold() -> void:
	var w := await start_session()
	var p: Player = w.player
	w.set_process(false)
	p.set_process(false)
	p._restored = 3
	p._palette = Player.palette_for(3, [])
	settings().glitch_intensity = 0.0
	var off := _measure(p, 60)
	check_eq(off["dropout"][0], 0.0, "glitch intensity 0: no dropped frames")
	check_eq(off["colour"][0], 0.0, "and no colour dropouts")
	check_eq(off["tear"][1], 0.0, "and no tears")
	settings().glitch_intensity = 1.0
	settings().reduce_flashing = true
	var calm := _measure(p, 60)
	settings().reduce_flashing = false
	var full := _measure(p, 60)
	check(calm["dropout"][0] < full["dropout"][0] * 0.5, "reduced flashing: far fewer dropped frames (%.2f vs %.2f per s)" % [calm["dropout"][0], full["dropout"][0]])
	p.set_process(true)
	w.set_process(true)

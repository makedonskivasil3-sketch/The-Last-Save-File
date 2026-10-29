extends "res://tests/test_case.gd"
## Planted-foot drift (docs/production/MOVEMENT_SPEC.md, "Animation
## contact"): Rue walks side-on at a steady speed; while a foot is planted
## its position on the floor (body travel + the foot's offset) should not
## move. Prints the drift per contact, in floor pixels, at game scale (1)
## and at the festival's (1.35).
##
##   $GODOT --headless --path . -s res://tests/run_tests.gd -- --test-mode \
##       --tour --filter=tour_foot_contact


func _drift(speed: float, scale: float) -> Dictionary:
	var c := HeroFigure.new("rue", Player.RUE)
	c.facing = Vector2.RIGHT
	var dt := 1.0 / 240.0
	var x := 0.0
	var worst := 0.0
	var total := 0.0
	var contacts := 0
	var planted_at := [INF, INF]
	var backwards := 0
	for i in 240 * 3:
		c.update(dt, Vector2(speed, 0))
		x += speed * dt
		var feet: Array = c.feet_now(scale)
		for k in 2:
			var f: Dictionary = feet[k]
			var on_floor: float = x + float(f.foot.x) * scale
			if f.planted:
				if planted_at[k] == INF:
					planted_at[k] = on_floor
					contacts += 1
				var d := on_floor - float(planted_at[k])
				worst = maxf(worst, absf(d))
			elif planted_at[k] != INF:
				var d2 := on_floor - float(planted_at[k])
				total += absf(d2)
				if d2 > 0.5:
					backwards += 0  # (lifted: free to move)
				planted_at[k] = INF
	return {"worst": worst, "contacts": contacts}


## The same for a supporting character's figure (IllustratedCharacter).
func _npc_drift(kind: String, speed: float) -> float:
	var c := IllustratedCharacter.new(kind, {})
	c.facing = Vector2.RIGHT
	var dt := 1.0 / 240.0
	var x := 0.0
	var worst := 0.0
	var at := [INF, INF]
	for i in 240 * 3:
		c.update(dt, Vector2(speed, 0))
		x += speed * dt
		for k in 2:
			var fp: Vector2 = c.foot_pose(-1.0 if k == 0 else 1.0, c._walk * PI, true)
			if fp.y <= 0.001:
				if at[k] == INF:
					at[k] = x + fp.x
				worst = maxf(worst, absf(x + fp.x - float(at[k])))
			else:
				at[k] = INF
	return worst


func test_foot_contact() -> void:
	for kind in ["child", "dress"]:
		print("CONTACT %s figure, 45 px/s: worst drift while planted %.2f px" % [kind, _npc_drift(kind, 45.0)])
	for scale in [1.0, 1.35]:
		for speed in [45.0, 90.0]:
			var r := _drift(speed, scale)
			print("CONTACT scale %.2f, %d px/s: worst drift while planted %.2f px over %d contacts" % [scale, speed, r.worst, r.contacts])
	check(true, "measured")

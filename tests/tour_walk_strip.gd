extends "res://tests/test_case.gd"
## The same walk on any revision, for before/after: Rue walks right across
## Arin's room, then left, then down; a frame every 3 physics ticks.
## Not part of the suite.


func test_walk_strip() -> void:
	var w := await start_session()
	w.director.paused = true
	await wait(0.6)
	w.player.global_position = Vector2(220, 200)
	await wait(0.3)
	var n := 0
	for dir in ["move_right", "move_left", "move_down"]:
		Input.action_press(dir)
		for i in 10:
			for t in 3:
				await tree.physics_frame
			await shot("walk_%02d" % n)
			n += 1
		Input.action_release(dir)
	await wait(0.3)
	await shot("walk_%02d" % n)

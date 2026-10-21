extends "res://tests/test_case.gd"
## Render the actual live portrait at two deterministic mouth-clock phases.

func test_live_portrait_clock_phases() -> void:
	if tree.current_scene != null:
		var previous := tree.current_scene
		tree.current_scene = null
		previous.queue_free()
		await frames(3)
	var backdrop := ColorRect.new()
	backdrop.color = Color("282830")
	backdrop.size = Vector2(640, 360)
	tree.root.add_child(backdrop)
	var view := PortraitView.new()
	view.position = Vector2(250, 100)
	view.size = Vector2(140, 160)
	backdrop.add_child(view)
	view.set_process(false)
	view.portrait = CharacterArt.mira("concerned")
	view.frame = "talk"
	view._figure._t = 0.0
	view.queue_redraw()
	await frames(3)
	await shot("live_portrait_clock_000")
	view._process(0.15)
	await frames(3)
	await shot("live_portrait_clock_150")
	check(absf(view._figure._t - 0.15) < 0.0001, "rendered portrait uses the advanced clock")
	backdrop.queue_free()
	await frames(2)

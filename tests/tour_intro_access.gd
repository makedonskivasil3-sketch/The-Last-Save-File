extends "res://tests/test_case.gd"
## The festival under the accessibility settings (docs/INTRO_REBUILD.md §6):
## large text with the touch controls shown, and the years under reduced
## motion (the static version). Not part of the suite.
##   ... --tour --filter=tour_intro_access --screenshots=DIR


func _festival() -> Prologue:
	var p := Prologue.new()
	p.replay = true
	var old := tree.current_scene
	tree.root.add_child(p)
	tree.current_scene = p
	if old:
		old.queue_free()
	await frames(3)
	return p


func test_large_text_and_touch() -> void:
	settings().large_text = true
	UiStyle.rescale_text(tree)
	var p := await _festival()
	for c in p.get_children():
		if c is TouchControls:
			c.active = true
			c.queue_redraw()
			if c.get("_draw_node"):
				c._draw_node.queue_redraw()
	p.autoplay = true
	await wait_until(func() -> bool: return p.acted.has("lit_1"), 30.0, "the first lantern")
	await wait(0.8)
	await shot("access_large_text_touch")
	settings().large_text = false
	UiStyle.rescale_text(tree)
	p._done = true
	p._handed_off = true
	p.queue_free()
	await frames(2)


func test_reduced_motion_years() -> void:
	settings().reduce_motion = true
	var p := await _festival()
	for i in 4:
		p.lit[i] = true
	p.lit[4] = true
	p._to_beat(Prologue.Beat.TIMELAPSE)
	await wait(6.0)
	await shot("access_reduced_motion_years_6s")
	await wait(10.0)
	await shot("access_reduced_motion_years_16s")
	settings().reduce_motion = false
	p._done = true
	p._handed_off = true
	p.queue_free()
	await frames(2)

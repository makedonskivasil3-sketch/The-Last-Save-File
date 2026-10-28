extends "res://tests/test_case.gd"
## The memory card, captured line by line. Not part of the suite.


func test_cold_open_frames() -> void:
	settings().opening_seen = false
	var title: Node = load("res://scenes/title.tscn").instantiate()
	var old := tree.current_scene
	tree.root.add_child(title)
	tree.current_scene = title
	if old:
		old.queue_free()
	await frames(3)
	title._start()
	await wait_until(func() -> bool: return scene() is ColdOpen, 3.0, "the memory card")
	for i in ColdOpen.LINES.size():
		await wait(2.4)
		await shot("cold_%d" % i)
		await press("interact")
	await wait(1.2)
	await shot("cold_after")

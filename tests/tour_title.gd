extends "res://tests/test_case.gd"
## The title in every state it can be in (docs/VISUAL_DIRECTION.md, pass 8):
## a clean save, some and all memories back, frayed, after an ending, every
## menu button present, large text, a small window, controller focus, touch.
## Each shot also records whether the menu fits the screen.
##   xvfb-run ... -s res://tests/run_tests.gd -- --test-mode --tour --filter=tour_title --screenshots=DIR


func _title(name: String) -> Node:
	tree.change_scene_to_file("res://scenes/title.tscn")
	await wait(1.2)
	var t := scene()
	var panel: Control = t._menu.get_parent()  # the visible panel (inside its full-screen margin)
	var view: Vector2 = t.get_viewport_rect().size
	var r := panel.get_global_rect()
	print("TITLE %s menu %s in %s · fits %s" % [name, r, view, Rect2(Vector2.ZERO, view).encloses(r)])
	check(Rect2(Vector2.ZERO, view).grow(0.5).encloses(r), "%s: the menu fits the screen (%s)" % [name, r])
	await shot(name)
	return t


func _remember(n: int) -> void:
	memory().fragments.clear()
	for f in Story.FRAGMENTS.slice(0, n):
		memory().fragments.append(f.id)


func test_title_states() -> void:
	memory().wipe()
	await _title("t00_clean")
	memory().sessions = 2
	memory().deaths = 1
	memory().purge = 1
	_remember(2)
	await _title("t01_partial")
	_remember(5)
	memory().knows_truth = true
	memory().frayed.append("wren")
	await _title("t02_full_frayed")
	# Everything that can add a button: records, opening, journal.
	memory().wins = 1
	memory().last_ending = "rue"
	memory().endings_seen.append("rue")
	settings().opening_seen = true
	memory().record_read("memory:controller", "memory", "THE SECOND CONTROLLER", "ARIN'S ROOM", ["x"])
	await _title("t03_after_ending_all_buttons")
	settings().large_text = true
	await _title("t04_large_text")
	var t := scene()
	(t._load as Button).grab_focus()
	await frames(4)
	await shot("t05_controller_focus")
	settings().using_touch = true
	await _title("t06_touch")
	settings().using_touch = false
	settings().large_text = false
	settings().opening_seen = false
	tree.root.size = Vector2i(800, 450)
	await _title("t07_small_window")
	tree.root.size = Vector2i(1280, 720)
	await wait(0.3)

extends "res://tests/test_case.gd"
## Actual pause-menu overview, with staged discoveries for layout coverage.

func test_overview_normal_and_large_text() -> void:
	var w := await start_session()
	w.open_pause()
	w._pause_menu._show_map()
	w._pause_menu._map.visited = MapView.NODES.duplicate()
	await frames(4)
	await shot("overview_normal")
	settings().large_text = true
	await frames(4)
	await shot("overview_large")
	w._pause_menu._map.visited = {"room": true, "square": true}
	await frames(4)
	await shot("overview_undiscovered")
	w._pause_menu.close()

extends "res://tests/test_case.gd"

class NotifiedArea:
	extends Area
	var notifications: Array[Rect2] = []
	func geometry_changed(where := Rect2()) -> void:
		notifications.append(where)

func test_retry_accepts_only_exact_numeric_previous_session() -> void:
	var room := ArinsRoom.new()
	room.previous_exit = "death"
	memory().sessions = 4
	for value in [3, 3.0, 3.9, "3", -1, INF, NAN, null, [], {}]:
		memory().deaths_log.assign([{"area": "edge", "x": 300.0, "y": 200.0, "session": value}])
		var valid: bool = (value is int or value is float) and value == 3
		check_eq(room.back_from_the_edge(), valid, "session %s must not be coerced" % str(value))
	memory().deaths_log.assign([{"area": "edge", "x": 300.0, "y": 200.0}])
	check(not room.back_from_the_edge(), "legacy missing metadata grants no false retry")
	room.free()

func test_unchanged_occupancy_does_not_invalidate_paths() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.paused = true
	var grid: NavGrid = w.area.arin.nav()
	var v := grid.version
	grid.refresh()
	grid.refresh(Rect2(300, 280, 10, 10))
	check_eq(grid.version, v, "an unchanged grid must keep paths and watch state valid")

func test_last_subthreshold_crate_movement_is_not_lost() -> void:
	var area := NotifiedArea.new()
	tree.root.add_child(area)
	var prop := DragProp.new()
	area.add_child(prop)
	prop.setup(Rect2(100, 100, 40, 40))
	prop.set_process(false)
	prop._process(0.0)
	var was := prop.rect()
	prop.held = true
	prop.position += Vector2(2, 0)
	prop._process(0.01)
	prop.held = false
	check_eq(area.notifications.size(), 1, "drag completion flushes even a 2 px final movement")
	if not area.notifications.is_empty():
		check(area.notifications[0].encloses(was) and area.notifications[0].encloses(prop.rect()), "both old and new solids are refreshed")
	prop.position += Vector2(1, 0)
	prop._process(0.3)
	prop._process(0.3)
	check_eq(area.notifications.size(), 2, "a settled programmatic correction also flushes")
	for i in 6:
		prop._process(0.3)
	check_eq(area.notifications.size(), 2, "a stationary crate sends no redundant refresh")
	area.queue_free()
	await frames(2)

func test_pending_refresh_can_release_its_area() -> void:
	var area := Area.new()
	tree.root.add_child(area)
	area.set_meta("nav_grid", NavGrid.new())
	var ref: WeakRef = weakref(area)
	area.geometry_changed()
	area.queue_free()
	await frames(5)
	check(ref.get_ref() == null, "pending refresh retains no freed area")

func test_pending_refresh_can_detach_on_the_first_physics_frame() -> void:
	var area := Area.new()
	tree.root.add_child(area)
	area.set_meta("nav_grid", NavGrid.new())
	# World transitions remove the old area before queue_free. Detach before
	# the coroutine resumes from its first wait, while the object still lives.
	tree.physics_frame.connect(func() -> void: tree.root.remove_child(area), CONNECT_ONE_SHOT)
	area.geometry_changed()
	await tree.physics_frame
	await frames(3)
	check(not area.is_inside_tree(), "the transition detached the still-live area")
	check(not area._nav_pending, "a detached refresh releases its pending state")
	area.free()

func test_map_bin_is_east_and_labels_fit_large_text() -> void:
	var map := MapView.new()
	map.size = Vector2(400, 170)
	tree.root.add_child(map)
	check(map._centre("bin").x > map._centre("archive").x, "the Bin lies east of the Archive")
	check(is_equal_approx(map._centre("bin").y, map._centre("archive").y), "the eastward route is horizontal")
	for large in [false, true]:
		settings().large_text = large
		var font := UiStyle.system_font()
		var fs := roundi(8 * Settings.text_scale())
		var boxes: Array[Rect2] = []
		for id in MapView.NODES:
			var box := Rect2(map._centre(id) - MapView.BOX * 0.5, MapView.BOX)
			check(Rect2(Vector2.ZERO, map.size).encloses(box), "box fits: %s" % id)
			for other in boxes:
				check(not other.intersects(box), "area boxes do not overlap")
			boxes.append(box)
			check(font.get_string_size(MapView.NODES[id][0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x <= MapView.BOX.x - 2, "label fits: %s, large=%s" % [id, large])
	map.queue_free()
	await frames(2)

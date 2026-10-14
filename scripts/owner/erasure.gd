class_name Erasure
extends Node2D
## The owner's eraser. Cells of the room get overwritten with nothing,
## growing toward whatever doesn't belong. Freshly erased cells flicker as a
## warning; once they settle they are lethal.

signal caught_player

const CELL := 8
const MATURE_TIME := 0.8
const HUNT_CHANCE := 0.7

var bounds := Rect2()
var target: Node2D
var active := false
## Seconds between growth ticks.
var interval := 0.45
## Cells grown per tick.
var burst := 1

var _cells: Dictionary = {}  # Vector2i -> age (float)
var _cols := 0
var _rows := 0
var _acc := 0.0
var _caught := false
var _t := 0.0


func setup(room_rect: Rect2, player: Node2D) -> void:
	bounds = room_rect
	target = player
	_cols = int(bounds.size.x / CELL)
	_rows = int(bounds.size.y / CELL)


func seed_at(world_pos: Vector2) -> void:
	var c := _to_cell(world_pos)
	if _in_grid(c) and not _cells.has(c):
		_cells[c] = 0.0


func seed_on_edge() -> void:
	var c: Vector2i
	match randi() % 4:
		0: c = Vector2i(randi() % _cols, 0)
		1: c = Vector2i(randi() % _cols, _rows - 1)
		2: c = Vector2i(0, randi() % _rows)
		_: c = Vector2i(_cols - 1, randi() % _rows)
	if not _cells.has(c):
		_cells[c] = 0.0


func cell_count() -> int:
	return _cells.size()


func _process(delta: float) -> void:
	_t += delta
	for c: Vector2i in _cells.keys():
		_cells[c] = float(_cells[c]) + delta
	if active:
		_acc += delta
		while _acc >= interval:
			_acc -= interval
			for i in burst:
				_grow()
	_check_target()
	queue_redraw()


func _grow() -> void:
	if _cells.is_empty():
		seed_on_edge()
		return
	var goal := _to_cell(target.global_position) if is_instance_valid(target) else Vector2i(_cols / 2, _rows / 2)
	var keys: Array = _cells.keys()
	var from: Vector2i = keys.pick_random()
	if randf() < HUNT_CHANCE:
		# Grow from the tip closest to you.
		var best := INF
		for c: Vector2i in keys:
			var d := Vector2(c - goal).length_squared()
			if d < best:
				best = d
				from = c
	var step := from
	var best_score := INF
	for dir: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var n := from + dir
		if not _in_grid(n) or _cells.has(n):
			continue
		var score := Vector2(n - goal).length() + randf() * 3.0
		if score < best_score:
			best_score = score
			step = n
	if step != from:
		_cells[step] = 0.0
	else:
		seed_on_edge()


func _check_target() -> void:
	if _caught or not is_instance_valid(target):
		return
	# Matches the player's 8x8 collider, shrunk a pixel for fairness.
	var p := target.global_position + Vector2(0, 2)
	for corner: Vector2 in [Vector2(-3, -3), Vector2(3, -3), Vector2(-3, 3), Vector2(3, 3)]:
		var c := _to_cell(p + corner)
		if _cells.has(c) and float(_cells[c]) >= MATURE_TIME:
			_caught = true
			caught_player.emit()
			return


func _draw() -> void:
	for c: Vector2i in _cells:
		var age: float = _cells[c]
		var r := Rect2(bounds.position + Vector2(c * CELL), Vector2(CELL, CELL))
		if age < MATURE_TIME:
			var blink := 0.5 + 0.5 * sin(_t * 30.0 + c.x)
			draw_rect(r.grow(-1), Color(0.88, 0.25, 0.2, 0.25 + 0.5 * blink), false, 1.0)
		else:
			draw_rect(r, Color(0.0, 0.0, 0.0))
			if randf() < 0.08:
				var px := r.position + Vector2(randi() % (CELL - 2), randi() % (CELL - 2))
				draw_rect(Rect2(px, Vector2(2, 1)), [Color("e0704f"), Color.WHITE, Color("ff3366")].pick_random())


func _to_cell(world_pos: Vector2) -> Vector2i:
	var local := world_pos - bounds.position
	return Vector2i(floori(local.x / CELL), floori(local.y / CELL))


func _in_grid(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < _cols and c.y < _rows

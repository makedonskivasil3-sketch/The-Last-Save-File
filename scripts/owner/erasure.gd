class_name Erasure
extends Node2D
## The owner's eraser. Cells of the room get overwritten with nothing,
## growing toward whatever doesn't belong. Freshly erased cells flicker as a
## warning; once they settle they are lethal.
##
## Settled cells are drawn by a child layer that only redraws when one is
## added, so a room full of erasure costs almost nothing per frame.

signal caught_player

const CELL := 8
const MATURE_TIME := 0.8
const HUNT_CHANCE := 0.7
const DIRS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const STATIC_COLORS: Array[Color] = [Color("e0704f"), Color.WHITE, Color("ff3366")]

var bounds := Rect2()
var target: Node2D
var active := false
## Seconds between growth ticks.
var interval := 0.45
## Cells grown per tick.
var burst := 1

var _cells: Dictionary = {}     # Vector2i -> true, every erased cell
var _young: Dictionary = {}     # Vector2i -> birth time, still flickering
var _mature: Array[Vector2i] = []
var _frontier: Dictionary = {}  # Vector2i -> true, erased cells with a free neighbour
var _cols := 0
var _rows := 0
var _acc := 0.0
var _caught := false
var _t := 0.0
var _mature_layer: _MatureLayer


func setup(room_rect: Rect2, player: Node2D) -> void:
	bounds = room_rect
	target = player
	_cols = int(bounds.size.x / CELL)
	_rows = int(bounds.size.y / CELL)
	_mature_layer = _MatureLayer.new()
	_mature_layer.owner_erasure = self
	add_child(_mature_layer)


func seed_at(world_pos: Vector2) -> void:
	_add(_to_cell(world_pos))


func seed_on_edge() -> void:
	match randi() % 4:
		0: _add(Vector2i(randi() % _cols, 0))
		1: _add(Vector2i(randi() % _cols, _rows - 1))
		2: _add(Vector2i(0, randi() % _rows))
		_: _add(Vector2i(_cols - 1, randi() % _rows))


func cell_count() -> int:
	return _cells.size()


func _process(delta: float) -> void:
	_t += delta
	_settle_cells()
	if active:
		_acc += delta
		while _acc >= interval:
			_acc -= interval
			for i in burst:
				_grow()
	_check_target()
	queue_redraw()


func _settle_cells() -> void:
	if _young.is_empty():
		return
	var settled := false
	for c: Vector2i in _young.keys():
		if _t - float(_young[c]) >= MATURE_TIME:
			_young.erase(c)
			_mature.append(c)
			settled = true
	if settled:
		_mature_layer.queue_redraw()


func _grow() -> void:
	if _cells.is_empty():
		seed_on_edge()
		return
	if _frontier.is_empty():
		return  # the whole room is gone
	var goal := _to_cell(target.global_position) if is_instance_valid(target) else Vector2i(_cols >> 1, _rows >> 1)
	var keys: Array = _frontier.keys()
	var from: Vector2i = keys.pick_random()
	if randf() < HUNT_CHANCE:
		# Grow from the edge closest to you.
		var best := INF
		for c: Vector2i in keys:
			var d := Vector2(c - goal).length_squared()
			if d < best:
				best = d
				from = c
	var step := from
	var best_score := INF
	for dir in DIRS:
		var n := from + dir
		if not _in_grid(n) or _cells.has(n):
			continue
		var score := Vector2(n - goal).length() + randf() * 3.0
		if score < best_score:
			best_score = score
			step = n
	_add(step)


func _add(c: Vector2i) -> void:
	if not _in_grid(c) or _cells.has(c):
		return
	_cells[c] = true
	_young[c] = _t
	_refresh_frontier(c)
	for dir in DIRS:
		if _cells.has(c + dir):
			_refresh_frontier(c + dir)


func _refresh_frontier(c: Vector2i) -> void:
	for dir in DIRS:
		var n := c + dir
		if _in_grid(n) and not _cells.has(n):
			_frontier[c] = true
			return
	_frontier.erase(c)


func _check_target() -> void:
	if _caught or not is_instance_valid(target):
		return
	# Matches the player's 8x8 collider, shrunk a pixel for fairness.
	var p := target.global_position + Vector2(0, 2)
	for corner: Vector2 in [Vector2(-3, -3), Vector2(3, -3), Vector2(-3, 3), Vector2(3, 3)]:
		var c := _to_cell(p + corner)
		if _cells.has(c) and not _young.has(c):
			_caught = true
			caught_player.emit()
			return


func _draw() -> void:
	# Young cells: a flickering outline, the only warning you get.
	for c: Vector2i in _young:
		var blink := 0.5 + 0.5 * sin(_t * 30.0 * Settings.flash_scale() + c.x)
		draw_rect(_cell_rect(c).grow(-1), Color(0.88, 0.25, 0.2, 0.25 + 0.5 * blink), false, 1.0)
	# A little static crawling over the settled cells.
	if _mature.is_empty():
		return
	for i in mini(int(_mature.size() / 12.0) + 1, 64):
		var r := _cell_rect(_mature.pick_random())
		var px := r.position + Vector2(randi() % (CELL - 2), randi() % (CELL - 2))
		draw_rect(Rect2(px, Vector2(2, 1)), STATIC_COLORS.pick_random())


func _draw_mature(canvas: CanvasItem) -> void:
	for c in _mature:
		canvas.draw_rect(_cell_rect(c), Color.BLACK)


func _cell_rect(c: Vector2i) -> Rect2:
	return Rect2(bounds.position + Vector2(c * CELL), Vector2(CELL, CELL))


func _to_cell(world_pos: Vector2) -> Vector2i:
	var local := world_pos - bounds.position
	return Vector2i(floori(local.x / CELL), floori(local.y / CELL))


func _in_grid(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < _cols and c.y < _rows


## Draws settled cells; redrawn only when the set changes.
class _MatureLayer extends Node2D:
	var owner_erasure: Erasure

	func _ready() -> void:
		show_behind_parent = true

	func _draw() -> void:
		owner_erasure._draw_mature(self)

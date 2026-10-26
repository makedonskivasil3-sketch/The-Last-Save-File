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
## How long a fresh cell flickers before it's lethal, and how often growth
## aims at you (vs. spreading anywhere). Areas tune these (the Edge is
## gentler: it's the finale, not a wall).
var mature_time := MATURE_TIME
var hunt_chance := HUNT_CHANCE
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
var _protected: Dictionary = {}  # Vector2i -> true, cells the eraser can't touch
## Where the static goes is drawn from its own generator, so the frame rate
## (every rendered frame draws random static) can't change its path, and a
## run can be replayed with `rng.seed`.
var rng := RandomNumberGenerator.new()


func setup(room_rect: Rect2, player: Node2D) -> void:
	bounds = room_rect
	target = player
	_cols = int(bounds.size.x / CELL)
	_rows = int(bounds.size.y / CELL)
	_mature_layer = _MatureLayer.new()
	_mature_layer.owner_erasure = self
	add_child(_mature_layer)


## Cells inside `rect` (world space) can never be erased: things the owner
## can't see (Slot 2).
func protect(rect: Rect2) -> void:
	var a := _to_cell(rect.position)
	var b := _to_cell(rect.end)
	for x in range(a.x, b.x + 1):
		for y in range(a.y, b.y + 1):
			_protected[Vector2i(x, y)] = true


## Is this point already void (a settled, lethal cell)?
func is_void(world_pos: Vector2) -> bool:
	var c := _to_cell(world_pos + Vector2(0, 2))
	return _cells.has(c) and not _young.has(c)


## Where the nearest erased cell is (Vector2.INF if none within `radius`).
func nearest_cell(world_pos: Vector2, radius: float) -> Vector2:
	var best := Vector2.INF
	var best_d := radius
	var c0 := _to_cell(world_pos)
	var reach := int(ceil(radius / CELL))
	for x in range(c0.x - reach, c0.x + reach + 1):
		for y in range(c0.y - reach, c0.y + reach + 1):
			var c := Vector2i(x, y)
			if _cells.has(c):
				var p := _cell_rect(c).get_center()
				var d := p.distance_to(world_pos)
				if d < best_d:
					best_d = d
					best = p
	return best


## SCRUB: erased cells within `radius` of a point become floor again.
func scrub(world_pos: Vector2, radius: float) -> int:
	var c0 := _to_cell(world_pos)
	var reach := int(ceil(radius / CELL))
	var removed: Array[Vector2i] = []
	for x in range(c0.x - reach, c0.x + reach + 1):
		for y in range(c0.y - reach, c0.y + reach + 1):
			var c := Vector2i(x, y)
			if _cells.has(c) and _cell_rect(c).get_center().distance_to(world_pos) <= radius:
				removed.append(c)
	for c in removed:
		_cells.erase(c)
		_young.erase(c)
		_frontier.erase(c)
		_mature.erase(c)
	for c in removed:
		for dir in DIRS:
			if _cells.has(c + dir):
				_refresh_frontier(c + dir)
	if not removed.is_empty():
		_mature_layer.queue_redraw()
	return removed.size()


func seed_at(world_pos: Vector2) -> void:
	_add(_to_cell(world_pos))


func seed_on_edge() -> void:
	match rng.randi() % 4:
		0: _add(Vector2i(rng.randi() % _cols, 0))
		1: _add(Vector2i(rng.randi() % _cols, _rows - 1))
		2: _add(Vector2i(0, rng.randi() % _rows))
		_: _add(Vector2i(_cols - 1, rng.randi() % _rows))


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
		if _t - float(_young[c]) >= mature_time:
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
	var from: Vector2i = keys[rng.randi() % keys.size()]
	if rng.randf() < hunt_chance:
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
		var score := Vector2(n - goal).length() + rng.randf() * 3.0
		if score < best_score:
			best_score = score
			step = n
	_add(step)


func _add(c: Vector2i) -> void:
	if not _in_grid(c) or _cells.has(c):
		return
	_cells[c] = true
	_young[c] = _t
	if active:
		Sfx.erase_tick()
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
	var flash := Settings.flash_scale()
	# Young cells: the only warning you get. A red frame that strobes while a
	# black core grows inside it; when the core fills the cell, it's lethal.
	for c: Vector2i in _young:
		var r := _cell_rect(c)
		var age := clampf((_t - float(_young[c])) / mature_time, 0.0, 1.0)
		var blink := 0.5 + 0.5 * sin(_t * 30.0 * flash + c.x * 1.7)
		draw_rect(r, Color(0.9, 0.12, 0.08, (0.12 + 0.25 * blink) * (0.5 + 0.5 * flash)))
		draw_rect(r.grow(-1), Color(1.0, 0.3, 0.2, 0.35 + 0.55 * blink), false, 1.0)
		var core := r.grow(-CELL * 0.5 * (1.0 - age))
		draw_rect(core, Color(0.0, 0.0, 0.0, 0.6 + 0.4 * age))
	if _mature.is_empty():
		return
	# The bite edge: settled cells that still touch the world burn dark red,
	# so the void reads as hungry rather than painted.
	var rim := Color(0.55, 0.02, 0.04, 0.55 + 0.25 * sin(_t * 4.0))
	for c: Vector2i in _frontier:
		if _young.has(c):
			continue
		var r := _cell_rect(c)
		for dir in DIRS:
			if _cells.has(c + dir) or not _in_grid(c + dir):
				continue
			match dir:
				Vector2i.LEFT: draw_rect(Rect2(r.position, Vector2(1, CELL)), rim)
				Vector2i.RIGHT: draw_rect(Rect2(r.position + Vector2(CELL - 1, 0), Vector2(1, CELL)), rim)
				Vector2i.UP: draw_rect(Rect2(r.position, Vector2(CELL, 1)), rim)
				_: draw_rect(Rect2(r.position + Vector2(0, CELL - 1), Vector2(CELL, 1)), rim)
	# Static crawling over the void; the occasional bright scar line.
	for i in mini(int(_mature.size() / 10.0) + 1, 80):
		var r := _cell_rect(_mature.pick_random())
		var px := r.position + Vector2(randi() % (CELL - 2), randi() % (CELL - 2))
		draw_rect(Rect2(px, Vector2(2, 1)), STATIC_COLORS.pick_random())
	if randf() < 0.08 * flash * Settings.glitch_intensity:
		var r := _cell_rect(_mature.pick_random())
		draw_rect(Rect2(Vector2(r.position.x - 24, r.position.y + randi() % CELL), Vector2(56, 1)), Color(1, 0.2, 0.5, 0.7))


func _draw_mature(canvas: CanvasItem) -> void:
	# Pure black void, with a faint deep-red grain baked in once per change.
	for c in _mature:
		var r := _cell_rect(c)
		canvas.draw_rect(r, Color.BLACK)
		if (c.x * 7 + c.y * 13) % 5 == 0:
			canvas.draw_rect(Rect2(r.position + Vector2((c.x * 3) % 6, (c.y * 5) % 6), Vector2(1, 1)), Color(0.25, 0.0, 0.05))


func _cell_rect(c: Vector2i) -> Rect2:
	return Rect2(bounds.position + Vector2(c * CELL), Vector2(CELL, CELL))


func _to_cell(world_pos: Vector2) -> Vector2i:
	var local := world_pos - bounds.position
	return Vector2i(floori(local.x / CELL), floori(local.y / CELL))


func _in_grid(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < _cols and c.y < _rows and not _protected.has(c)


## Draws settled cells; redrawn only when the set changes.
class _MatureLayer extends Node2D:
	var owner_erasure: Erasure

	func _ready() -> void:
		show_behind_parent = true

	func _draw() -> void:
		owner_erasure._draw_mature(self)

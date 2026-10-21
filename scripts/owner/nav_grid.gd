class_name NavGrid
extends RefCounted
## Where Arin can stand and how to get between two places, for one area
## (docs/GAMEPLAY_CONSISTENCY.md, pass 6). A grid of CELL px over the area's
## bounds; a cell is open when a circle of Arin's radius (plus a margin)
## centred on it touches no solid: walls, furniture, missing-texture blocks.
## People don't count (Arin walks past them). Built once per area from the
## same physics bodies that stop Rue, and rebuilt when the geometry changes
## (a door, dragged crates).

const CELL := 8.0
## Extra room beyond the radius, so a path never grazes a corner.
const MARGIN := 1.0

var bounds := Rect2()
var radius := 4.0
## Goes up on a build or actual occupancy change: anything
## holding a path from an older version plans again.
var version := 0
var _astar := AStarGrid2D.new()
var _space: PhysicsDirectSpaceState2D
var _mask := 1
var _exclude: Array[RID] = []
var _clear_shape := CircleShape2D.new()
var _clear_query := PhysicsShapeQueryParameters2D.new()
var _sweep_shape := CircleShape2D.new()
var _sweep_query := PhysicsShapeQueryParameters2D.new()


## Build the grid. `exclude`: bodies that don't block (Rue, people).
func build(space: PhysicsDirectSpaceState2D, area_bounds: Rect2, mask: int, exclude: Array[RID], body_radius: float) -> void:
	_space = space
	bounds = area_bounds
	radius = body_radius
	_mask = mask
	_exclude = exclude
	_astar.region = Rect2i(0, 0, ceili(bounds.size.x / CELL), ceili(bounds.size.y / CELL))
	_astar.cell_size = Vector2(CELL, CELL)
	_astar.offset = bounds.position + Vector2(CELL, CELL) * 0.5
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()
	_mark(Rect2i(Vector2i.ZERO, _astar.region.size))
	version += 1


## The level changed inside `where` (a door, a crate, an opening): re-check
## just those cells (and a body's width around them). An empty rect re-checks
## everything. Call it once physics has the new collision state (deferred
## shape changes land on the next physics frame; Area.geometry_changed waits
## for that).
func refresh(where := Rect2()) -> void:
	if _space == null:
		return
	var changed := false
	if where.size == Vector2.ZERO:
		changed = _mark(Rect2i(Vector2i.ZERO, _astar.region.size))
	else:
		var r := where.grow(radius + MARGIN + CELL)
		var a := _cell(r.position)
		var b := _cell(r.end)
		changed = _mark(Rect2i(a, b - a + Vector2i.ONE))
	if changed:
		version += 1


func _mark(cells: Rect2i) -> bool:
	var changed := false
	for x in range(cells.position.x, cells.end.x):
		for y in range(cells.position.y, cells.end.y):
			var c := Vector2i(x, y)
			var solid := not clear(_astar.get_point_position(c))
			if _astar.is_point_solid(c) != solid:
				_astar.set_point_solid(c, solid)
				changed = true
	return changed


## Can a body sweep in a straight line from `a` to `b` without touching a
## solid (the margin included)? The exact first and last steps of a path use
## it: an exact point is only kept when the step to it is safe.
func sweep_clear(a: Vector2, b: Vector2) -> bool:
	if _space == null or a.distance_to(b) < 0.01:
		return true
	var q := _sweep_query
	var circle := _sweep_shape
	circle.radius = radius + MARGIN * 0.5
	q.shape = circle
	q.transform = Transform2D(0.0, a)
	q.motion = b - a
	q.collision_mask = _mask
	q.exclude = _exclude
	var r := _space.cast_motion(q)
	return r.size() == 0 or r[0] >= 1.0


## Is a circle of the body's radius (plus MARGIN) at `p` inside the area and
## touching nothing solid? The one clearance rule for destinations, paths
## and recovery.
func clear(p: Vector2, extra := MARGIN) -> bool:
	var r := radius + extra
	if not bounds.grow(-r).has_point(p):
		return false
	if _space == null:
		return true
	var q := _clear_query
	var circle := _clear_shape
	circle.radius = r
	q.shape = circle
	q.transform = Transform2D(0.0, p)
	q.collision_mask = _mask
	q.exclude = _exclude
	return _space.intersect_shape(q, 1).is_empty()


func _cell(p: Vector2) -> Vector2i:
	var c := Vector2i(floori((p.x - bounds.position.x) / CELL), floori((p.y - bounds.position.y) / CELL))
	return c.clamp(Vector2i.ZERO, _astar.region.size - Vector2i.ONE)


func _open(c: Vector2i) -> bool:
	return _astar.is_in_boundsv(c) and not _astar.is_point_solid(c)


## The nearest open cell to `p` within `max_dist` px (its centre), else INF.
func nearest_open(p: Vector2, max_dist := 40.0) -> Vector2:
	var c := _cell(p)
	if _open(c) and clear(p):
		return p  # already clear: keep the exact point
	var best := Vector2.INF
	var steps := ceili(max_dist / CELL)
	for ring in range(0, steps + 1):
		for dx in range(-ring, ring + 1):
			for dy in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dy)) != ring:
					continue
				var n := c + Vector2i(dx, dy)
				if _open(n):
					var pos := _astar.get_point_position(n)
					if pos.distance_to(p) <= max_dist and (best == Vector2.INF or pos.distance_to(p) < best.distance_to(p)):
						best = pos
		if best != Vector2.INF:
			return best
	return Vector2.INF


## A walk from `from` to `to` around solids: points to visit in order, ending
## at `to` itself when it can be reached. Empty when `from` has no open cell
## nearby. `partial`: when `to` can't be reached, end at the reachable cell
## closest to it instead (and `reaches(...)` says so).
func path(from: Vector2, to: Vector2, partial := true) -> PackedVector2Array:
	var a := nearest_open(from, 24.0)
	var b := nearest_open(to, 24.0)
	if a == Vector2.INF:
		return PackedVector2Array()
	var target := _cell(b) if b != Vector2.INF else _cell(to)
	var pts := _astar.get_point_path(_cell(a), target, partial)
	if pts.is_empty():
		return pts
	# Exact ends instead of cell centres, but only when the straight step
	# to them is safe for the whole body; otherwise the cell centre stays.
	var start := a if a.distance_to(from) > 0.5 else from
	if pts.size() < 2 or sweep_clear(start, pts[1]):
		pts[0] = start
	var last := pts.size() - 1
	if b != Vector2.INF and _cell(pts[last]) == _cell(b):
		var before := pts[last - 1] if last > 0 else start
		if sweep_clear(before, b):
			pts[last] = b
	return pts


## Can a body at `from` walk to `to` (within 24 px of it, on open floor)?
func reaches(from: Vector2, to: Vector2) -> bool:
	var b := nearest_open(to, 24.0)
	if b == Vector2.INF:
		return false
	var pts := path(from, b, false)
	return not pts.is_empty()

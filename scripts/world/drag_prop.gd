class_name DragProp
extends StaticBody2D
## Something solid the owner's cursor can grab and drag across the world to
## block your way (the square's crate stack). You can PHASE through it, or
## wait for the owner to drag it back.

var size := Vector2(40, 40)
## Where it lives when nobody is dragging it.
var home := Vector2.ZERO
## Being carried by the cursor right now.
var held := false

var _t := 0.0


func setup(rect: Rect2) -> void:
	size = rect.size
	position = rect.get_center()
	home = position
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func rect() -> Rect2:
	return Rect2(global_position - size * 0.5, size)


## Where walkers last heard the stack was (moves under NOTIFY_STEP px are
## merged: a drag is one refresh every NOTIFY_EVERY s, not one a frame).
const NOTIFY_STEP := 4.0
const NOTIFY_EVERY := 0.25
var _told_at := Vector2.INF
var _tell_left := 0.0


func _process(delta: float) -> void:
	_t += delta
	_tell_left = maxf(0.0, _tell_left - delta)
	if _told_at == Vector2.INF:
		_told_at = global_position
	elif _tell_left <= 0.0 and _told_at.distance_to(global_position) > NOTIFY_STEP:
		# Where it was is open again; where it is now is blocked.
		var was := Rect2(_told_at - size * 0.5, size)
		Area.notify_geometry(self, was.merge(rect()))
		_told_at = global_position
		_tell_left = NOTIFY_EVERY
	queue_redraw()


func _draw() -> void:
	var r := Rect2(-size * 0.5, size)
	# A stack of crates seen from above: a lit lid, a slatted front face.
	var top := Decor.furniture(self, r, Color("8a6a48"), 8.0)
	for i in 3:
		var x := top.position.x + (i + 1) * top.size.x / 4.0
		draw_line(Vector2(x, top.position.y + 1), Vector2(x, top.end.y - 1), Color("6a4e34"), 0.8)
	draw_line(top.position + Vector2(2, 2), top.end - Vector2(2, 2), Color("6a4e34"), 1.0)
	for i in 2:
		var y := top.end.y + 2.6 + i * 2.6
		draw_line(Vector2(r.position.x + 1, y), Vector2(r.end.x - 1, y), Color("3a2a20"), 0.6)
	if held:
		# Selected by the owner: marching ants and a pale highlight.
		draw_rect(r, Color(0.55, 0.8, 1.0, 0.15))
		var phase := fmod(_t * 20.0, 4.0)
		var x := r.position.x + phase
		while x < r.end.x:
			draw_line(Vector2(x, r.position.y - 1), Vector2(minf(x + 2, r.end.x), r.position.y - 1), Color.WHITE)
			draw_line(Vector2(x, r.end.y + 1), Vector2(minf(x + 2, r.end.x), r.end.y + 1), Color.WHITE)
			x += 4.0

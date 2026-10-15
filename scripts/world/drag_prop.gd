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


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var r := Rect2(-size * 0.5, size)
	# A stack of crates: three rows of planks.
	draw_rect(r, Color("5a4632"))
	for i in 3:
		var y := r.position.y + (i + 1) * r.size.y / 3.0
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color("3a2a20"), 1.0)
	draw_line(r.position, r.end, Color("4a3828"), 1.0)
	draw_rect(r, Color("3a2a20"), false, 1.0)
	if held:
		# Selected by the owner: marching ants and a pale highlight.
		draw_rect(r, Color(0.55, 0.8, 1.0, 0.15))
		var phase := fmod(_t * 20.0, 4.0)
		var x := r.position.x + phase
		while x < r.end.x:
			draw_line(Vector2(x, r.position.y - 1), Vector2(minf(x + 2, r.end.x), r.position.y - 1), Color.WHITE)
			draw_line(Vector2(x, r.end.y + 1), Vector2(minf(x + 2, r.end.x), r.end.y + 1), Color.WHITE)
			x += 4.0

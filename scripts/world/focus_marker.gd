class_name FocusMarker
extends Node2D
## Corner brackets around whatever [E] would act on right now, so it's never a
## guess which thing you're about to talk to, read or climb into.

var target: Node2D

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	visible = is_instance_valid(target)
	if visible:
		global_position = target.global_position
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var s := 11.0 + sin(_t * 6.0) * 1.5
	var r := Rect2(Vector2(-s, -s - 6), Vector2(s, s) * 2.0)
	var c := Color(0.55, 0.95, 1.0, 0.85)
	var k := 4.0
	for corner in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var dx := k if corner.x == r.position.x else -k
		var dy := k if corner.y == r.position.y else -k
		draw_line(corner, corner + Vector2(dx, 0), c, 1.0)
		draw_line(corner, corner + Vector2(0, dy), c, 1.0)

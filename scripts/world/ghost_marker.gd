class_name GhostMarker
extends Node2D
## Where you died before. The owner kept a record. So does the floor.

const COL := Color("8cf2ff")

var index := 0
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var a := 0.12 + 0.06 * sin(_t * 1.3 + index)
	draw_rect(Rect2(-4, -10, 8, 16), Color(COL, a), false, 1.0)
	draw_line(Vector2(-6, 7), Vector2(6, 7), Color(COL, a))
	draw_string(UiStyle.system_font(), Vector2(-12, 16), "#%d" % (index + 1), HORIZONTAL_ALIGNMENT_CENTER, 24, 7, Color(COL, a * 1.5))

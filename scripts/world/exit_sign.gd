class_name ExitSign
extends Node2D
## A small in-world label at a way out: where it goes, with an arrow. Dim and
## crossed out while the way is closed.

var text := ""
## Which way the arrow points.
var direction := Vector2.RIGHT
## Returns bool: is this way open right now? (Always open if not set.)
var is_open: Callable

const COL := Color("c8b8a0")
const CLOSED := Color("8a8f98")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var open: bool = not is_open.is_valid() or is_open.call()
	var c := COL if open else CLOSED
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	# Label centred on the sign, arrow on the side it points to.
	var box := Rect2(Vector2(-w * 0.5 - 3, -6), Vector2(w + 6, 9))
	draw_rect(box, Color(0, 0, 0, 0.55))
	draw_string(font, Vector2(-w * 0.5, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(c, 0.9 if open else 0.6))
	var tip := direction * (w * 0.5 + 9.0) if direction.x != 0.0 else direction * 11.0
	if direction.y != 0.0:
		tip += Vector2(0, -1.5)
	var side := Vector2(-direction.y, direction.x) * 3.0
	draw_colored_polygon(PackedVector2Array([tip + direction * 3.0, tip + side, tip - side]), Color(c, 0.9 if open else 0.5))
	if not open:
		draw_line(box.position + Vector2(0, 4), box.end - Vector2(0, 5), Color(0.9, 0.3, 0.3, 0.7), 1.0)

class_name Readable
extends Node2D
## Something you can read: a book, a sign, a log. Opens in the dialogue box.

## RECORD: one of the Archive's readable records, an open book on a small
## stand, so it never looks like the shelf's decorative spines.
enum Look { BOOK, SIGN, TERMINAL, RECORD }

var title := "BOOK"
var prompt := "read"
var look: Look = Look.BOOK
## Returns Array[String].
var lines_provider: Callable
var awareness_cost := 0.0
var color := Color("c8b8a0")
## Callable() -> bool: while true, a slow cyan pulse marks this as what the
## story points at now (the CHARACTER FILE once the file is the next step).
var emphasis: Callable
## Callable() -> bool: true once Rue has read it (drawn a little dimmer).
var was_read: Callable

var _t := 0.0


func can_interact() -> bool:
	return lines_provider.is_valid()


func interact_prompt() -> String:
	return prompt


## What this is, shown small over the prompt (World.object_name).
func interact_name() -> String:
	return title


func interact() -> Dictionary:
	return {"speaker": title, "color": color, "lines": lines_provider.call()}


func _process(delta: float) -> void:
	_t += delta
	if look == Look.TERMINAL or look == Look.RECORD or emphasis.is_valid():
		queue_redraw()


func _draw() -> void:
	if emphasis.is_valid() and emphasis.call():
		var k := 0.5 + 0.5 * sin(_t * 2.2)
		draw_arc(Vector2.ZERO, 10.0 + 2.0 * k, 0.0, TAU, 24, Color(0.55, 0.95, 1.0, 0.25 + 0.35 * k), 1.0)
	match look:
		Look.RECORD:
			var read: bool = was_read.is_valid() and was_read.call()
			var page := Color("e8dcc4") if not read else Color("b8ad98")
			draw_circle(Vector2(0, 4), 9.0, Color(1.0, 0.85, 0.6, 0.06 if read else 0.12))  # a pool of light
			draw_rect(Rect2(-1, 0, 2, 5), Color("4f3a2c"))  # the stand
			draw_colored_polygon(PackedVector2Array([Vector2(-7, -3), Vector2(0, -1), Vector2(7, -3), Vector2(6, 1), Vector2(0, 2), Vector2(-6, 1)]), Decor.INK)
			draw_colored_polygon(PackedVector2Array([Vector2(-6, -2.5), Vector2(-0.5, -0.8), Vector2(-0.5, 1.2), Vector2(-5.5, 0.4)]), page)
			draw_colored_polygon(PackedVector2Array([Vector2(6, -2.5), Vector2(0.5, -0.8), Vector2(0.5, 1.2), Vector2(5.5, 0.4)]), page)
			draw_line(Vector2(1.5, 1.0), Vector2(1.5, 4.0), Color("c0392b"), 1.0)  # the ribbon
		Look.BOOK:
			draw_rect(Rect2(-4, -3, 8, 6), Color("6b3a2c"))
			draw_rect(Rect2(-3, -2, 1, 4), Color("c8b8a0"))
		Look.SIGN:
			draw_rect(Rect2(-1, 0, 2, 8), Color("4f3a2c"))
			draw_rect(Rect2(-8, -6, 16, 7), Color("6b5546"))
		Look.TERMINAL:
			draw_rect(Rect2(-6, -5, 12, 9), Color("1a1f24"))
			var on := fmod(_t, 1.0) < 0.6
			draw_rect(Rect2(-4, -3, 8, 1), Color("8cf2ff", 0.8 if on else 0.3))
			draw_rect(Rect2(-4, -1, 5, 1), Color("8cf2ff", 0.5))

class_name Readable
extends Node2D
## Something you can read: a book, a sign, a log. Opens in the dialogue box.

enum Look { BOOK, SIGN, TERMINAL }

var title := "BOOK"
var prompt := "read"
var look: Look = Look.BOOK
## Returns Array[String].
var lines_provider: Callable
var awareness_cost := 0.0
var color := Color("c8b8a0")

var _t := 0.0


func can_interact() -> bool:
	return lines_provider.is_valid()


func interact_prompt() -> String:
	return prompt


func interact() -> Dictionary:
	return {"speaker": title, "color": color, "lines": lines_provider.call()}


func _process(delta: float) -> void:
	_t += delta
	if look == Look.TERMINAL:
		queue_redraw()


func _draw() -> void:
	match look:
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

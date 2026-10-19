class_name Husk
extends Readable
## The body Rue stepped out of (docs/DARK_TRUTH_DESIGN.md, layer B): her
## shape, emptied, left where she stood. Readable, like a file.


func _init() -> void:
	title = Story.HUSK_TITLE
	prompt = "look"
	look = Look.SIGN  # not kept in the journal: it's a body, not a page
	lines_provider = func() -> Array: return Story.HUSK_LINES.duplicate()


func _draw() -> void:
	var ghost := Color(0.6, 0.65, 0.7, 0.45 + 0.1 * sin(_t * 2.0))
	# Lying on its side: head, body, the empty outline of a raincoat.
	draw_circle(Vector2(-7, -2), 3.0, ghost)
	draw_rect(Rect2(-4, -4, 11, 5), ghost)
	draw_rect(Rect2(-9, -6, 18, 9), Color(0.6, 0.65, 0.7, 0.25), false, 1.0)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

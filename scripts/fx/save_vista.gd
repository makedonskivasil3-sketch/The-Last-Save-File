class_name SaveVista
extends Control
## A small diorama of a save that is still running behind the load menu.
## No assets, flashes, or input capture; the centre stays quiet for the menu.
var elapsed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var scale_to_view := size / Vector2(640, 360)
	draw_set_transform(Vector2.ZERO, 0.0, scale_to_view)
	draw_rect(Rect2(0, 0, 640, 360), Color("090d15"))
	# Warm remembered world at left; cold, unwritten space at right.
	for i in 12:
		var a := 0.018 * (1.0 - float(i) / 12.0)
		draw_circle(Vector2(74, 115), 24.0 + i * 12.0, Color(1.0, 0.65, 0.32, a))
	for layer in 3:
		var y := 204.0 + layer * 34.0
		var col := Color("141c25").lightened(layer * 0.018)
		for i in 9:
			var x := float(i * 84 - 30)
			var height := 24.0 + fmod(float(i * 37 + layer * 19), 49.0)
			draw_rect(Rect2(x, y - height, 64, 360 - y + height), col)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 5, y - height), Vector2(x + 32, y - height - 22), Vector2(x + 69, y - height)]), col)
			if i < 2:
				draw_rect(Rect2(x + 22, y - height + 12, 8, 12), Color(0.9, 0.65, 0.33, 0.22))
	# An empty slot: the missing half of the remembered skyline.
	for y in range(100, 302, 18):
		draw_line(Vector2(508, y), Vector2(598, y), Color(0.45, 0.7, 0.8, 0.06))
	for x in range(508, 599, 18):
		draw_line(Vector2(x, 100), Vector2(x, 300), Color(0.45, 0.7, 0.8, 0.06))
	for i in 28:
		var x := fposmod(i * 97.0 + elapsed * (1.5 + i % 3), 640.0)
		var y := fposmod(i * 53.0 - elapsed * 2.0, 360.0)
		# Keep dust away from the menu's text.
		if x < 154.0 or x > 486.0:
			draw_rect(Rect2(x, y, 1, 1), Color(0.8, 0.75, 0.6, 0.16))
	# Dark centre preserves contrast at all text sizes.
	draw_rect(Rect2(152, 0, 336, 360), Color(0.025, 0.025, 0.04, 0.75))

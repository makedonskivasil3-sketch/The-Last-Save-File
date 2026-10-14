class_name SlotTwo
extends Area2D
## An empty save slot the owner forgot about. The last save file.

signal reached

var _t := 0.0
var _done := false


func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 9.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _physics_process(_delta: float) -> void:
	if _done:
		return
	for body in get_overlapping_bodies():
		if body is Player:
			_done = true
			reached.emit()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var bob := sin(_t * 2.0) * 2.0
	for i in 3:
		draw_circle(Vector2(0, bob), 10.0 + i * 6.0 + sin(_t * 3.0 + i) * 2.0, Color(0.55, 0.95, 1.0, 0.06))
	draw_rect(Rect2(Vector2(-7, -9 + bob), Vector2(14, 18)), Color("0c1a1f"))
	draw_rect(Rect2(Vector2(-7, -9 + bob), Vector2(14, 18)), Color("8cf2ff"), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(-6, 3 + bob), "02", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("8cf2ff"))
	draw_string(ThemeDB.fallback_font, Vector2(-30, 24), "SLOT 2 · EMPTY", HORIZONTAL_ALIGNMENT_CENTER, 60, 7, Color("8cf2ff", 0.7))

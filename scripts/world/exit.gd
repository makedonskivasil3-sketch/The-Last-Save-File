class_name Exit
extends Area2D
## A way from one area to another. Closed exits explain why when touched.

signal used(exit: Exit)
signal blocked(exit: Exit)

var target_area := ""
## Which entry point to use in the target area.
var arrival := ""
var open := true
var blocked_message := ""
var size := Vector2(16, 16)

var _was_inside := false


func setup(rect: Rect2, target: String, arrive_at: String) -> void:
	position = rect.get_center()
	size = rect.size
	target_area = target
	arrival = arrive_at
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _physics_process(_delta: float) -> void:
	var inside := false
	for body in get_overlapping_bodies():
		if body is Player:
			inside = true
	if inside and not _was_inside:
		if open:
			used.emit(self)
		else:
			blocked.emit(self)
	_was_inside = inside

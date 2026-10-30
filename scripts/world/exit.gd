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
var inward := Vector2.ZERO
var _retry := 0.0
const RETRY := 0.3


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
	queue_redraw()
	var inside := false
	for body in get_overlapping_bodies():
		if body is Player:
			inside = true
	if inside and not _was_inside:
		_retry = RETRY
		if open:
			used.emit(self)
		else:
			blocked.emit(self)
	elif inside and open:
		# Still standing in it (the move was refused, e.g. waiting for Wren):
		# try again every so often.
		_retry -= _delta
		if _retry <= 0.0:
			_retry = RETRY
			used.emit(self)
	_was_inside = inside


## A shared stone threshold continues the walking plane into each room.
## Ordinary crossings look like doors, not corruption or a reset.
func _draw() -> void:
	if inward == Vector2.ZERO:
		return
	var across := inward.orthogonal()
	var width := minf(26.0, maxf(size.x, size.y) - 4.0)
	var c := Color("d8bb82") if open else Color("7a6464")
	for step: float in [5.0, 10.0, 15.0]:
		var at := inward * step
		draw_line(at - across * width * 0.5, at + across * width * 0.5, Color(c, 0.28), 1.0)
	var tip := inward * 9.0
	if open:
		draw_polyline(PackedVector2Array([tip + inward * 4.0 - across * 3.0, tip, tip + inward * 4.0 + across * 3.0]), Color(c, 0.75), 1.0)

class_name SavePoint
extends StaticBody2D
## The owner's save crystal. It does not recognize you.

const CRYSTAL := Color("7fd6a8")
const DENIED := Color("e0704f")

var _t := 0.0
var _denied := 0.0
var _uses := 0


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 6)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, 4)
	add_child(col)


func can_interact() -> bool:
	return true


func interact_prompt() -> String:
	return "save"


func interact() -> String:
	_denied = 1.0
	_uses += 1
	if _uses == 1:
		return "SAVE FAILED: profile mismatch."
	return "SAVE DENIED: you are not the owner of this file."


func _process(delta: float) -> void:
	_t += delta
	_denied = maxf(0.0, _denied - delta)
	queue_redraw()


func _draw() -> void:
	var bob := sin(_t * 2.0) * 1.5
	var c := CRYSTAL.lerp(DENIED, _denied)
	var pts := PackedVector2Array([
		Vector2(0, -12 + bob), Vector2(5, -4 + bob), Vector2(0, 4 + bob), Vector2(-5, -4 + bob)
	])
	draw_colored_polygon(pts, c)
	draw_circle(Vector2(0, 7), 5.0, Color(c, 0.15))
	draw_rect(Rect2(-6, 5, 12, 3), Color("3a302b"))

class_name OwnerCursor
extends Node2D
## The owner's mouse pointer, reaching into the world. It drifts, then homes
## in when it can see you. Hold still under it too long and you get selected.
## Selected things get deleted.

signal selected_player

const SELECT_TIME := 1.1

var bounds := Rect2()
var player: Node2D
var is_hidden: Callable
var speed := 55.0

var _goal := Vector2.ZERO
var _select := 0.0
var _t := 0.0
var _done := false


func _ready() -> void:
	_goal = _random_point()


func _physics_process(delta: float) -> void:
	_t += delta
	var visible_target: bool = is_instance_valid(player) and not (is_hidden.is_valid() and is_hidden.call(player.global_position))
	if visible_target:
		_goal = player.global_position
	elif position.distance_to(_goal) < 6.0:
		_goal = _random_point()
	var to := _goal - position
	var spd := speed if visible_target else speed * 0.6
	position += to.normalized() * minf(spd * delta, to.length())

	var over: bool = visible_target and player.global_position.distance_to(position) < 12.0
	_select = clampf(_select + (delta if over else -delta * 2.0), 0.0, SELECT_TIME)
	if _select >= SELECT_TIME and not _done:
		_done = true
		selected_player.emit()


func _random_point() -> Vector2:
	return Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _select > 0.0:
		var s := 6.0 + 10.0 * (1.0 - _select / SELECT_TIME)
		var r := Rect2(-Vector2(s, s), Vector2(s, s) * 2.0)
		draw_rect(r, Color(0.55, 0.8, 1.0, 0.15))
		draw_rect(r, Color(0.55, 0.8, 1.0, 0.9), false, 1.0)
	# A plain arrow pointer, much bigger than anything in the world.
	var arrow := PackedVector2Array([
		Vector2(0, 0), Vector2(0, 17), Vector2(4, 13), Vector2(7, 20),
		Vector2(10, 19), Vector2(7, 12), Vector2(12, 12),
	])
	var outline := arrow.duplicate()
	outline.append(Vector2.ZERO)
	draw_colored_polygon(arrow, Color.WHITE)
	draw_polyline(outline, Color.BLACK, 1.0)

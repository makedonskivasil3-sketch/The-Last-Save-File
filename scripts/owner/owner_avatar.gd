class_name OwnerAvatar
extends Node2D
## Arin, driven by the owner. Walks a route through the area and looks where
## it walks. If it sees you, the owner's awareness climbs fast. If it walks
## into you, you're overwritten.

signal sees_player(delta: float)
signal touched_player

const BODY := Color("5a7fb0")
const HAIR := Color("2a2a30")
const SKIN := Color("e8c48a")
const VIEW_COL := Color(0.88, 0.44, 0.31)

var route: Array[Vector2] = []
var speed := 40.0
var view_distance := 85.0
var view_angle := deg_to_rad(70.0)
var player: Node2D
## Callable(Vector2) -> bool: true if the position is hidden from the owner.
var is_hidden: Callable
var paused := false

var _target := 0
var _facing := Vector2.RIGHT
var _seeing := false
var _wait := 0.0


func _physics_process(delta: float) -> void:
	if route.is_empty() or paused:
		return
	if _wait > 0.0:
		_wait -= delta
	else:
		_target %= route.size()  # the route may have been changed under us
		var goal := route[_target]
		var to := goal - position
		if to.length() < 2.0:
			_target = (_target + 1) % route.size()
			_wait = 0.6  # pauses at corners, looking around
		else:
			_facing = _facing.lerp(to.normalized(), minf(1.0, delta * 6.0)).normalized()
			position += to.normalized() * minf(speed * delta, to.length())
	_seeing = can_see(player.global_position) if is_instance_valid(player) else false
	if _seeing:
		sees_player.emit(delta)
	if is_instance_valid(player) and player.global_position.distance_to(global_position) < 8.0:
		touched_player.emit()


func can_see(pos: Vector2) -> bool:
	var to := pos - global_position
	if to.length() > view_distance:
		return false
	if absf(_facing.angle_to(to)) > view_angle * 0.5:
		return false
	return not (is_hidden.is_valid() and is_hidden.call(pos))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# View cone: faint, brighter when it has you.
	var a := 0.18 if _seeing else 0.06
	var pts := PackedVector2Array([Vector2.ZERO])
	for i in 9:
		var ang := _facing.angle() - view_angle * 0.5 + view_angle * i / 8.0
		pts.append(Vector2.from_angle(ang) * view_distance)
	draw_colored_polygon(pts, Color(VIEW_COL, a))
	draw_rect(Rect2(-4, -5, 8, 11), BODY)
	draw_rect(Rect2(-3, -10, 6, 5), SKIN)
	draw_rect(Rect2(-4, -11, 8, 2), HAIR)
	if _seeing:
		draw_string(ThemeDB.fallback_font, Vector2(-2, -14), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VIEW_COL)

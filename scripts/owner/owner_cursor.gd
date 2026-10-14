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
var _tracking := false
var _trail: Array[Vector2] = []
var _arrive := 1.0  # 1 -> 0 as it materialises
var _fx: ScreenFx
var _t := 0.0
var _done := false


func _ready() -> void:
	_goal = _random_point()
	_fx = get_tree().get_first_node_in_group("screen_fx") as ScreenFx
	if _fx:
		_fx.cursor_arrives()


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

	_tracking = visible_target
	var over: bool = visible_target and player.global_position.distance_to(position) < 12.0
	_select = clampf(_select + (delta if over else -delta * 2.0), 0.0, SELECT_TIME)
	# Being hovered is felt on the whole screen: static builds as the click comes.
	if _fx and _select > 0.0:
		_fx.noise(0.25 + 0.5 * _select / SELECT_TIME, 0.2)
		_fx.spike(0.2 * _select / SELECT_TIME, 0.2)
	if _select >= SELECT_TIME and not _done:
		_done = true
		selected_player.emit()


func _random_point() -> Vector2:
	return Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y))


func _process(delta: float) -> void:
	_arrive = maxf(0.0, _arrive - delta * 1.5)
	_trail.push_front(position)
	if _trail.size() > 5:
		_trail.pop_back()
	queue_redraw()


func _draw() -> void:
	var glitch := Settings.glitch_intensity
	# Arriving: a huge pointer shrinking down into the world.
	var scale := 1.0 + _arrive * _arrive * 6.0
	# Tracking: thin scan lines through the pointer, across the whole area.
	if _tracking:
		var a := 0.12 + 0.08 * sin(Time.get_ticks_msec() * 0.02)
		var tl := bounds.position - position
		var br := bounds.end - position
		draw_line(Vector2(tl.x, 0), Vector2(br.x, 0), Color(0.55, 0.8, 1.0, a))
		draw_line(Vector2(0, tl.y), Vector2(0, br.y), Color(0.55, 0.8, 1.0, a))
	# Selection box with marching ants, shrinking onto you.
	if _select > 0.0:
		var s := 6.0 + 10.0 * (1.0 - _select / SELECT_TIME)
		var r := Rect2(-Vector2(s, s), Vector2(s, s) * 2.0)
		draw_rect(r, Color(0.55, 0.8, 1.0, 0.18))
		_draw_ants(r, Time.get_ticks_msec() * 0.02)
	# Afterimages: the pointer smears behind itself in split colour.
	for i in range(1, _trail.size()):
		var off := _trail[i] - position
		var c := Color(1.0, 0.2, 0.5, 0.25 / i) if i % 2 == 1 else Color(0.4, 0.9, 1.0, 0.25 / i)
		_draw_arrow(off, scale, c, false)
	var split := (1.0 + (2.0 if _tracking else 0.0) + _arrive * 6.0) * glitch
	_draw_arrow(Vector2(-split, 0), scale, Color(1.0, 0.1, 0.4, 0.55), false)
	_draw_arrow(Vector2(split, 0), scale, Color(0.3, 0.9, 1.0, 0.55), false)
	_draw_arrow(Vector2.ZERO, scale, Color.WHITE, true)


func _draw_arrow(offset: Vector2, scale: float, color: Color, outline: bool) -> void:
	# A plain arrow pointer, much bigger than anything in the world.
	var arrow := PackedVector2Array()
	for p in [Vector2(0, 0), Vector2(0, 17), Vector2(4, 13), Vector2(7, 20), Vector2(10, 19), Vector2(7, 12), Vector2(12, 12)]:
		arrow.append(offset + p * scale)
	draw_colored_polygon(arrow, color)
	if outline:
		var closed := arrow.duplicate()
		closed.append(arrow[0])
		draw_polyline(closed, Color.BLACK, 1.0)


func _draw_ants(r: Rect2, phase: float) -> void:
	# Dashed outline whose dashes crawl around the rectangle.
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
	for e in 4:
		var a: Vector2 = pts[e]
		var b: Vector2 = pts[e + 1]
		var length := a.distance_to(b)
		var d := fmod(phase, 4.0)
		while d < length:
			var p0 := a.lerp(b, d / length)
			var p1 := a.lerp(b, minf(d + 2.0, length) / length)
			draw_line(p0, p1, Color.WHITE, 1.0)
			d += 4.0

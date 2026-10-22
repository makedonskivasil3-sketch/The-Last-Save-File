class_name OwnerLamp
extends Node2D
## A street lamp the owner looks through (the Square's exposed crossing,
## docs/VERTICAL_SLICE.md §3c): a beam that sweeps a fixed arc at a steady
## pace. It's Arin's view cone again, varied: it never walks and never
## chases, it only looks, so it can be read and timed from shelter. Before
## each turn the head ticks and dims (the telegraph); in the beam, after a
## short grace, the owner's attention rises.

signal sees_player(delta: float)

## The arc it sweeps (radians from +x; down is PI/2), and how far it reaches.
var arc_from := 0.4
var arc_to := PI - 0.4
var reach := 128.0
## The beam's width (radians), and seconds for one sweep end to end.
var width := 0.42
var sweep_time := 4.2
## Held at each end this long, ticking (the turn is announced).
const HOLD := 0.9
var player: Node2D
var is_hidden: Callable
var paused := false

var _t := 0.0
var _angle := 0.0
var _seeing := false
var _holding := false
var _ticked := false


func _ready() -> void:
	_angle = arc_from
	add_to_group("canopy_reveal")


## 0..1 along the sweep and the hold at each end, as a function of time.
func _phase() -> float:
	var cycle := (sweep_time + HOLD) * 2.0
	var t := fposmod(_t, cycle)
	var leg := sweep_time + HOLD
	var out := t < leg
	var s := t if out else t - leg
	_holding = s >= sweep_time
	var k := smoothstep(0.0, 1.0, clampf(s / sweep_time, 0.0, 1.0))
	return k if out else 1.0 - k


func _process(delta: float) -> void:
	if not paused:
		_t += delta
	_angle = lerpf(arc_from, arc_to, _phase())
	if _holding and not _ticked and not paused:
		_ticked = true
		Sfx.play("click", -18.0, 0.6, 0.0)  # about to turn
	elif not _holding:
		_ticked = false
	_seeing = not paused and player != null and can_see(player.global_position)
	if _seeing:
		sees_player.emit(delta)
	queue_redraw()


## The owner turns the lamp to cover more (the opened gate): the arc's start
## moves there over `seconds`, ticking as it goes, so the change is seen
## happening rather than found later. 0 seconds: already there (a save
## restored with the gate open).
func widen_to(from_angle: float, seconds := 1.5) -> void:
	if seconds <= 0.0:
		arc_from = from_angle
		return
	Sfx.play("click", -14.0, 0.5, 0.0)
	var tw := create_tween()
	tw.tween_property(self, "arc_from", from_angle, seconds).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void: Sfx.play("click", -16.0, 0.6, 0.0))


func facing() -> float:
	return _angle


func is_turning() -> bool:
	return _holding


func can_see(pos: Vector2) -> bool:
	var to := pos - global_position
	if to.length() > reach or absf(angle_difference(_angle, to.angle())) > width * 0.5:
		return false
	if _blocked(pos) != pos:
		return false
	return not (is_hidden.is_valid() and is_hidden.call(pos))


func _blocked(pos: Vector2) -> Vector2:
	if not is_inside_tree():
		return pos
	var q := PhysicsRayQueryParameters2D.create(global_position, pos)
	if player is CollisionObject2D:
		q.collision_mask = player.collision_mask
		q.exclude = [player.get_rid()]
	for i in 4:
		var hit := get_world_2d().direct_space_state.intersect_ray(q)
		if hit.is_empty():
			return pos
		if not (hit.collider is Npc):
			return hit.position
		q.exclude = q.exclude + [hit.rid]
	return pos


func _draw() -> void:
	# The beam, stopped by walls like Arin's look: faint, brighter on you,
	# dimmer while it holds before turning.
	var a := 0.2 if _seeing else (0.05 if _holding and not Settings.reduce_flashing else 0.09)
	var pts := PackedVector2Array([Vector2.ZERO])
	for i in 11:
		var ang := _angle - width * 0.5 + width * i / 10.0
		pts.append(_blocked(global_position + Vector2.from_angle(ang) * reach) - global_position)
	draw_colored_polygon(pts, Color(1.0, 0.86, 0.55, a))
	# The post and its head.
	draw_rect(Rect2(-1.5, -18, 3, 20), Color("2a2420"))
	draw_circle(Vector2(0, 2), 3.0, Color(0, 0, 0, 0.3))
	var head := Color("f2c878") if not _holding else Color("b08850")
	draw_circle(Vector2(0, -19), 3.2, head)
	draw_line(Vector2(0, -19), Vector2(0, -19) + Vector2.from_angle(_angle) * 5.0, Color("4a3a2a"), 2.0)

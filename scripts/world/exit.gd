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

## How lit the doorway is (0..1): brighter as Rue comes near (graphics §3).
var glow := 0.0
var _t := 0.0
const NEAR := 40.0
const WARM := Color("f0d8a0")
const COLD := Color("7a8aa0")

## Which way is out (unit vector, pointing out of the area): set by
## Area.add_exit from the side of the map the exit is on.
var outward := Vector2.ZERO

var _was_inside := false
var _retry := 0.0
var _still := 0.0
const RETRY := 0.3
## Leaving needs intent (docs/prompts/TRAVEL_AND_DEPTH_2026-10-30.md §1): Rue
## is moving out through it (her heading within ~70° of outward), or she has
## stopped inside it for this long. Brushing past sideways doesn't leave.
const INTENT_DOT := 0.3
const STILL_LEAVES := 0.25
## After arriving, exits ignore Rue until she has moved this far from where
## she arrived: holding the direction can't throw her straight back.
const ARRIVAL_CLEAR := 24.0


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


## Is Rue leaving through this exit, not just touching it?
func intends(p: Player, delta: float) -> bool:
	if outward == Vector2.ZERO:
		return true
	var heading := p.velocity if p.velocity.length() > 5.0 else p._intent
	if heading.length() < 0.05:
		_still += delta
		return _still >= STILL_LEAVES
	_still = 0.0
	return heading.normalized().dot(outward) > INTENT_DOT


func _armed(p: Player) -> bool:
	var w: Variant = get_parent().get("world") if get_parent() else null
	if w == null or not w.has_method("arrival_cleared"):
		return true
	return w.arrival_cleared(p.global_position)


func _physics_process(delta: float) -> void:
	var player: Player = null
	for body in get_overlapping_bodies():
		if body is Player:
			player = body
	var inside := player != null
	if not inside:
		_was_inside = false
		_still = 0.0
		return
	if not open:
		if not _was_inside:
			blocked.emit(self)
		_was_inside = true
		return
	if not _armed(player) or not intends(player, delta):
		_was_inside = true
		return
	if not _was_inside or _retry <= 0.0:
		# Fires on the way in; still standing in it (the move was refused,
		# e.g. waiting for Wren): tries again every so often.
		_retry = RETRY
		used.emit(self)
	else:
		_retry -= delta
	_was_inside = true


func _process(delta: float) -> void:
	_t += delta
	var p := get_tree().get_first_node_in_group("player") as Node2D
	var near := 0.0
	if p:
		near = 1.0 - clampf((p.global_position.distance_to(global_position) - 8.0) / NEAR, 0.0, 1.0)
	glow = move_toward(glow, near, delta * 3.0)
	queue_redraw()


## The threshold (docs/prompts/TRAVEL_AND_DEPTH_2026-10-30.md §3): a lit strip
## across the doorway, light spilling a little way into the room, brighter
## as she comes near. A closed way is cold and dim.
func _draw() -> void:
	if outward == Vector2.ZERO:
		return
	var c := WARM if open else COLD
	var base := 0.16 if open else 0.08
	var a := base + (0.3 if open else 0.06) * glow
	if open and not Settings.reduce_motion:
		a += 0.03 * sin(_t * 2.0)
	var across := Vector2(-outward.y, outward.x).abs()
	var half := size * 0.5
	var width := (half * across).length()
	# The strip on the room side of the gap.
	var inner := -outward * (half * outward.abs()).length()
	for i in 5:
		var d := float(i) * 3.0
		var k := 1.0 - float(i) / 5.0
		var centre := inner - outward * d
		var r := Rect2(centre - across * width - outward.abs() * 1.5, across * width * 2.0 + outward.abs() * 3.0)
		draw_rect(r, Color(c, a * k * k))
	# Two door-post ticks at the ends of the gap.
	for sgn: float in [-1.0, 1.0]:
		var post := inner + across * width * sgn
		draw_line(post, post - outward * 6.0, Color(c, a * 1.6), 1.0)


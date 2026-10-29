class_name SavePoint
extends StaticBody2D
## The owner's save crystal. It does not recognize you.

const CRYSTAL := Color("7fd6a8")
const DENIED := Color("e0704f")

## Rue pressed it once, her own way (not the habit).
signal own_pressed

## From this press in a run Rue stops doing the habit (two light taps, then
## the press: her player's, from the opening) and presses once.
const OWN_AT := 3
const RUE_CYAN := Color("8cf2ff")

var _t := 0.0
var _denied := 0.0
var _own := 0.0
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


## What this is, shown small over the prompt (World.object_name).
func interact_name() -> String:
	return "save point"


## "habit" (the two taps, then the press) or "own" (one press), for the
## next press.
func press_kind() -> String:
	return "own" if _uses + 1 >= OWN_AT else "habit"


func interact() -> String:
	var kind := press_kind()
	_uses += 1
	if kind == "own":
		# One press. It still doesn't save; it doesn't refuse her either.
		_own = 1.0
		Sfx.play("click", -6.0, 0.85, 0.0)
		own_pressed.emit()
		return ""
	for h in Opening.HABIT:
		get_tree().create_timer(h[0]).timeout.connect(func() -> void: Sfx.play("click", h[1], 1.3 if h[0] < 0.5 else 1.0, 0.0))
	get_tree().create_timer(0.7).timeout.connect(func() -> void:
		_denied = 1.0
		Sfx.play("denied"))
	if _uses == 1:
		return "SAVE FAILED: profile mismatch."
	return "SAVE DENIED: you are not the owner of this file."


func _process(delta: float) -> void:
	_t += delta
	_denied = maxf(0.0, _denied - delta)
	_own = maxf(0.0, _own - delta * 0.6)
	queue_redraw()


func _draw() -> void:
	# A save crystal on a carved stone plinth (the owner's: it lights green for
	# Arin, flushes red when it refuses Rue, cyan when she presses her own way).
	var bob := sin(_t * 2.0) * 1.2
	var c := CRYSTAL.lerp(DENIED, _denied).lerp(RUE_CYAN, _own)
	# Light on the floor, then the plinth: a wider foot, a step, a top slab.
	draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 11.0, Color(c, 0.10 + 0.05 * sin(_t * 2.0)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(-7, 5, 14, 4), Color("3a3430"))
	draw_rect(Rect2(-7, 5, 14, 1), Color("57504a"))
	draw_rect(Rect2(-5, 2, 10, 3), Color("4a433d"))
	draw_rect(Rect2(-5, 2, 10, 1), Color("6a625a"))
	draw_line(Vector2(-3, 7), Vector2(3, 7), Color(c, 0.5), 0.6)  # the carved slot, lit from above
	# The crystal: a long faceted gem, light side and shadow side, a glint.
	var top := Vector2(0, -13 + bob)
	var mid_l := Vector2(-4.5, -5 + bob)
	var mid_r := Vector2(4.5, -5 + bob)
	var tip := Vector2(0, 1 + bob)
	draw_colored_polygon(PackedVector2Array([top, Vector2(0, -5 + bob), mid_l]), c.lightened(0.25))
	draw_colored_polygon(PackedVector2Array([top, mid_r, Vector2(0, -5 + bob)]), c)
	draw_colored_polygon(PackedVector2Array([mid_l, Vector2(0, -5 + bob), tip]), c.darkened(0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -5 + bob), mid_r, tip]), c.darkened(0.4))
	draw_polyline(PackedVector2Array([top, mid_r, tip, mid_l, top]), c.darkened(0.55), 0.6)
	draw_line(top + Vector2(-1, 3), top + Vector2(-2.2, 6), Color(1, 1, 1, 0.75), 0.6)
	# Two motes turning around it.
	for k in 2:
		var a := _t * 1.6 + k * PI
		draw_circle(Vector2(cos(a) * 7.0, -5 + bob + sin(a) * 2.0), 0.7, Color(c.lightened(0.4), 0.5 + 0.4 * sin(a)))

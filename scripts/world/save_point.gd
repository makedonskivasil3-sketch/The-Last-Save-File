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
	var bob := sin(_t * 2.0) * 1.5
	var c := CRYSTAL.lerp(DENIED, _denied).lerp(RUE_CYAN, _own)
	var pts := PackedVector2Array([
		Vector2(0, -12 + bob), Vector2(5, -4 + bob), Vector2(0, 4 + bob), Vector2(-5, -4 + bob)
	])
	draw_colored_polygon(pts, c)
	draw_circle(Vector2(0, 7), 5.0, Color(c, 0.15))
	draw_rect(Rect2(-6, 5, 12, 3), Color("3a302b"))

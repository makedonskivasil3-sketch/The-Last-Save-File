class_name Door
extends StaticBody2D
## The only way out of the room. The owner knows that too.

enum State { OPEN, LOCKED, DELETED }

const FRAME := Color("6b5546")
const PANEL := Color("5a3d2c")
const LOCK := Color("e0704f")
const OUTSIDE := Color("f2d9a0")

var state: State = State.OPEN
var size := Vector2(32, 8)

var _flash := 0.0
var _t := 0.0


func setup(rect: Rect2, initial: State) -> void:
	position = rect.get_center()
	size = rect.size
	state = initial
	# Always solid: even "open", the doorway leads to a part of the save that
	# hasn't been loaded. You were never going to walk through it.
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func lock() -> void:
	if state != State.OPEN:
		return
	state = State.LOCKED
	_flash = 1.0


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(0.0, _flash - delta * 1.5)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(-size / 2.0, size)
	match state:
		State.OPEN:
			draw_rect(r, Color(0, 0, 0))
			# Warm light spilling in from somewhere you can't reach.
			var glow := 0.35 + 0.1 * sin(_t * 2.0)
			for i in 4:
				var band := Rect2(r.position + Vector2(2, r.size.y + i * 3), Vector2(r.size.x - 4, 3))
				draw_rect(band, Color(OUTSIDE, glow * (1.0 - i / 4.0) * 0.5))
		State.LOCKED:
			draw_rect(r, PANEL)
			draw_rect(r, FRAME, false, 1.0)
			var lock_col := LOCK.lerp(Color.WHITE, _flash)
			draw_rect(Rect2(Vector2(-3, -3), Vector2(6, 5)), lock_col)
			if fmod(_t, 1.4) < 0.7 or _flash > 0.0:
				draw_rect(Rect2(r.position + Vector2(0, r.size.y), Vector2(r.size.x, 1)), Color(LOCK, 0.6))
		State.DELETED:
			# Painted over, but not perfectly. The outline of where a door was.
			draw_rect(r, Color("4a3b33"))
			var dash := 3.0
			var x := r.position.x
			while x < r.end.x:
				draw_line(Vector2(x, r.end.y), Vector2(minf(x + dash, r.end.x), r.end.y), Color(LOCK, 0.35))
				x += dash * 2.0

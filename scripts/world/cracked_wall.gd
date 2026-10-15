class_name CrackedWall
extends StaticBody2D
## A thin partition with a crack in it, hiding something behind. The first
## glitch you need: face the crack and hold interact to PHASE through. Once
## the memory behind it is recovered the wall comes down for good, so you're
## never shut in.

## Wall pieces (area coordinates).
var rects: Array[Rect2] = []
## Where the crack is drawn (and where the guide points).
var crack := Vector2.ZERO
## The memory it hides; when that's recovered the wall falls.
var fragment_id := ""

var _t := 0.0
var _open := false


func setup(pieces: Array[Rect2], crack_at: Vector2, fragment: String) -> void:
	rects = pieces
	crack = crack_at
	fragment_id = fragment
	for r in rects:
		var shape := RectangleShape2D.new()
		shape.size = r.size
		var col := CollisionShape2D.new()
		col.shape = shape
		col.position = r.get_center()
		add_child(col)


func is_open() -> bool:
	return _open


func _process(delta: float) -> void:
	_t += delta
	if not _open and fragment_id != "" and OwnerMemory.has_fragment(fragment_id):
		open()
	queue_redraw()


## The memory is yours: the partition crumbles.
func open() -> void:
	if _open:
		return
	_open = true
	for c in get_children():
		if c is CollisionShape2D:
			c.set_deferred("disabled", true)
	for r in rects:
		GlitchBurst.at(get_parent(), r.get_center(), r.size + Vector2(6, 6), 0.5)
	Sfx.play("phase", -4.0, 0.7)
	create_tween().tween_property(self, "modulate:a", 0.0, 0.6)


func _draw() -> void:
	for r in rects:
		draw_rect(r, Color("3b302b"))
		draw_rect(r, Color("5a4a40"), false, 1.0)
	if _open:
		return
	# The crack: a jagged line that flickers pink and cyan, brighter in pulses.
	var pulse := 0.55 + 0.45 * sin(_t * 3.0)
	var col := Color("ff4fa3").lerp(Color("8cf2ff"), 0.5 + 0.5 * sin(_t * 1.3))
	col.a = 0.5 + 0.5 * pulse
	var pts := [Vector2(-7, 0), Vector2(-4, -2), Vector2(-1, 1), Vector2(2, -2), Vector2(5, 1), Vector2(8, -1)]
	for i in pts.size() - 1:
		draw_line(crack + pts[i], crack + pts[i + 1], col, 1.0)
	draw_circle(crack, 6.0 + 2.0 * pulse, Color(col, 0.08))

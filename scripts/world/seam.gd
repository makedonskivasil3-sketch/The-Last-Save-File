class_name Seam
extends Area2D
## A gap in the wall the owner hasn't rewritten yet.
## Touch it and you slip out of the room. The owner will patch it afterwards.

signal slipped_through(seam: Seam)

var id := 0
var size := Vector2(12, 22)
## 0..1, how visible the tear is. The owner's rewrites make it easier to see.
var reveal := 0.0
## Closed seams are invisible and can't be used.
var open := false
## A seam the owner patched in an earlier session: a scar, not a way out.
var sealed := false

var _used := false
var _t := 0.0
var _opened_at := -1.0


func setup(seam_id: int, rect: Rect2) -> void:
	id = seam_id
	position = rect.get_center()
	size = rect.size
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _physics_process(_delta: float) -> void:
	# Polled rather than body_entered, so standing in the spot when it opens counts.
	if _used or not open or sealed:
		return
	for body in get_overlapping_bodies():
		if body is Player:
			_used = true
			slipped_through.emit(self)
			return


func _process(delta: float) -> void:
	_t += delta
	if open and _opened_at < 0.0:
		_opened_at = _t
		var fx := get_tree().get_first_node_in_group("screen_fx") as ScreenFx
		if fx:
			fx.spike(0.6, 0.6)  # the wall tearing open
	if open or sealed:
		queue_redraw()


func _draw() -> void:
	var vertical := size.y > size.x
	if sealed:
		_draw_scar(vertical)
	elif open:
		_draw_wound(vertical)


## An open wound in the wall: a pulsing red glow, a torn bright core, ragged
## edges, and pixels dripping out of it. It splits wider as it opens.
func _draw_wound(vertical: bool) -> void:
	var flash := Settings.flash_scale()
	var opening := clampf((_t - _opened_at) / 0.6, 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	var long := (size.y if vertical else size.x) * opening
	var axis := Vector2(0, 1) if vertical else Vector2(1, 0)
	var across := Vector2(1, 0) if vertical else Vector2(0, 1)
	# Glow bleeding into the room.
	for i in 3:
		draw_circle(Vector2.ZERO, 8.0 + i * 6.0 + pulse * 3.0, Color(0.9, 0.1, 0.3, (0.07 - i * 0.02) * (0.6 + 0.4 * flash) * reveal * 2.0))
	# Ragged edges: short slashes along the tear, jittering.
	var steps := 8
	for i in steps:
		var along := -long / 2.0 + long * (i + 0.5) / steps
		var w := (1.5 + randf() * 2.5) * (0.6 + 0.4 * pulse)
		draw_line(axis * along - across * w, axis * along + across * w, Color(0.95, 0.2, 0.35, 0.8 * reveal * 1.5), 1.0)
	# Bright core: the world behind the wall isn't drawn, it's just light.
	var core := Rect2(-axis * long / 2.0 - across, axis * long + across * 2.0).abs()
	draw_rect(core, Color(0.85, 1.0, 1.0, (0.55 + 0.45 * pulse) * minf(reveal * 2.0, 1.0)))
	# Pixels leaking out.
	for i in 4:
		var h := fmod(float(i) * 0.37 + _t * (0.3 + i * 0.1), 1.0)
		var start := axis * (randf_range(-0.5, 0.5) * long)
		draw_rect(Rect2(start + across * (3.0 + h * 10.0) * (1 if i % 2 == 0 else -1), Vector2(1, 1)), Color(1, 0.3, 0.5, (1.0 - h) * reveal * 1.5))


## A patched seam: stitched shut, still faintly pulsing like something healing badly.
func _draw_scar(vertical: bool) -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 1.6 + id)
	var long := size.y if vertical else size.x
	var axis := Vector2(0, 1) if vertical else Vector2(1, 0)
	var across := Vector2(1, 0) if vertical else Vector2(0, 1)
	var scar := Color(0.45, 0.08, 0.12, 0.55 + 0.25 * pulse)
	draw_line(-axis * long / 2.0, axis * long / 2.0, scar, 2.0)
	for i in 5:
		var along := -long / 2.0 + long * (i + 0.5) / 5.0
		draw_line(axis * along - across * 3.0 + axis, axis * along + across * 3.0 - axis, Color(0.75, 0.65, 0.55, 0.6), 1.0)

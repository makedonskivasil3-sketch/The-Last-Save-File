class_name LaneGate
extends StaticBody2D
## The gate at the east end of the lane behind Tobben's (the Square,
## docs/VERTICAL_SLICE.md §3c). Latched on the lane side: from the crossing
## it's just a fence. Walk the lane once and lift the latch, and the
## shortcut to the Archive road stays open for good
## (OwnerMemory.square_gate_open).

signal opened

var size := Vector2(34, 6)
## The side the latch is on: Rue must be north of this y to lift it.
var latch_side_y := 0.0
var player: Node2D
var _col: CollisionShape2D
var _swing := 0.0


func setup(rect: Rect2) -> void:
	position = rect.get_center()
	size = rect.size
	latch_side_y = rect.position.y
	var shape := RectangleShape2D.new()
	shape.size = size
	_col = CollisionShape2D.new()
	_col.shape = shape
	add_child(_col)
	if OwnerMemory.square_gate_open:
		_col.disabled = true
		_swing = 1.0


func is_open() -> bool:
	return OwnerMemory.square_gate_open


func can_interact() -> bool:
	return not is_open()


func interact_prompt() -> String:
	return "lift the latch" if _on_latch_side() else "gate"


func interact() -> Variant:
	if not _on_latch_side():
		return "Latched on the far side. The lane behind Tobben's runs to it."
	OwnerMemory.square_gate_open = true
	OwnerMemory.save_memory()
	_col.set_deferred("disabled", true)
	Area.notify_geometry(self, Rect2(position - size, size * 2.0))
	Sfx.play("door_lock", -8.0, 1.4)  # the latch (the lock sound, lighter)
	opened.emit()
	return "The latch lifts. The gate stays open: a way back that isn't the crossing."


func _on_latch_side() -> bool:
	return player != null and player.global_position.y < latch_side_y


func _process(delta: float) -> void:
	var want := 1.0 if is_open() else 0.0
	if _swing != want:
		_swing = move_toward(_swing, want, delta * 2.5)
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var wood := Color("6b4a30")
	draw_rect(Rect2(-w * 0.5 - 2, -8, 3, 12), Color("4a3828"))
	draw_rect(Rect2(w * 0.5 - 1, -8, 3, 12), Color("4a3828"))
	# Swung open towards the lane.
	var leaf := w * (1.0 - _swing * 0.85)
	var lift := -_swing * 10.0
	for k in 3:
		draw_line(Vector2(-w * 0.5, -5 + k * 3 + lift * 0.0), Vector2(-w * 0.5 + leaf, -5 + k * 3 + lift), wood, 1.4)
	draw_line(Vector2(-w * 0.5, -6), Vector2(-w * 0.5 + leaf, 1 + lift), wood, 1.0)
	if not is_open():
		draw_rect(Rect2(w * 0.5 - 6, -9, 4, 3), Color("b0a090"))  # the latch, on the lane side

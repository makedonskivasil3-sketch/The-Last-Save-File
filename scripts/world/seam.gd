class_name Seam
extends Area2D
## A gap in the wall the owner hasn't rewritten yet.
## Touch it and you slip out of the room. The owner will patch it afterwards.

signal slipped_through(seam: Seam)

var id := 0
var size := Vector2(12, 22)
## 0..1, how visible the tear is. The owner's rewrites make it easier to see.
var reveal := 0.2

var _used := false


func setup(seam_id: int, rect: Rect2) -> void:
	id = seam_id
	position = rect.get_center()
	size = rect.size
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _used or not body is Player:
		return
	_used = true
	slipped_through.emit(self)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var r := Rect2(-size / 2.0, size)
	var vertical := size.y > size.x
	var slices := 6
	for i in slices:
		if randf() > 0.35 + reveal * 0.6:
			continue
		var c: Color = [Color("8cf2ff"), Color.WHITE, Color("ff3366")].pick_random()
		c.a = reveal * randf_range(0.4, 1.0)
		if vertical:
			var h := r.size.y / slices
			var w := randf_range(1.0, 3.0)
			draw_rect(Rect2(Vector2(randf_range(-2.0, 1.0), r.position.y + i * h), Vector2(w, h)), c)
		else:
			var w := r.size.x / slices
			var h := randf_range(1.0, 3.0)
			draw_rect(Rect2(Vector2(r.position.x + i * w, randf_range(-2.0, 1.0)), Vector2(w, h)), c)

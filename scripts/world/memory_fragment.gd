class_name MemoryFragment
extends Area2D
## A shard of the intruder's own past, floating where something happened.
## The same cyan as you. Touch it to remember (World plays the flashback).

signal touched(fragment: MemoryFragment)

const COL := Color("8cf2ff")

var fragment_id := ""
## The owner's planted memory: almost the right colour.
var planted := false
var player: Node2D

var _t := randf() * 5.0
var _taken := false
var _absorb := 0.0


func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _physics_process(_delta: float) -> void:
	if _taken:
		return
	for body in get_overlapping_bodies():
		if body is Player:
			_taken = true
			touched.emit(self)
			return


## Pulled into the player, then gone.
func absorb() -> void:
	_absorb = 0.001


func _process(delta: float) -> void:
	_t += delta
	if _absorb > 0.0:
		_absorb += delta
		if is_instance_valid(player):
			global_position = global_position.lerp(player.global_position + Vector2(0, -12), minf(1.0, delta * 6.0))
		if _absorb > 0.7:
			queue_free()
	queue_redraw()


func _draw() -> void:
	var fade := 1.0 - clampf(_absorb / 0.7, 0.0, 1.0) if _absorb > 0.0 else 1.0
	var tint := COL.lerp(Color("ffb0a0"), 0.35) if planted else COL
	if planted and fmod(_t, 2.3) < 0.12:
		# Its edges give it away, if you watch.
		draw_arc(Vector2(0, sin(_t * 2.2) * 2.0), 9.0, 0.0, TAU, 16, Color(1, 0.25, 0.2, 0.7 * fade), 1.0)
	var bob := sin(_t * 2.2) * 2.0
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	# Soft glow.
	for i in 3:
		draw_circle(Vector2(0, bob), 6.0 + i * 5.0 + pulse * 2.0, Color(tint, (0.08 - i * 0.02) * fade))
	# A torn scrap of a picture, turning in place (its width follows a
	# cosine): a pale border, a warm afternoon inside it, two small figures,
	# a ragged bottom edge. Not a gem: the save crystal is the gem.
	var w := 5.5 * absf(cos(_t * 1.6)) + 0.5
	var k := w / 6.0
	var y0 := -7.0 + bob
	var frame := PackedVector2Array([Vector2(-w, y0), Vector2(w, y0), Vector2(w, y0 + 10.5),
		Vector2(w * 0.4, y0 + 12.5), Vector2(-w * 0.2, y0 + 10.8), Vector2(-w * 0.7, y0 + 12.8), Vector2(-w, y0 + 11.0)])
	draw_colored_polygon(frame, Color(Color("f4ead8").lerp(Color.WHITE, pulse * 0.3), fade))
	var inner := Rect2(-w + 1.0 * k, y0 + 1.2, maxf(0.1, 2.0 * w - 2.0 * k), 7.5)
	draw_rect(inner, Color(tint.lerp(Color("e8b060"), 0.45), fade))
	draw_rect(Rect2(inner.position + Vector2(0, 5.0), Vector2(inner.size.x, 2.5)), Color(Color("6a8a4a"), fade))  # grass
	if k > 0.35:
		draw_rect(Rect2(Vector2(-2.6 * k, y0 + 3.8), Vector2(1.2 * k, 3.2)), Color(Color("3a4e7a"), fade))  # two figures
		draw_rect(Rect2(Vector2(1.2 * k, y0 + 3.8), Vector2(1.2 * k, 3.2)), Color(Color("e9b44c"), fade))
	draw_polyline(frame + PackedVector2Array([frame[0]]), Color(1, 1, 1, 0.5 * fade * pulse), 0.5)
	# Pixels orbiting it, like it's still pulling memories in.
	for i in 4:
		var a := _t * 1.8 + i * TAU / 4.0
		var p := Vector2(cos(a) * 10.0, sin(a) * 4.0 + bob)
		draw_rect(Rect2(p, Vector2(1, 1)), Color(tint, 0.8 * fade))

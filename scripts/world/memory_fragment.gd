class_name MemoryFragment
extends Area2D
## A shard of the intruder's own past, floating where something happened.
## The same cyan as you. Touch it to remember (World plays the flashback).

signal touched(fragment: MemoryFragment)

const COL := Color("8cf2ff")

var fragment_id := ""
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
	var bob := sin(_t * 2.2) * 2.0
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	# Soft glow.
	for i in 3:
		draw_circle(Vector2(0, bob), 6.0 + i * 5.0 + pulse * 2.0, Color(COL, (0.08 - i * 0.02) * fade))
	# A diamond turning in place: its width follows a cosine.
	var w := 4.0 * absf(cos(_t * 1.6)) + 0.6
	var pts := PackedVector2Array([Vector2(0, -7 + bob), Vector2(w, bob), Vector2(0, 7 + bob), Vector2(-w, bob)])
	draw_colored_polygon(pts, Color(COL.lerp(Color.WHITE, pulse * 0.4), fade))
	draw_line(Vector2(0, -7 + bob), Vector2(0, 7 + bob), Color(1, 1, 1, 0.7 * fade))
	# Pixels orbiting it, like it's still pulling memories in.
	for i in 4:
		var a := _t * 1.8 + i * TAU / 4.0
		var p := Vector2(cos(a) * 10.0, sin(a) * 4.0 + bob)
		draw_rect(Rect2(p, Vector2(1, 1)), Color(COL, 0.8 * fade))

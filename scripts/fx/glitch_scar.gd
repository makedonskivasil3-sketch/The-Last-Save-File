class_name GlitchScar
extends Node2D
## What a glitch leaves behind: a small pink and cyan tear in the world where
## it fired, flickering, fading over SCAR_TIME. Spending awareness should
## leave a mark. Bigger glitches leave bigger scars.

const SCAR_TIME := 25.0
## An area keeps at most this many; the oldest heals first.
const MAX_SCARS := 12

var size := 10.0
var _age := 0.0
var _seed := 0


static func leave(area: Node, pos: Vector2, cost: float) -> void:
	if area == null:
		return
	var scars: Array = area.get_children().filter(func(n: Node) -> bool: return n is GlitchScar)
	while scars.size() >= MAX_SCARS:
		scars.pop_front().queue_free()
	var s := GlitchScar.new()
	s.position = pos
	s.size = clampf(6.0 + cost * 0.6, 6.0, 18.0)
	s._seed = randi()
	s.z_index = 2
	area.add_child(s)


func _process(delta: float) -> void:
	_age += delta
	if _age >= SCAR_TIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var life := 1.0 - _age / SCAR_TIME
	var flicker := 0.7 + 0.3 * sin(_age * 9.0 + _seed % 7) * Settings.flash_scale()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	# A jagged tear: a few offset slivers, pink over cyan.
	for i in 4:
		var y := rng.randf_range(-size * 0.5, size * 0.5)
		var w := rng.randf_range(size * 0.4, size * 1.2)
		var x := rng.randf_range(-size * 0.6, size * 0.2)
		var col := Color("ff4fa3") if i % 2 == 0 else Color("8cf2ff")
		col.a = 0.55 * life * flicker
		draw_rect(Rect2(x, y, w, 1), col)
	# A dead pixel or two that outlast the rest.
	draw_rect(Rect2(rng.randf_range(-3, 3), rng.randf_range(-3, 3), 1, 1), Color(1, 1, 1, 0.6 * life))

class_name GlitchBurst
extends Node2D
## What a glitch looks like where it lands: the target's rectangle of the
## world tears into colour-split slices, blocks of static and a bright
## outline, for a moment. Scaled by glitch intensity; Reduce flashing keeps
## it but drops the bright strobes.

var size := Vector2(24, 28)
var life := 0.6

var _t := 0.0


## Spawn a burst over a world position (the node is added to `parent`).
static func at(parent: Node, pos: Vector2, area_size := Vector2(24, 28), duration := 0.6) -> GlitchBurst:
	var b := GlitchBurst.new()
	b.size = area_size
	b.life = duration
	b.z_index = 30
	parent.add_child(b)
	b.global_position = pos
	return b


func _process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := 1.0 - _t / life
	var g := Settings.glitch_intensity
	var flash := Settings.flash_scale()
	var r := Rect2(-size * 0.5 - Vector2(0, size.y * 0.3), size)
	# Torn slices, offset sideways in split colour.
	for i in 6:
		var y := r.position.y + randf() * r.size.y
		var off := randf_range(-6.0, 6.0) * g * k
		var c := Color(1.0, 0.15, 0.55, 0.6 * k) if i % 2 == 0 else Color(0.3, 0.95, 1.0, 0.6 * k)
		draw_rect(Rect2(r.position.x + off, y, r.size.x, randf_range(1.0, 3.0)), c)
	# Blocks of static.
	for i in int(8 * g) + 2:
		var p := r.position + Vector2(randf() * r.size.x, randf() * r.size.y)
		draw_rect(Rect2(p, Vector2(randf_range(1, 4), randf_range(1, 3))), Color(1, 1, 1, 0.7 * k * flash))
	# A selection-like outline snapping outward.
	draw_rect(r.grow(4.0 * (1.0 - k)), Color(0.55, 0.95, 1.0, 0.8 * k), false, 1.0)

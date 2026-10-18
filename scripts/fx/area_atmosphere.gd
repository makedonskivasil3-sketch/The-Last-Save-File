class_name AreaAtmosphere
extends Node2D
## Sparse, deterministic dust: independent of gameplay RNG and collision.
var area: Area
var elapsed := 0.0

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(area) or area.has_dust:
		return
	var b := area.bounds.grow(-8.0)
	var cold := area.area_id in ["edge", "oob", "bin"]
	var color := Color(0.5, 0.7, 0.8, 0.14) if cold else Color(1.0, 0.83, 0.58, 0.16)
	for i in 18:
		var x := b.position.x + fposmod(i * 83.0 + elapsed * (2.0 + i % 3), b.size.x)
		var y := b.position.y + fposmod(i * 47.0 - elapsed * 2.0, b.size.y)
		draw_rect(Rect2(x, y, 1, 1), color)

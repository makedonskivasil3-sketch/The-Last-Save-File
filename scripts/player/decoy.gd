class_name Decoy
extends Node2D
## DECOY: a stale frame of Rue left behind. Arin walks at it and the cursor
## selects it instead of you, until it times out or gets selected (it pops).

var life := Glitch.DECOY_TIME
## Rue's look at the moment the frame was left (PixelCharacter of the player).
var sprite: PixelCharacter

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
	queue_redraw()


## Selected or touched: the frame pops like a bubble.
func pop() -> void:
	Sfx.play("pop", -4.0, 0.6)
	queue_free()


func _draw() -> void:
	if sprite == null:
		return
	var fade := clampf(life / 0.6, 0.0, 1.0)
	var jitter := Vector2(randf_range(-1, 1), 0) * Settings.glitch_intensity if randf() < 0.3 else Vector2.ZERO
	sprite.draw(self, {"offset": jitter + Vector2(-1, 0), "solid": Color(1.0, 0.2, 0.5, 0.35 * fade)})
	sprite.draw(self, {"offset": jitter, "alpha": 0.75 * fade})
	# Scanlines through it: you can tell it's not quite you.
	var top := float(PixelCharacter.FEET_Y - sprite.height())
	var y := top
	while y < PixelCharacter.FEET_Y:
		draw_rect(Rect2(-9, y, 18, 1), Color(0, 0, 0, 0.35 * fade))
		y += 3.0

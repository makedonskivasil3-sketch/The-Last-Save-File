class_name Passage
extends Node2D
## A way between areas that you take on purpose (interact), not by walking
## off an edge: climbing into the well, climbing back up out of bounds.

signal taken(p: Passage)

enum Look { NONE, PILLAR }

var prompt := "climb in"
## What it is (World.object_name): "the well", "the pillar".
var object_name := ""
var look: Look = Look.NONE
var target_area := ""
var arrival := ""
## A warm light at its foot: the well keeps Rue's answer here (the anchor).
var lit := false

var _t := 0.0


func can_interact() -> bool:
	return target_area != ""


func interact_prompt() -> String:
	return prompt


## What this is, shown small over the prompt (World.object_name).
func interact_name() -> String:
	return object_name


## World shows a returned String in the console; "" shows nothing.
func interact() -> String:
	taken.emit(self)
	return ""


func _process(delta: float) -> void:
	_t += delta
	if look != Look.NONE:
		queue_redraw()


func _draw() -> void:
	if look == Look.PILLAR:
		# A respawn point: a beam of cyan light reaching up out of the void.
		var pulse := 0.5 + 0.5 * sin(_t * 3.0)
		draw_rect(Rect2(-6, -2, 12, 4), Color("0c1a1f"))
		draw_rect(Rect2(-6, -2, 12, 4), Color("8cf2ff"), false, 1.0)
		draw_rect(Rect2(-2, -40, 4, 38), Color(0.55, 0.95, 1.0, 0.25 + 0.2 * pulse))
		draw_rect(Rect2(-1, -40, 2, 38), Color(0.9, 1.0, 1.0, 0.5))
		if lit:
			draw_circle(Vector2(0, 0), 9.0 + pulse, Color(1.0, 0.8, 0.45, 0.18))
			draw_circle(Vector2(0, 0), 3.0, Color(1.0, 0.85, 0.55, 0.7))
		for i in 3:
			var y := -fmod(_t * 18.0 + i * 13.0, 40.0)
			draw_rect(Rect2(-3, y, 1, 1), Color(0.8, 1.0, 1.0, 0.8))
			draw_rect(Rect2(2, y - 6, 1, 1), Color(0.8, 1.0, 1.0, 0.6))

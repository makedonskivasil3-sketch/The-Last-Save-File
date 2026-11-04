class_name GhostMarker
extends Node2D
## Where you died before. The owner kept a record. So does the floor.

const COL := Color("8cf2ff")

var index := 0
var _t := 0.0
## Seconds left before the owner starts the static here (Area.start_erasure):
## while it counts down, the spot glows red and crackles, so the player can
## read it and go round (ISSUE_REGISTER PL-4b).
var warn_left := 0.0
const WARN := Color("ff3366")


func warn(seconds: float) -> void:
	warn_left = seconds


func _process(delta: float) -> void:
	_t += delta
	warn_left = maxf(0.0, warn_left - delta)
	queue_redraw()


func _draw() -> void:
	var a := 0.12 + 0.06 * sin(_t * 1.3 + index)
	draw_rect(Rect2(-4, -10, 8, 16), Color(COL, a), false, 1.0)
	draw_line(Vector2(-6, 7), Vector2(6, 7), Color(COL, a))
	draw_string(UiStyle.system_font(), Vector2(-12, 16), "#%d" % (index + 1), HORIZONTAL_ALIGNMENT_CENTER, 24, 7, Color(COL, a * 1.5))
	if warn_left > 0.0:
		# The static is coming here: a red ring closing in (no flashing: a
		# steady pulse under 3 Hz, softer with reduced flashing).
		var k := 1.0 - fmod(_t * 1.6, 1.0)
		var w := 0.35 + 0.3 * Settings.flash_scale()
		draw_arc(Vector2(0, 2), 4.0 + 10.0 * k, 0.0, TAU, 20, Color(WARN, w * (1.0 - k * 0.6)), 1.2)
		draw_rect(Rect2(-4, -10, 8, 16), Color(WARN, w), false, 1.0)

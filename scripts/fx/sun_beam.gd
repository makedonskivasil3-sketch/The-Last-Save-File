class_name SunBeam
extends Node2D
## The frozen afternoon (docs/ART_DIRECTION.md). The places the owner keeps
## are the version they remember: lit by an afternoon sun through a window,
## a sun that never moves, because the save is always 14:22.
##
## The light is the remembered version's warmth, and the owner's attention
## drains it: as awareness rises the beam thins and cools, and at HUNT it is
## barely there. When the owner reloads, it stutters. Dust hangs in it.
##
## Draw-only: no collision, no gameplay. Add it before the props that should
## stand in front of it.

## The window, in the wall (its bottom edge is where the light comes in).
var window := Rect2()
## How far the light travels across the floor (the far edge's offset from
## the window's bottom corners) and how much wider it gets.
var throw := Vector2(60, 170)
var spread := 26.0
var warm := Color(1.0, 0.86, 0.58)
var cold := Color(0.55, 0.72, 0.95)
## 0..1: how much the owner is watching (World's awareness / 100).
var watched := 0.0

const MOTES := 16
var _t := 0.0
var _stutter := 0.0


func _process(delta: float) -> void:
	_t += delta
	var w := get_parent().get("world") as World
	if w and w.director:
		# Smoothed, so the light seems to drain rather than switch.
		watched = move_toward(watched, clampf(w.director.awareness / 100.0, 0.0, 1.0), delta * 0.4)
		if w.owner_moves and w.owner_moves.rewinding:
			_stutter = 1.0
	_stutter = maxf(0.0, _stutter - delta * 1.5)
	queue_redraw()


## 1 in the calm, fading toward ~0.15 at HUNT and beyond.
func warmth() -> float:
	var calm := 1.0 - smoothstep(0.15, 0.8, watched)
	var s := 1.0
	if _stutter > 0.0:
		# The reload: the light skips, like a frame that didn't load.
		s = 0.35 if fmod(_t * 18.0, 1.0) < 0.5 * Settings.flash_scale() + 0.25 else 1.0
	return maxf(0.15, calm) * s


func _draw() -> void:
	var k := warmth()
	var col := cold.lerp(warm, k)
	var top_l := Vector2(window.position.x, window.end.y)
	var top_r := Vector2(window.end.x, window.end.y)
	var bot_l := top_l + throw + Vector2(-spread * 0.5, 0)
	var bot_r := top_r + throw + Vector2(spread * 0.5, 0)
	# The beam: brightest at the window, gone by the time it reaches the floor's far side.
	var near := Color(col, 0.2 * k + 0.02)
	var far := Color(col, 0.0)
	draw_polygon(PackedVector2Array([top_l, top_r, bot_r, bot_l]), PackedColorArray([near, near, far, far]))
	# The patch of light where it lands: a soft parallelogram on the floor.
	var land := PackedVector2Array([
		top_l.lerp(bot_l, 0.55), top_r.lerp(bot_r, 0.55), top_r.lerp(bot_r, 0.92), top_l.lerp(bot_l, 0.92)])
	draw_colored_polygon(land, Color(col, 0.12 * k))
	# Window panes: bright sky, a cross bar.
	draw_rect(window, Color(col.lightened(0.35), 0.35 + 0.5 * k))
	draw_rect(window, Color(0.18, 0.13, 0.1), false, 1.0)
	draw_line(Vector2(window.get_center().x, window.position.y), Vector2(window.get_center().x, window.end.y), Color(0.18, 0.13, 0.1), 1.0)
	# Dust, hanging in the light. Each mote drifts on its own slow loop.
	for i in MOTES:
		var u := fposmod(i * 0.618 + sin(_t * 0.07 + i) * 0.04, 1.0)          # across the beam
		var v := fposmod(i * 0.371 + _t * (0.008 + 0.004 * (i % 3)), 1.0)    # down the beam
		var p := top_l.lerp(top_r, u).lerp(bot_l.lerp(bot_r, u), v)
		p.x += sin(_t * 0.5 + i * 1.7) * 1.5
		var a := 0.5 * k * (1.0 - v) * (0.6 + 0.4 * sin(_t * 1.3 + i))
		if a > 0.02:
			draw_rect(Rect2(p.round(), Vector2.ONE), Color(1.0, 0.95, 0.8, a))

class_name Companion
extends Node2D
## Pip, Rue's fox. Fell out of the map with Rue years ago and was never saved
## back in, so the deletion never reached it, and the owner can't see it.
##
## WAITING: curled up out of bounds until you find it.
## FOLLOWING: trots after you through every area (through walls, too: Pip was
## never in the save's collision data). It runs a little ahead toward
## whatever you should find next (World.guide_target()), and yips "!" when
## Arin comes close.

enum Mode { WAITING, FOLLOWING }

const SPEED := 120.0
## How far ahead of you Pip trots toward the goal.
const LEAD := 26.0
const ORANGE := Color("e8833a")
const DARK := Color("6a3418")
const WHITE := Color("f4ead8")
const NAME_COLOR := Color("f0a050")
## Arin closer than this gets a warning yip.
const WARN_DISTANCE := 85.0
## Drawn a little bigger than 1:1 so the fox reads next to Rue (who is 2x).
const DRAW_SCALE := 1.5

var mode: Mode = Mode.WAITING
var world: World

var _t := randf() * 5.0
var _facing := 1.0
var _moving := false
var _line := 0
var _moment_shown := false
var _join_after_talk := false
## Seconds the "!" stays up, and the cooldown before the next warning.
var _yip := 0.0
var _yip_cooldown := 0.0


func can_interact() -> bool:
	return true


func interact_prompt() -> String:
	return "wake" if mode == Mode.WAITING else "talk"


func interact() -> Dictionary:
	if mode == Mode.WAITING:
		_join_after_talk = true
		return {"speaker": "PIP", "color": NAME_COLOR, "lines": Story.PIP_MEETING}
	# The first talk each run: how well Pip knows you (by your memories).
	if not _moment_shown:
		_moment_shown = true
		return {"speaker": "PIP", "color": NAME_COLOR, "lines": [Story.pip_moment(OwnerMemory.fragments.size())]}
	var line: String = Story.PIP_LINES[_line % Story.PIP_LINES.size()]
	_line += 1
	if line.contains("%d"):
		line = line % OwnerMemory.fragments.size()
	return {"speaker": "PIP", "color": NAME_COLOR, "lines": [line]}


## Appear next to the player (new area, new session).
func arrive(at: Vector2) -> void:
	position = at + Vector2(-14, 6)


func _process(delta: float) -> void:
	_t += delta
	_yip = maxf(0.0, _yip - delta)
	_yip_cooldown = maxf(0.0, _yip_cooldown - delta)
	if world == null:
		return
	if _join_after_talk and not world.hud.is_dialogue_open():
		_join_after_talk = false
		world.adopt_pip(self)
	if mode == Mode.FOLLOWING:
		_follow(delta)
		_warn_about_arin()
	queue_redraw()


func _follow(delta: float) -> void:
	var p: Vector2 = world.player.global_position
	var want := p + Vector2(-12.0 * _facing, 6.0)
	var goal := world.guide_target()
	if goal != Vector2.INF and goal.distance_to(p) > 20.0:
		want = p + (goal - p).normalized() * LEAD  # nose toward what's next
	var to := want - global_position
	_moving = to.length() > 3.0
	if _moving:
		global_position += to.normalized() * minf(SPEED * delta * clampf(to.length() / 20.0, 0.4, 1.4), to.length())
		if absf(to.x) > 1.0:
			_facing = signf(to.x)


func _warn_about_arin() -> void:
	var arin: Variant = world.area.get("arin") if world.area else null
	if not (arin is Node2D) or _yip_cooldown > 0.0:
		return
	if arin.global_position.distance_to(world.player.global_position) < WARN_DISTANCE:
		_yip = 1.0
		_yip_cooldown = 4.0
		Sfx.play("pop", -2.0, 1.6)


func _draw() -> void:
	# A small fox, about 12 x 9 pixels (x1.5), drawn facing right and flipped.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(DRAW_SCALE, DRAW_SCALE))
	var step := floori(_t * 10.0) % 2 if _moving else 0
	var sit := mode == Mode.WAITING or not _moving
	var bob := 0.0 if _moving else roundf(sin(_t * 2.0) * 0.5)
	var tail := roundf(sin(_t * (9.0 if _moving else 3.0)) * 1.0)
	if mode == Mode.WAITING:
		# Curled up asleep: a round orange heap with a white tail tip.
		_px(-5, -3, 10, 4, ORANGE)
		_px(-6, -2, 3, 3, ORANGE)
		_px(-7, -1, 2, 2, WHITE)
		_px(3, -4, 2, 1, DARK)
		var z := fmod(_t, 2.0)
		if z < 1.2:
			draw_string(ThemeDB.fallback_font, Vector2(4, -6 - z * 4.0), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 1, 1, 0.6))
		return
	var y := -1.0 + bob
	# Tail (behind), then body, legs, head, ears.
	_px(-9, y - 4 + tail, 4, 2, ORANGE)
	_px(-10, y - 5 + tail, 2, 2, WHITE)
	_px(-5, y - 4, 8, 4 if not sit else 3, ORANGE)
	_px(-4, y - (2 if sit else 1), 5, 1, WHITE)  # white chest
	if sit:
		_px(-4, y, 3, 1, DARK)
		_px(1, y, 2, 1, DARK)
	else:
		_px(-4 + step, y, 1, 2, DARK)
		_px(1 - step, y, 1, 2, DARK)
	_px(2, y - 7, 4, 4, ORANGE)
	_px(5, y - 5, 2, 2, WHITE)
	_px(6, y - 5, 1, 1, DARK)  # nose
	_px(4, y - 6, 1, 1, Color(0.1, 0.05, 0.05))  # eye
	_px(2, y - 9, 1, 2, ORANGE)
	_px(4, y - 9, 1, 2, ORANGE)
	if _yip > 0.0:
		var c := Color(1.0, 0.85, 0.45, minf(1.0, _yip * 3.0))
		draw_rect(Rect2(-1, y - 18, 2, 5), c)
		draw_rect(Rect2(-1, y - 12, 2, 2), c)


func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	var rx := x if _facing > 0.0 else -x - w
	draw_rect(Rect2(rx, y, w, h), c)

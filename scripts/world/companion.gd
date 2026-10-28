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
## Pip leads (noses toward what's next) for this long after arriving in an
## area, and again once Rue has stood still this long. Otherwise it stays at
## her heel: a companion, not a route arrow.
const ARRIVAL_LEAD := 3.0
const HESITATE := 2.5
## Coming back to her (a new run): one quick circle round her feet.
const GREET := 1.4

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
var _since_arrival := 0.0
var _still := 0.0
var _greet := 0.0
var _leading := false


func greeting() -> bool:
	return _greet > 0.0


func leading() -> bool:
	return _leading


## Back with her after a run: Pip runs one circle round her, then sits.
func greet() -> void:
	_greet = GREET
	Sfx.play("pop", -6.0, 1.8)


func can_interact() -> bool:
	return true


func interact_prompt() -> String:
	return "wake" if mode == Mode.WAITING else "talk"


## What this is, shown small over the prompt (World.object_name).
func interact_name() -> String:
	return "pip"


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
	_since_arrival = 0.0


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
	_since_arrival += delta
	_still = _still + delta if world.player.velocity.length() < 5.0 else 0.0
	if _greet > 0.0:
		_greet -= delta
		var a := (1.0 - _greet / GREET) * TAU
		want = p + Vector2(cos(a), sin(a) * 0.6) * 16.0  # round her feet
	var goal := world.guide_target()
	_leading = _greet <= 0.0 and goal != Vector2.INF and goal.distance_to(p) > 20.0 \
		and (_since_arrival < ARRIVAL_LEAD or _still > HESITATE)
	if _leading:
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


## Pip's size beside the taller cast (docs/ART_BIBLE.md: about 10 px tall,
## always low to the ground).
const DRAW_SCALE := 1.3


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * DRAW_SCALE)
	_draw_fox()
	draw_set_transform(Vector2.ZERO)


func _draw_fox() -> void:
	# A small fox, illustrated like the cast (docs/VISUAL_DIRECTION.md): soft
	# shapes with the shared outline, drawn facing right and mirrored.
	var f := _facing
	var sit := mode == Mode.WAITING or not _moving
	var bob := 0.0 if _moving else sin(_t * 2.0) * 0.4
	var swish := sin(_t * (9.0 if _moving else 3.0)) * 1.4
	var step := sin(_t * 18.0) * 1.2 if _moving else 0.0
	Decor.disc(self, Vector2(0, 0.6), 6.0, Color(0, 0, 0, 0.28), 10)  # contact shadow
	if mode == Mode.WAITING:
		# Curled up asleep: a round orange heap, the tail wrapped round it.
		_blob(Vector2(0, -2.5), Vector2(6.8, 3.6), ORANGE, true)
		_blob(Vector2(-4.0 * f, -1.5), Vector2(3.4, 2.2), ORANGE.darkened(0.08), true)
		_blob(Vector2(-6.4 * f, -1.2), Vector2(1.6, 1.3), WHITE, false)
		draw_line(Vector2(2.6 * f, -3.6), Vector2(4.0 * f, -3.4), DARK, 0.6)  # a closed eye
		var z := fmod(_t, 2.0)
		if z < 1.2:
			draw_string(ThemeDB.fallback_font, Vector2(5, -8 - z * 4.0), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 1, 1, 0.6))
		return
	var y := -1.5 + bob
	# Tail behind, then legs, body, chest, head, ears.
	var tail := PackedVector2Array([Vector2(-5 * f, y - 4), Vector2(-11 * f, y - 6 + swish), Vector2(-13 * f, y - 4 + swish), Vector2(-6 * f, y - 2)])
	_poly(tail, ORANGE)
	_blob(Vector2(-12.4 * f, y - 4.8 + swish), Vector2(1.6, 1.3), WHITE, false)
	for leg: float in [-3.0, 2.0]:
		var lift := step if leg < 0.0 else -step
		var top := Vector2(leg * f, y - 2.0)
		var foot := Vector2((leg + (lift * 0.5 if not sit else 0.0)) * f, y + 1.2 - (maxf(0.0, lift) * 0.6 if not sit else 0.0))
		draw_line(top, foot, Decor.INK, 2.4)
		draw_line(top, foot, DARK, 1.4)
	_blob(Vector2(-0.6 * f, y - 4.0 + (0.6 if sit else 0.0)), Vector2(5.4, 3.0), ORANGE, true)
	# Painted light from the upper left, like the cast: a darker belly and a
	# warm highlight along the back.
	_ellipse(Vector2(-0.6 * f, y - 2.6 + (0.6 if sit else 0.0)), Vector2(4.6, 1.4), ORANGE.darkened(0.16))
	_ellipse(Vector2(-1.4 * f, y - 5.6 + (0.6 if sit else 0.0)), Vector2(3.2, 0.8), ORANGE.lightened(0.22))
	_blob(Vector2(1.4 * f, y - 2.8), Vector2(2.2, 1.4), WHITE, false)  # white chest
	var head := Vector2(4.4 * f, y - 7.6 + (0.4 if sit else 0.0))
	for ear: float in [-1.4, 1.4]:
		_poly(PackedVector2Array([head + Vector2((ear - 1.0) * f, -1.6), head + Vector2(ear * f, -5.0), head + Vector2((ear + 1.2) * f, -1.8)]), ORANGE)
		_poly(PackedVector2Array([head + Vector2((ear - 0.4) * f, -2.0), head + Vector2(ear * f, -4.0), head + Vector2((ear + 0.6) * f, -2.1)]), DARK, false)  # inside the ear
	_poly(PackedVector2Array([head + Vector2(-2.6 * f, -1.8), head + Vector2(2.2 * f, -2.2), head + Vector2(4.6 * f, 0.6), head + Vector2(1.6 * f, 2.2), head + Vector2(-2.4 * f, 1.4)]), ORANGE)
	_poly(PackedVector2Array([head + Vector2(1.4 * f, 0.2), head + Vector2(4.6 * f, 0.6), head + Vector2(1.8 * f, 2.2)]), WHITE, false)  # muzzle
	Decor.disc(self, head + Vector2(4.6 * f, 0.5), 0.7, Decor.INK, 8)  # nose
	Decor.disc(self, head + Vector2(0.9 * f, -0.4), 0.7, Color(0.1, 0.05, 0.05), 8)  # eye
	Decor.disc(self, head + Vector2(0.7 * f, -0.7), 0.25, Color(1, 1, 1, 0.9), 6)
	if _yip > 0.0:
		var c := Color(1.0, 0.85, 0.45, minf(1.0, _yip * 3.0))
		draw_rect(Rect2(-1, y - 22, 2, 6), c)
		draw_rect(Rect2(-1, y - 15, 2, 2), c)


## A soft blob (with the shared outline behind it if `outline`).
func _blob(c: Vector2, r: Vector2, col: Color, outline := true) -> void:
	if outline:
		_ellipse(c, r + Vector2(0.75, 0.75), Decor.INK)
	_ellipse(c, r, col)


func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(pts, col)


func _poly(pts: PackedVector2Array, col: Color, outline := true) -> void:
	if outline:
		var centre := Vector2.ZERO
		for q in pts:
			centre += q
		centre /= pts.size()
		var grown := PackedVector2Array()
		for q in pts:
			grown.append(q + (q - centre).normalized() * 0.75)
		draw_colored_polygon(grown, Decor.INK)
	draw_colored_polygon(pts, col)

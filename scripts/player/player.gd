class_name Player
extends CharacterBody2D
## You. The thing that isn't supposed to be in this save.
##
## Drawn in colours the world's palette doesn't use, and the renderer never
## quite agrees on where you are: a pink ghost runs out of sync, a trail of
## stale frames follows you, and your body tears into slices. All of it gets
## worse as `instability` (the owner's awareness, 0..1) rises, and all of it
## scales with Settings.glitch_intensity.

const BODY := Color("8cf2ff")
const HEAD := Color("d8ffff")
const GHOST := Color(1.0, 0.2, 0.4, 0.22)
const TRAIL_LENGTH := 6
const TRAIL_INTERVAL := 0.05

@export var speed := 90.0

var frozen := false
## Seconds since the player last moved; the owner watches this.
var idle_time := 0.0
## 0..1, set by World from the owner's awareness.
var instability := 0.0

var _jitter := Vector2.ZERO
var _tear_rows := PackedFloat32Array([0, 0, 0])
var _blink := false
var _trail: Array[Vector2] = []
var _trail_timer := 0.0
var _t := 0.0
## "", "erased", "overwritten", "selected", "rescued"
var _dissolve := ""
var _dissolve_t := 0.0


func _physics_process(delta: float) -> void:
	if frozen:
		velocity = Vector2.ZERO
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * speed
	move_and_slide()
	idle_time = idle_time + delta if dir == Vector2.ZERO else 0.0


## Play the end-of-life (or rescue) animation for this cause.
func dissolve(cause: String) -> void:
	_dissolve = cause
	_dissolve_t = 0.0


func _process(delta: float) -> void:
	_t += delta
	var glitch := Settings.glitch_intensity
	var unstable := (0.25 + instability * 0.75) * glitch
	_jitter = Vector2(randf_range(-2.0, 2.0), 0.0) if randf() < (2.0 + instability * 10.0) * delta * glitch else Vector2.ZERO
	# Body slices: each row of the sprite occasionally renders a few pixels off.
	for i in _tear_rows.size():
		_tear_rows[i] = randf_range(-3.0, 3.0) * unstable if randf() < unstable * 0.25 else 0.0
	# Rare dropped frames: you briefly aren't drawn at all.
	_blink = randf() < instability * 0.02 * glitch * Settings.flash_scale()

	_trail_timer -= delta
	if _trail_timer <= 0.0:
		_trail_timer = TRAIL_INTERVAL
		_trail.push_front(global_position)
		if _trail.size() > TRAIL_LENGTH:
			_trail.pop_back()
	if _dissolve != "":
		_dissolve_t += delta
	queue_redraw()


func _draw() -> void:
	if _dissolve != "":
		_draw_dissolve()
		return
	_draw_trail()
	if _blink:
		return
	# Chromatic ghost: a second copy of you, slightly out of sync.
	var ghost_off := Vector2(1, 0) - _jitter + Vector2(sin(_t * 7.0), 0) * instability
	draw_rect(Rect2(Vector2(-4, -10) + ghost_off, Vector2(8, 16)), GHOST)
	_draw_body(Vector2.ZERO, 1.0)


func _draw_body(offset: Vector2, alpha: float) -> void:
	var o := offset + _jitter
	# Head, torso, legs: three slices that can tear apart independently.
	draw_rect(Rect2(Vector2(-3 + _tear_rows[0], -10) + o, Vector2(6, 5)), Color(HEAD, alpha))
	draw_rect(Rect2(Vector2(-4 + _tear_rows[1], -5) + o, Vector2(8, 6)), Color(BODY, alpha))
	draw_rect(Rect2(Vector2(-4 + _tear_rows[2], 1) + o, Vector2(8, 5)), Color(BODY, alpha))
	# Torn slice edges flash the other colour.
	for i in _tear_rows.size():
		if _tear_rows[i] != 0.0:
			var y := [-10.0, -5.0, 1.0][i] as float
			draw_rect(Rect2(Vector2(-6 + _tear_rows[i] * 2.0, y) + o, Vector2(1, 4)), Color(1, 0.2, 0.5, 0.8 * alpha))


func _draw_trail() -> void:
	# Stale frames: where you were a moment ago, fading, alternating cyan/pink.
	var strength := (0.35 + instability * 0.65) * Settings.glitch_intensity
	for i in range(1, _trail.size()):
		var p := _trail[i] - global_position
		if p.length() < 1.0:
			continue
		var a := strength * 0.22 * (1.0 - float(i) / TRAIL_LENGTH)
		var c := Color(0.55, 0.95, 1.0, a) if i % 2 == 0 else Color(1.0, 0.25, 0.55, a)
		draw_rect(Rect2(p + Vector2(-4, -10), Vector2(8, 16)), c)


func _draw_dissolve() -> void:
	var t := _dissolve_t
	match _dissolve:
		"erased":
			# Eaten from the feet up by black, red at the bite.
			var eaten := clampf(t / 1.2, 0.0, 1.0) * 16.0
			if eaten < 16.0:
				_draw_body(Vector2(randf_range(-1, 1), 0), 1.0)
				draw_rect(Rect2(-5, 6 - eaten, 10, eaten), Color.BLACK)
				draw_rect(Rect2(-5, 6 - eaten - 1, 10, 1), Color(0.95, 0.15, 0.1))
		"overwritten":
			# Arin's colours sweep down over you, row by row.
			var rows := clampf(t / 0.8, 0.0, 1.0) * 16.0
			_draw_body(Vector2(randf_range(-2, 2), 0), 1.0)
			draw_rect(Rect2(-4, -10, 8, rows), Color("5a7fb0"))
			draw_rect(Rect2(-4, -10 + rows, 8, 1), Color.WHITE)
		"selected":
			# A selection box snaps around you, then you scatter into pixels.
			if t < 0.35:
				_draw_body(Vector2.ZERO, 1.0)
				var s := 14.0 - t * 20.0
				draw_rect(Rect2(Vector2(-s, -s - 2), Vector2(s, s) * 2.0), Color(0.55, 0.8, 1.0, 0.9), false, 1.0)
			else:
				_draw_scatter(t - 0.35, [BODY, HEAD, Color(1, 0.2, 0.5), Color.WHITE], 40.0)
		"rescued":
			# Pulled upward into the slot as a stretched cyan streak.
			var stretch := clampf(t / 0.6, 0.0, 1.0)
			var a := 1.0 - clampf((t - 0.6) / 0.6, 0.0, 1.0)
			draw_rect(Rect2(-4 + stretch * 2.0, -10 - stretch * 60.0, 8 - stretch * 4.0, 16 + stretch * 60.0), Color(BODY, a))
			draw_rect(Rect2(-1, -10 - stretch * 80.0, 2, 16 + stretch * 80.0), Color(1, 1, 1, a))


## Pixels flying apart from the body: deterministic per pixel, no allocations.
func _draw_scatter(t: float, palette: Array, speed_px: float) -> void:
	var a := 1.0 - clampf(t / 1.2, 0.0, 1.0)
	for i in 36:
		var h := fmod(sin(float(i) * 12.9898) * 43758.5453, 1.0)
		var h2 := fmod(sin(float(i) * 78.233) * 12345.678, 1.0)
		var dir := Vector2.from_angle(h * TAU) * (0.4 + absf(h2))
		var start := Vector2(-4 + (i % 8), -10 + floori(i / 8.0) * 3)
		var p := start + dir * speed_px * t * (1.0 + t)
		draw_rect(Rect2(p, Vector2(1, 1) * (1 + (i % 2))), Color(palette[i % palette.size()], a))

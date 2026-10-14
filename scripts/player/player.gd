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
var _last_step := 0
var _dissolve := ""
var _dissolve_t := 0.0
## A hood around nothing, two points of light.
var _sprite := PixelCharacter.new("intruder", {
	"g": Color("3fa6b8"), "v": Color("05070a"), "c": BODY, "e": Color("e8ffff"),
	"l": Color("2f8a9a"), "f": Color("1c4e58"),
})


func _physics_process(delta: float) -> void:
	if frozen:
		velocity = Vector2.ZERO
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * speed
	move_and_slide()
	idle_time = idle_time + delta if dir == Vector2.ZERO else 0.0


## Play the end-of-life (or rescue) animation for this cause, or
## "materialize" to assemble out of pixels (waking up in the save).
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
		if _dissolve == "materialize" and _dissolve_t > 1.4:
			_dissolve = ""
	_sprite.update(delta, velocity if not frozen else Vector2.ZERO)
	# Footsteps on the walk cycle's contact frames.
	var step := _sprite.step_frame()
	if step != _last_step and step % 2 == 1:
		Sfx.play("step_%d" % (step >> 1), 0.0, 1.0, 0.1)
	_last_step = step
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
	_sprite.draw(self, {"offset": ghost_off, "solid": GHOST})
	_draw_body(Vector2.ZERO, 1.0)


func _draw_body(offset: Vector2, alpha: float) -> void:
	var o := offset + _jitter
	# Head, torso, legs: three slices that can tear apart independently.
	_sprite.draw(self, {"offset": o, "alpha": alpha, "slices": [_tear_rows[0], _tear_rows[1], _tear_rows[2]]})
	# Your eyes glow a little into the dark.
	if _sprite.facing != Vector2.UP:
		draw_circle(o + _sprite.eye_position(), 5.0, Color(0.8, 1.0, 1.0, 0.08 * alpha))
	# Torn slice edges flash the other colour.
	var top := float(PixelCharacter.FEET_Y - _sprite.height())
	for i in _tear_rows.size():
		if _tear_rows[i] != 0.0:
			var y := top + [2.0, 11.0, 20.0][i] as float
			draw_rect(Rect2(Vector2(-10 + _tear_rows[i] * 2.0, y) + o, Vector2(1, 6)), Color(1, 0.2, 0.5, 0.8 * alpha))


func _draw_trail() -> void:
	# Stale frames: where you were a moment ago, fading, alternating cyan/pink.
	var strength := (0.35 + instability * 0.65) * Settings.glitch_intensity
	for i in range(1, _trail.size()):
		var p := _trail[i] - global_position
		if p.length() < 1.0:
			continue
		var a := strength * 0.22 * (1.0 - float(i) / TRAIL_LENGTH)
		var c := Color(0.55, 0.95, 1.0, a) if i % 2 == 0 else Color(1.0, 0.25, 0.55, a)
		_sprite.draw(self, {"offset": p, "solid": c})


func _draw_dissolve() -> void:
	var t := _dissolve_t
	var top := float(PixelCharacter.FEET_Y - _sprite.height())
	var h := float(_sprite.height())
	match _dissolve:
		"materialize":
			# Pixels converge out of nowhere, then the body flickers in.
			if t < 0.9:
				_draw_scatter(0.9 - t, [BODY, HEAD, Color(1, 0.2, 0.5), Color.WHITE], 46.0)
			else:
				if randf() < (t - 0.9) * 2.5:
					_draw_body(Vector2.ZERO, clampf((t - 0.9) * 2.0, 0.0, 1.0))
				_draw_scatter(0.0, [BODY, Color.WHITE], 0.0)
		"erased":
			# Eaten from the feet up by black, red at the bite.
			var eaten := clampf(t / 1.2, 0.0, 1.0) * h
			if eaten < h:
				_draw_body(Vector2(randf_range(-1, 1), 0), 1.0)
				draw_rect(Rect2(-9, 6 - eaten, 18, eaten), Color.BLACK)
				draw_rect(Rect2(-9, 6 - eaten - 1, 18, 1), Color(0.95, 0.15, 0.1))
		"overwritten":
			# Arin's colours sweep down over you, row by row.
			var rows := clampf(t / 0.8, 0.0, 1.0) * h
			_draw_body(Vector2(randf_range(-2, 2), 0), 1.0)
			draw_rect(Rect2(-8, top, 16, rows), Color("5a7fb0"))
			draw_rect(Rect2(-8, top + rows, 16, 1), Color.WHITE)
		"selected":
			# A selection box snaps around you, then you scatter into pixels.
			if t < 0.35:
				_draw_body(Vector2.ZERO, 1.0)
				var s := 20.0 - t * 26.0
				draw_rect(Rect2(Vector2(-s, -s - 6), Vector2(s, s) * 2.0), Color(0.55, 0.8, 1.0, 0.9), false, 1.0)
			else:
				_draw_scatter(t - 0.35, [BODY, HEAD, Color(1, 0.2, 0.5), Color.WHITE], 40.0)
		"rescued":
			# Pulled upward into the slot as a stretched cyan streak.
			var stretch := clampf(t / 0.6, 0.0, 1.0)
			var a := 1.0 - clampf((t - 0.6) / 0.6, 0.0, 1.0)
			draw_rect(Rect2(-8 + stretch * 4.0, top - stretch * 60.0, 16 - stretch * 8.0, h + stretch * 60.0), Color(BODY, a))
			draw_rect(Rect2(-1, top - stretch * 80.0, 2, h + stretch * 80.0), Color(1, 1, 1, a))


## Pixels flying apart from the body: deterministic per pixel, no allocations.
func _draw_scatter(t: float, palette: Array, speed_px: float) -> void:
	var a := 1.0 - clampf(t / 1.2, 0.0, 1.0)
	for i in 36:
		var h := fmod(sin(float(i) * 12.9898) * 43758.5453, 1.0)
		var h2 := fmod(sin(float(i) * 78.233) * 12345.678, 1.0)
		var dir := Vector2.from_angle(h * TAU) * (0.4 + absf(h2))
		var start := Vector2(-8 + (i % 8) * 2, -18 + floori(i / 8.0) * 5)
		var p := start + dir * speed_px * t * (1.0 + t)
		draw_rect(Rect2(p, Vector2(1, 1) * (1 + (i % 2))), Color(palette[i % palette.size()], a))

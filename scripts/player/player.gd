class_name Player
extends CharacterBody2D
## You. The thing that isn't supposed to be in this save.
##
## You are RUE, the character slot 2's player made: messy hair, a red scarf,
## a yellow raincoat. Deleted, you load in "missing texture" cyan with a void
## where your face was; every memory fragment you recover restores part of
## your real palette (scarf, hair, coat, shoes, and last of all your face).
##
## The renderer never quite agrees on where you are: a pink ghost runs out of
## sync, a trail of stale frames follows you, and your body tears into slices.
## All of it gets worse as `instability` (the owner's awareness, 0..1) rises,
## and all of it scales with Settings.glitch_intensity.
##
## Rue also reacts: glances around when standing still, hugs themself and
## shivers when left idle under pressure, ducks when someone hides them, and
## startles when the owner reacts.

const BODY := Color("8cf2ff")
const HEAD := Color("d8ffff")
const GHOST := Color(1.0, 0.2, 0.4, 0.22)
## Rue's real colours (palette keys as in PixelCharacter; l legs, f shoes, e eyes).
const RUE := {
	"h": Color("8a4f2c"), "s": Color("f0c49c"), "c": Color("e9b44c"), "d": Color("a9772a"),
	"a": Color("d8463a"), "l": Color("3d4e78"), "f": Color("3a2226"), "e": Color("2a1612"),
}
## The deleted version: no texture, no face, two points of light.
const MISSING := {
	"h": Color("3fa6b8"), "s": Color("05070a"), "c": BODY, "d": Color("5fc8d8"),
	"a": Color("d8ffff"), "l": Color("2f8a9a"), "f": Color("1c4e58"), "e": Color("e8ffff"),
}
## Which keys each recovered fragment restores, in order.
const RESTORE_ORDER := [["a"], ["h"], ["c", "d"], ["l", "f"], ["s", "e"]]
const TRAIL_LENGTH := 6
const TRAIL_INTERVAL := 0.05

@export var speed := 90.0

var frozen := false
## Set by World while dialogue or a choice is open: idle_time holds.
var reading := false
## Seconds since the player last moved; the owner watches this.
var idle_time := 0.0
## True while someone hides you (set by World): you duck down.
var sheltered := false
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
var _sprite := PixelCharacter.new("rue", MISSING)
## The palette for how much of you is restored, and the fully-missing one
## the restored parts flicker back to under pressure.
var _palette: Dictionary = MISSING
var _restored := 0
## Seconds left of the "colour coming back" shimmer.
var _restore_flash := 0.0
var _glance_timer := 1.0
## PHASE: where you slipped from, and how long ago (for the streak).
var _phase_from := Vector2.ZERO
var _phase_t := 1.0
var _startle_mark := 0.0


## A faint cyan glow of Rue's own (World turns it on in lit areas).
var glow: PointLight2D


func _ready() -> void:
	refresh_look(false)
	glow = PointLight2D.new()
	glow.texture = Area.light_texture()
	glow.texture_scale = 0.75
	glow.color = Color(0.55, 0.95, 1.0)
	glow.energy = 0.35
	glow.position = Vector2(0, -6)
	glow.enabled = false
	add_child(glow)
	# Positional sound (Arin's footsteps, the cursor's hum) is heard from Rue.
	var ear := AudioListener2D.new()
	add_child(ear)
	ear.make_current()


## Rebuild the palette from how many memory fragments you have. With
## `animate`, the restored colours flash in.
func refresh_look(animate := true) -> void:
	var count := mini(OwnerMemory.fragments.size(), RESTORE_ORDER.size())
	_palette = MISSING.duplicate()
	for i in count:
		for key in RESTORE_ORDER[i]:
			_palette[key] = RUE[key]
	_sprite.palette = _palette
	_sprite.leg_color = _palette["l"]
	_sprite.shoe_color = _palette["f"]
	_sprite.eye_color = _palette["e"]
	if animate and count > _restored:
		_restore_flash = 1.2
	_restored = count


## Which way Rue is facing (for PHASE).
func facing() -> Vector2:
	return _sprite.facing


## The sprite (for DECOY: a frame of exactly how you look right now).
func sprite_snapshot() -> PixelCharacter:
	var copy := PixelCharacter.new("rue", _palette)
	copy.facing = _sprite.facing
	copy.leg_color = _sprite.leg_color
	copy.shoe_color = _sprite.shoe_color
	copy.eye_color = _sprite.eye_color
	return copy


## PHASE: blink through a wall to `to`, leaving a streak of stale frames.
func phase_to(to: Vector2) -> void:
	_phase_from = global_position - to
	_phase_t = 0.0
	global_position = to
	velocity = Vector2.ZERO


## How much of Rue is back (0..5).
func restored_parts() -> int:
	return _restored


## Something is aiming at Rue (the cursor settling, Arin pointing): eyes
## stay wide for as long as it lasts. Called every frame by World.
func set_targeted(on: bool) -> void:
	if on:
		_sprite.startled = maxf(_sprite.startled, 0.2)


## The owner just reacted: jump, eyes wide, a "!" over your head.
func startle() -> void:
	_sprite.startled = 0.9
	_sprite.hop(0.3)
	_startle_mark = 0.9


func _physics_process(delta: float) -> void:
	if frozen:
		velocity = Vector2.ZERO
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * speed
	move_and_slide()
	if dir != Vector2.ZERO:
		idle_time = 0.0
	elif not reading:
		idle_time += delta


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
		_dissolve_t += delta * (3.2 if _dissolve == "materialize" and OwnerMemory.sessions > 1 else 1.0)
		if _dissolve == "materialize" and _dissolve_t > 1.4:
			_dissolve = ""
	_sprite.update(delta, velocity if not frozen else Vector2.ZERO)
	_update_mood(delta)
	# Footsteps on the walk cycle's contact frames.
	var step := _sprite.step_frame()
	if step != _last_step and step % 2 == 1:
		Sfx.play("step_%d" % (step >> 1), 0.0, 1.0, 0.1)
	_last_step = step
	queue_redraw()


## Body language: glancing around, hugging yourself, ducking, flickering
## back to missing-texture cyan when the owner is close.
func _update_mood(delta: float) -> void:
	_restore_flash = maxf(0.0, _restore_flash - delta)
	_phase_t = minf(1.0, _phase_t + delta * 2.5)
	_startle_mark = maxf(0.0, _startle_mark - delta)
	var still := velocity.length() < 2.0
	_sprite.crouch = sheltered
	_sprite.hug = still and idle_time > 7.0 and instability > 0.3
	_sprite.shiver = _sprite.hug and instability > 0.5
	# Nervous glances once you've stood still for a moment.
	if still and idle_time > 2.0:
		_glance_timer -= delta
		if _glance_timer <= 0.0:
			_glance_timer = randf_range(0.6, 1.8) / (1.0 + instability)
			_sprite.glance = [-1, 0, 1].pick_random()
			if randf() < 0.25 and _sprite.facing.y == 0.0:
				_sprite.facing = -_sprite.facing  # look over your shoulder
	else:
		_sprite.glance = 0
	# Restored colours aren't stable yet: under pressure they drop out.
	var flicker := _restored > 0 and randf() < instability * 0.04 * Settings.glitch_intensity
	_sprite.palette = MISSING if flicker else _palette


func _draw() -> void:
	if _dissolve != "":
		_draw_dissolve()
		return
	_draw_trail()
	if _phase_t < 1.0:
		# The streak where you slipped through: frames smeared along the jump.
		for i in 5:
			var f := float(i) / 5.0
			var c := Color(0.55, 0.95, 1.0, 0.5 * (1.0 - _phase_t) * (1.0 - f)) if i % 2 == 0 else Color(1.0, 0.25, 0.55, 0.4 * (1.0 - _phase_t) * (1.0 - f))
			_sprite.draw(self, {"offset": _phase_from * (1.0 - f), "solid": c})
	if _blink:
		return
	# Chromatic ghost: a second copy of you, slightly out of sync.
	var ghost_off := Vector2(1, 0) - _jitter + Vector2(sin(_t * 7.0), 0) * instability
	_sprite.draw(self, {"offset": ghost_off, "solid": GHOST})
	_draw_body(Vector2.ZERO, 1.0)
	var top := float(PixelCharacter.FEET_Y - _sprite.height())
	if _restore_flash > 0.0:
		# Your colours flood back in: a white silhouette fading out.
		_sprite.draw(self, {"solid": Color(1, 1, 1, _restore_flash / 1.2 * 0.8)})
	if _startle_mark > 0.0:
		# "!" over your head.
		var c := Color(1.0, 0.85, 0.45, minf(1.0, _startle_mark * 3.0))
		draw_rect(Rect2(-1, top - 11, 2, 5), c)
		draw_rect(Rect2(-1, top - 5, 2, 2), c)


func _draw_body(offset: Vector2, alpha: float) -> void:
	var o := offset + _jitter
	# Head, torso, legs: three slices that can tear apart independently.
	_sprite.draw(self, {"offset": o, "alpha": alpha, "slices": [_tear_rows[0], _tear_rows[1], _tear_rows[2]]})
	# Until your face comes back, your eyes glow a little into the dark.
	if _sprite.facing != Vector2.UP and _restored < RESTORE_ORDER.size():
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

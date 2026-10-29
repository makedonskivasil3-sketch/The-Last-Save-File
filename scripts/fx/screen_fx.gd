class_name ScreenFx
extends ColorRect
## Drives the full-screen CRT/corruption shader (shaders/save_corruption.gdshader)
## and the world-layer shake. Everything visual that is "the screen itself"
## goes through here, so Settings are applied in exactly one place:
##
##   Settings.glitch_intensity (0..1)  scales every distortion: tearing,
##       aberration, sickness, block glitches, world jitter and shake.
##   Settings.reduce_flashing          scales colour washes, negative flashes,
##       static bursts, brightness flicker and screen roll down to ~30%.
##   Settings.crt_screen               the old CRT look (glass, scanlines, grille).
##
## Gameplay code only ever calls the event methods below (deletion_hit(),
## cursor_arrives(), play_death(), ...) or sets the awareness target.

## Permanent extra glitch, raised once the owner reaches PURGE.
var base_glitch := 0.0
## Owner awareness 0..1 (OwnerDirector sets this); the shader eases toward it.
var awareness_target := 0.0
## 1 while in the Edge.
var edge_target := 0.0
## Whether this screen also shakes the world layer (the title has no world).
var shake_world := true
## Where the world's camera looks (World.update_camera): the top-left of
## the view, in area coordinates. The world layer's transform is the camera
## and the shake together, set here only (one owner for canvas_transform).
var view_offset := Vector2.ZERO

var _awareness := 0.0
var _edge := 0.0
var _glitch := 0.0
var _glitch_decay := 1.0
var _noise := 0.0
var _noise_decay := 1.0
var _wash := Color(0, 0, 0, 0)
var _wash_decay := 1.0
var _invert := 0.0
var _shake := 0.0
var _roll := 0.0
var _roll_target := 0.0
var _jitter := Vector2.ZERO
var _jitter_timer := 0.0
var _haunted := false
var _haunt_timer := 3.0
## Animated by tweens during deaths, wins and quitting.
## `memory` tints the screen for flashbacks.
var memory_amount := 0.0
var squeeze := 0.0
var void_amount := 0.0
var smear := 0.0
var _mat: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("screen_fx")
	_mat = material as ShaderMaterial


func _exit_tree() -> void:
	if shake_world:
		get_viewport().canvas_transform = Transform2D.IDENTITY


# --- events -------------------------------------------------------------------

## A burst of tearing and block corruption that fades out over `duration` seconds.
func spike(amount: float, duration: float = 0.6) -> void:
	_glitch = maxf(_glitch, amount)
	_glitch_decay = _glitch / maxf(duration, 0.01)


## Static and high-frequency lines (the cursor arriving, deletions).
func noise(amount: float, duration: float) -> void:
	_noise = maxf(_noise, amount)
	_noise_decay = _noise / maxf(duration, 0.01)


## A full-screen colour flash that fades out.
func wash(color: Color, strength: float, duration: float) -> void:
	if strength >= _wash.a:
		_wash = Color(color, strength)
		_wash_decay = strength / maxf(duration, 0.01)


## Shakes the world layer (not the HUD), in game pixels.
func shake(pixels: float) -> void:
	_shake = maxf(_shake, pixels)


## The vertical hold slips by `amount` of the screen and snaps back.
func roll_slip(amount: float) -> void:
	_roll_target = amount * Settings.flash_scale()


## The owner crossed an awareness threshold. `level` 0..1 is how far along.
func threshold_pulse(level: float) -> void:
	spike(0.45 + level * 0.35, 0.7)
	roll_slip(0.03 + level * 0.07)
	wash(Color(0.55, 0.0, 0.12), 0.12 + 0.18 * level, 0.6)
	shake(1.5 + level * 3.0)


## A character is being deleted.
func deletion_hit() -> void:
	spike(0.85, 1.3)
	noise(0.35, 0.8)
	wash(Color(0.9, 0.1, 0.6), 0.32, 0.7)
	shake(3.0)


## The owner's cursor reaches into the world.
func cursor_arrives() -> void:
	noise(1.0, 1.8)
	spike(0.9, 1.2)
	roll_slip(0.09)
	wash(Color(0.85, 0.92, 1.0), 0.18, 0.4)
	shake(4.0)


## The eraser starts eating the area.
func eraser_starts() -> void:
	spike(0.9, 1.0)
	wash(Color(0.35, 0.0, 0.02), 0.4, 0.9)
	shake(3.0)


## Arriving somewhere. The Edge hits hardest.
func enter_area(area_id: String) -> void:
	edge_target = 1.0 if area_id == "edge" else 0.0
	if area_id == "edge":
		spike(1.0, 1.4)
		noise(0.6, 1.2)
		roll_slip(0.18)
	else:
		spike(0.4, 0.6)


## Death. Each cause gets its own treatment:
##   "erased"       the screen is eaten block by block, red at the bite.
##   "overwritten"  rows smear sideways under a wash of Arin's blue.
##   "selected"     negative flashes, then static, like a click and a delete.
func play_death(cause: String) -> void:
	var tw := create_tween()
	match cause:
		"overwritten":
			wash(Color(0.32, 0.48, 0.75), 0.55, 2.2)
			spike(0.8, 2.0)
			shake(6.0)
			tw.tween_property(self, "smear", 1.0, 0.6).set_ease(Tween.EASE_IN)
			# Retreats as the death text arrives, so the text stays readable.
			tw.tween_property(self, "smear", 0.0, 0.8)
		"selected":
			# One inverted hit, then the white wash: two flashes, not three
			# (UI-4: measured by tests/tour_flash.gd; the second hit 0.12 s
			# later put this at the WCAG limit).
			_invert = 1.0
			noise(1.0, 2.0)
			spike(1.0, 1.8)
			shake(4.0)
			tw.tween_interval(0.37)
			tw.tween_callback(func() -> void: wash(Color(0.9, 0.95, 1.0), 0.7, 1.4))
		_:
			spike(1.0, 2.5)
			wash(Color(0.4, 0.0, 0.0), 0.35, 1.5)
			shake(4.0)
			tw.tween_property(self, "void_amount", 0.92, 0.6).set_ease(Tween.EASE_IN)
			tw.tween_interval(0.1)
			# The void recedes behind the (already black) death screen.
			tw.tween_property(self, "void_amount", 0.0, 0.6)


## Reaching Slot 2: a rescue that doesn't quite feel safe. Cyan flood, the
## tube collapses to a line and comes back, and afterwards something magenta
## keeps flickering at the edge of the picture.
func play_win() -> void:
	wash(Color(0.55, 0.95, 1.0), 0.7, 1.2)
	noise(0.7, 1.0)
	spike(1.0, 1.0)
	var tw := create_tween()
	tw.tween_property(self, "squeeze", 0.75, 0.35).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "squeeze", 0.97, 0.15)
	tw.tween_interval(0.35)
	tw.tween_property(self, "squeeze", 0.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(_begin_haunting)


func _begin_haunting() -> void:
	awareness_target = 0.0
	edge_target = 0.0
	_haunted = true


## Flashbacks: the picture goes soft, pale and cyan, like a memory.
func memory(on: bool) -> void:
	var tw := create_tween()
	tw.tween_property(self, "memory_amount", 1.0 if on else 0.0, 0.6)
	if on:
		spike(0.5, 0.6)


## Quitting: the picture collapses like a CRT switching off.
func power_off(duration: float = 0.8) -> void:
	spike(0.6, duration)
	var tw := create_tween()
	tw.tween_property(self, "squeeze", 1.0, duration).set_ease(Tween.EASE_IN)


# --- per frame -----------------------------------------------------------------

func _process(delta: float) -> void:
	var intensity := Settings.glitch_intensity
	var flash := Settings.flash_scale()

	_awareness = move_toward(_awareness, awareness_target, delta * 0.35)
	_edge = move_toward(_edge, edge_target, delta * 1.5)
	_glitch = maxf(0.0, _glitch - _glitch_decay * delta)
	_noise = maxf(0.0, _noise - _noise_decay * delta)
	_wash.a = maxf(0.0, _wash.a - _wash_decay * delta)
	_invert = maxf(0.0, _invert - delta * 6.0)
	_shake = maxf(0.0, _shake - delta * 10.0)
	_update_roll(delta)
	_update_haunt(delta)

	var g := base_glitch + _glitch
	# Rare, unprompted twitches. Something is always running in the background,
	# and more often the more the owner is paying attention.
	if randf() < (0.25 + _awareness * 0.8) * delta * flash:
		g += 0.25

	# Screen effects off: skip the full-screen pass entirely (no screen copy,
	# no shader). Gameplay is unaffected; only the CRT look goes away.
	visible = Settings.screen_effects > 0
	_mat.set_shader_parameter("quality", Settings.screen_effects)
	_mat.set_shader_parameter("intensity", intensity)
	_mat.set_shader_parameter("flash", flash)
	_mat.set_shader_parameter("curvature", 0.14 if Settings.crt_screen else 0.0)
	_mat.set_shader_parameter("crt", 1.0 if Settings.crt_screen else 0.0)
	_mat.set_shader_parameter("awareness", _awareness)
	_mat.set_shader_parameter("edge_mode", _edge)
	_mat.set_shader_parameter("glitch", clampf(g, 0.0, 1.0))
	_mat.set_shader_parameter("noise_burst", _noise * flash)
	_mat.set_shader_parameter("roll", _roll)
	_mat.set_shader_parameter("squeeze", squeeze)
	_mat.set_shader_parameter("wash", _wash)
	_mat.set_shader_parameter("void_amount", void_amount)
	_mat.set_shader_parameter("smear", smear * maxf(intensity, 0.3))
	_mat.set_shader_parameter("invert", _invert)
	_mat.set_shader_parameter("memory", memory_amount)

	if shake_world:
		_update_world_transform(delta, intensity)


func _update_roll(delta: float) -> void:
	# Slips quickly to the target, then crawls back into place.
	if _roll_target > 0.0:
		_roll = move_toward(_roll, _roll_target, delta * 2.5)
		if is_equal_approx(_roll, _roll_target):
			_roll_target = 0.0
	else:
		_roll = move_toward(_roll, 0.0, delta * 0.6)


func _update_haunt(delta: float) -> void:
	# After the win: the owner is still out there.
	if not _haunted:
		return
	_haunt_timer -= delta
	if _haunt_timer <= 0.0:
		_haunt_timer = randf_range(1.5, 4.0)
		wash(Color(0.9, 0.1, 0.6), 0.12, 0.25)
		spike(0.3, 0.3)


## The world layer (canvas layer 0) twitches; the HUD stays put. Small
## constant jitter grows with awareness, plus decaying shake from events.
func _update_world_transform(delta: float, intensity: float) -> void:
	if not Settings.screen_shake:
		get_viewport().canvas_transform = Transform2D(0.0, -view_offset.round())
		return
	_jitter_timer -= delta
	if _jitter_timer <= 0.0:
		_jitter_timer = randf_range(0.05, 0.25)
		var sick := _awareness * _awareness
		_jitter = Vector2.ZERO
		if randf() < sick * 0.8:
			_jitter = Vector2(randf_range(-1.0, 1.0), randf_range(-0.5, 0.5)) * (0.5 + sick * 1.5)
	var offset := (_jitter + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake) * intensity
	var skew := 0.0
	if _awareness > 0.6 and randf() < 0.03 * intensity:
		skew = randf_range(-0.01, 0.01) * _awareness
	var xf := Transform2D(0.0, Vector2.ONE, skew, offset.round() - view_offset.round())
	get_viewport().canvas_transform = xf

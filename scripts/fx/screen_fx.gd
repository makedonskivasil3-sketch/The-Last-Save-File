class_name ScreenFx
extends ColorRect
## Drives the full-screen corruption shader.

## Constant background glitch, raised as the owner gets hostile.
var base_glitch := 0.0

var _spike := 0.0
var _decay := 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## A burst of corruption that fades out over `duration` seconds.
func spike(amount: float, duration: float = 0.6) -> void:
	amount *= Settings.flash_scale()
	_spike = maxf(_spike, amount)
	_decay = amount / maxf(duration, 0.01)


func _process(delta: float) -> void:
	_spike = maxf(0.0, _spike - _decay * delta)
	var g := base_glitch + _spike
	# Rare, unprompted twitches. Something is always running in the background.
	if randf() < 0.25 * delta * Settings.flash_scale():
		g += 0.25
	g *= Settings.glitch_intensity
	var mat := material as ShaderMaterial
	mat.set_shader_parameter("glitch", clampf(g, 0.0, 1.0))
	mat.set_shader_parameter("grain", Settings.glitch_intensity)

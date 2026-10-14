extends Node
## Player preferences. Stored in user://settings.cfg, separate from the
## owner's memory: wiping the owner never touches these.

signal changed

const PATH := "user://settings.cfg"

## 0..1 linear master volume.
var volume := 0.8
var fullscreen := false
## 0..1 multiplier for screen tearing, chromatic split and grain.
var glitch_intensity := 1.0
## Curved CRT glass. Off = flat screen (some players find curvature disorienting).
var crt_curvature := true
## Softens flashes: no strobing lights, gentler spikes, slower blinking.
var reduce_flashing := false
## Whether the last input came from a gamepad (for button prompts).
var using_gamepad := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	apply()


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		using_gamepad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		using_gamepad = false


## Scale for anything that flashes (screen spikes, blinking, light strobes).
func flash_scale() -> float:
	return 0.3 if reduce_flashing else 1.0


## Glyph for an action's button, matching the last-used device.
func glyph(action: String) -> String:
	match action:
		"interact":
			return "A" if using_gamepad else "E"
		"confirm":
			return "A" if using_gamepad else "ENTER"
		"pause":
			return "START" if using_gamepad else "ESC"
	return action.to_upper()


func set_value(key: String, value: Variant) -> void:
	set(key, value)
	apply()
	save()
	changed.emit()


func apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(0, volume <= 0.001)
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("accessibility", "glitch_intensity", glitch_intensity)
	cfg.set_value("accessibility", "reduce_flashing", reduce_flashing)
	cfg.set_value("video", "crt_curvature", crt_curvature)
	cfg.save(PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	volume = clampf(float(cfg.get_value("audio", "volume", volume)), 0.0, 1.0)
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))
	glitch_intensity = clampf(float(cfg.get_value("accessibility", "glitch_intensity", glitch_intensity)), 0.0, 1.0)
	reduce_flashing = bool(cfg.get_value("accessibility", "reduce_flashing", reduce_flashing))
	crt_curvature = bool(cfg.get_value("video", "crt_curvature", crt_curvature))

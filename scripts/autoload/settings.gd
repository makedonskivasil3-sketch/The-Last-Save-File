extends Node
## Player preferences. Stored in user://settings.cfg, separate from the
## owner's memory: wiping the owner never touches these.

signal changed

const PATH := "user://settings.cfg"
## Tests (`-- --test-mode`) never read or write the player's settings.
const TEST_PATH := "user://test_settings.cfg"

## 0..1 linear volumes: master, music (drone + flashback music) and effects
## (everything else, including menus). Sfx creates the buses.
var volume := 0.8
var music_volume := 0.8
var sfx_volume := 0.9
var fullscreen := false
## 0..1 multiplier for screen tearing, chromatic split and grain.
var glitch_intensity := 1.0
## Curved CRT glass. Off = flat screen (some players find curvature disorienting).
var crt_curvature := true
## Screen effects quality: 2 = full CRT, 1 = light (one texture read, no
## colour fringing or aperture grille; for weak GPUs and laptops), 0 = off
## (no full-screen pass at all).
var screen_effects := 2
## Softens flashes: no strobing lights, gentler spikes, slower blinking.
var reduce_flashing := false
## Short vibrations on phones (glitches, deaths, the save ring).
var vibration := true
## Bigger HUD and menu text (x1.25), for small screens and tired eyes.
var large_text := false
## First-session tips (moving, the owner watching, hiding, quitting).
## Turning them back on shows every tip again.
var tutorial_tips := true
## Tip ids already shown, so each one only ever appears once.
var tips_seen: Array = []
## Whether the last input came from a gamepad (for button prompts).
var using_gamepad := false
## Whether the last input was a touch (phones, tablets): prompts then name
## the on-screen buttons, and TouchControls shows them.
var using_touch := false

var _path := PATH


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if "--test-mode" in OS.get_cmdline_user_args():
		_path = TEST_PATH
	_load()
	apply()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		using_touch = true
		using_gamepad = false
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		using_gamepad = true
		using_touch = false
	elif event is InputEventKey:
		using_gamepad = false
		using_touch = false
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		using_gamepad = false


## Marks a tutorial tip as shown (and saves, so it never comes back).
func mark_tip_seen(id: String) -> void:
	if id not in tips_seen:
		tips_seen.append(id)
		save()


## Scale for anything that flashes (screen spikes, blinking, light strobes).
func flash_scale() -> float:
	return 0.3 if reduce_flashing else 1.0


## Multiplier for every font size in the HUD and menus.
func text_scale() -> float:
	return 1.25 if large_text else 1.0


## Glyph for an action's button, matching the last-used device.
func glyph(action: String) -> String:
	match action:
		"interact":
			return "A" if using_gamepad else "E"
		"confirm":
			return "A" if using_gamepad else "ENTER"
		"pause":
			return "II" if using_touch else ("START" if using_gamepad else "ESC")
		"move":
			if using_touch:
				return "Drag on the left side of the screen"
			return "LEFT STICK" if using_gamepad else "WASD / ARROWS"
	return action.to_upper()


## A short buzz on touch screens (if Vibration is on). ms: 10-200.
## last_buzz is kept for tests.
var last_buzz := 0
func buzz(ms: int) -> void:
	if not vibration or not using_touch:
		return
	last_buzz = ms
	Input.vibrate_handheld(ms)


func set_value(key: String, value: Variant) -> void:
	if key == "tutorial_tips" and value:
		tips_seen.clear()  # switching tips back on replays them
	set(key, value)
	apply()
	save()
	changed.emit()


func apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(0, volume <= 0.001)
	for bus in ["Music", "Memory"]:
		_set_bus(bus, music_volume)
	for bus in ["SFX", "UI"]:
		_set_bus(bus, sfx_volume)
	UiStyle.rescale_text(get_tree())
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _set_bus(bus: String, linear: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i == -1:
		return
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(i, linear <= 0.001)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("accessibility", "glitch_intensity", glitch_intensity)
	cfg.set_value("accessibility", "reduce_flashing", reduce_flashing)
	cfg.set_value("accessibility", "vibration", vibration)
	cfg.set_value("video", "crt_curvature", crt_curvature)
	cfg.set_value("video", "screen_effects", screen_effects)
	cfg.set_value("accessibility", "large_text", large_text)
	cfg.set_value("help", "tutorial_tips", tutorial_tips)
	cfg.set_value("help", "tips_seen", tips_seen)
	cfg.save(_path)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_path) != OK:
		# First launch: phones get the lighter screen pass by default.
		if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
			screen_effects = 1
		return
	volume = clampf(float(cfg.get_value("audio", "volume", volume)), 0.0, 1.0)
	music_volume = clampf(float(cfg.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))
	glitch_intensity = clampf(float(cfg.get_value("accessibility", "glitch_intensity", glitch_intensity)), 0.0, 1.0)
	reduce_flashing = bool(cfg.get_value("accessibility", "reduce_flashing", reduce_flashing))
	vibration = bool(cfg.get_value("accessibility", "vibration", vibration))
	crt_curvature = bool(cfg.get_value("video", "crt_curvature", crt_curvature))
	screen_effects = clampi(int(cfg.get_value("video", "screen_effects", screen_effects)), 0, 2)
	large_text = bool(cfg.get_value("accessibility", "large_text", large_text))
	tutorial_tips = bool(cfg.get_value("help", "tutorial_tips", tutorial_tips))
	var seen: Variant = cfg.get_value("help", "tips_seen", [])
	tips_seen = seen if seen is Array else []

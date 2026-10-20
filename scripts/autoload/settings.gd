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
## Character voices and typing (the Voice bus).
var voice_volume := 0.9
## Opt-in system speech for dialogue and cinematic narration.
var narration := false
## The world shaking and jittering (events and high awareness). Off keeps
## every other effect; nothing gameplay-relevant is shown only by shake.
var screen_shake := true
## How fast text appears: 0 slow, 1 normal, 2 fast, 3 instant.
var text_speed := 1
## Story lines (dialogue box, cinematics): 0 = manual (each press reveals,
## then advances; the default, so nobody is rushed), 1 = automatic.
var advance_mode := 0
## Automatic reading pace (StoryPacing.READ_SPEEDS): 0 slow, 1 normal, 2 fast.
var auto_speed := 1
## Pause after a voiced line ends, in auto mode (StoryPacing.VOICE_DELAYS).
var voice_delay := 1
## Subtitle text size (dialogue, cinematics, console): 0 normal, 1 large, 2 larger.
var subtitle_size := 0
## Opacity of the backing behind subtitles and the console, 0..1.
var subtitle_bg := 0.75
## Show who is speaking (name above dialogue, "NAME:" in the console).
var speaker_labels := true
## Pause the game when its window loses focus (alt-tab, a phone call).
var pause_on_focus_loss := true
var fullscreen := false
## 0..1 multiplier for screen tearing, chromatic split and grain.
var glitch_intensity := 1.0
## The old CRT screen (curved glass, scanlines, grille). Off by default: the
## picture is clean and the screen only degrades when something is wrong.
var crt_screen := false
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
## The opening film has been seen (or skipped) once: it doesn't play again
## on its own. The title's "Opening" button replays it.
var opening_seen := false
## Whether the last input came from a gamepad (for button prompts).
var using_gamepad := false
## Whether the last input was a touch (phones, tablets): prompts then name
## the on-screen buttons, and TouchControls shows them.
var using_touch := false

var _path := PATH


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiStyle.install_fonts()
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
## Multiplier for how fast text types out (TEXT_SPEEDS), INF = instant.
const TEXT_SPEEDS := [0.6, 1.0, 1.8, INF]
func text_rate() -> float:
	return TEXT_SPEEDS[clampi(text_speed, 0, 3)]


func flash_scale() -> float:
	return 0.3 if reduce_flashing else 1.0


## Multiplier for subtitle text, on top of text_scale().
const SUBTITLE_SCALES := [1.0, 1.2, 1.4]
func subtitle_scale() -> float:
	return SUBTITLE_SCALES[clampi(subtitle_size, 0, 2)]


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


## A short buzz on touch screens, or a rumble on a gamepad (if Vibration is
## on). ms: 10-200. last_buzz is kept for tests.
var last_buzz := 0
func buzz(ms: int) -> void:
	if not vibration or not (using_touch or using_gamepad):
		return
	last_buzz = ms
	if using_touch:
		Input.vibrate_handheld(ms)
		return
	# Longer buzzes are the heavier ones (a death is 160): rumble harder.
	var strong := clampf(ms / 200.0, 0.0, 1.0)
	for pad in Input.get_connected_joypads():
		Input.start_joy_vibration(pad, clampf(0.3 + strong, 0.0, 1.0), strong, ms / 1000.0)


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
	apply_music()
	for bus in ["SFX", "UI"]:
		_set_bus(bus, sfx_volume)
	_set_bus("Voice", voice_volume)
	UiStyle.rescale_text(get_tree())
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


## Music and the memory theme: the player's volume, less the speech duck
## (Sfx.speech_duck_db(), never above 0 dB).
func apply_music() -> void:
	var sfx := get_node_or_null("/root/Sfx")
	var duck: float = minf(0.0, sfx.speech_duck_db()) if sfx else 0.0
	for bus in ["Music", "Memory"]:
		_set_bus(bus, music_volume, duck)


func _set_bus(bus: String, linear: float, offset_db := 0.0) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i == -1:
		return
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(linear, 0.0001)) + offset_db)
	AudioServer.set_bus_mute(i, linear <= 0.001)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "voice_volume", voice_volume)
	cfg.set_value("accessibility", "narration", narration)
	cfg.set_value("accessibility", "text_speed", text_speed)
	cfg.set_value("story", "advance_mode", advance_mode)
	cfg.set_value("story", "auto_speed", auto_speed)
	cfg.set_value("story", "voice_delay", voice_delay)
	cfg.set_value("story", "subtitle_size", subtitle_size)
	cfg.set_value("story", "subtitle_bg", subtitle_bg)
	cfg.set_value("story", "speaker_labels", speaker_labels)
	cfg.set_value("story", "pause_on_focus_loss", pause_on_focus_loss)
	cfg.set_value("accessibility", "screen_shake", screen_shake)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("accessibility", "glitch_intensity", glitch_intensity)
	cfg.set_value("accessibility", "reduce_flashing", reduce_flashing)
	cfg.set_value("accessibility", "vibration", vibration)
	cfg.set_value("video", "crt_screen", crt_screen)
	cfg.set_value("video", "screen_effects", screen_effects)
	cfg.set_value("accessibility", "large_text", large_text)
	cfg.set_value("help", "tutorial_tips", tutorial_tips)
	cfg.set_value("help", "tips_seen", tips_seen)
	cfg.set_value("help", "opening_seen", opening_seen)
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
	voice_volume = clampf(float(cfg.get_value("audio", "voice_volume", voice_volume)), 0.0, 1.0)
	text_speed = clampi(int(cfg.get_value("accessibility", "text_speed", text_speed)), 0, 3)
	advance_mode = clampi(int(cfg.get_value("story", "advance_mode", advance_mode)), 0, 1)
	auto_speed = clampi(int(cfg.get_value("story", "auto_speed", auto_speed)), 0, 2)
	voice_delay = clampi(int(cfg.get_value("story", "voice_delay", voice_delay)), 0, 3)
	subtitle_size = clampi(int(cfg.get_value("story", "subtitle_size", subtitle_size)), 0, 2)
	subtitle_bg = clampf(float(cfg.get_value("story", "subtitle_bg", subtitle_bg)), 0.0, 1.0)
	speaker_labels = bool(cfg.get_value("story", "speaker_labels", speaker_labels))
	pause_on_focus_loss = bool(cfg.get_value("story", "pause_on_focus_loss", pause_on_focus_loss))
	var narration_v: Variant = cfg.get_value("accessibility", "narration", false)
	narration = narration_v if narration_v is bool else false
	var shake_v: Variant = cfg.get_value("accessibility", "screen_shake", screen_shake)
	screen_shake = shake_v if shake_v is bool else true
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))
	glitch_intensity = clampf(float(cfg.get_value("accessibility", "glitch_intensity", glitch_intensity)), 0.0, 1.0)
	reduce_flashing = bool(cfg.get_value("accessibility", "reduce_flashing", reduce_flashing))
	vibration = bool(cfg.get_value("accessibility", "vibration", vibration))
	# The old "crt_curvature" key was on by default for everyone, so it isn't
	# read as a choice: the clean screen is the new default (docs/VISUAL_DIRECTION.md).
	crt_screen = bool(cfg.get_value("video", "crt_screen", crt_screen))
	screen_effects = clampi(int(cfg.get_value("video", "screen_effects", screen_effects)), 0, 2)
	large_text = bool(cfg.get_value("accessibility", "large_text", large_text))
	tutorial_tips = bool(cfg.get_value("help", "tutorial_tips", tutorial_tips))
	var seen: Variant = cfg.get_value("help", "tips_seen", [])
	tips_seen = seen if seen is Array else []
	opening_seen = bool(cfg.get_value("help", "opening_seen", false))

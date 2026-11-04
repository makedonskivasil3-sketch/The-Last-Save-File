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
## System TTS only; recorded performances retain their authored speed.
var speech_rate := 2
const SPEECH_RATES := [0.75, 0.85, 1.0, 1.1]
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
## Owner pace (docs/prompts/NEXT_PASS_2026-10-29.md §2): 0 normal, 1 gentle.
## Gentle slows the threats down; it changes no story, purge or ending.
var owner_pace := 0
## No parallax, camera drift, pushes or follow: the picture holds still
## (the title room, the opening's push, area cameras).
var reduce_motion := false
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
## The one controller the player is using (its device id; -1: none yet).
## One player: only this pad's loss holds the game, and only it rumbles.
var active_pad := -1

var _path := PATH


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiStyle.install_fonts()
	if "--test-mode" in OS.get_cmdline_user_args():
		_path = TEST_PATH
	_load()
	apply()
	apply_binds()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		using_touch = true
		using_gamepad = false
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		using_gamepad = true
		using_touch = false
		active_pad = event.device
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


## How fast a threat runs at this Owner pace: "arin" and "cursor" move at
## this share of their speed, "static" spreads at it, and a death spot's
## "warning" lasts this many times as long. 1.0 at Normal, always.
const GENTLE := {"arin": 0.8, "cursor": 0.8, "static": 0.6, "warning": 2.0}
func pace(kind: String) -> float:
	return float(GENTLE.get(kind, 1.0)) if owner_pace == 1 else 1.0


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
# --- control remapping (keyboard) --------------------------------------------

## Actions the player can rebind, and their default keys (physical, so the
## defaults sit in the same place on any layout). The arrow keys (movement)
## and Esc (pause) stay as fixed fallbacks: nobody can lock themselves out.
const REBINDABLE := ["move_up", "move_down", "move_left", "move_right", "interact", "pause"]
const DEFAULT_KEYS := {"move_up": KEY_W, "move_down": KEY_S, "move_left": KEY_A, "move_right": KEY_D, "interact": KEY_E, "pause": KEY_ESCAPE}
const FIXED_KEYS := {"move_up": KEY_UP, "move_down": KEY_DOWN, "move_left": KEY_LEFT, "move_right": KEY_RIGHT, "pause": KEY_ESCAPE}
const ACTION_NAMES := {"move_up": "Move up", "move_down": "Move down", "move_left": "Move left", "move_right": "Move right", "interact": "Interact", "pause": "Pause"}
## action -> physical keycode, only where the player changed it.
var key_binds: Dictionary = {}


func key_for(action: String) -> int:
	return int(key_binds.get(action, DEFAULT_KEYS.get(action, KEY_NONE)))


func key_label(action: String) -> String:
	var code := key_for(action)
	# The layout's own letter where the display server can tell (desktop);
	# the web and headless servers can't, so the physical key's name is used.
	var shown := code
	if DisplayServer.get_name() not in ["headless", "Web"] and not OS.has_feature("web"):
		shown = DisplayServer.keyboard_get_keycode_from_physical(code)
	var label := OS.get_keycode_string(shown if shown != KEY_NONE else code)
	return label.to_upper() if label != "" else "?"


## Binds `action` to `keycode`. Returns "" when done, or why not (the key is
## already used: by another action, a fixed fallback or a menu key).
func bind_key(action: String, keycode: int) -> String:
	if action not in REBINDABLE:
		return "that can't be changed."
	if keycode in [KEY_NONE, KEY_ESCAPE] and action != "pause":
		return "Esc is kept for pausing."
	for other: String in REBINDABLE:
		if other != action and (key_for(other) == keycode or int(FIXED_KEYS.get(other, KEY_NONE)) == keycode):
			return "%s already uses %s." % [ACTION_NAMES[other], OS.get_keycode_string(keycode)]
	if keycode in [KEY_ENTER, KEY_KP_ENTER] and action != "interact":
		return "Enter is kept for confirming."
	if keycode == int(DEFAULT_KEYS[action]):
		key_binds.erase(action)
	else:
		key_binds[action] = keycode
	apply_binds()
	save()
	return ""


func reset_binds() -> void:
	key_binds.clear()
	pad_binds.clear()
	apply_binds()
	save()


## Puts the bindings into the InputMap: each rebindable action's own key is
## replaced; its fixed fallback (and pads, Space for interact) stay.
func apply_binds() -> void:
	for action: String in REBINDABLE:
		if not InputMap.has_action(action):
			continue
		var own := key_for(action)
		var keep := [int(FIXED_KEYS.get(action, KEY_NONE))]
		if action == "interact":
			keep.append(KEY_SPACE)
		for e in InputMap.action_get_events(action):
			if e is InputEventKey and int((e as InputEventKey).physical_keycode) not in keep:
				InputMap.action_erase_event(action, e)
		if own not in keep:
			var ev := InputEventKey.new()
			ev.physical_keycode = own
			InputMap.action_add_event(action, ev)
	# Pads: the action's own button replaces the default; Start stays on pause.
	for action: String in PAD_REBINDABLE:
		if not InputMap.has_action(action):
			continue
		var fixed := int(FIXED_PADS.get(action, JOY_BUTTON_INVALID))
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton and int((e as InputEventJoypadButton).button_index) != fixed:
				InputMap.action_erase_event(action, e)
		if pad_for(action) != fixed:
			var pe := InputEventJoypadButton.new()
			pe.button_index = pad_for(action) as JoyButton
			InputMap.action_add_event(action, pe)


# --- control remapping (gamepad) ---------------------------------------------

## Pad buttons the player can rebind (movement stays on the stick and the
## d-pad). B is kept for backing out of menus and Start stays a pause
## fallback, so nobody can lock themselves out.
const PAD_REBINDABLE := ["interact", "pause"]
const DEFAULT_PADS := {"interact": JOY_BUTTON_A, "pause": JOY_BUTTON_START}
const FIXED_PADS := {"pause": JOY_BUTTON_START}
const PAD_NAMES := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_BACK: "BACK", JOY_BUTTON_START: "START", JOY_BUTTON_GUIDE: "HOME",
	JOY_BUTTON_DPAD_UP: "D-PAD UP", JOY_BUTTON_DPAD_DOWN: "D-PAD DOWN",
	JOY_BUTTON_DPAD_LEFT: "D-PAD LEFT", JOY_BUTTON_DPAD_RIGHT: "D-PAD RIGHT",
}
## action -> JoyButton, only where the player changed it.
var pad_binds: Dictionary = {}


func pad_for(action: String) -> int:
	return int(pad_binds.get(action, DEFAULT_PADS.get(action, JOY_BUTTON_INVALID)))


func pad_label(action: String) -> String:
	return str(PAD_NAMES.get(pad_for(action), "BUTTON %d" % pad_for(action)))


## Binds `action` to a pad button. Returns "" when done, or why not.
func bind_pad(action: String, button: int) -> String:
	if action not in PAD_REBINDABLE:
		return "that can't be changed."
	if button == JOY_BUTTON_B:
		return "B is kept for going back."
	if button == JOY_BUTTON_GUIDE:
		return "the home button belongs to the system."
	if button in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
		return "the d-pad moves Rue."
	for other: String in PAD_REBINDABLE:
		if other != action and (pad_for(other) == button or int(FIXED_PADS.get(other, JOY_BUTTON_INVALID)) == button):
			return "%s already uses %s." % [ACTION_NAMES[other], PAD_NAMES.get(button, "that button")]
	if button == int(DEFAULT_PADS[action]):
		pad_binds.erase(action)
	else:
		pad_binds[action] = button
	apply_binds()
	save()
	return ""


func glyph(action: String) -> String:
	match action:
		"interact":
			return pad_label("interact") if using_gamepad else key_label("interact")
		"confirm":
			return "A" if using_gamepad else "ENTER"
		"pause":
			return "II" if using_touch else ((pad_label("pause") if pad_for("pause") == JOY_BUTTON_START else pad_label("pause") + " / START") if using_gamepad else ("ESC" if key_for("pause") == KEY_ESCAPE else key_label("pause") + " / ESC"))
		"move":
			if using_touch:
				return "Drag on the left side of the screen"
			if using_gamepad:
				return "LEFT STICK"
			var keys := ""
			for a in ["move_up", "move_left", "move_down", "move_right"]:
				keys += key_label(a)
			return ("WASD" if keys == "WASD" else keys) + " / ARROWS"
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
	for pad in rumble_pads(Input.get_connected_joypads()):
		Input.start_joy_vibration(pad, clampf(0.3 + strong, 0.0, 1.0), strong, ms / 1000.0)


## Which of the connected pads a rumble goes to: the player's, only.
func rumble_pads(connected: Array) -> Array:
	return [active_pad] if using_gamepad and active_pad in connected else []


## Does this pad dropping out take the player's controller away?
func is_players_pad(device: int) -> bool:
	return using_gamepad and (device == active_pad or active_pad == -1)


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
	cfg.set_value("accessibility", "speech_rate", speech_rate)
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
	cfg.set_value("accessibility", "owner_pace", owner_pace)
	cfg.set_value("accessibility", "vibration", vibration)
	cfg.set_value("accessibility", "reduce_motion", reduce_motion)
	cfg.set_value("video", "crt_screen", crt_screen)
	cfg.set_value("video", "screen_effects", screen_effects)
	cfg.set_value("accessibility", "large_text", large_text)
	cfg.set_value("help", "tutorial_tips", tutorial_tips)
	cfg.set_value("help", "tips_seen", tips_seen)
	cfg.set_value("help", "opening_seen", opening_seen)
	cfg.set_value("controls", "keys", key_binds)
	cfg.set_value("controls", "pads", pad_binds)
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
	var speech_v: Variant = cfg.get_value("accessibility", "speech_rate", 2)
	speech_rate = clampi(int(speech_v), 0, SPEECH_RATES.size() - 1) if (speech_v is int or speech_v is float) and is_finite(float(speech_v)) else 2
	var shake_v: Variant = cfg.get_value("accessibility", "screen_shake", screen_shake)
	screen_shake = shake_v if shake_v is bool else true
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))
	glitch_intensity = clampf(float(cfg.get_value("accessibility", "glitch_intensity", glitch_intensity)), 0.0, 1.0)
	reduce_flashing = bool(cfg.get_value("accessibility", "reduce_flashing", reduce_flashing))
	owner_pace = clampi(int(cfg.get_value("accessibility", "owner_pace", owner_pace)), 0, 1)
	vibration = bool(cfg.get_value("accessibility", "vibration", vibration))
	reduce_motion = bool(cfg.get_value("accessibility", "reduce_motion", reduce_motion))
	# The old "crt_curvature" key was on by default for everyone, so it isn't
	# read as a choice: the clean screen is the new default (docs/VISUAL_DIRECTION.md).
	crt_screen = bool(cfg.get_value("video", "crt_screen", crt_screen))
	screen_effects = clampi(int(cfg.get_value("video", "screen_effects", screen_effects)), 0, 2)
	large_text = bool(cfg.get_value("accessibility", "large_text", large_text))
	tutorial_tips = bool(cfg.get_value("help", "tutorial_tips", tutorial_tips))
	var seen: Variant = cfg.get_value("help", "tips_seen", [])
	tips_seen = seen if seen is Array else []
	opening_seen = bool(cfg.get_value("help", "opening_seen", false))
	pad_binds = {}
	var pads: Variant = cfg.get_value("controls", "pads", {})
	if pads is Dictionary:
		for a in pads:
			if a in PAD_REBINDABLE and (pads[a] is int) and int(pads[a]) >= 0 and int(pads[a]) != JOY_BUTTON_B:
				pad_binds[a] = int(pads[a])
	key_binds = {}
	var binds: Variant = cfg.get_value("controls", "keys", {})
	if binds is Dictionary:
		for a in binds:
			if a in REBINDABLE and (binds[a] is int) and int(binds[a]) > 0:
				key_binds[a] = int(binds[a])

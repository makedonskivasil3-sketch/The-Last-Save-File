class_name SettingsPanel
extends VBoxContainer
## Sound, picture, comfort and help options in two columns. Used by the title screen and
## the pause menu. Changes apply and save immediately.

signal closed
signal memory_wiped

## The title screen also offers wiping the owner's memory.
var show_reset := false

const SOUND_CHECK := preload("res://scripts/ui/sound_check.gd")

var _first: Control
var _master: HSlider
var _music_slider: HSlider
var _effects: HSlider
var _reset_button: Button
var _reset_armed := false
var _narration: CheckButton
## Control remapping: one button per action; the one waiting for a key.
var _bind_buttons := {}
var _binding := ""
var _bind_note: Label


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	UiStyle.heading(self, "SETTINGS", UiStyle.TEXT, 14)
	# Two columns so everything fits on a 360-pixel-high screen, even with
	# large text: sound and picture on the left, comfort and help on the right.
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 232
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	add_child(scroll)
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(columns)
	var left := _column(columns)
	var right := _column(columns)

	_section(left, "SOUND")
	_first = _slider(left, "Master", Settings.volume, func(v: float) -> void: Settings.set_value("volume", v))
	_master = _first
	_music_slider = _slider(left, "Music", Settings.music_volume, func(v: float) -> void: Settings.set_value("music_volume", v))
	_effects = _slider(left, "Effects", Settings.sfx_volume, _on_effects_volume)
	var voices := _slider(left, "Voices", Settings.voice_volume, func(v: float) -> void:
		Settings.set_value("voice_volume", v)
		Sfx.voice_blip("MIRA"))  # so you hear the level you're choosing
	# Can you hear it? Effect, music box, voice; and the defaults back.
	var check: Node = SOUND_CHECK.new()
	check.name = "SoundCheck"
	left.add_child(check)
	check.defaults_restored.connect(func() -> void:
		for pair in [[_master, Settings.volume], [_music_slider, Settings.music_volume], [_effects, Settings.sfx_volume], [voices, Settings.voice_volume]]:
			pair[0].set_value_no_signal(pair[1]))
	_section(left, "PICTURE")
	_check(left, "Fullscreen", Settings.fullscreen, func(on: bool) -> void: Settings.set_value("fullscreen", on))
	_check(left, "CRT screen", Settings.crt_screen, func(on: bool) -> void: Settings.set_value("crt_screen", on))
	var fx_button := Button.new()
	fx_button.focus_mode = Control.FOCUS_ALL
	fx_button.pressed.connect(_cycle_effects.bind(fx_button))
	left.add_child(fx_button)
	_label_effects(fx_button)

	_section(right, "COMFORT")
	_slider(right, "Glitch", Settings.glitch_intensity, func(v: float) -> void: Settings.set_value("glitch_intensity", v))
	_check(right, "Reduce flashing", Settings.reduce_flashing, func(on: bool) -> void: Settings.set_value("reduce_flashing", on))
	_check(right, "Reduce motion", Settings.reduce_motion, func(on: bool) -> void: Settings.set_value("reduce_motion", on))
	_check(right, "Screen shake", Settings.screen_shake, func(on: bool) -> void: Settings.set_value("screen_shake", on))
	_check(right, "Large text", Settings.large_text, func(on: bool) -> void: Settings.set_value("large_text", on))
	_check(right, "Vibration", Settings.vibration, func(on: bool) -> void: Settings.set_value("vibration", on))
	_check(right, "Pause when unfocused", Settings.pause_on_focus_loss, func(on: bool) -> void: Settings.set_value("pause_on_focus_loss", on))
	# Story text (docs/STORY_PACING.md): how lines appear, advance and look.
	_section(left, "STORY TEXT")
	var speed_button := Button.new()
	speed_button.focus_mode = Control.FOCUS_ALL
	speed_button.pressed.connect(_cycle_text_speed.bind(speed_button))
	left.add_child(speed_button)  # the left column has the room, even with large text
	_label_text_speed(speed_button)
	_cycler(left, "advance_mode", ["Advance: Manual", "Advance: Auto"],
		"Manual: the first press shows the whole line, the next press moves on. Auto: lines move on once read (and spoken).")
	_cycler(left, "auto_speed", ["Auto reading: Slow", "Auto reading: Normal", "Auto reading: Fast"],
		"How long auto mode leaves each line on screen. Also paces the console.")
	_cycler(left, "voice_delay", ["After voice: 0 s", "After voice: 0.5 s", "After voice: 1 s", "After voice: 2 s"],
		"In auto mode, the pause after a spoken line ends.")
	_cycler(left, "subtitle_size", ["Subtitles: Normal", "Subtitles: Large", "Subtitles: Larger"], "Size of dialogue, scene and console text.")
	_slider(left, "Text backing", Settings.subtitle_bg, func(v: float) -> void: Settings.set_value("subtitle_bg", v))
	_check(left, "Speaker names", Settings.speaker_labels, func(on: bool) -> void: Settings.set_value("speaker_labels", on))
	_section(right, "HELP")
	_check(right, "Tutorial tips", Settings.tutorial_tips, func(on: bool) -> void: Settings.set_value("tutorial_tips", on))
	_narration = _check(right, "Spoken narration", Settings.narration, func(on: bool) -> void: Settings.set_value("narration", on))
	_cycler(right, "speech_rate", ["Speech: 0.75x", "Speech: 0.85x", "Speech: 1.0x", "Speech: 1.1x"], "System speech only. A change stops the current utterance; captions remain and the next line uses the new rate. Recordings are unchanged.")
	# The device is asked for voices when these settings are on screen, not
	# when the menu is built (A24). (Deferred: a menu built inside a box that
	# is hidden right after, like the title's, is never on screen and asks nothing.)
	visibility_changed.connect(_refresh_narration)
	_refresh_narration.call_deferred()
	# Controls (keyboard): press a button, then the key. Arrows and Esc stay.
	_section(right, "CONTROLS")
	for action: String in Settings.REBINDABLE:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_start_binding.bind(action))
		right.add_child(b)
		_bind_buttons[action] = b
	UiStyle.button(right, "Reset controls", func() -> void:
		Settings.reset_binds()
		_bind_note.text = "controls back to their defaults."
		_label_binds())
	_bind_note = UiStyle.note(right, "arrow keys and Esc always work too.", UiStyle.MUTED)
	_label_binds()
	if show_reset:
		_reset_button = UiStyle.button(right, "Reset owner memory", _on_reset)

	UiStyle.button(self, "Back", func() -> void: closed.emit(), "ui_back")


func _label_binds() -> void:
	for action: String in _bind_buttons:
		var b: Button = _bind_buttons[action]
		b.text = "%s: %s" % [Settings.ACTION_NAMES[action], "press a key..." if action == _binding else Settings.key_label(action)]


func _start_binding(action: String) -> void:
	_binding = action
	_bind_note.text = "press the new key for %s (Backspace cancels)." % Settings.ACTION_NAMES[action].to_lower()
	_label_binds()


## The key that comes next is the new binding (Backspace cancels).
func _input(event: InputEvent) -> void:
	if _binding == "" or not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	var key := event as InputEventKey
	var code := int(key.physical_keycode) if key.physical_keycode != KEY_NONE else int(key.keycode)
	var action := _binding
	_binding = ""
	if code == KEY_BACKSPACE:
		_bind_note.text = "unchanged."
	else:
		var why := Settings.bind_key(action, code)
		_bind_note.text = ("%s: %s" % [Settings.ACTION_NAMES[action], Settings.key_label(action)]) if why == "" else "not changed: " + why
	_label_binds()
	if _bind_buttons.has(action):
		(_bind_buttons[action] as Button).grab_focus()


func _refresh_narration() -> void:
	if not is_visible_in_tree() or _narration == null:
		return
	_narration.disabled = not Narration.available()
	_narration.tooltip_text = "Reads dialogue and story scenes using an English system voice. Uses Master and Voices volume." if not _narration.disabled else "No English system voice is available. Install a system voice and restart the game. Text and character sounds remain available."


func focus_first() -> void:
	_first.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		closed.emit()


## Effects volume, with a tick so you can hear the level you're choosing.
func _on_effects_volume(v: float) -> void:
	Settings.set_value("sfx_volume", v)
	Sfx.ui("ui_move")


## Full -> Light -> Off -> Full.
func _cycle_effects(b: Button) -> void:
	Settings.set_value("screen_effects", (Settings.screen_effects + 2) % 3)
	_label_effects(b)


func _label_effects(b: Button) -> void:
	b.text = "Screen: %s" % ["Off", "Light", "Full"][Settings.screen_effects]


func _cycle_text_speed(b: Button) -> void:
	Settings.set_value("text_speed", (Settings.text_speed + 1) % Settings.TEXT_SPEEDS.size())
	_label_text_speed(b)


func _label_text_speed(b: Button) -> void:
	b.text = "Text reveal: %s" % ["Slow", "Normal", "Fast", "Instant"][Settings.text_speed]


## A button that cycles an int setting through `labels`.
func _cycler(parent: Control, key: String, labels: Array, tip: String) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_ALL
	b.tooltip_text = tip
	b.text = labels[clampi(int(Settings.get(key)), 0, labels.size() - 1)]
	b.pressed.connect(func() -> void:
		Settings.set_value(key, (int(Settings.get(key)) + 1) % labels.size())
		b.text = labels[int(Settings.get(key))])
	parent.add_child(b)
	return b


func _on_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_button.text = "Forget everything? Press again"
		return
	OwnerMemory.wipe()
	memory_wiped.emit()
	_reset_armed = false
	_reset_button.text = "The owner forgot you."
	_reset_button.disabled = true


func _column(parent: Control) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(col)
	return col


func _section(parent: Control, title: String) -> void:
	var l := Label.new()
	l.text = title
	UiStyle.sized(l, 9)
	l.add_theme_color_override("font_color", UiStyle.MUTED)
	parent.add_child(l)


func _slider(parent: Control, label: String, value: float, on_change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.custom_minimum_size.x = 70
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size.x = 110
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.focus_mode = Control.FOCUS_ALL
	s.value_changed.connect(on_change)
	row.add_child(s)
	parent.add_child(row)
	return s


func _check(parent: Control, label: String, value: bool, on_toggle: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.text = label
	c.button_pressed = value
	c.focus_mode = Control.FOCUS_ALL
	c.toggled.connect(on_toggle)
	parent.add_child(c)
	return c

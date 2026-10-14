class_name SettingsPanel
extends VBoxContainer
## Sound, picture, comfort and help options in two columns. Used by the title screen and
## the pause menu. Changes apply and save immediately.

signal closed
signal memory_wiped

## The title screen also offers wiping the owner's memory.
var show_reset := false

var _first: Control
var _reset_button: Button
var _reset_armed := false


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	UiStyle.heading(self, "SETTINGS", UiStyle.TEXT, 14)
	# Two columns so everything fits on a 360-pixel-high screen, even with
	# large text: sound and picture on the left, comfort and help on the right.
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	add_child(columns)
	var left := _column(columns)
	var right := _column(columns)

	_section(left, "SOUND")
	_first = _slider(left, "Master", Settings.volume, func(v: float) -> void: Settings.set_value("volume", v))
	_slider(left, "Music", Settings.music_volume, func(v: float) -> void: Settings.set_value("music_volume", v))
	_slider(left, "Effects", Settings.sfx_volume, _on_effects_volume)
	_section(left, "PICTURE")
	_check(left, "Fullscreen", Settings.fullscreen, func(on: bool) -> void: Settings.set_value("fullscreen", on))
	_check(left, "CRT curvature", Settings.crt_curvature, func(on: bool) -> void: Settings.set_value("crt_curvature", on))
	var fx_button := Button.new()
	fx_button.focus_mode = Control.FOCUS_ALL
	fx_button.pressed.connect(_cycle_effects.bind(fx_button))
	left.add_child(fx_button)
	_label_effects(fx_button)

	_section(right, "COMFORT")
	_slider(right, "Glitch", Settings.glitch_intensity, func(v: float) -> void: Settings.set_value("glitch_intensity", v))
	_check(right, "Reduce flashing", Settings.reduce_flashing, func(on: bool) -> void: Settings.set_value("reduce_flashing", on))
	_check(right, "Large text", Settings.large_text, func(on: bool) -> void: Settings.set_value("large_text", on))
	_section(right, "HELP")
	_check(right, "Tutorial tips", Settings.tutorial_tips, func(on: bool) -> void: Settings.set_value("tutorial_tips", on))
	if show_reset:
		_reset_button = UiStyle.button(right, "Reset owner memory", _on_reset)

	UiStyle.button(self, "Back", func() -> void: closed.emit(), "ui_back")


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

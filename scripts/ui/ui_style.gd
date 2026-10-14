class_name UiStyle
extends RefCounted
## Shared look for menus: dark panels, thin borders, the owner's orange on
## hover and the intruder's cyan on keyboard/gamepad focus.

const BG := Color(0.02, 0.016, 0.024, 0.94)
const TEXT := Color("c8b8a0")
const MUTED := Color("8a8f98")
const OWNER := Color("e0704f")
const INTRUDER := Color("8cf2ff")


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 11
	for type in ["Button", "CheckButton"]:
		t.set_stylebox("normal", type, _box(Color(1, 1, 1, 0.03), Color(1, 1, 1, 0.12)))
		t.set_stylebox("hover", type, _box(Color(1, 1, 1, 0.06), OWNER))
		t.set_stylebox("pressed", type, _box(Color(OWNER, 0.2), OWNER))
		t.set_stylebox("hover_pressed", type, _box(Color(OWNER, 0.2), OWNER))
		t.set_stylebox("focus", type, _box(Color(0, 0, 0, 0), INTRUDER))
		t.set_stylebox("disabled", type, _box(Color(0, 0, 0, 0), Color(1, 1, 1, 0.05)))
		t.set_color("font_color", type, TEXT)
		t.set_color("font_hover_color", type, Color.WHITE)
		t.set_color("font_focus_color", type, INTRUDER)
		t.set_color("font_pressed_color", type, Color.WHITE)
		t.set_color("font_hover_pressed_color", type, Color.WHITE)
		t.set_color("font_disabled_color", type, Color(MUTED, 0.5))
	t.set_color("font_color", "Label", TEXT)
	var slider_focus := StyleBoxFlat.new()
	slider_focus.draw_center = false
	slider_focus.set_border_width_all(1)
	slider_focus.border_color = INTRUDER
	slider_focus.set_expand_margin_all(3)
	t.set_stylebox("focus", "HSlider", slider_focus)
	return t


## A centered, bordered panel holding a VBox. Returns the VBox.
static func centered_panel(parent: Control, width: float) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(center)
	var panel := PanelContainer.new()
	var box := _box(BG, Color(1, 1, 1, 0.1))
	box.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", box)
	panel.custom_minimum_size.x = width
	center.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)
	return vbox


static func heading(parent: Control, text: String, color := OWNER, size := 16) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


static func note(parent: Control, text: String, color := MUTED) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


static func button(parent: Control, text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(on_pressed)
	parent.add_child(b)
	return b


static func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(1)
	s.border_color = border
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s

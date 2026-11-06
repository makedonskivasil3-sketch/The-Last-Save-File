class_name StoryTouchControl
extends Control
## Explicit touch/mouse ownership for the opening's Continue and hold Skip.
## Keyboard/controller actions remain with the reader. No mouse emulation
## is required and canceled pointers never activate a tap.

signal tapped
var text := "Continue"
var hold_only := false
var progress := 0.0
var enabled := true:
	set(value):
		enabled = value
		if not value:
			cancel()
var disabled: bool:
	get:
		return not enabled
	set(value):
		enabled = not value
var _finger := -1
var _mouse := false
var _down := false
var _box := StyleBoxFlat.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.set_border_width_all(1)
	_box.set_corner_radius_all(4)


func is_held() -> bool:
	return enabled and is_visible_in_tree() and _down


func cancel() -> void:
	_finger = -1
	_mouse = false
	_down = false
	progress = 0.0
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel()


func _input(event: InputEvent) -> void:
	if not enabled or not is_visible_in_tree():
		return
	var rect := get_global_rect()
	if event is InputEventScreenTouch:
		Settings.using_touch = true
		Settings.using_gamepad = false
		if event.index == _finger:
			if event.canceled or not event.pressed:
				var activate: bool = _down and not event.canceled and rect.has_point(event.position)
				cancel()
				get_viewport().set_input_as_handled()
				if activate and not hold_only:
					tapped.emit()
		elif event.pressed and not event.canceled and _finger == -1 and not _mouse and rect.has_point(event.position):
			_finger = event.index
			_down = true
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _finger:
		if not rect.has_point(event.position):
			_down = false  # must lift and press again after dragging out
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _finger == -1 and rect.has_point(event.position):
			_mouse = true
			_down = true
			get_viewport().set_input_as_handled()
		elif not event.pressed and _mouse:
			var activate: bool = _down and rect.has_point(event.position)
			cancel()
			get_viewport().set_input_as_handled()
			if activate and not hold_only:
				tapped.emit()
	elif event is InputEventMouseMotion and _mouse and not rect.has_point(event.position):
		_down = false
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_box.bg_color = Color("24414b") if is_held() else Color("161c27")
	_box.border_color = Color("8cf2ff") if enabled else Color("58616d")
	draw_style_box(_box, Rect2(Vector2.ZERO, size))
	var font := UiStyle.system_font()
	var fs := roundi((9 if size.x < 100 else 10) * Settings.text_scale())
	var baseline := (size.y + font.get_ascent(fs) - font.get_descent(fs)) * 0.5
	draw_string(font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs,
		Color("e4f7fb") if enabled else Color("7c858e"))
	if hold_only and progress > 0:
		draw_rect(Rect2(2, size.y - 4, (size.x - 4) * clampf(progress, 0, 1), 2), Color("8cf2ff"))

class_name TouchControls
extends CanvasLayer
signal orientation_changed(portrait: bool)
## On-screen controls for phones and tablets. Hidden until the screen is
## touched (or on a mobile browser / device), then:
##   - a joystick wherever your thumb lands on the left side of the screen;
##   - an "E" button (interact, advance text, confirm) bottom right;
##   - a pause button "II" under the awareness meter.
## In portrait it asks you to turn the phone sideways.
##
## Buttons send the same input actions as the keyboard, so everything else in
## the game works unchanged. Positions are in the 640x360 game space.

const STICK_RADIUS := 34.0
const DEAD_ZONE := 0.18
## The joystick only starts in this part of the screen.
const STICK_ZONE := Rect2(0, 60, 300, 300)
const BUTTONS := {
	"interact": {"center": Vector2(588, 292), "radius": 30.0, "label": "E", "actions": ["interact", "confirm"]},
	"pause": {"center": Vector2(612, 90), "radius": 15.0, "label": "II", "actions": ["pause"]},
}
const CYAN := Color("8cf2ff")

var active := false
## Set by the glitch controller: what holding E would do ("" for nothing),
## and how far the hold has charged (0..1, or < 0 when not charging).
var hold_label := ""
var hold_progress := -1.0
## The title screen only wants the "turn sideways" notice: menus take taps.
var buttons_enabled := true

var _stick_finger := -1
var _stick_centre := Vector2.ZERO
var _stick_knob := Vector2.ZERO
## The stick's current direction. Re-applied every frame: in Godot 4.3, any
## parsed action event (the E button) releases actions set with action_press,
## which would stop Rue dead whenever you pressed E while running.
var _stick := Vector2.ZERO
## Finger index -> button name.
var _held: Dictionary = {}
var _draw_node: Control
var _portrait := false


func portrait_active() -> bool:
	return active and get_window().size.y > get_window().size.x


func _ready() -> void:
	layer = 18  # above the screen shader: crisp
	process_mode = Node.PROCESS_MODE_ALWAYS
	_draw_node = Control.new()
	_draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw_node.draw.connect(_on_draw)
	add_child(_draw_node)
	active = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel_touches()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		active = true
		if not buttons_enabled:
			return
		if event.canceled:
			_touch_up(event.index)
		elif event.pressed:
			_touch_down(event.index, event.position)
		else:
			_touch_up(event.index)
	elif event is InputEventScreenDrag and event.index == _stick_finger:
		_move_stick(event.position)


func _touch_down(finger: int, pos: Vector2) -> void:
	if get_window().size.y > get_window().size.x:
		return
	for name: String in BUTTONS:
		var b: Dictionary = BUTTONS[name]
		if pos.distance_to(b.center) <= b.radius + 6.0:
			if get_tree().paused and name != "pause":
				return  # menus take taps themselves
			_held[finger] = name
			for action in b.actions:
				_send(action, true)
			get_viewport().set_input_as_handled()
			return
	if get_tree().paused:
		return
	if _stick_finger == -1 and STICK_ZONE.has_point(pos):
		_stick_finger = finger
		_stick_centre = pos
		_stick_knob = pos


func _touch_up(finger: int) -> void:
	if _held.has(finger):
		for action in BUTTONS[_held[finger]].actions:
			_send(action, false)
		_held.erase(finger)
	if finger == _stick_finger:
		_stick_finger = -1
		_stick = Vector2.ZERO
		_set_move(Vector2.ZERO)


func _move_stick(pos: Vector2) -> void:
	var off := pos - _stick_centre
	if off.length() > STICK_RADIUS:
		off = off.normalized() * STICK_RADIUS
	_stick_knob = _stick_centre + off
	var v := off / STICK_RADIUS
	_stick = v if v.length() > DEAD_ZONE else Vector2.ZERO
	_set_move(_stick)


## The joystick drives the same four move actions as the keys, with strength.
func _set_move(v: Vector2) -> void:
	_axis("move_right", "move_left", v.x)
	_axis("move_down", "move_up", v.y)


func _axis(pos_action: String, neg_action: String, value: float) -> void:
	if value > 0.0:
		Input.action_press(pos_action, value)
		Input.action_release(neg_action)
	elif value < 0.0:
		Input.action_press(neg_action, -value)
		Input.action_release(pos_action)
	else:
		Input.action_release(pos_action)
		Input.action_release(neg_action)


## As a real input event, so handlers that read events (pause) see it too.
func _send(action: String, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)


func _process(_delta: float) -> void:
	var portrait := portrait_active()
	if portrait != _portrait:
		_portrait = portrait
		orientation_changed.emit(portrait)
	# Rotation must not leave an invisible joystick driving behind the notice.
	if active and get_window().size.y > get_window().size.x \
			and (_stick_finger != -1 or not _held.is_empty()):
		cancel_touches()
	if _stick_finger != -1:
		_set_move(_stick)
	_draw_node.visible = active
	if active:
		_draw_node.queue_redraw()


func _exit_tree() -> void:
	cancel_touches()


## A story panel takes over without leaving a virtual stick or E held.
func cancel_touches() -> void:
	for finger in _held.keys():
		_touch_up(finger)
	_stick_finger = -1
	_stick = Vector2.ZERO
	_set_move(Vector2.ZERO)


func _on_draw() -> void:
	var font := ThemeDB.fallback_font
	var win := Vector2(get_window().size)
	if win.y > win.x:
		# Portrait: the game is tiny like this.
		_draw_node.draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.85))
		_draw_node.draw_string(font, Vector2(0, 170), "turn your phone sideways", HORIZONTAL_ALIGNMENT_CENTER, 640, 18, CYAN)
		_draw_node.draw_string(font, Vector2(0, 196), "(landscape works best)", HORIZONTAL_ALIGNMENT_CENTER, 640, 11, Color(CYAN, 0.6))
		return
	if not buttons_enabled:
		return
	if _stick_finger != -1:
		_draw_node.draw_circle(_stick_centre, STICK_RADIUS, Color(1, 1, 1, 0.08))
		_draw_node.draw_arc(_stick_centre, STICK_RADIUS, 0.0, TAU, 32, Color(CYAN, 0.35), 1.5)
		_draw_node.draw_circle(_stick_knob, 12.0, Color(CYAN, 0.45))
	elif not get_tree().paused:
		_draw_node.draw_string(font, Vector2(24, 250), "drag here to move", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.18))
	for name: String in BUTTONS:
		if get_tree().paused and name != "pause":
			continue
		var b: Dictionary = BUTTONS[name]
		var held: bool = name in _held.values()
		_draw_node.draw_circle(b.center, b.radius, Color(CYAN, 0.32) if held else Color(0, 0, 0, 0.45))
		_draw_node.draw_arc(b.center, b.radius, 0.0, TAU, 32, Color(CYAN, 0.7), 1.5)
		var fs := 18 if b.radius > 20.0 else 10
		_draw_node.draw_string(font, b.center + Vector2(-b.radius, fs * 0.35), b.label, HORIZONTAL_ALIGNMENT_CENTER, b.radius * 2.0, fs, CYAN)
		if name == "interact" and hold_label != "":
			_draw_hold(b.center, b.radius, font)


## Something to glitch in reach: the E button grows a pink "HOLD" ring that
## fills as you charge.
func _draw_hold(c: Vector2, r: float, font: Font) -> void:
	var pink := Color("ff4fa3")
	var ring := r + 6.0
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
	if hold_progress < 0.0:
		# Dashed: "press and hold".
		for i in 12:
			var a := TAU * i / 12.0
			_draw_node.draw_arc(c, ring, a, a + TAU / 24.0, 4, Color(pink, 0.45 + 0.4 * pulse), 2.0)
	else:
		_draw_node.draw_arc(c, ring, 0.0, TAU, 32, Color(pink, 0.25), 2.0)
		_draw_node.draw_arc(c, ring, -PI * 0.5, -PI * 0.5 + TAU * hold_progress, 32, pink.lerp(CYAN, hold_progress), 3.0)
	var text := "HOLD · " + hold_label
	_draw_node.draw_string_outline(font, c + Vector2(-90, -ring - 6), text, HORIZONTAL_ALIGNMENT_CENTER, 180, 9, 3, Color(0, 0, 0, 0.8))
	_draw_node.draw_string(font, c + Vector2(-90, -ring - 6), text, HORIZONTAL_ALIGNMENT_CENTER, 180, 9, pink)

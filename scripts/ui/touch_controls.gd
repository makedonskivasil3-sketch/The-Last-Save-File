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
##
## Ownership (docs/INPUT_POLICY.md):
##   - a button is held while ANY finger that landed on it stays down; the
##     action is pressed when the first finger lands and released when the
##     last one lifts (two thumbs on E never drop it halfway);
##   - a finger may roll a little off E and keep it; slid further than
##     SLIDE_CANCEL from the centre, the press is cancelled: E lets go and
##     nothing happens (a cancelled press never acts on its release);
##   - an OS cancellation, focus loss or rotation cancels the same way;
##   - zones (the festival's skip chip) are owned by the finger that landed
##     in them, are checked before E and the stick, and keep working while a
##     story panel has the buttons switched off.

const STICK_RADIUS := 34.0
const DEAD_ZONE := 0.18
## The joystick only starts in this part of the screen.
const STICK_ZONE := Rect2(0, 60, 300, 300)
const BUTTONS := {
	# Only "interact": every reader of E accepts it (confirm is Enter's own
	# action). Sending both broke holding: in Godot 4.3 the second parsed
	# action event ("confirm") releases the first, so "interact" was never
	# held and a glitch could not be charged by touch (docs/INPUT_POLICY.md).
	"interact": {"center": Vector2(588, 292), "radius": 30.0, "label": "E", "actions": ["interact"]},
	"pause": {"center": Vector2(612, 90), "radius": 15.0, "label": "II", "actions": ["pause"]},
}
const CYAN := Color("8cf2ff")
## A finger on a button that slides further than this from its centre
## cancels the press (a thumb rolling a little stays on it).
const SLIDE_CANCEL := 56.0
## How long a tap's flash shows on the button (a tap can go down and up
## inside one frame, too short to see as "held").
const FLASH_TIME := 0.14

var active := false
## Set by the glitch controller: what holding E would do ("" for nothing),
## and how far the hold has charged (0..1, or < 0 when not charging).
var hold_label := ""
var hold_progress := -1.0
## The title screen only wants the "turn sideways" notice: menus take taps.
var buttons_enabled := true
## What E does right now ("TALK", "NEXT", "USE"...; "" shows a plain E).
## The world sets it every frame.
var context_label := ""
## Extra touch zones a scene owns (name -> Rect2 in game space): the
## festival's skip chip. Checked before the buttons and the stick.
var zones: Dictionary = {}

var _stick_finger := -1
var _stick_centre := Vector2.ZERO
var _stick_knob := Vector2.ZERO
## The stick's current direction. Re-applied every frame: in Godot 4.3, any
## parsed action event (the E button) releases actions set with action_press,
## which would stop Rue dead whenever you pressed E while running.
var _stick := Vector2.ZERO
## Finger index -> button name.
var _held: Dictionary = {}
## Finger index -> zone name.
var _zone_fingers: Dictionary = {}
## Button name -> seconds of tap flash left.
var _flash: Dictionary = {}
## A short notice over E ("nothing in reach", "cancelled") and its time left.
var _notice := ""
var _notice_t := 0.0
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


static func is_portrait(win: Vector2) -> bool:
	return win.y > win.x
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel_touches("focus lost")


func _input(event: InputEvent) -> void:
	# A key or a pad press: the player switched device (UI-2, UX C12). The
	# controls hide until the screen is touched again.
	if active and (event is InputEventKey or event is InputEventJoypadButton) and event.is_pressed() and _held.is_empty() and _stick_finger == -1:
		active = false
		return
	if event is InputEventScreenTouch:
		active = true
		var at := _game_pos(event.position)
		if event.canceled:
			InputTrace.add("cancel", "touch#%d" % event.index, "", "OS cancelled the touch")
			_touch_cancel(event.index)
		elif event.pressed:
			if _zone_down(event.index, at):
				get_viewport().set_input_as_handled()
				return
			if not buttons_enabled:
				InputTrace.add("touch-down", "touch#%d" % event.index, "", "buttons off (story panel or menu) at %s" % at.round())
				return
			_touch_down(event.index, at)
		else:
			_touch_up(event.index)
	elif event is InputEventScreenDrag:
		var at := _game_pos(event.position)
		if event.index == _stick_finger:
			_move_stick(at)
		elif _held.has(event.index):
			var b: Dictionary = BUTTONS[_held[event.index]]
			if at.distance_to(b.center) > SLIDE_CANCEL:
				InputTrace.add("drag-off", "touch#%d" % event.index, _held[event.index], "slid off: cancelled")
				if _held[event.index] == "interact":
					PressGate.cancel("slid off E")
					notice("cancelled")
				_release_finger(event.index)
		elif _zone_fingers.has(event.index):
			var r: Rect2 = zones.get(_zone_fingers[event.index], Rect2())
			if not r.grow(12.0).has_point(at):
				InputTrace.add("drag-off", "touch#%d" % event.index, _zone_fingers[event.index], "slid off the zone")
				_zone_fingers.erase(event.index)


## Events reach _input already in the viewport's 640x360 space (Godot
## applies the stretch transform first), the space the controls live in.
func _game_pos(viewport_pos: Vector2) -> Vector2:
	return viewport_pos


func _zone_down(finger: int, pos: Vector2) -> bool:
	if get_window().size.y > get_window().size.x:
		return false
	for name: String in zones:
		if (zones[name] as Rect2).grow(4.0).has_point(pos):
			_zone_fingers[finger] = name
			InputTrace.add("touch-down", "touch#%d" % finger, name, "zone", true)
			return true
	return false


## Is a finger holding this zone?
func zone_held(name: String) -> bool:
	return name in _zone_fingers.values()


func _touch_down(finger: int, pos: Vector2) -> void:
	if get_window().size.y > get_window().size.x:
		InputTrace.add("touch-down", "touch#%d" % finger, "", "portrait notice", false)
		return
	for name: String in BUTTONS:
		var b: Dictionary = BUTTONS[name]
		if pos.distance_to(b.center) <= b.radius + 6.0:
			if get_tree().paused and name != "pause":
				InputTrace.add("touch-down", "touch#%d" % finger, name, "paused: the menu takes taps", false)
				return  # menus take taps themselves
			var first: bool = not (name in _held.values())
			_held[finger] = name
			_flash[name] = FLASH_TIME
			InputTrace.add("touch-down", "touch#%d" % finger, name, ("press" if first else "second finger: already held"), true)
			if first:
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
		InputTrace.add("touch-down", "touch#%d" % finger, "stick", "", true)
		return
	InputTrace.add("touch-down", "touch#%d" % finger, "", "missed: no control at %s" % pos.round(), false)


func _touch_up(finger: int) -> void:
	if _held.has(finger):
		InputTrace.add("touch-up", "touch#%d" % finger, _held[finger])
	_release_finger(finger)
	_zone_fingers.erase(finger)
	if finger == _stick_finger:
		_stick_finger = -1
		_stick = Vector2.ZERO
		_set_move(Vector2.ZERO)


## An OS-cancelled touch: whatever it held lets go without acting.
func _touch_cancel(finger: int) -> void:
	if _held.get(finger, "") == "interact":
		PressGate.cancel("OS cancelled the touch")
	_touch_up(finger)


## This finger stops owning its button; the action is released only when
## no other finger still owns it.
func _release_finger(finger: int) -> void:
	if not _held.has(finger):
		return
	var name: String = _held[finger]
	_held.erase(finger)
	if name in _held.values():
		return  # another finger still holds it
	for action in BUTTONS[name].actions:
		_send(action, false)


## A short word over E: why a tap did nothing ("nothing in reach") or that
## a press was cancelled.
func notice(text: String, seconds := 1.2) -> void:
	_notice = text
	_notice_t = seconds


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
## A release also clears the action at once (Input.action_release): a
## cancelled or lifted E must not read as held for one more frame while
## the event waits in Input's buffer.
func _send(action: String, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)
	if not pressed:
		Input.action_release(action)


func _process(delta: float) -> void:
	for k in _flash.keys():
		_flash[k] -= delta
		if _flash[k] <= 0.0:
			_flash.erase(k)
	_notice_t = maxf(0.0, _notice_t - delta)
	var portrait := portrait_active()
	# The rotation instruction must remain readable above the pause/story
	# panels. Normal virtual controls stay beneath those modal panels.
	layer = 30 if portrait else 18
	if portrait != _portrait:
		_portrait = portrait
		orientation_changed.emit(portrait)
	# Rotation must not leave an invisible joystick driving behind the notice.
	if active and get_window().size.y > get_window().size.x \
			and (_stick_finger != -1 or not _held.is_empty() or not _zone_fingers.is_empty()):
		cancel_touches("rotated to portrait")
	if _stick_finger != -1:
		_set_move(_stick)
	_draw_node.visible = active
	if active:
		_draw_node.queue_redraw()


func _exit_tree() -> void:
	cancel_touches("scene left")


## A story panel takes over without leaving a virtual stick or E held. The
## press is cancelled, not let go: nothing acts on it afterwards.
func cancel_touches(reason := "cancelled", keep_zones := false) -> void:
	if "interact" in _held.values():
		PressGate.cancel(reason)
	if not _held.is_empty() or not _zone_fingers.is_empty() or _stick_finger != -1:
		InputTrace.add("cancel", "all", "", reason)
	for finger in _held.keys():
		_release_finger(finger)
	_held.clear()
	if not keep_zones:
		_zone_fingers.clear()
	_stick_finger = -1
	_stick = Vector2.ZERO
	_set_move(Vector2.ZERO)


func _on_draw() -> void:
	var font := ThemeDB.fallback_font
	var win := Vector2(get_window().size)
	if is_portrait(win):
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
		var held: bool = name in _held.values() or _flash.has(name)
		_draw_node.draw_circle(b.center, b.radius, Color(CYAN, 0.45) if held else Color(0, 0, 0, 0.45))
		_draw_node.draw_arc(b.center, b.radius, 0.0, TAU, 32, Color(CYAN, 0.7), 1.5)
		var fs := 18 if b.radius > 20.0 else 10
		if name == "interact" and context_label != "":
			# What E does here, with a small E above it so the key is still taught.
			_draw_node.draw_string(font, b.center + Vector2(-b.radius, -9), "E", HORIZONTAL_ALIGNMENT_CENTER, b.radius * 2.0, 8, Color(CYAN, 0.7))
			_draw_node.draw_string(font, b.center + Vector2(-b.radius, 6), context_label, HORIZONTAL_ALIGNMENT_CENTER, b.radius * 2.0, 10, CYAN)
		else:
			_draw_node.draw_string(font, b.center + Vector2(-b.radius, fs * 0.35), b.label, HORIZONTAL_ALIGNMENT_CENTER, b.radius * 2.0, fs, CYAN)
		if name == "interact" and hold_label != "":
			_draw_hold(b.center, b.radius, font)
		if name == "interact" and _notice_t > 0.0 and hold_label == "":
			var nc: Vector2 = b.center + Vector2(-90, -b.radius - 10)
			_draw_node.draw_string_outline(font, nc, _notice, HORIZONTAL_ALIGNMENT_CENTER, 180, 9, 3, Color(0, 0, 0, 0.8))
			_draw_node.draw_string(font, nc, _notice, HORIZONTAL_ALIGNMENT_CENTER, 180, 9, Color(1, 1, 1, minf(1.0, _notice_t * 2.0)))


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

class_name HowToPlayPanel
extends VBoxContainer
## The title screen's HOW TO PLAY: the rules on one scrolling page, with the
## controls for whatever you're holding (keyboard, gamepad or touch).

signal closed

const KEY_COL := Color("8cf2ff")

const SECTIONS := [
	["YOU", "You're a character in someone else's save file. The owner wants you gone. Get out of Arin's room, find where Slot 2 went, and write yourself into it."],
	["THE OWNER", "The bar at the top is how aware of you the owner is. It fills when Arin sees you, when you touch things you shouldn't, and every time you glitch. As it climbs, the owner locks doors, reloads saves, sends the cursor and the eraser."],
	["HIDING", "Stay out of Arin's light cone. Some people will hide you if you stand right beside them, and closets work too. The owner slowly loses track, but never forgets what they've already done."],
	["GLITCHES", "Hold interact on whatever's in the pink brackets to corrupt it: open a locked door, walk through a thin wall, freeze someone. Each glitch costs awareness. Memories you recover unlock more."],
	["DYING", "If the owner catches you, the run ends. Next run, the world remembers: who helped you, how you died, what you found. Quitting counts too: in a browser, closing the tab mid-run is quitting (it asks first)."],
	["PEOPLE", "Talk to everyone more than once. Some of them want something. Some of them want to come with you."],
	["JOURNAL", "Every note, book, file and memory you read is kept, word for word, in the Journal (pause menu or title screen). The owner can't edit it."],
]


var _back: Button
var _scroll: ScrollContainer


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	UiStyle.heading(self, "HOW TO PLAY", UiStyle.TEXT, 16)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 230)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_scroll = scroll
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 3)
	scroll.add_child(body)
	_section(body, "CONTROLS", "")
	for row in controls():
		_entry(body, row[0], row[1])
	for s in SECTIONS:
		_section(body, s[0], s[1])
	_back = UiStyle.button(self, "Back", func() -> void: closed.emit(), "ui_back")


## [what, how] rows for the device you're using.
static func controls() -> Array:
	if Settings.using_touch or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return [["Move", "drag on the left side"], ["Interact", "tap E"], ["Glitch", "hold E"], ["Pause", "tap II"]]
	if Settings.using_gamepad:
		return [["Move", "left stick / d-pad"], ["Interact", "A"], ["Glitch", "hold A"], ["Pause / map", "Start"], ["Back", "B"]]
	return [["Move", "WASD / arrow keys"], ["Interact", "E / Space"], ["Glitch", "hold E / Space"], ["Pause / map", "Esc"]]


func _section(parent: Control, title: String, text: String) -> void:
	var gap := Control.new()
	gap.custom_minimum_size.y = 4
	parent.add_child(gap)
	UiStyle.heading(parent, title, UiStyle.OWNER, 12)
	if text != "":
		UiStyle.note(parent, text, UiStyle.TEXT).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _entry(parent: Control, what: String, how: String) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var a := UiStyle.note(row, what, UiStyle.MUTED)
	a.custom_minimum_size.x = 110
	a.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var b := UiStyle.note(row, how, KEY_COL)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


## Up/down (stick, d-pad or keys) scrolls the page: Back is the only button.
func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var dir := Input.get_axis("move_up", "move_down")
	if absf(dir) > 0.2:
		_scroll.scroll_vertical += int(dir * 260.0 * delta)


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		closed.emit()


func focus_first() -> void:
	_back.grab_focus()

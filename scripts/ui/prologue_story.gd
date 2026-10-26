class_name PrologueStory
extends PanelContainer
## Player-paced, written-only story beats. The owner ticks this reader so
## focus/controller holds stop its reading allowance too. No TTS or acting
## is implied by a speaker label. A page is remembered only on acknowledgement.

signal page_read(id: String, speaker: String, text: String)

var story_id := ""
var page := 0
var _pages: Array = []
var _age := 0.0
var _armed := false
var _speaker: Label
var _body: Label
var _next: Button


func _ready() -> void:
	position = Vector2(32, 176)
	custom_minimum_size.x = 576
	size = Vector2(576, 0)
	resized.connect(_place)
	theme = UiStyle.make_theme()
	var box := StyleBoxFlat.new()
	box.bg_color = Color("11131d")
	box.border_color = Color("8babb8")
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	add_theme_stylebox_override("panel", box)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	_speaker = Label.new()
	_speaker.custom_minimum_size.x = 544
	_speaker.size.x = 544
	_speaker.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.sized(_speaker, 10)
	_speaker.add_theme_color_override("font_color", UiStyle.INTRUDER)
	column.add_child(_speaker)
	_body = Label.new()
	_body.custom_minimum_size.x = 544
	_body.size.x = 544
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.sized(_body, 12)
	column.add_child(_body)
	_next = UiStyle.button(column, "Continue", advance)
	_next.custom_minimum_size.y = 26
	_next.focus_mode = Control.FOCUS_NONE  # one input path for keys/pad; GUI for taps
	visible = false


func _place() -> void:
	position = Vector2(32, maxf(12.0, 348.0 - size.y))


func open(id: String, pages: Array) -> void:
	story_id = id
	_pages = pages.duplicate(true)
	page = 0
	visible = not _pages.is_empty()
	if visible:
		_show_page()


func _show_page() -> void:
	_speaker.text = "%s  ·  %d / %d" % [_pages[page][0], page + 1, _pages.size()]
	_body.text = _pages[page][1]
	_age = 0.0
	_armed = false
	_next.disabled = true
	_next.text = "Continue" if page < _pages.size() - 1 else "Return to the scene"
	size = Vector2(576, 0)  # reflow at large text; no fixed-height clipping


func tick(delta: float, auto := false) -> void:
	if not visible:
		return
	_age += delta
	if not Input.is_action_pressed("interact") and not Input.is_action_pressed("confirm") \
			and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_armed = true
	_next.disabled = not _armed or _age < 0.25
	if (auto or StoryPacing.is_auto()) and _age >= StoryPacing.reading_time(_body.text):
		_acknowledge()
	elif not _next.disabled and (Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("confirm")):
		advance()


func advance() -> void:
	if visible and _armed and _age >= 0.25:
		_acknowledge()


func _acknowledge() -> void:
	page_read.emit(story_id, str(_pages[page][0]), str(_pages[page][1]))
	page += 1
	if page >= _pages.size():
		visible = false
	else:
		_show_page()


func cancel() -> void:
	visible = false  # skipping is not reading


func rearm() -> void:
	_armed = false
	_next.disabled = true

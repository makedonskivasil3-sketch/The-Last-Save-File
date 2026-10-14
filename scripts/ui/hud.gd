class_name Hud
extends CanvasLayer
## The save file's own UI, plus a console the owner types into.

const OWNER_COLOR := Color("e0704f")
const SYSTEM_COLOR := Color("8a8f98")
const NPC_COLOR := Color("e8c48a")
const SLOT_COLOR := Color("c8b8a0")
const MAX_LINES := 4
const TYPE_SPEED := 36.0  # characters per second
const LINE_PAUSE := 0.5

## The owner's character. Not you.
var character_name := "ARIN"
var unknown_processes := 0

var _slot: Label
var _awareness_label: Label
var _awareness_fill: ColorRect
var _awareness := 0.0
var _console: VBoxContainer
var _prompt: Label
var _overlay: ColorRect
var _overlay_title: Label
var _overlay_body: Label
var _hint: Label

var _queue: Array[Dictionary] = []
var _typing: Label
var _typed := 0.0
var _pause := 0.0
var _playtime := 14.0 * 3600.0 + 22.0 * 60.0  # the owner has played a lot


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_slot = _make_label(root, Vector2(8, 6), Vector2(400, 14), 10, SLOT_COLOR)

	_awareness_label = _make_label(root, Vector2(472, 4), Vector2(160, 12), 8, SYSTEM_COLOR)
	_awareness_label.text = "OWNER AWARENESS"
	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(472, 17)
	bar_bg.size = Vector2(160, 4)
	bar_bg.color = Color(1, 1, 1, 0.08)
	root.add_child(bar_bg)
	_awareness_fill = ColorRect.new()
	_awareness_fill.position = bar_bg.position
	_awareness_fill.size = Vector2(0, 4)
	_awareness_fill.color = OWNER_COLOR
	root.add_child(_awareness_fill)

	_console = VBoxContainer.new()
	_console.position = Vector2(10, 302)
	_console.size = Vector2(450, 56)
	_console.add_theme_constant_override("separation", 0)
	root.add_child(_console)

	_prompt = _make_label(root, Vector2(470, 302), Vector2(160, 14), 9, SYSTEM_COLOR)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_hint = _make_label(root, Vector2(470, 344), Vector2(160, 12), 8, Color(SYSTEM_COLOR, 0.6))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0.82)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	root.add_child(_overlay)
	_overlay_title = _make_label(_overlay, Vector2(0, 120), Vector2(640, 40), 28, OWNER_COLOR)
	_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_body = _make_label(_overlay, Vector2(40, 170), Vector2(560, 140), 11, SLOT_COLOR)
	_overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


## kind: "owner", "system" or "npc". speaker is shown for npc lines.
func say(text: String, kind: String = "owner", speaker: String = "") -> void:
	_queue.append({"text": text, "kind": kind, "speaker": speaker})


func clear_queue() -> void:
	_queue.clear()


func set_awareness(value: float) -> void:
	_awareness = clampf(value, 0.0, 1.0)


func set_prompt(text: String) -> void:
	_prompt.text = "[%s] %s" % [Settings.glyph("interact"), text] if text != "" else ""


func set_hint(text: String) -> void:
	_hint.text = text


func show_overlay(title: String, body: String, title_color: Color = OWNER_COLOR) -> void:
	_overlay.visible = true
	_overlay_title.text = title
	_overlay_title.add_theme_color_override("font_color", title_color)
	_overlay_body.text = body


func hide_overlay() -> void:
	_overlay.visible = false


func _process(delta: float) -> void:
	_playtime += delta
	_update_slot()
	_awareness_fill.size.x = lerpf(_awareness_fill.size.x, 160.0 * _awareness, 1.0 - exp(-6.0 * delta))
	var blink := _awareness >= 0.75 and fmod(_playtime, 0.5) >= 0.25 and not Settings.reduce_flashing
	_awareness_fill.color = Color.WHITE if blink else OWNER_COLOR
	_update_typing(delta)


func _update_slot() -> void:
	var secs := int(_playtime)
	var name_shown := character_name
	# The name glitches more as the owner gets agitated.
	if randf() < _awareness * 0.04:
		var i := randi() % name_shown.length()
		name_shown = name_shown.substr(0, i) + ["#", "?", "_", "0"].pick_random() + name_shown.substr(i + 1)
	var text := "SLOT 1  ·  %s  ·  LV 7  ·  %02d:%02d:%02d" % [name_shown, floori(secs / 3600.0), floori(secs / 60.0) % 60, secs % 60]
	if unknown_processes > 0:
		text += "  ·  [!] %d UNKNOWN PROCESS" % unknown_processes
	_slot.text = text


func _update_typing(delta: float) -> void:
	if _typing:
		_typed += TYPE_SPEED * delta
		_typing.visible_characters = int(_typed)
		if _typed >= _typing.get_total_character_count():
			_typing.visible_characters = -1
			_typing = null
			_pause = LINE_PAUSE
		return
	if _pause > 0.0:
		_pause -= delta
		return
	if _queue.is_empty():
		return
	var msg: Dictionary = _queue.pop_front()
	var line := Label.new()
	line.add_theme_font_size_override("font_size", 10)
	match msg.kind:
		"owner":
			line.text = "> " + msg.text
			line.add_theme_color_override("font_color", OWNER_COLOR)
		"npc":
			line.text = "%s: %s" % [msg.speaker, msg.text]
			line.add_theme_color_override("font_color", NPC_COLOR)
		_:
			line.text = msg.text
			line.add_theme_color_override("font_color", SYSTEM_COLOR)
	line.visible_characters = 0
	_console.add_child(line)
	while _console.get_child_count() > MAX_LINES:
		var old := _console.get_child(0)
		_console.remove_child(old)
		old.queue_free()
	for i in _console.get_child_count():
		var l := _console.get_child(i) as Label
		l.modulate.a = 0.35 + 0.65 * float(i + 1) / _console.get_child_count()
	_typing = line
	_typed = 0.0


func _make_label(parent: Control, pos: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

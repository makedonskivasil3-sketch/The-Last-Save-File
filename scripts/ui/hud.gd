class_name Hud
extends CanvasLayer
## The save file's own UI, plus a console the owner types into, a dialogue
## box for characters, area title cards and screen fades.

signal dialogue_closed

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
var _meter: AwarenessMeter
## Owner lines in the console, kept so they can corrupt themselves later.
var _owner_lines: Array[Label] = []
var _corrupt_timer := 0.0
var _corrupted: Label
var _corrupted_text := ""
var _death_style := ""
var _death_title := ""
var _death_ghosts: Array[Label] = []
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

var _dialogue: Panel
var _dialogue_speaker: Label
var _dialogue_text: Label
var _dialogue_hint: Label
var _dialogue_lines: Array = []
var _dialogue_index := 0
var _dialogue_typed := 0.0
var _dialogue_opened_frame := -1
var _area_title: Label
var _area_tween: Tween
var _fade: ColorRect


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_slot = _make_label(root, Vector2(8, 6), Vector2(400, 14), 10, SLOT_COLOR)

	_meter = AwarenessMeter.new()
	_meter.position = Vector2(472, 3)
	_meter.size = Vector2(160, 22)
	_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_meter)

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
	# Two colour-split ghosts behind the title, used by the death screens.
	for c in [Color(1.0, 0.1, 0.35, 0.6), Color(0.3, 0.9, 1.0, 0.6)]:
		var ghost := _make_label(_overlay, Vector2(0, 120), Vector2(640, 40), 28, c)
		ghost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ghost.visible = false
		_death_ghosts.append(ghost)
	_overlay_title = _make_label(_overlay, Vector2(0, 120), Vector2(640, 40), 28, OWNER_COLOR)
	_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_body = _make_label(_overlay, Vector2(40, 170), Vector2(560, 140), 11, SLOT_COLOR)
	_overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_area_title = _make_label(root, Vector2(0, 150), Vector2(640, 24), 16, SLOT_COLOR)
	_area_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_area_title.add_theme_constant_override("outline_size", 4)
	_area_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_area_title.modulate.a = 0.0

	_dialogue = Panel.new()
	_dialogue.position = Vector2(6, 298)
	_dialogue.size = Vector2(628, 58)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.02, 0.016, 0.024, 0.95)
	box.set_border_width_all(1)
	box.border_color = Color(1, 1, 1, 0.15)
	_dialogue.add_theme_stylebox_override("panel", box)
	_dialogue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue.visible = false
	root.add_child(_dialogue)
	_dialogue_speaker = _make_label(_dialogue, Vector2(8, 3), Vector2(400, 12), 9, NPC_COLOR)
	_dialogue_text = _make_label(_dialogue, Vector2(8, 16), Vector2(560, 40), 10, SLOT_COLOR)
	_dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_hint = _make_label(_dialogue, Vector2(500, 42), Vector2(122, 12), 8, SYSTEM_COLOR)
	_dialogue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_fade)


## Opens the dialogue box. lines: Array of Strings, advanced with interact.
func show_dialogue(speaker: String, color: Color, lines: Array) -> void:
	if lines.is_empty():
		return
	_dialogue_lines = lines
	_dialogue_index = 0
	_dialogue_typed = 0.0
	_dialogue_opened_frame = Engine.get_process_frames()
	_dialogue_speaker.text = speaker
	_dialogue_speaker.add_theme_color_override("font_color", color)
	_dialogue.visible = true
	_console.visible = false
	_prompt.visible = false
	_show_dialogue_line()


func close_dialogue() -> void:
	if not _dialogue.visible:
		return
	_dialogue.visible = false
	_console.visible = true
	_prompt.visible = true
	dialogue_closed.emit()


func is_dialogue_open() -> bool:
	return _dialogue.visible


func show_area_title(text: String) -> void:
	_area_title.text = text
	if _area_tween:
		_area_tween.kill()
	var tw := create_tween()
	_area_tween = tw
	tw.tween_property(_area_title, "modulate:a", 1.0, 0.4)
	tw.tween_interval(1.6)
	tw.tween_property(_area_title, "modulate:a", 0.0, 0.8)


## Fades the screen to black (or back). Await the returned tween's `finished`.
func fade(to_black: bool, duration: float = 0.25) -> Tween:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0 if to_black else 0.0, duration)
	return tw


func _show_dialogue_line() -> void:
	_dialogue_text.text = str(_dialogue_lines[_dialogue_index])
	_dialogue_text.visible_characters = 0
	_dialogue_typed = 0.0
	var last := _dialogue_index == _dialogue_lines.size() - 1
	_dialogue_hint.text = "[%s] %s" % [Settings.glyph("interact"), "close" if last else "next"]


func _update_dialogue(delta: float) -> void:
	if not _dialogue.visible:
		return
	var total := _dialogue_text.get_total_character_count()
	if _dialogue_text.visible_characters >= 0 and _dialogue_text.visible_characters < total:
		_dialogue_typed += 55.0 * delta
		_dialogue_text.visible_characters = mini(int(_dialogue_typed), total)
	if Engine.get_process_frames() == _dialogue_opened_frame:
		return  # the press that opened the box doesn't also advance it
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("confirm"):
		if _dialogue_text.visible_characters >= 0 and _dialogue_text.visible_characters < total:
			_dialogue_text.visible_characters = -1  # finish the line first
		elif _dialogue_index < _dialogue_lines.size() - 1:
			_dialogue_index += 1
			_show_dialogue_line()
		else:
			close_dialogue()


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


## A threshold was crossed: the awareness meter flinches.
func awareness_jolt() -> void:
	_meter.jolt()


## Death screen, styled per cause ("erased", "overwritten", "selected"):
## the title shakes with colour-split ghosts and keeps corrupting itself.
func show_death(title: String, body: String, cause: String) -> void:
	_death_style = cause
	_death_title = title
	var colors := {"erased": OWNER_COLOR, "overwritten": Color("8fb4e8"), "selected": Color.WHITE}
	show_overlay(title, body, colors.get(cause, OWNER_COLOR))
	_overlay.color = {"erased": Color(0, 0, 0, 0.88), "overwritten": Color(0.04, 0.07, 0.14, 0.85), "selected": Color(0.02, 0.03, 0.06, 0.8)}.get(cause, Color(0, 0, 0, 0.82))
	for g in _death_ghosts:
		g.visible = Settings.glitch_intensity > 0.0
		g.text = title


func show_overlay(title: String, body: String, title_color: Color = OWNER_COLOR) -> void:
	if _area_tween:
		_area_tween.kill()
	_area_title.modulate.a = 0.0
	_overlay.visible = true
	_overlay_title.text = title
	_overlay_title.add_theme_color_override("font_color", title_color)
	_overlay_body.text = body


func hide_overlay() -> void:
	_overlay.visible = false


func _process(delta: float) -> void:
	_playtime += delta
	_update_slot()
	_meter.value = _awareness
	_update_typing(delta)
	_update_corruption(delta)
	_update_death_title()
	_update_dialogue(delta)


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
		var full: String = _typing.get_meta("full", _typing.text)
		var n := mini(int(_typed), full.length())
		if _typing.has_meta("owner") and n < full.length() and Settings.glitch_intensity > 0.0:
			# The owner's text arrives wrong first: garbage ahead of the cursor
			# that resolves into the real letters as they're typed.
			_typing.text = full.substr(0, n) + _garbage(mini(2, full.length() - n))
			_typing.visible_characters = -1
		else:
			_typing.text = full
			_typing.visible_characters = n
		if _typed >= full.length():
			_typing.text = full
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
			# A colour-split shadow so the owner's words never sit quite still.
			line.add_theme_color_override("font_shadow_color", Color(0.3, 0.9, 1.0, 0.35 * Settings.glitch_intensity))
			line.add_theme_constant_override("shadow_offset_x", -1)
			line.add_theme_constant_override("shadow_offset_y", 0)
			line.set_meta("owner", true)
			_owner_lines.append(line)
		"npc":
			line.text = "%s: %s" % [msg.speaker, msg.text]
			line.add_theme_color_override("font_color", NPC_COLOR)
		_:
			line.text = msg.text
			line.add_theme_color_override("font_color", SYSTEM_COLOR)
	line.set_meta("full", line.text)
	line.visible_characters = 0
	_console.add_child(line)
	while _console.get_child_count() > MAX_LINES:
		var old := _console.get_child(0) as Label
		_console.remove_child(old)
		_owner_lines.erase(old)
		if old == _corrupted:
			_corrupted = null
		old.queue_free()
	for i in _console.get_child_count():
		var l := _console.get_child(i) as Label
		l.modulate.a = 0.35 + 0.65 * float(i + 1) / _console.get_child_count()
	_typing = line
	_typed = 0.0


## Every so often a finished owner line corrupts for a moment, more often the
## more aware the owner is. Scales with Settings.glitch_intensity.
func _update_corruption(delta: float) -> void:
	if _corrupted:
		_corrupt_timer -= delta
		if _corrupt_timer <= 0.0:
			_corrupted.text = _corrupted_text
			_corrupted.position.x = 0.0
			_corrupted = null
		return
	var rate := (0.2 + _awareness * 2.0) * Settings.glitch_intensity
	if _owner_lines.is_empty() or randf() > rate * delta:
		return
	var line: Label = _owner_lines.pick_random()
	if line == _typing or not is_instance_valid(line):
		return
	_corrupted = line
	_corrupted_text = line.text
	var chars := line.text.length()
	var text := line.text
	for i in 1 + int(_awareness * 4.0):
		var at := randi() % chars
		text = text.substr(0, at) + _garbage(1) + text.substr(at + 1)
	line.text = text
	line.position.x = randf_range(-2.0, 2.0) * Settings.glitch_intensity
	_corrupt_timer = randf_range(0.06, 0.18)


func _update_death_title() -> void:
	if _death_style == "" or not _overlay.visible:
		return
	var glitch := Settings.glitch_intensity
	var text := _death_title
	if randf() < 0.25 * glitch:
		var at := randi() % text.length()
		text = text.substr(0, at) + _garbage(1) + text.substr(at + 1)
	_overlay_title.text = text
	var base := Vector2(0, 120)
	match _death_style:
		"overwritten":
			# Dragged sideways, like the row is being written over.
			_overlay_title.position = base + Vector2(randf_range(-1, 6) * glitch, 0)
		"selected":
			# Snaps between positions, like a selection being dragged.
			if randf() < 0.1:
				_overlay_title.position = base + Vector2(randf_range(-4, 4), randf_range(-2, 2)) * glitch
		_:
			_overlay_title.position = base + Vector2(randf_range(-2, 2), randf_range(-1, 1)) * glitch
	for i in _death_ghosts.size():
		var g := _death_ghosts[i]
		g.text = text
		var dir := -1.0 if i == 0 else 1.0
		g.position = _overlay_title.position + Vector2(dir * randf_range(1.0, 4.0) * glitch, 0)


func _garbage(count: int) -> String:
	var pool := "#%&@!?/\\|_=+*<>01"
	var out := ""
	for i in count:
		out += pool[randi() % pool.length()]
	return out


func _make_label(parent: Control, pos: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

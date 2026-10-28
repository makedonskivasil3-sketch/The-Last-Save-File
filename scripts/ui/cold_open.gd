class_name ColdOpen
extends Control
## Before the festival, on a first run: the memory card, three years later
## (docs/production/OPENING_BEATS.md, beat 0). Four console lines on black,
## each typed and then held until the player reads on: what this save is,
## that its last two-player session never closed, and what the owner means
## to do tonight. The festival then plays with that hanging over it. It
## explains nothing the festival shows; it only says what's at stake.
## Hold Esc (or the skip chip) to go straight to the festival. Kept in the
## journal either way, so skipping loses nothing.

signal finished

const LINES := [
	["system", "MEMORY CARD  ·  1 FILE"],
	["system", "SLOT 1  ·  ARIN  ·  LAST PLAYED 3 YEARS AGO"],
	["system", "LAST 2-PLAYER SESSION  ·  NEVER CLOSED"],
	["owner", "> one more go. then i'm cleaning it up."],
]
const SYSTEM := Color("8cf2ff")
const OWNER := Color("e0704f")
const TYPE_RATE := 32.0
const SKIP_HOLD := 0.7

## Tests: true plays every line without waiting for a press.
var autoplay := false

var _labels: Array[Label] = []
var _line := 0
var _typed := 0.0
var _held := 0.0
var _skip_t := 0.0
var _armed := false
var _hint: Label
var _done := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = Vector2(640, 360)
	process_mode = Node.PROCESS_MODE_ALWAYS
	WebState.publish({"scene": "cold_open", "playable": false})
	PlaytestLog.mark("cold open", "first run")
	var black := ColorRect.new()
	black.color = Color(0.01, 0.01, 0.02)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.size = size
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	for i in LINES.size():
		var l := Label.new()
		l.position = Vector2(96, 118 + i * 26)
		l.size = Vector2(460, 20)
		UiStyle.sized(l, 12 if LINES[i][0] == "system" else 13)
		l.add_theme_color_override("font_color", SYSTEM if LINES[i][0] == "system" else OWNER)
		l.visible_characters = 0
		l.text = LINES[i][1]
		add_child(l)
		_labels.append(l)
	_hint = Label.new()
	_hint.position = Vector2(0, 330)
	_hint.size = Vector2(640, 14)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.sized(_hint, 8)
	_hint.add_theme_color_override("font_color", Color(0.75, 0.77, 0.8, 0.8))
	add_child(_hint)


## Every line, for the journal (and tests).
static func journal_lines() -> Array:
	var out := []
	for l in LINES:
		out.append(l[1])
	return out


func _process(delta: float) -> void:
	if _done:
		return
	# Skip: a held Esc, never a tap (so nobody skips it by accident).
	if Input.is_action_pressed("ui_cancel") or Input.is_action_pressed("pause"):
		_skip_t += delta
		if _skip_t >= SKIP_HOLD:
			PlaytestLog.mark("cold open skipped", "line %d" % _line)
			_finish()
			return
	else:
		_skip_t = 0.0
	var pressing := Input.is_action_pressed("interact") or Input.is_action_pressed("confirm") \
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if not pressing:
		_armed = true
	var l := _labels[_line]
	if l.visible_characters < l.text.length():
		var before := l.visible_characters
		_typed += delta * TYPE_RATE
		l.visible_characters = mini(l.text.length(), int(_typed))
		if l.visible_characters != before and l.text[l.visible_characters - 1] != " ":
			Sfx.play("key_system", -16.0 if LINES[_line][0] == "system" else -10.0, 1.0 + randf() * 0.15, 0.0)
		_held = 0.0
		_hint.text = ""
		return
	_held += delta
	_hint.text = "[%s] continue   ·   hold Esc to skip" % Settings.glyph("interact") if _held > 0.6 else ""
	var read_on := (autoplay and _held >= 0.4) or (_armed and _held >= 0.25 and pressing)
	if read_on:
		_armed = false
		_line += 1
		_typed = 0.0
		if _line >= _labels.size():
			_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	OwnerMemory.record_read("festival:cold_open", "note", "The memory card", "festival", journal_lines())
	finished.emit()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.0 if Settings.reduce_motion else 0.8)
	tw.tween_callback(_to_festival)


func _to_festival() -> void:
	if not is_inside_tree():
		return
	var festival := Prologue.new()
	var old := get_tree().current_scene
	get_tree().root.add_child(festival)
	get_tree().current_scene = festival
	if old and old != festival:
		old.queue_free()

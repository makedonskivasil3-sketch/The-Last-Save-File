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
##
## Dressing (drawn, no assets): an old television's glass (a soft glow
## from the middle, faint scanlines, darker corners), the memory card
## itself beside the first line with its slot label and contacts, and a
## block cursor after the line being typed, blinking while it waits for the
## reader. Reduce motion: the cursor doesn't blink and the glow doesn't
## breathe. Nothing flashes.

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
var _art: Control
var _t := 0.0


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
	_art = Control.new()
	_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art.size = size
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.draw.connect(_draw_art)
	add_child(_art)
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
	_t += delta
	_art.queue_redraw()
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


## Where the cursor sits now: after the typed part of the current line.
func cursor_at() -> Vector2:
	var l := _labels[mini(_line, _labels.size() - 1)]
	var font := l.get_theme_font("font")
	var fs := l.get_theme_font_size("font_size")
	var typed := l.text.substr(0, l.visible_characters)
	var w := font.get_string_size(typed, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x if font else typed.length() * 6.0
	return l.position + Vector2(w + 2.0, 3.0)


## Whether the cursor shows this frame: solid while typing, blinking while
## it waits for the reader (always solid with reduced motion).
func cursor_on() -> bool:
	if _done or _line >= _labels.size():
		return false
	var l := _labels[_line]
	if l.visible_characters < l.text.length() or Settings.reduce_motion:
		return true
	return fmod(_held, 1.0) < 0.55


func _draw_art() -> void:
	var view := size
	var mid := view * 0.5
	# The glass: a soft glow from the middle (breathing very slowly), then
	# darker corners.
	var breath := 1.0 if Settings.reduce_motion else 0.92 + 0.08 * sin(_t * 0.8)
	for i in 14:
		var k := 1.0 - i / 14.0
		var r := Vector2(300, 150) * (0.35 + 0.65 * k)
		_art.draw_set_transform(mid, 0.0, Vector2(1.0, r.y / r.x))
		_art.draw_circle(Vector2.ZERO, r.x, Color(0.30, 0.62, 0.70, 0.008 * breath))
	_art.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for y in range(0, int(view.y), 2):
		_art.draw_line(Vector2(0, y + 0.5), Vector2(view.x, y + 0.5), Color(0, 0, 0, 0.16), 1.0)
	var corner := Color(0, 0, 0, 0.35)
	for c in [Vector2.ZERO, Vector2(view.x, 0), Vector2(0, view.y), view]:
		_art.draw_circle(c, 90.0, Color(0, 0, 0, 0.22))
		_art.draw_circle(c, 50.0, corner)
	# The memory card, beside the first line once it starts.
	var shown := clampf(float(_labels[0].visible_characters) / 4.0, 0.0, 1.0) if not _labels.is_empty() else 0.0
	if shown > 0.0:
		_memory_card(Vector2(62, 108), shown * (modulate.a if _done else 1.0))
	if cursor_on():
		var owner_line: bool = LINES[_line][0] == "owner"
		var c := OWNER if owner_line else SYSTEM
		_art.draw_rect(Rect2(cursor_at(), Vector2(6, 11)), Color(c, 0.85))


## A small grey memory card seen face on: the notched corner, a label with
## the slot written on it, the contacts along the bottom edge, and a tiny
## access light that glows while the card is being read.
func _memory_card(at: Vector2, a: float) -> void:
	var body := PackedVector2Array([at, at + Vector2(16, 0), at + Vector2(20, 4), at + Vector2(20, 26), at + Vector2(0, 26)])
	_art.draw_colored_polygon(PackedVector2Array(Array(body).map(func(p: Vector2) -> Vector2: return p + Vector2(1.5, 1.5))), Color(0, 0, 0, 0.5 * a))
	_art.draw_colored_polygon(body, Color(0.42, 0.44, 0.48, a))
	_art.draw_polyline(body + PackedVector2Array([at]), Color(0.62, 0.65, 0.7, a), 1.0)
	_art.draw_rect(Rect2(at + Vector2(3, 5), Vector2(14, 11)), Color(0.88, 0.86, 0.80, a))
	_art.draw_line(at + Vector2(5, 8), at + Vector2(14, 8), Color(0.25, 0.28, 0.4, a), 1.0)
	_art.draw_line(at + Vector2(5, 12), at + Vector2(11, 12), Color(0.25, 0.28, 0.4, a), 1.0)
	for i in 5:
		_art.draw_rect(Rect2(at + Vector2(3 + i * 3, 20), Vector2(2, 4)), Color(0.78, 0.66, 0.35, a))
	var reading := not _done and _line < _labels.size() and _labels[_line].visible_characters < _labels[_line].text.length()
	_art.draw_circle(at + Vector2(17, 17.5), 1.0, Color(0.95, 0.35, 0.2, a) if reading else Color(0.3, 0.12, 0.1, a))


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

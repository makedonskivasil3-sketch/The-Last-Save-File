class_name RecordsPanel
extends VBoxContainer
## The title screen's RECORDS: every ending, memory and secret you've found
## (with a hint for the ones you haven't), and what the owner has counted.
## Everything here comes from OwnerMemory, so it survives between runs (and
## resets with Settings > Reset the owner's memory).

signal closed

const FOUND := Color("8cf2ff")
const ENDING_COL := Color("f0e0c8")

var _back: Button


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	UiStyle.heading(self, "RECORDS", UiStyle.TEXT, 16)
	UiStyle.note(self, progress_line(), UiStyle.MUTED)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 230)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var cols := HBoxContainer.new()
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 16)
	scroll.add_child(cols)
	var left := _column(cols)
	var right := _column(cols)

	_section(left, "ENDINGS")
	for e in Story.ENDINGS_RECORD:
		if e[0] in OwnerMemory.endings_seen:
			_entry(left, e[1], e[2], ENDING_COL)
		else:
			_entry(left, "? ? ?", e[3], UiStyle.MUTED)

	_section(right, "MEMORIES")
	for f in Story.FRAGMENTS:
		var title: String = str(f.title).trim_prefix("MEMORY · ")
		if OwnerMemory.has_fragment(f.id):
			_line(right, title, FOUND)
		else:
			_line(right, "? ? ?   (%s)" % _area_name(f.area), UiStyle.MUTED)
	_section(right, "SECRETS")
	for sec in Story.secrets():
		if sec[2]:
			_line(right, sec[0], FOUND)
		else:
			_entry(right, "? ? ?", sec[1], UiStyle.MUTED)

	_section(left, "THE OWNER COUNTED")
	_line(left, stats_line(), UiStyle.TEXT)
	var worst := worst_death()
	if worst != "":
		_line(left, worst, UiStyle.OWNER)

	_back = UiStyle.button(self, "Back", func() -> void: closed.emit(), "ui_back")


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		closed.emit()


func focus_first() -> void:
	_back.grab_focus()


## "ENDINGS 1/4 · MEMORIES 2/5 · SECRETS 0/4" (also on the save card).
static func progress_line() -> String:
	var secrets_found := 0
	for sec in Story.secrets():
		if sec[2]:
			secrets_found += 1
	var endings := 0
	for e in Story.ENDINGS_RECORD:
		if e[0] in OwnerMemory.endings_seen:
			endings += 1
	return "ENDINGS %d/%d   ·   MEMORIES %d/%d   ·   SECRETS %d/%d" % [endings, Story.ENDINGS_RECORD.size(),
			OwnerMemory.fragments.size(), Story.FRAGMENTS.size(), secrets_found, Story.secrets().size()]


static func stats_line() -> String:
	return "runs %d   ·   deaths %d   ·   quits %d   ·   escapes %d" % [OwnerMemory.sessions, OwnerMemory.deaths,
			OwnerMemory.quits, OwnerMemory.wins]


## What got you most often, if anything has.
static func worst_death() -> String:
	var best := ""
	var most := 0
	for reason in OwnerMemory.death_causes:
		if int(OwnerMemory.death_causes[reason]) > most:
			most = int(OwnerMemory.death_causes[reason])
			best = reason
	if best == "" or not Story.DEATHS.has(best):
		return ""
	return "most often: %s  (x%d)" % [str(Story.DEATHS[best][0]).to_lower(), most]


func _column(parent: Control) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	parent.add_child(v)
	return v


func _section(parent: Control, text: String) -> void:
	var l := Label.new()
	l.text = text
	UiStyle.sized(l, 10)
	l.add_theme_color_override("font_color", UiStyle.OWNER)
	parent.add_child(l)


func _line(parent: Control, text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.sized(l, 9)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)


func _entry(parent: Control, title: String, body: String, color: Color) -> void:
	_line(parent, title, color)
	var l := Label.new()
	l.text = "   " + body
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.sized(l, 8)
	l.add_theme_color_override("font_color", Color(UiStyle.MUTED, 0.85))
	parent.add_child(l)


static func _area_name(area: String) -> String:
	return {"room": "arin's room", "square": "ashvale", "oob": "out of bounds", "archive": "the archive",
		"edge": "the edge"}.get(area, area)

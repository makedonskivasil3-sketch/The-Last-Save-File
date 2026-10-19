class_name JournalPanel
extends VBoxContainer
## The artefact journal: every note, book, file and memory Rue has read,
## kept word for word (OwnerMemory.journal). Pick one on the left to read it
## on the right. Opened from the title screen and the pause menu.

signal closed

const KIND_LABEL := {"memory": "MEMORY", "note": "NOTE", "book": "BOOK", "file": "FILE"}
const KIND_COL := {"memory": Color("8cf2ff"), "note": Color("e6d6b0"), "book": Color("c8b8a0"), "file": Color("9fd8a0")}

var _list: VBoxContainer
var _title: Label
var _status: Label
var _where: Label
var _body: Label
var _text_scroll: ScrollContainer
var _back: Button
var _count: Label


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	UiStyle.heading(self, "JOURNAL", UiStyle.TEXT, 16)
	_count = UiStyle.note(self, "", UiStyle.MUTED)
	# Where she is in her own story (Progression): more than the HUD says.
	_status = UiStyle.note(self, "", UiStyle.TEXT)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size = Vector2(190, 220)
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(list_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	list_scroll.add_child(_list)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(page)
	_title = UiStyle.heading(page, "", UiStyle.OWNER, 12)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_where = UiStyle.note(page, "", UiStyle.MUTED)
	_where.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text_scroll = ScrollContainer.new()
	_text_scroll.custom_minimum_size = Vector2(300, 180)
	_text_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Focusable, so keys and gamepads can scroll a long entry (ScrollContainer
	# can't take focus by default).
	_text_scroll.focus_mode = Control.FOCUS_ALL
	page.add_child(_text_scroll)
	_body = UiStyle.note(_text_scroll, "", UiStyle.TEXT)
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_back = UiStyle.button(self, "Back", func() -> void: closed.emit(), "ui_back")
	refresh()


## Rebuild the list from OwnerMemory (call before showing).
func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var entries := OwnerMemory.journal
	_status.text = Progression.journal_summary()
	_count.text = "%d kept" % entries.size() if not entries.is_empty() else ""
	if entries.is_empty():
		_show_empty()
		return
	for i in entries.size():
		var e: Dictionary = entries[i]
		var b := Button.new()
		# The colour says what kind it is; a plain "NOTE" says where it hangs.
		b.text = _short(e.title) if e.title != KIND_LABEL.get(e.kind, "") else "%s · %s" % [e.title, str(e.area).to_lower()]
		b.tooltip_text = e.title
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_color_override("font_color", KIND_COL.get(e.kind, UiStyle.TEXT))
		b.focus_entered.connect(_show_entry.bind(i))
		b.focus_entered.connect(func() -> void: Sfx.ui("ui_move"))
		b.mouse_entered.connect(_show_entry.bind(i))
		b.pressed.connect(func() -> void: _text_scroll.grab_focus())
		_list.add_child(b)
	_show_entry(entries.size() - 1)


func _short(title: String) -> String:
	return title.trim_prefix("MEMORY · ")


func _show_empty() -> void:
	_title.text = "NOTHING YET"
	_where.text = ""
	_body.text = "Notes, books, files and memories you read are kept here, word for word, so you can read them again.\n\nThe owner can't edit this page."


func _show_entry(i: int) -> void:
	var entries := OwnerMemory.journal
	if i < 0 or i >= entries.size():
		return
	var e: Dictionary = entries[i]
	_title.text = e.title
	_title.add_theme_color_override("font_color", KIND_COL.get(e.kind, UiStyle.OWNER))
	_where.text = "%s  ·  %s" % [KIND_LABEL.get(e.kind, "FILE").to_lower(), str(e.area).to_lower()]
	_body.text = "\n\n".join(e.lines)
	_text_scroll.scroll_vertical = 0


## The text currently on the page (tests).
func page_text() -> String:
	return _body.text


func _process(delta: float) -> void:
	if not is_visible_in_tree() or not _text_scroll.has_focus():
		return
	var dir := Input.get_axis("move_up", "move_down")
	if absf(dir) > 0.2:
		_text_scroll.scroll_vertical += int(dir * 220.0 * delta)


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		if _text_scroll.has_focus() and _list.get_child_count() > 0:
			focus_first()
		else:
			closed.emit()


func focus_first() -> void:
	var last := _list.get_child_count() - 1
	if last >= 0 and not _list.get_child(last).is_queued_for_deletion():
		(_list.get_child(last) as Button).grab_focus()
	else:
		_back.grab_focus()

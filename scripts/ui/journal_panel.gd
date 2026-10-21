class_name JournalPanel
extends VBoxContainer
## The archive Rue keeps (docs/NARRATIVE_CONTRACT.md §3): people she has
## met, memories, documents read word for word, objects and where they are
## now, places and current leads (ArchivePages). Pick a section, then an
## entry on the left to read it on the right; new entries are marked until
## opened. Opened from the title screen and the pause menu.
##
## Reading rules (docs/COHERENCE_MILESTONE.md, F8/F9): the journal reopens
## where the reader left it; an entry counts as read once it has been on
## the page for DWELL seconds, or is picked on purpose (a click, or moving
## to it with keys or a pad); passing over it with the mouse doesn't. An
## entry that says something new since it was read is marked "updated".

signal closed

const KIND_LABEL := {"memory": "MEMORY", "note": "NOTE", "book": "BOOK", "file": "FILE", "person": "PERSON",
	"object": "OBJECT", "place": "PLACE", "lead": "LEAD"}
const KIND_COL := {"memory": Color("8cf2ff"), "note": Color("e6d6b0"), "book": Color("c8b8a0"), "file": Color("9fd8a0"),
	"person": Color("f0c8a0"), "object": Color("d8c0f0"), "place": Color("b0c8e8"), "lead": Color("f2e08c")}
const NEW_MARK := "• "
const UPDATED_MARK := "+ "
## Seconds an entry must stay on the page to count as read.
const DWELL := 1.5

## Where the reader was (kept while the game runs, across openings).
static var _last_section := ""
static var _last_key := ""


## A new game, or a test: nowhere to return to.
static func forget_place() -> void:
	_last_section = ""
	_last_key = ""

var _list: VBoxContainer
var _tabs: HBoxContainer
var _title: Label
var _status: Label
var _where: Label
var _body: Label
var _text_scroll: ScrollContainer
var _back: Button
var _count: Label
var _portrait: PortraitView
## The section on show (ArchivePages.SECTIONS) and its entries.
var section := "documents"
var _entries: Array = []
## The entry on the page, and how long it has been there.
var _shown := -1
var _dwell := 0.0
## Focus moved by the panel itself (opening it), not by the reader.
var _auto_focus := false


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	UiStyle.heading(self, "JOURNAL", UiStyle.TEXT, 16)
	_count = UiStyle.note(self, "", UiStyle.MUTED)
	# Where she is in her own story (Progression): more than the HUD says.
	_status = UiStyle.note(self, "", UiStyle.TEXT)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 4)
	add_child(_tabs)
	for id in ArchivePages.SECTIONS:
		var t := Button.new()
		t.text = ArchivePages.SECTION_LABEL[id]
		t.focus_mode = Control.FOCUS_ALL
		t.toggle_mode = true
		t.add_theme_font_size_override("font_size", 9)
		t.pressed.connect(func() -> void:
			_last_section = id  # the reader chose it
			_last_key = ""
			show_section(id))
		t.set_meta("section", id)
		_tabs.add_child(t)
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
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	page.add_child(head)
	# A person's face, as last seen (their colours then, not now).
	_portrait = PortraitView.new()
	_portrait.custom_minimum_size = Vector2(40, 40)
	_portrait.visible = false
	head.add_child(_portrait)
	_title = UiStyle.heading(head, "", UiStyle.OWNER, 12)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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


## "new", "updated" or "" for an entry (leads are never marked).
static func mark_of(e: Dictionary) -> String:
	if str(e.key).begins_with("lead:"):
		return ""
	return OwnerMemory.archive_mark(e.key, str(e.get("rev", "")))


static func _mark_text(mark: String) -> String:
	return NEW_MARK if mark == "new" else (UPDATED_MARK if mark == "updated" else "")


## Rebuild from OwnerMemory (call before showing). Reopens where the reader
## left it; the very first time, on the section of the newest thing kept.
func refresh() -> void:
	_status.text = Progression.journal_summary()
	var total := 0
	for id in ArchivePages.SECTIONS:
		if id != "leads":
			total += ArchivePages.section(id).size()
	_count.text = ("%d kept   ·   %snew   %supdated" % [total, NEW_MARK, UPDATED_MARK]) if total > 0 else ""
	if _last_section != "":
		section = _last_section
	elif not OwnerMemory.journal.is_empty():
		section = "memories" if OwnerMemory.journal[-1].kind == "memory" else "documents"
	elif not ArchivePages.people().is_empty():
		section = "people"
	show_section(section, _last_key if section == _last_section else "")


## Shows a section. select_key: the entry to put on the page (else the
## newest unread one here, else the last).
func show_section(id: String, select_key := "") -> void:
	section = id
	_update_tabs()
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_entries = ArchivePages.section(id)
	_shown = -1
	if _entries.is_empty():
		_show_empty()
		return
	var pick := -1
	for i in _entries.size():
		var e: Dictionary = _entries[i]
		var b := Button.new()
		var label: String = _short(e.title) if e.title != KIND_LABEL.get(e.kind, "") else "%s · %s" % [e.title, str(e.area).to_lower()]
		b.set_meta("label", label)
		b.text = _mark_text(mark_of(e)) + label
		b.tooltip_text = e.title
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_color_override("font_color", KIND_COL.get(e.kind, UiStyle.TEXT))
		# Moving here with keys or a pad is choosing it; the panel's own
		# focus on opening is not.
		b.focus_entered.connect(func() -> void: _show_entry(i, not _auto_focus))
		b.focus_entered.connect(func() -> void: Sfx.ui("ui_move"))
		b.mouse_entered.connect(_show_entry.bind(i, false))  # a preview
		b.pressed.connect(func() -> void:
			_show_entry(i, true)
			_text_scroll.grab_focus())
		_list.add_child(b)
		if e.key == select_key:
			pick = i
		elif pick < 0 and select_key == "" and mark_of(e) != "":
			pick = i
	_show_entry(pick if pick >= 0 else _entries.size() - 1, false)


func _update_tabs() -> void:
	for t in _tabs.get_children():
		var sid: String = t.get_meta("section")
		(t as Button).button_pressed = sid == section
		var marks := ArchivePages.section(sid).map(mark_of)
		var mark := "new" if "new" in marks else ("updated" if "updated" in marks else "")
		(t as Button).text = _mark_text(mark) + ArchivePages.SECTION_LABEL[sid]


func _short(title: String) -> String:
	return title.trim_prefix("MEMORY · ")


func _show_empty() -> void:
	_portrait.visible = false
	_title.text = "NOTHING YET"
	_where.text = ""
	_body.text = {
		"people": "People you meet are kept here: what you've learned about them, and what happened between you.",
		"objects": "Things you find, use, give back or lose, and where each one is now.",
		"places": "Places you've been.",
		"leads": "Nothing to follow yet.",
	}.get(section, "Notes, books, files and memories you read are kept here, word for word, so you can read them again.\n\nThe owner can't edit this page.")


func _show_entry(i: int, deliberate := false) -> void:
	if i < 0 or i >= _entries.size():
		return
	var e: Dictionary = _entries[i]
	if i != _shown:
		_dwell = 0.0
	_shown = i
	_title.text = e.title
	_title.add_theme_color_override("font_color", KIND_COL.get(e.kind, UiStyle.OWNER))
	_where.text = KIND_LABEL.get(e.kind, "FILE").to_lower() + ("  ·  %s" % str(e.area).to_lower() if str(e.area) != "" and e.kind != "place" else "")
	_body.text = e.body
	_text_scroll.scroll_vertical = 0
	var who: String = e.get("who", "")
	_portrait.visible = who != "" and CharacterArt.has_portrait(who)
	if _portrait.visible:
		_portrait.portrait = CharacterArt.Portrait.new(who, "neutral", OwnerMemory.look_of(who))
	if deliberate:
		_mark_read(i)


## The entry on the page has been read: no more "new" or "updated" on it.
func _mark_read(i: int) -> void:
	if i < 0 or i >= _entries.size() or not is_visible_in_tree():
		return
	var e: Dictionary = _entries[i]
	# Read on purpose (or long enough): this is where the reader is.
	_last_section = section
	_last_key = e.key
	if mark_of(e) == "":
		return
	OwnerMemory.mark_seen_in_archive(e.key, str(e.get("rev", "")))
	if i < _list.get_child_count():
		var b := _list.get_child(i) as Button
		b.text = str(b.get_meta("label", b.text))
	_update_tabs()


## The key of the entry on the page ("" if none) (tests).
func shown_key() -> String:
	return str(_entries[_shown].key) if _shown >= 0 and _shown < _entries.size() else ""


## The text currently on the page (tests).
func page_text() -> String:
	return _body.text


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	# On the page long enough: read.
	if _shown >= 0 and _dwell < DWELL:
		_dwell += delta
		if _dwell >= DWELL:
			_mark_read(_shown)
	if not _text_scroll.has_focus():
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


## Focus the entry on the page (not a choice the reader made).
func focus_first() -> void:
	var i := _shown if _shown >= 0 else _list.get_child_count() - 1
	if i >= 0 and i < _list.get_child_count() and not _list.get_child(i).is_queued_for_deletion():
		_auto_focus = true
		(_list.get_child(i) as Button).grab_focus()
		_auto_focus = false
	else:
		_back.grab_focus()

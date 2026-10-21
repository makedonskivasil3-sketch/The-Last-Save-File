class_name JournalPanel
extends VBoxContainer
## The archive Rue keeps (docs/NARRATIVE_CONTRACT.md §3): people she has
## met, memories, documents read word for word, objects and where they are
## now, places and current leads (ArchivePages). Pick a section, then an
## entry on the left to read it on the right; new entries are marked until
## opened. Opened from the title screen and the pause menu.

signal closed

const KIND_LABEL := {"memory": "MEMORY", "note": "NOTE", "book": "BOOK", "file": "FILE", "person": "PERSON",
	"object": "OBJECT", "place": "PLACE", "lead": "LEAD"}
const KIND_COL := {"memory": Color("8cf2ff"), "note": Color("e6d6b0"), "book": Color("c8b8a0"), "file": Color("9fd8a0"),
	"person": Color("f0c8a0"), "object": Color("d8c0f0"), "place": Color("b0c8e8"), "lead": Color("f2e08c")}
const NEW_MARK := "• "

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
		t.pressed.connect(show_section.bind(id))
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


## Rebuild from OwnerMemory (call before showing). Opens on the section of
## the newest thing kept, so a memory just lived is the first thing shown.
func refresh() -> void:
	_status.text = Progression.journal_summary()
	var total := 0
	for id in ArchivePages.SECTIONS:
		if id != "leads":
			total += ArchivePages.section(id).size()
	_count.text = "%d kept" % total if total > 0 else ""
	if not OwnerMemory.journal.is_empty():
		section = "memories" if OwnerMemory.journal[-1].kind == "memory" else "documents"
	elif not ArchivePages.people().is_empty():
		section = "people"
	show_section(section)


func show_section(id: String) -> void:
	section = id
	for t in _tabs.get_children():
		var sid: String = t.get_meta("section")
		(t as Button).button_pressed = sid == id
		var fresh := ArchivePages.section(sid).any(func(e: Dictionary) -> bool: return e.key not in OwnerMemory.archive_seen)
		(t as Button).text = (NEW_MARK if fresh and sid != "leads" else "") + ArchivePages.SECTION_LABEL[sid]
	for c in _list.get_children():
		c.queue_free()
	_entries = ArchivePages.section(id)
	if _entries.is_empty():
		_show_empty()
		return
	for i in _entries.size():
		var e: Dictionary = _entries[i]
		var b := Button.new()
		var label: String = _short(e.title) if e.title != KIND_LABEL.get(e.kind, "") else "%s · %s" % [e.title, str(e.area).to_lower()]
		b.text = (NEW_MARK if e.key not in OwnerMemory.archive_seen and id != "leads" else "") + label
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
	_show_entry(_entries.size() - 1)


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


func _show_entry(i: int) -> void:
	if i < 0 or i >= _entries.size():
		return
	var e: Dictionary = _entries[i]
	_title.text = e.title
	_title.add_theme_color_override("font_color", KIND_COL.get(e.kind, UiStyle.OWNER))
	_where.text = KIND_LABEL.get(e.kind, "FILE").to_lower() + ("  ·  %s" % str(e.area).to_lower() if str(e.area) != "" and e.kind != "place" else "")
	_body.text = e.body
	_text_scroll.scroll_vertical = 0
	var who: String = e.get("who", "")
	_portrait.visible = who != "" and CharacterArt.has_portrait(who)
	if _portrait.visible:
		_portrait.portrait = CharacterArt.Portrait.new(who, "neutral", OwnerMemory.look_of(who))
	if e.key not in OwnerMemory.archive_seen and section != "leads" and is_visible_in_tree():
		OwnerMemory.mark_seen_in_archive(e.key)


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

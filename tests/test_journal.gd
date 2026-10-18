extends "res://tests/test_case.gd"
## The artefact journal: what Rue reads is kept, word for word, and survives
## saving, loading and new sessions.


func _readable(w: Node, title: String) -> Node2D:
	for n in w.area.interactables:
		if n is Readable and n.title == title:
			return n
	return null


func test_reading_a_book_keeps_it() -> void:
	var w := await start_session()
	await go_to(w, "archive", "west")
	var book := _readable(w, "SESSION LOG")
	check(book != null, "the archive has its session log")
	w._interact(book)
	await frames(2)
	var m := memory()
	check_eq(m.journal.size(), 1, "one entry kept")
	var e: Dictionary = m.journal[0]
	check_eq(e.kind, "book", "kept as a book")
	check_eq(e.title, "SESSION LOG", "with its title")
	check(e.lines == book.lines_provider.call(), "word for word")
	w.hud.close_dialogue()
	w._interact(book)
	check_eq(m.journal.size(), 1, "reading it again doesn't duplicate it")


func test_signs_are_not_artefacts() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var sign := _readable(w, "ARIN'S HOUSE")
	check(sign != null, "the square has the house sign")
	w._interact(sign)
	check(memory().journal.is_empty(), "a sign isn't kept")


func test_a_rewritten_note_keeps_both_versions() -> void:
	var m := memory()
	check(m.record_read("room:NOTE", "note", "NOTE", "ARIN'S ROOM", ["STAY IN YOUR ROOM."]), "first read is new")
	check(not m.record_read("room:NOTE", "note", "NOTE", "ARIN'S ROOM", ["I SAW YOU."]), "a re-read isn't new")
	check_eq(m.journal[0].lines, ["STAY IN YOUR ROOM.", "I SAW YOU."], "both versions, in the order seen")


func test_the_journal_survives_a_reload_and_rejects_junk() -> void:
	var m := memory()
	m.record_read("memory:well", "memory", "MEMORY · THE WELL", "ASHVALE", ["line one", "line two"])
	m.save_memory()
	m.journal.clear()
	m.load_memory()
	check_eq(m.journal.size(), 1, "the entry came back")
	check_eq(m.journal[0].lines, ["line one", "line two"], "with its lines")
	var raw := FileAccess.open(m._path, FileAccess.READ).get_as_text()
	var data: Dictionary = JSON.parse_string(raw)
	data.journal = [{"id": 3}, "nope", {"id": "x", "title": "T", "lines": [1, "ok"]}]
	SafeFile.write_atomic(m._path, JSON.stringify(data))
	m.load_memory()
	check_eq(m.journal.size(), 1, "only the well-formed entry loads")
	check_eq(m.journal[0].lines, ["ok"], "and only its text lines")
	m.wipe()
	check(m.journal.is_empty(), "a reset clears the journal")


func test_memories_are_kept_and_readable_from_pause() -> void:
	var w := await start_session()
	var f: Dictionary = Story.FRAGMENTS[0]
	memory().record_read("memory:" + f.id, "memory", f.title, "ARIN'S ROOM", f.lines)
	w._pause_menu.open()
	w._pause_menu._show_journal()
	await frames(3)
	var j: JournalPanel = w._pause_menu._journal
	check(j.is_visible_in_tree(), "the journal opens from pause")
	check(j.page_text().contains(f.lines[0]), "showing the memory's text")
	w._pause_menu.close()


func test_a_long_entry_scrolls_with_keys_and_gamepad() -> void:
	var m := memory()
	var lines: Array = []
	for i in 16:
		lines.append("line %d of a long file that goes on for a while." % i)
	m.record_read("bin:long.txt", "file", "long.txt", "BIN", lines)
	var w := await start_session()
	w._pause_menu.open()
	w._pause_menu._show_journal()
	await frames(3)
	var j: JournalPanel = w._pause_menu._journal
	await press("ui_accept")  # pick the entry: focus moves to its text
	await frames(2)
	check(j._text_scroll.has_focus(), "the text takes focus")
	var before: int = j._text_scroll.scroll_vertical
	_act("move_down", true)
	await wait(0.4)
	_act("move_down", false)
	check(j._text_scroll.scroll_vertical > before, "and scrolls with down")
	w._pause_menu.close()

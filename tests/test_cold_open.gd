extends "res://tests/test_case.gd"
## The memory card before the festival (scripts/ui/cold_open.gd): a first
## run only; each line waits for the reader; held Esc skips it; the journal
## keeps it either way.


func _title() -> Node:
	settings().opening_seen = false
	var title: Node = load("res://scenes/title.tscn").instantiate()
	var old := tree.current_scene
	tree.root.add_child(title)
	tree.current_scene = title
	if old:
		old.queue_free()
	await frames(3)
	return title


func test_a_first_run_opens_on_the_memory_card() -> void:
	var title := await _title()
	title._start()
	await wait_until(func() -> bool: return scene() is ColdOpen, 3.0, "the memory card")
	check(scene() is ColdOpen, "the memory card comes first")
	var card: ColdOpen = scene()
	await wait(3.0)
	check_eq(card._line, 0, "with nobody pressing, it waits on its first line")
	check_eq(card._labels[0].visible_characters, card._labels[0].text.length(), "(typed out)")
	for i in ColdOpen.LINES.size():
		await wait(2.0)
		await press("interact")
	check(await wait_until(func() -> bool: return scene() is Prologue, 6.0, "the festival"), "read through: the festival")
	check(memory().journal.any(func(e: Dictionary) -> bool: return e.id == "festival:cold_open"), "kept in the journal")
	check_eq(memory().sessions, 0, "no run has started")


func test_held_esc_skips_it_and_the_journal_still_has_it() -> void:
	var title := await _title()
	title._start()
	await wait_until(func() -> bool: return scene() is ColdOpen, 3.0, "the memory card")
	Input.action_press("ui_cancel")
	await wait(1.0)
	Input.action_release("ui_cancel")
	check(await wait_until(func() -> bool: return scene() is Prologue, 6.0, "the festival"), "skipped to the festival")
	check(memory().journal.any(func(e: Dictionary) -> bool: return e.id == "festival:cold_open"), "nothing lost: it's in the journal")


func test_a_replay_from_the_menu_skips_it() -> void:
	var title := await _title()
	title._play_prologue(true)
	await frames(4)
	check(scene() is Prologue and scene().replay, "the festival replay goes straight in")

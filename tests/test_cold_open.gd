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


func test_the_cursor_waits_with_the_reader() -> void:
	var title := await _title()
	title._start()
	await wait_until(func() -> bool: return scene() is ColdOpen, 3.0, "the memory card")
	var card: ColdOpen = scene()
	check(card.cursor_on(), "solid while typing")
	await wait(2.5)
	var seen := {}
	for i in 24:
		seen[card.cursor_on()] = true
		await wait(0.05)
	check(seen.has(true) and seen.has(false), "blinks while it waits")
	settings().reduce_motion = true
	var steady := true
	for i in 24:
		steady = steady and card.cursor_on()
		await wait(0.05)
	check(steady, "reduce motion: it doesn't blink")
	check(card.cursor_at().x > card._labels[0].position.x + 100.0, "it sits after the typed line")
	settings().reduce_motion = false


func test_instant_text_and_reveal_require_a_separate_advance() -> void:
	var old_speed: int = settings().text_speed
	var title := await _title()
	title._start()
	await wait_until(func() -> bool: return scene() is ColdOpen, 3.0, "card")
	var card: ColdOpen = scene()
	card.set_process(false)
	settings().text_speed = 3
	card._typed = 0.0
	card._labels[0].visible_characters = 0
	card._process(0.01)
	check_eq(card._labels[0].visible_characters, card._labels[0].text.length(), "Instant applies to the card")
	settings().text_speed = 1
	card._typed = 0.0
	card._labels[0].visible_characters = 0
	card._armed = true
	Input.action_press("interact")
	card._process(0.01)
	check_eq(card._labels[0].visible_characters, card._labels[0].text.length(), "first press reveals")
	card._process(0.5)
	check_eq(card._line, 0, "holding the revealing press cannot dismiss the line")
	Input.action_release("interact")
	card._process(0.01)
	Input.action_press("interact")
	card._process(0.01)
	check_eq(card._line, 1, "a separate press advances")
	Input.action_release("interact")
	settings().text_speed = old_speed


func test_focus_loss_freezes_typing_and_clears_skip_hold() -> void:
	var title := await _title()
	title._start()
	await wait_until(func() -> bool: return scene() is ColdOpen, 3.0, "card")
	var card: ColdOpen = scene()
	card.set_process(false)
	var before: float = card._typed
	card._skip_t = 0.6
	card.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	card._process(2.0)
	check_eq(card._typed, before, "typing freezes while away")
	check_eq(card._skip_t, 0.0, "skip hold is canceled")
	card.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	card._process(0.1)
	check(card._typed > before, "typing resumes on return")

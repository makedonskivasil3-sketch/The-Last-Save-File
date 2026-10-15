extends "res://tests/test_case.gd"
## The Slot 2 choice and its three endings.


func _at_slot(with_wren := false) -> Node:
	var w := await start_session()
	if with_wren:
		w.debug("wren")
	w.debug("slot2")
	await wait_until(func() -> bool: return w.area.area_id == "edge" and not w._transitioning, 3.0, "at the Edge")
	if with_wren:
		w.escort.global_position = w.player.global_position
	return w


func _finish(w: Node) -> void:
	for i in 60:
		if w._win_card_shown:
			return
		await press("interact")
		await wait(0.2)


func _choices(w: Node) -> Array:
	var out: Array = []
	for b in w.hud._choice_list.get_children():
		out.append(b.text)
	return out


func test_two_choices_without_wren() -> void:
	var w := await _at_slot()
	w.reach_slot2()
	await until_choosing(w)
	check(w.hud.is_choosing(), "Slot 2 asks whose name goes there")
	check_eq(_choices(w).size(), 2, "yourself, or a message for the owner")


func test_escape_ending() -> void:
	var w := await _at_slot()
	w.reach_slot2()
	await until_choosing(w)
	w.hud._chosen.emit(0)
	await _finish(w)
	check_eq(memory().last_ending, "escape", "you took the slot")
	check(w.hud._overlay_title.text.begins_with("SAVED TO SLOT 2"), "the escape end card")


func test_wren_ending() -> void:
	var w := await _at_slot(true)
	w.reach_slot2()
	await until_choosing(w)
	check_eq(_choices(w).size(), 3, "with Wren there, three choices")
	w.hud._chosen.emit(1)
	await _finish(w)
	check_eq(memory().last_ending, "wren", "you gave her the slot")
	check(w.hud._overlay_title.text.contains("WREN"), "her end card")
	get_tree_change_to_title()
	await frames(5)
	check(_title_text().contains("WREN"), "the title shows her in slot 2")


func test_message_ending_reconciles() -> void:
	memory().purge = 3
	memory().npc_fates["mira"] = "deleted"
	var w := await _at_slot()
	w.reach_slot2()
	await until_choosing(w)
	w.hud._chosen.emit(1)  # the message
	await frames(3)
	check(w.hud.is_choosing(), "then you choose what to write")
	w.hud._chosen.emit(0)
	await _finish(w)
	check_eq(memory().last_ending, "message", "you handed the slot back")
	check_eq(memory().purge, 0, "the owner stops the purge")
	check(memory().npc_fates.is_empty(), "and lets everyone back")
	get_tree_change_to_title()
	await frames(5)
	check(_title_text().contains("someone is waiting"), "the title changes its tune")


func get_tree_change_to_title() -> void:
	tree.change_scene_to_file("res://scenes/title.tscn")
	await frames(3)


func _title_text() -> String:
	var out := ""
	var s := scene()
	if s == null:
		return out
	for n in s.find_children("*", "Label", true, false):
		out += (n as Label).text + "\n"
	return out

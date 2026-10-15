extends "res://tests/test_case.gd"
## Phase 3: the owner as a person (notes between runs), the weight of every
## run at Slot 2, the false memory, the bin's unsent draft.


func _said(w: Node) -> String:
	var out := ""
	for q in w.hud._queue:
		out += str(q.text) + "\n"
	for l in w.hud._console.find_children("*", "Label", true, false):
		out += (l as Label).text + "\n"
	if w.hud._typing:
		out += w.hud._typing.text
	return out


func test_the_owner_leaves_a_note_each_run() -> void:
	memory().sessions = 1
	memory().last_exit = "death"
	var w := await start_session()
	check(_said(w).contains(Story.OWNER_NOTES[0]), "the first note, on the second run")
	check_eq(memory().owner_notes_seen, 1, "remembered")
	w.kill("erased", "eraser")
	var next := await wait_for_new_session(w)
	check(_said(next).contains(Story.OWNER_NOTES[1]), "the next note, the run after")


func test_notes_react_to_how_you_played() -> void:
	memory().last_run_glitches = 9
	check(Story.owner_note_about_you().contains("holes"), "lots of glitching: the owner says so")
	memory().last_run_glitches = 0
	memory().wren_saved = true
	check(Story.owner_note_about_you().contains("putting people back"), "saving people: the owner notices")


func test_the_archive_keeps_the_notes() -> void:
	memory().owner_notes_seen = 3
	var w := await start_session()
	await go_to(w, "archive", "west")
	var lines := "\n".join(w.area._owner_notes())
	check(lines.contains(Story.OWNER_NOTES[2]), "the pages you've read are in the book")
	check(not lines.contains(Story.OWNER_NOTES[5]), "not the ones you haven't")


func test_slot_two_carries_every_run() -> void:
	memory().sessions = 6
	memory().deaths = 4
	memory().total_reloads = 3
	memory().npc_fates["wren"] = "deleted"
	var recap := Story.slot2_recap(false)
	check(str(recap).contains("4 times"), "the deaths")
	check(str(recap).contains("reloaded 3"), "the reloads")
	check(str(recap).contains("trusted you"), "Wren, lost")


func test_the_false_memory() -> void:
	memory().sessions = 3
	memory().add_fragment("controller")
	memory().add_fragment("well")
	var w := await start_session()
	await go_to(w, "square", "house")
	var lie: MemoryFragment = null
	for c in w.area.get_children():
		if c is MemoryFragment and c.planted:
			lie = c
	check(lie != null, "after two memories, the owner plants one")
	w.area.arin.position = Vector2(100, 280)
	var before: float = w.director.awareness
	w.recover_fragment(lie)
	await wait_until(func() -> bool: return not w._cutscene, 30.0, "the false memory")
	check(memory().false_memory_taken, "taken")
	check_eq(memory().fragments.size(), 2, "it doesn't count as yours")
	check(w.director.awareness >= before + 15.0, "and it costs you")
	check(w.owner_moves.save_progress >= 0.0, "the owner starts saving over you")


func test_the_bin_keeps_the_unsent_draft() -> void:
	var w := await start_session()
	await go_to(w, "archive", "west")
	await go_to(w, "bin", "west")
	var draft: Readable = null
	for n in w.area.interactables:
		if n is Readable and n.title == "owner_draft.txt":
			draft = n
	check(draft != null and "\n".join(draft.interact().lines).contains("still have your sa"), "the reply that was never sent")

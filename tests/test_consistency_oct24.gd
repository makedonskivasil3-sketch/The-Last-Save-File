extends "res://tests/test_case.gd"
## Consistency defects found in the 24 October review (docs/REVIEW_OCT24.md):
## A. what a line teaches is learned once the line is fully revealed, not
##    when its page opens;
## B. Rue only observes someone she can see;
## C. Tobben's reports don't stack;
## D. unbroken text pages at the limit asked for.


# --- A. facts at reveal --------------------------------------------------------

const NOT_ARIN := "You're not Arin. Who are you?"


func test_a_fact_is_not_learned_when_its_page_opens() -> void:
	var w := await start_session()
	settings().text_speed = 1  # typing, not instant
	w.hud.show_dialogue("MIRA", Color.WHITE, [NOT_ARIN])
	check(not memory().knows_fact("mira.not_arin"), "the page opened: nothing is read yet")
	w.hud.close_dialogue()  # walked away while it was still typing
	await frames(2)
	check(not memory().knows_fact("mira.not_arin"), "walked away mid-reveal: not learned")


func test_a_fact_is_learned_once_the_line_is_revealed() -> void:
	var w := await start_session()
	settings().text_speed = 1
	var revealed := []
	w.hud.line_revealed.connect(func(l: String) -> void: revealed.append(l))
	w.hud.show_dialogue("MIRA", Color.WHITE, [NOT_ARIN, "And another thing."])
	await press("interact")  # the first press reveals the whole line
	check(memory().knows_fact("mira.not_arin"), "revealed by a press: learned")
	await press("interact")
	await press("interact")
	check_eq(revealed.count(NOT_ARIN), 1, "learned exactly once (%s)" % [str(revealed)])
	w.hud.close_dialogue()


func test_instant_text_reveals_on_the_first_frame() -> void:
	var w := await start_session()
	settings().text_speed = 3  # Instant
	w.hud.show_dialogue("MIRA", Color.WHITE, [NOT_ARIN])
	await frames(2)
	check(memory().knows_fact("mira.not_arin"), "instant text: revealed at once, and learned")
	w.hud.close_dialogue()
	settings().text_speed = 1


func test_a_truth_piece_waits_for_its_line() -> void:
	var w := await start_session()
	settings().text_speed = 1
	w.hud.show_dialogue("MIRA", Color.WHITE, [Story.TRUTH_LINES.mira])
	check("mira" not in memory().truth_pieces, "opened, not read")
	w.hud.close_dialogue()
	await frames(2)
	check("mira" not in memory().truth_pieces, "walked away: no piece")
	w.hud.show_dialogue("MIRA", Color.WHITE, [Story.TRUTH_LINES.mira])
	await press("interact")
	check("mira" in memory().truth_pieces, "read: the piece")
	w.hud.close_dialogue()


func test_milestones_come_in_order_and_once() -> void:
	var w := await start_session()
	settings().text_speed = 1
	var seen := []
	w.hud.line_presented.connect(func(l: String) -> void: seen.append("presented:" + l))
	w.hud.line_revealed.connect(func(l: String) -> void: seen.append("revealed:" + l))
	w.hud.line_acknowledged.connect(func(l: String) -> void: seen.append("acknowledged:" + l))
	w.hud.show_dialogue("MIRA", Color.WHITE, ["One.", "Two."])
	await finish_dialogue(w)
	check_eq(seen, ["presented:One.", "revealed:One.", "acknowledged:One.", "presented:Two.", "revealed:Two.", "acknowledged:Two."], "presented, revealed, acknowledged, per line")
	check(w.hud.dialogue_finished, "and the conversation completed")


# --- B. observed only when seen -------------------------------------------------

func _seen(id: String) -> Dictionary:
	return memory().encounters.get(id, {}).get("seen", {})


func test_coming_back_from_the_archive_does_not_see_someone_off_screen() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await wait(0.6)
	memory().meet("wren", "square")
	await wait(0.6)
	check_eq(_seen("wren").get("state", ""), "well", "by the house door, Wren is in view: seen as she is")
	await go_to(w, "archive", "west")
	memory().npc_fates["wren"] = "deleted"  # while Rue was reading
	await go_to(w, "square", "east")
	await wait(0.6)
	check(w.view_offset.x > 200.0, "arrived at the east end: the house corner is off-screen")
	check_eq(_seen("wren").get("state", ""), "well", "Wren is off-screen: what Rue last saw stands (%s)" % [str(_seen("wren"))])
	check(ArchivePages.condition("wren") != "Deleted: you saw them gone.", "the journal doesn't claim she saw it")
	w.player.global_position = w.area.wren.global_position + Vector2(30, 0)
	await wait(1.5)
	check_eq(_seen("wren").get("state", ""), "deleted", "walked over: now she sees it")


func test_someone_in_view_on_arrival_is_seen_at_once() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	memory().meet("tobben", "square")
	await go_to(w, "archive", "west")
	await go_to(w, "square", "east")
	await wait(0.6)
	check_eq(int(_seen("tobben").get("session", -1)), memory().sessions, "Tobben's stall is in view from the east road: seen this run")


func test_a_save_with_old_sightings_keeps_them() -> void:
	memory().encounters["wren"] = {"first": 0, "last": 0, "count": 1, "seen": {"state": "well", "session": 0}}
	var w := await start_session()
	await go_to(w, "square", "east")
	check_eq(_seen("wren").get("session", -1), 0, "last seen in an earlier run, and not on screen now: kept")
	check(ArchivePages.condition("wren").contains("Since then: unknown"), "so the journal says since then is unknown")


# --- C. Tobben reports once, not once per conversation ---------------------------

func _reports(w: Node) -> int:
	var n := 0
	for m in w.hud._queue:
		if str(m.text).contains("tobben says"):
			n += 1
	for e in w.hud.history:
		if str(e.text).contains("tobben says"):
			n += 1
	return n


func _talk_to_tobben(w: Node) -> void:
	await interact_with(w, w.area.tobben)
	w.hud.close_dialogue()  # (walked off: he still saw her)
	await frames(2)


func test_rapid_conversations_make_one_report() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	for i in 3:
		await _talk_to_tobben(w)
		await wait(0.3)
	await wait(VillageSquare.REPORT_DELAY + 1.0)
	check_eq(_reports(w), 1, "three conversations in a row: he tells the owner once")
	await _talk_to_tobben(w)
	await wait(VillageSquare.REPORT_DELAY + 1.0)
	check_eq(_reports(w), 1, "and not again straight after (he already told)")


func test_a_report_waits_for_a_story_scene() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await _talk_to_tobben(w)
	w.hud.show_dialogue("WREN", Color.WHITE, ["A long, long story scene line."])
	await wait(VillageSquare.REPORT_DELAY + 1.0)
	check_eq(_reports(w), 0, "nothing lands while someone else is talking")
	w.hud.close_dialogue()
	await wait(VillageSquare.REPORT_DELAY + 1.0)
	check_eq(_reports(w), 1, "it lands after")


func test_leaving_the_square_does_not_stack_or_lose_it_twice() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await _talk_to_tobben(w)
	await go_to(w, "archive", "west")
	await go_to(w, "square", "east")
	await _talk_to_tobben(w)
	await wait(VillageSquare.REPORT_DELAY + 1.0)
	check(_reports(w) <= 1, "out and back in, talking again: still one report (%d)" % _reports(w))


func test_written_tobben_cannot_tell() -> void:
	memory().frayed.append("tobben")
	var w := await start_session()
	await go_to(w, "square", "house")
	check(w.area.tobben.mute, "his voice is Rue's: he writes")
	await _talk_to_tobben(w)
	await wait(VillageSquare.REPORT_DELAY + 1.0)
	check_eq(_reports(w), 0, "with no voice he can't tell the owner")


func test_after_the_guest_book_he_tells_less() -> void:
	memory().guestbook_restored = true
	Relationships.add("tobben.guestbook")
	var w := await start_session()
	await go_to(w, "square", "house")
	await _talk_to_tobben(w)
	await wait(VillageSquare.REPORT_DELAY + 1.0)
	var said := []
	for e in w.hud.history:
		if str(e.text).contains("tobben says"):
			said.append(e.text)
	for m in w.hud._queue:
		if str(m.text).contains("tobben says"):
			said.append(m.text)
	check_eq(said.size(), 1, "he still reports: it's his script")
	check(said.size() == 1 and str(said[0]) == VillageSquare.TOBBEN_REPORT_BOOK, "but leaves out what she asked (%s)" % [str(said)])


# --- D. unbroken text pages at the limit asked for -------------------------------

func test_unbroken_text_pages_at_the_given_limit() -> void:
	var id := "res://saves/rue_slot02/" + "x".repeat(400)
	for limit in [40, 90, StoryPacing.PAGE_CHARS, 260]:
		var pages := StoryPacing.pages(id, limit)
		for p in pages:
			check(p.length() <= limit, "limit %d: a page of %d" % [limit, p.length()])
		check_eq("".join(pages), id, "limit %d: nothing lost or added" % limit)
		check_eq(pages.size(), ceili(float(id.length()) / limit), "limit %d: as few pages as fit" % limit)


func test_a_long_identifier_keeps_its_history_whole() -> void:
	var w := await start_session()
	var id := "rue_slot02.hitbox::" + "0123456789abcdef".repeat(20)
	w.hud.show_dialogue("ARCHIVIST", Color.WHITE, [id])
	check(w.hud._dialogue_lines.size() > 1, "paged")
	check_eq(w.hud.history.filter(func(e: Dictionary) -> bool: return e.text == id).size(), 1, "history keeps it whole, once")
	w.hud.close_dialogue()


# --- the message ending and the timeline (§2) -------------------------------------

func test_the_message_ending_says_it_is_the_character() -> void:
	memory().knows_truth = true
	var card := Story.ending_text("message", Story.FRAGMENTS.size())
	var all := card + "\n" + "\n".join(Story.MESSAGE_TRUTH)
	check(not all.contains("part of her"), "no 'a part of her': that reads as the girl herself (%s)" % all)
	check(card.contains("the character she left running"), "the card says what she'll hear about: the character")
	check(Story.MESSAGE_TRUTH[1].contains("character"), "and so does the owner's promise")


func test_the_present_is_dated() -> void:
	var boot := "\n".join(Story.BOOT)
	check(boot.contains("3 YEARS AGO"), "the boot says how long slot 2 has been gone: the present is three years on")
	check(Story.FRAGMENTS[-1].lines[0].contains("months later"), "the message came months after she moved away")
	var bin := RecycleBin.new()
	check(str(bin.get_script().source_code).contains("deleted 3 years ago"), "the Bin's dates agree")
	bin.free()

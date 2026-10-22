extends "res://tests/test_case.gd"
## What counts as said (2026-10-22 opening review, item 3): choosing what
## someone will say changes nothing; a one-time remark or an introduction
## counts once it's read to the end. A gameplay grant (the Archivist's
## pointer) is the deliberate exception: given, and shown, at once.


func _lines(r: Variant) -> Array:
	return r if r is Array else r.get("lines", [])


func _archive(w: Node) -> void:
	await go_to(w, "square", "house")
	await go_to(w, "archive", "west")


func _walk_away(w: Node) -> void:
	await press("interact")  # the first page, read
	await frames(2)
	w.hud.close_dialogue()  # then off, before the end (as walking away does)
	await frames(3)


func test_asking_what_he_would_say_twice_loses_nothing() -> void:
	var w := await start_session()
	memory().sheds = 1
	await _archive(w)
	var first := _lines(w.area._archivist_lines())
	var second := _lines(w.area._archivist_lines())
	check(Story.ARCHIVIST_SHED_FIRST[0] in first, "his remark about the bodies is chosen")
	check(Story.ARCHIVIST_SHED_FIRST[0] in second, "and is still there the second time it's asked for (nothing was read)")
	check("archivist" not in memory().shed_said, "nothing is marked said by choosing it")


func test_his_remark_counts_once_it_is_heard() -> void:
	var w := await start_session()
	memory().sheds = 1
	await _archive(w)
	await interact_with(w, w.area.archivist)
	await _walk_away(w)
	check("archivist" not in memory().shed_said, "walked away: not heard yet")
	await interact_with(w, w.area.archivist)
	await finish_dialogue(w)
	check("archivist" in memory().shed_said, "read to the end: heard, and not said again")


func test_walking_away_from_his_introduction_keeps_the_pointer_and_the_introduction() -> void:
	var w := await start_session()
	await _archive(w)
	await interact_with(w, w.area.archivist)
	check(w.flags.get("pointer", false), "the pointer is handed over at once (the north road opens)")
	await _walk_away(w)
	check(not Relationships.has("archivist.introduced"), "but he never got to say who he is")
	var again := _lines(w.area._archivist_lines())
	check(again.has(Archive_first(1)), "next time he does (%s)" % again)
	check(not again.has(ArchiveArea.ARCHIVIST_BACK), "no reunion before an introduction")
	await interact_with(w, w.area.archivist)
	await finish_dialogue(w)
	check(Relationships.has("archivist.introduced"), "heard whole: introduced")
	check(not _lines(w.area._archivist_lines()).has(Archive_first(1)), "and he doesn't tell it again")


func test_a_new_session_after_a_broken_off_introduction_is_not_a_reunion() -> void:
	var w := await start_session()
	await _archive(w)
	await interact_with(w, w.area.archivist)
	await _walk_away(w)
	w.kill("overwritten", "arin")
	var w2 := await wait_for_new_session(w)
	check(w2.flags.get("pointer", false), "the pointer is kept in the save")
	await _archive(w2)
	var lines := _lines(w2.area._archivist_lines())
	check(not lines.has(ArchiveArea.ARCHIVIST_BACK), "not 'I remember you' to someone he never finished meeting")
	check(lines.has(ArchiveArea.ARCHIVIST_RESUMED_OPEN), "he picks it up again")


func Archive_first(i: int) -> String:
	return ArchiveArea.ARCHIVIST_FIRST[i]

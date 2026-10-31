extends "res://tests/test_case.gd"
## UI-6 / brief §8: places are named on arrival; chapters follow the story
## (Story.CHAPTERS from Quests.story_mission), so exploring in any order
## never shows a later chapter before an earlier one.


func _chapters_seen() -> Array:
	return memory().acts_seen.filter(func(a: String) -> bool: return a.begins_with("chapter:"))


func _assert_in_order(label: String) -> void:
	var order := Story.CHAPTERS.map(func(c: Array) -> String: return "chapter:" + c[0])
	var seen := _chapters_seen()
	var last := -1
	var ok := true
	for k in seen:
		var i := order.find(k)
		ok = ok and i > last
		last = i
	check(ok, "%s: chapters seen in story order (%s)" % [label, seen])


func test_archive_before_the_well() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "archive", "west")
	check("chapter:who_kept" in memory().acts_seen, "reaching the Archive turns to 'who kept it burning'")
	await go_to(w, "square", "east")
	await go_to(w, "oob", "well")
	_assert_in_order("Archive, then the well")
	check(not w.hud.is_act_shown(), "the well afterwards is a place, not a chapter")


func test_well_before_archive() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "oob", "well")
	memory().found_pip = true
	await go_to(w, "square", "well")
	await go_to(w, "archive", "west")
	_assert_in_order("the well, then the Archive")


func test_workshop_before_pip_is_a_place() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "archive", "west")
	await go_to(w, "workshop", "stairs", false)
	check(not w.hud.is_act_shown(), "the optional workshop never turns a chapter")
	_assert_in_order("workshop")


func test_an_old_save_sees_only_its_current_chapter() -> void:
	memory().acts_seen.assign(["room", "square", "oob"])  # an area-act save
	memory().places.assign(["room", "square", "oob", "archive"])
	memory().found_pip = true
	var _w := await start_session()
	var seen := _chapters_seen()
	check(seen.has("chapter:who_kept") and seen.has("chapter:fifth_lantern"), "on waking: earlier chapters marked, the current one shown (%s)" % [seen])
	check(not seen.has("chapter:slot2"), "and nothing ahead of the story")
	_assert_in_order("old save")


func test_the_pointer_turns_the_chapter_without_leaving() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "archive", "west")
	memory().met_archivist = true
	check(await wait_until(func() -> bool: return "chapter:slot2" in memory().acts_seen, 3.0, "the chapter"), "meeting the Archivist turns the chapter in place")
	_assert_in_order("pointer")

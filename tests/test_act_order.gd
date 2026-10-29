extends "res://tests/test_case.gd"
## UI-6: act cards count up in the order this player reaches the places.


func test_acts_count_up_whichever_way_round() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await go_to(w, "archive", "west")
	check("oob" not in memory().acts_seen and memory().acts_seen[-1] == "archive", "the Archive before Out of Bounds (%s)" % [memory().acts_seen])
	var n: int = memory().acts_seen.size()
	check(n <= 3, "so the Archive is the third act reached at most")
	check(w.hud._act_label.text.contains(Story.act_label(n) + " "), "and its card counts up: %s" % w.hud._act_label.text)
	check(not w.hud._act_label.text.contains("ACT IV"), "not ACT IV")


func test_labels() -> void:
	check_eq(Story.act_label(1), "ACT I", "one")
	check_eq(Story.act_label(5), "ACT V", "five")

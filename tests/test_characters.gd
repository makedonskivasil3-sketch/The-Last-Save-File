extends "res://tests/test_case.gd"
## First encounters (docs/OPENING_REVIEW.md, character matrix): a routine
## before a request; recognition before utility.


func test_mira_is_at_her_cups_before_she_asks_anything() -> void:
	var w := await start_session()
	check_eq(w.area.mira.idle_style, "tend", "Mira, at her two cups: her routine")


func test_pip_knows_her_before_it_guides_her() -> void:
	# (Already in place: its first talk is recognition, then the offer.)
	var lines: Array = Story.PIP_MEETING
	var knows := lines.find("...rue?")
	var guides := -1
	for i in lines.size():
		if str(lines[i]).contains("smell where your pieces are"):
			guides = i
	check(knows == 0 and guides > knows, "it says her name first, and offers to guide her last")

extends "res://tests/test_case.gd"
## The Archivist (docs/production/CHARACTERS.md): he names the colours once,
## and after Rue reads the CHARACTER FILE he starts a new one, under PEOPLE.


func _readable(area: Node, title: String) -> Readable:
	for n in area.find_children("*", "Readable", true, false):
		if (n as Readable).title == title:
			return n
	return null


func test_he_names_the_colours_once_while_she_is_partly_coloured() -> void:
	memory().fragments.assign(["controller"])
	var w := await start_session()
	await go_to(w, "archive", "west")
	var first: Dictionary = w.area._archivist_lines()
	check(first.lines.has(ArchiveArea.ARCHIVIST_COLOURS), "partly coloured: he says it")
	for f in first.after:
		f.call()
	var second: Dictionary = w.area._archivist_lines()
	check(not second.lines.has(ArchiveArea.ARCHIVIST_COLOURS), "heard once: not again")


func test_no_colour_remark_before_any_memory() -> void:
	var w := await start_session()
	await go_to(w, "archive", "west")
	check(not w.area._archivist_lines().lines.has(ArchiveArea.ARCHIVIST_COLOURS), "no colours back yet: nothing to remark on")


func test_after_the_file_he_starts_a_new_one() -> void:
	var w := await start_session()
	await go_to(w, "archive", "west")
	check(_readable(w.area, ArchiveArea.NEW_FILE_TITLE) == null, "before she knows: no new file")
	memory().knows_truth = true
	await go_to(w, "square", "east")
	await go_to(w, "archive", "west")
	var r := _readable(w.area, ArchiveArea.NEW_FILE_TITLE)
	check(r != null, "after the truth: a new file on his desk")
	if r:
		var lines: Array = r.lines_provider.call()
		check(str(lines).contains("FILED UNDER: PEOPLE"), "filed under people")
		check_eq(r.prompt, "look", "a thing to look at, not a book")

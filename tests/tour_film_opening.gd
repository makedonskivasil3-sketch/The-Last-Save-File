extends "res://tests/test_case.gd"
## The film's first part (tools/record_film.sh): a fresh profile's title,
## the memory card and the whole festival, played as a player who acts as
## soon as asked and reads each page for its reading time (autoplay).


func test_opening_film() -> void:
	settings().opening_seen = false
	tree.change_scene_to_file(TITLE_SCENE)
	await wait(4.0)  # the title, as a first launch shows it
	scene()._start()
	await wait_until(func() -> bool: return scene() is ColdOpen or scene() is Prologue, 5.0, "the memory card")
	if scene() is ColdOpen:
		scene().autoplay = true
		await wait_until(func() -> bool: return scene() is Prologue, 120.0, "the festival")
	var p: Prologue = scene()
	await wait(1.5)
	Input.action_press("move_up")
	await wait(0.2)
	Input.action_release("move_up")
	p.autoplay = true
	check(await wait_until(func() -> bool: return scene() is World, 600.0, "the room"), "the festival hands over to the run")
	var w := scene()
	if w is World:
		await wait_until(func() -> bool: return w._awake, 20.0, "awake")
	await wait(3.0)

extends "res://tests/test_case.gd"
## Rue: colours restored by memory fragments, and body language.


func test_rue_starts_as_missing_texture() -> void:
	var w := await start_session()
	check_eq(w.player.restored_parts(), 0, "nothing restored without memories")
	check_eq(w.player._sprite.palette["a"], Player.MISSING["a"], "scarf is missing-texture cyan")
	check_eq(w.player._sprite.palette["s"], Player.MISSING["s"], "no face yet")


func test_fragments_restore_rue_in_order() -> void:
	var w := await start_session()
	var p: Player = w.player
	var expected := 0
	for f in Story.FRAGMENTS:
		memory().add_fragment(f.id)
		p.refresh_look()
		expected += 1
		check_eq(p.restored_parts(), expected, "%d fragments restore %d parts" % [expected, expected])
		for key in Player.RESTORE_ORDER[expected - 1]:
			check_eq(p._palette[key], Player.RUE[key], "fragment %d restores '%s'" % [expected, key])
	check_eq(p._palette["s"], Player.RUE["s"], "with every memory, Rue has a face")


func test_rue_startles_when_the_owner_reacts() -> void:
	var w := await start_session()
	w.director.add_awareness(OwnerDirector.NOTICE + 1.0)
	await frames(2)
	check(w.player._startle_mark > 0.0, "a threshold makes Rue jump")
	check(w.player._sprite.startled > 0.0, "with wide eyes")

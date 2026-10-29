extends "res://tests/test_case.gd"
## Canon decision B (docs/CANON_DECISIONS.md): in the `rue` ending she picks
## a colour nobody chose for her, and wears it from then on.


func test_nobody_else_has_her_colour() -> void:
	for pal in [Player.RUE, Player.MISSING] + Player.BORROWED.values():
		check(not (pal as Dictionary).values().has(Player.OWN), "not in anyone's palette")
	check(not Player.palette_for(5, []).has("o"), "five memories back: still nothing of her own")
	check_eq(Player.palette_for(0, [], true).get("o"), Player.OWN, "chosen: hers even with nothing else back")


func test_after_the_rue_ending_she_wears_it() -> void:
	memory().endings_seen.assign(["rue"])
	var w := await start_session()
	check_eq(w.player.palette().get("o"), Player.OWN, "the sprite's palette has it")
	w.player._sprite.palette = Player.MISSING  # what the owner's flicker shows
	check(not w.player._sprite.palette.has("o"), "under the owner's attention it goes with the rest")


func test_before_it_she_does_not() -> void:
	memory().endings_seen.assign(["escape", "wren"])
	var w := await start_session()
	check(not w.player.palette().has("o"), "other endings: no colour of her own")


func test_the_rue_epilogue_says_so() -> void:
	var lines := Story.epilogue("rue", Story.FRAGMENTS.size(), false)
	check(lines.has(Story.RUE_OWN_COLOUR), "the epilogue tells it")
	check(not Story.epilogue("escape", 2, false).has(Story.RUE_OWN_COLOUR), "only that ending")


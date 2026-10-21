extends "res://tests/test_case.gd"
## Pass 7 (docs/GAMEPLAY_CONSISTENCY.md): fairness fixes from the player
## experience review, and the story's end cards and messages following what
## Rue knows (docs/RELEASE_READINESS.md).


func _remember_everything() -> void:
	for f in Story.FRAGMENTS:
		if f.id not in memory().fragments:
			memory().fragments.append(f.id)


func test_a_save_over_waits_while_you_are_hidden() -> void:
	var w := await start_session()
	await go_to(w, "house", "front")
	w.director.paused = true
	w.area.next_visit = 999.0
	w.player.global_position = ArinsHouse.CLOSETS[0].get_center()
	await frames(3)
	check(w.is_hidden_now(), "in the closet, Rue is hidden")
	w.owner_moves.start_save_over()
	await wait(OwnerMoves.SAVE_TIME + 1.0)
	check_eq(w.ending, "", "standing still in a closet is not a death")
	check(w.owner_moves.save_progress < 0.2, "the ring doesn't fill while she's hidden (%.2f)" % w.owner_moves.save_progress)


func test_the_square_cursor_never_outruns_rue_and_comes_in_far_away() -> void:
	memory().purge = 5
	var w := await start_session()
	await go_to(w, "square", "north")
	w.director.paused = true
	var arrived: Vector2 = w.player.global_position
	w.area._unleash()
	var cursor: OwnerCursor = w.area.cursor
	check(cursor.speed <= VillageSquare.CURSOR_MAX_SPEED, "capped at %.0f (got %.0f)" % [VillageSquare.CURSOR_MAX_SPEED, cursor.speed])
	check(cursor.speed < w.player.speed, "slower than Rue walks")
	check(cursor.position.distance_to(arrived) > 150.0, "it comes in away from where she arrived (%.0f px)" % cursor.position.distance_to(arrived))


func test_the_static_does_not_start_under_your_feet() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var here: Vector2 = w.player.global_position
	memory().deaths_log.append({"area": "square", "x": here.x, "y": here.y, "session": memory().sessions})
	w.area.start_erasure()
	await wait(1.2)
	check(not w.area.erasure.is_void(here), "a death where you now stand doesn't seed the static there")


func test_end_cards_follow_what_rue_knows() -> void:
	_remember_everything()
	memory().knows_truth = false
	var escape := Story.ending_text("escape", Story.FRAGMENTS.size())
	check(escape.contains("don't know yet who you are"), "an escape with every memory but not the truth says so (%s)" % escape)
	memory().knows_truth = true
	check(Story.ending_text("escape", Story.FRAGMENTS.size()).contains("yours once"), "with the truth, the slot was hers once: hers is yours")
	check(Story.ending_text("rue", Story.FRAGMENTS.size()).contains("you know who you are"), "RUE's card speaks to the truth it needed")


func test_the_apology_changes_once_rue_knows_she_is_not_the_girl() -> void:
	memory().knows_truth = false
	check_eq(Story.messages()[0], Story.MESSAGES[0], "before the truth, the first message is the old apology")
	memory().knows_truth = true
	check_eq(Story.messages()[0], Story.MESSAGE_SORRY_TRUTH, "after it, she can't apologise for leaving")
	check_eq(Story.messages().size(), Story.MESSAGES.size(), "the same three choices")
	memory().knows_truth = false

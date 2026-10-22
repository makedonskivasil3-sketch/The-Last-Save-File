extends "res://tests/test_case.gd"
## The author's decisions (docs/NARRATIVE_DECISIONS.md, 2026-10-16) stay
## decided: these lines must not drift back into contradiction.


func test_fragment_one_rue_makes_her_own() -> void:
	var lines: Array = Story.fragment("controller").lines
	check(lines.has("\"you be arin,\" i said. \"i'll make my own.\""), "Rue says both lines")


func test_message_then_delete_the_same_night() -> void:
	var notes := "\n".join(Story.OWNER_NOTES)
	check(not notes.contains("two years"), "no 'two years'")
	check(not notes.contains("already deleted"), "the message came before the deletion")
	check(notes.contains("that same night i deleted it"), "deleted the night of the message")
	check("\n".join(Story.fragment("delete").lines).contains("months later"), "the message came months after the move")


func test_slot_two_is_the_deleted_slots_ghost() -> void:
	check(Story.FINAL_FIGHT.notice.contains("i deleted that"), "the owner recognises the slot they deleted")
	check(Story.win_text(0).contains("survived"), "the escape: the owner doesn't know it survived")
	var archive := FileAccess.get_file_as_string("res://scripts/world/areas/archive.gd")
	check(archive.contains("the owner thinks is gone"), "the Archivist")
	check(not archive.contains("never used"), "no 'never used' left")


## The author's decision of 2026-10-22 (docs/CANON_DECISIONS.md §1): main's
## premise. Rue is the character, not the girl: what she left running. She
## stays "she"; RUE needs the truth; the real girl learns that Rue exists.
## The draft's "part of her that stayed" text is gone.
func test_rue_is_what_she_left_running() -> void:
	check(Story.TRUTH_REVEAL.has("(i'm what she left running.)"), "the reveal's last line")
	check(Story.TRUTH_REVEAL.has("(i'm not her.)"), "Rue is not the girl")
	check(Story.CHARACTER_FILE.any(func(l: String) -> bool: return l.contains("player: moved away")), "the file: her player moved away")
	check(Story.MESSAGE_TRUTH[0].contains("tell her about me") and Story.MESSAGE_TRUTH[0].contains("what she left running"), "the real girl will hear about Rue")
	check(not Story.EPILOGUE_TRUE.has("(i am. the part that stayed.)"), "no draft answer to the owner's denial: 'you're not her' is true")
	check(Story.ENDINGS_RECORD.any(func(e: Array) -> bool: return e[0] == "rue" and e[3].contains("knowing what you are")), "the RUE hint names the truth")
	var all := "\n".join(Story.TRUTH_REVEAL + Story.CHARACTER_FILE + [Story.TRUTH_AFTER])
	for draft in ["costume", "still in session", "part of her didn't"]:
		check(not all.contains(draft), "no draft text left: %s" % draft)
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


## The continuity milestone's contract (docs/NARRATIVE_CONTRACT.md §1,
## proposed, replacing the 2026-10-19 "dark truth"): Rue is the part of the
## girl that stayed in the interrupted save; she stays "she"; RUE needs the
## truth; the rest of her outside learns where she is. The owner's "you're
## not her" stays, as denial, and Rue answers it.
func test_rue_is_the_part_of_her_that_stayed() -> void:
	check(Story.TRUTH_REVEAL.has("(i'm what she left.)"), "the reveal's last line")
	check(Story.TRUTH_REVEAL.has("(i'm not what she left running.)"), "Rue is not a program she left running")
	check(not Story.TRUTH_REVEAL.has("(i'm not her.)"), "the old reveal is gone")
	check(Story.CHARACTER_FILE.any(func(l: String) -> bool: return l.contains("player: still in session")), "the file says the player is still in it")
	check(Story.MESSAGE_TRUTH[0].contains("tell her about me") and Story.MESSAGE_TRUTH[0].contains("where the rest of her is"), "the girl outside will hear where she is")
	check(Story.EPILOGUE_TRUE.has("(i am. the part that stayed.)"), "Rue answers the owner's denial")
	check(Story.ENDINGS_RECORD.any(func(e: Array) -> bool: return e[0] == "rue" and e[3].contains("knowing who you are")), "the RUE hint names the truth")
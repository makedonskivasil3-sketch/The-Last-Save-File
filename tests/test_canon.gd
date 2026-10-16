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

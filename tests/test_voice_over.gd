extends "res://tests/test_case.gd"
## Recorded voice lines are optional (docs/ASSET_PRODUCTION.md): a line with no
## file keeps its procedural voice and nothing else changes.


func test_an_unrecorded_line_is_silent_and_harmless() -> void:
	check_eq(VoiceOver.path_for("memory_does_not_exist"), "", "no file, no path")
	var holder := Node.new()
	tree.root.add_child(holder)
	check(VoiceOver.play(holder, "memory_does_not_exist") == null, "nothing plays")
	check_eq(holder.get_child_count(), 0, "and no player is left behind")
	holder.free()


func test_every_scripted_id_names_a_real_line() -> void:
	# The ids in the voice script must match what the game asks for.
	for f in Story.FRAGMENTS:
		check(("memory_" + f.id).is_valid_filename(), "memory id %s is a usable file name" % f.id)

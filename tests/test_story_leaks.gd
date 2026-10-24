extends "res://tests/test_case.gd"
## Story leaks in the first hour (docs/INTRO_REBUILD.md §5): before the
## CHARACTER FILE, nothing Rue says claims the girl's life as her own, and
## every memory says whose recording it is.

## What only the girl did: sat in front of the screen, moved away, chose
## Rue's colours.
const GIRL_CLAIMS := ["in front of it", "i moved away", "i said i'd come back", "i came back", "i picked that colo"]


func _rue_lines_before_the_truth() -> Array:
	var out: Array = Story.RESTORED.values()
	for f in Story.FRAGMENTS:
		out.append(f.after)
	return out


func test_rue_never_speaks_as_the_girl_before_the_file() -> void:
	for line: String in _rue_lines_before_the_truth():
		for claim: String in GIRL_CLAIMS:
			check(not line.to_lower().contains(claim), "Rue says \"%s\": that's the girl's (%s)" % [claim, line])


func test_every_memory_says_whose_recording_it_is() -> void:
	for f in Story.FRAGMENTS + [Story.FALSE_FRAGMENT]:
		var frame := Story.replay_frame(f.id)
		check(frame.begins_with("REPLAY · ") or frame.begins_with("LOG · "), "%s has its frame (%s)" % [f.id, frame])
	for id in ["controller", "well", "new_game", "argument"]:
		check(Story.replay_frame(id).begins_with("REPLAY · P2 · "), "%s is Player 2's recording" % id)
	check_eq(Story.replay_frame("argument"), "REPLAY · P2 · 41:07:12", "the last time is the end of the 41 hours")


func test_the_frame_shows_with_speaker_labels_off() -> void:
	settings().speaker_labels = false
	var w := await start_session()
	var f := Story.fragment("controller")
	for c in w.area.get_children():
		if c is MemoryFragment:
			w.player.global_position = c.global_position
	await wait_until(func() -> bool: return w.hud.is_cinematic(), 4.0, "the memory")
	check(w.hud._cine_title.text.begins_with(f.replay), "the frame is on screen (%s)" % w.hud._cine_title.text)
	check(not w.hud._cine_title.text.contains(f.title), "and the title isn't (speaker labels are off)")
	await read_through_cinematic(w)
	settings().speaker_labels = true


func test_the_journal_page_keeps_the_frame() -> void:
	var f := Story.fragment("well")
	memory().keep_memory(f.id, f.title, "Out of bounds", f.lines)
	var page: Dictionary = ArchivePages.memories()[0]
	check(page.body.begins_with(f.replay), "the journal's page opens with it (%s)" % page.body.get_slice("\n", 0))
